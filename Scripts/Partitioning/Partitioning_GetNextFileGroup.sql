--=========================================
-- Create scalar-valued function template
--=========================================

USE SalesDW
GO

IF OBJECT_ID (N'ETL.GetNextFleGroup') IS NOT NULL
   DROP FUNCTION ETL.GetNextFleGroup
GO

CREATE FUNCTION ETL.GetNextFleGroup (@tablename nvarchar(255), @oldestdate datetime)
RETURNS nvarchar(255)
WITH EXECUTE AS CALLER
AS
-- place the body of the function here
BEGIN
	declare @ReturnValue varchar(255)
	
	SET @ReturnValue = (select fg.name
	FROM sys.tables AS t 
		INNER JOIN sys.indexes AS i 
			ON (t.object_id = i.object_id)
		INNER JOIN sys.partition_schemes AS ps 
			ON (i.data_space_id = ps.data_space_id)
		INNER JOIN sys.destination_data_spaces AS dds 
			ON (ps.data_space_id = dds.partition_scheme_id)
		INNER JOIN sys.filegroups AS fg
			ON dds.data_space_id = fg.data_space_id
	WHERE (t.name = @tablename) and (i.index_id IN (0,1))
		AND dds.destination_id = $partition.SixMonthDateRangePFN(@oldestdate))
	
		RETURN(@ReturnValue)
END
GO
