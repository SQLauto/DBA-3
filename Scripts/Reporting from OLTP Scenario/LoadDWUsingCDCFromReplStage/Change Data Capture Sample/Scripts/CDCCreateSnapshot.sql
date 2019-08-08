SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Pat Martin
-- Create date: July 2010
-- Description:	Create Snapshot for CDC
-- =============================================
ALTER PROCEDURE ETL.CreateCDCSnapshot 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'SalesStage_ETLSnapshot')
	DROP DATABASE [SalesStage_ETLSnapshot]

------------------------------------------------------------------------------
-- ** Step 1 Begin **
------------------------------------------------------------------------------
-----------------------------------------------------------------------------

-- Ensure you have a reporting user if you want to report directly from the
-- snapshot, not in this case as we will be reading from DW tables.

------------------------------------------------------------------------------
-- ** Step 2 Begin **
------------------------------------------------------------------------------
-----------------------------------------------------------------------------

--sp_helpfile - Check logical filename exists for data file.

-- Create the database snapshot.
CREATE DATABASE [SalesStage_ETLSnapshot] ON
	(NAME = N'SalesStage',
		FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV02\MSSQL\DATA\SalesStage.MDF_SS')
AS SNAPSHOT OF SalesStage;

END

