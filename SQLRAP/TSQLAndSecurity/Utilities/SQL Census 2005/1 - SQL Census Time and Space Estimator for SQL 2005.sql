-- Signature="2353AC8C442A39EB"

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    SQL Census Time and Space Estimator for SQL 2005.sql                                              ****/
--/****    estimates resource consumption for a SQL Census Data Collector run on a SQL Server 2005 instance  ****/
--/****                                                                                                      ****/
--/****    2010.Jan.25 - created (wardp) - adapted from the 3.0 script                                       ****/
--/****    2010.Jul.22 - updated (wardp) - CR 466805                                                         ****/
--/****    2010.Sep.11 - updated (wardp) - bug 468281, bug 468251                                            ****/
--/****    2010.Sep.21 - updated (wardp) - bug 468699                                                        ****/
--/****    2010.Sep.30 - updated (wardp) - bug 468895                                                        ****/
--/****    2010.Oct.01 - updated (wardp) - bug 468926                                                        ****/
--/****    2010.Oct.06 - updated (wardp) - bug 469000                                                        ****/
--/****    2010.Oct.07 - updated (wardp) - bug 417498                                                        ****/
--/****    2010.Nov.29 - updated (rajpo) - bug 471301 case sensitivity issue                                 ****/
--/****                                                                                                      ****/
--/****    Copyright (c) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/
SET NOCOUNT ON
USE tempdb
GO

--	version check; a failure here will be logged and the connection forcibly broken
IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),2) <> '9.'
BEGIN
	DECLARE @ErrorString nvarchar(4000)
	SET @ErrorString = 'Attempt to run SQL Server 2005 (SQL Server version 9.x) SQLRAP Time and Space Estimator against a SQL Server '
					  + CASE
						  WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),4) = '10.5' THEN '2008 R2'
						  WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),2) = '10'   THEN '2008'
						  WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),2) = '8.'   THEN '2000'
					    END
					  + ' (version '
					  + CAST(SERVERPROPERTY('ProductVersion') AS nvarchar)
					  + ') instance.  Process terminated.'
					  + CHAR(13) + CHAR(10)
					  + 'Please run the SQL Server '
					  + CASE
						  WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),2) = '10'   THEN '2008'
						  WHEN LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),2) = '8.'   THEN '2000'
					    END
					  + ' SQLRAP Time and Space Estimator against this instance.'
	RAISERROR (@ErrorString, 25, 1) WITH LOG
END
GO

-- check for bootstrap object; a failure will be logged if it's not found
IF OBJECT_ID('SQLRAP_SQLCensus_ExcludedDatabases') IS NULL
BEGIN
	DECLARE @ErrorString nvarchar(4000)
	SET @ErrorString = 'Attempt to run SQL Server 2005 SQLRAP TimeAndSpaceEstimator without first running Bootstrap process.  Process terminated.'
					  + CHAR(13) + CHAR(10)
					  + 'Please run the SQL Server 2005 Bootstrap against this instance.'
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

CREATE TABLE dbo.SQLRAP_SQLCensus_Numbers(i int PRIMARY KEY);
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
CREATE TABLE dbo.SQLRAP_SQLCensus_TimeAndSpace (
    databaseid                  int PRIMARY KEY,
    NumberOfObjects             int,
    EstimatedRunTimeInSeconds   decimal(12,4),
    CodebaseSize                BIGINT,
    EstimateRun					bit DEFAULT(1)
)
GO
CREATE VIEW dbo.SQLRAP_SQLCensus_SummaryForCalibration AS
SELECT  DB_NAME(t.databaseid) AS DatabaseName,
		t.databaseid,
		t.NumberOfObjects,
		t.EstimatedRunTimeInSeconds,
		t.CodebaseSize,
		CONVERT(decimal(16,2),t.CodebaseSize) / (1024 * 1024) AS CodebaseSizeInMB,
		CONVERT(nvarchar(10),CONVERT(int,(EstimatedRunTimeInSeconds / 60))) + N' min ' +
		CONVERT(nvarchar(2), CONVERT(bigint,(EstimatedRunTimeInSeconds % 60))) + N' sec'
		AS FriendlyEstimatedRunTime

FROM    dbo.SQLRAP_SQLCensus_TimeAndSpace t (NOLOCK)
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
		WHEN Keyword = '[@' THEN '[[]@'
		WHEN Keyword IN ('<>', '!=', '!<', '!>', '=*', '*=', '*', '(', ')', '../', '.nodes', '.query', '.value', '.modify', 'xp_cmdshell') THEN Keyword
		ELSE N'[/, ()' + CHAR(9) + CHAR(10) + CHAR(13) + ''']'
							+ Keyword
							+ N'[/, ()' + CHAR(9) + CHAR(10) + CHAR(13) + ''']'
		END					PERSISTED,
	ChangesDepthUp		bit,			-- used to calculate statement depth; only applies to open paren
	ChangesDepthDown	bit,			-- used to calculate statement depth; only applies to close paren
	KeywordLength		AS LEN(Keyword) PERSISTED,
	KeywordSearchStringLength AS		-- the length of the keyword and its whitespace
		CASE
		WHEN Keyword IN ('<>', '!=', '!<', '!>', '=*', '*=', '*', '(', ')', '../', '.nodes', '.query', '.value', '.modify', 'xp_cmdshell', '[@') THEN LEN(Keyword)
		ELSE LEN(Keyword) + 2
		END					PERSISTED,
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

-- XML related terms
INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('../', 0, 0, 0) -- parent axis access

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('[1]',  0, 0, 0) -- single root node

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('.nodes',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('.query',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('.value',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('.modify',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('explicit',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('for',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('openxml',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('raw',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('sp_xml_preparedocument',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('sp_xml_removedocument',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('xml',  0, 0, 0)

INSERT dbo.SQLRAP_SQLCensus_Keywords (Keyword, ChangesDepthUp, ChangesDepthDown, CanStartStatement)
VALUES ('[@',  0, 0, 0)

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
	PRIMARY KEY (databaseid, objectid, LocationInCode, KeywordID)
)
GO
--CREATE INDEX q1 ON SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration (KeywordID)
CREATE INDEX q2 ON SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration (IsPartOfObjectDeclaration)
GO
CREATE TABLE dbo.SQLRAP_SQLCensus_RunTimeEstimates (
	databaseid			 int,
    ProcessTimeInSeconds decimal(12,4),
    CodebaseSizeInBytes	 bigint,
    NumberOfObjects		 bigint
)
GO
CREATE TABLE dbo.SQLRAP_SQLCensus_ObjectsForCalibration (
	databaseid			 int,
    ObjectId			 int,
    Number				 smallint DEFAULT(0),
    ObjectName			 sysname,
    ObjectOwner			 sysname,
    ObjectType			 nvarchar(2)
    PRIMARY KEY (databaseid, ObjectId)
)
GO
-- now run thekeyword sniffing code in msdb, timing the results..
--   (unlike the mainline code, we'll look at MSShipped objects in this run)

SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' -- Processing msdb Database for baseline..' AS [Status]
GO

DECLARE @StartTime			DATETIME,
		@EndTime			DATETIME,
		@CodeSizeInMaster	INT

SET	@StartTime = GETDATE()

EXEC('
USE [msdb]

DECLARE @debug bit,
		@objectid int,
		@objectdefinition nvarchar(max),
		@KeywordID int,
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
SELECT	object_id, CAST(N'' '' AS nvarchar(max)) + LOWER(OBJECT_DEFINITION(object_id))
FROM	sys.sql_modules (NOLOCK)
-- (for the purposes of the calibration, we won''t apply the filters to avoid MSFT sprocs
--WHERE	OBJECTPROPERTY(object_id,''IsMSShipped'') = 0
--AND		object_id NOT IN
--		(
--            SELECT OBJECT_ID(objname)
--            FROM   ::fn_listextendedproperty (''microsoft_database_tools_support'', DEFAULT, DEFAULT, DEFAULT, DEFAULT, NULL, NULL)
--            WHERE  value = 1
--        )
ORDER BY object_id ASC

OPEN GetTheObjects

FETCH NEXT FROM GetTheObjects
INTO @objectid, @objectdefinition

WHILE @@FETCH_STATUS = 0
BEGIN

	BEGIN TRAN
	
	INSERT tempdb.dbo.SQLRAP_SQLCensus_ObjectsForCalibration (
		databaseid,
		ObjectId,
		ObjectName,
		ObjectOwner,
		ObjectType
	)
	SELECT
		DB_ID(),
		@objectid,
		OBJECT_NAME(@objectid),
		OBJECT_SCHEMA_NAME(@objectid, DB_ID()),
		type
	FROM	sys.objects
	WHERE	object_id = @objectid
	
	CREATE TABLE #CharacterExclusions (
		StartLocationInCode int,
		EndLocationInCode int,
		ExclusionType nchar(2)
		)

	CREATE INDEX ce1 ON #CharacterExclusions (EndLocationInCode)

    IF   PATINDEX(N''%--%'', @objectdefinition COLLATE Latin1_General_BIN) >= 1
    OR   PATINDEX(N''%/*%'', @objectdefinition COLLATE Latin1_General_BIN) >= 1

	BEGIN

	 SET @StringLength = LEN(@objectdefinition)
	 
	 SET @LoopCounter = 1
	 
	 SET @InsideBlockComment = 0
	 
	 SET @InsideLineComment = 0

	 WHILE @LoopCounter < @StringLength
	 BEGIN

		-- handle characters inside a block comment
		WHILE (@InsideBlockComment = 1 AND SUBSTRING(@objectdefinition COLLATE Latin1_General_BIN,@LoopCounter,2) <> N''*/'' AND @LoopCounter < @StringLength)
		BEGIN
			SET @LoopCounter = @LoopCounter + 1
		END

		-- handle characters inside a line comment
		WHILE (@InsideLineComment = 1 AND SUBSTRING(@objectdefinition COLLATE Latin1_General_BIN,@LoopCounter,1) <> CHAR(10) AND SUBSTRING(@objectdefinition COLLATE Latin1_General_BIN,@LoopCounter,1) <> CHAR(13) AND @LoopCounter < @StringLength)
		BEGIN
			SET @LoopCounter = @LoopCounter + 1
		END

		-- finish handling a block comment
		IF @InsideBlockComment = 1 AND SUBSTRING(@objectdefinition COLLATE Latin1_General_BIN,@LoopCounter,2) = N''*/''
		BEGIN
			SET @InsideBlockComment = 0
			INSERT #CharacterExclusions (StartLocationInCode, EndLocationInCode, ExclusionType) VALUES (@CommentStart, @LoopCounter+1, ''BC'') -- block comment
			SET @LoopCounter = @LoopCounter + 2
		END

		-- finish handling a line comment
		ELSE IF @InsideLineComment = 1 AND (SUBSTRING(@objectdefinition COLLATE Latin1_General_BIN,@LoopCounter,1) = CHAR(10) OR SUBSTRING(@objectdefinition COLLATE Latin1_General_BIN,@LoopCounter,1) = CHAR(13))
		BEGIN
			SET @InsideLineComment = 0
			INSERT #CharacterExclusions (StartLocationInCode, EndLocationInCode, ExclusionType) VALUES (@CommentStart, @LoopCounter, ''LC'') -- line comment
			SET @LoopCounter = @LoopCounter + 1
		END

		-- start handling a block comment
		ELSE IF @InsideBlockComment = 0 AND @InsideLineComment = 0 AND SUBSTRING(@objectdefinition COLLATE Latin1_General_BIN,@LoopCounter,2) = N''/*''
		BEGIN
			SET @InsideBlockComment = 1
			SET @CommentStart = @LoopCounter
			SET @LoopCounter = @LoopCounter + 2
		END

		-- start handling a line comment
		ELSE IF @InsideBlockComment = 0 AND @InsideLineComment = 0 AND SUBSTRING(@objectdefinition COLLATE Latin1_General_BIN,@LoopCounter,2) = N''--''
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
	INTO	@KeywordID,
			@Keyword,
			@KeywordLength,
			@KeywordSearchString,
			@KeywordSearchStringLength

	IF @debug = 1
	BEGIN
		SELECT GETDATE(), @KeywordID as LoopCounter, @Keyword
	END

	WHILE @@FETCH_STATUS = 0
	BEGIN

		-- check to see if the keyword exists in the object.
		-- if it does, and it''s not commented out, load a reference in the StaticCodeAnalysisForCalibration table
		
		IF PATINDEX(''%'' + @KeywordSearchString + ''%'', @objectdefinition COLLATE Latin1_General_BIN) > 0
		BEGIN
			INSERT	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration(
				databaseid, 
				objectid, 
				LocationInCode, 
				KeywordID
				)
				OUTPUT 
					inserted.LocationInCode + 1 AS StartLocationInCode,
					inserted.LocationInCode + @KeywordLength - 1 AS EndLocationInCode,
					''PC'' AS ExclusionType  -- PC = ProcessedCode
					INTO   #CharacterExclusions
			SELECT
				db_id() AS databaseid,
				@objectid AS objectid,
				s.i as LocationInCode,
				@KeywordID
			  FROM	tempdb.dbo.SQLRAP_SQLCensus_Numbers s (NOLOCK)
			  LEFT OUTER JOIN
			  (
				  SELECT  s1.i
				  FROM	  tempdb.dbo.SQLRAP_SQLCensus_Numbers s1 (NOLOCK)
				  JOIN	  #CharacterExclusions x (NOLOCK)
				  ON	  s1.i BETWEEN x.StartLocationInCode AND x.EndLocationInCode
			  ) x
			  ON	x.i = s.i
			  WHERE	s.i <= LEN(@objectdefinition)
			  AND	x.i IS NULL
			  AND	PATINDEX(@KeywordSearchString, SUBSTRING(@objectdefinition COLLATE Latin1_General_BIN, s.i-1, @KeywordSearchStringLength)) = 1
			  OPTION  (MAXDOP 1)
		END

		FETCH NEXT FROM GetTheKeywords
		INTO	@KeywordID,
				@Keyword,
				@KeywordLength,
				@KeywordSearchString,
				@KeywordSearchStringLength

		IF @debug = 1
		BEGIN
			SELECT GETDATE(), @KeywordID AS LoopCounter, @Keyword
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
	ON		sca.KeywordID = k.KeywordID
	WHERE	sca.databaseid = DB_ID()
	AND		sca.objectid    = @objectid
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

		UPDATE  tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration
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

	DROP TABLE #CharacterExclusions

    -- set the iterations
    
    UPDATE sca
	SET Iteration = 
	(
		SELECT	COUNT(*)
		FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration (NOLOCK)
		WHERE	databaseid				= DB_ID()
		AND		objectid				= @objectid
		AND		LogicalStatementNumber	= sca.LogicalStatementNumber
		AND		StatementDepth			= sca.StatementDepth
		AND		KeywordID				= sca.KeywordID
		AND		LocationInCode			<= sca.LocationInCode
	)
	FROM tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration sca
	WHERE	databaseid	= DB_ID()
	AND		objectid	= @objectid

	COMMIT TRAN

	FETCH NEXT FROM
	GetTheObjects
	INTO @objectid, @objectdefinition

END

CLOSE GetTheObjects

DEALLOCATE GetTheObjects
')

SET @EndTime = GETDATE()

INSERT	dbo.SQLRAP_SQLCensus_RunTimeEstimates (
		databaseid,
		ProcessTimeInSeconds,
		CodebaseSizeInBytes,
		NumberOfObjects
		)
SELECT	DB_ID('msdb'),
		CAST(DATEDIFF(ms,@StartTime,@EndTime)/1000.0 AS DECIMAL(12,4)),
		SUM(LEN(definition)),
		COUNT(*)
FROM	msdb.sys.sql_modules (NOLOCK)
OPTION	(MAXDOP 1)

--select * from SQLRAP_SQLCensus_RunTimeEstimates 

SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' -- Processing User Databases.' AS [Status]
GO

--	process T-SQL in scheduled jobs
USE msdb

SELECT  j.job_id, 
        s.step_id AS number,
        ISNULL(DATALENGTH(s.command)/2,0) AS ObjectLength,
        1 AS Lines
INTO	#PlaceHolder
FROM	msdb.dbo.sysjobs j
JOIN	msdb.dbo.sysjobsteps s
ON		j.job_id = s.job_id
AND		s.subsystem = N'TSQL'
OPTION  (MAXDOP 1)

INSERT tempdb.dbo.SQLRAP_SQLCensus_TimeAndSpace (
    databaseid,
    CodebaseSize,
	NumberOfObjects
    )
SELECT
	DB_ID(),
	SUM(ISNULL(p.ObjectLength,0)),
	COUNT(*)
FROM	#PlaceHolder p
JOIN	tempdb.dbo.SQLRAP_SQLCensus_RunTimeEstimates m
ON		m.databaseid = DB_ID('msdb')

DROP TABLE #PlaceHolder

USE tempdb
GO

-- old script starts here
DECLARE @dbid int,
        @name sysname,
        @SQLString nvarchar(max),
        @ReportingServicesMaster sysname,
        @ReportingServicesTempdb sysname        

SET		@ReportingServicesMaster = 'ReportServer' +
			CASE  
				WHEN CONVERT(sysname,SERVERPROPERTY('InstanceName')) IS NOT NULL
					THEN '$' + CONVERT(sysname,SERVERPROPERTY('InstanceName'))
				ELSE ''
			END
SET		@ReportingServicesTempdb = @ReportingServicesMaster + 'TempDB'

DECLARE TraverseTheDatabases
CURSOR FAST_FORWARD FOR
SELECT  s.database_id, s.name
FROM    sys.databases s
-- the following databases MUST be excluded for the SQL RAP to produce the desired results
WHERE   lower(s.name) NOT IN (N'master', N'tempdb', N'model', N'msdb', N'pubs', N'northwind', N'adventureworks', N'adventureworksdw')
-- limit to databases which are online
AND		s.state_desc = N'ONLINE'
-- the following line should be uncommented and editted as appropriate for the site
--  to reflect customer databases to be excluded from the process
--AND     lower(name) NOT IN (N'dellstore_campaign_clone', N'dellstore_campaign2_clone', N'DNC_Campaign_clone', N'ecomm4_clone', N'global_dnc_campaign_clone',
--                            N'global_dnc_campaing_q3_pilot_clone', N'MSCS_Admin_clone')
AND		s.is_distributor = 0  -- bug 243806
AND     s.compatibility_level >= 80 -- bug 319949
AND		s.name NOT IN (@ReportingServicesMaster, @ReportingServicesTempdb, N'ReportServer', N'ReportServerTempDB')
ORDER BY s.database_id
OPTION  (MAXDOP 1)

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

INSERT	tempdb.dbo.SQLRAP_SQLCensus_RunTimeEstimates (
		databaseid,
		CodebaseSizeInBytes,
		NumberOfObjects
		)
SELECT	DB_ID(),
		ISNULL(SUM(LEN(s.definition)),0),
		ISNULL(COUNT(*),0)
FROM	sys.sql_modules s (NOLOCK)
LEFT OUTER JOIN  --		object_id NOT IN
		(
            SELECT OBJECT_ID(objname) AS object_id
            FROM   ::fn_listextendedproperty (''microsoft_database_tools_support'', DEFAULT, DEFAULT, DEFAULT, DEFAULT, NULL, NULL)
            WHERE  value = 1
        ) AS a
ON		a.object_id = s.object_id
WHERE	a.object_id IS NULL
AND 	OBJECTPROPERTY(s.object_id,''IsMSShipped'') = 0
OPTION	(MAXDOP 1)
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
DECLARE	@BaseTime decimal (12,4),
		@BaseSize int,
		@WorkFactor decimal (18,5)

SELECT	@BaseTime = ProcessTimeInSeconds,
		@BaseSize = CodebaseSizeInBytes,
		@WorkFactor = ProcessTimeInSeconds / (CodebaseSizeInBytes / 1024)
FROM	dbo.SQLRAP_SQLCensus_RunTimeEstimates
WHERE	databaseid = DB_ID('msdb')
OPTION (MAXDOP 1)

--UPDATE	dbo.SQLRAP_SQLCensus_RunTimeEstimates
--SET		ProcessTimeInSeconds = @BaseTime * (CodebaseSizeInBytes / CAST(@BaseSize AS DECIMAL(12,4)))
--WHERE	databaseid <> DB_ID('msdb')

INSERT	dbo.SQLRAP_SQLCensus_TimeAndSpace (
		databaseid,
		NumberOfObjects,
		CodebaseSize,
		EstimatedRunTimeInSeconds
		)
SELECT	databaseid,
		NumberOfObjects,
		CodebaseSizeInBytes,
		CASE  -- increase very small estimates to account for process overhead
			WHEN @BaseTime * (CodebaseSizeInBytes / CAST(@BaseSize AS DECIMAL(12,4))) = 0  THEN 0
			WHEN @BaseTime * (CodebaseSizeInBytes / CAST(@BaseSize AS DECIMAL(12,4))) <= .999 THEN .999 -- @BaseTime * (CodebaseSizeInBytes / CAST(@BaseSize AS DECIMAL(12,4))) * 2
			ELSE @BaseTime * (CodebaseSizeInBytes / CAST(@BaseSize AS DECIMAL(12,4)))
		END
FROM	dbo.SQLRAP_SQLCensus_RunTimeEstimates
WHERE	databaseid <> DB_ID('msdb')
OPTION (MAXDOP 1)
--select * from dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration sca JOIN dbo.SQLRAP_SQLCensus_Keywords k on sca.KeywordID = k.KeywordID
--select * from tempdb.dbo.SQLRAP_SQLCensus_ObjectsForCalibration

DROP TABLE dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForCalibration
DROP TABLE dbo.SQLRAP_SQLCensus_ObjectsForCalibration
DROP TABLE dbo.SQLRAP_SQLCensus_RunTimeEstimates
GO


SELECT CONVERT (nvarchar(40), GETDATE(), 109) + N' -- Data Collection Complete; estimates follow:' AS [Status]

-- report summary results

SELECT
	   CAST(SERVERPROPERTY('MachineName') AS sysname) AS ServerName,
	   ISNULL(SERVERPROPERTY('InstanceName'),SERVERPROPERTY('MachineName')) AS InstanceName,
	   CAST(
		CAST(
		SUM(CodebaseSizeInMB) * 8.5 -- StaticCodeAnalysis records
        + 12.9  -- Numbers table
           AS DECIMAL(12,2)
            )
         AS nvarchar(20)
         ) + ' Mb'
        AS EstimatedTempDBSpace,
        CONVERT(nvarchar(10),CONVERT(int,SUM(ISNULL(EstimatedRunTimeInSeconds,0))/3600)) + N' hr '
       + CONVERT(nvarchar(2),CONVERT(int,(SUM(ISNULL(EstimatedRunTimeInSeconds,0))%3600)/60)) + N' min '
       + CONVERT(nvarchar(2),CAST(SUM(ISNULL(EstimatedRunTimeInSeconds,0)) AS int) %60) + N' sec' AS EstimatedRunTime

FROM tempdb.dbo.SQLRAP_SQLCensus_SummaryForCalibration (NOLOCK)
OPTION  (MAXDOP 1)

-- report individual databases sorted by estimated execution time

SELECT   FriendlyEstimatedRunTime,
         DatabaseName,
         databaseid,
         NumberOfObjects,
         EstimatedRunTimeInSeconds,
         CASE
			WHEN CodebaseSizeInMB * 1024 < 1 THEN CAST(CodebaseSize AS nvarchar(4)) + ' bytes'
			WHEN CodebaseSizeInMB > 1 THEN CAST(CAST(CodebaseSizeInMB AS DECIMAL(12,3)) AS nvarchar(20)) + ' Mb'
			ELSE CAST(CAST(CodebaseSizeInMB * 1024 AS DECIMAL(12,3)) AS nvarchar(20)) + ' Kb'
		  END AS CodebaseSize
FROM tempdb.dbo.SQLRAP_SQLCensus_SummaryForCalibration (NOLOCK)
ORDER BY EstimatedRunTimeInSeconds DESC,
         CodebaseSizeInMB DESC
OPTION  (MAXDOP 1)

-- report individual databases sorted by estimated space in tempdb

SELECT
        CASE
			WHEN CodebaseSizeInMB * 1024 < 1 THEN CAST(CodebaseSize AS nvarchar(4)) + ' bytes'
			WHEN CodebaseSizeInMB > 1 THEN CAST(CAST(CodebaseSizeInMB AS DECIMAL(12,3)) AS nvarchar(20)) + ' Mb'
			ELSE CAST(CAST(CodebaseSizeInMB * 1024 AS DECIMAL(12,3)) AS nvarchar(20)) + ' Kb'
		 END AS CodebaseSize,
         DatabaseName,
         databaseid,
         NumberOfObjects,
         EstimatedRunTimeInSeconds,
         FriendlyEstimatedRunTime
FROM tempdb.dbo.SQLRAP_SQLCensus_SummaryForCalibration (NOLOCK)
ORDER BY CodebaseSizeInMB DESC,
         EstimatedRunTimeInSeconds DESC
OPTION  (MAXDOP 1)
         
-- report individual databases sorted by databaseid

SELECT
        CASE
			WHEN CodebaseSizeInMB * 1024 < 1 THEN CAST(CodebaseSize AS nvarchar(4)) + ' bytes'
			WHEN CodebaseSizeInMB > 1 THEN CAST(CAST(CodebaseSizeInMB AS DECIMAL(12,3)) AS nvarchar(20)) + ' Mb'
			ELSE CAST(CAST(CodebaseSizeInMB * 1024 AS DECIMAL(12,3)) AS nvarchar(20)) + ' Kb'
		 END AS CodebaseSize,
         DatabaseName,
         databaseid,
         NumberOfObjects,
         EstimatedRunTimeInSeconds,
         FriendlyEstimatedRunTime
FROM     tempdb.dbo.SQLRAP_SQLCensus_SummaryForCalibration (NOLOCK)
ORDER BY databaseid
OPTION  (MAXDOP 1)