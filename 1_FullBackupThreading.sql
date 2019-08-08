/*
Code from Tim Chapman.  Added Indexing support to test threading of Index filegroups for backup - PJM
*/

use master
GO

GO
IF DB_ID('NumbersDB') IS NOT NULL
BEGIN
	EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'NumbersDB' -- PJM Added removal of backup history
	ALTER DATABASE NumbersDB
	SET SINGLE_USER WITH ROLLBACK IMMEDIATE -- PJM -Note rollback immediate needed to avoid self-blocking
	
	DROP DATABASE NumbersDB

END
GO

CREATE DATABASE NumbersDB
GO
ALTER DATABASE NumbersDB
ADD FILEGROUP FG_A
GO
ALTER DATABASE NumbersDB
ADD FILEGROUP FG_B
GO
ALTER DATABASE NumbersDB
ADD FILEGROUP FG_IDX
GO
ALTER DATABASE NumbersDB
ADD FILEGROUP FG_IDX2
GO

GO
-------------------------------------------------------
-- For RANGE Partitions
-- Add Files to each Filegroup
-------------------------------------------------------
ALTER DATABASE NumbersDB
ADD FILE 
  (NAME = N'NumbersDBFile1',
  FILENAME = N'C:\SQL\NumbersDBFile1.ndf',
  SIZE = 5MB,
  MAXSIZE = 500MB,
  FILEGROWTH = 50MB)
TO FILEGROUP FG_A
GO
ALTER DATABASE NumbersDB
ADD FILE 
  (NAME = N'NumbersDBFile2',
  FILENAME = N'C:\SQL\NumbersDBFile2.ndf',
  SIZE = 5MB,
  MAXSIZE = 500MB,
  FILEGROWTH = 50MB)
TO FILEGROUP FG_B
GO

ALTER DATABASE NumbersDB
ADD FILE 
  (NAME = N'NumbersDBFile3',
  FILENAME = N'C:\SQL\NumbersDBFile3.ndf',
  SIZE = 5MB,
  MAXSIZE = 500MB,
  FILEGROWTH = 50MB)
TO FILEGROUP FG_B
GO

ALTER DATABASE NumbersDB
ADD FILE 
  (NAME = N'NumbersDBIndexFile',
  FILENAME = N'H:\SQL\NumbersDBIndexFile1.ndf',
  SIZE = 5MB,
  MAXSIZE = 500MB,
  FILEGROWTH = 50MB)
TO FILEGROUP FG_IDX
GO

ALTER DATABASE NumbersDB
ADD FILE 
  (NAME = N'NumbersDBIndexFile2',
  FILENAME = N'H:\SQL\NumbersDBIndexFile2.ndf',
  SIZE = 5MB,
  MAXSIZE = 500MB,
  FILEGROWTH = 50MB)
TO FILEGROUP FG_IDX2
GO

USE NumbersDB
GO
CREATE TABLE NumbersTable
(
	NumberValue BIGINT NOT NULL IDENTITY(1,1), 
	OtherNumber BIGINT NOT NULL, 
	CharCol VARCHAR(500) DEFAULT(REPLICATE('x',500))
) 
GO
CREATE TABLE NumbersTable2
(
	NumberValue BIGINT NOT NULL IDENTITY(1,1), 
	OtherNumber BIGINT NOT NULL, 
	CharCol VARCHAR(500) DEFAULT(REPLICATE('x',500))
) 
GO
ALTER TABLE NumbersTable
ADD CONSTRAINT PK_NumbersTable PRIMARY KEY CLUSTERED (NumberValue)
ON FG_A
GO
ALTER TABLE NumbersTable2
ADD CONSTRAINT PK_NumbersTable2 PRIMARY KEY CLUSTERED (NumberValue)
ON FG_B
GO

INSERT INTO NumbersTable(OtherNumber)
SELECT	SalesOrderDetailID
FROM AdventureWorks2008.Sales.SalesOrderDetail
GO 5

INSERT INTO NumbersTable2(OtherNumber)
SELECT	SalesOrderDetailID
FROM AdventureWorks2008.Sales.SalesOrderDetail
GO 5

-- Indexes

USE [NumbersDB]
GO
CREATE NONCLUSTERED INDEX [NCIDX] ON [dbo].[NumbersTable] 
(
	[OtherNumber] ASC
)WITH (STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF,
	 DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [FG_IDX]
GO

USE [NumbersDB]
GO
CREATE NONCLUSTERED INDEX [NCIDX2] ON [dbo].[NumbersTable2] 
(
	[OtherNumber] ASC
)WITH (STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF,
	 DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [FG_IDX2]
GO


/*
	INIT = 
	FORMAT = 
*/

/*

/* Rebuild indexes :)-
ALTER INDEX NCIDX ON DBO.NumbersTable REBUILD
ALTER INDEX NCIDX2 ON DBO.NumbersTable2 REBUILD

--1. create a single file backup
BACKUP DATABASE NumbersDB 
TO 
	DISK = 'C:\SQL\NDBFile1.bak'
 WITH INIT, FORMAT
 GO

 --2. use multiple backup files
BACKUP DATABASE NumbersDB 
TO 
	DISK = 'C:\SQL\NDBFile1.bak'
	DISK = 'C:\SQL\NDBFile2.bak'
	DISK = 'H:\SQL\NDBFile3.bak'
 WITH INIT, FORMAT
 GO


  --3. mirror a backup file
BACKUP DATABASE NumbersDB 
TO 
	DISK = 'C:\SQL\NDBFile1.bak', 
	DISK = 'C:\SQL\NDBFile2.bak'
	MIRROR TO 
		DISK = 'C:\SQL\NDBFile1.bak', 
		DISK = 'H:\SQL\NDBFile2.bak' 
 WITH INIT, FORMAT
 GO
 */