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






