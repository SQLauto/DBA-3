USE SBroker;
GO

-- Create a table to receive log entries
CREATE TABLE dbo.ApplicationLog 
  ( LogID INTEGER IDENTITY(1,1),
    Details XML,
    UserState int
  );
GO

-- Create a procedure to write log entries
CREATE PROCEDURE dbo.WriteLogEntry
  @Details NVARCHAR(100),
  @UserState int = NULL
AS
  SET NOCOUNT ON;
  INSERT dbo.ApplicationLog (Details,UserState)
    VALUES(NCHAR(0xFEFF) 
           + '<LogEntry>' + @Details + '</LogEntry>',@UserState);
GO

-- Test the procedure
DELETE FROM dbo.ApplicationLog;

EXEC dbo.WriteLogEntry @Details = 'Synchronous Hello',@UserState = 1;

SELECT * FROM dbo.ApplicationLog ORDER BY LogID;
GO


-- Change the log entry process to asynchronous mode 
-- using Service Broker

USE master;
GO

-- Enable Service Broker for the database
-- NOTE: this needs a database-level lock
ALTER DATABASE SBroker SET ENABLE_BROKER;
GO

USE SBroker;
GO

-- Create a message to hold the log messages
CREATE MESSAGE TYPE [MessageTypes/LogMessage]
       VALIDATION = WELL_FORMED_XML;
GO

-- Create a contract to define the log message conversation rules
CREATE CONTRACT [MessageContracts/LogContract]
  ([MessageTypes/LogMessage] SENT BY INITIATOR
  );
GO

-- Create a procedure to read queue entries and log them
CREATE PROCEDURE dbo.ProcessLogEntry
AS
  DECLARE @Message NVARCHAR(MAX);
  DECLARE @DialogHandle UNIQUEIDENTIFIER;
  DECLARE @MessageType NVARCHAR(256);

  SET NOCOUNT ON;

  -- note that we should process multiple entries here, etc.
  RECEIVE TOP(1) @DialogHandle = conversation_handle,
                 @Message = message_body,
                 @MessageType = message_type_name
    FROM LogEntryQueue;

  IF (@@ROWCOUNT = 0) RETURN;

  -- note that the code here should deal with other message types
  IF @MessageType = 'MessageTypes/LogMessage'
    INSERT dbo.ApplicationLog (Details) VALUES(@Message);

  END CONVERSATION @DialogHandle;
GO

-- Create the queue to store the entries
CREATE QUEUE LogEntryQueue
  WITH STATUS = ON,
  ACTIVATION (STATUS = ON,
              PROCEDURE_NAME = dbo.ProcessLogEntry,
              MAX_QUEUE_READERS = 1,
              EXECUTE AS SELF);
GO

-- Create the service to process the queue
CREATE SERVICE [Services/LogService]
  ON QUEUE LogEntryQueue ([MessageContracts/LogContract]);
GO

-- Modify our log entry writing procedure
-- to use a Service Broker conversation
ALTER PROCEDURE dbo.WriteLogEntry
  @Details NVARCHAR(100)
AS
  DECLARE @DialogHandle UNIQUEIDENTIFIER;
  
  SET NOCOUNT ON;

  BEGIN DIALOG CONVERSATION @DialogHandle
    FROM SERVICE [Services/LogService]
    TO SERVICE 'Services/LogService'
    ON CONTRACT [MessageContracts/LogContract];

  SEND ON CONVERSATION @DialogHandle
    MESSAGE TYPE [MessageTypes/LogMessage]
    (NCHAR(0xFEFF) + '<LogEntry>' + @Details + '</LogEntry>');
    
  END CONVERSATION @DialogHandle;
GO

-- Test the procedure again
DELETE FROM dbo.ApplicationLog;
GO

EXEC dbo.WriteLogEntry @Details = 'Asynchronous Hello';
GO

SELECT * FROM dbo.ApplicationLog;
GO

-- Where did our entry go?
-- > check the application log on the system

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Very secret stuff';
GO

-- Test the procedure again
DELETE FROM dbo.ApplicationLog;
GO

EXEC dbo.WriteLogEntry @Details = 'Asynchronous Hello';
GO

SELECT * FROM dbo.ApplicationLog;
GO

USE master;
GO
