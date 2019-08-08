
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
-- Step 1: create the initiator side
--

IF EXISTS (SELECT * FROM sys.services WHERE name = 'TestInitiator')
    DROP SERVICE TestInitiator;
GO

IF EXISTS 
  (SELECT * FROM sys.service_queues WHERE name = 'TestInitiatorQueue')
    DROP QUEUE TestInitiatorQueue;
GO


-- create queues and services
CREATE QUEUE TestInitiatorQueue
GO

CREATE SERVICE TestInitiator
 ON QUEUE TestInitiatorQueue
 ([DEFAULT])
GO

-- No remote service binding and no user for cert
-- This means:
--   No dialog authentication or encryption
--   All Conversations must be ENCRYPTION OFF 
--   Target must GRANT CONNECT to public


CREATE ROUTE TestRoute WITH
	SERVICE_NAME = 'TestTarget',
    ADDRESS = 'TCP://localhost:4567'
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
   SERVICE_NAME = ''TestInitiator'',
   ADDRESS = ''LOCAL'',
   BROKER_INSTANCE = ' 
+ '''' + @brokerguid + ''''
PRINT @cmdstr
EXECUTE sp_executesql @cmdstr
GO
