

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


IF EXISTS (SELECT * FROM sys.services WHERE name = 'TestTarget')
    DROP SERVICE [TestTarget];
GO

IF EXISTS 
  (SELECT * FROM sys.service_queues WHERE name = 'TestTargetQueue')
    DROP QUEUE TestTargetQueue;
GO


-- create queues and services
CREATE QUEUE TestTargetQueue
GO

CREATE SERVICE [TestTarget]
 ON QUEUE TestTargetQueue
 ([DEFAULT])
GO

-- This will work with:
-- Dialog encryption turned off or
-- Anonymous remote service binding at initiator or
-- Named remote service binding at initiator
GRANT SEND ON SERVICE::[TestTarget] TO public
GO

-- need a route back to each remote initiator
CREATE ROUTE TestRoute WITH
	SERVICE_NAME = 'TestInitiator',
    ADDRESS = 'TCP://localhost:4321'
GO

-- determine the GUID of the TestDB database
SELECT name, service_broker_guid 
FROM master.sys.databases where name = 'TestDB'
GO

-- Create route to local service in MSDB
USE MSDB
GO

IF EXISTS(
  SELECT * FROM sys.routes 
   WHERE name = N'TestRoute'
)
DROP ROUTE TestRoute
GO

DECLARE @cmdstr NVARCHAR(255);
DECLARE @brokerguid NVARCHAR(255);
SELECT @brokerguid = service_broker_guid
  FROM sys.databases 
  WHERE name = 'TestDB';
SET @cmdstr = 
'CREATE ROUTE TestRoute WITH
   SERVICE_NAME = ''TestTarget'',
   ADDRESS = ''LOCAL'',
   BROKER_INSTANCE = ' 
+ '''' + @brokerguid + ''''
PRINT @cmdstr
EXECUTE sp_executesql @cmdstr
GO
  