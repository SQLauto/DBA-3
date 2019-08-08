
:CONNECT localhost\SQLDEV01

USE MASTER
GO

DROP DATABASE TestDB
GO

-- you must drop endpoint
-- before dropping the cert that secures it
IF EXISTS (
	SELECT name from sys.service_broker_endpoints WHERE name = N'BrokerEndpoint_SQLDEV01'
)
	DROP ENDPOINT BrokerEndpoint_SQLDEV01
GO

IF EXISTS(
  SELECT * FROM sys.certificates 
   WHERE name = N'BrokerEndpointCert_SQLDEV01'
)
DROP CERTIFICATE BrokerEndpointCert_SQLDEV01
GO

-- Drop the proxies

IF EXISTS(
  SELECT * FROM sys.certificates 
   WHERE name = N'BrokerEPCert_SQLDEV02'
)
DROP CERTIFICATE BrokerEPCert_SQLDEV02
GO

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'BrokerEPUser_SQLDEV02')
DROP USER [BrokerEPUser_SQLDEV02]
GO

IF  EXISTS (SELECT * FROM sys.server_principals WHERE name = N'BrokerEPLogin_SQLDEV02')
DROP LOGIN [BrokerEPLogin_SQLDEV02]
GO

PRINT 'Don''t forget to delete the contents of c:\certs'
GO