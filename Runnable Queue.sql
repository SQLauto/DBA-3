---- Runnable Queue
---- Signal waits are the time spent in the runnable queue waiting for CPU
---- For overall waits for a workload, use track_waitstats_2005

--- This script is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
---
select scheduler_id, session_id, status, command 
from sys.dm_exec_requests
where status = 'runnable'
and session_id > 50
order by scheduler_id