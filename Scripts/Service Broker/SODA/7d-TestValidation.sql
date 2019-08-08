
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

DECLARE @h UNIQUEIDENTIFIER;
DECLARE @invreq XML;
SET @invreq = '
<InventoryReq xmlns="http://www.company.com/inventoryRequest">
  <order>1</order>
  <product>1040</product>
  <units>3</units>
  <status>Req</status>
</InventoryReq>
';

BEGIN TRANSACTION;
BEGIN DIALOG CONVERSATION @h
 FROM SERVICE TestInitiator
 TO SERVICE 'TestTarget'
 ON CONTRACT InvContract
 -- ENCRYPTION = ON is the default
 WITH ENCRYPTION = OFF
;

-- 1 unit 
SEND ON CONVERSATION @h 
 MESSAGE TYPE InvRequestMsg (@invreq);
COMMIT;
GO

-- select * from sys.transmission_queue
-- receive * from TestInitiatorQueue
-- select convert(xml, message_body) from TestInitiatorQueue

--
-- Step 2: Receive message and return the reply
-- This happens at the target.
--

:CONNECT localhost\SQLDEV02
GO


USE TestDB
GO

DECLARE @h UNIQUEIDENTIFIER;
DECLARE @request_msg XML;

BEGIN TRANSACTION;
WAITFOR (
RECEIVE TOP(1)
 @request_msg = CAST(message_body AS XML),
 @h = conversation_handle
 FROM TestTargetQueue), TIMEOUT 30000;
PRINT CAST(@request_msg AS NVARCHAR(MAX));
SEND ON CONVERSATION @h 
 MESSAGE TYPE InvResponseMsg ('
<InventoryReq xmlns="http://www.company.com/inventoryRequest">
  <order>1</order>
  <product>1040</product>
  <units>3</units>
  <status>OK</status>
</InventoryReq>');
END CONVERSATION @h
COMMIT;
GO

--
-- Step 3: Receive the response and end the conversation
-- This happens at the initiator.
--

:CONNECT localhost\SQLDEV01
GO

USE TestDB
GO

DECLARE @h UNIQUEIDENTIFIER;
DECLARE @resp XML;

BEGIN TRANSACTION;
WAITFOR (
RECEIVE TOP(1)
 @resp = CAST(message_body AS XML),
 @h = conversation_handle
 FROM TestInitiatorQueue), TIMEOUT 30000;
PRINT CAST(@resp AS NVARCHAR(MAX));
-- You don't need to read the end conversation message
-- You can decide to unconditionally end the conversation
END CONVERSATION @h
COMMIT;
GO