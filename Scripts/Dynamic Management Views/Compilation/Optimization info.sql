---- Optimization info.sql

---- SQL Server 2005 Performance Tuning with DMVs - T. Davidson

---- CPU resources required for optimization
---- Optimizations - total query plans created
---- Elapsed time - Optimization is CPU intensive thus CPU time
---- Trivial plan - the number of 'trivial' plans
---- Tables - average number of tables per query
---- Inserts/Updates/Deletes - number of inserts, updates, deletes

---- This script is provided "AS IS" with no warranties, and confers no rights. 
---- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
----

Select * from sys.dm_exec_query_optimizer_info
where counter in ('optimizations','elapsed time','trivial plan','tables','insert stmt','update stmt','delete stmt')
