USE [xyzmain]
GO

DECLARE	@return_value int

EXEC	@return_value = [ETL].[GetCDCLSNsForThisInterval]
		@StartTime = null

SELECT	'Return Value' = @return_value

GO
