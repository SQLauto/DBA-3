--- Locking & Inserts

--- SQL Server 2005 Performance Tuning with DMVs - T. Davidson

--- Compare Locking & Repeatable Reads.sql and
---	    Locking & Serializable.sql
---
--- What kind of locks are held?  Key vs. Range
--- (1) Range (Serializable) disallows inserting in the range.
--- (2) Key locks (Repeatable Read) allows inserts (phantoms).

-- This script is provided "AS IS" with no warranties, and confers no rights. 
-- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
--
set lock_timeout 5000
go
begin tran
go
Insert into [Order Details]
values (50001,51,42.00,10,0)
go
-- rollback