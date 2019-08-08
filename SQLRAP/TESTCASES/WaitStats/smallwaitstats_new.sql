--Signature="4AB7C70A4D5D5518" 

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    Populate the wait stats information for each iteration that the RAPID client initiates, and		 ****/
--/****    outputs the delta wait time between the current run and previous run for each wait type for	     ****/ 
--/****    both SQL Server 2000 and SQL Server 2005.														 ****/
--/****    This script creates a permanent table tempdb.dbo.SQLRAP_tbl_wait_stats in the tempdb to store the ****/
--/****    previous run wait stats information.  This table must be dropped as part of post comments script. ****/
--/****    updated 10/30/2009 by rajpo to add support for SQL2K8 (CR 375891)                                 ****/
--/****    rajpo 12/10/2009 added several ignoranle wait type filters into SQL2008 branch                    ****/
--/****    rajpo 12/10/2010 added more ignorable wait types                                                  ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright Microsoft Corporation. All rights reserved.											 ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

--set nocount on
--go

declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));
---Create permanent table in tempdb for storing the previous run values.

	if   object_id('tempdb.dbo.SQLRAP_tbl_wait_stats') is  null
			
	Create table tempdb.dbo.SQLRAP_tbl_wait_stats
	(Run_time datetime,
	wait_type nvarchar(60),
	wait_time_ms bigint)

---Create the temp table for only SQL2K to populate the output of DBCC sqlperf(waitstats) command

if 8 = (select substring(@version, 1, 1))
begin
	
		if object_id('tempdb.dbo.#tbl_wait_stats_2000_10sec') is not null
			drop table #tbl_wait_stats_2000_10sec
		
		create table #tbl_wait_stats_2000_10sec
		(wait_type nvarchar(60),
		Requests bigint,
		wait_time_ms bigint,
		signal_wait_ms bigint)
end




---Actual execution of the logic starts here

	if  '10' = (select substring(@version, 1, 2))
    Begin
		---SQL Server 2008 wait stats
		select getdate() as 'Run_Time',ws.wait_type,  
		ws.wait_time_ms-temp_ws.wait_time_ms as "Delta_wait" from sys.dm_os_wait_stats ws
		left outer join tempdb.dbo.SQLRAP_tbl_wait_stats temp_ws
		on ws.wait_type=temp_ws.wait_type
		where ws.wait_type not in ('BROKER_TASK_STOP','Total','SLEEP','BROKER_EVENTHANDLER','BROKER_RECEIVE_WAITFOR',
		'BROKER_TRANSMITTER','CHECKPOINT_QUEUE','CHKPT','CLR_AUTO_EVENT','CLR_MANUAL_EVENT','KSOURCE_WAKEUP','LAZYWRITER_SLEEP',
		'LOGMGR_QUEUE','ONDEMAND_TASK_QUEUE','REQUEST_FOR_DEADLOCK_SEARCH','RESOURCE_QUEUE','SERVER_IDLE_CHECK',
		'SLEEP_BPOOL_FLUSH','SLEEP_DBSTARTUP','SLEEP_DCOMSTARTUP','SLEEP_MSDBSTARTUP','SLEEP_SYSTEMTASK','SLEEP_TASK',
		'SLEEP_TEMPDBSTARTUP','SNI_HTTP_ACCEPT','SQLTRACE_BUFFER_FLUSH','TRACEWRITE','WAIT_FOR_RESULTS','WAITFOR_TASKSHUTDOWN',
		'XE_DISPATCHER_WAIT','XE_TIMER_EVENT','WAITFOR')
		order by ws.wait_time_ms desc

		truncate table tempdb.dbo.SQLRAP_tbl_wait_stats

		
		insert into tempdb.dbo.SQLRAP_tbl_wait_stats ( Run_time, wait_type,wait_time_ms) select getdate() as 'Run_Time',wait_type,wait_time_ms  from sys.dm_os_wait_stats 
		order by wait_time_ms desc
	End

	if  9 = (select substring(@version, 1, 1))
	Begin
		----SQL Server 2005 wait stats
		



		select getdate() as 'Run_Time',ws.wait_type,  
		ws.wait_time_ms-temp_ws.wait_time_ms as "Delta_wait" from sys.dm_os_wait_stats ws
		left outer join tempdb.dbo.SQLRAP_tbl_wait_stats temp_ws
		on ws.wait_type=temp_ws.wait_type
		where ws.wait_type not in ('LAZYWRITER_SLEEP','SQLTRACE_BUFFER_FLUSH','BROKER_TASK_STOP','RESOURCE_QUEUE','Total','SLEEP','WAITFOR')
		order by ws.wait_time_ms desc

		truncate table tempdb.dbo.SQLRAP_tbl_wait_stats

		
		insert into tempdb.dbo.SQLRAP_tbl_wait_stats ( Run_time, wait_type,wait_time_ms) select getdate() as 'Run_Time',wait_type,wait_time_ms  from sys.dm_os_wait_stats 
		order by wait_time_ms desc
		


	end 
	else
	if 8=(select substring(@version, 1, 1))
	begin
		---For SQL Server 20000
		
		
		
		
		insert into #tbl_wait_stats_2000_10sec exec('dbcc sqlperf(waitstats) with tableresults, no_infomsgs')
		
		select getdate() as 'Run_Time',ws.wait_type,  
		ws.wait_time_ms-temp_ws.wait_time_ms as "Delta_wait" from #tbl_wait_stats_2000_10sec ws
		left outer join tempdb.dbo.SQLRAP_tbl_wait_stats temp_ws
		on ws.wait_type=temp_ws.wait_type
		where ws.wait_type not in ('LAZYWRITER_SLEEP','SQLTRACE_BUFFER_FLUSH','BROKER_TASK_STOP','WAITFOR','RESOURCE_QUEUE','Total','SLEEP')
		order by ws.wait_time_ms desc
		truncate table tempdb.dbo.SQLRAP_tbl_wait_stats
		insert into tempdb.dbo.SQLRAP_tbl_wait_stats (Run_time,wait_type,wait_time_ms) select getdate(),wait_type,wait_time_ms from #tbl_wait_stats_2000_10sec
		truncate table #tbl_wait_stats_2000_10sec
	end
