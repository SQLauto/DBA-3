
:CONNECT localhost\SQLDEV01

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

IF EXISTS (SELECT * FROM sys.services WHERE name = 'TCP://localhost:4321')
    DROP SERVICE [TCP://localhost:4321];
GO

IF EXISTS 
  (SELECT * FROM sys.service_queues WHERE name = 'TransportInitQueue')
    DROP QUEUE TransportInitQueue;
GO


-- create queues and services
CREATE QUEUE TransportInitQueue
GO

CREATE SERVICE [TCP://localhost:4321]
 ON QUEUE TransportInitQueue
 ([DEFAULT])
GO