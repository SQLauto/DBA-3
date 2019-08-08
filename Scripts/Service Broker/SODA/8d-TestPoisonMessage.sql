
-- send a message to it
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
 -- WITH ENCRYPTION = OFF
;

-- 1 unit 
SEND ON CONVERSATION @h 
 MESSAGE TYPE InvRequestMsg (@invreq);
COMMIT;
GO

-- Execute this at localhost\SQLDEV02 five times...

:CONNECT localhost\SQLDEV02
GO

USE TestDB
GO

-- After 5 rollbacks, you get this:
-- Msg 9617, Level 16, State 1, Line 6
-- The service queue "TestTargetQueue" is currently disabled.
DECLARE @h UNIQUEIDENTIFIER;
DECLARE @request_msg XML;

BEGIN TRANSACTION;
RECEIVE TOP(1)
 @request_msg = CAST(message_body AS XML),
 @h = conversation_handle
 FROM TestTargetQueue;
PRINT CAST(@request_msg AS NVARCHAR(MAX));
PRINT 'Rolling Back'
ROLLBACK;
GO

:CONNECT localhost\SQLDEV02
GO

USE TestDB
GO

-- there should be a message here
SELECT CAST(message_body AS XML) FROM PoisonQueue
GO

:CONNECT localhost\SQLDEV02
GO

USE TestDB
GO

-- If you want to turn queue back on
ALTER QUEUE TestTargetQueue WITH STATUS = ON
GO

-- Now this should work again

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

:CONNECT localhost\SQLDEV02

USE TestDB
GO

-- reset PoisonQueue, just get rid of the message
RECEIVE * FROM PoisonQueue

-- this doesn't cause the same event
ALTER QUEUE TestTargetQueue WITH STATUS = OFF
GO