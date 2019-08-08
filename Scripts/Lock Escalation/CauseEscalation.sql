/*============================================================================
  File:     CauseEscalation.sql

  Summary:  Trigger table and partition level lock escalation

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

--CREATE DATABASE LockEscalationTest;
--GO
--
--USE LockEscalationTest;
--GO
--
---- Create three partitions: -7999, 8000-15999, 16000+
--CREATE PARTITION FUNCTION MyPartitionFunction (INT)
--AS RANGE RIGHT FOR VALUES (8000, 16000);
--GO
--
--CREATE PARTITION SCHEME MyPartitionScheme
--AS PARTITION MyPartitionFunction
--ALL TO ([PRIMARY]);
--GO
--
---- Create a partitioned table
--CREATE TABLE MyPartitionedTable (c1 INT);
--GO
--
--CREATE CLUSTERED INDEX MPT_Clust ON MyPartitionedTable (c1)
--ON MyPartitionScheme (c1);
--GO
--
---- Fill the table
--SET NOCOUNT ON;
--GO
--
--DECLARE @a INT = 1;
--WHILE (@a < 17000)
--BEGIN
	--INSERT INTO MyPartitionedTable VALUES (@a);
	--SELECT @a = @a + 1;
--END;
--GO

USE LockEscalationTest;
GO

-- Show how fast the partition 3 query is

-- Specifically set lock escalation to be TABLE
ALTER TABLE MyPartitionedTable
SET (LOCK_ESCALATION = TABLE);

-- Cause escalation by updating 7500 rows from
-- partition 1 in a single transaction
BEGIN TRAN
UPDATE MyPartitionedTable SET c1 = c1 WHERE c1 < 7500
GO

-- Try querying partition 3

-- Check the locks being held...

ROLLBACK TRAN;
GO

-- Specifically set lock escalation to be AUTO to
-- allow partition level escalation
ALTER TABLE MyPartitionedTable
SET (LOCK_ESCALATION = AUTO);

-- Cause escalation by updating 7500 rows from
-- partition 1 in a single transaction
BEGIN TRAN
UPDATE MyPartitionedTable SET c1 = c1 WHERE c1 < 7500
GO

-- Try querying partition 3 again

-- Check the locks being held...

-- Go to CauseDeadlock.sql

-- Use this to cause a deadlock
-- Selects a row from partition 2 while it is X locked.
SELECT * FROM MyPartitionedTable WHERE c1 = 8500;
GO
