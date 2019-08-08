---- Currently executing statements.sql

---- SQL Server 2005 Performance Tuning with DMVs - T. Davidson

---- lists users in sys.dm_exec_requests
---- status of 'runnable' indicates user waiting on CPU
---- Each scheduler has its own runnable queue

--- This script is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
---
select r.session_id
		,status
		,substring(qt.text,r.statement_start_offset/2, 
			(case when r.statement_end_offset = -1 
			then len(convert(nvarchar(max), qt.text)) * 2 
			else r.statement_end_offset end - r.statement_start_offset)/2) 
		as query_text   --- this is the statement executing right now
		,qt.dbid
		,qt.objectid
		,r.cpu_time
		,r.total_elapsed_time
		,r.reads
		,r.writes
		,r.logical_reads
		,r.scheduler_id
from sys.dm_exec_requests r
cross apply sys.dm_exec_sql_text(sql_handle) as qt
where r.session_id > 50
order by r.scheduler_id, r.status, r.session_id
