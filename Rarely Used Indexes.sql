--- Rarely Used Indexes.sql 
--- rarely used indexes appear first

--- This stored procedure is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
---
declare @dbid int
select @dbid = db_id()
select objectname=object_name(s.object_id), s.object_id
	, indexname=i.name, i.index_id
	, user_seeks, user_scans, user_lookups, user_updates
from sys.dm_db_index_usage_stats s,
	sys.indexes i
where database_id = @dbid 
and objectproperty(s.object_id,'IsUserTable') = 1
and i.object_id = s.object_id
and i.index_id = s.index_id
order by (user_seeks + user_scans + user_lookups + user_updates) asc
