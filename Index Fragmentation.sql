---- Index Fragmentation.sql

---- SQL Server 2005 Performance Tuning with DMVs - T. Davidson

---- lists out the fragmentation for a specific object
---- 'use database' to list the object and index names
----
---- This stored procedure is provided "AS IS" with no warranties, and confers no rights. 
---- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
----
use Northwind
go
SELECT a.database_id
		,a.object_id
		,a.index_id
		,b.name
		,a.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats (DB_ID(), object_id('[Employees]'),
     NULL, NULL, NULL) AS a
    JOIN sys.indexes AS b 
	ON a.object_id = b.object_id 
	AND a.index_id = b.index_id
where a.database_id = db_id()
order by a.object_id
GO
