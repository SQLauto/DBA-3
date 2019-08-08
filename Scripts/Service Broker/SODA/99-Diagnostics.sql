
-- 
-- Diagnostic queries
--
--

SELECT * FROM TestTargetQueue
SELECT * FROM TestInitiatorQueue

SELECT * FROM sys.transmission_queue

SELECT * FROM sys.conversation_endpoints

-- How many rows SELECTED?
SELECT * FROM TestTargetQueue
GO

-- How many rows RECEIVED?
RECEIVE * FROM TestTargetQueue
GO

-- Diagnostic procedure
-- Get last transmission status for handle
-- Pass in handle is pass NULL if there is only one message
-- on transmission queue
--
CREATE PROCEDURE get_status_for_handle (
  @h UNIQUEIDENTIFIER = NULL
)
AS
BEGIN
IF (@h IS NULL)
  -- read first conversation handle from transmission_queue
  SELECT TOP(1)
   @h = conversation_handle
   FROM sys.transmission_queue;

PRINT GET_TRANSMISSION_STATUS(@h);
END;
GO

EXECUTE get_status_for_handle