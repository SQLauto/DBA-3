/*============================================================================
  File:     TailOfTheLog.sql

  Summary:  This script shows using log-tail
			backups to do up-to-the minute
			recovery

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
GO

-- Create the database
CREATE DATABASE DBMaint2008;
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
	DISK = 'C:\SQLskills\DBMaint2008.bck'
WITH INIT;
GO

-- Now add some more data
INSERT INTO DBMaint2008..TestTable
	VALUES ('Transaction 2');
GO
INSERT INTO DBMaint2008..TestTable
	VALUES ('Transaction 3');
GO

-- Simulate a crash
SHUTDOWN WITH NOWAIT;
GO

-- Trash the data file and restart SQL

USE DBMaint2008;
GO

-- The backup doesn't have the most recent
-- transactions - if we restore it we'll
-- lose them.

-- Take a log backup?
BACKUP LOG DBMaint2008 TO
	DISK = 'C:\SQLskills\DBMaint2008_tail.bck'
WITH INIT;
GO

-- Use the special syntax!
BACKUP LOG DBMaint2008 TO
	DISK = 'C:\SQLskills\DBMaint2008_tail.bck'
WITH INIT, NO_TRUNCATE;
GO

-- Now restore
RESTORE DATABASE DBMaint2008 FROM
	DISK = 'C:\SQLskills\DBMaint2008.bck'
WITH REPLACE, NORECOVERY;
GO

RESTORE LOG DBMaint2008 FROM
	DISK = 'C:\SQLskills\DBMaint2008_tail.bck';
GO

-- Is everything there?
SELECT * FROM DBMaint2008..TestTable;
GO

