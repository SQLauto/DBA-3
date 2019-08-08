
-- You only have to do this once per instance. Ever.

:CONNECT localhost\SQLDEV01

-- endpoint certs must be in MASTER
USE MASTER
GO

IF NOT EXISTS
  (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPW1'
GO

-- Define cert for my endpoint
-- Owned by DBO in MASTER

DECLARE @cmdstr NVARCHAR(255);
SET @cmdstr = 
'CREATE CERTIFICATE BrokerEndpointCert_SQLDEV01
WITH SUBJECT = ''BrokerEndpointCert_SQLDEV01'',
START_DATE = ' + '''' 
+ convert(NVARCHAR(10), dateadd(day, -3, getdate()), 101)
+ ''''
PRINT @cmdstr
EXECUTE sp_executesql @cmdstr
GO

--
-- Back the certificate up to a file
-- This only backs up the public key, not the private key
--
BACKUP CERTIFICATE BrokerEndpointCert_SQLDEV01
TO FILE = 'c:\certs\BrokerEndpointCert_SQLDEV01_pub.cer'
GO

-- create endpoint, authentication by cert
-- unless you have a good reason, encryption should be disabled

CREATE ENDPOINT BrokerEndpoint_SQLDEV01
STATE = STARTED
AS TCP
(
  LISTENER_PORT = 4321
)
FOR SERVICE_BROKER
(
  AUTHENTICATION = CERTIFICATE BrokerEndpointCert_SQLDEV01,
  ENCRYPTION = REQUIRED
);
go

--check that the endpoint has been created
select * from sys.service_broker_endpoints;
go