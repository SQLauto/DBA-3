/* Encrypt a database */

use master
go

-- Backup Service Master Key, SMK is required to create a Database Master Key
-- SMK created by SQL during Setup or at first creation of Master Key

BACKUP SERVICE MASTER KEY TO FILE = 'c:\backupcert\dev02servicekey.pvk'
    ENCRYPTION BY PASSWORD = 'P@ssw0rd'
    
-- Create the Database Master Key - One for each database, one in Master is used for TDE

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'P@ssw0rd'; 

-- Backup the database master key in case we need to restore it to another server
-- for TDE we can restore and then open it and then restore the certificate used to
-- protect the DEK OR we can create a new Master key at the target instance master
-- and then restore the certificate

BACKUP MASTER KEY TO FILE = 'c:\backupcert\dev02masterkey.pvk'
    ENCRYPTION BY PASSWORD = 'P@ssw0rd';
    
/* Some useful encryption related queries    
select * from sys.key_encryptions
select * from sys.asymmetric_keys
select * from sys.certificates
select * from sys.crypt_properties
select * from sys.cryptographic_providers
select * from sys.dm_database_encryption_keys
*/


-- Now that we have a Master Key we can create a certificate, which is required to create a DEK
-- If you leave off encyption by password then the database master key is used to encrypt the certificate
-- IF WE USE A PASSWORD THEN WE DON'T NEED A MASTER KEY!


CREATE CERTIFICATE MyServerCert
   --ENCRYPTION BY PASSWORD = 'P@ssw0rd'   
   WITH SUBJECT = 'This is a test certificate';
   
--DROP Certificate MyServerCert;   
   
-- Backup certificate and associated Private Key.
-- If we used a password when we created the certificate then we need to provide it as the decryption clause.

BACKUP CERTIFICATE MyServerCert TO FILE = 'c:\backupcert\MyServerCert.cer' 
WITH PRIVATE KEY ( FILE = 'c:\backupcert\MyServerCert.pvk' ,
 ENCRYPTION BY PASSWORD = 'P@ssw0rd');
 --DECRYPTION BY PASSWORD =  'P@ssw0rd');

-- OK, now we have a Service Master Key, A Database Master Key for Master and a Certificate, all backed up...


Use AdventureWorksLT
Go

-- Create a DEK using the above certificate in the target database to be encrypted.

CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_128
ENCRYPTION BY SERVER CERTIFICATE MyServerCert;
GO

-- Create a table put some data in it and then look at it

CREATE TABLE tblEncrypt ( Col1 int, Col2 varchar(20) );
GO

-- step 5a
-- Insert some sample data in the Table with identifiable pattern in this case KATMAI
SET NOCOUNT ON;
DECLARE @i int;
SET @i = 0;
WHILE (@i < 200)
	BEGIN
		INSERT INTO tblEncrypt VALUES (@i, 'KATMAI')
		SET @i = @i+1
	END
SET NOCOUNT OFF;

select * from tblEncrypt;

-- Turn on TDE for the database
Use master
Go

ALTER DATABASE AdventureWorksLT SET ENCRYPTION ON;
GO

/* Can still access and select but using say List.Exe you will find that database is now encrypted!

ALTER DATABASE AdventureWorksLT SET OFFLINE;
GO

...Run list.exe against .mdf ...

ALTER DATABASE AdventureWorksLT SET Online;
GO
*/

Use AdventureWorksLT
Go

Select * from tblEncrypt;

SELECT DB_NAME(database_id) ,* FROM sys.dm_database_encryption_keys;
