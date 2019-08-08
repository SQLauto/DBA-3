/*============================================================================
  File:     CorruptMetadata.sql

  Summary:  This script shows repairing corrupt
			metadata after an upgrade from SQL2000

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

-- Restore the corrupt 2000 database
RESTORE DATABASE DemoCorruptMetadata FROM
DISK = 'D:\SQLskills\CorruptionDemoBackups\DemoCorruptMetadata2000.bak'
WITH MOVE 'DemoCorruptMetadata' TO
	'C:\SQLskills\DemoCorruptMetadata.mdf',
MOVE 'DemoCorruptMetadata_log' TO
	'C:\SQLskills\DemoCorruptMetadata_log.ldf',
REPLACE;
GO

-- Check consistency
DBCC CHECKDB (DemoCorruptMetadata)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO















-- Try to repair...
ALTER DATABASE DemoCorruptMetadata SET SINGLE_USER;
GO
DBCC CHECKDB (DemoCorruptMetadata, REPAIR_ALLOW_DATA_LOSS)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO
ALTER DATABASE DemoCorruptMetadata SET MULTI_USER;
GO




















-- Ok - can we hack the system tables?
--
SELECT name FROM DemoCorruptMetadata.sys.objects;
GO

-- Hmm - narrow it down a bit
--
SELECT name FROM DemoCorruptMetadata.sys.objects
WHERE name LIKE '%col%';
GO












-- Try one...
SELECT * FROM DemoCorruptMetadata.sys.sysrowsetcolumns
WHERE 1=0;
GO












-- ok - we can't bind to or change the system tables in 2005
-- UNLESS we use the Dedicated Admin Connection AND
-- single_user mode...
-- Documented in MSDN
-- http://msdn.microsoft.com/en-us/library/ms179503.aspx
-- http://forums.microsoft.com/MSDN/ShowPost.aspx?PostID=89594&SiteID=1


-- CMD window

-- Check it worked...
DBCC CHECKDB (DemoCorruptMetadata)
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO






















-- DAC commands

SELECT * FROM sys.sysrowsetcolumns WHERE 1 = 0;
GO
SELECT * FROM sys.syshobtcolumns WHERE 1 = 0;
GO
SELECT * FROM sys.syscolpars WHERE 1 = 0;
GO

DELETE FROM sys.syscolpars WHERE id = 1977058079

-- do it again with the SERVER in single-user mode