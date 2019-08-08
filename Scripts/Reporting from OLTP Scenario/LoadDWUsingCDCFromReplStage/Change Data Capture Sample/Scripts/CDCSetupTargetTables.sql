/*=====================================================================
  This file is part of a Microsoft SQL Server Shared Source Application.
  Copyright (C) Microsoft Corporation.  All rights reserved.
 
THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
PARTICULAR PURPOSE.
======================================================= */

USE xyzmain
IF EXISTS (
	SELECT is_cdc_enabled from sys.databases
	WHERE name = 'xyzmain'
	AND is_cdc_enabled = 1)
	exec sp_cdc_disable_db
GO
IF EXISTS (
	SELECT is_cdc_enabled from sys.databases
	WHERE name = 'xyzmain'
	AND is_cdc_enabled = 0)
	exec sp_cdc_enable_db
GO


-- Enable change data capture for the tables under the CDC ETL process
exec sys.sp_cdc_enable_table 'dbo', 'Orders', @supports_net_changes = 1, @role_name = null
go

exec sys.sp_cdc_enable_table 'dbo', 'order details', @supports_net_changes = 1, @role_name = null
go








