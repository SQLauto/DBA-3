--- Missing Indexes.sql

---- SQL Server 2005 Performance Tuning with DMVs - T. Davidson

--- SQL Server 2005 Optimizer can sometimes
--- 	Identify potentially Useful Indexes
--- The key is when identified, it is **only** proposed 
---	to improve the query in question.  
--- Remember: Indexes are used to avoid big IOs
---
--- This script is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
---
select d.*
		, s.avg_total_user_cost
		, s.avg_user_impact
		, s.last_user_seek
		,s.unique_compiles
from sys.dm_db_missing_index_group_stats s
		,sys.dm_db_missing_index_groups g
		,sys.dm_db_missing_index_details d
where s.group_handle = g.index_group_handle
and d.index_handle = g.index_handle
order by s.avg_user_impact desc
go
--- suggested index columns & usage
declare @handle int

select @handle = d.index_handle
from sys.dm_db_missing_index_group_stats s
		,sys.dm_db_missing_index_groups g
		,sys.dm_db_missing_index_details d
where s.group_handle = g.index_group_handle
and d.index_handle = g.index_handle

select * 
from sys.dm_db_missing_index_columns(@handle)
order by column_id
