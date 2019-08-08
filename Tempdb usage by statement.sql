--- Tempdb - statements using tempdb
---
--- This script is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm

SELECT t1.session_id,
(t1.internal_objects_alloc_page_count + task_alloc) as allocated,
(t1.internal_objects_dealloc_page_count + task_dealloc) as deallocated
	, t3.sql_handle, t3.statement_start_offset
	, t3.statement_end_offset, t3.plan_handle
from sys.dm_db_session_space_usage as t1, 
		sys.dm_exec_requests t3,
(select session_id, 
   sum(internal_objects_alloc_page_count) as task_alloc,
   sum (internal_objects_dealloc_page_count) as task_dealloc
      from sys.dm_db_task_space_usage group by session_id) as t2
where t1.session_id = t2.session_id and t1.session_id >50
and t1.database_id = 2   --- tempdb is database_id=2
and t1.session_id = t3.session_id
order by allocated DESC
