---- Parallelism, worker and elapsed time

---- SQL Server 2005 Performance Tuning with DMVs - T. Davidson

---- Parallel plans indicated where worker time > elapsed time

-- This script is provided "AS IS" with no warranties, and confers no rights. 
-- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
--
select 
  qs.sql_handle, 
  qs.statement_start_offset, 
  qs.statement_end_offset, 
  q.dbid,
  q.objectid,
  q.number,
  q.encrypted,
  q.text
from sys.dm_exec_query_stats qs
	cross apply sys.dm_exec_sql_text(qs.plan_handle) as q
where qs.total_worker_time > qs.total_elapsed_time

