
USE Master
GO

IF EXISTS
  (SELECT * FROM sys.databases WHERE name = 'TestDB')
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