/*============================================================================
  File:     SetupAndTestFILESTREAM.sql

  Summary:  Setup and investigate FILESTREAM tables

  Date:     August 2008

  SQL Server Version: 10.0.2531.0 (SQL Server 2008 SP1)
------------------------------------------------------------------------------
  Written by Kimberly L. Tripp & Paul S. Randal, SQLskills.com

  For more scripts and sample code, check out http://www.SQLskills.com

  This script is intended as a supplement to the SQL Server 2008 Jumpstart or
  Metro training.
  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

-- Setup FILESTREAM at the OS level
-- (this has already been done)

-- Check the FILESTREAM configuration level
EXEC sp_configure 'filestream_access_level';
GO

-- If it isn't enabled, enable FILESTREAM at the
-- instance level
EXEC sp_configure 'filestream_access_level', 2;
RECONFIGURE;
GO

-- Create a database. Note the FILESTREAM filegroup
CREATE DATABASE FileStreamTestDB ON PRIMARY
  ( NAME = FileStreamTestDB_data,
    FILENAME = N'C:\Metro Demos\FileStreamTestDB\FSTestDB_data.mdf'),
FILEGROUP FileStreamFileGroup CONTAINS FILESTREAM
  ( NAME = FileStreamTestDBDocuments,
    FILENAME = N'C:\Metro Demos\FileStreamTestDB\Documents')
LOG ON 
  ( NAME = 'FileStreamTestDB_log', 
    FILENAME = N'C:\Metro Demos\FileStreamTestDB\FSTestDB_log.ldf');
GO
  
-- Look in the C:\Metro Demos\FileStreamTestDB directory
-- at what's been created
--		$FSLOG - FILESTREAM log
--		filestream.hdr - FILESTREAM system file

-- Create two tables with FILESTREAM columns
USE FileStreamTestDB;
GO

CREATE TABLE FileStreamTest1 (
	DocId UNIQUEIDENTIFIER ROWGUIDCOL NOT NULL UNIQUE,
	DocName VARCHAR (25),
	Document VARBINARY(MAX) FILESTREAM);
GO

CREATE TABLE FileStreamTest2 (
	DocId UNIQUEIDENTIFIER ROWGUIDCOL NOT NULL UNIQUE,
	DocName VARCHAR (25),
	Document1 VARBINARY(MAX) FILESTREAM,
	Document2 VARBINARY(MAX) FILESTREAM);
GO

-- Now look at the filesystem again
-- New directories for the tables just created, with a
-- sub-directory for each FILESTREAM column

INSERT INTO FileStreamTest1 VALUES (
	NEWID (), 'Paul Randal',
	CAST ('SQLskills.com' AS VARBINARY(MAX)));
INSERT INTO FileStreamTest1 VALUES (
	NEWID (), 'Kimberly Tripp',
	CAST ('SQLskills.com' AS VARBINARY(MAX)));
GO

-- Note - empty file creation useful for later
-- populations

SELECT *, CAST (Document AS VARCHAR(MAX))
FROM FileStreamTest1;
GO

-- Note the two files in the FILESTREAM folder

-- Now what happens when we update a FILESTREAM value;
UPDATE FileStreamTest1
SET Document = CAST (REPLICATE ('a', 8000)
	AS VARBINARY(MAX))
WHERE DocName LIKE '%Tripp%';
GO

-- Look again and see that the original file hasn't been
-- deleted, there are three files now, representing two
-- values. It will be garbage collected later.

-- Open the second file in notepad to demonstrate that
-- someone with privileges can access the files.
-- Now delete the file and try selecting from the table
-- again.
SELECT *, CAST (Document AS VARCHAR(MAX))
FROM FileStreamTest1;
GO

-- Error 5552 and connection broken.

-- Try DBCC CHECKDB
DBCC CHECKDB (FileStreamTestDB)
	WITH ALL_ERRORMSGS, NO_INFOMSGS;
GO

-- DBCC CHECKDB does an extensive check.
-- Try creating a random file in the FILESTREAM directory
-- and running DBCC CHECKDB again
DBCC CHECKDB (FileStreamTestDB)
	WITH ALL_ERRORMSGS, NO_INFOMSGS;
GO
-- And it finds it. Repair can fix all FILESTREAM
-- errors too.

--
-- Example of partitioning
CREATE PARTITION FUNCTION MyPartFunction (INT)
AS RANGE RIGHT FOR VALUES (1000, 2000);

CREATE PARTITION SCHEME MyPartScheme
	AS PARTITION MyPartFunction
ALL TO ([PRIMARY]);

-- Note we create a FILESTREAM partitioning scheme
CREATE PARTITION SCHEME MyFSPartScheme
	AS PARTITION MyPartFunction
ALL TO ([FileStreamFileGroup]);

CREATE TABLE FileStreamTest3 (
	TestId UNIQUEIDENTIFIER ROWGUIDCOL NOT NULL
		UNIQUE ON [PRIMARY],
	Customer INT,
	Name VARCHAR (25),
	Document VARBINARY(MAX) FILESTREAM)
ON MyPartScheme (Customer)
FILESTREAM_ON MyFSPartScheme;
GO
