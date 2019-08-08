/*============================================================================
  File:     NCIndexCorruption.sql

  Summary:  This script demonstrates fixing non-clustered
			index corruption

  Date:     June 2009

  SQL Server Versions:
		10.0.2531.00 (SS2008 SP1)
		9.00.4035.00 (SS2005 SP3)
------------------------------------------------------------------------------
  Written by Paul S. Randal, SQLskills.com

  For more scripts and sample code, check out 
    http://www.SQLskills.com

  You may alter this code for your own *non-commercial* purposes. You may
  republish altered code as long as you give due credit.
  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

/* Setup
USE master;
GO

-- Get the backup from
-- \\minerva\SQLskills\SQLMaint\CorruptionDemoBackups
-- Make sure the restore path exists...
RESTORE DATABASE DemoNCIndex FROM
	DISK = 'c:\SQLskills\CorruptDemoNCIndex.bak'
WITH REPLACE, STATS = 10;
GO
*/

restore  headeronly  from  disk = 'c:\SQLskills\CorruptDemoNCIndex.bak'
restore  filelistonly  from  disk = 'c:\SQLskills\CorruptDemoNCIndex.bak'

RESTORE DATABASE DemoNCIndex FROM
	DISK = 'c:\SQLskills\CorruptDemoNCIndex.bak' 
	WITH MOVE 'SalesDBData' TO 'C:\SQLskills\SalesDB.mdf',
		 MOVE 'SalesDBLog'  TO 'C:\SQLskills\SalesDBLog.ldf',
REPLACE;
GO


-- Run a CHECKDB
DBCC CHECKDB (DemoNCIndex)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO


-- Is it just non-clustered indexes?
-- Scan through all the errors looking for index IDs
-- Maybe use WITH TABLERESULTS?
DBCC CHECKDB (DemoNCIndex)
WITH NO_INFOMSGS, ALL_ERRORMSGS, TABLERESULTS;
GO

-- If you wanted to fix them with CHECKDB, it
-- may do single row repairs or rebuild the index,
-- depending on the error.
Alter Database DemoNCIndex set single_user
DBCC CHECKDB (DemoNCIndex, REPAIR_REBUILD)
WITH NO_INFOMSGS, ALL_ERRORMSGS, TABLERESULTS;
GO

Alter index CustomerName on customers rebuild













-- You need to be in SINGLE_USER mode! Just to
-- fix non-clustered indexes.
--
-- That doesn't make sense. Just rebuild them
-- manually and keep the database online. Try an
-- online rebuild...
USE DemoNCIndex
GO
EXEC sp_HelpIndex 'Customers';
GO

ALTER INDEX - ON Customers REBUILD
WITH (ONLINE = ON);
GO

-- And check again...
DBCC CHECKDB (DemoNCIndex)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO

















-- Didn't work! Online index rebuild scans
-- the old index...
-- Offline rebuild doesn't...
ALTER INDEX CustomerName ON Customers REBUILD;
GO

DBCC CHECKDB (DemoNCIndex)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO