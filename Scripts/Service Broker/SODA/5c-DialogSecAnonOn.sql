
-- Setting up Dialog Security

-- Configure the target first

:CONNECT localhost\SQLDEV02

USE TestDB
GO

IF NOT EXISTS
  (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPW1'
GO

-- Configure a special user to own the cert
-- If all SERVICEs in same database are the same
-- security-wise, you can have one cert for all SERVICEs 
-- owned by DBO

CREATE USER TestTargetUser WITHOUT LOGIN
GO

GRANT CONTROL ON SERVICE::TestTarget TO TestTargetUser
GO

GRANT SEND ON SERVICE::TestTarget TO public
GO

DECLARE @cmdstr NVARCHAR(255);
SET @cmdstr = 
'CREATE CERTIFICATE TestTargetCert
AUTHORIZATION TestTargetUser
WITH SUBJECT = ''TestTargetCert'',
START_DATE = ' + '''' 
+ convert(NVARCHAR(10), dateadd(day, -3, getdate()), 101)
+ '''' + ' ACTIVE FOR BEGIN_DIALOG = ON;'
PRINT @cmdstr
EXECUTE sp_executesql @cmdstr
GO

--
-- Back the certificate up to a file
-- This only backs up the public key, not the private key
--
BACKUP CERTIFICATE TestTargetCert
TO FILE = 'c:\certs\TestTargetCert_pub.cer'
GO

-- Now configure the initiator
-- Specifying ENCRYPTION=ON requires dialog security

:CONNECT localhost\SQLDEV01
GO

USE TestDB
GO

IF NOT EXISTS
  (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPW1'
GO

--
-- Step 1-Install Certs:
-- Create a user in this database (without login or any other priv)
--

CREATE USER TestTargetProxy_SQLDEV02 WITHOUT LOGIN
GO


--
-- The user owns a certificate created by using
-- the public key only-portion from the partner's database
--

CREATE CERTIFICATE TestTargetProxyCert
AUTHORIZATION TestTargetProxy_SQLDEV02
FROM FILE = 'c:\certs\TestTargetCert_pub.cer'
GO

-- CREATE A REMOTE SERVICE BINDING 
-- with ANONYMOUS=ON
-- Remote Service Bindings tie proxy users to services
-- Remote Service Bindings are needed for the initiator ONLY

-- With this one, the other side needs to give
-- SEND privilege on the SERVICE TO PUBLIC
-- Because ANONYMOUS=ON does not send proxy identity
CREATE REMOTE SERVICE BINDING TestTargetBinding
TO SERVICE 'TestTarget' 
WITH USER = TestTargetProxy_SQLDEV02,
ANONYMOUS=ON
GO