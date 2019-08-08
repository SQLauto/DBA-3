--- Index Usage Stats.sql

---- SQL Server 2005 Performance Tuning with DMVs - T. Davidson

--- lists out Stats for Existing Indexes, ordered by user_updates
---
--- When an index is used, it is inserted into sys.dm_db_index_usage_stats
--- Conversely, if an index is not used, it will NOT appear in sys.dm_db_index_usage_stats

--- This script is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
---
select 
	* 
from 
	sys.dm_db_index_usage_stats 
order by 
	user_updates desc
