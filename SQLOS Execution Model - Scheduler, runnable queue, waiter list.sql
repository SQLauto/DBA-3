---- SQLOS Execution Model
----	For each Scheduler show runnable queues, waiter list & workers
---- Resource waits are the time spent waiting for the resource 
---- Notice wait_duration_ms, wait_type
---- For overall waits for a workload use track_waitstats_2005

--- This script is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm

select distinct s.scheduler_id as sched
	, r.session_id as sid
	, w.exec_context_id as eid
	--, w.blocking_exec_context_id as beid
	, r.status
	, r.wait_type
	, s.runnable_tasks_count as runnable
	, s.active_workers_count as act_workers
	, s.current_workers_count as cur_workers
from sys.dm_os_schedulers s
left outer join sys.dm_exec_requests r
on s.scheduler_id = r.scheduler_id
left outer join sys.dm_os_waiting_tasks w
on r.session_id = w.session_id
where r.session_id > 50
order by s.scheduler_id
	, r.session_id
	, w.exec_context_id
	, r.status
	, r.wait_type
	, s.runnable_tasks_count
	, s.active_workers_count
go
select distinct session_id, exec_context_id, count(*)
from sys.dm_os_waiting_tasks
where session_id > 50
group by session_id, exec_context_id
order by session_id, exec_context_id