-- SET IDENTITY_INSERT to ON.
SET IDENTITY_INSERT [XYZMain].[dbo].[Customers] ON
GO


INSERT INTO [XYZMain].[dbo].[Customers]
           (CustomerID
           ,[FirstName]
           ,[LastName]
           ,[Title]
           ,[Address]
           ,[City]
           ,[State]
           ,[PostalCode]
           ,[Country]
           ,[Phone]
           ,[Fax])
 select * from [.\sqldev02].xyzmain.dbo.customers

GO


select * from [XYZMain].[dbo].[Customers]

--select * from sys.servers

DBCC CHECKIDENT ("[XYZMain].[dbo].[Customers]", noreseed);
GO

DBCC CHECKIDENT ("[XYZMain].[dbo].[Customers]", RESEED, 200000);
GO
