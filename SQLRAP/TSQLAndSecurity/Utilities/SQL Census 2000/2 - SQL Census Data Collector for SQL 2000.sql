-- Signature="4E4B0A724616C87E"

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    SQL Census Data Collector for SQL 2000.sql                                                        ****/
--/****    builds infrastructure for and executes SQL Census code mapping for a SQL Server 2000 instance     ****/
--/****                                                                                                      ****/
--/****    2010.Mar.16 - created (wardp) - adapted from the 3.0 scripts                                      ****/
--/****    2010.Jul.22 - updated (wardp) - CR 466805                                                         ****/
--/****    2010.Sep.11 - updated (wardp) - bug 468251                                                        ****/
--/****    2010.Sep.15 - updated (wardp) - bug 224894                                                        ****/
--/****    2010.Sep.21 - updated (wardp) - bug 468699                                                        ****/
--/****    2010.Sep.30 - updated (wardp) - bug 468895                                                        ****/
--/****    2010.Oct.01 - updated (wardp) - bug 468926                                                        ****/
--/****    2010.Oct.07 - updated (wardp) - bug 417498                                                        ****/
--/****    2010.Dec.10 - updated (rajpo) - bug 471301 case sensitivity issue                                 ****/
--/****    2011.Apr.08 - updated (gsacavdm) - bug 473806													 ****/
--/****                                                                                                      ****/
--/****    Copyright (c) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

SET NOCOUNT ON
USE tempdb
GO

--	version check; a failure here will be logged and the connection forcibly broken
IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),2) <> '8.'
BEGIN
	DECLARE @ErrorString nvarchar(4000)
	SET @ErrorString = 'Attempt to run SQL Server 2000 (SQL Server version 8) SQLRAP Data Collector on a SQL Server '
					  + CASE
						  WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),4) = '10.5' THEN '2008 R2'
						  WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),2) = '10'   THEN '2008'
						  WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),2) = '9.'   THEN '2005'
					    END
					  + ' version '
					  + CAST(SERVERPROPERTY('ProductVersion') AS nvarchar)
					  + ' platform.  Process terminated.'
					  + CHAR(13) + CHAR(10)
					  + 'Please run the SQL Server '
					  + CASE
						  WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),2) = '10'   THEN '2008'
						  WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),2) = '9.'   THEN '2005'
					    END
					  + ' SQLRAP Data Collector against this instance.'
	RAISERROR (@ErrorString, 25, 1) WITH LOG
END
GO

-- check for bootstrap object; a failure will be logged if it's not found
IF OBJECT_ID('SQLRAP_SQLCensus_ExcludedDatabases') IS NULL
BEGIN
	DECLARE @ErrorString nvarchar(4000)
	SET @ErrorString = 'Attempt to run SQL Server 2000 SQLRAP Data Collector without first running Bootstrap process.  Process terminated.'
					  + CHAR(13) + CHAR(10)
					  + 'Please run the SQL Server 2000 Bootstrap against this instance.'
	RAISERROR (@ErrorString, 25, 1) WITH LOG
END
GO

DECLARE @Restarted bit

IF OBJECT_ID('SQLRAP_SQLCensus_StaticCodeAnalysis') IS NULL
BEGIN
	SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' -- building infrastructure' AS [Status]
	SET		@Restarted = 0
END
ELSE
BEGIN
	SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' -- restarting' AS [Status]
	SET		@Restarted = 1
END

-- drop the indexes if they're already there
IF EXISTS (SELECT id FROM sysindexes (NOLOCK) WHERE name = N'q5' AND id = OBJECT_ID('SQLRAP_SQLCensus_StaticCodeAnalysis'))
BEGIN
	DROP INDEX [SQLRAP_SQLCensus_StaticCodeAnalysis].q5
	DROP INDEX [SQLRAP_SQLCensus_StaticCodeAnalysis].q6
	DROP INDEX [SQLRAP_SQLCensus_StaticCodeAnalysis].q7
	DROP INDEX [SQLRAP_SQLCensus_StaticCodeAnalysis].q8
	DROP INDEX [SQLRAP_SQLCensus_StaticCodeAnalysis].q9
	DROP INDEX [SQLRAP_SQLCensus_StaticCodeAnalysis].q10

	DROP INDEX [SQLRAP_SQLCensus_StaticCodeAnalysisForJobs].jq7
	DROP INDEX [SQLRAP_SQLCensus_StaticCodeAnalysisForJobs].jq8
	DROP INDEX [SQLRAP_SQLCensus_StaticCodeAnalysisForJobs].jq10
END

-- create TimeAndSpaceEstimator objects if they're not present..
IF OBJECT_ID('SQLRAP_SQLCensus_TimeAndSpace') IS NULL
BEGIN
	EXEC('
CREATE TABLE dbo.SQLRAP_SQLCensus_TimeAndSpace (
    DatabaseName                sysname,
    databaseid                  int PRIMARY KEY,
    EstimateRun					bit DEFAULT(0),
    Fast                        bigint,
    Slow                        bigint,
    [Total] AS Fast + Slow,
    NumberOfObjects AS Fast + Slow,
    EstimatedSlowSpaceInBytes      bigint,
    EstimatedFastSpaceInBytes      bigint,
    ActualRunTimeInSeconds      decimal(12,4),
    SlowCalibrationAverage      decimal(12,4),
    FastCalibrationAverage      decimal(12,4),
    AverageSizeOfSlowObject		int,
    AverageSizeOfFastObject		int,
	SlowAverageInDB AS CASE Slow WHEN 0 THEN 0 ELSE EstimatedSlowSpaceInBytes/Slow END,
	FastAverageInDB AS CASE [Fast] WHEN 0 THEN 0 ELSE EstimatedFastSpaceInBytes/[Fast] END,
	EstimatedRunTimeInSeconds   AS
		CASE 
			WHEN AverageSizeOfSlowObject = 0 THEN 0
			WHEN AverageSizeOfSlowObject IS NULL THEN 0
			WHEN Slow = 0 THEN 0
			WHEN Slow IS NULL THEN 0
			ELSE SlowCalibrationAverage * Slow * ((CASE Slow WHEN 0 THEN 0 ELSE ((EstimatedSlowSpaceInBytes)/Slow) END * 1.2)/AverageSizeOfSlowObject)
		END
		+
		CASE 
			WHEN AverageSizeOfFastObject = 0 THEN 0
			WHEN AverageSizeOfFastObject IS NULL THEN 0
			WHEN Fast = 0 THEN 0
			WHEN Fast IS NULL THEN 0
			ELSE FastCalibrationAverage * 1.2 * [Fast] * ((CASE [Fast] WHEN 0 THEN 0 ELSE EstimatedFastSpaceInBytes/[Fast] END)/AverageSizeOfFastObject)
        END
, SlowEstimate AS
		CASE 
			WHEN AverageSizeOfSlowObject = 0 THEN 0
			WHEN AverageSizeOfSlowObject IS NULL THEN 0
			WHEN Slow = 0 THEN 0
			WHEN Slow IS NULL THEN 0
			ELSE SlowCalibrationAverage * Slow * ((CASE Slow WHEN 0 THEN 0 ELSE ((EstimatedSlowSpaceInBytes)/Slow) END * 1.2)/AverageSizeOfSlowObject)
		END
,FastEstimate AS
		CASE 
			WHEN AverageSizeOfFastObject = 0 THEN 0
			WHEN AverageSizeOfFastObject IS NULL THEN 0
			WHEN Fast = 0 THEN 0
			WHEN Fast IS NULL THEN 0
			ELSE FastCalibrationAverage * 1.2 * [Fast] * ((CASE [Fast] WHEN 0 THEN 0 ELSE EstimatedFastSpaceInBytes/[Fast] END)/AverageSizeOfFastObject)
        END
, FastFactor AS
		CASE 
			WHEN AverageSizeOfFastObject = 0 THEN 0
			WHEN AverageSizeOfFastObject IS NULL THEN 0
			WHEN Fast = 0 THEN 0
			WHEN Fast IS NULL THEN 0
			ELSE ((CASE [Fast] WHEN 0 THEN 0 ELSE EstimatedFastSpaceInBytes/[Fast] END)/AverageSizeOfFastObject)
		END
, SlowFactor AS
		CASE 
			WHEN AverageSizeOfSlowObject = 0 THEN 0
			WHEN AverageSizeOfSlowObject IS NULL THEN 0
			WHEN Slow = 0 THEN 0
			WHEN Slow IS NULL THEN 0
			ELSE ((CASE Slow WHEN 0 THEN 0 ELSE ((EstimatedSlowSpaceInBytes)/Slow) END * 1.2)/AverageSizeOfSlowObject)
		END
    )
'
		)
	EXEC('	
		-- load the table with records for each database
		-- since we are not running an estimate, set the estimate values to -1
		-- (the status script will use these values to figure out there is no estimate

		DECLARE @ReportingServicesMaster sysname,
				@ReportingServicesTempdb sysname,
				@dbid int,
				@name sysname,
				@SQLString nvarchar(4000),
				@distribdb sysname
		 
		EXEC sp_helpdistributor @distribdb = @distribdb output

		SET		@ReportingServicesMaster = ''ReportServer'' +
					CASE  
						WHEN CONVERT(sysname,SERVERPROPERTY(''InstanceName'')) IS NOT NULL
							THEN ''$'' + CONVERT(sysname,SERVERPROPERTY(''InstanceName''))
						ELSE ''''
					END
		SET		@ReportingServicesTempdb = @ReportingServicesMaster + ''TempDB''

		INSERT dbo.SQLRAP_SQLCensus_TimeAndSpace (
			databaseid,
			DatabaseName,
			Fast,
			Slow,
			EstimatedSlowSpaceInBytes,
			EstimatedFastSpaceInBytes
			)
		SELECT
			s.dbid,
			s.name,
			-1,
			-1,
			-1,
			-1
		FROM    master..sysdatabases s
		WHERE   lower(s.name) NOT IN (N''master'', N''tempdb'', N''model'', N''msdb'', N''pubs'', N''northwind'', N''adventureworks'', N''adventureworksdw'')
		AND  (
			 (@distribdb is not null and lower(s.name) <> lower(@distribdb))  -- bug 243806
			 OR
			 (@distribdb IS NULL)
			 )
		-- omit databases which did not start up cleanly
		AND		s.status & 32 = 0		-- loading
		AND		s.status & 64 = 0		-- pre recovery
		AND		s.status & 128 = 0	-- recovering
		AND		s.status & 256 = 0	-- not recovered
		AND		s.status & 512 = 0	-- offline
		AND		s.status & 32768 = 0	-- emergency mode

		UNION ALL

		SELECT  DB_ID(''msdb''), 
				''msdb'',
				COUNT(*),
				-1,
				-1,
				SUM(ISNULL(DATALENGTH(s.command)/2,0))
		FROM	msdb.dbo.sysjobs j
		JOIN	msdb.dbo.sysjobsteps s
		ON		j.job_id = s.job_id
		AND		s.subsystem = N''TSQL''

		ORDER BY s.dbid
		OPTION (MAXDOP 1)
		'
		)
END
-- create Numbers table
IF OBJECT_ID('SQLRAP_SQLCensus_Numbers') IS NULL
BEGIN
	EXEC('
		CREATE TABLE dbo.SQLRAP_SQLCensus_Numbers(i int PRIMARY KEY);
	
		INSERT dbo.SQLRAP_SQLCensus_Numbers (i)
		SELECT 1 + d1.i + 10*d2.i + 100*d3.i + 1000*d4.i + 10000*d5.i  + 100000*d6.i AS i
		FROM    (SELECT 1 AS i UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL
				SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL
				SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL
				SELECT 0) AS d1,
				(SELECT 1 AS i UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL
				SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL
				SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL
				SELECT 0) AS d2,
				(SELECT 1 AS i UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL
				SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL
				SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL
				SELECT 0) AS d3,
				(SELECT 1 AS i UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL
				SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL
				SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL
				SELECT 0) AS d4,
				(SELECT 1 AS i UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL
				SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL
				SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL
				SELECT 0) AS d5,
				(SELECT 1 AS i UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL
				SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL
				SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL
				SELECT 0
				) AS d6
				ORDER BY 1
				OPTION (MAXDOP 1)
				')
END

-- create and populate SQLRAP_SQLCensus_Keywords table
IF OBJECT_ID('dbo.SQLRAP_SQLCensus_Keywords') IS NULL
BEGIN
	EXEC('
		CREATE TABLE dbo.SQLRAP_SQLCensus_Keywords (
			KeywordID			int identity(1,1) primary key,
			Keyword				nvarchar(64),	-- the keyword itself
			KeywordSearchString	AS				-- the keyword with whitespace around it (except for parens and old outer joins)
				CASE
				WHEN Keyword IN (''<>'', ''!='', ''!<'', ''!>'', ''=*'', ''*='', ''*'', ''('', '')'', ''../'', ''xp_cmdshell'', ''[@'', ''[1]'') THEN Keyword
				ELSE N''[/, ('' + CHAR(9) + CHAR(10) + CHAR(13) + '']''
									+ Keyword
									+ N''[/, ()'' + CHAR(9) + CHAR(10) + CHAR(13) + '']''
				END,
			ChangesDepthUp		bit,			-- used to calculate statement depth; only applies to open paren
			ChangesDepthDown	bit,			-- used to calculate statement depth; only applies to close paren
			KeywordLength		AS LEN(Keyword),
			KeywordSearchStringLength AS		-- the length of the keyword and its whitespace
				CASE
				WHEN Keyword IN (''<>'', ''!='', ''!<'', ''!>'', ''=*'', ''*='', ''*'', ''('', '')'', ''../'', ''xp_cmdshell'', ''[@'', ''[1]'') THEN LEN(Keyword)
				ELSE LEN(Keyword) + 2
				END,
			CanStartStatement		bit
			)

		CREATE UNIQUE INDEX Keyword ON dbo.SQLRAP_SQLCensus_Keywords(Keyword)	

		-- populate Keywords table

		BEGIN TRAN

		-- terms which can change depth

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''('', 1, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES('')'', 0, 1, 0)

		-- terms which can start a statement
		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''insert'', 0, 0, 1)
		
		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''select'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''update'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''add'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''alter'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''backup'', 0, 0, 1)
		
		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''begin'', 0, 0, 1)
		
		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''break'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''bulk'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''checkpoint'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''commit'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''continue'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''create'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''dbcc'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''declare'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''delete'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''deny'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''disable'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''drop'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''enable'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''end'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''exec'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''execute'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''go'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''goto'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''grant'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''if'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''kill'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''load'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''merge'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''move'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''print'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''readtext'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''receive'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''reconfigure'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''restore'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''return'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''revert'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''revoke'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''rollback'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''save'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''send'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''set'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''setuser'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''shutdown'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''truncate'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''updatetext'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''use'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''waitfor'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''while'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''with'', 0, 0, 0)  -- going to need to figure out something for CTEs..

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''writetext'', 0, 0, 1)

		-- cursor-related terms

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''close'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''deallocate'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''dynamic'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''fetch'',  0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''global'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''insensitive'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''keyset'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''open'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''static'',  0, 0, 0)

		-- join hint-related terms

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''hash'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''loop'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''remote'',  0, 0, 0)

		-- locking hint-related terms

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''holdlock'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''nolock'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''paglock'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''readcommitted'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''readpast'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''readuncommitted'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''repeatableread'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''rowlock'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''serializable'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''tablock'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''tablockx'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''updlock'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''xlock'',  0, 0, 0)

		-- query hint related terms

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''concat'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''expand'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''fast'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''force'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''forced'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''group'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''keep'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''keepfixed'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''maxdop'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''maxrecursion'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''optimize'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''option'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''order'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''parameterization'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''plan'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''recompile'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''robust'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''simple'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''views'',  0, 0, 0)

		-- XML related terms

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''../'', 0, 0, 0) -- parent axis access

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''[1]'',  0, 0, 0) -- single root node

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''explicit'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''for'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''openxml'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''raw'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''sp_xml_preparedocument'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''sp_xml_removedocument'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''xml'',  0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''[@'',  0, 0, 0)

		--NOTE THERE''S MORE TO DO HERE

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''xp_cmdshell'', 0, 0, 0)

		-- other terms of interest

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''*='', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''=*'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''<>'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''!='', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''!>'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''!<'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''*'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''as'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''between'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''caller'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''case'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''committed'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''cursor'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''else'', 0, 0, 1)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''exists'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''from'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''in'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''join'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''like'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''not'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''on'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''owner'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''read'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''repeatable'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''self'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''snapshot'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''transaction'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''tran'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''uncommitted'', 0, 0, 0)

        INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
        VALUES (''union'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''when'', 0, 0, 0)

		INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
		VALUES (''where'', 0, 0, 0)

		COMMIT TRAN

		UPDATE STATISTICS dbo.SQLRAP_SQLCensus_Keywords WITH FULLSCAN'
		)
END

--SELECT Keyword FROM tempdb.dbo.SQLRAP_SQLCensus_Keywords
--Group by Keyword
--having COUNT(*) > 1

-- create SQLRAP_SQLCensus_Objects table
IF OBJECT_ID('SQLRAP_SQLCensus_Objects') IS NULL
BEGIN
	EXEC('
		CREATE TABLE dbo.SQLRAP_SQLCensus_Objects (
			databaseid			 int,
			ObjectId			 int,
			Number				 int,
			ObjectName			 sysname,
			ObjectOwner			 sysname,
			ObjectType			 nvarchar(2),
            ExtendedProperties   nvarchar(1000)
			PRIMARY KEY (databaseid, ObjectId, Number)
		)
')
END

-- create SQLRAP_SQLCensus_Timings table
IF OBJECT_ID('SQLRAP_SQLCensus_Timings') IS NULL
BEGIN
	EXEC('
		CREATE TABLE dbo.SQLRAP_SQLCensus_Timings (
			databaseid			int,
			StartDateTime		datetime,
			EndDateTime			datetime DEFAULT GETDATE()
		)
')
END

--	create SQLRAP_SQLCensus_StaticCodeAnalysis table
IF OBJECT_ID('SQLRAP_SQLCensus_StaticCodeAnalysis') IS NULL
BEGIN
	EXEC('
		CREATE TABLE dbo.SQLRAP_SQLCensus_StaticCodeAnalysis
		(
			databaseid int, 
			objectid int,
			number int,
			LocationInCode bigint,
			RowNumber int,
			LogicalStatementNumber int,
			StatementDepth int,
			KeywordID int,
			Iteration smallint,
			NewStatementStartsHere bit,
			IsPartOfObjectDeclaration bit
			PRIMARY KEY (databaseid, objectid, number, LocationInCode)
		)

		CREATE INDEX q1 ON SQLRAP_SQLCensus_StaticCodeAnalysis (KeywordID, IsPartOfObjectDeclaration)

')
END

IF OBJECT_ID('SQLRAP_SQLCensus_StaticCodeAnalysisForJobs') IS NULL
BEGIN
	EXEC('
		CREATE TABLE dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs
		(
			job_id uniqueidentifier, 
			step_id int,
			LocationInCode bigint,
			RowNumber int,
			LogicalStatementNumber int,
			StatementDepth int,
			KeywordID int,
			Iteration smallint,
			NewStatementStartsHere bit
			PRIMARY KEY (job_id, step_id, LocationInCode, KeywordID)
		)
		')
END

IF OBJECT_ID('SQLRAP_SQLCensus_Summary') IS NULL
	EXEC('
		CREATE VIEW dbo.SQLRAP_SQLCensus_Summary AS
		SELECT  DB_NAME(t.databaseid) AS DatabaseName,
				t.databaseid,
				t.EstimateRun,
				t.Slow,
				t.Fast,
				ISNULL(t.Fast,0) + ISNULL(t.Slow,0) AS Total,
				CASE
					WHEN t.databaseid = DB_ID(''msdb'') THEN
						(SELECT	ISNULL(COUNT(DISTINCT CAST(job_id AS nvarchar(40))+''|''+CAST(step_id AS nvarchar)),0) 
						 FROM tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs (NOLOCK))
					ELSE ISNULL(t.Fast,0) + ISNULL(t.Slow,0) 
				END AS NumberOfObjects,
				t.EstimatedRunTimeInSeconds,
				t.EstimatedSlowSpaceInBytes + t.EstimatedFastSpaceInBytes AS CodebaseSize,
				CAST(t.EstimatedSlowSpaceInBytes + t.EstimatedFastSpaceInBytes AS DECIMAL(16,2))/(1024*1024) AS CodebaseSizeInMB,
				runtimes.ActualRunTimeInSeconds,
				CONVERT(nvarchar(10),CONVERT(bigint,(EstimatedRunTimeInSeconds)) / 60) + N'' min '' +
				CONVERT(nvarchar(2), CONVERT(bigint,(EstimatedRunTimeInSeconds)) % 60) + N'' sec''
				AS FriendlyEstimatedRunTime,
				CONVERT(nvarchar(10),CONVERT(bigint,(runtimes.ActualRunTimeInSeconds)) / 60) + N'' min '' +
				CONVERT(nvarchar(2), CONVERT(bigint,(runtimes.ActualRunTimeInSeconds)) % 60) + N'' sec''
				AS FriendlyActualRunTime

		FROM    dbo.SQLRAP_SQLCensus_TimeAndSpace t (NOLOCK)
		LEFT OUTER JOIN
				tempdb.dbo.SQLRAP_SQLCensus_ExcludedDatabases x (NOLOCK)
		ON		t.databaseid = x.databaseid
		FULL OUTER JOIN
		(SELECT databaseid, SUM(DATEDIFF(ms,StartDateTime,EndDateTime)/1000.0) AS ActualRunTimeInSeconds
		FROM    dbo.SQLRAP_SQLCensus_Timings t (NOLOCK)
		GROUP BY databaseid
		) AS runtimes
		ON	runtimes.databaseid = t.databaseid
		WHERE	(x.databaseid IS NULL
				 OR
				(x.databaseid IS NOT NULL AND x.ExcludeDatabase = 0)
				)
'
		)

IF OBJECT_ID('fnSQLRAP_SQLCensus_Presentation') IS NULL
BEGIN
	EXEC('
		CREATE FUNCTION dbo.fnSQLRAP_SQLCensus_Presentation
			(@Keywords1XML ntext,
			 @dbid int,
			 @idoc int)

		RETURNS @Results TABLE
		(
			databaseid				int,
			objectid				int,
			LogicalStatementNumber	int,
			StatementDepth			int,
			Keyword					nvarchar(255),
			LocationInCode			int,
			Iteration				smallint,
			RowNumber				int
		)
		AS

		BEGIN

		DECLARE @Keywords TABLE (
			Keyword nvarchar(255)
		)
		
		-- load the keywords into the table variable
				
		INSERT	@Keywords (Keyword)
		SELECT	[Keyword]
		FROM	OPENXML (@idoc, ''/Keywords[1]/Keyword'')
		WITH	([Keyword] nvarchar(255))
				
		INSERT @Results
		SELECT	sca.databaseid,
				sca.objectid,
				sca.LogicalStatementNumber,
				sca.StatementDepth,
				k.Keyword,
				sca.LocationInCode,
				sca.Iteration,
				sca.RowNumber
		FROM	@Keywords input
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
		ON		k.Keyword						= input.Keyword
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)
		ON		sca.KeywordID					= k.KeywordID
--		AND		sca.databaseid					= @dbid
		AND		sca.IsPartOfObjectDeclaration	= 0

		RETURN
		END'
	)
END

IF OBJECT_ID('fnSQLRAP_SQLCensus_ObjectTypePresentation') IS NULL
BEGIN
	EXEC('
		CREATE FUNCTION dbo.fnSQLRAP_SQLCensus_ObjectTypePresentation
			(@ObjectType nvarchar(2))
		RETURNS nvarchar(100)
		AS
		BEGIN
		RETURN
			CASE @ObjectType 
				WHEN ''AF'' THEN ''Aggregate function (CLR)''
				WHEN ''C''  THEN ''CHECK constraint''
				WHEN ''D''  THEN ''DEFAULT (constraint or stand-alone)''
				WHEN ''F''  THEN ''FOREIGN KEY constraint''
				WHEN ''PK'' THEN ''PRIMARY KEY constraint''
				WHEN ''P''  THEN ''SQL stored procedure''
				WHEN ''PC'' THEN ''Assembly (CLR) stored procedure''
				WHEN ''FN'' THEN ''SQL scalar function''
				WHEN ''FS'' THEN ''Assembly (CLR) scalar function''
				WHEN ''FT'' THEN ''Assembly (CLR) table-valued function''
				WHEN ''R''  THEN ''Rule (old-style, stand-alone)''
				WHEN ''RF'' THEN ''Replication-filter-procedure''
				WHEN ''S''  THEN ''System base table''
				WHEN ''SN'' THEN ''Synonym''
				WHEN ''SQ'' THEN ''Service queue''
				WHEN ''TA'' THEN ''Assembly (CLR) DML trigger''
				WHEN ''TR'' THEN ''SQL DML trigger''
				WHEN ''IF'' THEN ''SQL inline table-valued function''
				WHEN ''TF'' THEN ''SQL table-valued-function''
				WHEN ''U''  THEN ''Table (user-defined)''
				WHEN ''UQ'' THEN ''UNIQUE constraint''
				WHEN ''V''  THEN ''View''
				WHEN ''X''  THEN ''Extended stored procedure''
				WHEN ''IT'' THEN ''Internal table''
				ELSE NULL
			END
		END'
		)
END

IF OBJECT_ID('fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation') IS NULL
BEGIN
	EXEC('
		CREATE FUNCTION dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation
			(@FirstKeyword sysname,
			 @SecondKeyword sysname,
			 @dbid int)
		RETURNS TABLE
		AS

		RETURN
		(
		SELECT	sca1.databaseid,
				sca1.objectid,
				sca1.LogicalStatementNumber,
                sca1.StatementDepth,
				@FirstKeyword + '' '' + @SecondKeyword AS Keyword
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)
		ON		k1.Keyword						= @FirstKeyword
		AND 	k2.Keyword						= @SecondKeyword
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca1 (NOLOCK)
		ON		k1.KeywordID					= sca1.KeywordID
--		AND		sca1.databaseid					= @dbid
		AND		sca1.IsPartOfObjectDeclaration	= 0
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca2 (NOLOCK)
		ON		sca2.KeywordID					= k2.KeywordID
		AND		sca2.IsPartOfObjectDeclaration	= 0
		AND		sca2.databaseid					= sca1.databaseid
		AND		sca2.objectid					= sca1.objectid
		AND		sca2.LogicalStatementNumber		= sca1.LogicalStatementNumber
		AND		sca2.RowNumber					= sca1.RowNumber + 1
		)'
		)
END

IF OBJECT_ID('fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation_invert') IS NULL
BEGIN
	EXEC('
		CREATE FUNCTION dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation_invert
			(@FirstKeyword sysname,
			 @SecondKeyword sysname,
			 @dbid int)
		RETURNS TABLE
		AS

		RETURN
		(
		SELECT	sca1.databaseid,
				sca1.objectid,
				sca1.LogicalStatementNumber,
                sca1.StatementDepth,
				@FirstKeyword + '' '' + @SecondKeyword AS Keyword
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)
		ON		k1.Keyword						= @FirstKeyword
		AND 	k2.Keyword						= @SecondKeyword
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca2 (NOLOCK)
		ON		k2.KeywordID					= sca2.KeywordID
--		AND		sca2.databaseid					= @dbid
		AND		sca2.IsPartOfObjectDeclaration	= 0
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca1 (NOLOCK)
		ON		sca1.KeywordID					= k1.KeywordID
		AND		sca1.IsPartOfObjectDeclaration	= 0
		AND		sca1.databaseid					= sca2.databaseid
		AND		sca1.objectid					= sca2.objectid
		AND		sca1.LogicalStatementNumber		= sca2.LogicalStatementNumber
		AND		sca1.RowNumber					= sca2.RowNumber - 1
		)'
		)
END

IF OBJECT_ID('fnSQLRAP_SQLCensus_NearKeywordsPresentation') IS NULL
BEGIN
	EXEC('
		CREATE FUNCTION dbo.fnSQLRAP_SQLCensus_NearKeywordsPresentation
			(@FirstKeyword sysname,
			 @SecondKeyword sysname,
			 @dbid int)
		RETURNS TABLE
		AS

		RETURN
		(
		SELECT	sca1.databaseid,
				sca1.objectid,
				sca1.LogicalStatementNumber,
				@FirstKeyword + '' '' + @SecondKeyword AS Keyword
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)
		ON		k1.Keyword						= @FirstKeyword
		AND 	k2.Keyword						= @SecondKeyword
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca1 (NOLOCK)
		ON		k1.KeywordID					= sca1.KeywordID
--		AND		sca1.databaseid					= @dbid
		AND		sca1.IsPartOfObjectDeclaration	= 0
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca2 (NOLOCK)
		ON		sca2.KeywordID					= k2.KeywordID
		AND		sca2.IsPartOfObjectDeclaration	= 0
		AND		sca2.databaseid					= sca1.databaseid
		AND		sca2.objectid					= sca1.objectid
		AND		sca2.LogicalStatementNumber		= sca1.LogicalStatementNumber
		AND		sca2.StatementDepth				= sca1.StatementDepth
		--AND		sca2.RowNumber					= sca1.RowNumber + 1
		)'
		)
END

IF OBJECT_ID('fnSQLRAP_SQLCensus_AdjacentLogicalStatementsPresentation') IS NULL
BEGIN
	EXEC('
		CREATE FUNCTION dbo.fnSQLRAP_SQLCensus_AdjacentLogicalStatementsPresentation
			(@FirstKeyword sysname,
			 @SecondKeyword sysname,
			 @dbid int)
		RETURNS TABLE
		AS

		RETURN
		(
		SELECT	sca1.databaseid,
				sca1.objectid,
				sca1.LogicalStatementNumber AS FirstKeywordLogicalStatementNumber,
				sca2.LogicalStatementNumber AS SecondKeywordLogicalStatementNumber,
				@FirstKeyword + '' '' + @SecondKeyword AS Keyword
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)
		ON		k1.Keyword						= @FirstKeyword
		AND 	k2.Keyword						= @SecondKeyword
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca1 (NOLOCK)
		ON		k1.KeywordID					= sca1.KeywordID
--		AND		sca1.databaseid					= @dbid
		AND		sca1.IsPartOfObjectDeclaration	= 0
		AND		sca1.NewStatementStartsHere     = 1
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca2 (NOLOCK)
		ON		sca2.KeywordID					= k2.KeywordID
		AND		sca2.IsPartOfObjectDeclaration	= 0
		AND		sca2.NewStatementStartsHere		= 1
		AND		sca2.databaseid					= sca1.databaseid
		AND		sca2.objectid					= sca1.objectid
		AND		sca2.LogicalStatementNumber		= sca1.LogicalStatementNumber + 1
		--AND		sca2.StatementDepth				= sca1.StatementDepth
		--AND		sca2.RowNumber					= sca1.RowNumber + 1
		)'
		)
END

IF OBJECT_ID('fnSQLRAP_SQLCensus_PresentationForJobs') IS NULL
BEGIN
	EXEC('
		CREATE FUNCTION dbo.fnSQLRAP_SQLCensus_PresentationForJobs
			(@Keywords1XML ntext,
			 @dbid int,
			 @idoc int)

		RETURNS @Results TABLE
		(
			job_id					uniqueidentifier,
			step_id					int,
			LogicalStatementNumber	int,
			StatementDepth			int,
			Keyword					nvarchar(255),
			LocationInCode			int,
			Iteration				smallint,
			RowNumber				int
		)
		AS

		BEGIN

		DECLARE @Keywords TABLE (
			Keyword nvarchar(255)
		)
		
		-- load the keywords into the table variable
				
		INSERT	@Keywords (Keyword)
		SELECT	[Keyword]
		FROM	OPENXML (@idoc, ''/Keywords[1]/Keyword'')
		WITH	([Keyword] nvarchar(255))
				
		INSERT @Results
		SELECT	sca.job_id,
				sca.step_id,
				sca.LogicalStatementNumber,
				sca.StatementDepth,
				k.Keyword,
				sca.LocationInCode,
				sca.Iteration,
				sca.RowNumber
		FROM	@Keywords input
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
		ON		k.Keyword						= input.Keyword
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca (NOLOCK)
		ON		sca.KeywordID					= k.KeywordID
--		AND		sca.databaseid					= @dbid

		RETURN
		END'
	)
END

IF OBJECT_ID('fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs') IS NULL
BEGIN
	EXEC('
		CREATE FUNCTION dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs
			(@FirstKeyword sysname,
			 @SecondKeyword sysname,
			 @dbid int)
		RETURNS TABLE
		AS

		RETURN
		(
		SELECT	sca1.job_id,
				sca1.step_id,
				sca1.LogicalStatementNumber,
                sca1.StatementDepth,
				@FirstKeyword + '' '' + @SecondKeyword AS Keyword
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)
		ON		k1.Keyword						= @FirstKeyword
		AND 	k2.Keyword						= @SecondKeyword
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca1 (NOLOCK)
		ON		k1.KeywordID					= sca1.KeywordID
--		AND		sca1.databaseid					= @dbid
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca2 (NOLOCK)
		ON		sca2.KeywordID					= k2.KeywordID
		AND		sca2.job_id						= sca1.job_id
		AND		sca2.step_id					= sca1.step_id
		AND		sca2.LogicalStatementNumber		= sca1.LogicalStatementNumber
		AND		sca2.RowNumber					= sca1.RowNumber + 1
		)'
		)
END

IF OBJECT_ID('fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs_invert') IS NULL
BEGIN
	EXEC('
		CREATE FUNCTION dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs_invert
			(@FirstKeyword sysname,
			 @SecondKeyword sysname,
			 @dbid int)
		RETURNS TABLE
		AS

		RETURN
		(
		SELECT	sca1.job_id,
				sca1.step_id,
				sca1.LogicalStatementNumber,
                sca1.StatementDepth,
				@FirstKeyword + '' '' + @SecondKeyword AS Keyword
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)
		ON		k1.Keyword						= @FirstKeyword
		AND 	k2.Keyword						= @SecondKeyword
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca2 (NOLOCK)
		ON		k2.KeywordID					= sca2.KeywordID
--		AND		sca2.databaseid					= @dbid
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca1 (NOLOCK)
		ON		sca1.KeywordID					= k1.KeywordID
		AND		sca1.job_id						= sca2.job_id
		AND		sca1.step_id					= sca2.step_id
		AND		sca1.LogicalStatementNumber		= sca2.LogicalStatementNumber
		AND		sca1.RowNumber					= sca2.RowNumber - 1
		)'
		)
END

IF OBJECT_ID('fnSQLRAP_SQLCensus_NearKeywordsPresentationForJobs') IS NULL
BEGIN
	EXEC('
		CREATE FUNCTION dbo.fnSQLRAP_SQLCensus_NearKeywordsPresentationForJobs
			(@FirstKeyword sysname,
			 @SecondKeyword sysname,
			 @dbid int)
		RETURNS TABLE
		AS

		RETURN
		(
		SELECT	sca1.job_id,
				sca1.step_id,
				sca1.LogicalStatementNumber,
				@FirstKeyword + '' '' + @SecondKeyword AS Keyword
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)
		ON		k1.Keyword						= @FirstKeyword
		AND 	k2.Keyword						= @SecondKeyword
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca1 (NOLOCK)
		ON		k1.KeywordID					= sca1.KeywordID
--		AND		sca1.databaseid					= @dbid
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca2 (NOLOCK)
		ON		sca2.KeywordID					= k2.KeywordID
		AND		sca2.job_id						= sca1.job_id
		AND		sca2.step_id					= sca1.step_id
		AND		sca2.LogicalStatementNumber		= sca1.LogicalStatementNumber
		AND		sca2.StatementDepth				= sca1.StatementDepth
		--AND		sca2.RowNumber					= sca1.RowNumber + 1
		)'
		)
END

IF OBJECT_ID('fnSQLRAP_SQLCensus_AdjacentLogicalStatementsPresentationForJobs') IS NULL
BEGIN
	EXEC('
		CREATE FUNCTION dbo.fnSQLRAP_SQLCensus_AdjacentLogicalStatementsPresentationForJobs
			(@FirstKeyword sysname,
			 @SecondKeyword sysname,
			 @dbid int)
		RETURNS TABLE
		AS

		RETURN
		(
		SELECT	sca1.job_id,
				sca1.step_id,
				sca1.LogicalStatementNumber AS FirstKeywordLogicalStatementNumber,
				sca2.LogicalStatementNumber AS SecondKeywordLogicalStatementNumber,
				@FirstKeyword + '' '' + @SecondKeyword AS Keyword
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)
		ON		k1.Keyword						= @FirstKeyword
		AND 	k2.Keyword						= @SecondKeyword
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca1 (NOLOCK)
		ON		k1.KeywordID					= sca1.KeywordID
--		AND		sca1.databaseid					= @dbid
		AND		sca1.NewStatementStartsHere     = 1
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca2 (NOLOCK)
		ON		sca2.KeywordID					= k2.KeywordID
		AND		sca2.NewStatementStartsHere		= 1
		AND		sca2.job_id						= sca1.job_id
		AND		sca2.step_id					= sca1.step_id
		AND		sca2.LogicalStatementNumber		= sca1.LogicalStatementNumber + 1
		--AND		sca2.StatementDepth				= sca1.StatementDepth
		--AND		sca2.RowNumber					= sca1.RowNumber + 1
		)'
		)
END

IF OBJECT_ID('fnSQLRAP_SQLCensus_ExclusionMessageCheck') IS NULL
BEGIN
	EXEC('
	CREATE FUNCTION dbo.fnSQLRAP_SQLCensus_ExclusionMessageCheck
	(
		@objectid	int,
		@databaseid int
	)
	RETURNS nvarchar(1024)
	AS
	BEGIN
	RETURN
		CASE @objectid
			WHEN -1
				THEN ''--== Informational: Database ''
						+ DB_NAME(@databaseid)
						+ '' excluded from SQL Census data collection and report, both by user directive ==--''
			WHEN -2
				THEN ''--== Warning: Database ''
						+ DB_NAME(@databaseid)
						+ '' EXCLUDED from test case execution but included in SQL Census data collection, both by user directive. ==--''
			WHEN -3
				THEN ''--== ERROR: Database ''
						+ DB_NAME(@databaseid)
						+ '' EXCLUDED from SQL Census data collection and then included in test case execution, both by user directive.  Re-run SQL Census Data Collector to resolve. ==--''
			ELSE NULL
		END
	END
	')
END

IF OBJECT_ID('fnSQLRAP_SQLCensus_ExclusionMessagePresentation') IS NULL
BEGIN
	EXEC ('
	CREATE FUNCTION dbo.fnSQLRAP_SQLCensus_ExclusionMessagePresentation
		(@TestCase sysname)
	RETURNS TABLE
	AS
	-- select * from fnSQLRAP_SQLCensus_ExclusionMessagePresentation(''NOT logic'')
	RETURN
	(
	-- scenario 1: informational
	SELECT	x.databaseid, -1 AS objectid, t.Issue AS Keyword
	FROM tempdb.dbo.SQLRAP_SQLCensus_ExcludedDatabases x (NOLOCK)
	LEFT OUTER JOIN
			tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)
	ON		sca.databaseid = x.databaseid
	JOIN	tempdb.dbo.vwSQLRAP_SQLCensus_TestCaseIssue t (NOLOCK)
	ON		t.TestCase = @TestCase
	WHERE	sca.databaseid IS NULL
	AND		x.ExcludeDatabase = 1

	UNION ALL

	-- scenario 2: warning
	SELECT	DISTINCT x.databaseid, -2 AS objectid, t.Issue
	FROM tempdb.dbo.SQLRAP_SQLCensus_ExcludedDatabases x (NOLOCK)
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)
	ON		sca.databaseid = x.databaseid
	AND		x.ExcludeDatabase = 1
	JOIN	tempdb.dbo.vwSQLRAP_SQLCensus_TestCaseIssue t (NOLOCK)
	ON		t.TestCase = @TestCase

	UNION ALL

	-- scenario 3: error
	SELECT	x.databaseid, -3 AS objectid, t.Issue
	FROM tempdb.dbo.SQLRAP_SQLCensus_ExcludedDatabases x (NOLOCK)
	LEFT OUTER JOIN
			tempdb.dbo.SQLRAP_SQLCensus_Timings sca (NOLOCK)
	ON		sca.databaseid = x.databaseid
	JOIN	tempdb.dbo.vwSQLRAP_SQLCensus_TestCaseIssue t (NOLOCK)
	ON		t.TestCase = @TestCase
	WHERE	sca.databaseid IS NULL
	AND		x.ExcludeDatabase = 0
	)
	')
END

IF @Restarted = 0
	SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' -- infrastructure complete' AS [Status]
GO

SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' -- processing scheduled jobs in msdb' AS [Status]

USE [msdb]

--		insert a new record in the timings table
INSERT	tempdb.dbo.SQLRAP_SQLCensus_Timings (databaseid, StartDateTime)
VALUES  (DB_ID(), GETDATE())

DECLARE @debug bit,
		@job_id uniqueidentifier,
		@step_id int,
		@objectdefinition nvarchar(3200),
		@keywordid int,
		@Keyword sysname,
		@KeywordSearchString sysname,
		@KeywordLength int,
		@KeywordSearchStringLength int,
		@RowNumber int,
		@StatementDepth int,
		@LocationInCode int,
		@CanStartStatement bit,
		@ChangesDepthUp int,
		@ChangesDepthDown int,
		@LogicalStatementNumber int,
		@IsPartOfObjectDeclaration bit,
		@PreviousKeyword sysname

DECLARE	@StringLength bigint,
		@LoopCounter bigint,
		@CommentStart bigint,
		@InsideBlockComment bit,
		@InsideLineComment bit

DECLARE	@InsideUpdateDeclaration bit,
		@InsideCursorDeclaration bit,
		@InsideCaseStatement bit,
		@StatementIncrement smallint

SET		@debug = 0

DECLARE GetTheObjects CURSOR FOR
SELECT	j.job_id, s.step_id, ' ' + LOWER(s.command)
FROM	msdb.dbo.sysjobs j (NOLOCK)
JOIN	msdb.dbo.sysjobsteps s (NOLOCK)
ON		j.job_id = s.job_id
AND		s.subsystem = N'TSQL'
LEFT OUTER JOIN
		tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca (NOLOCK)
ON		sca.job_id		= j.job_id
AND		sca.step_id		= s.step_id
WHERE	sca.job_id IS NULL
ORDER BY j.job_id ASC, s.step_id ASC
OPTION (MAXDOP 1)

OPEN GetTheObjects

FETCH NEXT FROM GetTheObjects
INTO @job_id, @step_id, @objectdefinition

WHILE @@FETCH_STATUS = 0
BEGIN

	BEGIN TRAN

	CREATE TABLE #CharacterExclusions (
		StartLocationInCode int,
		EndLocationInCode int,
		ExclusionType nchar(2)
		)

	CREATE INDEX ce1 ON #CharacterExclusions (EndLocationInCode)

    IF   PATINDEX(N'%--%', @objectdefinition COLLATE Latin1_General_BIN) >= 1
    OR   PATINDEX(N'%/*%', @objectdefinition COLLATE Latin1_General_BIN) >= 1

	BEGIN

	 SET @StringLength = LEN(@objectdefinition)
	 
	 SET @LoopCounter = 1
	 
	 SET @InsideBlockComment = 0
	 
	 SET @InsideLineComment = 0

	 WHILE @LoopCounter < @StringLength
	 BEGIN

		-- handle characters inside a block comment
		WHILE (@InsideBlockComment = 1 AND SUBSTRING(@objectdefinition COLLATE Latin1_General_BIN,@LoopCounter,2) <> N'*/' AND @LoopCounter < @StringLength)
		BEGIN
			SET @LoopCounter = @LoopCounter + 1
		END

		-- handle characters inside a line comment
		WHILE (@InsideLineComment = 1 AND SUBSTRING(@objectdefinition COLLATE Latin1_General_BIN,@LoopCounter,1) <> CHAR(10) AND SUBSTRING(@objectdefinition COLLATE Latin1_General_BIN,@LoopCounter,1) <> CHAR(13) AND @LoopCounter < @StringLength)
		BEGIN
			SET @LoopCounter = @LoopCounter + 1
		END

		-- finish handling a block comment
		IF @InsideBlockComment = 1 AND SUBSTRING(@objectdefinition COLLATE Latin1_General_BIN,@LoopCounter,2) = N'*/'
		BEGIN
			SET @InsideBlockComment = 0
			INSERT #CharacterExclusions (StartLocationInCode, EndLocationInCode, ExclusionType) VALUES (@CommentStart, @LoopCounter+1, 'BC') -- block comment
			SET @LoopCounter = @LoopCounter + 2
		END

		-- finish handling a line comment
		ELSE IF @InsideLineComment = 1 AND (SUBSTRING(@objectdefinition COLLATE Latin1_General_BIN,@LoopCounter,1) = CHAR(10) OR SUBSTRING(@objectdefinition COLLATE Latin1_General_BIN,@LoopCounter,1) = CHAR(13))
		BEGIN
			SET @InsideLineComment = 0
			INSERT #CharacterExclusions (StartLocationInCode, EndLocationInCode, ExclusionType) VALUES (@CommentStart, @LoopCounter, 'LC') -- line comment
			SET @LoopCounter = @LoopCounter + 1
		END

		-- start handling a block comment
		ELSE IF @InsideBlockComment = 0 AND @InsideLineComment = 0 AND SUBSTRING(@objectdefinition COLLATE Latin1_General_BIN,@LoopCounter,2) = N'/*'
		BEGIN
			SET @InsideBlockComment = 1
			SET @CommentStart = @LoopCounter
			SET @LoopCounter = @LoopCounter + 2
		END

		-- start handling a line comment
		ELSE IF @InsideBlockComment = 0 AND @InsideLineComment = 0 AND SUBSTRING(@objectdefinition COLLATE Latin1_General_BIN,@LoopCounter,2) = N'--'
		BEGIN
			SET @InsideLineComment = 1
			SET @CommentStart = @LoopCounter
			SET @LoopCounter = @LoopCounter + 2
		END

		-- ignore character and process the next one
		ELSE
		BEGIN
			SET @LoopCounter = @LoopCounter + 1
		END
	 END

	END	 	 
	-- now that we've built a list of the characters which are commented out,
	-- use that list to filter each keyword search.
	
	-- we'll do that in a cursor to minimize memory consumption
	-- (checking for multiple keywords in one statement can explode memory requirement)

	DECLARE GetTheKeywords CURSOR FOR
	SELECT	KeywordID, 
			Keyword,
			KeywordLength,
			KeywordSearchString,
			KeywordSearchStringLength
	FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords (NOLOCK)
	ORDER BY KeywordID ASC

	OPEN GetTheKeywords
	
	FETCH NEXT FROM GetTheKeywords
	INTO	@keywordid,
			@Keyword,
			@KeywordLength,
			@KeywordSearchString,
			@KeywordSearchStringLength

	IF @debug = 1
	BEGIN
		SELECT GETDATE(), @keywordid as LoopCounter, @Keyword
	END

	WHILE @@FETCH_STATUS = 0
	BEGIN

		-- check to see if the keyword exists in the object.
		-- if it does, and it's not commented out, load a reference in the StaticCodeAnalysis table
		
		IF PATINDEX('%' + @Keyword + '%', @objectdefinition COLLATE Latin1_General_BIN) > 0
		BEGIN
			INSERT	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs(
				job_id, 
				step_id, 
				LocationInCode, 
				KeywordID
				)
				--OUTPUT 
				--	inserted.LocationInCode + 1 AS StartLocationInCode,
				--	inserted.LocationInCode + @KeywordLength - 1 AS EndLocationInCode,
				--	'PC' AS ExclusionType  -- PC = ProcessedCode
				--	INTO   #CharacterExclusions
			SELECT
				@job_id AS job_id,
				@step_id AS step_id,
				s.i as LocationInCode,
				@keywordid
			FROM	tempdb.dbo.SQLRAP_SQLCensus_Numbers s (NOLOCK)
			LEFT OUTER JOIN
			  (
				  SELECT  s1.i
				  FROM	  tempdb.dbo.SQLRAP_SQLCensus_Numbers s1 (NOLOCK)
				  JOIN	  #CharacterExclusions x (NOLOCK)
				  ON	  s1.i BETWEEN x.StartLocationInCode AND x.EndLocationInCode
			  ) x
			  ON		x.i = s.i
			  WHERE		x.i IS NULL
			  AND	  s.i <= LEN(@objectdefinition)
			AND		PATINDEX(@KeywordSearchString, SUBSTRING(@objectdefinition COLLATE Latin1_General_BIN, s.i-1, @KeywordSearchStringLength)) = 1
			OPTION  (MAXDOP 1)
		END

		FETCH NEXT FROM GetTheKeywords
		INTO	@keywordid,
				@Keyword,
				@KeywordLength,
				@KeywordSearchString,
				@KeywordSearchStringLength

		IF @debug = 1
		BEGIN
			SELECT GETDATE(), @keywordid AS LoopCounter, @Keyword
		END
		
	END

	CLOSE GetTheKeywords
	
	DEALLOCATE GetTheKeywords

	--	now set RowNumber and StatementDepth
	--	do this in a cursor on StaticCodeCalibration which mimics
	--  what the ROW_NUMBER() call and CTE did

	SET @RowNumber = 0
	SET @StatementDepth = 1
	SET @LogicalStatementNumber = 0
	SET @PreviousKeyword = 'nothing legal in SQL'
	SET @InsideUpdateDeclaration = 0
	SET @InsideCursorDeclaration = 0
	SET @InsideCaseStatement = 0

	DECLARE WalkTheKeywordsFromTheObject CURSOR
	FOR
	SELECT  sca.LocationInCode, k.CanStartStatement, CAST(k.ChangesDepthUp AS INT), CAST(k.ChangesDepthDown AS INT), k.Keyword
	FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca (NOLOCK)
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
	ON		sca.KeywordID	= k.KeywordID
	WHERE	sca.job_id		= @job_id
	AND		sca.step_id     = @step_id
	ORDER BY sca.LocationInCode
	
	OPEN WalkTheKeywordsFromTheObject
	
	FETCH NEXT 
	FROM WalkTheKeywordsFromTheObject
	INTO @LocationInCode,
		 @CanStartStatement,
		 @ChangesDepthUp,
		 @ChangesDepthDown,
		 @Keyword
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
	
		SET @RowNumber = @RowNumber + 1
		
		SET @StatementDepth = @StatementDepth + (@ChangesDepthUp - @ChangesDepthDown)

		-- are we inside a cursor declaration?
		SET @InsideCursorDeclaration =
			CASE
				WHEN (@InsideCursorDeclaration = 0 AND @PreviousKeyword = N'declare' AND @Keyword = N'cursor') THEN 1
				WHEN (@InsideCursorDeclaration = 1 AND @PreviousKeyword = N'select') THEN 0
				ELSE @InsideCursorDeclaration
			END

		-- are we inside an update statement?
		SET	@InsideUpdateDeclaration = 
			CASE
				WHEN (@InsideUpdateDeclaration = 0 AND @InsideCursorDeclaration = 0 AND @Keyword = N'update') THEN 1
				WHEN (@InsideUpdateDeclaration = 1 AND @InsideCursorDeclaration = 0 AND @PreviousKeyword = N'set') THEN 0
				ELSE @InsideUpdateDeclaration
			END
			
		-- are we inside a case statement?
		SET	@InsideCaseStatement = 
			CASE
				WHEN @Keyword = N'case' THEN 1
				WHEN (@InsideCaseStatement = 1 AND @PreviousKeyword = N'end') THEN 0
				ELSE @InsideCaseStatement
			END

		SET @StatementIncrement =
		   CASE  
				-- ignore "update" in "for update" portion of "declare cursor" statement
				WHEN @CanStartStatement = 1
					AND  ((@StatementDepth + @ChangesDepthUp - @ChangesDepthDown) = 1)
