--- Scheduler wait list, workers & runnable queues

--- This script is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
---
select 
	scheduler_id,
	current_tasks_count,
	runnable_tasks_count,
	current_workers_count,
	active_workers_count,
	work_queue_count,
	load_factor
from sys.dm_os_schedulers
where scheduler_id < 255
