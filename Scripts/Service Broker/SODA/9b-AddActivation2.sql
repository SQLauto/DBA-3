
:CONNECT localhost\SQLDEV02

-- Don't forget to add database tables
-- before running this
USE TestDB
GO

IF EXISTS (SELECT * FROM sys.procedures
           WHERE name = 'decrement_inventory' AND type = 'P')
DROP PROCEDURE decrement_inventory
GO

CREATE PROCEDURE decrement_inventory
AS
DECLARE @c UNIQUEIDENTIFIER;
DECLARE @h UNIQUEIDENTIFIER;
DECLARE @m XML;
DECLARE @t NVARCHAR(128);

WHILE 1 = 1
BEGIN

BEGIN TRANSACTION
WAITFOR(
   GET CONVERSATION GROUP @c FROM TestTargetQueue),
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
		@m=CAST(message_body as XML) 
     FROM TestTargetQueue 
     WHERE conversation_group_id = @c;

    IF @@rowcount <> 1 
		BREAK;
    IF @t = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
    OR @t = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error' 
    BEGIN 
		END CONVERSATION @h;
        CONTINUE
    END
    ELSE
    IF @t = N'InvRequestMsg'
    BEGIN
		SAVE TRANSACTION afterreceive;
        DECLARE @invreq XML
		SET @invreq = @m
		-- Process message. If it gets here it's valid
		BEGIN TRY;
		-- UPDATE the Inventory table with the values extracted from the XML
        WITH XMLNAMESPACES(DEFAULT 'http://www.company.com/inventoryRequest') 
		UPDATE Inventory 
		  SET units_in_stock = units_in_stock - @invreq.value('(/InventoryReq/units)[1]', 'int') 
		  WHERE product_id = @invreq.value('(/InventoryReq/product)[1]', 'int');

		SET @invreq.modify('
		  declare default element namespace "http://www.company.com/inventoryRequest";
		  replace value of (/InventoryReq/status/text())[1] with "OK" '); 
		END TRY
		BEGIN CATCH
		  ROLLBACK TRANSACTION afterreceive
		  SET @invreq.modify('
			 declare default element namespace "http://www.company.com/inventoryRequest";
			 replace value of (/InventoryReq/status/text())[1] with "Backordered" ');
		  -- Queue up a request to the ordering system here
		END CATCH;

		SEND ON CONVERSATION @h
		 MESSAGE TYPE InvResponseMsg (@invreq);
		END CONVERSATION @h
    END
END
COMMIT TRANSACTION;
END
GO

-- 
-- Turn on activation
--

ALTER QUEUE TestTargetQueue WITH ACTIVATION 
  (STATUS=ON,
   PROCEDURE_NAME=decrement_inventory,
   MAX_QUEUE_READERS=5,
   EXECUTE AS SELF
  )
go

/*
ALTER QUEUE TestTargetQueue WITH ACTIVATION 
  (STATUS=OFF,
   PROCEDURE_NAME=decrement_inventory,
   MAX_QUEUE_READERS=5,
   EXECUTE AS SELF
  )
go
*/


