-- Signature="9DAB98386E7D1BE9"

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    SQLCensus_XML_Issues.sql         											                     ****/
--/****    Return SQL Census XML Test Case Issues to UI                  		                             ****/
--/****                                                                                                      ****/
--/****    Created by wardp 2010.Feb.23                                                                      ****/
--/****    Updated by wardp 2010.Jun.07 (first draft complete)                                               ****/
--/****    Updated by wardp 2010.Jul.22 (CR 168493)                                                          ****/
--/****    Updated by wardp 2010.Sep.11 (bug 468281)                                                         ****/
--/****    Updated by wardp 2010.Sep.29 (CR 468879)                                                          ****/
--/****    Updated by rajpo 2010.Nov.23 Case sensitivity issues                                              ****/
--/****    Updated by gsacavdm 2011.Apr.8 (Bug 473806)														 ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright  Microsoft Corporation. All rights reserved.                                            ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

DECLARE @dbid  int

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

	-- FOR XML test case
	SELECT	databaseid, objectid, Keyword 
	FROM	tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentation_invert(N'for',N'xml', @dbid)

	UNION ALL

--	OPENXML test case
	SELECT	sca1.databaseid, sca1.objectid, k.Keyword
	FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca1 (NOLOCK)
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
	ON		k.Keyword				= N'openxml'
	AND		sca1.KeywordID			= k.KeywordID

	UNION ALL
	
--	sp_xml_removedocument test case
	SELECT	sca1.databaseid, sca1.objectid, N'sp_xml_removedocument'
    FROM
    (
        SELECT	sca.databaseid, sca.objectid, sca.number, COUNT(*) AS Counter
	    FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)
	    JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
	    ON		k.Keyword				= N'sp_xml_preparedocument'
	    AND		sca.KeywordID			= k.KeywordID
        GROUP BY sca.databaseid, sca.objectid, sca.number
    ) sca1
	LEFT OUTER JOIN
    (
        SELECT	DISTINCT sca.databaseid, sca.objectid, sca.number, COUNT(*) AS Counter
	    FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)
	    JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
	    ON		k.Keyword				= N'sp_xml_removedocument'
	    AND		sca.KeywordID			= k.KeywordID
        GROUP BY sca.databaseid, sca.objectid, sca.number
    ) sca2
	ON		sca1.databaseid			= sca2.databaseid
	AND		sca1.objectid			= sca2.objectid
	AND		sca1.number				= sca2.number
	WHERE	sca2.databaseid IS NULL
    OR      sca1.Counter <> sca2.Counter

	UNION ALL

--	single root node test case
	SELECT	sca1.databaseid, sca1.objectid, N'single root node'
	FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca1 (NOLOCK)
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)
	ON		k1.Keyword				IN (N'.nodes',N'openxml')
	AND		sca1.KeywordID			= k1.KeywordID
	AND     (	
			SELECT ISNULL(MAX(1),0)
			FROM tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca2 (NOLOCK)
			JOIN tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)
				ON		k2.Keyword				= N'[1]'
				AND		k2.KeywordID			= sca2.KeywordID
			WHERE	
						sca1.databaseid			= sca2.databaseid
				AND		sca1.objectid			= sca2.objectid
				AND		sca1.number				= sca2.number
				AND		sca1.LogicalStatementNumber = sca2.LogicalStatementNumber
			) = 0

	UNION ALL

--	parent axis access test case
	SELECT	sca1.databaseid, sca1.objectid, N'parent axis access'
	FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca1 (NOLOCK)
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)
	ON		k1.Keyword				IN (N'.nodes',N'openxml')
	AND		sca1.KeywordID			= k1.KeywordID
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca2 (NOLOCK)
	ON		sca1.databaseid			= sca2.databaseid
	AND		sca1.objectid			= sca2.objectid
	AND		sca1.number				= sca2.number
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)
	ON		k2.Keyword				= N'../'
	AND		k2.KeywordID			= sca2.KeywordID

	UNION ALL

--	instrinsics test case
	SELECT	sca1.databaseid, sca1.objectid, N'intrinsics'
	FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca1 (NOLOCK)
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)
	ON		k1.Keyword				= N'.value'
	AND		sca1.KeywordID			= k1.KeywordID
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca2 (NOLOCK)
	ON		sca1.databaseid			= sca2.databaseid
	AND		sca1.objectid			= sca2.objectid
	AND		sca1.number				= sca2.number
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)
	ON		k2.Keyword				= N'.nodes'
	AND		k2.KeywordID			= sca2.KeywordID
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k3 (NOLOCK)
	ON		k3.Keyword				IN (N'join',N'where')
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca3 (NOLOCK)
	ON		sca1.databaseid			= sca3.databaseid
	AND		sca1.objectid			= sca3.objectid
	AND		sca1.number				= sca3.number
	AND		k3.KeywordID			= sca3.KeywordID
	AND		sca1.LocationInCode		> sca3.LocationInCode

	UNION ALL

--	expanded paths test case
	SELECT	sca1.databaseid, sca1.objectid, N'expanded paths'
	FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca1 (NOLOCK)
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)
	ON		k1.Keyword				IN (N'.nodes', '.value', '.query', '.modify')
	AND		sca1.KeywordID			= k1.KeywordID
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca2 (NOLOCK)
	ON		sca1.databaseid			= sca2.databaseid
	AND		sca1.objectid			= sca2.objectid
	AND		sca1.number				= sca2.number
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)
	ON		k2.Keyword				= N'[@'
	AND		k2.KeywordID			= sca2.KeywordID

	UNION ALL

-- database exclusion messages
	SELECT	databaseid, objectid, Keyword
	FROM	tempdb.dbo.fnSQLRAP_SQLCensus_ExclusionMessagePresentation (N'xml')
	WHERE	objectid = -3	-- CR 468879
) SQLCensus
LEFT OUTER JOIN
		tempdb.dbo.SQLRAP_SQLCensus_Objects obj (NOLOCK)
ON		SQLCensus.databaseid	= obj.databaseid
AND		SQLCensus.objectid		= obj.ObjectId

LEFT OUTER JOIN
        tempdb.dbo.vwSQLRAP_SQLCensus_TestCaseIssue i (NOLOCK)
ON      SQLCensus.Keyword = i.Issue
AND     i.TestCase = N'xml'

WHERE	ISNULL(CAST(obj.ObjectName AS nvarchar(255)), tempdb.dbo.fnSQLRAP_SQLCensus_ExclusionMessageCheck (SQLCensus.objectid, SQLCensus.databaseid)) IS NOT NULL

UNION ALL

SELECT DISTINCT		
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

	-- FOR XML test case
	SELECT	job_id, step_id, Keyword 
	FROM	tempdb.dbo.fnSQLRAP_SQLCensus_AdjacentKeywordsPresentationForJobs_invert(N'for',N'xml', @dbid)

	UNION ALL

--	OPENXML test case
	SELECT	sca1.job_id, sca1.step_id, k.Keyword
	FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca1 (NOLOCK)
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
	ON		k.Keyword				= N'openxml'
	AND		sca1.KeywordID			= k.KeywordID

	UNION ALL
	
--	sp_xml_removedocument test case
	SELECT	sca1.job_id, sca1.step_id, N'sp_xml_removedocument'
    FROM
    (
        SELECT	sca.job_id, sca.step_id, COUNT(*) AS Counter
	    FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca (NOLOCK)
	    JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
	    ON		k.Keyword				= N'sp_xml_preparedocument'
	    AND		sca.KeywordID			= k.KeywordID
        GROUP BY sca.job_id, sca.step_id
    ) sca1
	LEFT OUTER JOIN
    (
        SELECT	DISTINCT sca.job_id, sca.step_id, COUNT(*) AS Counter
	    FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca (NOLOCK)
	    JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
	    ON		k.Keyword				= N'sp_xml_removedocument'
	    AND		sca.KeywordID			= k.KeywordID
        GROUP BY sca.job_id, sca.step_id
    ) sca2
	ON		sca1.job_id			= sca2.job_id
	AND		sca1.step_id			= sca2.step_id
	WHERE	sca2.job_id IS NULL
    OR      sca1.Counter <> sca2.Counter

	UNION ALL

--	single root node test case
	SELECT	sca1.job_id, sca1.step_id, N'single root node'
	FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca1 (NOLOCK)
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)
	ON		k1.Keyword				IN (N'.nodes',N'openxml')
	AND		sca1.KeywordID			= k1.KeywordID
	AND     (	
			SELECT ISNULL(MAX(1),0)
			FROM tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca2 (NOLOCK)
			JOIN tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)
				ON		k2.Keyword				= N'[1]'
				AND		k2.KeywordID			= sca2.KeywordID
			WHERE	
						sca1.job_id					= sca2.job_id
				AND		sca1.step_id				= sca2.step_id
				AND		sca1.LogicalStatementNumber = sca2.LogicalStatementNumber
			) = 0

	UNION ALL

--	parent axis access test case
	SELECT	sca1.job_id, sca1.step_id, N'parent axis access'
	FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca1 (NOLOCK)
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)
	ON		k1.Keyword				IN (N'.nodes',N'openxml')
	AND		sca1.KeywordID			= k1.KeywordID
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca2 (NOLOCK)
	ON		sca1.job_id				= sca2.job_id
	AND		sca1.step_id			= sca2.step_id
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)
	ON		k2.Keyword				= N'../'
	AND		k2.KeywordID			= sca2.KeywordID

	UNION ALL

--	instrinsics test case
	SELECT	sca1.job_id, sca1.step_id, N'intrinsics'
	FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca1 (NOLOCK)
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)
	ON		k1.Keyword				= N'.value'
	AND		sca1.KeywordID			= k1.KeywordID
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca2 (NOLOCK)
	ON		sca1.job_id				= sca2.job_id
	AND		sca1.step_id			= sca2.step_id
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)
	ON		k2.Keyword				= N'.nodes'
	AND		k2.KeywordID			= sca2.KeywordID
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k3 (NOLOCK)
	ON		k3.Keyword				IN (N'join',N'where')
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca3 (NOLOCK)
	ON		sca1.job_id				= sca3.job_id
	AND		sca1.step_id			= sca3.step_id
	AND		k3.KeywordID			= sca3.KeywordID
	AND		sca1.LocationInCode		> sca3.LocationInCode

	UNION ALL

--	expanded paths test case
	SELECT	sca1.job_id, sca1.step_id, N'expanded paths'
	FROM	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca1 (NOLOCK)
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)
	ON		k1.Keyword				IN (N'.nodes', '.value', '.query', '.modify')
	AND		sca1.KeywordID			= k1.KeywordID
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca2 (NOLOCK)
	ON		sca1.job_id			    = sca2.job_id
	AND		sca1.step_id			= sca2.step_id
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)
	ON		k2.Keyword				= N'[@'
	AND		k2.KeywordID			= sca2.KeywordID
) SQLCensus

JOIN	msdb.dbo.sysjobs j (NOLOCK)
ON		SQLCensus.job_id	= j.job_id
JOIN	msdb.dbo.sysjobsteps s (NOLOCK)
ON		SQLCensus.job_id	= s.job_id
AND		SQLCensus.step_id	= s.step_id

LEFT OUTER JOIN
        tempdb.dbo.vwSQLRAP_SQLCensus_TestCaseIssue i (NOLOCK)
ON      SQLCensus.Keyword = i.Issue
AND     i.TestCase = N'xml'

ORDER BY [RuleName]
OPTION (MAXDOP 1)
