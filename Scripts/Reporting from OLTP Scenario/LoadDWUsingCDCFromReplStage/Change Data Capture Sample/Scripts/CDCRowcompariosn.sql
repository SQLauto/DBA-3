
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Pat Martin
-- Create date: July 2010
-- Description:	Row comparison check
-- =============================================
CREATE PROCEDURE ETL.CompareRows 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

/*=============================================
  This file is part of a Microsoft SQL Server Shared Source Application.
  Copyright (C) Microsoft Corporation.  All rights reserved.
 
THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
PARTICULAR PURPOSE.
============================================= */

	declare @SalesMismatch int = 0
	 
	if exists (	
			select s.SalesID from SalesStage.dbo.Sales s
			inner join SalesDW.dbo.Sales d on s.SalesID = d.SalesID
			where CHECKSUM(s.SalesID, s.SalesPersonID, s.CustomerID, s.ProductID, s.Quantity) <>
				  CHECKSUM(d.SalesID, d.SalesPersonID, d.CustomerID, d.ProductID, d.Quantity)
	   ) 
		begin
		 set @SalesMismatch = 1
		end
	/*	
		
	- Can't do this as warehouse will grow over time...
		
	declare @count1 int, @count2 int
	select @count1 = COUNT(*) from AdventureWorks2008.CDCSample.CreditCard 
	select @count2 = COUNT(*) from AdventureWorksDW2008.CDCSample.CreditCard
	if @count1 <> @count2 
	begin
	 set @SalesMismatch = 1
	end
	
	*/
	
	select	@SalesMismatch as SalesMismatch

END