--					AND  @InsideCursorDeclaration = 1
					AND	 @PreviousKeyword = N'for'
					AND	 @Keyword = N'update'
					THEN 0

				-- ignore "select" after "for" in of "declare cursor" statement
				WHEN @CanStartStatement = 1
					AND  ((@StatementDepth + @ChangesDepthUp - @ChangesDepthDown) = 1)
					AND  @InsideCursorDeclaration = 1
					AND	 @PreviousKeyword = N'for'
					AND	 @Keyword = N'select'
					THEN 0

				-- ignore "set" in "update" statement
				WHEN @CanStartStatement = 1
					AND  ((@StatementDepth + @ChangesDepthUp - @ChangesDepthDown) = 1)
					AND  @InsideUpdateDeclaration = 1
					AND	 @Keyword = N'set'
					THEN 0

				-- ignore "else" and "end" in "case" statement
				WHEN @CanStartStatement = 1
					AND  ((@StatementDepth + @ChangesDepthUp - @ChangesDepthDown) = 1)
					AND  @InsideCaseStatement = 1
					AND	 @Keyword IN (N'else', N'end')
					THEN 0

				-- exception processing complete; process remainder of data normally
				WHEN @CanStartStatement = 1
					AND  ((@StatementDepth + @ChangesDepthUp - @ChangesDepthDown) = 1)					
				    THEN 1  

				 ELSE 0  
		   END

		SET @LogicalStatementNumber = @LogicalStatementNumber + @StatementIncrement

		UPDATE  tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs
		SET		RowNumber					= @RowNumber,
				StatementDepth				= @StatementDepth,
				NewStatementStartsHere		= CAST(@StatementIncrement AS bit),
				LogicalStatementNumber		= @LogicalStatementNumber
		WHERE	job_id = @job_id
		AND		step_id = @step_id
		AND		LocationInCode = @LocationInCode
		
		SET @PreviousKeyword = @Keyword
		
		FETCH NEXT 
		FROM WalkTheKeywordsFromTheObject
		INTO @LocationInCode,
			 @CanStartStatement,
			 @ChangesDepthUp,
			 @ChangesDepthDown,
			 @Keyword
	
	END
	
	CLOSE WalkTheKeywordsFromTheObject

	DEALLOCATE WalkTheKeywordsFromTheObject

    -- set the iterations
    
    UPDATE sca
	SET Iteration = 
	(
		SELECT	COUNT(*)
		FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs (NOLOCK)
		WHERE	job_id					= sca.job_id
		AND		step_id					= sca.step_id
		AND		LogicalStatementNumber	= sca.LogicalStatementNumber
		AND		StatementDepth			= sca.StatementDepth
		AND		KeywordID				= sca.KeywordID
		AND		LocationInCode			<= sca.LocationInCode
	)
	FROM tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca
	WHERE	job_id	= @job_id
	AND		step_id	= @step_id

	DROP TABLE #CharacterExclusions
	
	UPDATE  tempdb.dbo.SQLRAP_SQLCensus_Timings
	SET		EndDateTime = GETDATE()
	WHERE	databaseid = DB_ID()
	AND		StartDateTime = (SELECT MAX(StartDateTime) FROM tempdb.dbo.SQLRAP_SQLCensus_Timings (NOLOCK) WHERE databaseid = DB_ID())

	COMMIT TRAN
	
	FETCH NEXT FROM
	GetTheObjects
	INTO @job_id, @step_id, @objectdefinition

