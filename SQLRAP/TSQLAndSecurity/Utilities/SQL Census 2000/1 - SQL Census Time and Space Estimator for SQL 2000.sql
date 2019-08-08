-- Signature="3D8E55B665C7E6E5"

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    SQL Census Time and Space Estimator for SQL 2000.sql                                              ****/
--/****    estimates resource consumption for a SQL Census Data Collector run on a SQL Server 2000 instance  ****/
--/****                                                                                                      ****/
--/****    2010.Mar.11 - created (wardp) - adapted from the 2005 script                                      ****/
--/****    2010.Sep.11 - updated (wardp) - bug 468251                                                        ****/
--/****    2010.Sep.21 - updated (wardp) - bug 468699                                                        ****/
--/****    2010.Sep.30 - updated (wardp) - bug 468895                                                        ****/
--/****    2010.Oct.01 - updated (wardp) - bug 468926                                                        ****/
--/****    2010.Oct.07 - updated (wardp) - bug 417498                                                        ****/
--/****    2010.Dec.06 - updated (rajpo) - bug 471301 case sensitivity                                       ****/
--/****                                                                                                      ****/
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
	SET @ErrorString = 'Attempt to run SQL Server 2000 (SQL Server version 8) SQLRAP Time and Space Estimator against a SQL Server '
					  + CASE
						  WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),4) = '10.5' THEN '2008 R2'
						  WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),2) = '10'   THEN '2008'
						  WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),2) = '9.'   THEN '2005'
					    END
					  + ' version '
					  + CAST(SERVERPROPERTY('ProductVersion') AS nvarchar)
					  + ' instance.  Process terminated.'
					  + CHAR(13) + CHAR(10)
					  + 'Please run the SQL Server '
					  + CASE
						  WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),2) = '10'   THEN '2008'
						  WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),2) = '9.'   THEN '2005'
					    END
					  + ' SQLRAP Time and Space Estimator against this instance.'
	RAISERROR (@ErrorString, 25, 1) WITH LOG
END
GO

-- check for bootstrap object; a failure will be logged if it's not found
IF OBJECT_ID('SQLRAP_SQLCensus_ExcludedDatabases') IS NULL
BEGIN
	DECLARE @ErrorString nvarchar(4000)
	SET @ErrorString = 'Attempt to run SQL Server 2000 SQLRAP TimeAndSpaceEstimator without first running Bootstrap process.  Process terminated.'
					  + CHAR(13) + CHAR(10)
					  + 'Please run the SQL Server 2000 Bootstrap against this instance.'
	RAISERROR (@ErrorString, 25, 1) WITH LOG
END
GO

SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' -- Building Infrastructure' AS [Status]
GO
IF (OBJECTPROPERTY(OBJECT_ID('dbo.SQLRAP_SQLCensus_SummaryForCalibration'), 'IsView') = 1)
	DROP VIEW dbo.SQLRAP_SQLCensus_SummaryForCalibration
IF (OBJECTPROPERTY(OBJECT_ID('dbo.SQLRAP_SQLCensus_Numbers'), 'IsTable') = 1)
	DROP TABLE dbo.SQLRAP_SQLCensus_Numbers
IF (OBJECTPROPERTY(OBJECT_ID('dbo.SQLRAP_SQLCensus_TimeAndSpace'), 'IsTable') = 1)
	DROP TABLE dbo.SQLRAP_SQLCensus_TimeAndSpace
IF (OBJECTPROPERTY(OBJECT_ID('dbo.SQLRAP_SQLCensus_Keywords'), 'IsTable') = 1)
	DROP TABLE dbo.SQLRAP_SQLCensus_Keywords
IF (OBJECTPROPERTY(OBJECT_ID('dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration'), 'IsTable') = 1)
	DROP TABLE dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration
IF (OBJECTPROPERTY(OBJECT_ID('dbo.SQLRAP_SQLCensus_ObjectsForCalibration'), 'IsTable') = 1)
	DROP TABLE dbo.SQLRAP_SQLCensus_ObjectsForCalibration
IF (OBJECTPROPERTY(OBJECT_ID('dbo.SQLRAP_SQLCensus_RunTimeEstimates'), 'IsTable') = 1)
	DROP TABLE dbo.SQLRAP_SQLCensus_RunTimeEstimates
