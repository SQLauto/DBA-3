

-- Test by:
--   Send message 
--   Read message, send response, end conversation
--   Receive response, end conversation

--
-- Step 1: Start a dialog and send a message
--
--

:CONNECT localhost\SQLDEV01
GO

USE TestDB
GO

--
-- We're replacing a 
-- Traditional transaction update orders and inventory 
-- at the same time, in the same instance
--
/*
DECLARE @orderform XML

BEGIN TRANSACTION
	INSERT INTO orders VALUES(347, GETDATE()) 
    SET @orderid = SCOPE_IDENTITY();
    -- one for each line item 
    INSERT INTO order_line_item VALUES(@orderid, 1040, 3, 500.00, 0);
    -- orderform is NULL for test
    INSERT INTO order_form VALUES(@orderid, @orderform);

	UPDATE	inventory 
	SET		units_in_stock = units_in_stock - 3
	WHERE	product_id = 1040;
COMMIT
go

SELECT * FROM inventory
go

*/

-- END TRADITIONAL TRANSACTION

IF EXISTS (SELECT * FROM sys.procedures
           WHERE name = 'update_inventory' AND type = 'P')
DROP PROCEDURE update_inventory
GO

-- Encapsulate the broker step into a stored procedure
CREATE PROCEDURE update_inventory(@order_id BIGINT, @product_id INT, @units_ordered INT)
AS
DECLARE @h UNIQUEIDENTIFIER;
DECLARE @invreq XML;

-- Use Query Method to create XML
DECLARE @empty XML;
SET @empty = ''
SET @invreq = @empty.query('
 declare default element namespace "http://www.company.com/inventoryRequest";
<InventoryReq>
  <order>{sql:variable("@order_id")}</order>
  <product>{sql:variable("@product_id")}</product>
  <units>{sql:variable("@units_ordered")}</units>
  <status>Req</status>
</InventoryReq>
')

BEGIN TRY
BEGIN TRANSACTION;
BEGIN DIALOG CONVERSATION @h
 FROM SERVICE TestInitiator
 TO SERVICE 'TestTarget'
 ON CONTRACT InvContract
 WITH ENCRYPTION = OFF;

-- request for product 1040
SEND ON CONVERSATION @h 
 MESSAGE TYPE InvRequestMsg (@invreq);
COMMIT;
END TRY
BEGIN CATCH
	PRINT ERROR_MESSAGE()
    ROLLBACK;
END CATCH
GO

--
-- Rewrite initiator for process into procedure
--

DECLARE @i INT
SET @i = 1
WHILE @i < 2
 BEGIN
   DECLARE @orderform XML
   DECLARE @orderid BIGINT
   BEGIN TRANSACTION
   INSERT INTO orders VALUES(347, GETDATE())
   SET @orderid = SCOPE_IDENTITY();
   -- one for each line item 
   INSERT INTO order_line_item VALUES(@orderid, 1040, 3, 500.00, NULL);
   -- orderform is NULL for test
   INSERT INTO order_form VALUES(@orderid, @orderform);
   EXECUTE update_inventory @orderid, 1040, 3
   COMMIT
   SET @i = @i + 1
 END
go

-- select * from sys.transmission_queue
-- select * from TestInitiatorQueue
-- select * from sys.conversation_endpoints

--
-- Step 2: Check that inventory has been reduced
-- This happens at the target.
--

:CONNECT localhost\SQLDEV02
GO

USE TestDB
GO

-- select * from sys.transmission_queue
-- select * from TestTargetQueue
-- select * from sys.conversation_endpoints

SELECT * FROM dbo.Inventory
WHERE Product_ID = 1040
GO

:CONNECT localhost\SQLDEV01
GO

USE TestDB
GO

SELECT * FROM orders
SELECT * FROM order_line_item
