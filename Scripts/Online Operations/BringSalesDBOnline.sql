/*============================================================================
  File:     BringSalesDBOnline.sql

  Summary:  A database which is detected as damaged during 
			Restart Recovery must be brought online manually.
  
  Date:     August 2008

  SQL Server Version: 10.0.2531.0 (SQL Server 2008 SP1)
------------------------------------------------------------------------------
  Written by Kimberly L. Tripp & Paul S. Randal, SQLskills.com
  All rights reserved.

  For more scripts and sample code, check out http://www.SQLskills.com

  This script is intended only as a supplement to demos and lectures
  given by SQLskills.com  
  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

USE master 
go

ALTER DATABASE [SalesDB]
	MODIFY FILE (NAME = N'SalesDBSalesDataPartition2', OFFLINE)
GO

ALTER DATABASE [SalesDB] 
	SET ONLINE
GO

USE [SalesDB]
go

SELECT file_id, name, physical_name, state_desc 
FROM sys.database_files
go

----------------------------------------------------------------------------------------------
------------------------------ Restore Damaged FILE from Backup ------------------------------
----------------------------------------------------------------------------------------------

USE Master
GO

RESTORE DATABASE [SalesDB]
	FILE = N'SalesDBSalesDataPartition2'
FROM DISK = N'C:\SQLskills\SalesDBBackup.bak' 
WITH FILE = 1, STATS = 10,
--	MOVE N'SalesDBSalesDataPartition2' TO N'J:\SalesDBSalesDataPartition2.ndf', 
	NORECOVERY
go

USE [SalesDB]
go

SELECT file_id, name, physical_name, state_desc 
FROM sys.database_files
go

----------------------------------------------------------------------------------------------
------------------------------ Backup the Tail -----------------------------------------------
----------------------------------------------------------------------------------------------
-- You must backup the tail of the log AFTER the file has been taken offline
-- otherwise the sync lsn will not match and you won't be able to bring the file
-- back online!

USE master
go

BACKUP LOG [SalesDB]
	TO DISK = N'C:\SQLskills\SalesDBBackup.bak' 
	WITH NOINIT, NO_TRUNCATE, STATS = 10
go

-- Now restore the tail
RESTORE LOG [SalesDB]
	FROM DISK = N'C:\SQLskills\SalesDBBackup.bak' 
	WITH FILE = 2, RECOVERY, STATS = 10
go

USE [SalesDB]
go

SELECT file_id, name, physical_name, state_desc 
FROM sys.database_files
go
