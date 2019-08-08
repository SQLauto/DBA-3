--- Locking & Reads

--- SQL Server 2005 Performance Tuning with DMVs - T. Davidson

--- Compare Locking & Repeatable Reads.sql and
---	    Locking & Serializable.sql
---
--- What kind of locks are held?  Key vs. Range
--- (1) Range (Serializable) disallows inserting in the range.
--- (2) Key locks (Repeatable Read) allows inserts (phantoms).
---
--- This stored procedure is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
---
begin tran
go
select count(*)
from [Order Details]
where OrderID between 50000 and 50500
go
commit
-- rollback