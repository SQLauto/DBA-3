
-- You only have to do this once per instance. Ever.

:CONNECT localhost\SQLDEV02

-- endpoint certs must be in master
USE MASTER
GO

IF NOT EXISTS
  (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPW1'
GO

-- Define the cert for my endpoint
-- Owned by DBO in MASTER

DECLARE @cmdstr NVARCHAR(255);
SET @cmdstr = 
'CREATE CERTIFICATE BrokerEndpointCert_SQLDEV02
WITH SUBJECT = ''BrokerEndpointCert_SQLDEV02'',
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
BACKUP CERTIFICATE BrokerEndpointCert_SQLDEV02
TO FILE = 'c:\certs\BrokerEndpointCert_SQLDEV02_pub.cer'
GO

-- create endpoint, authentication by cert
-- unless you have a good reason, encryption should be disabled

CREATE ENDPOINT BrokerEndpoint_SQLDEV02
STATE = STARTED
AS TCP
(
  LISTENER_PORT = 4567
)
FOR SERVICE_BROKER
(
  AUTHENTICATION = CERTIFICATE BrokerEndpointCert_SQLDEV02,
  ENCRYPTION = REQUIRED
);
go

--check that the endpoint has been created
select * from sys.service_broker_endpoints;
go