END

CLOSE GetTheObjects

DEALLOCATE GetTheObjects
GO

DECLARE @SQLString01 nvarchar(4000),
        @SQLString02 nvarchar(4000),
        @SQLString03 nvarchar(4000),
        @SQLString04 nvarchar(4000),
        @SQLString05 nvarchar(4000),
        @SQLString06 nvarchar(4000),
        @SQLString07 nvarchar(4000),
        @SQLString08 nvarchar(4000),
        @SQLString09 nvarchar(4000),
        @SQLString10 nvarchar(4000),
        @spid        nvarchar(10),
        @dbname      sysname


SET     @spid = CAST (@@spid as nvarchar(10))

declare @distribdb sysname
 
exec sp_helpdistributor @distribdb = @distribdb output

DECLARE GetTheDatabases CURSOR FAST_FORWARD FOR
SELECT name
FROM master..sysdatabases s (NOLOCK)
LEFT OUTER JOIN
		tempdb.dbo.SQLRAP_SQLCensus_ExcludedDatabases x (NOLOCK)
ON		s.dbid = x.databaseid
WHERE   lower(s.name) NOT IN (N'master', N'tempdb', N'model', N'msdb', N'pubs', N'northwind', N'adventureworks', N'adventureworksdw')
-- the following line should be uncommented and editted as appropriate for the site
--  to reflect customer databases to be excluded from the process
--AND     lower(name) NOT IN (N'dellstore_campaign_clone', N'dellstore_campaign2_clone', N'DNC_Campaign_clone', N'ecomm4_clone', N'global_dnc_campaign_clone',
                            --N'global_dnc_campaing_q3_pilot_clone', N'MSCS_Admin_clone')
