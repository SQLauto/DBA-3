/*============================================================================
  File:     LogClearing.sql

  Summary:  This script shows that in the FULL
			recovery model, only a log backup
			will clear the log.

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

USE master;
GO

IF DATABASEPROPERTYEX ('DBMaint2008', 'Version') > 0
	DROP DATABASE DBMaint2008;
GO

-- Create the database
CREATE DATABASE DBMaint2008;
GO

USE DBMaint2008;
GO

-- Create a table and insert 8MB
CREATE TABLE BigTable (
	c1 INT IDENTITY,
	c2 CHAR (8000) DEFAULT 'a');
GO
CREATE CLUSTERED INDEX BigTable_CL 
	ON BigTable (c1);
GO

SET NOCOUNT ON;
GO

INSERT INTO BigTable DEFAULT VALUES;
GO 10000

-- Put the database into the FULL recovery
-- model and clear out the log.
ALTER DATABASE DBMaint2008 SET RECOVERY FULL;
GO

BACKUP DATABASE DBMaint2008 TO
	DISK = 'c:\SQLskills\DBMaint2008_Full_0.bak'
	WITH INIT, STATS;
GO

BACKUP LOG DBMaint2008 TO
	DISK = 'c:\SQLskills\DBMaint2008_Log_0_Initial.bak'
	WITH INIT, STATS;
GO

-- Now rebuild the clustered index to
-- generate a bunch of log
ALTER INDEX BigTable_CL ON BigTable REBUILD;
GO

-- Backup the log to get a baseline size
BACKUP LOG DBMaint2008 TO
	DISK = 'c:\SQLskills\DBMaint2008_Log_1_Baseline.bak'
	WITH INIT, STATS;
GO

-- Test 1
-- Now rebuilds the clustered index again
-- to generate more log
ALTER INDEX BigTable_CL ON BigTable REBUILD;
GO

-- Now try a full backup and see if it clears
-- the log
BACKUP DATABASE DBMaint2008 TO
	DISK = 'c:\SQLskills\DBMaint2008_Full_1.bak'
	WITH INIT, STATS;
GO

-- If it did, this next log backup should be
-- very small
BACKUP LOG DBMaint2008 TO
	DISK = 'c:\SQLskills\DBMaint2008_Log_2_FullTest.bak'
	WITH INIT, STATS;
GO

-- Test 2
-- Now rebuild the clustered index again
-- to generate more log
ALTER INDEX BigTable_CL ON BigTable REBUILD;
GO

-- Now try a checkpoint and see if it clears
-- the log
CHECKPOINT;
GO

-- If it did, this next log backup should be
-- very small
BACKUP LOG DBMaint2008 TO
	DISK = 'c:\SQLskills\DBMaint2008_Log_3_CheckTest.bak'
	WITH INIT, STATS;
GO

-- Now let's try a rebuild in BULK_LOGGED
-- recovery model. Does that change log
-- backup size?
ALTER DATABASE DBMaint2008
	SET RECOVERY BULK_LOGGED;
GO

ALTER INDEX BigTable_CL ON BigTable REBUILD;
GO

ALTER DATABASE DBMaint2008
	SET RECOVERY FULL;
GO

BACKUP LOG DBMaint2008 TO
	DISK = 'c:\SQLskills\DBMaint2008_Log_4_BulkTest.bak'
	WITH INIT, STATS;
GO

-- Test 5
-- Now the case where there's a long-running
-- transaction and the log can't be cleared
-- by the backup. When does it get cleared?

-- In the other window, do a long-running
-- transaction...

-- In the other window, try a log backup

-- How much log is being used?
DBCC SQLPERF (LOGSPACE);
GO

-- Now let's take a log backup
BACKUP LOG DBMaint2008 TO
	DISK = 'c:\SQLskills\DBMaint2008_Log_5_LongTest.bak'
	WITH INIT, STATS;
GO

-- How big is it?

-- Did the percentage used go down?
DBCC SQLPERF (LOGSPACE);
GO

-- Now commit the transaction...

select * from sys.databases

-- Did the percentage used go down?
DBCC SQLPERF (LOGSPACE);
GO

-- Yes, why? Log reservation.

-- How about a checkpoint?
CHECKPOINT;
GO
DBCC SQLPERF (LOGSPACE);
GO

-- How about a full backup?
BACKUP DATABASE DBMaint2008 TO
	DISK = 'c:\SQLskills\DBMaint2008_Full_2.bak'
	WITH INIT, STATS;
GO
DBCC SQLPERF (LOGSPACE);
GO

-- How about a log backup?
BACKUP LOG DBMaint2008 TO
	DISK = 'c:\SQLskills\DBMaint2008_Log_LongTest2.bak'
	WITH INIT, STATS;
GO
DBCC SQLPERF (LOGSPACE);
GO

-- Added by Pat Martin - March 2011

dbcc loginfo
sp_helpfile

dbcc shrinkfile('DBMaint2008_log', truncateonly)

ALTER DATABASE DBMaint2008 MODIFY FILE(NAME = 'DBMaint2008_log', SIZE = 100)


ALTER DATABASE DBMaint2008
	SET RECOVERY Simple;
GO
checkpoint
dbcc shrinkfile('DBMaint2008_log')
ALTER DATABASE DBMaint2008
	SET RECOVERY Full;
GO
dbcc loginfo

