/*============================================================================
  File:     DropTableAndRecoverToPointInTime.sql

  Summary:  How do you recover from a dropped table?
  
  Date:     August 2008

  SQL Server Version: 10.0.2531.0 (SQL Server 2008 SP1)
------------------------------------------------------------------------------
  Written by Kimberly L. Tripp & Paul S. Randal, SQLskills.com

  For more scripts and sample code, check out 
    http://www.SQLskills.com

  This script is intended only as a supplement to demos and lectures
  written/presented by SQLskills.com  
  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

------------------------------------------------------------------------------
-- ** STEP 1 Begin **
------------------------------------------------------------------------------
-- Delete backup history for SalesDB database
USE msdb;
GO

EXEC sp_delete_database_backuphistory 'SalesDB';
GO

-- Create a new full backup to use as the base for restore operations
USE master;
GO

BACKUP DATABASE SalesDB 
	TO DISK = N'C:\SQLSkills\SalesDBBackup.bak'
	WITH NAME = N'Full Database Backup',
	DESCRIPTION = 'Starting point for recovery',
	INIT,
	STATS = 10;
GO
------------------------------------------------------------------------------
-- ** STEP 1 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** STEP 2 Begin **
------------------------------------------------------------------------------
USE SalesDB;
GO

SELECT count(*) AS "Row Count"
	FROM Sales 
	WITH (READUNCOMMITTED);
GO
-- Saved Row Count: 

SELECT getdate() AS "Date";
GO
-- Saved Date: 
------------------------------------------------------------------------------
-- ** STEP 2 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** STEP 3 Begin **
------------------------------------------------------------------------------
-- Simulate a user dropping the unprotected table.
DROP TABLE Sales;
GO
------------------------------------------------------------------------------
-- ** STEP 3 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** STEP 4 Begin **
------------------------------------------------------------------------------
-- Examine the database file structure.
EXEC sp_helpfile;
GO
------------------------------------------------------------------------------
-- ** STEP 4 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** STEP 5 Begin **
------------------------------------------------------------------------------
-- Take the database offline for regular users.
USE master;
GO

ALTER DATABASE SalesDB
	SET RESTRICTED_USER
	WITH ROLLBACK IMMEDIATE;
GO
------------------------------------------------------------------------------
-- ** STEP 5 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** STEP 6 Begin **
------------------------------------------------------------------------------
-- Backup the tail of the log
BACKUP LOG SalesDB 
	TO DISK = N'C:\SQLskills\SalesDBBackup.bak'
	WITH NAME = N'Transaction Log Backup',
	DESCRIPTION = 'Getting everything to current point in time.', 
	STATS = 10;
GO
------------------------------------------------------------------------------
-- ** STEP 6 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** STEP 7 Begin **
------------------------------------------------------------------------------
-- See what backups we have
RESTORE HEADERONLY FROM
	DISK = N'C:\SQLskills\SalesDBBackup.bak';
GO
------------------------------------------------------------------------------
-- ** STEP 7 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** STEP 8 Begin **
------------------------------------------------------------------------------
USE master;
GO

RESTORE DATABASE SalesDB
	FROM DISK = N'C:\SQLskills\SalesDBBackup.bak'
	WITH NORECOVERY;
GO

RESTORE LOG SalesDB
	FROM DISK = N'C:\SQLskills\SalesDBBackup.bak'
	WITH FILE = 2,
	STOPAT = '????',
	RECOVERY;
GO
------------------------------------------------------------------------------
-- ** STEP 8 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** STEP 9 Begin **
------------------------------------------------------------------------------
-- See how many rows existed at the restore time.
USE SalesDB;
GO

SELECT count(*) AS "Row Count"
	FROM Sales 
	WITH (READUNCOMMITTED);
GO
-- Saved Row Count : 

SELECT max(SalesID) AS "Max SalesID"
	FROM Sales 
	WITH (READUNCOMMITTED);
GO
-- Saved Max SalesID : 
------------------------------------------------------------------------------
-- ** STEP 9 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** STEP 10 Begin **
------------------------------------------------------------------------------
-- Reseed the identity value, creating a gap so that we can let users back in.
DBCC CHECKIDENT ('Sales', RESEED, 7000000);
GO

USE master;
GO

-- Let users back into the database.
ALTER DATABASE SalesDB
	SET MULTI_USER;
GO
------------------------------------------------------------------------------
-- ** STEP 10 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** STEP 11 Begin **
------------------------------------------------------------------------------
-- Examine the backups to see what the time interval is we need to consider.
SELECT [Name],
	Backup_Start_Date, 
	Backup_Finish_Date, 
	[Description],
	First_LSN, 
	Last_LSN, 
	* -- get all of the columns
FROM msdb.dbo.backupset AS s
    JOIN msdb.dbo.backupmediafamily AS m
        ON s.media_set_id = m.media_set_id
WHERE database_name = 'SalesDB'
ORDER BY 1 ASC;
GO
------------------------------------------------------------------------------
-- ** STEP 11 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** STEP 12 Begin **
------------------------------------------------------------------------------
-- Move forward a little bit through the transaction log using STOPAT and STANDBY.
USE master;
GO

RESTORE DATABASE [SalesDB_Investigate] 
FROM DISK = N'C:\SQLskills\SalesDBBackup.bak' 
WITH FILE = 1,  
	MOVE N'SalesDBData' TO N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV01\MSSQL\DATA\SalesDBData_Investigate.mdf',  
	MOVE N'SalesDBLog' TO N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV01\MSSQL\DATA\SalesDBLog_Investigate.ldf',  
	STANDBY = N'C:\SQLskills\SalesDB_UNDO.bak',
	STOPAT = '????',
	STATS;
GO

RESTORE LOG [SalesDB_Investigate] 
FROM DISK = N'C:\SQLskills\SalesDBBackup.bak' 
WITH FILE = 2,
	STANDBY = N'C:\SQLskills\SalesDB_UNDO.bak',
	STOPAT = '????',
	STATS;
GO

-- Examine the temporary database to see whether we found any more records.
SELECT max(SalesID) as "Max SalesID"
	FROM SalesDB_investigate.dbo.Sales 
	WITH (READUNCOMMITTED);
GO
-- Saved Max SalesID: 
------------------------------------------------------------------------------
-- ** STEP 12 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** STEP 13 Begin **
------------------------------------------------------------------------------
-- Now move forward a little bit further...
USE master;
GO

RESTORE LOG [SalesDB_Investigate] 
FROM DISK = N'C:\SQLskills\SalesDBBackup.bak' 
WITH FILE = 2,
	STANDBY = N'C:\SQLskills\SalesDB_UNDO.bak',
	STOPAT = '????',
	STATS;
GO

-- See if we found any more records.
SELECT max(SalesID) as "Max SalesID"
	FROM SalesDB_investigate.dbo.Sales 
	WITH (READUNCOMMITTED);
GO
-- Saved Max SalesID: 
------------------------------------------------------------------------------
-- ** STEP 13 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** STEP 14 Begin **
------------------------------------------------------------------------------
-- Examine the recovered rows to ensure they are valid.
SELECT *
	FROM SalesDB_investigate.dbo.Sales AS R
	WHERE R.SalesID > ????;
GO
------------------------------------------------------------------------------
-- ** STEP 14 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** STEP 15 Begin **
------------------------------------------------------------------------------
-- Copy the recovered records back to the SalesDB database.

-- Ensure that explicit identity values are not recalculated.
SET IDENTITY_INSERT SalesDB.dbo.Sales ON;
GO

-- Copy the records.
INSERT SalesDB.dbo.Sales
		( SalesID
		, SalesPersonID
		, CustomerID
		, ProductID
		, Quantity)
SELECT *
	FROM SalesDB_investigate.dbo.Sales AS R
WHERE R.SalesID > ????;
GO
------------------------------------------------------------------------------
-- ** STEP 15 End **
------------------------------------------------------------------------------
