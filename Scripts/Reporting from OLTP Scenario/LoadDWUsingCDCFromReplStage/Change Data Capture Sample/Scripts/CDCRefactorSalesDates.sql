SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Pat Martin
-- Create date: July 2010
-- Description:	Business logic for initial load of sales to set Dates :)-
-- =============================================
ALTER PROCEDURE ETL.RefactorSalesDates 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    
    update SalesDW.dbo.Sales 
     set SalesDate = 
     (select case 
     when  salesID between 0 and 100000 then DATEADD(month,-6,GETDATE())
     when  salesID between 100000 and 200000  then DATEADD(month,-5,getdate())
     when  salesID between 200000 and 300000  then DATEADD(month,-4,getdate())
     when  salesID between 300000 and 400000  then DATEADD(month,-3,getdate())
     when  salesID between 400000 and 500000  then DATEADD(month,-2,getdate())
     when  salesID between 500000 and 600000  then DATEADD(month,-1,getdate())  
     when  salesID between 600000 and 700000  then getdate()                        
     else GETDATE()
     end)

END
GO