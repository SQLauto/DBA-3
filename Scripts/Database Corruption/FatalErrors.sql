/*============================================================================
  File:     FatalErrors.sql

  Summary:  This script shows some fatal (to CHECKDB) corruptions

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
RESTORE DATABASE DemoFatalCorruption1 FROM
	DISK = 'C:\SQLskills\CorruptDemoFatalCorruption1.bak'
WITH REPLACE, STATS = 10;
GO
RESTORE DATABASE DemoFatalCorruption2 FROM
	DISK = 'C:\SQLskills\CorruptDemoFatalCorruption2.bak'
WITH REPLACE, STATS = 10;
GO
*/

Restore filelistonly from disk = 'c:\SQLskills\CorruptDemoFatalCorruption1.bak'
Restore filelistonly from disk = 'c:\SQLskills\CorruptDemoFatalCorruption2.bak'

Restore Database DemoFatalCorruption1 from 
	DISK = 'c:\SQLskills\CorruptDemoFatalCorruption1.bak'
	WITH MOVE 'DemoFatalCorruption1' to 'c:\sqlskills\DemoFatalCorruption1.mdf',
	MOVE 'DemoFatalCorruption1_log' to 'c:\sqlskills\DemoFatalCorruption1.ldf',
	REPLACE
	
Restore Database DemoFatalCorruption2 from 
	DISK = 'c:\SQLskills\CorruptDemoFatalCorruption2.bak'
	WITH MOVE 'DemoFatalCorruption2' to 'c:\sqlskills\DemoFatalCorruption2.mdf',
	MOVE 'DemoFatalCorruption2_log' to 'c:\sqlskills\DemoFatalCorruption2.ldf',
	REPLACE	

USE master;
GO

-- Corrupt IAM chain for sys.syshobts
--
DBCC CHECKDB (DemoFatalCorruption1)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO

-- Corruption found by the metadata layer
-- of the Engine
DBCC CHECKDB (DemoFatalCorruption2)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO

