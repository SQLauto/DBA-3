/*============================================================================
  File:     EnableCompression.sql

  Summary:  Enable compression on some tables

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

USE SparseColumnsTest;
GO

-- Time updating all rows in the table
DBCC DROPCLEANBUFFERS;
GO

UPDATE NonSparseDocRepository
SET c103 = 1;
GO

-- Time: approx 40-50 seconds for 100000 rows
-- Explain about DBCC DROPCLEANBUFFERS, how update is a
-- good test as it needs to read all the pages plus crack
-- the row format

-- How many pages total?
SELECT * FROM sys.dm_db_index_physical_stats (
	DB_ID ('SparseColumnsTest'),
	OBJECT_ID ('SparseColumnsTest.dbo.NonSparseDocRepository'),
	NULL, NULL, 'DETAILED');
GO
-- Page count: 100000 + 371 + 1

-- Turn on compression
ALTER TABLE NonSparseDocRepository REBUILD
WITH (DATA_COMPRESSION = ROW);
GO
-- Takes 30-60 seconds

-- Explain about the new syntax, extra disk space, extra
-- log/backup space. Especially problematic for VLDBs
-- that may not be able to rebuild normally.
-- Trying page compression would take longer for no
-- gain (remember we estimated the savings!)

-- Time the update again
DBCC DROPCLEANBUFFERS;
GO

UPDATE NonSparseDocRepository
SET c103 = 2;
GO
-- Wow. Must be a huge decrease in the number of pages

SELECT * FROM sys.dm_db_index_physical_stats (
	DB_ID ('SparseColumnsTest'),
	OBJECT_ID ('SparseColumnsTest.dbo.NonSparseDocRepository'),
	NULL, NULL, 'DETAILED');
GO
-- Page count:

-- Out of interest, show the estimation for *removing*
-- compression
EXEC sp_estimate_data_compression_savings
	@schema_name = 'dbo',
	@object_name = 'NonSparseDocRepository',
	@index_id = NULL,
	@partition_number = NULL,
	@data_compression = 'NONE';
GO

