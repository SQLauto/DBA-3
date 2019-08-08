-- Signature="7BFB5804C68051C4"
IF (SELECT LEFT(CAST(SERVERPROPERTY(N'ProductVersion') AS NVARCHAR),1)) <> N'8'

BEGIN

	EXEC ('

	DECLARE @sql nvarchar(max)

	SET @sql =
				-- sproc name and opening quote for parm
				N''EXEC tempdb.dbo.spSQLRAP_SQLCensus_ExcludedDatabases N'' + CHAR(39)
			 +
				-- xml for parameter
				 ISNULL
				 (
					--CAST
					-- (
					--	(
					--	SELECT	name AS ''@db''
					--	FROM	master.sys.databases
					--	WHERE	name NOT IN (N''master'', N''model'', N''msdb'', N''tempdb'')
					--	AND		name NOT LIKE N''ReportServer%''
					--	AND		name NOT IN (N''RAPTEST'', N''ScratchRAP'')
					--	FOR		XML PATH (''Exclude''), ROOT (''SQLRAP_SQLCensus_Exclusions''), TYPE
					--	) 
					-- AS nvarchar(max)
					-- ),
					N''SampleXML'',
				 N''<SQLRAP_SQLCensus_Exclusions/>''
				 )				 
			  +
				-- closing quote for parm
			  CHAR(39)

	SELECT @sql
	EXEC (@sql)
	')
END

ELSE

BEGIN

-- for SQL 2000, cut and paste results of your query into the EXEC below,
-- and then run THAT statement to set exclusions.

--	DECLARE @parm nvarchar(4000)

--	SET @parm =
--	(
 --   SELECT 1 AS TAG, 0 AS parent,
 --   NULL AS [SQLRAP_SQLCensus_Exclusions!1!],
 --   NULL AS [Exclude!2!],
 --   NULL AS [Exclude!2!db]

 --   UNION ALL

 --   SELECT 2 AS TAG, 1 AS parent,
 --   NULL,
 --   NULL,
 --   name
 --   FROM master.dbo.sysdatabases
	--WHERE	name NOT IN (N'master', N'model', N'msdb', N'tempdb')
	--AND		name NOT LIKE N'ReportServer%'
	--AND		name NOT IN (N'RAPTEST', N'ScratchRAP')
	--FOR XML EXPLICIT
--	)
	
--	SELECT @Parm
	
	EXEC tempdb.dbo.spSQLRAP_SQLCensus_ExcludedDatabases
	N'SampleXML'
	
END
SELECT * FROM tempdb.dbo.SQLRAP_SQLCensus_ExcludedDatabases


