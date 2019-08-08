/*============================================================================
  File:     EstimateSavings.sql

  Summary:  Estimate compression savings using the stored-proc

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

-- Need to be in the database context
USE LockEscalationTest;
GO

-- All partitions
EXEC sp_estimate_data_compression_savings
	@schema_name = 'dbo',
	@object_name = 'MyPartitionedTable',
	@index_id = 1,
	@partition_number = NULL,
	@data_compression = 'PAGE';
GO

-- Single partition
EXEC sp_estimate_data_compression_savings
	@schema_name = 'dbo',
	@object_name = 'MyPartitionedTable',
	@index_id = 1,
	@partition_number = 1,
	@data_compression = 'PAGE';
GO

-- Let's try a larger table. Make sure the
-- SparseColumnsTest database has been restored
--RESTORE DATABASE SparseColumnsTest FROM
--DISK = 'C:\Metro Demos\Sparse Columns Demos\SparseColumns.bak'
--WITH REPLACE;
--GO

USE SparseColumnsTest;
GO

-- Try ROW first (30 seconds)...
-- Explain how the SP works
EXEC sp_estimate_data_compression_savings
	@schema_name = 'dbo',
	@object_name = 'NonSparseDocRepository',
	@index_id = NULL,
	@partition_number = NULL,
	@data_compression = 'ROW';
GO

-- Try PAGE next...
EXEC sp_estimate_data_compression_savings
	@schema_name = 'dbo',
	@object_name = 'NonSparseDocRepository',
	@index_id = NULL,
	@partition_number = NULL,
	@data_compression = 'PAGE';
GO

-- Unfortunately can't try both at once
-- Note the size of free space needed in TEMPDB - could
-- be a bottleneck on large systems
--
-- Note they're almost the same so not much point adding
-- PAGE compression

-- What about on a table with sparse columns?
-- Errors out immediately
EXEC sp_estimate_data_compression_savings
	@schema_name = 'dbo',
	@object_name = 'SparseDocRepository',
	@index_id = NULL,
	@partition_number = NULL,
	@data_compression = 'ROW';
GO

