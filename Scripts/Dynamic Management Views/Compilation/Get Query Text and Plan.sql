--- Get Query Text and Plan.sql
--- provide the sql_handle and plan_handle to retrieve the sql text & xml plan

-- This stored procedure is provided "AS IS" with no warranties, and confers no rights. 
-- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
--
select 
(select text from sys.dm_exec_sql_text(put_sql_handle_here)) as sql_text
,(select query_plan from sys.dm_exec_query_plan(put_plan_handle_here)) as query_plan
go