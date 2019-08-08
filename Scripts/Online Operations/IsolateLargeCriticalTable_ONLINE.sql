/*============================================================================
  File:     IsolateLargeCriticalTable_ONLINE.sql

  Summary:  Can we isolate ONLY this table to take only the table offline.
			This STILL allows us to backup the transaction log AND it keeps
			users from seeing the damaged data. Depending on the table lost,
			you might still want to take the entire database offline.
  
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
ADD FILEGROUP SalesDataFG
go

ALTER DATABASE [SalesDB]
ADD FILE
(	NAME = N'SalesDBSalesData'
	, FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV01\MSSQL\DATA\SalesDBSalesData.ndf' 
	, SIZE = 300
	, MAXSIZE = UNLIMITED
	, FILEGROWTH = 50)
TO FILEGROUP SalesDataFG
GO

sp_help Sales
go

sp_helpfile
go

CREATE UNIQUE CLUSTERED INDEX SalesPK 
ON Sales (SalesID)
WITH (DROP_EXISTING = ON, ONLINE = ON)
ON SalesDataFG	
GO

sp_help Sales
go