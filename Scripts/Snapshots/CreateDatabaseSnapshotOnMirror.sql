/*============================================================================
  File:     CreateDatabaseSnapshotOnMirror.sql

  Summary:  Create a database snapshot on the TicketSalesDB on the Principal
			Server (SQLDEV01).

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

------------------------------------------------------------------------------
-- ** Step 1 Begin **
-- CONNECT TO PRINCIPAL TO GET DB FILE STRUCTURE
------------------------------------------------------------------------------
:CONNECT (local)\SQLDEV01
go

USE TicketSalesDB;
GO

-- Examine the database files.
sp_helpfile;
go
------------------------------------------------------------------------------
-- ** Step 1 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** Step 2 Begin **
-- CREATE THE MIRROR SNAPSHOT ON MIRROR DATABASE!
-- NOTE - IF FAILOVER TO MIRROR THEN PRINCIPAL AND SNAPSHOT ON SAME SERVER!
------------------------------------------------------------------------------
:CONNECT (local)\SQLDEV02
go

USE master;
GO

-- Create the database snapshot.
CREATE DATABASE [TicketSalesDB_Snapshot] ON
	(NAME = N'TicketSalesDBData',
		FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV02\MSSQL\DATA\TicketSalesDBData.mdf_SS'),
	(NAME = N'TicketSalesFG2005Q1',
		FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV02\MSSQL\Data\TicketSalesFG2005Q1.ndf_SS'),
	(NAME = N'TicketSalesFG2005Q2',
		FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV02\MSSQL\Data\TicketSalesFG2005Q2.ndf_SS'),
	(NAME = N'TicketSalesFG2005Q3',
		FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV02\MSSQL\Data\TicketSalesFG2005Q3.ndf_SS'),
	(NAME = N'TicketSalesFG2005Q4',
		FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV02\MSSQL\Data\TicketSalesFG2005Q4.ndf_SS')
AS SNAPSHOT OF TicketSalesDB;
GO
------------------------------------------------------------------------------
-- ** Step 2 End **
------------------------------------------------------------------------------

