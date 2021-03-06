
USE [SalesDW]
GO

/****** Object:  StoredProcedure [ETL].[SixMonthSlidingSalesWindow]    Script Date: 08/02/2010 23:42:21 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ETL].[SixMonthSlidingSalesWindow]') AND type in (N'P', N'PC'))
DROP PROCEDURE [ETL].[SixMonthSlidingSalesWindow]
GO

CREATE PROCEDURE ETL.SixMonthSlidingSalesWindow  
    @OldestDate       datetime 
AS

declare	@MaxPartition	  int = 7
declare	@OldestPartition  int = 2

declare @NextOldestDate   datetime = dateadd(month,1,@OldestDate)
declare @NewDateBoundary  datetime = dateadd(month,6,@OldestDate)
declare @NextDateBoundary datetime = dateadd(month,1,@NewDateBoundary)

declare @FileGroupToUse	  varchar(255) = 
    (SELECT [SalesDW].[ETL].[GetNextFleGroup] ('SalesReporting', @OldestDate))

declare @execstr nvarchar(max)	


IF  EXISTS (SELECT * FROM sys.check_constraints WHERE object_id = OBJECT_ID(N'[dbo].[SalesCurrentMonthCK]') AND parent_object_id = OBJECT_ID(N'[dbo].[SalesCurrentMonth]'))
ALTER TABLE [dbo].[SalesCurrentMonth] DROP CONSTRAINT [SalesCurrentMonthCK]

/****** Object:  Table [dbo].[SalesCurrentMonth]    Script Date: 08/01/2010 11:05:43 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SalesCurrentMonth]') AND type in (N'U'))
DROP TABLE [dbo].[SalesCurrentMonth]

/****** Object:  Table [dbo].[SalesCurrentMonth]    Script Date: 08/01/2010 11:05:15 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SalesOldestMonth]') AND type in (N'U'))
DROP TABLE [dbo].[SalesOldestMonth]

IF  EXISTS (SELECT * FROM sys.check_constraints WHERE object_id = OBJECT_ID(N'[dbo].[SalesRangeSixMonthCK]') AND parent_object_id = OBJECT_ID(N'[dbo].[SalesReporting]'))
ALTER TABLE [dbo].[SalesReporting] DROP CONSTRAINT [SalesRangeSixMonthCK]

-------------------------------------------------------
-- Create staging tables for sales, we can always use this
-- table name - Here we test with the NEW Data of August 2010
-------------------------------------------------------

set @execstr = 

'CREATE TABLE SalesDW.[dbo].[SalesCurrentMonth]  
(
	[SalesDate]     [datetime] NOT NULL,
	[SalesID]	    int NOT NULL,
	[SalesPersonID] int NOT NULL,
	[CustomerID]    int NOT NULL,
	[ProductID]     int NOT NULL,		
	[Quantity]      int NOT NULL
) ON ' + @FileGroupToUse

exec (@execstr)

-- -------------------------------------------------------
-- Populate this months staging table with new data.
-- -------------------------------------------------------
-- Through INSERT...SELECT or through parallel bulk insert
-- statements against the text files.

INSERT SalesDW.[dbo].[SalesCurrentMonth]
	SELECT  s.[SalesDate] 
			, s.[SalesID]
			, s.[SalesPersonID]
			, s.[CustomerID]
			, s.[ProductID] 
			, s.[Quantity] 
	FROM dbo.sales AS s
		WHERE ([SalesDate] >= @NewDateBoundary AND 
		       [SalesDate] < @NextDateBoundary)
		       		       

-- -------------------------------------------------------
-- Once the data is loaded then you can ALTER TABLE to
-- add the constraint. Be sure to use default WITH CHECK to 
-- verify the data and create a "trusted" constraint.
-- -------------------------------------------------------

set @execstr = 

'ALTER TABLE SalesDW.[dbo].[SalesCurrentMonth]  
ADD CONSTRAINT SalesCurrentMonthCK
	CHECK (([SalesDate] >= ''' + convert(char(8),@NewDateBoundary,112) + '''' + 
	' AND [SalesDate] < ''' + convert(char(8),@NextDateBoundary,112) + '''' + '))'

--select @execstr	
exec (@execstr)

-------------------------------------------------------
-- The table must have the same clustered index
-- definition!
-------------------------------------------------------
set @execstr = 
'ALTER TABLE [dbo].[SalesCurrentMonth]
ADD CONSTRAINT SalesCurrentMonthPK
 PRIMARY KEY CLUSTERED (SalesDate, SalesID)
ON ' + @FileGroupToUse
exec (@execstr)

-------------------------------------------------------
-- Now that the data is ready to be moved IN you can 
-- prepare to switch out the old data.
-- Create a table for the oldest data partition being 
-- moved out 

-- THIS MUST BE ON THE SAME FILEGROUP AS THE PARTITION
-- BEING SWITCHED OUT. 
-- Remember, a switch solely "switches" meta data - to do this
-- the objects must be on the same filegroup!
-------------------------------------------------------
set @execstr =
'CREATE TABLE SalesDW.[dbo].[SalesOldestMonth]  
(
	[SalesDate]     [datetime] NOT NULL,
	[SalesID]	    int NOT NULL,
	[SalesPersonID] int NOT NULL,
	[CustomerID]    int NOT NULL,
	[ProductID]     int NOT NULL,		
	[Quantity]      int NOT NULL
) ON ' + @FileGroupToUse
exec (@execstr)

-------------------------------------------------------
-- The table must have the same clustered index
-- definition!
-------------------------------------------------------
set @execstr = 
'ALTER TABLE [dbo].[SalesOldestMonth]
ADD CONSTRAINT SalesOldestMonthPK
 PRIMARY KEY CLUSTERED (SalesDate, SalesID)
ON ' + @FileGroupToUse
exec (@execstr)

-------------------------------------------------------
-- "Switch" the old partition out to a new table
-- Always partition 2 for Range Right
-------------------------------------------------------
ALTER TABLE SalesReporting
SWITCH PARTITION @OldestPartition
TO [dbo].[SalesOldestMonth]

-- Next you could back up the table and/or just drop it,
-- depending on what your archiving rules are, etc.
-- Here in this scheme we reuse this table name next month,
-- a synonym would work well here - PJM.


-------------------------------------------------------
-- Verify Data In Partition Ranges ...
-------------------------------------------------------

/*
SELECT $partition.SixMonthDateRangePFN(SalesDate)
			AS [Partition Number]
	, min(SalesDate) AS [Min Sales Date]
	, max(SalesDate) AS [Max Sales Date]
	, count(*) AS [Rows In Partition]
FROM SalesReporting
GROUP BY $partition.SixMonthDateRangePFN(SalesDate)
ORDER BY [Partition Number]

*/

