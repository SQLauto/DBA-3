--- Worst Plan Re-use by statement
---
--- lowest 50 Usecounts by statement
---

--- This script is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm

SELECT TOP 50
        cp.cacheobjtype
		,cp.usecounts
		,size=cp.size_in_bytes  
		,stmt_start=qs.statement_start_offset
		,stmt_end=qs.statement_end_offset
		,qt.dbid
		,qt.objectid
		,qt.text
		,SUBSTRING(qt.text,qs.statement_start_offset/2, 
			(case when qs.statement_end_offset = -1 
			then len(convert(nvarchar(max), qt.text)) * 2 
			else qs.statement_end_offset end -qs.statement_start_offset)/2) 
		as statement
		,qs.sql_handle
		,qs.plan_handle
FROM sys.dm_exec_query_stats qs
cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
inner join sys.dm_exec_cached_plans as cp on qs.plan_handle=cp.plan_handle
where cp.plan_handle=qs.plan_handle
and qt.dbid is NULL
ORDER BY [usecounts],[statement] asc
