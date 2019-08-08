---- Recompilation & SQL.sql
----     (plan_generation_num) & sql statements
---- A statement has been recompiled WHEN the plan generation number is incremented

---- This script is provided "AS IS" with no warranties, and confers no rights. 
---- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
----
select top 25
	--sql_text.text,
	sql_handle,
	plan_generation_num,
	substring(text,qs.statement_start_offset/2, 
			(case when qs.statement_end_offset = -1 
			then len(convert(nvarchar(max), text)) * 2 
			else qs.statement_end_offset end - qs.statement_start_offset)/2) 
		as stmt_executing,
	execution_count,
	dbid,
	objectid 
from sys.dm_exec_query_stats as qs
	Cross apply sys.dm_exec_sql_text(sql_handle) sql_text
where plan_generation_num >1
order by sql_handle, plan_generation_num
