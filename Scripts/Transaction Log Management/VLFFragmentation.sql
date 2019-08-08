/*============================================================================
  File:     VLFFragmentation.sql

  Summary:  This script shows how to see VLF
			fragmentation and remove it.

			Note: The run-away log file demo
			should be run first

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

USE DBMaint2008;
GO

-- How many VLFs do we have?
DBCC LOGINFO ('DBMaint2008');
GO

-- Shrink the log
DBCC SHRINKFILE (2);
GO

-- Backup the log again to enable
-- freeing more space
BACKUP LOG DBMaint2008 TO
	DISK = 'C:\SQLskills\DBMaint2008_log.bck'
	WITH STATS;
GO

-- Shrink the log again.. this time
-- it goes way down
DBCC SHRINKFILE (2);
GO

-- Now grow it manually and set auto growth
ALTER DATABASE DBMaint2008
	MODIFY FILE (
		NAME = DBMaint2008_Log,
		SIZE = 100MB,
		FILEGROWTH = 20MB);
GO
-- Check perfmon

-- And check VLFs again
DBCC LOGINFO ('DBMaint2008');
GO