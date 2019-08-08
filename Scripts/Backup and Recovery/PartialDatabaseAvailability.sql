/*============================================================================
  File:     PartialDatabaseAvailability.sql

  Summary:  This script shows partial database
			availability

  Date:     June 2008

  SQL Server Versions:
		10.0.1600.22 (SS2008 RTM)
		9.00.3068.00 (SS2005 SP2+)
------------------------------------------------------------------------------
  Written By Paul S. Randal, SQLskills.com
  All rights reserved.

  For more scripts and sample code, check out 
    http://www.SQLskills.com

  You may alter this code for your own *non-commercial* purposes. You may
  republish altered code as long as you give due credit.
  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

-- Take a backup
USE master;
GO

BACKUP DATABASE SalesDB TO
	DISK = N'C:\SQLskills\SalesDBBackup.bak'
WITH NAME = N'Full Database Backup', 
	DESCRIPTION = 'Starting point for recovery',
	INIT, STATS = 10;
GO

-- Show data access...
-- Partition1
SELECT TOP 100 * FROM SalesDB.dbo.Sales 
	WHERE SalesID < 2000000;
GO
-- Partition2
SELECT TOP 100 * FROM SalesDB.dbo.Sales 
	WHERE SalesID >= 2000000
	AND SalesID < 4000000;
GO
-- Partition3
SELECT TOP 100 * FROM SalesDB.dbo.Sales 
	WHERE SalesID >= 4000000
	AND SalesID < 6000000;
GO
-- Partition4
SELECT TOP 100 * FROM SalesDB.dbo.Sales 
	WHERE SalesID >= 6000000
	AND SalesID < 8000000;
GO

-- Simulate disaster - shutdown and remove file 2
SHUTDOWN WITH NOWAIT;
GO

-- Use the database again
USE SalesDB;
GO

-- Take the file offline
ALTER DATABASE SalesDB MODIFY FILE (
	NAME = N'SalesDBSalesDataPartition2',
	OFFLINE);
GO

-- Bring the database online
ALTER DATABASE SalesDB SET ONLINE;
GO

-- Check files states
SELECT [name], [state_desc]
	FROM SalesDB.sys.database_files;
GO

-- Try the queries again to show
-- partial database availability
SELECT TOP 100 * FROM SalesDB.dbo.Sales 
	WHERE SalesID < 2000000;
GO
SELECT TOP 100 * FROM SalesDB.dbo.Sales 
	WHERE SalesID >= 2000000
	AND SalesID < 4000000;
GO
SELECT TOP 100 * FROM SalesDB.dbo.Sales 
	WHERE SalesID >= 4000000
	AND SalesID < 6000000;
GO
SELECT TOP 100 * FROM SalesDB.dbo.Sales 
	WHERE SalesID >= 6000000
	AND SalesID < 8000000;
GO

-- Start activity...

-- Backup the tail of the log.
BACKUP LOG SalesDB TO
	DISK = N'C:\SQLskills\SalesDBBackup_LogTail1.bak' 
	WITH INIT, NO_TRUNCATE, STATS = 10;
GO

-- Restore the damaged file from the
-- first backup ONLINE!!!
RESTORE DATABASE SalesDB
	FILE = 'SalesDBSalesDataPartition2'
FROM DISK = 'C:\SQLskills\SalesDBBackup.bak' 
WITH STATS = 10, NORECOVERY;
GO

-- Restore the log tail
RESTORE LOG SalesDB FROM
	DISK = N'C:\SQLskills\SalesDBBackup_LogTail1.bak' 
WITH NORECOVERY, STATS = 10;
GO

-- Check files states
SELECT [name], [state_desc]
	FROM SalesDB.sys.database_files;
GO

-- Still not online? Was activity running?
-- If so, any activity that occured before
-- the initial restore of the file must be
-- backed up and restored to *ensure* that
-- nothing affected the restored file.
-- Although we know nothing did, SQL doesn't.
BACKUP LOG SalesDB TO
	DISK = N'C:\SQLskills\SalesDBBackup_LogTail2.bak' 
	WITH INIT, NO_TRUNCATE, STATS = 10;
GO

-- Restore the log tail (again)
RESTORE LOG SalesDB FROM
	DISK = N'C:\SQLskills\SalesDBBackup_LogTail2.bak' 
WITH NORECOVERY, STATS = 10;
GO

-- Finish recovery
RESTORE DATABASE SalesDB WITH RECOVERY;
GO

-- Check files states
SELECT [name], [state_desc]
	FROM SalesDB.sys.database_files;
GO