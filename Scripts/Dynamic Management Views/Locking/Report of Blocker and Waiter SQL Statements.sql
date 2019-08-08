--- Report of Blocker & Waiter SQL Statements.sql
--- 
--- Long running query, locking/blocking analysis
---
--- lists the blocker and waiter sql statements
---
--- This script is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
---
select t1.resource_type
	,db_name(resource_database_id) as [database]
	,t1.resource_associated_entity_id as [blk object]
	,t1.request_mode
	,t1.request_session_id   -- spid of waiter
	,(select text from sys.dm_exec_requests as r  --- get sql for waiter
		cross apply sys.dm_exec_sql_text(r.sql_handle) where r.session_id = t1.request_session_id) as waiter_text
	,t2.blocking_session_id  -- spid of blocker
     ,(select text from sys.sysprocesses as p		--- get sql for blocker
		cross apply sys.dm_exec_sql_text(p.sql_handle) where p.spid = t2.blocking_session_id) as blocker_text
	from 
	sys.dm_tran_locks as t1, 
	sys.dm_os_waiting_tasks as t2
where 
	t1.lock_owner_address = t2.resource_address
go
