/*============================================================================
  File:     DataPurityCorruption.sql

  Summary:  This script demonstrates fixing a
			data purity corruption

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
RESTORE DATABASE DemoDataPurity FROM
	DISK = 'D:\SQLskills\CorruptionDemoBackups\CorruptDemoDataPurity.bak'
WITH REPLACE, STATS = 10;
GO
*/

-- Run a CHECKDB
DBCC CHECKDB (DemoDataPurity)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO














-- Data purity corruption. Error only gives the page
-- and slot. Let's take a look.

-- Enable DBCC PAGE output to the console
DBCC TRACEON (3604)
GO

DBCC PAGE (DemoDataPurity, 1, 24473, 3); -- slot 91
GO





















-- It's definitely corrupt. Let's see if we can
-- just delete the record. Maybe not a good idea...
USE DemoDataPurity;
GO

sp_helpindex 'Products';
GO

DELETE FROM Products WHERE ProductID = -;
GO



















-- Hmm - ok - we'll need to update it to something
-- for now.
UPDATE Products SET Price = 0.01
WHERE ProductID = 243;
GO

-- Hopefully that fixed it...
DBCC CHECKDB (DemoDataPurity)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO


-- Success. Steps: look at the page to get the
-- index keys. Update the row and set the column
-- to a valid value. Make sure the value makes
-- sense for the application.