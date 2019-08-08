---- Indexes Not Used.sql

---- SQL Server 2005 Performance Tuning with DMVs - T. Davidson

---- Question: what indexes are NOT used?
---- When an index is used, the index appears in sys.dm_db_index_usage_stats
---- Conversely, any index NOT used since SQL was last recycled will
----    not appear in sys.dm_db_index_usage_stats

-- This sscript is provided "AS IS" with no warranties, and confers no rights. 
-- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
--
use Northwind
go
select object_name(i.object_id), i.name 
from sys.indexes i, sys.objects o 
where  i.index_id NOT IN (select s.index_id 
       from sys.dm_db_index_usage_stats s 
 	  where s.object_id=i.object_id and 
	 		i.index_id=s.index_id and 
			database_id = db_id('Northwind') )
and o.type = 'U'
and o.object_id = i.object_id
order by object_name(i.object_id) asc
go

---- note: Period index x2 is on OrderDate
select * from Period
where OrderDate = getdate()
--- note: Perid index x1 is on DateID
select * from Period
where DateID = 20001010
go
---- after executing the above select statement from the Period table, redisplay the indexes NOT used
---- you will discover the x1 and x2 indexes are no longer listed as NOT used.