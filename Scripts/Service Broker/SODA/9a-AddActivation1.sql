
-- Simple program for initiator
-- Handle errors and end conversation

:CONNECT localhost\SQLDEV01

USE TestDB
GO

IF EXISTS (SELECT * FROM sys.procedures
           WHERE name = 'inventory_response' AND type = 'P')
DROP PROCEDURE inventory_response
GO

CREATE PROCEDURE inventory_response
AS
DECLARE @c UNIQUEIDENTIFIER;
DECLARE @h UNIQUEIDENTIFIER;
DECLARE @m XML;
DECLARE @t NVARCHAR(128);

WHILE 1 = 1
BEGIN

BEGIN TRANSACTION
WAITFOR(
   GET CONVERSATION GROUP @c FROM TestInitiatorQueue),
   TIMEOUT 100 ;

IF @c IS NULL 
  BEGIN
   ROLLBACK TRANSACTION;
   BREAK;
  END

WHILE 1 = 1
BEGIN
	RECEIVE TOP(1) 
        @h=conversation_handle, 
        @t=message_type_name,
		@m=CAST(message_body as XML) FROM TestInitiatorQueue 
     WHERE conversation_group_id = @c;

    IF @@rowcount <> 1 
		BREAK;

    IF @t = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
    OR @t = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error' 
    BEGIN 
		END CONVERSATION @h;
        CONTINUE
    END

    IF @t = N'InvResponseMsg'
		BEGIN
		-- Parse the XML return message for status and update the appropriate order_line_item
		IF @m.value('declare default element namespace "http://www.company.com/inventoryRequest";
			(/InventoryReq/status)[1]', 'varchar(10)') = 'OK'
	       BEGIN
			UPDATE order_line_item SET in_stock = 1 
				  WHERE order_id = @m.value('declare default element namespace "http://www.company.com/inventoryRequest";
				(/InventoryReq/order)[1]', 'int') 
				  AND product_id = @m.value('declare default element namespace "http://www.company.com/inventoryRequest";
				(/InventoryReq/product)[1]', 'int');
		   -- diagnostic, comment out in production
		   -- PRINT N'Got OK Message';
           END;
		ELSE
           BEGIN
		   UPDATE order_line_item SET in_stock = 0 
			  WHERE order_id = @m.value('declare default element namespace "http://www.company.com/inventoryRequest";
			(/InventoryReq/order)[1]', 'int') 
			  AND product_id = @m.value('declare default element namespace "http://www.company.com/inventoryRequest";
			(/InventoryReq/product)[1]', 'int')
		   -- diagnostic, comment out in production
		   -- PRINT N'Got Not OK Message';
           END
		END

END
COMMIT TRANSACTION;
END
go

ALTER QUEUE TestInitiatorQueue WITH ACTIVATION 
  (STATUS=ON,
   PROCEDURE_NAME=inventory_response,
   MAX_QUEUE_READERS=5,
   EXECUTE AS SELF
  )
go