USE Master
GO

DROP DATABASE TestDB
GO

CREATE DATABASE TestDB
GO

USE TestDB
GO

-- 
-- Step 1:
-- CREATE the QUEUES and SERVICES for this program
--

-- Target Service
IF EXISTS (SELECT * FROM sys.services WHERE name = 'TestTarget')
    DROP SERVICE TestTarget;
GO
IF EXISTS 
  (SELECT * FROM sys.service_queues WHERE name = 'TestTargetQueue')
    DROP QUEUE TestTargetQueue;
GO

CREATE QUEUE TestTargetQueue
GO

CREATE SERVICE TestTarget
ON QUEUE TestTargetQueue
 ([DEFAULT])
GO

-- Initiator Service
IF EXISTS (SELECT * FROM sys.services WHERE name = 'TestInitiator')
    DROP SERVICE TestInitiator;
GO
IF EXISTS 
  (SELECT * FROM sys.service_queues WHERE name = 'TestInitiatorQueue')
    DROP QUEUE TestInitiatorQueue;
GO

CREATE QUEUE TestInitiatorQueue
GO

CREATE SERVICE TestInitiator
ON QUEUE TestInitiatorQueue
GO

-- You need a database master key 
-- for encrypted conversations

IF NOT EXISTS
  (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPW1'
GO