AND  (
	 (@distribdb is not null and lower(s.name) <> lower(@distribdb))  -- bug 243806
	 OR
	 (@distribdb IS NULL)
	 )
-- omit databases which did not start up cleanly
AND		s.status & 32 = 0		-- loading
AND		s.status & 64 = 0		-- pre recovery
AND		s.status & 128 = 0	-- recovering
AND		s.status & 256 = 0	-- not recovered
AND		s.status & 512 = 0	-- offline
AND		s.status & 32768 = 0	-- emergency mode
AND		(x.databaseid IS NULL
		 OR
		(x.databaseid IS NOT NULL AND x.ExcludeDatabase = 0)
		)
ORDER BY s.dbid
OPTION (MAXDOP 1)

OPEN GetTheDatabases

FETCH NEXT FROM GetTheDatabases
INTO @dbname

WHILE @@Fetch_status = 0

BEGIN

SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' -- processing database ' + @dbname AS [Status]

SET @SQLString01 = N'SET XACT_ABORT ON
SET NOCOUNT ON
SET TEXTSIZE 2147483647

DECLARE @dbid int,
        @objectid int,
        @colid int,
        @Pointer int,
        @StringToTest nvarchar(4000),
        @ptrval varbinary(16),
        @OuterLoopFetchStatus int,
        @Lines int,
        @ObjectName sysname,
		@Length int,
		@StringLength bigint,
		@LoopCounter bigint,
		@CommentStart bigint,
		@InsideBlockComment bit,
		@InsideLineComment bit,
		@debug bit,
		@OneChar nchar(1),
		@TwoChar nchar(2),
		@keywordid int,
		@number int,
		@Keyword nvarchar(256),
		@PreviousKeyword nvarchar(256),
		@KeywordSearchString nvarchar(256),
		@RowNumber int,
		@LogicalStatementNumber int,
		@IsPartOfObjectDeclaration bit,
		@KeywordLength int,
		@KeywordSearchStringLength int,
		@StatementDepth int,
		@LocationInCode int,
		@ChangesDepthUp smallint,
		@ChangesDepthDown smallint,
		@CanStartStatement bit,
		@InsideUpdateDeclaration bit,
		@InsideCursorDeclaration bit,
		@InsideCaseStatement bit,
		@StatementIncrement smallint

