-- Signature="2AFB46FA2199A705"

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    SQLCensus_QueryHints_Issues.sql     											                     ****/
--/****    Return SQL Census Query Hints Test Case Issues to UI                  		                     ****/
--/****                                                                                                      ****/
--/****    Created by wardp 2010.Feb.12                                                                      ****/
--/****    Updated by wardp 2010.Jul.22 (CR 168493)                                                          ****/
--/****    Updated by wardp 2010.Sep.02 (bug 468087)                                                         ****/
--/****    Updated by wardp 2010.Sep.15 (bug 224894)                                                         ****/
--/****    Updated by wardp 2010.Sep.29 (bug 468878, CR 468879)                                              ****/
--/****    Updated by rajpo 2010.Nov.23 Case sensitivity issue                                               ****/
--/****                                                                                                      ****/
--/****    Copyright  Microsoft Corporation. All rights reserved.                                            ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

DECLARE @dbid  int,
		@idoc1 int,
		@Keywords1XML nvarchar(4000)

--SET @dbid = DB_ID()

SET @Keywords1XML = N'<Keywords><Keyword Keyword="fast"/><Keyword Keyword="maxdop"/><Keyword Keyword="maxrecursion"/><Keyword Keyword="recompile"/></Keywords>'

--	if this is a SQL 2000 instance, prepare XML for evaluation
IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),1) = '8'
BEGIN
	EXEC sp_xml_preparedocument @idoc1 OUTPUT, @Keywords1XML
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
 	SELECT databaseid, objectid, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_Presentation (@Keywords1XML, @dbid, @idoc1)
	UNION ALL
	SELECT databaseid, objectid, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation (N'concat',N'union', @dbid)
	UNION ALL
	SELECT databaseid, objectid, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation (N'expand',N'views', @dbid)
 	UNION ALL
	SELECT databaseid, objectid, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation (N'force',N'order', @dbid)
	UNION ALL
	SELECT databaseid, objectid, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation (N'hash',N'group', @dbid)
	UNION ALL
	SELECT databaseid, objectid, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation (N'hash',N'join', @dbid)
	UNION ALL
	SELECT databaseid, objectid, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation (N'hash',N'union', @dbid)
	UNION ALL
	SELECT databaseid, objectid, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation (N'keep',N'plan', @dbid)
	UNION ALL
	SELECT databaseid, objectid, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation (N'keepfixed',N'plan', @dbid)
	UNION ALL
	SELECT databaseid, objectid, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation (N'loop',N'join', @dbid)
	UNION ALL
	SELECT databaseid, objectid, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation (N'merge',N'join', @dbid)
	UNION ALL
	SELECT databaseid, objectid, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation (N'merge',N'union', @dbid)
	UNION ALL
	SELECT databaseid, objectid, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation (N'optimize',N'for', @dbid)
	UNION ALL
	SELECT databaseid, objectid, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation_invert (N'order',N'group', @dbid)
	UNION ALL
	SELECT databaseid, objectid, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation (N'parameterization',N'forced', @dbid)
	UNION ALL
	SELECT databaseid, objectid, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation (N'parameterization',N'simple', @dbid)
	UNION ALL
	SELECT databaseid, objectid, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation (N'robust',N'plan', @dbid)
	UNION ALL
	SELECT databaseid, objectid, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation_invert (N'use',N'plan', @dbid)
	UNION ALL
	-- database exclusion messages
	SELECT	databaseid, objectid, NULL, NULL, Keyword
	FROM	tempdb.dbo.fnSQLRAP_SQLCensus_ExclusionMessagePresentation (N'query hints')
	WHERE	objectid = -3	-- CR 468879

	) SQLCensus

JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca1 (NOLOCK)
ON		SQLCensus.databaseid				= sca1.databaseid
AND		SQLCensus.objectid					= sca1.objectid
AND		SQLCensus.LogicalStatementNumber	= sca1.LogicalStatementNumber
AND     sca1.StatementDepth					= SQLCensus.StatementDepth -1
AND		sca1.IsPartOfObjectDeclaration		= 0

JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
ON		k.Keyword						= N'option'
AND		sca1.KeywordID					= k.KeywordID

LEFT OUTER JOIN
		tempdb.dbo.SQLRAP_SQLCensus_Objects obj (NOLOCK)
ON		SQLCensus.databaseid	= obj.databaseid
AND		SQLCensus.objectid		= obj.ObjectId

LEFT OUTER JOIN
        tempdb.dbo.vwSQLRAP_SQLCensus_TestCaseIssue i (NOLOCK)
ON      SQLCensus.Keyword = i.Issue
AND     i.TestCase = N'query hints'

WHERE	ISNULL(CAST(obj.ObjectName AS nvarchar(255)), tempdb.dbo.fnSQLRAP_SQLCensus_ExclusionMessageCheck (SQLCensus.objectid, SQLCensus.databaseid)) IS NOT NULL

UNION ALL

SELECT DISTINCT
	SERVERPROPERTY('machinename')																						AS 'Server Name',
    ISNULL(SERVERPROPERTY('instancename'),SERVERPROPERTY('machinename'))												AS 'Instance Name',
    'msdb (Scheduled Job Steps)'																						AS 'Database Name',
    USER_NAME(j.owner_sid)																								AS 'Owner Name',
	N'Job Name [' + j.name + N']; Step Name [' + s.step_name + N']'														AS 'Object Name',
    N'Scheduled Job Step'																								AS 'Object Type',
    SQLCensus.Keyword																									AS 'Issue',
    i.RuleName                                                                                                          AS 'RuleName'
FROM 
 	(
 	SELECT job_id, step_id, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_PresentationForJobs (@Keywords1XML, @dbid, @idoc1)
	UNION ALL
	SELECT job_id, step_id, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs (N'concat',N'union', @dbid)
	UNION ALL
	SELECT job_id, step_id, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs (N'expand',N'views', @dbid)
 	UNION ALL
	SELECT job_id, step_id, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs (N'force',N'order', @dbid)
	UNION ALL
	SELECT job_id, step_id, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs (N'hash',N'group', @dbid)
	UNION ALL
	SELECT job_id, step_id, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs (N'hash',N'join', @dbid)
	UNION ALL
	SELECT job_id, step_id, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs (N'hash',N'union', @dbid)
	UNION ALL
	SELECT job_id, step_id, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs (N'keep',N'plan', @dbid)
	UNION ALL
	SELECT job_id, step_id, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs (N'keepfixed',N'plan', @dbid)
	UNION ALL
	SELECT job_id, step_id, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs (N'loop',N'join', @dbid)
	UNION ALL
	SELECT job_id, step_id, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs (N'merge',N'join', @dbid)
	UNION ALL
	SELECT job_id, step_id, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs (N'merge',N'union', @dbid)
	UNION ALL
	SELECT job_id, step_id, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs (N'optimize',N'for', @dbid)
	UNION ALL
	SELECT job_id, step_id, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs_invert (N'order',N'group', @dbid)
	UNION ALL
	SELECT job_id, step_id, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs (N'parameterization',N'forced', @dbid)
	UNION ALL
	SELECT job_id, step_id, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs (N'parameterization',N'simple', @dbid)
	UNION ALL
	SELECT job_id, step_id, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs (N'robust',N'plan', @dbid)
	UNION ALL
	SELECT job_id, step_id, LogicalStatementNumber, StatementDepth, Keyword FROM tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs_invert (N'use',N'plan', @dbid)
	) SQLCensus

JOIN	msdb.dbo.sysjobs j (NOLOCK)
ON		SQLCensus.job_id	= j.job_id
JOIN	msdb.dbo.sysjobsteps s (NOLOCK)
ON		SQLCensus.job_id	= s.job_id
AND		SQLCensus.step_id	= s.step_id

JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca1 (NOLOCK)
ON		SQLCensus.job_id					= sca1.job_id
AND		SQLCensus.step_id					= sca1.step_id
AND		SQLCensus.LogicalStatementNumber	= sca1.LogicalStatementNumber
AND     sca1.StatementDepth					= SQLCensus.StatementDepth -1

JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
ON		k.Keyword						= N'option'
AND		sca1.KeywordID					= k.KeywordID

LEFT OUTER JOIN
        tempdb.dbo.vwSQLRAP_SQLCensus_TestCaseIssue i (NOLOCK)
ON      SQLCensus.Keyword = i.Issue
AND     i.TestCase = N'query hints'

ORDER BY [RuleName]
OPTION (MAXDOP 1)

--	if this is a SQL 2000 instance, remove XML from memory
IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),1) = '8'
BEGIN
	EXEC sp_xml_removedocument @idoc1
END