GO
CREATE TABLE dbo.SQLRAP_SQLCensus_Numbers(i int PRIMARY KEY)
GO
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
GO
CREATE TABLE dbo.SQLRAP_SQLCensus_RunTimeEstimates (
		databaseid int,
		FastProcessTimeInSeconds decimal(12,4),
		SlowProcessTimeInSeconds decimal(12,4),
		FastAverageInMS decimal(12,4),
		SlowAverageInMS decimal(12,4),
		FastCodebaseSizeInBytes bigint,
		SlowCodebaseSizeInBytes bigint,
		NumberOfFastObjects bigint,
		NumberOfSlowObjects bigint,
		AverageSizeOfFastObject AS FastCodebaseSizeInBytes/NumberOfFastObjects,
		AverageSizeOfSlowObject AS SlowCodebaseSizeInBytes/NumberOfSlowObjects
		)
GO

CREATE TABLE dbo.SQLRAP_SQLCensus_TimeAndSpace (
    DatabaseName                sysname,
    databaseid                  int PRIMARY KEY,
    EstimateRun					bit DEFAULT(1),
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

--CREATE INDEX NDX_1_SQLRAP_SQLCensus_TimeAndSpace ON dbo.SQLRAP_SQLCensus_TimeAndSpace (EstimatedRunTimeInSeconds DESC)
--
--CREATE INDEX NDX_2_SQLRAP_SQLCensus_TimeAndSpace ON dbo.SQLRAP_SQLCensus_TimeAndSpace (EstimatedSpaceInKB DESC)

--SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' --   Results Table Created'
GO

CREATE VIEW dbo.SQLRAP_SQLCensus_SummaryForCalibration AS
SELECT  t.DatabaseName,
        t.databaseid,
        ISNULL(t.Fast,0) + ISNULL(t.Slow,0) AS Total,
        ISNULL(t.Fast,0) + ISNULL(t.Slow,0) AS NumberOfObjects,
        t.EstimatedRunTimeInSeconds,
        t.ActualRunTimeInSeconds,
        (ISNULL(t.EstimatedSlowSpaceInBytes,0) + ISNULL(t.EstimatedFastSpaceInBytes,0)) / 1024 AS EstimatedSpaceInKB,
        CONVERT(decimal(16,2),(ISNULL(t.EstimatedSlowSpaceInBytes,0) + ISNULL(t.EstimatedFastSpaceInBytes,0))) / (1024 * 1024) AS EstimatedSpaceInMB,
        CONVERT(nvarchar(10),(CONVERT(int,t.EstimatedRunTimeInSeconds) / 60)) + N' min ' +
        CONVERT(nvarchar(2), (CONVERT(int,t.EstimatedRunTimeInSeconds) % 60)) + N' sec'
        AS FriendlyEstimatedRunTime,
        CONVERT(nvarchar(10),ISNULL(CAST(t.ActualRunTimeInSeconds AS INT)/ 60,0)) + N' min ' +
        CONVERT(nvarchar(2), ISNULL(CAST(t.ActualRunTimeInSeconds AS INT) % 60,0)) + N' sec'
        AS FriendlyActualRunTime,
        ISNULL(t.Fast,0) AS [Fast],
        ISNULL(t.Slow,0) AS Slow,
        r.FastAverageInMS AS FastAverageInMS,
        r.SlowAverageInMS AS SlowAverageInMS,
        ISNULL(t.EstimatedSlowSpaceInBytes,0) AS EstimatedSlowSpaceInBytes,
        ISNULL(t.EstimatedFastSpaceInBytes,0) AS EstimatedFastSpaceInBytes,
        r.AverageSizeOfFastObject,
        r.AverageSizeOfSlowObject

FROM    dbo.SQLRAP_SQLCensus_TimeAndSpace t
JOIN	dbo.SQLRAP_SQLCensus_RunTimeEstimates r
ON		r.databaseid = DB_ID('msdb')
LEFT OUTER JOIN
		tempdb.dbo.SQLRAP_SQLCensus_ExcludedDatabases x
ON		t.databaseid = x.databaseid
WHERE	(x.databaseid IS NULL
		 OR
		(x.databaseid IS NOT NULL AND x.ExcludeDatabase = 0)
		)
GO

CREATE TABLE dbo.SQLRAP_SQLCensus_Keywords (
	KeywordID			int identity(1,1) primary key,
	Keyword				nvarchar(64),	-- the keyword itself
	KeywordSearchString	AS				-- the keyword with whitespace around it (except for parens and old outer joins)
		CASE
		WHEN Keyword IN ('<>', '!=', '!<', '!>', '=*', '*=', '*', '(', ')', '../', 'xp_cmdshell') THEN Keyword
		ELSE N'[/, (' + CHAR(9) + CHAR(10) + CHAR(13) + ''']'
				+ Keyword
				+ N'[/, ()' + CHAR(9) + CHAR(10) + CHAR(13) + ''']'
		END,
	ChangesDepthUp		bit,			-- used to calculate statement depth; only applies to open paren
	ChangesDepthDown	bit,			-- used to calculate statement depth; only applies to close paren
	KeywordLength		AS LEN(Keyword),
	KeywordSearchStringLength AS		-- the Length of the keyword and its whitespace
		CASE
		WHEN Keyword IN ('<>', '!=', '!<', '!>', '=*', '*=', '*', '(', ')', '../', 'xp_cmdshell') THEN LEN(Keyword)
		ELSE LEN(Keyword) + 2
		END,
	CanStartStatement		bit
)

