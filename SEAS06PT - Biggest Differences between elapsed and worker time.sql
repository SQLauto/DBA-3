--- Biggest differences between elapsed and worker time
--- top 50 statements 
---
--- For example, if you have lock wait types .e.g blocking and you want to track it down
--- first look at index contention and row lock waits.
---
--- Then look at Biggest differences between elapsed and worker time to find statements
--- that have big deltas:  elapsed > worker
---

SELECT TOP 50

qs.total_elapsed_time*1.0/qs.execution_count as [Avg Elapsed Time]
,qs.total_worker_time*1.0/qs.execution_count as [Avg CPU Time]
,(qs.total_elapsed_time - qs.total_worker_time*1.0)/qs.execution_count as [Elapsed Diff]
,(qs.total_elapsed_time - qs.total_worker_time*1.0) as [Total Elapsed Diff]
,qs.execution_count
,SUBSTRING(qt.text,qs.statement_start_offset/2, 
			(case when qs.statement_end_offset = -1 
			then len(convert(nvarchar(max), qt.text)) * 2 
			else qs.statement_end_offset end -qs.statement_start_offset)/2) 
	as query_text
,qt.dbid, dbname=db_name(qt.dbid)
,qt.objectid 
FROM sys.dm_exec_query_stats qs
cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
where qs.execution_count > 200
ORDER BY 
        [Total Elapsed Diff] DESC