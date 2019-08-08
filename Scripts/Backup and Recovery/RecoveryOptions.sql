/*============================================================================
  File:     RecoveryOptions.sql

  Summary:  This script shows the three options
			for recovery during a restore

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

-- Create the database
CREATE DATABASE DBMaint2008;
GO

-- Create a dump device
EXEC SP_ADDUMPDEVICE 'disk',
	'MyBackupDevice',
	'C:\SQLskills\test\MyBigBackup.bak';
GO

-- Create a table
CREATE TABLE DBMaint2008..TestTable (
	c1 INT IDENTITY,
	c2 VARCHAR (100));
GO

INSERT INTO DBMaint2008..TestTable
	VALUES ('Initial data: transaction 1');
GO

-- And take a full backup
BACKUP DATABASE DBMaint2008 TO
	MyBackupDevice
WITH FORMAT;
GO

-- Now add some more data and a backup
INSERT INTO DBMaint2008..TestTable
	VALUES ('Transaction 2');
GO
INSERT INTO DBMaint2008..TestTable
	VALUES ('Transaction 3');
GO

BACKUP LOG DBMaint2008 TO MyBackupDevice;
GO

-- And more data
INSERT INTO DBMaint2008..TestTable
	VALUES ('Transaction 4');
GO
INSERT INTO DBMaint2008..TestTable
	VALUES ('Transaction 5');
GO
-- Now check the time and save it
SELECT GETDATE ();
GO

-- Saved time: 

-- And add some more data
INSERT INTO DBMaint2008..TestTable
	VALUES ('Transaction 6');
GO
INSERT INTO DBMaint2008..TestTable
	VALUES ('Transaction 7');
GO

-- And take another backup
BACKUP LOG DBMaint2008 TO MyBackupDevice;
GO

-- Simulate disaster
DROP DATABASE DBMaint2008;
GO

-- So what do we have?
RESTORE HEADERONLY FROM
	MyBackupDevice;
GO

-- Restore the full backup
RESTORE DATABASE DBMaint2008
	FROM MyBackupDevice
WITH FILE = 1;
GO

-- And the log backups
RESTORE LOG DBMaint2008
	FROM MyBackupDevice
WITH FILE = 2;

RESTORE LOG DBMaint2008
	FROM MyBackupDevice
WITH FILE = 3;
GO

-- WITH RECOVERY is the DEFAULT!
-- We need to start again...
RESTORE DATABASE DBMaint2008
	FROM MyBackupDevice
WITH FILE = 1, NORECOVERY, REPLACE;
GO

RESTORE LOG DBMaint2008
	FROM MyBackupDevice
WITH FILE = 2, NORECOVERY;

RESTORE LOG DBMaint2008
	FROM MyBackupDevice
WITH FILE = 3, NORECOVERY;
GO

-- And then finalize recovery
RESTORE DATABASE DBMaint2008 WITH RECOVERY;
GO

SELECT * from DBMaint2008..TestTable;
GO

-- What if we want to examine things
-- between restores?
RESTORE DATABASE DBMaint2008
	FROM MyBackupDevice
WITH FILE = 1, REPLACE,
	STANDBY = 'C:\SQLskills\standbyfile.dat';
GO

-- We can see what's in there...
SELECT * from DBMaint2008..TestTable;
GO

-- Can we update anything?
INSERT INTO DBMaint2008..TestTable
	VALUES ('Transaction 6');
GO

-- Let's do the next log file.
RESTORE LOG DBMaint2008
	FROM MyBackupDevice
WITH FILE = 2,
	STANDBY = 'C:\SQLskills\standbyfile.dat';
GO

-- Now what's there?
SELECT * from DBMaint2008..TestTable;
GO

-- Now restore the rest and bring the
-- database online
RESTORE LOG DBMaint2008
	FROM MyBackupDevice
WITH FILE = 3, NORECOVERY;
GO

RESTORE DATABASE DBMaint2008 WITH RECOVERY;
GO

SELECT * from DBMaint2008..TestTable;
GO

-- What if we want to stop at a specific point?
RESTORE DATABASE DBMaint2008
	FROM MyBackupDevice
WITH FILE = 1, NORECOVERY, REPLACE,
	STOPAT = 'XXXX';
GO

RESTORE LOG DBMaint2008
	FROM MyBackupDevice
WITH FILE = 2, 
	STOPAT = 'XXXX',
	STANDBY = 'C:\SQLskills\standbyfile.dat';

-- Are we there yet?
SELECT * from DBMaint2008..TestTable;
GO

RESTORE LOG DBMaint2008
	FROM MyBackupDevice
WITH FILE = 3,
	STOPAT = 'XXXX',
	STANDBY = 'C:\SQLskills\standbyfile.dat';
GO

-- Is this the right point?
SELECT * from DBMaint2008..TestTable;
GO

-- Finalize recovery
RESTORE DATABASE DBMaint2008 WITH RECOVERY;
GO
SELECT * from DBMaint2008..TestTable;
GO

-- Take another backup so we don't need
-- to go through all that again
BACKUP DATABASE DBMaint2008 TO
	MyBackupDevice;
GO

-- Cleanup
EXEC SP_DROPDEVICE 'MyBackupDevice';
GO
