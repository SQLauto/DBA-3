

-- Test the transport route

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
DECLARE @quantity INT;

BEGIN TRANSACTION;
BEGIN DIALOG CONVERSATION @h
 FROM SERVICE [TCP://localhost:4321]
 TO SERVICE 'TCP://localhost:4567'
 WITH ENCRYPTION = OFF;

-- 1 unit of Inv
SEND ON CONVERSATION @h (1);
COMMIT;
PRINT 'Message Sent'
GO

-- For debugging if message doesn't appear at target
-- select * from sys.transmission_queue
-- select convert(xml,message_body) from TransportInitQueue
GO

--
-- Step 2: Receive message and return the reply
-- This happens at the target.
--

:CONNECT localhost\SQLDEV02
GO

USE TestDB
GO

DECLARE @h UNIQUEIDENTIFIER;
DECLARE @quantity INT;

BEGIN TRANSACTION;
WAITFOR (
RECEIVE TOP(1)
 @quantity = CAST(message_body AS int),
 @h = conversation_handle
 FROM TransportTargetQueue), TIMEOUT 30000;
PRINT @quantity;
SEND ON CONVERSATION @h ('OK');
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
DECLARE @resp VARCHAR(10);

BEGIN TRANSACTION;
WAITFOR (
RECEIVE TOP(1)
 @resp = CAST(message_body AS VARCHAR(10)),
 @h = conversation_handle
 FROM TransportInitQueue), TIMEOUT 30000;
PRINT @resp;
-- You don't need to read the end conversation message
-- You can decide to unconditionally end the conversation
END CONVERSATION @h
COMMIT;
GO

-- select * from sys.conversation_endpoints