SET @dbid = db_id(''' + @dbname + N''')

--		insert a new record in the timings table
INSERT	tempdb.dbo.SQLRAP_SQLCensus_Timings (databaseid, StartDateTime)
VALUES  (@dbid, GETDATE())

--		update object count if not set
IF EXISTS (SELECT * FROM tempdb.dbo.SQLRAP_SQLCensus_TimeAndSpace WHERE	databaseid = @dbid AND NumberOfObjects = -2)
BEGIN

	USE [' + @dbname + ']

	SELECT  s.id, 
			s.number,
			SUM(CAST(ISNULL(DATALENGTH(s.text)/2,0) AS BIGINT)) AS ObjectLength,
			COUNT(*) AS Lines
	INTO    #PlaceHolder
	FROM    syscomments s
	JOIN	sysobjects a
	ON		a.id = s.id
	AND		OBJECTPROPERTY(s.id, ''IsMSShipped'') = 0 
	AND     s.encrypted = 0
	AND     s.id NOT IN (
				SELECT OBJECT_ID(objname)
				FROM   ::fn_listextendedproperty (''microsoft_database_tools_support'', default, default, default, default, NULL, NULL)
				WHERE  value = 1)
	GROUP   BY s.id, s.number
	OPTION  (MAXDOP 1)

	UPDATE	tempdb.dbo.SQLRAP_SQLCensus_TimeAndSpace
	SET		Fast = a.Fast,
			Slow = a.Slow,
			EstimatedSlowSpaceInBytes = a.EstimatedSlowSpaceInBytes,
			EstimatedFastSpaceInBytes = a.EstimatedFastSpaceInBytes
	FROM
	(
	SELECT
		CAST (SUM (CASE
			WHEN p.Lines = 1 THEN 1
			ELSE 0
		END) AS bigint) AS Fast,
		CAST (SUM (CASE
			WHEN p.Lines = 1 THEN 0
			ELSE 1
		END) AS bigint) AS Slow,
		CAST (SUM (CASE
			WHEN p.Lines = 1 THEN 0
			ELSE ObjectLength
		END) AS bigint) AS EstimatedSlowSpaceInBytes,
		CAST (SUM (CASE
			WHEN p.Lines = 1 THEN ObjectLength
			ELSE 0
		END) AS bigint) AS EstimatedFastSpaceInBytes
		FROM	#PlaceHolder p
	) a
	WHERE	databaseid = @dbid
	OPTION (MAXDOP 1)

	DROP TABLE #PlaceHolder

	USE [tempdb]

