
:CONNECT localhost\SQLDEV02

IF EXISTS
  (SELECT * FROM sys.databases WHERE name = 'TestDB')
DROP DATABASE TestDB
GO

CREATE DATABASE TestDB
GO

USE TestDB
GO

--
-- Step 1: create the target side
--

CREATE ROUTE TransportRoute WITH ADDRESS = N'TRANSPORT'
GO

IF EXISTS (SELECT * FROM sys.services WHERE name = 'TCP://localhost:4567')
    DROP SERVICE [TCP://localhost:4567];
GO

IF EXISTS 
  (SELECT * FROM sys.service_queues WHERE name = 'TransportTargetQueue')
    DROP QUEUE TransportTargetQueue;
GO


-- create queues and services
CREATE QUEUE TransportTargetQueue
GO

CREATE SERVICE [TCP://localhost:4567]
 ON QUEUE TransportTargetQueue
 ([DEFAULT])
GO

GRANT SEND ON SERVICE::[TCP://localhost:4567] TO public
GO