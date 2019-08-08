---- blocker_proc sql.sql
---- This script holds a lock to create a block condition
---- Run this script before Waiter_proc sql.sql
use Northwind
go
create proc blocker_proc @OrderID int
as --- This stored procedure is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
---
    select  *
    from    Orders with ( holdlock )
    where   OrderID = @OrderID
    waitfor delay '00:00:10'
--- the update will be blocked by Waiter_proc's shared lock
    update  Orders
    set     ShippedDate = getdate()
    where   OrderID = @OrderID
    waitfor delay '00:01:30'
go
--- begin a transaction
begin tran
go
exec blocker_proc @OrderID = 15000
go
--- uncomment the next statement when you are ready to rollback blocker_proc
--- rollback
go