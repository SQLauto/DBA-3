---- Signal vs. Resource Waits.sql
---- Signal waits are the time spent in the runnable queue waiting for CPU
---- Resource waits are the time spent waiting for the resource = wait_time_ms - signal_wait_time_ms
---- Total waits are wait_time_ms

--- This script is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm

Select signal_wait_time_ms=sum(signal_wait_time_ms)
	,'%signal waits' = cast(100.0 * sum(signal_wait_time_ms) / sum (wait_time_ms) as numeric(20,2))
	,resource_wait_time_ms=sum(wait_time_ms - signal_wait_time_ms)
	,'%resource waits'= cast(100.0 * sum(wait_time_ms - signal_wait_time_ms) / sum (wait_time_ms) as numeric(20,2))
From sys.dm_os_wait_stats
