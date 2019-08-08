--- Buffer counts by object & index.sql

---- SQL Server 2005 Performance Tuning with DMVs - T. Davidson

--- This script breaks down buffers by object (table, index) in buffer cache
--- Use database to get the object names for the database

--- This script is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
---
use Northwind
go
select b.database_id, db=db_name(b.database_id)
		,p.object_id
		,object_name(p.object_id) as objname
		,p.index_id
		,buffer_count=count(*)
from sys.allocation_units a,
		sys.dm_os_buffer_descriptors b,
		sys.partitions p
where a.allocation_unit_id = b.allocation_unit_id
and a.container_id = p.hobt_id
and b.database_id = db_id()
group by b.database_id,p.object_id, p.index_id
order by buffer_count desc
