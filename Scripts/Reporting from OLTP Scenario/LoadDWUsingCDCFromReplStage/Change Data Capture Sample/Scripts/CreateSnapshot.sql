-- ** Step 1 Begin **
------------------------------------------------------------------------------
USE XYZMain;
GO

-- Examine the database files.
--sp_helpfile;
--GO
------------------------------------------------------------------------------
-- ** Step 1 End **
------------------------------------------------------------------------------

IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'XYZMain_ETLSnapshot')
DROP DATABASE [XYZMain_ETLSnapshot]
GO

------------------------------------------------------------------------------
-- ** Step 2 Begin **
------------------------------------------------------------------------------
-----------------------------------------------------------------------------

-- Create the database snapshot.
CREATE DATABASE [XYZMain_ETLSnapshot] ON
	(NAME = N'XYZMain_Data',
		FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV01\MSSQL\DATA\XYZMain.MDF_SS')
AS SNAPSHOT OF XYZMain;
GO

------------------------------------------------------------------------------
-- ** Step 2 End **
------------------------------------------------------------------------------
