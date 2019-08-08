
-- First, verify the state of your cache... is it filled with "USE Count 1" plans?
SELECT objtype
	, count(*) AS [Total Plans]
	, sum(cast(size_in_bytes as decimal(12,2)))/1024/1024 
			AS [Total MBs]
	, avg(usecounts) AS [Avg Use Count]
	, sum(cast((CASE WHEN usecounts = 1 
		THEN size_in_bytes ELSE 0 END) as decimal(12,2)))/1024/1024 AS [Total MBs - USE Count 1]
	, sum(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) AS [Total Plans - USE Count 1]
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY [Total MBs - USE Count 1] DESC
go

-- Here's the statement text from the plans as grouped above
SELECT cp.*, st.text
FROM sys.dm_exec_cached_plans AS cp
	CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
ORDER BY objtype
go

-- This will clear all "USE Count 1" plans but is manual
DBCC FREESYSTEMCACHE('SQL Plans')
go

-- And, if you see this as a regular problem... in SQL Server 2008

--sp_configure 'optimize for ad hoc workloads', 0
--go
--reconfigure
--go

-- More to see how this really works:

USE Credit
go

SET STATISTICS IO ON;
-- Turn Graphical Showplan ON (Ctrl+K)

DBCC FREEPROCCACHE;      --Clears all plans from cache
DBCC DROPCLEANBUFFERS;    --Clears all data from cache

UPDATE member 
	SET lastname = 'Tripp' 
	WHERE member_no = 1234;
go

CREATE INDEX MemberLastName ON dbo.member (lastname);
go

SELECT m.* 
FROM dbo.member AS m
WHERE m.lastname = 'Tripp';
go

SELECT * 
FROM dbo.member AS m
WHERE m.member_no = 1234;
go

SELECT sc.[sql], sc.* 
FROM master.dbo.syscacheobjects AS sc
WHERE sc.[sql] LIKE '%member%' 
	AND sc.[sql] NOT LIKE '%syscacheobjects%';
-- notice that there are 2 adhoc (each of the two statements above) 
-- and 1 prepared (for member_no = 1234)

SELECT st.text, qs.EXECUTION_COUNT, qs.plan_handle, qs.statement_start_offset, qs.*, qp.* 
FROM sys.dm_exec_query_stats AS qs 
	CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS st
	CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
WHERE st.text LIKE '%member%' 
	AND st.text NOT LIKE '%syscacheobjects%'
ORDER BY 1, qs.EXECUTION_COUNT DESC;

SELECT m.* 
FROM dbo.member AS m
WHERE m.lastname = 'Tripps'
go

SELECT m.* 
FROM dbo.member AS m
WHERE m.lastname = 'Tripped'
go

SELECT sc.[sql], sc.* 
FROM master.dbo.syscacheobjects AS sc
WHERE sc.[sql] LIKE '%member%' 
	AND sc.[sql] NOT LIKE '%syscacheobjects%';
-- notice that there are 4 adhoc (each of the four statements above) 
-- and still only 1 prepared (for member_no = 1234)

SELECT st.text, qs.EXECUTION_COUNT, qs.plan_handle, qs.statement_start_offset, qs.*, qp.* 
FROM sys.dm_exec_query_stats AS qs 
	CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS st
	CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
WHERE st.text LIKE '%member%' 
	AND st.text NOT LIKE '%syscacheobjects%'
ORDER BY 1, qs.EXECUTION_COUNT DESC;
-- notice that their query_plan and query_plan_hash are the same...
go

SELECT qs2.query_hash AS [Query Hash]
	, SUM(qs2.total_worker_time)/SUM(qs2.execution_count) 
		AS [Avg CPU Time]
	, COUNT(*) AS [Number of plans] 
	, MIN(qs2.statement_text) AS [Statement Text]
 FROM (SELECT qs.*, SUBSTRING(ST.text, (QS.statement_start_offset/2) + 1, 
	((CASE statement_end_offset WHEN -1 THEN DATALENGTH(st.text) 
		ELSE QS.statement_end_offset END - QS.statement_start_offset)/2) + 1) AS statement_text FROM sys.dm_exec_query_stats AS QS CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) as ST) as qs2
GROUP BY qs2.query_hash ORDER BY 2 DESC; 
GO


sp_configure 'optimize for ad hoc workloads', 1
go
reconfigure
go

SELECT m.* 
FROM dbo.member AS m
WHERE m.lastname = 'Tripper'
go

SELECT sc.[sql], sc.* 
FROM master.dbo.syscacheobjects AS sc
WHERE sc.[sql] LIKE '%member%' 
	AND sc.[sql] NOT LIKE '%syscacheobjects%';
-- notice that the new query only has a compiled plan stub
-- and notice the size of the plans (3 pages for the others and 0 pages for this one)

SELECT st.text, qp.query_plan, qs.EXECUTION_COUNT, qs.plan_handle, qs.statement_start_offset, qs.*, qp.* 
FROM sys.dm_exec_query_stats AS qs 
	CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS st
	CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
WHERE st.text LIKE '%member%' 
	AND st.text NOT LIKE '%syscacheobjects%'
ORDER BY 1, qs.EXECUTION_COUNT DESC;
go

sp_configure 'optimize for ad hoc workloads', 0
go
reconfigure
go