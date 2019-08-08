/*============================================================================
  File:     RestoreFromMultiFileBackup.sql

  Summary:  This script shows restoring from
			multi-file backups, and using
			multi-file databases

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

IF DATABASEPROPERTYEX ('DBMaint2008', 'Version') > 0
	DROP DATABASE DBMaint2008;

-- Create a multi-file database
CREATE DATABASE DBMaint2008;
GO

ALTER DATABASE DBMaint2008
	ADD FILEGROUP TestFileGroup;
GO

ALTER DATABASE DBMaint2008
	ADD FILE (
		NAME = TestFile1,
		FILENAME = 'C:\SQLskills\TestFile1.ndf',
		SIZE = 5MB),
		(NAME = TestFile2,
		FILENAME = 'C:\SQLskills\TestFile2.ndf',
		SIZE = 5MB)
	TO FILEGROUP TestFileGroup;
GO

-- Create a dump device
EXEC SP_ADDUMPDEVICE 'disk',
	'MyBackupDevice',
	'C:\SQLskills\test\MyBigBackup.bak';
GO

-- Create a backup with multiple databases
BACKUP DATABASE msdb TO
	MyBackupDevice
WITH FORMAT;
GO

BACKUP DATABASE DBMaint2008 TO
	MyBackupDevice;
GO

-- Now simulate a disaster
ALTER DATABASE DBMaint2008
	MODIFY FILE (
		NAME = TestFile2, OFFLINE);
GO

SELECT [name], [state_desc] FROM
	DBMaint2008.sys.database_files;
GO

-- Bring it back online
ALTER DATABASE DBMaint2008
	MODIFY FILE (
		NAME = TestFile2, ONLINE);
GO

-- Uh-oh - we need to restore

-- First thing - backup the tail of the log!
BACKUP LOG DBMaint2008 TO
	MyBackupDevice;
GO

-- Now how do we restore the 'corrupt' file?
RESTORE HEADERONLY FROM
	MyBackupDevice;
GO 

-- What about the files?
RESTORE FILELISTONLY FROM
	MyBackupDevice;
GO 

-- We need to specify a backup otherwise it uses
-- the first one
RESTORE FILELISTONLY FROM
	MyBackupDevice
WITH FILE = 2;
GO 

-- Now we need to pull out the right file
RESTORE DATABASE DBMaint2008
	FILE = 'TestFile2' FROM MyBackupDevice
WITH FILE = 2, NORECOVERY;
GO

-- And restore the tail of the log
RESTORE LOG DBMaint2008
	FROM MyBackupDevice
WITH FILE = 3, NORECOVERY;
GO

-- And finalize recovery
RESTORE DATABASE DBMaint2008 WITH RECOVERY;
GO

-- Check the status again
SELECT [name], [state_desc] FROM
	DBMaint2008.sys.database_files;
GO

-- Cleanup
EXEC SP_DROPDEVICE 'MyBackupDevice';
GO