--CREATE UNIQUE INDEX Keyword ON dbo.SQLRAP_SQLCensus_Keywords(Keyword)
GO

-- populate Keywords table

BEGIN TRAN

-- terms which can change depth

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('(', 1, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES(')', 0, 1, 0)

-- terms which can start a statement
INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('insert', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('select', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('update', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('add', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('alter', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('backup', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('begin', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('break', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('bulk', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('checkpoint', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('commit', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('continue', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('create', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('dbcc', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('declare', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('delete', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('deny', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('disable', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('drop', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('enable', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('end', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('exec', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('execute', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('go', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('goto', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('grant', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('if', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('kill', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('load', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('merge', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('move', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('print', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('readtext', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('receive', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('reconfigure', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('restore', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('return', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('revert', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('revoke', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('rollback', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('save', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('send', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('set', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('setuser', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('shutdown', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('truncate', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('updatetext', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('use', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('waitfor', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('while', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('with', 0, 0, 0)  -- going to need to figure out something for CTEs..

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('writetext', 0, 0, 1)

-- cursor-related terms

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('close', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('deallocate', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('dynamic', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('fetch',  0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('global',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('insensitive',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('keyset',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('open', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('static',  0, 0, 0)

-- join hint-related terms

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('hash',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('loop',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('remote',  0, 0, 0)

-- locking hint-related terms

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('holdlock',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('nolock',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('paglock',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('readcommitted',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('readpast',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('readuncommitted',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('repeatableread',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('rowlock',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('serializable',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('tablock',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('tablockx',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('updlock',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('xlock',  0, 0, 0)

-- query hint related terms

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('concat',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('expand',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('fast',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('force',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('forced',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('group',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('keep',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('keepfixed',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('maxdop',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('maxrecursion',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('optimize',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('option',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('order',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('parameterization',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('plan',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('recompile',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('robust',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('simple',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('views',  0, 0, 0)

-- XML related terms (excluded in SQL Server 2000 except for single root node)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('[1]',  0, 0, 0) -- single root node

--NOTE THERE'S MORE TO DO HERE

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('xp_cmdshell', 0, 0, 0)

-- other terms of interest

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('*=', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('=*', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('<>', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('!=', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('!>', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('!<', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('*', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('as', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('between', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('caller', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('case', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('committed', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('cursor', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('else', 0, 0, 1)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('exists', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('from', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('in', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('join', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('like', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('not', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('on', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('owner', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('read', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('repeatable', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('self', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('snapshot', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('transaction', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('tran', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('uncommitted', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('union', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('when', 0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('where', 0, 0, 0)

COMMIT TRAN
GO
-- begin test
--SELECT Keyword FROM tempdb.dbo.SQLRAP_SQLCensus_Keywords
--GROUP BY Keyword
--HAVING COUNT(*) > 1
--GO
-- end test
CREATE TABLE dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration
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
GO
--CREATE INDEX q1 ON SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration (KeywordID)
CREATE INDEX q2 ON SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration (KeywordID, IsPartOfObjectDeclaration)
GO
CREATE TABLE dbo.SQLRAP_SQLCensus_ObjectsForCalibration (
	databaseid			 int,
    ObjectId			 int,
    Number  			 int DEFAULT (0),
    ObjectName			 sysname,
    ObjectOwner			 sysname,
    ObjectType			 nvarchar(2)
    PRIMARY KEY (databaseid, ObjectId, Number)
)
GO
IF OBJECT_ID('SQLRAP_SQLCensus_TimingsForCalibration') IS NOT NULL
	DROP TABLE dbo.SQLRAP_SQLCensus_TimingsForCalibration
GO
CREATE TABLE dbo.SQLRAP_SQLCensus_TimingsForCalibration (
	ObjectId	int,
	Number      int,
	Lines		int,
	ElapsedMS	int
	)
	
-- now run the keyword sniffing code in msdb, timing the results..
--   (unlike the mainline code, we'll look at MSShipped objects in this run)

SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' -- Processing msdb Database for baseline..' AS [Status]
GO

DECLARE @StartTime			DATETIME,
		@EndTime			DATETIME,
		@CodeSizeInMaster	INT,
		@SQLString01		nvarchar(4000),
        @SQLString02		nvarchar(4000),
        @SQLString03		nvarchar(4000),
        @SQLString04		nvarchar(4000),
        @SQLString05		nvarchar(4000),
        @SQLString06		nvarchar(4000),
        @SQLString07		nvarchar(4000),
        @SQLString08		nvarchar(4000),
        @SQLString09		nvarchar(4000),
        @SQLString10		nvarchar(4000),
        @spid				nvarchar(10),
        @dbname				sysname;set @dbname = REPLICATE('q',50)

SET     @spid = CAST (@@spid as nvarchar(10))

SET		@dbname = 'msdb'

SET		@StartTime = GETDATE()

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
        @lines int,
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
		@Start datetime,
		@End datetime,
		@InsideUpdateDeclaration bit,
		@InsideCursorDeclaration bit,
		@InsideCaseStatement bit,
		@StatementIncrement smallint

SET @dbid = db_id(''' + @dbname + N''')

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
--AND    OBJECTPROPERTYEX(b.id, ''''IsMSShipped'''') = 0 
JOIN   (SELECT   id,
                 number,
                 COUNT(*) AS lines
        FROM     syscomments (NOLOCK)
--        WHERE OBJECTPROPERTY(id,''''IsMSShipped'''') = 0
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

DECLARE GetTheObjects CURSOR FAST_FORWARD 
FOR
SELECT
		o.id, 
        o.number,
        o.lines
FROM  #ObjectsToCheck o (NOLOCK)
LEFT OUTER JOIN tempdb.dbo.SQLRAP_SQLCensus_ObjectsForCalibration ob (NOLOCK)
ON    ob.databaseid = @dbid
AND   ob.ObjectId = o.id
AND   ob.Number = o.number
WHERE ob.databaseid IS NULL
ORDER BY o.id, o.number
OPTION (MAXDOP 1)

OPEN GetTheObjects

FETCH NEXT FROM GetTheObjects
INTO @objectid, @number, @lines

SET @OuterLoopFetchStatus = @@FETCH_STATUS

WHILE @OuterLoopFetchStatus = 0

BEGIN

    BEGIN TRAN

	SET @Start = GETUTCDATE()

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

    IF @lines = 1

    BEGIN
        
		 SET @StringLength = LEN(@StringToTest)
		 
		 SET @LoopCounter = 1
		 
		 SET @InsideBlockComment = 0
		 
		 SET @InsideLineComment = 0

		 WHILE @LoopCounter < @StringLength
		 BEGIN
'

SET @SQLString02 = N'
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
			-- if it does, and it''s not commented out, load a reference in the StaticCodeAnalysisForCalibration table
			
			IF PATINDEX(''%'' + @KeywordSearchString + ''%'', @StringToTest COLLATE Latin1_General_BIN) > 0
			BEGIN
				INSERT	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration(
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
				FROM	tempdb.dbo.SQLRAP_SQLCensus_Numbers s (NOLOCK)
'

SET @SQLString03 = N'
				  LEFT OUTER JOIN
				  (
					  SELECT  s1.i
					  FROM	  tempdb.dbo.SQLRAP_SQLCensus_Numbers s1 (NOLOCK)
					  JOIN	  #CharacterExclusions x (NOLOCK)
					  ON	  s1.i BETWEEN x.StartLocationInCode AND x.EndLocationInCode
				  ) x
				  ON	x.i = s.i
				  LEFT OUTER JOIN
						tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration sca (NOLOCK)
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
				FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration (NOLOCK)
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
		FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration sca (NOLOCK)
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
'

SET @SQLString04 = N'
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

			UPDATE  tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration
			SET		RowNumber					= @RowNumber,
					StatementDepth				= @StatementDepth,
					NewStatementStartsHere		= CAST(@StatementIncrement AS bit),
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

    END -- @lines = 1

    ELSE -- @lines > 1

    BEGIN

        INSERT  #ConcatenatedCode (ConcatenatedCodeId, [text])
        VALUES  (1, N'' '' + @StringToTest)

        SELECT  @ptrval = TEXTPTR([text])
        FROM    #ConcatenatedCode (NOLOCK)
        WHERE   ConcatenatedCodeId = 1
        OPTION (MAXDOP 1)
'

SET @SQLString05 = N'
        --  get the remaining lines
		SET @colid = 2
		
		WHILE @colid <= @lines
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
'

SET @SQLString06 = N'
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
		-- if it does, and it''s not commented out, load a reference in the StaticCodeAnalysisForCalibration table
		
		IF (SELECT PATINDEX(''%'' + @Keyword + ''%'',[text] COLLATE Latin1_General_BIN)
			FROM #ConcatenatedCode  (NOLOCK)
			WHERE ConcatenatedCodeId = 1
			) > 0

		BEGIN
			INSERT	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration(
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
				FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration (NOLOCK)
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
	FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration sca (NOLOCK)
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
	ON		sca.KeywordID	= k.KeywordID
	WHERE	sca.databaseid	= @dbid
	AND		sca.objectid    = @objectid
	AND	    sca.number		= @number
	ORDER BY sca.LocationInCode
'

SET @SQLString07 = N'	
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

		UPDATE  tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration
		SET		RowNumber					= @RowNumber,
				StatementDepth				= @StatementDepth,
				NewStatementStartsHere		= CAST(@StatementIncrement AS bit),
				LogicalStatementNumber		= @LogicalStatementNumber,
				IsPartOfObjectDeclaration	= @IsPartOfObjectDeclaration
		WHERE	databaseid		= @dbid
		AND		objectid		= @objectid
		AND		number			= @number
		AND		LocationInCode	= @LocationInCode
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

    END -- @lines > 1
'

SET @SQLString08 = N'    
    -- set the iterations
    
    UPDATE sca
	SET Iteration = 
	(
		SELECT	COUNT(*)
		FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration (NOLOCK)
		WHERE	databaseid				= @dbid
		AND		objectid				= @objectid
		AND		number					= @number
		AND		LogicalStatementNumber	= sca.LogicalStatementNumber
		AND		StatementDepth			= sca.StatementDepth
		AND		KeywordID				= sca.KeywordID
		AND		LocationInCode			<= sca.LocationInCode
	)
	FROM tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration sca
	WHERE	databaseid	= @dbid
	AND		objectid	= @objectid
	AND		number		= @number

	DROP TABLE #CharacterExclusions

	DROP TABLE #ConcatenatedCode

	USE [' + @dbname + ']

	INSERT tempdb.dbo.SQLRAP_SQLCensus_ObjectsForCalibration (
		databaseid,
		ObjectId,
		Number,
		ObjectName,
		ObjectOwner,
		ObjectType
	)
	SELECT
		@dbid,
		@objectid,
		@number,
		name,
		USER_NAME(uid),
		xtype
	FROM	dbo.sysobjects (NOLOCK)
	WHERE	id		= @objectid

	USE [tempdb]

	SET @End = GETUTCDATE()

	INSERT	dbo.SQLRAP_SQLCensus_TimingsForCalibration (ObjectId, Number, Lines, ElapsedMS)
	SELECT	id, number, lines, DATEDIFF(ms,@Start,@End)
	FROM	#ObjectsToCheck
	WHERE	id = @objectid AND number = @number

	COMMIT TRAN

    FETCH NEXT FROM GetTheObjects
    INTO @objectid, @number, @lines
    
    SET @OuterLoopFetchStatus	= @@FETCH_STATUS

END -- @OuterLoopFetchStatus = 0

CLOSE GetTheObjects

DEALLOCATE GetTheObjects
'

SET @SQLString09 = N''

SET @SQLString10 = N''

-- SELECT @dbname, LEN(@SQLString01),LEN(@SQLString02),LEN(@SQLString03),LEN(@SQLString04),LEN(@SQLString05),LEN(@SQLString06),LEN(@SQLString07),LEN(@SQLString08),LEN(@SQLString09),LEN(@SQLString10)

EXEC (@SQLString01 + @SQLString02 + @SQLString03 + @SQLString04 + @SQLString05 + @SQLString06 + @SQLString07 + @SQLString08 + @SQLString09 + @SQLString10)

SET @EndTime = GETDATE()

INSERT	dbo.SQLRAP_SQLCensus_RunTimeEstimates (
		databaseid,
		FastProcessTimeInSeconds,
		SlowProcessTimeInSeconds,
		FastAverageInMS,
		SlowAverageInMS,
		FastCodebaseSizeInBytes,
		SlowCodebaseSizeInBytes,
		NumberOfFastObjects,
		NumberOfSlowObjects
		)
SELECT	DB_ID('msdb'),
		(SELECT CAST(SUM(ElapsedMS)/1000.0 AS DECIMAL(12,4)) FROM tempdb.dbo.SQLRAP_SQLCensus_TimingsForCalibration (NOLOCK) WHERE Lines = 1),
		(SELECT CAST(SUM(ElapsedMS)/1000.0 AS DECIMAL(12,4)) FROM tempdb.dbo.SQLRAP_SQLCensus_TimingsForCalibration (NOLOCK) WHERE Lines >= 2),
		(SELECT AVG(ElapsedMS) AS FastAvg FROM (SELECT ObjectId, Number, SUM(ElapsedMS) AS ElapsedMS FROM tempdb.dbo.SQLRAP_SQLCensus_TimingsForCalibration (NOLOCK) WHERE Lines = 1 GROUP BY ObjectId, Number) f),
		(SELECT AVG(ElapsedMS) AS SlowAvg FROM (SELECT ObjectId, Number, SUM(ElapsedMS) AS ElapsedMS FROM tempdb.dbo.SQLRAP_SQLCensus_TimingsForCalibration (NOLOCK) WHERE Lines >= 2 GROUP BY ObjectId, Number) s),
		(SELECT SUM(LEN(s.[text])) FROM msdb..syscomments s (NOLOCK) JOIN tempdb.dbo.SQLRAP_SQLCensus_TimingsForCalibration t (NOLOCK) ON s.id = t.ObjectId AND t.Lines = 1),
		(SELECT SUM(LEN(s.[text])) FROM msdb..syscomments s (NOLOCK) JOIN tempdb.dbo.SQLRAP_SQLCensus_TimingsForCalibration t (NOLOCK) ON s.id = t.ObjectId AND t.Lines >= 2),
		(SELECT COUNT(*) FROM (SELECT DISTINCT ObjectId, Number FROM tempdb.dbo.SQLRAP_SQLCensus_TimingsForCalibration (NOLOCK) WHERE Lines = 1)f),
		(SELECT COUNT(*) FROM (SELECT DISTINCT ObjectId, Number FROM tempdb.dbo.SQLRAP_SQLCensus_TimingsForCalibration (NOLOCK) WHERE Lines >= 2)s)
OPTION	(MAXDOP 1, ROBUST PLAN)

--select sca.*, k.Keyword from tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration sca
--join tempdb.dbo.SQLRAP_SQLCensus_Keywords k
--on sca.KeywordID = k.KeywordID
--order by sca.databaseid, sca.objectid, sca.number, sca.LocationInCode

--select * from tempdb.dbo.SQLRAP_SQLCensus_TimingsForCalibration

--select * from tempdb.dbo.SQLRAP_SQLCensus_RunTimeEstimates


SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' -- Processing User Databases.' AS [Status]
GO

--	process T-SQL in scheduled jobs
USE msdb

SELECT  j.job_id, 
        1 AS number,
        ISNULL(DATALENGTH(s.command)/2,0) AS ObjectLength,
        1 AS Lines
INTO	#PlaceHolder
FROM	msdb.dbo.sysjobs j
JOIN	msdb.dbo.sysjobsteps s
ON		j.job_id = s.job_id
AND		s.subsystem = N'TSQL'
OPTION  (MAXDOP 1)

INSERT tempdb.dbo.SQLRAP_SQLCensus_TimeAndSpace (
    DatabaseName,
    databaseid,
    Fast,
    Slow,
    EstimatedSlowSpaceInBytes,
    EstimatedFastSpaceInBytes,
    SlowCalibrationAverage,
    FastCalibrationAverage,
    AverageSizeOfSlowObject,
    AverageSizeOfFastObject
    )
SELECT
	DB_NAME(),
	DB_ID(),
	1,
	0,
	0,
	SUM(p.ObjectLength),
	MIN(m.SlowAverageInMS)/1000,
	MIN(m.FastAverageInMS)/1000,
	MIN(m.AverageSizeOfSlowObject),
	MIN(m.AverageSizeOfFastObject)
FROM	#PlaceHolder p
JOIN	tempdb.dbo.SQLRAP_SQLCensus_RunTimeEstimates m
ON		m.databaseid = DB_ID('msdb')

DROP TABLE #PlaceHolder

USE tempdb
GO

-- old script starts here
DECLARE @dbid int,
        @name sysname,
        @SQLString nvarchar(4000),
        @ReportingServicesMaster sysname,
        @ReportingServicesTempdb sysname,
		@distribdb sysname

SET		@ReportingServicesMaster = 'ReportServer' +
			CASE  
				WHEN CONVERT(sysname,SERVERPROPERTY('InstanceName')) IS NOT NULL
					THEN '$' + CONVERT(sysname,SERVERPROPERTY('InstanceName'))
				ELSE ''
			END
SET		@ReportingServicesTempdb = @ReportingServicesMaster + 'TempDB'
 
EXEC sp_helpdistributor @distribdb = @distribdb OUTPUT

DECLARE TraverseTheDatabases CURSOR FOR
SELECT dbid, name
FROM master..sysdatabases (NOLOCK)
WHERE   lower(name) NOT IN (N'master', N'tempdb', N'model', N'msdb', N'pubs', N'northwind', N'adventureworks', N'adventureworksdw')
-- the following line should be uncommented and editted as appropriate for the site
--  to reflect customer databases to be excluded from the process
--AND     lower(name) NOT IN (N'dellstore_campaign_clone', N'dellstore_campaign2_clone', N'DNC_Campaign_clone', N'ecomm4_clone', N'global_dnc_campaign_clone',
                            --N'global_dnc_campaing_q3_pilot_clone', N'MSCS_Admin_clone')
AND  (
	 (@distribdb is not null and lower(name) <> lower(@distribdb))  -- bug 243806
	 OR
	 (@distribdb IS NULL)
	 )
-- omit databases which did not start up cleanly
AND		status & 32 = 0		-- loading
AND		status & 64 = 0		-- pre recovery
AND		status & 128 = 0	-- recovering
AND		status & 256 = 0	-- not recovered
AND		status & 512 = 0	-- offline
AND		status & 32768 = 0	-- emergency mode
ORDER BY dbid
OPTION (MAXDOP 1)

OPEN    TraverseTheDatabases

FETCH NEXT
FROM  TraverseTheDatabases
INTO  @dbid, @name

--SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' --   Cursor Open; compiling results'

WHILE @@FETCH_STATUS = 0

BEGIN

    PRINT CONVERT (nvarchar(40), GETDATE(), 109) + N' -- Processing database [' + @name + N']'

	EXEC ('
USE [' + @name + '];

SET NUMERIC_ROUNDABORT OFF

SELECT  s.id, 
        s.number,
        SUM(CAST(ISNULL(DATALENGTH(s.text)/2,0) AS BIGINT)) AS ObjectLength,
        COUNT(*) AS Lines
INTO    #PlaceHolder
FROM    syscomments s
JOIN	sysobjects a
ON		a.id = s.id
AND   OBJECTPROPERTY(s.id, ''IsMSShipped'') = 0 
AND     s.encrypted = 0
AND     s.id NOT IN (
            SELECT OBJECT_ID(objname)
            FROM   ::fn_listextendedproperty (''microsoft_database_tools_support'', default, default, default, default, NULL, NULL)
            WHERE  value = 1)
GROUP   BY s.id, s.number
OPTION  (MAXDOP 1)

INSERT tempdb.dbo.SQLRAP_SQLCensus_TimeAndSpace (
    DatabaseName,
    databaseid,
    Fast,
    Slow,
    EstimatedSlowSpaceInBytes,
    EstimatedFastSpaceInBytes,
    SlowCalibrationAverage,
    FastCalibrationAverage,
    AverageSizeOfSlowObject,
    AverageSizeOfFastObject
    )
SELECT
	DB_NAME(),
	DB_ID(),
	CAST (SUM (CASE
		WHEN p.Lines = 1 THEN 1
		ELSE 0
	END) AS bigint),
	CAST (SUM (CASE
		WHEN p.Lines = 1 THEN 0
		ELSE 1
	END) AS bigint),
	CAST (SUM (CASE
		WHEN p.Lines = 1 THEN 0
		ELSE ObjectLength
	END) AS bigint),
	CAST (SUM (CASE
		WHEN p.Lines = 1 THEN ObjectLength
		ELSE 0
	END) AS bigint),
	MIN(m.SlowAverageInMS)/1000,
	MIN(m.FastAverageInMS)/1000,
	MIN(m.AverageSizeOfSlowObject),
	MIN(m.AverageSizeOfFastObject)
FROM	#PlaceHolder p
JOIN	tempdb.dbo.SQLRAP_SQLCensus_RunTimeEstimates m
ON		m.databaseid = DB_ID(''msdb'')
OPTION (MAXDOP 1)

DROP TABLE #PlaceHolder
'
)

    FETCH NEXT
    FROM  TraverseTheDatabases
    INTO  @dbid, @name

END

-- SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' --   loop complete; closing cursor'

CLOSE TraverseTheDatabases

DEALLOCATE TraverseTheDatabases
GO

DROP TABLE dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration
DROP TABLE dbo.SQLRAP_SQLCensus_ObjectsForCalibration
--DROP TABLE dbo.SQLRAP_SQLCensus_RunTimeEstimates
GO

SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' -- Data Collection Complete; estimates follow:' AS [Status]
GO

-- report summary results

SELECT 	CAST(SERVERPROPERTY('MachineName') AS sysname) AS ServerName,
		ISNULL(SERVERPROPERTY('InstanceName'),SERVERPROPERTY('MachineName')) AS InstanceName,
		SUM(s.EstimatedSpaceInMB) -- syscomments records
       + 12.9  -- Numbers table
        AS EstimatedTempDBSpaceInMB,
        CONVERT(nvarchar(10),CONVERT(int,CONVERT(int,SUM(s.EstimatedRunTimeInSeconds))/3600)) + N' hr '
       + CONVERT(nvarchar(2),CONVERT(int,(CONVERT(int,SUM(s.EstimatedRunTimeInSeconds))%3600)/60)) + N' min '
       + CONVERT(nvarchar(2),CONVERT(int,SUM(s.EstimatedRunTimeInSeconds))%60) + N' sec' AS FriendlyRawEstimatedRunTime,
        SUM(s.[Fast]) AS FastMemoryCheckWillBeUsed,
        MIN(m.FastAverageInMS)/1000 AS EstSecondsPerFastCheck,
        SUM(s.Slow) AS SlowTableCheckWillBeUsed,
        MIN(m.SlowAverageInMS)/1000 AS EstSecondsPerSlowCheck
FROM tempdb.dbo.SQLRAP_SQLCensus_SummaryForCalibration s
JOIN	tempdb.dbo.SQLRAP_SQLCensus_RunTimeEstimates m
ON		m.databaseid = DB_ID('msdb')
OPTION (MAXDOP 1)


-- report individual databases sorted by estimated execution time

SELECT   FriendlyEstimatedRunTime AS EstimatedRunTime,
         DatabaseName,
         databaseid,
         Fast,
         Slow,
         Total,
         EstimatedRunTimeInSeconds,
         EstimatedSpaceInKB,
         EstimatedSpaceInMB
FROM     tempdb.dbo.SQLRAP_SQLCensus_SummaryForCalibration
ORDER BY EstimatedRunTimeInSeconds DESC,
         EstimatedSpaceInKB DESC
OPTION (MAXDOP 1)

-- report individual databases sorted by estimated space in tempdb

SELECT   EstimatedSpaceInMB,
         DatabaseName,
         databaseid,
         Fast,
         Slow,
         Total,
         EstimatedRunTimeInSeconds,
         EstimatedSpaceInKB,
         FriendlyEstimatedRunTime AS EstimatedRunTime
FROM     tempdb.dbo.SQLRAP_SQLCensus_SummaryForCalibration
ORDER BY EstimatedSpaceInKB DESC,
         EstimatedRunTimeInSeconds DESC
OPTION (MAXDOP 1)
 -- report individual databases sorted by databaseid

SELECT   EstimatedSpaceInMB,
         DatabaseName,
         databaseid,
         Fast,
         Slow,
         Total,
         EstimatedRunTimeInSeconds,
         EstimatedSpaceInKB,
         FriendlyEstimatedRunTime AS EstimatedRunTime
FROM     tempdb.dbo.SQLRAP_SQLCensus_SummaryForCalibration
ORDER BY databaseid
OPTION (MAXDOP 1)

GO
DROP VIEW SQLRAP_SQLCensus_SummaryForCalibration
DROP TABLE SQLRAP_SQLCensus_TimingsForCalibration
