-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Pat Martin
-- Create date: July 2010
-- Description:	CDC Setup for Lab
-- =============================================
CREATE PROCEDURE ETL.SetupTablesForCDC 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS (
		SELECT is_cdc_enabled from sys.databases
		WHERE name = 'SalesStage'
		AND is_cdc_enabled = 1)
		exec sp_cdc_disable_db

	IF EXISTS (
		SELECT is_cdc_enabled from sys.databases
		WHERE name = 'SalesStage'
		AND is_cdc_enabled = 0)
		exec sp_cdc_enable_db



	-- Enable change data capture for the tables under the CDC ETL process
	exec sys.sp_cdc_enable_table 'dbo', 'Sales',
	                             @supports_net_changes = 1, @role_name = null
END


