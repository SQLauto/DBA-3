--- Locking & Serializable

--- SQL Server 2005 Performance Tuning with DMVs - T. Davidson

--- Notice key RANGE xlocks are held until the commit
--- trace flag 1211 disallows lock escalation
---
--- This script is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
---
use northwind
go
dbcc traceon(1211,-1)
go
set transaction isolation level serializable
go
begin transaction
go
select *
from [Order Details] with (rowlock)  ---,xlock)
where OrderID between 50000 and 50500
go
declare @spid int
select @spid=@@spid
exec sp_lock @spid
--commit
go