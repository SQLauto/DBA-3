/*============================================================================
  File:     IsolateWithPartitioning_ONLINE.sql

  Summary:  How about Partitioning an object for better control...
  
  Date:     August 2008

  SQL Server Version: 10.0.2531.0 (SQL Server 2008 SP1)
------------------------------------------------------------------------------
  Written by Kimberly L. Tripp & Paul S. Randal, SQLskills.com
  All rights reserved.

  For more scripts and sample code, check out http://www.SQLskills.com

  This script is intended only as a supplement to demos and lectures
  given by SQLskills.com  
  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

USE SalesDB
go

ALTER DATABASE [SalesDB] 
ADD FILEGROUP SalesDBSalesDataPartition1
go

ALTER DATABASE [SalesDB]
ADD FILE
(	NAME = N'SalesDBSalesDataPartition1'
	, FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV01\MSSQL\DATA\SalesDBSalesDataPartition1.ndf' 
--	, FILENAME = N'E:\SalesDBSalesDataPartition1.ndf' 
	, SIZE = 100
	, MAXSIZE = 120
	, FILEGROWTH = 10)
TO FILEGROUP SalesDBSalesDataPartition1
GO
PRINT 'Created SalesDBSalesDataPartition1'
GO

ALTER DATABASE [SalesDB] 
ADD FILEGROUP SalesDBSalesDataPartition2
go

ALTER DATABASE [SalesDB]
ADD FILE
(	NAME = N'SalesDBSalesDataPartition2'
	, FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV01\MSSQL\DATA\SalesDBSalesDataPartition2.ndf' 
--	, FILENAME = N'F:\SalesDBSalesDataPartition2.ndf' 
	, SIZE = 100
	, MAXSIZE = 120
	, FILEGROWTH = 10)
TO FILEGROUP SalesDBSalesDataPartition2
GO
PRINT 'Created SalesDBSalesDataPartition2'
GO

ALTER DATABASE [SalesDB] 
ADD FILEGROUP SalesDBSalesDataPartition3
go

ALTER DATABASE [SalesDB]
ADD FILE
(	NAME = N'SalesDBSalesDataPartition3'
	, FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV01\MSSQL\DATA\SalesDBSalesDataPartition3.ndf' 
--	, FILENAME = N'G:\SalesDBSalesDataPartition3.ndf' 
	, SIZE = 100
	, MAXSIZE = 120
	, FILEGROWTH = 10)
TO FILEGROUP SalesDBSalesDataPartition3
GO
PRINT 'Created SalesDBSalesDataPartition3'
GO

ALTER DATABASE [SalesDB] 
ADD FILEGROUP SalesDBSalesDataPartition4
go

ALTER DATABASE [SalesDB]
ADD FILE
(	NAME = N'SalesDBSalesDataPartition4'
	, FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV01\MSSQL\DATA\SalesDBSalesDataPartition4.ndf' 
--	, FILENAME = N'H:\SalesDBSalesDataPartition4.ndf' 
	, SIZE = 100
	, MAXSIZE = 120
	, FILEGROWTH = 10)
TO FILEGROUP SalesDBSalesDataPartition4
GO
PRINT 'Created SalesDBSalesDataPartition4'
GO

----------------------------------------------------------------------------------------------
------------------------------ Partition Function --------------------------------------------
----------------------------------------------------------------------------------------------

CREATE PARTITION FUNCTION Sales4Partitions_PFN(int)
AS 
RANGE RIGHT FOR VALUES (2000000,		-- 2 million
						4000000,		-- 4 million
						6000000)		-- 6 million
GO

----------------------------------------------------------------------------------------------
------------------------------ Partition Scheme ----------------------------------------------
----------------------------------------------------------------------------------------------
CREATE PARTITION SCHEME [Sales4Partitions_PS]
AS 
PARTITION [Sales4Partitions_PFN] TO 
		(SalesDBSalesDataPartition1, SalesDBSalesDataPartition2, 
		SalesDBSalesDataPartition3, SalesDBSalesDataPartition4 )
GO

----------------------------------------------------------------------------------------------
------------------------------ MOVE to a Partitioned Table -----------------------------------
----------------------------------------------------------------------------------------------

CREATE UNIQUE CLUSTERED INDEX SalesPK 
ON Sales (SalesID)
WITH (DROP_EXISTING = ON, ONLINE = ON)
ON [Sales4Partitions_PS](SalesID)
GO

----------------------------------------------------------------------------------------------
-------------------------------- Verify final location ---------------------------------------
----------------------------------------------------------------------------------------------

sp_help Sales
go