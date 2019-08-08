
-- You have to do this once per instance
-- That wants to connect to you
-- Whether you're the initiator or target

-- This allows instance SQLDEV02 to connect

:CONNECT localhost\SQLDEV01

USE MASTER
GO

--create a login and a user which you eventually will assign a public
--key from the cert in the remote master db to

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

create login BrokerEPLogin_SQLDEV02
	with password = 'StrongPW1';
go

create user BrokerEPUser_SQLDEV02
	from login BrokerEPLogin_SQLDEV02;
go

--grant connect to the endpoint to the login
grant connect on endpoint::BrokerEndpoint_SQLDEV01 to BrokerEPLogin_SQLDEV02
go

-- public key only
create certificate BrokerEPCert_SQLDEV02
authorization BrokerEPUser_SQLDEV02
from file = 'c:\certs\BrokerEndpointCert_SQLDEV02_pub.cer';
go