
-- Restore a TDE enabled database

:CONNECT (local)\SQLDEV02

USE master;
GO

/* Take a backup if we don't have one already! Restart the backupset with INIT 

BACKUP DATABASE AdventureWorksLT
 TO DISK='C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV02\MSSQL\BACKUP\AdventureWorksLT.bak' WITH INIT;
GO

Play safe and backup log also

--BACKUP LOG AdventureWorksLT
 TO DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV02\MSSQL\BACKUP\AdventureWorksLT.trn' WITH INIT;
GO
*/

-- Then connect to the mirror and restore it, this will fail with 33111, failed to find certificate so first we need to restore it...
:CONNECT (local)\SQLDEV03

USE master;
GO

/*
Use AdventureWorksLT
go
sp_helpfile
*/ 

-- Note NORECOVERY for mirroring

RESTORE DATABASE AdventureWorksLT
   from disk='C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV02\MSSQL\BACKUP\AdventureWorksLT.bak' WITH FILE =1, NORECOVERY,
  MOVE 'AdventureWorksLT_Data' TO 'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV03\MSSQL\DATA\AdventureWorksLT_Data.LDF',
  MOVE 'AdventureWorksLT_Log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV03\MSSQL\DATA\AdventureWorksLT_Log.LDF';
  
 GO 
   
 RESTORE LOG AdventureWorksLT
  from disk='C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV02\MSSQL\BACKUP\AdventureWorksLT.trn' WITH FILE=1, NORECOVERY;
  GO
  
 -- If we need to restore the master key in order to import the certificate then we can do so using the syntax below
 -- after restore / import we would need to open the master key before importing the certificate which it was used to encrypt
 
 /*
 Use Master
 GO
 
 RESTORE MASTER KEY FROM FILE = 'C:\backupCert\dev02masterkey.pvk'
  DECRYPTION BY PASSWORD = 'P@ssw0rd' ENCRYPTION BY PASSWORD = 'P@ssw0rd';
  GO
  
  OPEN MASTER KEY DECRYPTION BY PASSWORD = 'P@ssw0rd';
  GO
  */
  
  Use Master
  GO
  
  -- I can import the old master key and open it OR just create a new master key!
  -- If I don't do this then I get an appropriate error message when trying to import the certificate...
  
  CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'P@ssw0rd2'; 
  
  CREATE CERTIFICATE MyServerCert FROM FILE = 'c:\backupCert\MyServerCert.cer'
   WITH PRIVATE KEY ( FILE = 'C:\backupCert\MyServerCert.pvk' , DECRYPTION BY PASSWORD = 'P@ssw0rd' );
  GO
  
  -- NOW RESTORE WILL WORK :)- RECOVERY VS. NORECOVERY!
   
  RESTORE DATABASE AdventureWorksLT
   from disk='C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV02\MSSQL\BACKUP\AdventureWorksLT.bak' WITH FILE=1, NORECOVERY,
  MOVE 'AdventureWorksLT_Data' TO 'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV03\MSSQL\DATA\AdventureWorksLT_Data.LDF',
  MOVE 'AdventureWorksLT_Log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV03\MSSQL\DATA\AdventureWorksLT_Log.LDF';
  
 GO 
 
 -- RECOVERY TO USE DATABASE, NORECOVERY FOR LOG RESTORES / MIRRORING...
   
 RESTORE LOG AdventureWorksLT
  from disk='C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV02\MSSQL\BACKUP\AdventureWorksLT.trn' WITH FILE=1, NORECOVERY;
  GO
  



