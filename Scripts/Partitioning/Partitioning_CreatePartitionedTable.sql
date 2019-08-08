/*============================================================================
 PJM August 2010
 Partition SalesReporting Table for six month rolling range
 Kept simple, Range Right, Six partitions + Primary as partition one :)-
============================================================================*/

USE SalesDW
GO

IF  EXISTS (SELECT * FROM sys.check_constraints WHERE object_id = OBJECT_ID(N'[dbo].[SalesRangeSixMonthCK]') AND parent_object_id = OBJECT_ID(N'[dbo].[SalesReporting]'))
ALTER TABLE [dbo].[SalesReporting] DROP CONSTRAINT [SalesRangeSixMonthCK]
GO

/****** Object:  Table [dbo].[SalesReporting]    Script Date: 08/01/2010 10:52:05 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SalesReporting]') AND type in (N'U'))
DROP TABLE [dbo].[SalesReporting]
GO

/****** Object:  PartitionScheme [SixMonthDateRangePScheme]    Script Date: 08/01/2010 10:53:10 ******/
IF  EXISTS (SELECT * FROM sys.partition_schemes WHERE name = N'SixMonthDateRangePScheme')
DROP PARTITION SCHEME [SixMonthDateRangePScheme]
GO

/****** Object:  PartitionFunction [SixMonthDateRangePFN]    Script Date: 08/01/2010 10:53:37 ******/
IF  EXISTS (SELECT * FROM sys.partition_functions WHERE name = N'SixMonthDateRangePFN')
DROP PARTITION FUNCTION [SixMonthDateRangePFN]
GO

-------------------------------------------------------
-- Create the partition function
-------------------------------------------------------
CREATE PARTITION FUNCTION SixMonthDateRangePFN(datetime)
AS 
RANGE RIGHT FOR VALUES 
(			'20100201',	-- Feb 2010
			'20100301',	-- Mar 2010
			'20100401',	-- Apr 2010
			'20100501',	-- May 2010
			'20100601',	-- Jun 2010
			'20100701') -- Jul 2010
GO

-------------------------------------------------------
-- Create the partition scheme
-------------------------------------------------------
CREATE PARTITION SCHEME [SixMonthDateRangePScheme]
AS 
PARTITION [SixMonthDateRangePFN] TO 
		( [PRIMARY], [FG1], [FG2], [FG3], [FG4], [FG5], [FG6])
		
-- The first partition will ALWAYS be empty using the Rolling Range Right Scenario. 
-- Using the PRIMARY is acceptable for this as no data will actually reside there.
GO

-------------------------------------------------------
-- Create the Sales table on the RANGE partition scheme
-------------------------------------------------------
CREATE TABLE SalesDW.[dbo].[SalesReporting]  
(
	[SalesDate]     [datetime] NOT NULL 
		CONSTRAINT SalesRangeSixMonthCK
			CHECK ([SalesDate] >= '20100201' AND [SalesDate] < '20100801'),
	[SalesID]	    int NOT NULL,
	[SalesPersonID] int NOT NULL,
	[CustomerID]    int NOT NULL,
	[ProductID]     int NOT NULL,		
	[Quantity]      int NOT NULL
) ON SixMonthDateRangePScheme(SalesDate)
GO

-------------------------------------------------------
-- Copy data from staging to the data warehouse.
-------------------------------------------------------

INSERT dbo.[SalesReporting]
	SELECT s.[SalesDate] 
			, s.[SalesID]
			, s.[SalesPersonID]
			, s.[CustomerID]
			, s.[ProductID] 
			, s.[Quantity] 
	FROM dbo.sales AS s
		WHERE ([SalesDate] >= '20100201' 
				 AND [SalesDate] < '20100801')

-------------------------------------------------------
-- Verify Partition Ranges
-------------------------------------------------------

SELECT $partition.[SixMonthDateRangePFN](s.SalesDate) 
			AS [Partition Number]
	, min(s.SalesDate) AS [Min Sales Date]
	, max(s.SalesDate) AS [Max Sales Date]
	, count(*) AS [Rows In Partition]
FROM dbo.SalesReporting AS s
GROUP BY $partition.[SixMonthDateRangePFN](s.SalesDate)
ORDER BY [Partition Number]
GO

-------------------------------------------------------
-- Create the clustered indexes as Primary keys
-- for partitioned table. Specifying the SCHEME 
-- is optional. If the table is partitioned the defaulf 
-- behavior is for SQL Server to create the cl index 
-- on the same partition scheme.
-------------------------------------------------------
ALTER TABLE SalesReporting
ADD CONSTRAINT SalesPK
	PRIMARY KEY CLUSTERED (SalesDate, SalesID)
	ON SixMonthDateRangePScheme(SalesDate)
GO

-- NOTE ONLINE VERSION TO MODIFY EXISTING

/*
CREATE UNIQUE CLUSTERED INDEX SalesPK ON Sales (SalesID)
	WITH (DROP_EXISTING = ON, ONLINE = ON)
	ON [Sales4Partitions_PS](SalesID);
GO
*/

