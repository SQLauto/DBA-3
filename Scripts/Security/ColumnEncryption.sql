USE master;
GO

IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'EncryptTest')
  DROP DATABASE EncryptTest;
GO

CREATE DATABASE EncryptTest;
GO

USE EncryptTest;
GO

CREATE SYMMETRIC KEY GregsKey
  WITH ALGORITHM = TRIPLE_DES
  ENCRYPTION BY
  PASSWORD = 'VerySecretStuff';
GO
OPEN SYMMETRIC KEY GregsKey
  DECRYPTION BY PASSWORD = 'VerySecretStuff';
GO

DECLARE @CipherData varbinary(max);

SET @CipherData = EncryptByKey(Key_GUID('GregsKey'),
                   'Text that I don''t want anyone to read');

SELECT @CipherData;

SELECT CONVERT(varchar(200),DecryptByKey(@CipherData));

CLOSE SYMMETRIC KEY GregsKey;

SELECT DecryptByKey(@CipherData);

SELECT COALESCE(DecryptByKey(@CipherData),'RESTRICTED');
GO

USE master;
GO

IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'EncryptTest')
  DROP DATABASE EncryptTest;
GO
