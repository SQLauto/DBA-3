/*=====================================================================
  This file is part of a Microsoft SQL Server Shared Source Application.
  Copyright (C) Microsoft Corporation.  All rights reserved.
 
THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
PARTICULAR PURPOSE.
======================================================= */
USE [master]
GO
if exists (
	select * from sys.databases where name = 'AdventureWorks2008_dbss')
	drop database AdventureWorks2008_dbss
GO
USE [AdventureWorks2008]
IF EXISTS (
	SELECT is_cdc_enabled from sys.databases
	WHERE name = 'AdventureWorks2008'
	AND is_cdc_enabled = 1)
	exec sp_cdc_disable_db
GO
IF EXISTS (
	SELECT is_cdc_enabled from sys.databases
	WHERE name = 'AdventureWorks2008'
	AND is_cdc_enabled = 0)
	exec sp_cdc_enable_db
GO
if object_id(N'CDCSample.Customer', 'U') is not null
		drop table CDCSample.Customer
go
if object_id(N'CDCSample.CreditCard', 'U') is not null
		drop table CDCSample.CreditCard
go
if object_id(N'CDCSample.WorkOrder', 'U') is not null
		drop table CDCSample.WorkOrder
go
if exists (
	select name	from sys.schemas
	where name = N'CDCSample')
	drop schema CDCSample
go
CREATE SCHEMA CDCSample
GO
CREATE TABLE [CDCSample].[Customer](
	[CustomerID] [int] NOT NULL,
	[PersonID] [int] NULL,
	[StoreID] [int] NULL,
	[TerritoryID] [int] NULL,
	[AccountNumber]  AS (isnull('AW'+[dbo].[ufnLeadingZeros]([CustomerID]),'')),
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL CONSTRAINT [DF_Customer_rowguid]  DEFAULT (newid()),
	[ModifiedDate] [datetime] NOT NULL CONSTRAINT [DF_Customer_ModifiedDate]  DEFAULT (getdate()),
 CONSTRAINT [CDC_PK_Customer_CustomerID] PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [CDCSample].[CreditCard](
	[CreditCardID] [int] NOT NULL,
	[CardType] [nvarchar](50) NOT NULL,
	[CardNumber] [nvarchar](25) NOT NULL,
	[ExpMonth] [tinyint] NOT NULL,
	[ExpYear] [smallint] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_CreditCard_CreditCardID] PRIMARY KEY CLUSTERED 
(
	[CreditCardID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [CDCSample].[WorkOrder](
	[WorkOrderID] [int] NOT NULL,
	[ProductID] [int] NOT NULL,
	[OrderQty] [int] NOT NULL,
	[StockedQty]  AS (isnull([OrderQty]-[ScrappedQty],(0))),
	[ScrappedQty] [smallint] NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[DueDate] [datetime] NOT NULL,
	[ScrapReasonID] [smallint] NULL,
	[ModifiedDate] [datetime] NOT NULL CONSTRAINT [DF_WorkOrder_ModifiedDate]  DEFAULT (getdate()),
 CONSTRAINT [CDC_PK_WorkOrder_WorkOrderID] PRIMARY KEY CLUSTERED 
(
	[WorkOrderID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
USE [AdventureWorksDW2008]
GO
if object_id(N'CDCSample.Customer', 'U') is not null
		drop table CDCSample.Customer
go
if object_id(N'CDCSample.CreditCard', 'U') is not null
		drop table CDCSample.CreditCard
go
if object_id(N'CDCSample.WorkOrder', 'U') is not null
		drop table CDCSample.WorkOrder
go
if exists (
	select name	from sys.schemas
	where name = N'CDCSample')
	drop schema CDCSample
go
if object_id(N'dbo.ufnLeadingZeros', 'FN') is not null
		drop function dbo.ufnLeadingZeros
go
CREATE FUNCTION [dbo].[ufnLeadingZeros](
    @Value int
) 
RETURNS varchar(8) 
WITH SCHEMABINDING 
AS 
BEGIN
    DECLARE @ReturnValue varchar(8);

    SET @ReturnValue = CONVERT(varchar(8), @Value);
    SET @ReturnValue = REPLICATE('0', 8 - DATALENGTH(@ReturnValue)) + @ReturnValue;

    RETURN (@ReturnValue);
END;
GO
CREATE SCHEMA CDCSample
GO
CREATE TABLE [CDCSample].[Customer](
	[CustomerID] [int] NOT NULL,
	[PersonID] [int] NULL,
	[StoreID] [int] NULL,
	[TerritoryID] [int] NULL,
	[AccountNumber]  AS (isnull('AW'+[dbo].[ufnLeadingZeros]([CustomerID]),'')),
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [CDC_PK_Customer_CustomerID] PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [CDCSample].[CreditCard](
	[CreditCardID] [int] NOT NULL,
	[CardType] [nvarchar](50) NOT NULL,
	[CardNumber] [nvarchar](25) NOT NULL,
	[ExpMonth] [tinyint] NOT NULL,
	[ExpYear] [smallint] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_CreditCard_CreditCardID] PRIMARY KEY CLUSTERED 
(
	[CreditCardID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [CDCSample].[WorkOrder](
	[WorkOrderID] [int] NOT NULL,
	[ProductID] [int] NOT NULL,
	[OrderQty] [int] NOT NULL,
	[StockedQty]  AS (isnull([OrderQty]-[ScrappedQty],(0))),
	[ScrappedQty] [smallint] NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[DueDate] [datetime] NOT NULL,
	[ScrapReasonID] [smallint] NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [CDC_PK_WorkOrder_WorkOrderID] PRIMARY KEY CLUSTERED 
(
	[WorkOrderID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
USE AdventureWorks2008
go
insert into CDCSample.Customer
select CustomerID, PersonID, StoreID, TerritoryID, rowguid, getdate()
from Sales.Customer
where CustomerID < 8000
go
-- Enable change data capture for the table
exec sys.sp_cdc_enable_table 'CDCSample', 'Customer', 'Customer', @supports_net_changes = 1, @role_name = null
go
insert into CDCSample.CreditCard
select CreditCardID, CardType, CardNumber, ExpMonth, ExpYear, getdate()
from Sales.CreditCard
where CreditCardID < 8000
go
-- Enable change data capture for the table
exec sys.sp_cdc_enable_table 'CDCSample', 'CreditCard', 'CreditCard', @supports_net_changes = 1, @role_name = null
go
insert into CDCSample.WorkOrder
select WorkOrderID, ProductID, OrderQty, ScrappedQty, StartDate, EndDate, DueDate, ScrapReasonID, getdate()
from Production.WorkOrder
where  ModifiedDate < CONVERT(datetime,'20020718',112)
go
-- Enable change data capture for the table
exec sys.sp_cdc_enable_table 'CDCSample', 'WorkOrder', 'WorkOrder', @supports_net_changes = 1, @role_name = null
go





