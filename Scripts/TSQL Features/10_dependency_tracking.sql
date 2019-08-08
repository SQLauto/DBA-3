CREATE DATABASE test_dependency
GO

USE test_dependency
GO

CREATE TABLE t1 (a int, b int)
GO


--Create a valid reference
CREATE PROC p1 
AS
	SELECT 
		a
	FROM t1
GO


--Create an invalid reference
CREATE PROC p2
AS
	SELECT 
		*
	FROM t2
GO


--Create a valid reference that will become invalid
CREATE PROC p3
AS
	SELECT 
		b
	FROM t1
GO


ALTER TABLE t1
DROP COLUMN b
GO


--Note referenced_id column may be NULL for invalid references
--Not reliable for invalid cross-database references
SELECT *
FROM sys.sql_expression_dependencies
GO


--Get references for a specific object in the current DB
--Make sure to schema-qualify the table name!
SELECT *
FROM sys.dm_sql_referencing_entities('dbo.t1', 'object')
GO


--Get column-level references
SELECT *
FROM sys.dm_sql_referenced_entities('dbo.p1', 'object')
GO


--Brute-force stored procedure validation
--(at least for table/column references)
DECLARE @object_name SYSNAME = 'dbo.p2'

BEGIN TRY
	DECLARE @i INT = 
	(
		SELECT COUNT(*)
		FROM sys.dm_sql_referenced_entities(@object_name, 'object')
	)
END TRY
BEGIN CATCH
	SELECT @object_name + ' might have an invalid reference'
END CATCH
GO

