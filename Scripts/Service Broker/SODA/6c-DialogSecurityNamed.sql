
:CONNECT localhost\SQLDEV02

USE TestDB
GO

REVOKE SEND ON SERVICE::TestTarget TO public
GO

:CONNECT localhost\SQLDEV01

USE TestDB
GO

IF NOT EXISTS
  (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPW1'
GO

-- This certificate is owned by DBO
-- Who is also the owner of the SERVICE

DECLARE @cmdstr NVARCHAR(255);
SET @cmdstr = 
'CREATE CERTIFICATE TestInitiatorCert
WITH SUBJECT = ''TestInitiatorCert'',
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
BACKUP CERTIFICATE TestInitiatorCert
TO FILE = 'c:\certs\TestInitiatorCert_pub.cer'
GO

DROP REMOTE SERVICE BINDING TestTargetBinding
GO

CREATE REMOTE SERVICE BINDING TestTargetBindingNamed
TO SERVICE 'TestTarget' 
WITH USER = TestTargetProxy_SQLDEV02,
ANONYMOUS=OFF
GO

SELECT * FROM sys.remote_service_bindings
GO

-- The message will be sent using the NEWEST certificate owned by
-- the service owner (which is DBO). 
-- DBO only ones one certificate currently
SELECT C.* FROM sys.certificates C
JOIN sys.database_principals P
  ON P.principal_id = C.principal_id
WHERE P.name = 'dbo'    
GO

:CONNECT localhost\SQLDEV02

-- There must be a proxy user in the database
-- This user must own the certificate 
-- and have SEND on the SERVICE

USE TestDB
GO

CREATE USER TestInitiatorProxy_SQLDEV01 WITHOUT LOGIN
GO

--
-- The user owns a certificate created by using
-- the public key only-portion from the partner's database
--
CREATE CERTIFICATE TestInitiatorProxyCert
AUTHORIZATION TestInitiatorProxy_SQLDEV01
FROM FILE = 'c:\certs\TestInitiatorCert_pub.cer'
GO

-- Grant SEND to the user
GRANT SEND ON SERVICE::TestTarget TO TestInitiatorProxy_SQLDEV01
GO
