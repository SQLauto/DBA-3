
-- You have to do this once per instance
-- That wants to connect to you
-- Whether you're the initiator or target

-- This allows instance SQLDEV01 to connect

:CONNECT localhost\SQLDEV02

USE MASTER
GO

IF EXISTS(
  SELECT * FROM sys.certificates 
   WHERE name = N'BrokerEPCert_SQLDEV01'
)
DROP CERTIFICATE BrokerEPCert_SQLDEV01
GO

IF  EXISTS (SELECT * FROM sys.database_principals 
	WHERE name = N'BrokerEPUser_SQLDEV01')
DROP USER [BrokerEPUser_SQLDEV01]
GO

IF  EXISTS (SELECT * FROM sys.server_principals 
	WHERE name = N'BrokerEPLogin_SQLDEV01')
DROP LOGIN [BrokerEPLogin_SQLDEV01]
GO


--create a login and a user which you eventually will assign a public
--key from the cert in the remote master db to
create login BrokerEPLogin_SQLDEV01
	with password = 'StrongPW1';
go

create user BrokerEPUser_SQLDEV01
	from login BrokerEPLogin_SQLDEV01;
go

--grant connect to the endpoint to the login
grant connect on endpoint::BrokerEndpoint_SQLDEV02 to BrokerEPLogin_SQLDEV01
go

create certificate BrokerEPCert_SQLDEV01
authorization BrokerEPUser_SQLDEV01
from file = 'c:\certs\BrokerEndpointCert_SQLDEV01_pub.cer';
go