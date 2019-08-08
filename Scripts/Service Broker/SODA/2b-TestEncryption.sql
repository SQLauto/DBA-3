

USE TestDB
GO

--
-- Step 1: Start a dialog and send a message
--
--

DECLARE @h UNIQUEIDENTIFIER;
DECLARE @quantity INT;

BEGIN TRANSACTION;
BEGIN DIALOG CONVERSATION @h
 FROM SERVICE TestInitiator
 TO SERVICE 'TestTarget'
 -- encryption ON is default
 -- WITH ENCRYPTION = OFF   
;

-- 1 unit of Inv
SEND ON CONVERSATION @h (1);
COMMIT;
GO


--
-- Step 2: Receive message and return the reply
-- This happens at the target.
--

DECLARE @h UNIQUEIDENTIFIER;
DECLARE @quantity INT;

BEGIN TRANSACTION;

-- Wait up to 30 seconds for a message to arrive
WAITFOR (
RECEIVE TOP(1)
 @quantity = CAST(message_body AS int),
 @h = conversation_handle
 FROM TestTargetQueue), TIMEOUT 30000;
PRINT @quantity;
SEND ON CONVERSATION @h ('OK');
END CONVERSATION @h
COMMIT;
GO

--
-- Step 3: Receive the response and end the conversation
-- This happens at the initiator.
--

DECLARE @h UNIQUEIDENTIFIER;
DECLARE @resp VARCHAR(10);

BEGIN TRANSACTION;
-- Wait up to 30 seconds for a message to arrive
WAITFOR (
RECEIVE TOP(1)
 @resp = CAST(message_body AS VARCHAR(10)),
 @h = conversation_handle
 FROM TestInitiatorQueue), TIMEOUT 30000;
PRINT @resp;
-- You don't need to read the end conversation message
-- You can decide to unconditionally end the conversation
END CONVERSATION @h
COMMIT;
GO