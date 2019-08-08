--select SUM(unitprice*quantity) from [Order Details] -- 4102711.63



-- ** Step 1 Begin **
------------------------------------------------------------------------------
USE XYZMain;
GO

-- Examine the database files.
sp_helpfile;
GO
------------------------------------------------------------------------------
-- ** Step 1 End **
------------------------------------------------------------------------------

-- Ensure that snapshot file stucture matches that of source database
-- Create any reporting users BEFORE the snapshot :)-

------------------------------------------------------------------------------
-- ** Step 2 Begin **
------------------------------------------------------------------------------

USE [master]
GO
CREATE LOGIN [XYZReportUser] WITH PASSWORD=N'Twiglets101',
 DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
GO
USE [XYZMain]
GO
CREATE USER [XYZReportUser] FOR LOGIN [XYZReportUser]
GO
USE [XYZMain]
GO
EXEC sp_addrolemember N'db_datareader', N'XYZReportUser'
GO
------------------------------------------------------------------------------
-- ** Step 2 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** Step 3 Begin **
------------------------------------------------------------------------------

-- Create the database snapshot.
CREATE DATABASE [XYZMain_Snapshot] ON
	(NAME = N'XYZMain_Data',
		FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQLDEV02\MSSQL\DATA\XYZMain.MDF_SS')
AS SNAPSHOT OF XYZMain;
GO

------------------------------------------------------------------------------
-- ** Step 2 End **
------------------------------------------------------------------------------