-------------------------------------------------------
-- Alter the partition function to drop the old range
-- The idea is that when partitions are merged a boundary
-- point is removed.

-- The merge operation should be extremely fast!
-------------------------------------------------------


ALTER PARTITION FUNCTION SixMonthDateRangePFN()
MERGE RANGE (@OldestDate)

-------------------------------------------------------
-- Verify Partition Ranges
-- Data was in partitions 2 through 7 and now merge removed
-- partition 2 so data is now in partitions 1 through 6.
-- SQL Server always numbers the data based on the CURRENT
-- number of partitions so if you run the query again you 
-- will see ONLY 6 partitions but the partition numbers
-- will be 2, 3, etc. even though NO DATA HAS MOVED (only 
-- the logical partition numbers have changed).
-------------------------------------------------------

/*

SELECT $partition.SixMonthDateRangePFN(SalesDate)
			AS [Partition Number]
	, min(SalesDate) AS [Min Sales Date]
	, max(SalesDate) AS [Max Sales Date]
	, count(*) AS [Rows In Partition]
FROM SalesReporting
GROUP BY $partition.SixMonthDateRangePFN(SalesDate)
ORDER BY [Partition Number]

*/

-------------------------------------------------------
-- This also removes the filegroup associated with the
-- partition scheme (meaning that [FG1] filegroup is 
-- no longer associated. If you want to roll the new data
-- through the same existing 6 partitions then you
-- will need to make FG1 next used again.
-------------------------------------------------------

--Use the following query to see to see ALL filegroups
--SELECT * FROM sys.filegroups

-- Use the following query to see to see ONLY the filegroups
-- associated with SalesReporting

/*
SELECT ps.name AS PSName, 
		dds.destination_id AS PartitionNumber, 
		fg.name AS FileGroupName
FROM (((sys.tables AS t 
	INNER JOIN sys.indexes AS i 
		ON (t.object_id = i.object_id))
	INNER JOIN sys.partition_schemes AS ps 
		ON (i.data_space_id = ps.data_space_id))
	INNER JOIN sys.destination_data_spaces AS dds 
		ON (ps.data_space_id = dds.partition_scheme_id))
	INNER JOIN sys.filegroups AS fg
		ON dds.data_space_id = fg.data_space_id
WHERE (t.name = 'SalesReporting') and (i.index_id IN (0,1))
*/

-------------------------------------------------------
-- Alter the partition SCHEME to add the next partition
-------------------------------------------------------
--select * from sys.partition_functions

set @execstr = 
'ALTER PARTITION SCHEME SixMonthDateRangePScheme
  NEXT USED ' + @FileGroupToUse
exec (@execstr)

-------------------------------------------------------
-- Alter the partition function to add the new range
-------------------------------------------------------

ALTER PARTITION FUNCTION SixMonthDateRangePFN() 
 SPLIT RANGE (@NewDateBoundary)

-------------------------------------------------------
-- BEFORE you can add this data you must allow it.
-------------------------------------------------------

--ALTER TABLE SalesReporting DROP CONSTRAINT SalesRangeSixMonthCK

SET @execstr = 

'ALTER TABLE SalesReporting WITH CHECK  
ADD CONSTRAINT [SalesRangeSixMonthCK]
	CHECK (([SalesDate] >= ''' + convert(char(8),@NextOldestDate,112) + '''' + 
	' AND [SalesDate] < ''' + convert(char(8),@NextDateBoundary,112) + '''' + '))'

--select @execstr	
exec (@execstr)

ALTER TABLE SalesReporting CHECK CONSTRAINT [SalesRangeSixMonthCK]

-------------------------------------------------------
-- "Switch" the new partition in. ALWAYS RIGHTMOST
-- partition in Range Right
-------------------------------------------------------
ALTER TABLE dbo.SalesCurrentMonth
  SWITCH TO SalesReporting PARTITION @MaxPartition

-------------------------------------------------------
-- Verify Date Ranges for partitions
-------------------------------------------------------
SELECT $partition.SixMonthDateRangePFN(SalesDate)
			AS [Partition Number]
	, min(SalesDate) AS [Min Sales Date]
	, max(SalesDate) AS [Max Sales Date]
	, count(*) AS [Rows In Partition]
FROM salesreporting --$(PartitionedTableName)
GROUP BY $partition.SixMonthDateRangePFN(SalesDate)
ORDER BY [Partition Number]

-------------------------------------------------------
-- Backup the filegroup
-------------------------------------------------------
/*
BACKUP DATABASE SalesDW 
	FILEGROUP = N'FG1' 
TO DISK = N'c:\sqlskills\SalesDWCurrentMonth.bak'
WITH INIT
*/
