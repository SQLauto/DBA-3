---- Waiter_proc sql.sql
---- A block situation is set up by running blocker_proc.sql BEFORE this proc
use Northwind
go
create proc waiter_proc @OrderID int
as
--- This script is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm


select * from Orders with (holdlock)
where OrderID = @OrderID
waitfor delay '00:01:30'
---- this update will cause a deadlock if you execute blocker_proc just prior
update Orders
set ShippedDate = getdate()
where OrderID = @OrderID
go
begin tran
go
exec waiter_proc @OrderID=15000
go
rollback
go