END

CREATE TABLE #ObjectsToCheck (
	id int,
	number int,
	name sysname,
	lines int
	PRIMARY KEY (id, number)
)

INSERT #ObjectsToCheck (id, number, name, lines)
EXEC (''USE [' + @dbname + N'];
SELECT DISTINCT 
       b.id, 
       b.number,
       a.name,
       c.lines
FROM   sysobjects a (NOLOCK)
JOIN   syscomments b (NOLOCK)
ON     a.id           = b.id
AND    b.encrypted    = 0
AND    OBJECTPROPERTYEX(b.id, ''''IsMSShipped'''') = 0 
JOIN   (SELECT   id,
                 number,
                 COUNT(*) AS lines
        FROM     syscomments (NOLOCK)
        WHERE OBJECTPROPERTY(id,''''IsMSShipped'''') = 0
        GROUP BY id, number
) c
ON      b.id          = c.id
AND		b.number      = c.number
ORDER BY b.id, b.number
OPTION (MAXDOP 1, ROBUST PLAN)'')

IF @debug <> 0
BEGIN
	SELECT * FROM #ObjectsToCheck
END
'

SET @SQLString02 = N'
DECLARE GetTheObjects CURSOR FAST_FORWARD 
FOR
SELECT
		o.id, 
        o.number,
        o.lines
FROM  #ObjectsToCheck o (NOLOCK)
LEFT OUTER JOIN tempdb.dbo.SQLRAP_SQLCensus_Objects ob (NOLOCK)
ON    ob.databaseid = @dbid
AND   ob.ObjectId = o.id
AND   ob.Number = o.number
WHERE ob.databaseid IS NULL
ORDER BY o.id, o.number
OPTION (MAXDOP 1)

OPEN GetTheObjects

FETCH NEXT FROM GetTheObjects
INTO @objectid, @number, @Lines

SET @OuterLoopFetchStatus = @@FETCH_STATUS

WHILE @OuterLoopFetchStatus = 0

BEGIN

    BEGIN TRAN

	CREATE TABLE #CharacterExclusions (
		StartLocationInCode int,
		EndLocationInCode int,
		ExclusionType nchar(2)
		)

	CREATE INDEX ce1 ON #CharacterExclusions (EndLocationInCode)

	CREATE TABLE #ConcatenatedCode (
		ConcatenatedCodeId int,
		[text] ntext
	)


	SELECT	@StringToTest = '' '' + ISNULL(LOWER(text),'''')
	FROM	[' + @dbname + N'].dbo.syscomments (NOLOCK)
	WHERE	id = @objectid
	AND		number = @number
	AND		colid = 1

    IF @Lines = 1

    BEGIN
        
		 SET @StringLength = LEN(@StringToTest)
		 
		 SET @LoopCounter = 1
		 
		 SET @InsideBlockComment = 0
		 
		 SET @InsideLineComment = 0

		 WHILE @LoopCounter < @StringLength
		 BEGIN

			-- handle characters inside a block comment
			WHILE (@InsideBlockComment = 1 AND SUBSTRING(@StringToTest COLLATE Latin1_General_BIN,@LoopCounter,2) <> N''*/'' AND @LoopCounter < @StringLength)
			BEGIN
				SET @LoopCounter = @LoopCounter + 1
			END

			-- handle characters inside a line comment
			WHILE (@InsideLineComment = 1 AND SUBSTRING(@StringToTest COLLATE Latin1_General_BIN,@LoopCounter,1) <> CHAR(10) AND SUBSTRING(@StringToTest COLLATE Latin1_General_BIN,@LoopCounter,1) <> CHAR(13) AND @LoopCounter < @StringLength)
			BEGIN
				SET @LoopCounter = @LoopCounter + 1
			END

			-- finish handling a block comment
			IF @InsideBlockComment = 1 AND SUBSTRING(@StringToTest COLLATE Latin1_General_BIN,@LoopCounter,2) = N''*/''
			BEGIN
				SET @InsideBlockComment = 0
				INSERT #CharacterExclusions (StartLocationInCode, EndLocationInCode, ExclusionType) VALUES (@CommentStart, @LoopCounter+1, ''BC'') -- block comment
				SET @LoopCounter = @LoopCounter + 2
			END

			-- finish handling a line comment
			ELSE IF @InsideLineComment = 1 AND (SUBSTRING(@StringToTest COLLATE Latin1_General_BIN,@LoopCounter,1) = CHAR(10) OR SUBSTRING(@StringToTest COLLATE Latin1_General_BIN,@LoopCounter,1) = CHAR(13))
			BEGIN
				SET @InsideLineComment = 0
				INSERT #CharacterExclusions (StartLocationInCode, EndLocationInCode, ExclusionType) VALUES (@CommentStart, @LoopCounter, ''LC'') -- line comment
				SET @LoopCounter = @LoopCounter + 1
			END

			-- start handling a block comment
			ELSE IF @InsideBlockComment = 0 AND @InsideLineComment = 0 AND SUBSTRING(@StringToTest COLLATE Latin1_General_BIN,@LoopCounter,2) = N''/*''
			BEGIN
				SET @InsideBlockComment = 1
				SET @CommentStart = @LoopCounter
				SET @LoopCounter = @LoopCounter + 2
			END

			-- start handling a line comment
			ELSE IF @InsideBlockComment = 0 AND @InsideLineComment = 0 AND SUBSTRING(@StringToTest COLLATE Latin1_General_BIN,@LoopCounter,2) = N''--''
			BEGIN
				SET @InsideLineComment = 1
				SET @CommentStart = @LoopCounter
				SET @LoopCounter = @LoopCounter + 2
			END

			-- ignore character and process the next one
			ELSE
			BEGIN
				SET @LoopCounter = @LoopCounter + 1
			END
		 END -- @LoopCounter < @StringLength
'

SET @SQLString03 = N'
		-- now that we''ve built a list of the characters which are commented out,
		-- use that list to filter each keyword search.
		
		-- we''ll do that in a cursor to minimize memory consumption
		-- (checking for multiple keywords in one statement can explode memory requirement)

		DECLARE GetTheKeywords CURSOR FOR
		SELECT	KeywordID, 
				Keyword,
				KeywordLength,
				KeywordSearchString,
				KeywordSearchStringLength
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords (NOLOCK)
		ORDER BY KeywordID ASC

		OPEN GetTheKeywords
		
		FETCH NEXT FROM GetTheKeywords
		INTO	@keywordid,
				@Keyword,
				@KeywordLength,
				@KeywordSearchString,
				@KeywordSearchStringLength

		IF @debug = 1
		BEGIN
			SELECT GETDATE(), @keywordid as LoopCounter, @Keyword
		END

		WHILE @@FETCH_STATUS = 0
		BEGIN

			-- check to see if the keyword exists in the object.
			-- if it does, and it''s not commented out, load a reference in the StaticCodeAnalysis table
			
			IF PATINDEX(''%'' + @KeywordSearchString + ''%'', @StringToTest COLLATE Latin1_General_BIN) > 0
			BEGIN
				INSERT	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis(
					databaseid, 
					objectid, 
					number,
					LocationInCode, 
					KeywordID
					)
				SELECT DISTINCT
					@dbid,
					@objectid,
					@number,
					CASE
						WHEN @KeywordLength = @KeywordSearchStringLength THEN (s.i - 1)
					    ELSE s.i
					END,
					@keywordid
				FROM	tempdb.dbo.SQLRAP_SQLCensus_Numbers s (NOLOCK)
				LEFT OUTER JOIN
				  (
					  SELECT  s1.i
					  FROM	  tempdb.dbo.SQLRAP_SQLCensus_Numbers s1 (NOLOCK)
					  JOIN	  #CharacterExclusions x (NOLOCK)
					  ON	  s1.i BETWEEN x.StartLocationInCode AND x.EndLocationInCode
				  ) x
				  ON	x.i =
					CASE
						WHEN @KeywordLength = @KeywordSearchStringLength THEN (s.i - 1)
					    ELSE s.i
					END
				  LEFT OUTER JOIN
						tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)
				  ON	sca.databaseid	= @dbid
				  AND	sca.objectid	= @objectid
				  AND	sca.number		= @number
				  AND	sca.KeywordID	= @keywordid
				  WHERE	sca.databaseid	IS NULL
				  AND	s.i <= LEN(@StringToTest)
				  AND	x.i IS NULL
				  AND	PATINDEX(@KeywordSearchString, SUBSTRING(@StringToTest COLLATE Latin1_General_BIN, s.i-1, @KeywordSearchStringLength)) = 1
				  OPTION  (MAXDOP 1)
			END -- PATINDEX

			IF @@ROWCOUNT <> 0
			BEGIN

				INSERT #CharacterExclusions (
					StartLocationInCode,
					EndLocationInCode,
					ExclusionType
					)

				SELECT
					LocationInCode,
					LocationInCode + @KeywordLength - 1,
					''PC''
				FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis (NOLOCK)
				WHERE	databaseid	= @dbid
				AND		objectid	= @objectid
				AND		number		= @number
				AND		KeywordID	= @keywordid
				OPTION  (MAXDOP 1)
			END

			FETCH NEXT FROM GetTheKeywords
			INTO	@keywordid,
					@Keyword,
					@KeywordLength,
					@KeywordSearchString,
					@KeywordSearchStringLength

			IF @debug = 1
			BEGIN
				SELECT GETDATE(), @keywordid AS LoopCounter, @Keyword
			END
			
		END -- @@FETCH_STATUS

		CLOSE GetTheKeywords
		
		DEALLOCATE GetTheKeywords
'

SET @SQLString04 = N'
		--	now set RowNumber, LogicalStatementNumber and StatementDepth
		--	do this in a cursor on StaticCodeCalibration
		--	(this is faster than more modern techniques (CTEs, ROW_NUMBER(), etc.)

		SET @RowNumber = 0
		SET @StatementDepth = 1
		SET @LogicalStatementNumber = 0
		SET @IsPartOfObjectDeclaration = 1
		SET @PreviousKeyword = ''nothing legal in SQL''
		SET @InsideUpdateDeclaration = 0
		SET @InsideCursorDeclaration = 0
		SET @InsideCaseStatement = 0

		DECLARE WalkTheKeywordsFromTheObject CURSOR
		FOR
		SELECT  sca.LocationInCode, k.CanStartStatement, CAST(k.ChangesDepthUp AS INT), CAST(k.ChangesDepthDown AS INT), k.Keyword
		FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
		ON		sca.KeywordID = k.KeywordID
		WHERE	sca.databaseid = @dbid
		AND		sca.objectid    = @objectid
		AND		sca.number		= @number
		ORDER BY sca.LocationInCode
		
		OPEN WalkTheKeywordsFromTheObject

		FETCH NEXT 
		FROM WalkTheKeywordsFromTheObject
		INTO @LocationInCode,
			 @CanStartStatement,
			 @ChangesDepthUp,
			 @ChangesDepthDown,
			 @Keyword
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
		
			SET @RowNumber = @RowNumber + 1
		
			SET @StatementDepth = @StatementDepth + (@ChangesDepthUp - @ChangesDepthDown)

			-- are we inside a cursor declaration?
			SET @InsideCursorDeclaration =
				CASE
					WHEN (@InsideCursorDeclaration = 0 AND @PreviousKeyword = N''declare'' AND @Keyword = N''cursor'') THEN 1
					WHEN (@InsideCursorDeclaration = 1 AND @PreviousKeyword = N''select'') THEN 0
					ELSE @InsideCursorDeclaration
				END

			-- are we inside an update statement?
			SET	@InsideUpdateDeclaration = 
				CASE
					WHEN (@InsideUpdateDeclaration = 0 AND @InsideCursorDeclaration = 0 AND @Keyword = N''update'') THEN 1
					WHEN (@InsideUpdateDeclaration = 1 AND @InsideCursorDeclaration = 0 AND @PreviousKeyword = N''set'') THEN 0
					ELSE @InsideUpdateDeclaration
				END

			-- are we inside a case statement?
			SET	@InsideCaseStatement = 
				CASE
					WHEN @Keyword = N''case'' THEN 1
					WHEN (@InsideCaseStatement = 1 AND @PreviousKeyword = N''end'') THEN 0
					ELSE @InsideCaseStatement
				END

			SET @StatementIncrement =
			   CASE  
					-- ignore "update" in "for update" portion of "declare cursor" statement
					WHEN @CanStartStatement = 1
						AND  ((@StatementDepth + @ChangesDepthUp - @ChangesDepthDown) = 1)
	--					AND  @InsideCursorDeclaration = 1
						AND	 @PreviousKeyword = N''for''
						AND	 @Keyword = N''update''
						THEN 0

					-- ignore "select" after "for" in of "declare cursor" statement
					WHEN @CanStartStatement = 1
						AND  ((@StatementDepth + @ChangesDepthUp - @ChangesDepthDown) = 1)
						AND  @InsideCursorDeclaration = 1
						AND	 @PreviousKeyword = N''for''
						AND	 @Keyword = N''select''
						THEN 0

					-- ignore "set" in "update" statement
					WHEN @CanStartStatement = 1
						AND  ((@StatementDepth + @ChangesDepthUp - @ChangesDepthDown) = 1)
						AND  @InsideUpdateDeclaration = 1
						AND	 @Keyword = N''set''
						THEN 0

					-- ignore "else" and "end" in "case" statement
					WHEN @CanStartStatement = 1
						AND  ((@StatementDepth + @ChangesDepthUp - @ChangesDepthDown) = 1)
						AND  @InsideCaseStatement = 1
						AND	 @Keyword IN (N''else'', N''end'')
						THEN 0

					-- exception processing complete; process remainder of data normally
					WHEN @CanStartStatement = 1
						AND  ((@StatementDepth + @ChangesDepthUp - @ChangesDepthDown) = 1)					
						THEN 1  

					 ELSE 0  
			   END

			SET @LogicalStatementNumber = @LogicalStatementNumber + @StatementIncrement
'

SET @SQLString05 = N'	
			UPDATE  tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis
			SET		RowNumber					= @RowNumber,
					StatementDepth				= @StatementDepth,
					NewStatementStartsHere		=   
					   CASE  
						WHEN @CanStartStatement = 1 AND (@StatementDepth + @ChangesDepthUp - @ChangesDepthDown) = 1  
						 THEN 1  
						ELSE 0  
					   END,
					LogicalStatementNumber		= @LogicalStatementNumber,
					IsPartOfObjectDeclaration	= @IsPartOfObjectDeclaration
			WHERE	databaseid = @dbid
			AND		objectid = @objectid
			AND		number	 = @number
			AND		LocationInCode = @LocationInCode
			OPTION	(MAXDOP 1)

			-- if the object definition is complete, set the flag memvar appropriately

			IF	@IsPartOfObjectDeclaration = 1 
			AND @Keyword = ''as'' 
			AND @PreviousKeyword <> ''execute''
			BEGIN
				SET @IsPartOfObjectDeclaration = 0
			END
			
			SET @PreviousKeyword = @Keyword
		
			FETCH NEXT 
			FROM WalkTheKeywordsFromTheObject
			INTO @LocationInCode,
				 @CanStartStatement,
				 @ChangesDepthUp,
				 @ChangesDepthDown,
				 @Keyword
		
		END -- @@FETCH_STATUS
		
		CLOSE WalkTheKeywordsFromTheObject

		DEALLOCATE WalkTheKeywordsFromTheObject

    END -- @Lines = 1

    ELSE -- @Lines > 1

    BEGIN

        INSERT  #ConcatenatedCode (ConcatenatedCodeId, [text])
        VALUES  (1, N'' '' + @StringToTest)

        SELECT  @ptrval = TEXTPTR([text])
        FROM    #ConcatenatedCode (NOLOCK)
        WHERE   ConcatenatedCodeId = 1
        OPTION (MAXDOP 1)

        --  get the remaining lines
		SET @colid = 2
		
		WHILE @colid <= @Lines
		BEGIN

			SELECT  @ptrval = TEXTPTR([text])
			FROM    #ConcatenatedCode (NOLOCK)
			WHERE   ConcatenatedCodeId = 1
			OPTION (MAXDOP 1)

			SELECT	@StringToTest = ISNULL(LOWER([text]),'''')
			FROM	[' + @dbname + N'].dbo.syscomments (NOLOCK)
			WHERE	id = @objectid
			AND		number = @number
			AND		colid = @colid

            UPDATETEXT #ConcatenatedCode.[text] @ptrval NULL 0 @StringToTest

			SET @colid = @colid + 1

        END

		IF   (SELECT PATINDEX(N''%--%'', [text] COLLATE Latin1_General_BIN) FROM #ConcatenatedCode (NOLOCK) WHERE ConcatenatedCodeId = 1) >= 1
		OR   (SELECT PATINDEX(N''%/*%'', [text] COLLATE Latin1_General_BIN) FROM #ConcatenatedCode (NOLOCK) WHERE ConcatenatedCodeId = 1) >= 1

		BEGIN
		 
		 SELECT  @StringLength = ISNULL(DATALENGTH([text])/2,0)
		 FROM	#ConcatenatedCode (NOLOCK)
		 WHERE	ConcatenatedCodeId = 1

		 SET @LoopCounter = 1
		 
		 SET @InsideBlockComment = 0
		 
		 SET @InsideLineComment = 0

		 WHILE @LoopCounter < @StringLength
		 BEGIN

			-- retrieve the fragments which will drive the test
			SELECT @OneChar = SUBSTRING([text],@LoopCounter,1) FROM #ConcatenatedCode (NOLOCK) WHERE ConcatenatedCodeId = 1
			SELECT @TwoChar = SUBSTRING([text],@LoopCounter,2) FROM #ConcatenatedCode (NOLOCK) WHERE ConcatenatedCodeId = 1

			-- handle characters inside a block comment
			WHILE (@InsideBlockComment = 1 AND @TwoChar <> N''*/'' AND @LoopCounter < @StringLength)
			BEGIN
				SET @LoopCounter = @LoopCounter + 1
				SELECT @TwoChar = SUBSTRING([text],@LoopCounter,2) FROM #ConcatenatedCode (NOLOCK) WHERE ConcatenatedCodeId = 1
			END
'

SET @SQLString06 = N'
			-- handle characters inside a line comment
			WHILE (@InsideLineComment = 1 AND @OneChar <> CHAR(10) AND @OneChar <> CHAR(13) AND @LoopCounter < @StringLength)
			BEGIN
				SET @LoopCounter = @LoopCounter + 1
				SELECT @OneChar = SUBSTRING([text],@LoopCounter,1) FROM #ConcatenatedCode (NOLOCK) WHERE ConcatenatedCodeId = 1
			END

			-- finish handling a block comment
			IF @InsideBlockComment = 1 AND @TwoChar = N''*/''
			BEGIN
				SET @InsideBlockComment = 0
				INSERT #CharacterExclusions (StartLocationInCode, EndLocationInCode, ExclusionType) VALUES (@CommentStart, @LoopCounter+1, ''BC'') -- block comment
				SET @LoopCounter = @LoopCounter + 2
			END

			-- finish handling a line comment
			ELSE IF @InsideLineComment = 1 AND (@OneChar = CHAR(10) OR @OneChar = CHAR(13))
			BEGIN
				SET @InsideLineComment = 0
				INSERT #CharacterExclusions (StartLocationInCode, EndLocationInCode, ExclusionType) VALUES (@CommentStart, @LoopCounter, ''LC'') -- line comment
				SET @LoopCounter = @LoopCounter + 1
			END

			-- start handling a block comment
			ELSE IF @InsideBlockComment = 0 AND @InsideLineComment = 0 AND @TwoChar = N''/*''
			BEGIN
				SET @InsideBlockComment = 1
				SET @CommentStart = @LoopCounter
				SET @LoopCounter = @LoopCounter + 2
			END

			-- start handling a line comment
			ELSE IF @InsideBlockComment = 0 AND @InsideLineComment = 0 AND @TwoChar = N''--''
			BEGIN
				SET @InsideLineComment = 1
				SET @CommentStart = @LoopCounter
				SET @LoopCounter = @LoopCounter + 2
			END

			-- ignore character and process the next one
			ELSE
			BEGIN
				SET @LoopCounter = @LoopCounter + 1
			END
		 END  -- @LoopCounter < @StringLength

	 END -- PATINDEX

	-- now that we''ve built a list of the characters which are commented out,
	-- use that list to filter each keyword search.
	
	-- we''ll do that in a cursor to minimize memory consumption
	-- (checking for multiple keywords in one statement can explode memory requirement)

	DECLARE GetTheKeywords CURSOR FOR
	SELECT	KeywordID, 
			Keyword,
			KeywordLength,
			KeywordSearchString,
			KeywordSearchStringLength
	FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords (NOLOCK)
	ORDER BY KeywordID ASC

	OPEN GetTheKeywords
	
	FETCH NEXT FROM GetTheKeywords
	INTO	@keywordid,
			@Keyword,
			@KeywordLength,
			@KeywordSearchString,
			@KeywordSearchStringLength

	IF @debug = 1
	BEGIN
		SELECT GETDATE(), @keywordid as LoopCounter, @Keyword
	END

	WHILE @@FETCH_STATUS = 0
	BEGIN

		-- check to see if the keyword exists in the object.
		-- if it does, and it''s not commented out, load a reference in the StaticCodeAnalysis table
		
		IF (SELECT PATINDEX(''%'' + @Keyword + ''%'',[text] COLLATE Latin1_General_BIN)
			FROM #ConcatenatedCode  (NOLOCK)
			WHERE ConcatenatedCodeId = 1
			) > 0

		BEGIN
			INSERT	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis(
				databaseid, 
				objectid,
				number,
				LocationInCode, 
				KeywordID
				)
			SELECT DISTINCT
				@dbid,
				@objectid,
				@number,
				s.i,
				@keywordid
			  FROM	#ConcatenatedCode c (NOLOCK)
			  JOIN	tempdb.dbo.SQLRAP_SQLCensus_Numbers s (NOLOCK)
			  ON	c.ConcatenatedCodeId = 1
			  AND	s.i			<= @StringLength
			  LEFT OUTER JOIN
			  (
				  SELECT  s1.i
				  FROM	  tempdb.dbo.SQLRAP_SQLCensus_Numbers s1 (NOLOCK)
				  JOIN	  #CharacterExclusions x (NOLOCK)
				  ON	  s1.i BETWEEN x.StartLocationInCode AND x.EndLocationInCode
			  ) x
			  ON	x.i = s.i
			  WHERE	x.i IS NULL
			  AND	PATINDEX(@KeywordSearchString, SUBSTRING(c.[text] COLLATE Latin1_General_BIN, s.i-1, @KeywordSearchStringLength)) = 1
			  OPTION  (MAXDOP 1)
'

SET @SQLString07 = N'
			IF @@ROWCOUNT <> 0
			BEGIN

				INSERT #CharacterExclusions (
					StartLocationInCode,
					EndLocationInCode,
					ExclusionType
					)

				SELECT
					LocationInCode,
					LocationInCode + @KeywordLength -1,
					''PC''
				FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis (NOLOCK)
				WHERE	databaseid	= @dbid
				AND		objectid	= @objectid
				AND		number		= @number
				AND		KeywordID	= @keywordid
				OPTION  (MAXDOP 1)
			END
		END -- PATINDEX

		FETCH NEXT FROM GetTheKeywords
		INTO	@keywordid,
				@Keyword,
				@KeywordLength,
				@KeywordSearchString,
				@KeywordSearchStringLength

		IF @debug = 1
		BEGIN
			SELECT GETDATE(), @keywordid AS LoopCounter, @Keyword
		END
		
	END

	CLOSE GetTheKeywords
	
	DEALLOCATE GetTheKeywords

	--	now set RowNumber, LogicalStatementNumber and StatementDepth
	--	do this in a cursor on StaticCodeCalibration
	--	(this is faster than more modern techniques (CTEs, ROW_NUMBER(), etc.)

	SET @RowNumber = 0
	SET @StatementDepth = 1
	SET @LogicalStatementNumber = 0
	SET @IsPartOfObjectDeclaration = 1
	SET @PreviousKeyword = ''nothing legal in SQL''
	SET @InsideUpdateDeclaration = 0
	SET @InsideCursorDeclaration = 0
	SET @InsideCaseStatement = 0

	DECLARE WalkTheKeywordsFromTheObject CURSOR
	FOR
	SELECT  sca.LocationInCode, k.CanStartStatement, CAST(k.ChangesDepthUp AS INT), CAST(k.ChangesDepthDown AS INT), k.Keyword
	FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
	ON		sca.KeywordID	= k.KeywordID
	WHERE	sca.databaseid	= @dbid
	AND		sca.objectid    = @objectid
	AND	    sca.number		= @number
	ORDER BY sca.LocationInCode
	
	OPEN WalkTheKeywordsFromTheObject
	
	FETCH NEXT 
	FROM WalkTheKeywordsFromTheObject
	INTO @LocationInCode,
		 @CanStartStatement,
		 @ChangesDepthUp,
		 @ChangesDepthDown,
		 @Keyword

	WHILE @@FETCH_STATUS = 0
	BEGIN
	
		SET @RowNumber = @RowNumber + 1
		
		SET @StatementDepth = @StatementDepth + (@ChangesDepthUp - @ChangesDepthDown)

		-- are we inside a cursor declaration?
		SET @InsideCursorDeclaration =
			CASE
				WHEN (@InsideCursorDeclaration = 0 AND @PreviousKeyword = N''declare'' AND @Keyword = N''cursor'') THEN 1
				WHEN (@InsideCursorDeclaration = 1 AND @PreviousKeyword = N''select'') THEN 0
				ELSE @InsideCursorDeclaration
			END

		-- are we inside an update statement?
		SET	@InsideUpdateDeclaration = 
			CASE
				WHEN (@InsideUpdateDeclaration = 0 AND @InsideCursorDeclaration = 0 AND @Keyword = N''update'') THEN 1
				WHEN (@InsideUpdateDeclaration = 1 AND @InsideCursorDeclaration = 0 AND @PreviousKeyword = N''set'') THEN 0
				ELSE @InsideUpdateDeclaration
			END

		-- are we inside a case statement?
		SET	@InsideCaseStatement = 
			CASE
				WHEN @Keyword = N''case'' THEN 1
				WHEN (@InsideCaseStatement = 1 AND @PreviousKeyword = N''end'') THEN 0
				ELSE @InsideCaseStatement
			END

		SET @StatementIncrement =
		   CASE  
				-- ignore "update" in "for update" portion of "declare cursor" statement
				WHEN @CanStartStatement = 1
					AND  ((@StatementDepth + @ChangesDepthUp - @ChangesDepthDown) = 1)
--					AND  @InsideCursorDeclaration = 1
					AND	 @PreviousKeyword = N''for''
					AND	 @Keyword = N''update''
					THEN 0
'

SET @SQLString08 = N'
				-- ignore "select" after "for" in of "declare cursor" statement
				WHEN @CanStartStatement = 1
					AND  ((@StatementDepth + @ChangesDepthUp - @ChangesDepthDown) = 1)
					AND  @InsideCursorDeclaration = 1
					AND	 @PreviousKeyword = N''for''
					AND	 @Keyword = N''select''
					THEN 0

				-- ignore "set" in "update" statement
				WHEN @CanStartStatement = 1
					AND  ((@StatementDepth + @ChangesDepthUp - @ChangesDepthDown) = 1)
					AND  @InsideUpdateDeclaration = 1
					AND	 @Keyword = N''set''
					THEN 0

				-- ignore "else" and "end" in "case" statement
				WHEN @CanStartStatement = 1
					AND  ((@StatementDepth + @ChangesDepthUp - @ChangesDepthDown) = 1)
					AND  @InsideCaseStatement = 1
					AND	 @Keyword IN (N''else'', N''end'')
					THEN 0

				-- exception processing complete; process remainder of data normally
				WHEN @CanStartStatement = 1
					AND  ((@StatementDepth + @ChangesDepthUp - @ChangesDepthDown) = 1)					
				    THEN 1  

				 ELSE 0  
		   END

		SET @LogicalStatementNumber = @LogicalStatementNumber + @StatementIncrement

		UPDATE  tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis
		SET		RowNumber					= @RowNumber,
				StatementDepth				= @StatementDepth,
				NewStatementStartsHere		= CAST(@StatementIncrement AS bit),
				LogicalStatementNumber		= @LogicalStatementNumber,
				IsPartOfObjectDeclaration	= @IsPartOfObjectDeclaration
		WHERE	databaseid = DB_ID()
		AND		objectid = @objectid
		AND		LocationInCode = @LocationInCode
		OPTION	(MAXDOP 1)

		-- if the object definition is complete, set the flag memvar appropriately

		IF	@IsPartOfObjectDeclaration = 1 
		AND @Keyword = ''as'' 
		AND @PreviousKeyword <> ''execute''
		BEGIN
			SET @IsPartOfObjectDeclaration = 0
		END
		
		SET @PreviousKeyword = @Keyword
		
		FETCH NEXT 
		FROM WalkTheKeywordsFromTheObject
		INTO @LocationInCode,
			 @CanStartStatement,
			 @ChangesDepthUp,
			 @ChangesDepthDown,
			 @Keyword
	
	END
	
	CLOSE WalkTheKeywordsFromTheObject

	DEALLOCATE WalkTheKeywordsFromTheObject

    END -- @Lines > 1

    -- set the iterations
    
    UPDATE sca
	SET Iteration = 
	(
		SELECT	COUNT(*)
		FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis (NOLOCK)
		WHERE	databaseid				= @dbid
		AND		objectid				= @objectid
		AND		number					= @number
		AND		LogicalStatementNumber	= sca.LogicalStatementNumber
		AND		StatementDepth			= sca.StatementDepth
		AND		KeywordID				= sca.KeywordID
		AND		LocationInCode			<= sca.LocationInCode
	)
	FROM tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca
	WHERE	databaseid	= @dbid
	AND		objectid	= @objectid
	AND		number		= @number

	DROP TABLE #CharacterExclusions

	DROP TABLE #ConcatenatedCode
'

SET @SQLString09 = N'
	USE [' + @dbname + N']


	INSERT tempdb.dbo.SQLRAP_SQLCensus_Objects (
		databaseid,
		ObjectId,
		Number,
		ObjectName,
		ObjectOwner,
		ObjectType,
        ExtendedProperties
	)
	SELECT
		@dbid,
		@objectid,
		@number,
		name,
		USER_NAME(uid),
		xtype,
        CASE
            WHEN xtype != N''TR''
		        THEN NULL
            ELSE
                CASE
                    WHEN OBJECTPROPERTY(id,N''ExecIsFirstDeleteTrigger'') = 1
                        THEN N''First SQL DML DELETE trigger''
                    WHEN OBJECTPROPERTY(id,N''ExecIsLastDeleteTrigger'') = 1
                        THEN N''Last SQL DML DELETE trigger''
                    WHEN OBJECTPROPERTY(id,N''ExecIsDeleteTrigger'') = 1
                        THEN N''SQL DML DELETE trigger''
                    WHEN OBJECTPROPERTY(id,N''ExecIsFirstInsertTrigger'') = 1
                        THEN N''First SQL DML INSERT trigger''
                    WHEN OBJECTPROPERTY(id,N''ExecIsLastInsertTrigger'') = 1
                        THEN N''Last SQL DML INSERT trigger''
                    WHEN OBJECTPROPERTY(id,N''ExecIsInsertTrigger'') = 1
                        THEN N''SQL DML INSERT trigger''
                    WHEN OBJECTPROPERTY(id,N''ExecIsFirstUpdateTrigger'') = 1
                        THEN N''First SQL DML UPDATE trigger''
                    WHEN OBJECTPROPERTY(id,N''ExecIsLastUpdateTrigger'') = 1
                        THEN N''Last SQL DML UPDATE trigger''
                    WHEN OBJECTPROPERTY(id,N''ExecIsUpdateTrigger'') = 1
                        THEN N''SQL DML UPDATE trigger''
                    WHEN OBJECTPROPERTY(id,N''ExecIsAfterTrigger'') = 1
                        THEN N''SQL DML AFTER trigger''
                    WHEN OBJECTPROPERTY(id,N''ExecIsInsteadOfTrigger'') = 1
                        THEN N''SQL DML INSTEAD OF trigger''
                    ELSE N''Trigger''
                END + N'' on '' + USER_NAME(uid) + N''.'' + OBJECT_NAME(parent_obj) +
                CASE
                    WHEN OBJECTPROPERTYEX(id,N''ExecIsTriggerDisabled'') = 1
                        THEN N'' (disabled)''
                    ELSE N''''    
                END
            END COLLATE DATABASE_DEFAULT

	FROM	dbo.sysobjects (NOLOCK)
	WHERE	id		= @objectid

	USE [tempdb]

	UPDATE  tempdb.dbo.SQLRAP_SQLCensus_Timings
	SET		EndDateTime = GETDATE()
	WHERE	databaseid = @dbid
	AND		StartDateTime = (SELECT MAX(StartDateTime) FROM tempdb.dbo.SQLRAP_SQLCensus_Timings (NOLOCK) WHERE databaseid = @dbid)

	COMMIT TRAN

    FETCH NEXT FROM GetTheObjects
    INTO @objectid, @number, @Lines
    
    SET @OuterLoopFetchStatus	= @@FETCH_STATUS

END -- @OuterLoopFetchStatus = 0

CLOSE GetTheObjects

DEALLOCATE GetTheObjects'

SET @SQLString10 = N''

--select @dbname, len(@SQLString01),len(@SQLString02),len(@SQLString03),len(@SQLString04),len(@SQLString05),len(@SQLString06),len(@SQLString07),len(@SQLString08),len(@SQLString09),len(@SQLString10)

EXEC (@SQLString01 + @SQLString02 + @SQLString03 + @SQLString04 + @SQLString05 + @SQLString06 + @SQLString07 + @SQLString08 + @SQLString09 + @SQLString10)

FETCH NEXT FROM GetTheDatabases
INTO @dbname

END --@@FETCH_STATUS = 0

CLOSE GetTheDatabases
DEALLOCATE GetTheDatabases

USE tempdb

SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' -- building new indexes' AS [Status]

CREATE NONCLUSTERED INDEX q5
ON [dbo].[SQLRAP_SQLCensus_StaticCodeAnalysis] ([KeywordID],[IsPartOfObjectDeclaration],[databaseid],[objectid],[LocationInCode],[LogicalStatementNumber],[StatementDepth], [Iteration])

CREATE NONCLUSTERED INDEX q6
ON [dbo].[SQLRAP_SQLCensus_StaticCodeAnalysis] ([IsPartOfObjectDeclaration],[databaseid],[objectid],[RowNumber],[LogicalStatementNumber],[KeywordID], [Iteration])

CREATE NONCLUSTERED INDEX q7
ON [dbo].[SQLRAP_SQLCensus_StaticCodeAnalysis] ([KeywordID],[IsPartOfObjectDeclaration],[databaseid],[objectid],[RowNumber],[LogicalStatementNumber], [Iteration])

CREATE NONCLUSTERED INDEX q8
ON [dbo].[SQLRAP_SQLCensus_StaticCodeAnalysis] ([NewStatementStartsHere],[IsPartOfObjectDeclaration],[databaseid],[objectid],[LogicalStatementNumber],[KeywordID], [Iteration])

CREATE NONCLUSTERED INDEX q9
ON [dbo].[SQLRAP_SQLCensus_StaticCodeAnalysis] ([IsPartOfObjectDeclaration],[databaseid],[objectid],[LogicalStatementNumber],[StatementDepth],[KeywordID], [Iteration])

CREATE NONCLUSTERED INDEX q10
ON [dbo].[SQLRAP_SQLCensus_StaticCodeAnalysis] ([Iteration],[IsPartOfObjectDeclaration],[KeywordID])

CREATE NONCLUSTERED INDEX jq7
ON [dbo].[SQLRAP_SQLCensus_StaticCodeAnalysisForJobs] ([KeywordID],[job_id],[step_id],[RowNumber],[LogicalStatementNumber], [Iteration])

CREATE NONCLUSTERED INDEX jq8
ON [dbo].[SQLRAP_SQLCensus_StaticCodeAnalysisForJobs] ([NewStatementStartsHere],[job_id],[step_id],[LogicalStatementNumber],[KeywordID], [Iteration])

CREATE NONCLUSTERED INDEX jq10
ON [dbo].[SQLRAP_SQLCensus_StaticCodeAnalysisForJobs] ([Iteration],[KeywordID])

SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' -- performing index maintenance' AS [Status]

--ALTER INDEX ALL ON dbo.SQLRAP_SQLCensus_StaticCodeAnalysis REBUILD

UPDATE STATISTICS dbo.SQLRAP_SQLCensus_StaticCodeAnalysis
WITH FULLSCAN

UPDATE STATISTICS dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs
WITH FULLSCAN

EXEC sp_recompile 'dbo.SQLRAP_SQLCensus_StaticCodeAnalysis'

EXEC sp_recompile 'dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs'

SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' -- --==Complete==--' AS [Status]
