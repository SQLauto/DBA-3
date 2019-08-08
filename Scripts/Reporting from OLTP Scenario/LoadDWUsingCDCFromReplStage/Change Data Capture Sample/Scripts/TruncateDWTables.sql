SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Pat Martin
-- Create date: July 2010
-- Description:	ETL Table Truncation
-- =============================================
ALTER PROCEDURE ETL.TruncateTables 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	Truncate Table dbo.Sales
	Truncate Table dbo.Customers
	Truncate Table dbo.Employees
	Truncate Table dbo.Products

END
GO