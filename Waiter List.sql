---- Waiter list
---- Resource waits are the time spent waiting for the resource 
---- Notice wait_duration_ms, wait_type
---- For overall waits for a workload use track_waitstats_2005

--- This script is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm

select session_id
		, exec_context_id
		, wait_type
		, wait_duration_ms
		, blocking_session_id
from sys.dm_os_waiting_tasks
where session_id > 50
order by session_id, exec_context_id