/*============================================================================
  File:     FindingMinLSN.sql

  Summary:  This script shows how to find min-LSN
			from the backups and the history tables

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

-- Delete any old backups first!!!

-- Cleanout the backup history
USE msdb;
GO

DECLARE @dateStr VARCHAR (20);

SELECT @dateStr = CONVERT (VARCHAR, GETDATE (), 1);

EXEC sp_delete_backuphistory @datestr;
GO

USE master;
GO

IF DATABASEPROPERTYEX ('DBMaint2008', 'Version') > 0
	DROP DATABASE DBMaint2008;

-- Create the database
CREATE DATABASE DBMaint2008;
GO

-- Create a table that will grow
-- large quickly
CREATE TABLE DBMaint2008..TestTable (
	c1 INT IDENTITY,
	c2 CHAR (8000) DEFAULT 'a');
GO
SET NOCOUNT ON;
GO

INSERT INTO DBMaint2008..TestTable
	DEFAULT VALUES;
GO 1000

-- And take Sunday full backup
BACKUP DATABASE DBMaint2008 TO DISK =
	'D:\SQLskills\DBMaint2008_Full_Sunday.bak'
WITH INIT;
GO
BACKUP LOG DBMaint2008 TO DISK =
	'D:\SQLskills\DBMaint2008_Log_Monday.bak'
WITH INIT;
GO

-- Now add more data, hourly log backups
-- and 6-hr differential backups for Monday
DECLARE @count INT;
SELECT @count = 1;
WHILE @count < 25
BEGIN
	INSERT INTO DBmaint2008..TestTable
		DEFAULT VALUES;

	BACKUP LOG DBMaint2008 TO DISK =
		'D:\SQLskills\DBMaint2008_Log_Monday.bak';

	IF (@count % 6 = 0)
	BEGIN
		BACKUP DATABASE DBMaint2008 TO DISK =
			'D:\SQLskills\DBMaint2008_Diff_Monday.bak'
		WITH DIFFERENTIAL;
	END

	SELECT @count = @count + 1;

	WAITFOR DELAY '00:00:01';
END
GO
	
BACKUP LOG DBMaint2008 TO DISK =
	'D:\SQLskills\DBMaint2008_Log_Tuesday.bak'
WITH INIT;
GO

-- Now add more data and hourly log
-- backups for Wednesday, but we crash
-- just after the 3am backup
DECLARE @count INT;
SELECT @count = 1;
WHILE @count < 4
BEGIN
	INSERT INTO DBmaint2008..TestTable
		DEFAULT VALUES;

	BACKUP LOG DBMaint2008 TO DISK =
		'D:\SQLskills\DBMaint2008_Log_Tuesday.bak';

	SELECT @count = @count + 1;

	WAITFOR DELAY '00:00:01';
END
GO
	
-- Now we crash
SHUTDOWN WITH NOWAIT;
GO

-- I/O subsystem trashes data file
-- and system restarts

-- Try to access the datbase
USE DBMaint2008;
GO

-- First thing - tail of the log backup
BACKUP LOG DBMaint2008 TO DISK =
	'D:\SQLskills\DBMaint2008_Log_Tail.bak'
WITH NO_TRUNCATE, INIT;
GO

-- Now we have to restore. What
-- backups do we have?

-- What about from the backup files
-- themselves?
RESTORE HEADERONLY FROM DISK =
	'D:\SQLskills\DBMaint2008_Full_Sunday.bak';

RESTORE HEADERONLY FROM DISK =
	'D:\SQLskills\DBMaint2008_Diff_Monday.bak';

RESTORE HEADERONLY FROM DISK =
	'D:\SQLskills\DBMaint2008_Log_Monday.bak';
GO

RESTORE HEADERONLY FROM DISK =
	'D:\SQLskills\DBMaint2008_Log_Tuesday.bak';
GO

-- A little ungainly. How about from the
-- backup history tables?
SELECT Backup_Start_Date,
	(CASE [type]
		WHEN 'D' THEN 'Full'
		WHEN 'I' THEN 'Diff'
		WHEN 'L' THEN 'Log'
		ELSE 'Unknown'
	END) AS 'Type',
	[Position],
	[Name],
	[Description],
	First_LSN, 
	Last_LSN, 
	Backup_Finish_Date, 
	* -- OR Just *
FROM msdb.dbo.backupset AS s
    JOIN msdb.dbo.backupmediafamily AS m
        ON s.media_set_id = m.media_set_id
WHERE database_name = 'DBMaint2008'
ORDER BY 1 ASC

-- Now do the restore
USE master;
GO

RESTORE DATABASE DBMaint2008 FROM DISK =
	'D:\SQLskills\DBMaint2008_Full_Sunday.bak'
	WITH NORECOVERY;

RESTORE DATABASE DBMaint2008 FROM DISK =
	'D:\SQLskills\DBMaint2008_Diff_Monday.bak'
	WITH FILE = 4, NORECOVERY;

RESTORE DATABASE DBMaint2008 FROM DISK =
	'D:\SQLskills\DBMaint2008_Log_Tuesday.bak'
	WITH FILE = 2, NORECOVERY;
GO

RESTORE DATABASE DBMaint2008 FROM DISK =
	'D:\SQLskills\DBMaint2008_Log_Tuesday.bak'
	WITH FILE = 3, NORECOVERY;
GO

RESTORE DATABASE DBMaint2008 FROM DISK =
	'D:\SQLskills\DBMaint2008_Log_Tuesday.bak'
	WITH FILE = 4, NORECOVERY;
GO

RESTORE DATABASE DBMaint2008 FROM DISK =
	'D:\SQLskills\DBMaint2008_Log_Tail.bak'
	WITH NORECOVERY;
GO

RESTORE DATABASE DBMaint2008 WITH RECOVERY;
GO

USE DBMaint2008;
GO

SELECT COUNT (*) FROM TestTable;
GO

-- Now suppose Monday's last diff is bad.. if we
-- didn't have the backup history tables, and
-- we have individual log files, could take a
-- while...

-- And how about automatically generating the
-- RESTORE statements...
