-- Signature="CE9845F141752845"

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    SQLCensus_Cursor_Issues.sql      											                     ****/
--/****    Return SQL Census Cursor Test Case Issues to UI                  		                         ****/
--/****                                                                                                      ****/
--/****    Created by wardp 2010.Feb.23                                                                      ****/
--/****    Updated by wardp 2010.May.17 (for SQL2K, faster with UDFs)                                        ****/
--/****    Updated by wardp 2010.Jul.22 (CR 168493)                                                          ****/
--/****    Updated by wardp 2010.Sep.10 (bug 467926)                                                         ****/
--/****    Updated by wardp 2010.Sep.21 (bug 467926 again)                                                   ****/
--/****    Updated by wardp 2010.Sep.29 (CR 468879)                                                          ****/
--/****    Updated by wardp 2010.Sep.30 (bug 468749)                                                         ****/
--/****    Updated by rajpo	2010.Oct.26  Fixed the false positive around missing close and deallocate cursors****/
--/****    Updated by rajpo	2010.Nov.23 Case sensitivity issue                                               ****/
--/****    Copyright  Microsoft Corporation. All rights reserved.                                            ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

-- interface documentation: do not delete..

-- global = SQL_cursor_global_statement
-- external fetch from global = SQL_cursor_global_fetch_statement
-- internal fetch from global = SQL_cursur_fetch_global_statement

DECLARE @dbid  int,
		@idoc1 int,
		@KeywordsXML		    nvarchar(4000)

--SET @dbid = DB_ID()

SET @KeywordsXML		    = N'<Keywords><Keyword Keyword="dynamic"/><Keyword Keyword="global"/><Keyword Keyword="insensitive"/><Keyword Keyword="keyset"/><Keyword Keyword="static"/></Keywords>'

--	if this is a SQL 2000 instance, prepare XML for evaluation
IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),1) = '8'
BEGIN
	EXEC sp_xml_preparedocument @idoc1 OUTPUT, @KeywordsXML
END

SELECT DISTINCT
	SERVERPROPERTY('machinename')																						AS 'Server Name',
    ISNULL(SERVERPROPERTY('instancename'),SERVERPROPERTY('machinename'))												AS 'Instance Name',
    DB_NAME(SQLCensus.databaseid)																						AS 'Database Name',
    ISNULL(obj.ObjectOwner, '--')																						AS 'Owner Name',
	ISNULL(CAST(obj.ObjectName AS nvarchar(255)), tempdb.dbo.fnSQLRAP_SQLCensus_ExclusionMessageCheck (SQLCensus.objectid, SQLCensus.databaseid)) COLLATE DATABASE_DEFAULT
                                                                                                                        AS 'Object Name',
    CASE
        WHEN obj.ObjectType = N'TR'
            THEN obj.ExtendedProperties
        ELSE
            ISNULL(tempdb.dbo.fnSQLRAP_SQLCensus_ObjectTypePresentation(obj.ObjectType), '--')
    END COLLATE DATABASE_DEFAULT			                                                                            AS 'Object Type',
    SQLCensus.Keyword																									AS 'Issue',
    i.RuleName                                                                                                          AS 'RuleName'
FROM
(
	SELECT	SQLCensus1.databaseid, SQLCensus1.objectid, SQLCensus1.Keyword
	FROM	tempdb.dbo.fnSQLRAP_SQLCensus_Presentation  (@KeywordsXML, @dbid, @idoc1) SQLCensus1
	JOIN	tempdb.dbo.fnSQLRAP_SQLCensus_NearKeywordsPresentation('declare','cursor', @dbid) cursorlines
	ON		SQLCensus1.databaseid				= cursorlines.databaseid
	AND		SQLCensus1.objectid					= cursorlines.objectid
	AND		SQLCensus1.LogicalStatementNumber	= cursorlines.LogicalStatementNumber

	UNION ALL

	SELECT SQLCensus2.databaseid, SQLCensus2.objectid, N'external fetch from global' AS Keyword
	FROM	tempdb.dbo.fnSQLRAP_SQLCensus_NearKeywordsPresentation(N'fetch',N'global', @dbid) SQLCensus2
	LEFT OUTER JOIN	tempdb.dbo.fnSQLRAP_SQLCensus_NearKeywordsPresentation(N'declare',N'cursor', @dbid) cursorlines
	ON		SQLCensus2.databaseid				= cursorlines.databaseid
	AND		SQLCensus2.objectid					= cursorlines.objectid
	--AND		SQLCensus2.LogicalStatementNumber	= cursorlines.LogicalStatementNumber
	WHERE	cursorlines.databaseid IS NULL
    
   	UNION ALL

	SELECT	SQLCensus3.databaseid, SQLCensus3.objectid, N'internal fetch from global' AS Keyword
	FROM	tempdb.dbo.fnSQLRAP_SQLCensus_NearKeywordsPresentation(N'fetch',N'global', @dbid)  SQLCensus3
	JOIN	tempdb.dbo.fnSQLRAP_SQLCensus_NearKeywordsPresentation(N'cursor',N'global', @dbid) globalcursors
	ON		SQLCensus3.databaseid				= globalcursors.databaseid
	AND		SQLCensus3.objectid					= globalcursors.objectid

	UNION ALL
	
	SELECT  cursorlines.databaseid, cursorlines.objectid, N'missing close' AS Keyword
	FROM
	(
		SELECT	databaseid, objectid, COUNT(*) AS Kount
		FROM	tempdb.dbo.fnSQLRAP_SQLCensus_NearKeywordsPresentation(N'declare',N'cursor', @dbid)
		GROUP BY databaseid, objectid
	) cursorlines
	LEFT OUTER JOIN
	(
		SELECT	sca.databaseid, sca.objectid, COUNT(*) AS Kount
		FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
		ON		k.Keyword		= N'close'
		AND		sca.KeywordID	= k.KeywordID
		GROUP BY sca.databaseid, sca.objectid
	) SQLCensus4
	ON		SQLCensus4.databaseid				= cursorlines.databaseid
	AND		SQLCensus4.objectid					= cursorlines.objectid
	WHERE	SQLCensus4.databaseid IS NULL
	OR		SQLCensus4.Kount					< cursorlines.Kount
	
	UNION ALL
	
	SELECT  cursorlines.databaseid, cursorlines.objectid, N'missing deallocate' AS Keyword
	FROM
	(
		SELECT	databaseid, objectid, COUNT(*) AS Kount
		FROM	tempdb.dbo.fnSQLRAP_SQLCensus_NearKeywordsPresentation(N'declare',N'cursor', @dbid)
		GROUP BY databaseid, objectid
	) cursorlines
	LEFT OUTER JOIN
	(
		SELECT	sca.databaseid, sca.objectid, COUNT(*) AS Kount
		FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
		ON		k.Keyword		= N'deallocate'
		AND		sca.KeywordID	= k.KeywordID
		GROUP BY sca.databaseid, sca.objectid
	) SQLCensus5
	ON		SQLCensus5.databaseid				= cursorlines.databaseid
	AND		SQLCensus5.objectid					= cursorlines.objectid
	WHERE	SQLCensus5.databaseid IS NULL
	OR		SQLCensus5.Kount					< cursorlines.Kount
	
	UNION ALL

	-- database exclusion messages
	SELECT	databaseid, objectid, Keyword
	FROM	tempdb.dbo.fnSQLRAP_SQLCensus_ExclusionMessagePresentation (N'cursors')
	WHERE	objectid = -3	-- CR 468879
) SQLCensus
LEFT OUTER JOIN
		tempdb.dbo.SQLRAP_SQLCensus_Objects obj (NOLOCK)
ON		SQLCensus.databaseid	= obj.databaseid
AND		SQLCensus.objectid		= obj.ObjectId
LEFT OUTER JOIN tempdb.dbo.vwSQLRAP_SQLCensus_TestCaseIssue i (NOLOCK)
ON      SQLCensus.Keyword = i.Issue
AND     i.TestCase = N'cursors'

WHERE	ISNULL(CAST(obj.ObjectName AS nvarchar(255)), tempdb.dbo.fnSQLRAP_SQLCensus_ExclusionMessageCheck (SQLCensus.objectid, SQLCensus.databaseid)) IS NOT NULL

UNION ALL

SELECT
	SERVERPROPERTY('machinename')																						AS 'Server Name',
    ISNULL(SERVERPROPERTY('instancename'),SERVERPROPERTY('machinename'))												AS 'Instance Name',
    'msdb (Scheduled Job Steps)'																								AS 'Database Name',
    USER_NAME(j.owner_sid)																								AS 'Owner Name',
	N'Job Name [' + j.name + N']; Step Name [' + s.step_name + N']'														AS 'Object Name',
    N'Scheduled Job Step'																								AS 'Object Type',
    SQLCensus.Keyword																									AS 'Issue',
    i.RuleName                                                                                                          AS 'RuleName'
FROM
(
	SELECT	SQLCensus1.job_id, SQLCensus1.step_id, SQLCensus1.Keyword 
	FROM	tempdb.dbo.fnSQLRAP_SQLCensus_PresentationForJobs  (@KeywordsXML, @dbid, @idoc1) SQLCensus1
	JOIN	tempdb.dbo.fnSQLRAP_SQLCensus_NearKeywordsPresentationForJobs('declare','cursor', @dbid) cursorlines
	ON		SQLCensus1.job_id					= cursorlines.job_id
	AND		SQLCensus1.step_id					= cursorlines.step_id
	AND		SQLCensus1.LogicalStatementNumber	= cursorlines.LogicalStatementNumber

	UNION ALL

	SELECT SQLCensus2.job_id, SQLCensus2.step_id, N'external fetch from global'
	FROM	tempdb.dbo.fnSQLRAP_SQLCensus_NearKeywordsPresentationForJobs(N'fetch',N'global', @dbid) SQLCensus2
	LEFT OUTER JOIN	tempdb.dbo.fnSQLRAP_SQLCensus_NearKeywordsPresentationForJobs(N'declare',N'cursor', @dbid) cursorlines
	ON		SQLCensus2.job_id					= cursorlines.job_id
	AND		SQLCensus2.step_id					= cursorlines.step_id
	--AND		SQLCensus2.LogicalStatementNumber	= cursorlines.LogicalStatementNumber
	WHERE	cursorlines.job_id IS NULL

	UNION ALL

	SELECT	SQLCensus3.job_id, SQLCensus3.step_id, N'internal fetch from global' AS Keyword
	FROM	tempdb.dbo.fnSQLRAP_SQLCensus_NearKeywordsPresentationForJobs(N'fetch',N'global', @dbid)  SQLCensus3
	JOIN	tempdb.dbo.fnSQLRAP_SQLCensus_NearKeywordsPresentationForJobs(N'cursor',N'global', @dbid) globalcursors
	ON		SQLCensus3.job_id					= globalcursors.job_id
	AND		SQLCensus3.step_id					= globalcursors.step_id

	UNION ALL

	SELECT  cursorlines.job_id, cursorlines.step_id, N'missing close' AS Keyword
	FROM
	(
		SELECT	job_id, step_id, COUNT(*) AS Kount
		FROM	tempdb.dbo.fnSQLRAP_SQLCensus_NearKeywordsPresentationForJobs(N'declare',N'cursor', @dbid)
		GROUP BY job_id, step_id
	) cursorlines
	LEFT OUTER JOIN
	(
		SELECT	sca.job_id, sca.step_id, COUNT(*) AS Kount
		FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca (NOLOCK)
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
		ON		k.Keyword		= N'close'
		AND		sca.KeywordID	= k.KeywordID
		GROUP BY sca.job_id, sca.step_id
	) SQLCensus4
	ON		SQLCensus4.job_id				= cursorlines.job_id
	AND		SQLCensus4.step_id				= cursorlines.step_id
	WHERE	SQLCensus4.job_id IS NULL
	OR		SQLCensus4.Kount				<> cursorlines.Kount
	
	UNION ALL
	
	SELECT  cursorlines.job_id, cursorlines.step_id, N'missing deallocate' AS Keyword
	FROM
	(
		SELECT	job_id, step_id, COUNT(*) AS Kount
		FROM	tempdb.dbo.fnSQLRAP_SQLCensus_NearKeywordsPresentationForJobs(N'declare',N'cursor', @dbid)
		GROUP BY job_id, step_id
	) cursorlines
	LEFT OUTER JOIN
	(
		SELECT	sca.job_id, sca.step_id, COUNT(*) AS Kount
		FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca (NOLOCK)
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
		ON		k.Keyword		= N'deallocate'
		AND		sca.KeywordID	= k.KeywordID
		GROUP BY sca.job_id, sca.step_id
	) SQLCensus5
	ON		SQLCensus5.job_id				= cursorlines.job_id
	AND		SQLCensus5.step_id				= cursorlines.step_id
	WHERE	SQLCensus5.job_id IS NULL
	OR		SQLCensus5.Kount				<> cursorlines.Kount
) SQLCensus

JOIN	msdb.dbo.sysjobs j (NOLOCK)
ON		SQLCensus.job_id	= j.job_id
JOIN	msdb.dbo.sysjobsteps s (NOLOCK)
ON		SQLCensus.job_id	= s.job_id
AND		SQLCensus.step_id	= s.step_id
LEFT OUTER JOIN tempdb.dbo.vwSQLRAP_SQLCensus_TestCaseIssue i (NOLOCK)
ON      SQLCensus.Keyword = i.Issue
AND     i.TestCase = N'cursors'

ORDER BY [RuleName]
OPTION (MAXDOP 1)

--	if this is a SQL 2000 instance, remove XML from memory
IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),1) = '8'
BEGIN
	EXEC sp_xml_removedocument @idoc1
END