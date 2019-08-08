

-- This script runs in an infinite loop every 30 seconds ( can be invoked with SQLCMD or management Studio) 
-- @SQLCPUThreshold_Percent specifies what CPU threshold we are monitoring 
-- If for 2 successive Ring buffer snapshots ( 2 minutes), the CPU is above the threshold we specified, 
-- We then collect the top 25 Statements along with their plans in the Database and table we created. 

-- Database/Table creation script not included. 


Declare @SQLCPUThrehold_Percent int

Set @SQLCPUThrehold_Percent = 1 

WHILE (1 = 1)

BEGIN 
      SELECT TOP 2 
      CONVERT (varchar(30), getdate(), 126) AS runtime, 
                record.value('(Record/@id)[1]', 'int') AS record_id, 
                record.value('(Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS system_idle_cpu, 
                record.value('(Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS sql_cpu_utilization 
	  into #tempCPU 
      FROM sys.dm_os_sys_info inf CROSS JOIN ( 
      SELECT timestamp, CONVERT (xml, record) AS record 
      FROM sys.dm_os_ring_buffers 
      WHERE ring_buffer_type = 'RING_BUFFER_SCHEDULER_MONITOR'
      AND record LIKE '%<SystemHealth>%') AS t 
      ORDER BY record.value('(Record/@id)[1]', 'int') DESC 

	  --select * from #tempCPU


-- If the IF statement is satisfied, last 2 Ring buffer records had CPU > threshold so we capture the plans 
if ( (select count(*) from #tempCPU) = (select count(*) from #tempCPU where sql_cpu_utilization >@SQLCPUThrehold_Percent)) 
begin
-- insert top 25 Statements and plans by CPU into the table 
      insert into dba.dbo.Tbl_troubleshootingPlans 
      SELECT TOP 25   getdate() as runtime, 
                        qs.Execution_count as Executions,
                        qs.total_worker_time as TotalCPU, 
                        qs.total_physical_reads as PhysicalReads, 
                        qs.total_logical_reads as LogicalReads, 
                        qs.total_logical_writes as LogicalWrites,
                        qs.total_elapsed_time as Duration, 
                        qs.total_worker_time/qs.execution_count as [Avg CPU Time], 
                        substring (qt.text,qs.statement_start_offset/2,(case when qs.statement_end_offset = -1 then len (convert (nvarchar(max), qt.text)) * 2 
                        else qs.statement_end_offset end - qs.statement_start_offset)/2) as query_text, 
                        qt.dbid as DBID, 
                        qt.objectid as OBJECT_ID, 
                        cast ( query_plan as xml) as XMLPlan 
      FROM sys.dm_exec_query_stats qs 
      cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt 
      CROSS APPLY sys.dm_exec_query_plan(plan_handle) 
      ORDER BY TotalCPU DESC 

end 

--select * from #tempCPU
drop table #tempCPU 
waitfor delay '0:00:30' 

end 
go

/*
-- Look for CPU spikes during the time in question...

select runtime,Executions,TotalCPU,LogicalReads,Duration,[Avg CPU Time], query_text from dba.dbo.tbl_TroubleshootingPlans 
where runtime between '2008-11-03 06:00:00.530' and '2008-11-03 06:06:00.530' order by TotalCPU desc

*/

