USE tempdb
GO


--Create a table type
CREATE TYPE myTableType AS TABLE (x int, y int)
go


--Use it...
DECLARE @t myTableType

INSERT @t 
VALUES 
	(123, 456),
	(789, 101112)
go


--Table-valued parameter
CREATE PROC SelectTableType
	@t as myTableType READONLY
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT *
	FROM @t
END
go


--Use it...
DECLARE @t myTableType

INSERT @t 
VALUES 
	(123, 456),
	(789, 101112)
	
EXEC SelectTableType @t
go
