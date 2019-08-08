-- Moving tempdb

-- Check where the files are
SELECT name, physical_name
FROM sys.master_files
WHERE database_id = DB_ID('tempdb');
GO

-- Move the files
USE master;
GO

ALTER DATABASE tempdb MODIFY FILE (NAME = tempdev, 
   FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL10.MSSQLSERVER\MSSQL\DATA\tempdb.mdf',  SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 5MB);
GO

ALTER DATABASE tempdb MODIFY FILE (NAME = tempdb2, 
   FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL10.MSSQLSERVER\MSSQL\DATA\tempdb2.mdf',  SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 5MB);
GO

ALTER DATABASE  tempdb MODIFY FILE (NAME = templog, FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL10.MSSQLSERVER\MSSQL\DATA\templog.ldf');
GO

-- MAYBE ADD... PJM

ALTER Database tempdb ADD FILE ( NAME = tempdb2,  FILENAME = 'c:\SQLSkills\tempdb2.mdf',  SIZE = 5MB,  MAXSIZE = 100MB,  FILEGROWTH = 5MB);


-- Restart the services

--shutdown with nowait

-- Make sure it's moved
SELECT name, physical_name
FROM sys.master_files
WHERE database_id = DB_ID('tempdb');
GO

sp_helpfile 'tempdb'

-- make sure to delete the original files