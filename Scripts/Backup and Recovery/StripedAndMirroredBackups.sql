/*============================================================================
  File:     StripedAndMirroredBackups.sql

  Summary:  This script shows striped and
			mirrored backups and their effect
			on the backup header and file sizes

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


-- Using a backup device
BACKUP DATABASE msdb TO
	DISK = 'C:\SQLskills\test\msdbBackup.bak'
WITH FORMAT;
GO

EXEC SP_ADDUMPDEVICE 'disk',
	'MsdbBackupDevice',
	'C:\SQLskills\test\msdbBackup.bak';
GO

BACKUP DATABASE msdb TO
	MsdbBackupDevice
WITH FORMAT;
GO

-- Cleanup
EXEC SP_DROPDEVICE 'MsdbBackupDevice';
GO

-- Striped/Mirrored Backups

-- 1) Single-device backup, no mirror

BACKUP DATABASE AdventureWorks TO
	DISK = N'C:\SQLskills\test\MediaSet1Device1.bck'
WITH FORMAT, STATS;
GO

RESTORE HEADERONLY FROM
	DISK = N'C:\SQLskills\test\MediaSet1Device1.bck';
GO 

-- Windows Explorer window to C:\SQLskills\test

-- The BackupSize in the HEADERONLY output
-- is 168,899,072 bytes and the on-disk size
-- of the file MediaSet1Device1.bck is 161MB.

-- Notice Position = 1

-- Add another backup to the same device...
BACKUP DATABASE msdb TO
	DISK = N'C:\SQLskills\test\MediaSet1Device1.bck'
WITH STATS;
GO

RESTORE HEADERONLY FROM
	DISK = N'C:\SQLskills\test\MediaSet1Device1.bck';
GO

-- Notice it lists both backups within one backup
-- file

-- 2) Single-device backup, mirrored

BACKUP DATABASE AdventureWorks TO
	DISK = N'C:\SQLskills\test\MediaSet1Device1.bck'
MIRROR TO
	DISK = N'C:\SQLskills\test\MediaSet2Device1.bck'
WITH FORMAT, STATS;
GO

RESTORE HEADERONLY FROM
	DISK = N'C:\SQLskills\test\MediaSet1Device1.bck';
RESTORE HEADERONLY FROM
	DISK = N'C:\SQLskills\test\MediaSet2Device1.bck';
GO

-- The BackupSize in the HEADERONLY output of
-- both files is 337,798,144 bytes. This is
-- double the size of the backup in case #1
-- above - and it because there are now two
-- copies of the backup. The on-disk size of
-- both files is 161MB, which is what we'd
-- expect as MediaSet2Device1.bck is a copy
-- of MediaSet1Device1.bck.

-- 3) Two-device backup, no mirror (striped)

BACKUP DATABASE AdventureWorks TO
	DISK = N'C:\SQLskills\test\MediaSet1Device1.bck',
	DISK = N'C:\SQLskills\test\MediaSet1Device2.bck'
WITH FORMAT, STATS;
GO

RESTORE HEADERONLY FROM
	DISK = N'C:\SQLskills\test\MediaSet1Device1.bck';
GO

-- The BackupSize in the HEADERONLY output is
-- 169,959,424 bytes. This is nearly exactly
-- the same as for the single-Device backup in
-- case #1, but includes a bit more to account
-- for the extra metadata in the second Device.
-- This time, the on-disk size of the file
-- MediaSet1Device1.bck is 81MB. This is half
-- of the on-disk size from the single-Device
-- case #1 as the backup is now split between
-- the two files.

-- 4) Two-device backup, mirrored & striped

BACKUP DATABASE AdventureWorks TO
	DISK = N'C:\SQLskills\test\MediaSet1Device1.bck',
	DISK = N'C:\SQLskills\test\MediaSet1Device2.bck'
MIRROR TO
	DISK = N'C:\SQLskills\test\MediaSet2Device1.bck',
	DISK = N'C:\SQLskills\test\MediaSet2Device2.bck'
WITH FORMAT, STATS;
GO

RESTORE HEADERONLY FROM
	DISK = N'C:\SQLskills\test\MediaSet1Device1.bck';
RESTORE HEADERONLY FROM
	DISK = N'C:\SQLskills\test\MediaSet2Device1.bck';
GO

-- The BackupSize in the HEADERONLY output of
-- both files is 339,918,848 bytes - again,
-- double the size of the non-mirrored backup
-- in case #3. The on-disk size of each file is
-- 81MB, as each file is one half of a copy of
-- the backup.

-- Restoring: Can we mix'n'match devices from
-- mirrored backup media sets?

RESTORE DATABASE AdventureWorks
	FROM DISK = N'C:\SQLskills\test\MediaSet1Device1.bck',
	DISK = N'C:\SQLskills\test\MediaSet2Device2.bck'
WITH REPLACE, STATS;
GO

