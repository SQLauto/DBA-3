-- Signature="722DAD028CF32978"

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    SQLCensus_Other_Issues.sql       											                     ****/
--/****    Return SQL Census Other Test Case Issues to UI                   		                         ****/
--/****                                                                                                      ****/
--/****    Created by wardp 2010.Feb.24                                                                      ****/
--/****    Updated by wardp 2010.Jul.22 (CR 168493)                                                          ****/
--/****    Updated by wardp 2010.Sep.29 (CR 468879)                                                          ****/
--/****    Updated by wardp 2010.Sep.30 (bug 468699)                                                         ****/
--/****    Updated by rajpo 2010.Nov.23 Case sensitivity issue                                               ****/
--/****    Updated by rajpo 2010.Dec.09 (Bug 470648 exclude data digram SPs                                  ****/
--/****    Copyright  Microsoft Corporation. All rights reserved.                                            ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

--	FIVE issues in one script (including new "use of xp_cmdshell" test)

--	MISSING WHEREs:
--		algorithm: SELECTs with FROMS, but missing a WHERE or a JOIN
--				   UPDATEs and DELETEs, but missing a WHERE or a JOIN (FROM is optional for these directives)
--		discussion topic: does a JOIN count as a WHERE in this context?
--		discussion contribution: wardp says YES, as it's evidence of an effort to scope return

DECLARE @dbid  int

--SET @dbid = DB_ID()

set statistics io on
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

-- Missing WHEREs test case

(
SELECT
		DML.databaseid,
		DML.objectid,
		N'Missing WHEREs' AS Keyword
FROM
(
(
--	SELECTs with FROMs (strips out memvar assignments and displayed messages)
SELECT	sca1.databaseid,
		sca1.objectid,
		sca1.LogicalStatementNumber,
		sca1.StatementDepth,
		sca1.Iteration

FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca1 (NOLOCK)
ON		k.Keyword						= N'select'
AND		sca1.KeywordID					= k.KeywordID
AND		sca1.IsPartOfObjectDeclaration	= 0
AND     sca1.NewStatementStartsHere		= 1
JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)
ON		k.Keyword						= N'from'
JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca2 (NOLOCK)
ON		sca2.KeywordID					= k2.KeywordID
AND		sca2.IsPartOfObjectDeclaration	= 0
AND		sca1.databaseid					= sca2.databaseid
AND		sca1.objectid					= sca2.objectid
AND		sca1.LogicalStatementNumber		= sca2.LogicalStatementNumber
AND		sca1.StatementDepth				= sca2.StatementDepth
AND		sca1.Iteration					= sca2.Iteration
	
)

UNION ALL

--	DELETEs and UPDATEs (FROM is optional for these commands)
SELECT 
		sca.databaseid,
		sca.objectid,
		sca.LogicalStatementNumber,
		sca.StatementDepth,
		sca.Iteration

FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)
ON		k.Keyword						IN (N'delete', N'update')
AND		sca.KeywordID					= k.KeywordID
AND		sca.IsPartOfObjectDeclaration	= 0
AND		sca.NewStatementStartsHere		= 1

) AS [DML]

LEFT OUTER JOIN
(
SELECT
		sca.databaseid,
		sca.objectid,
		sca.LogicalStatementNumber,
		sca.StatementDepth,
		sca.Iteration

FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)
ON		k.Keyword						IN (N'join', N'where')
AND		sca.KeywordID					= k.KeywordID
AND		sca.IsPartOfObjectDeclaration	= 0
)		[Conditionals]

ON		[DML].databaseid				= [Conditionals].databaseid
AND		[DML].objectid					= [Conditionals].objectid
AND		[DML].LogicalStatementNumber	= [Conditionals].LogicalStatementNumber
AND		[DML].StatementDepth			= [Conditionals].StatementDepth
AND		[DML].Iteration					= [Conditionals].Iteration

WHERE	[Conditionals].databaseid IS NULL

UNION ALL

--	goto/xp_cmdshell test cases

SELECT	databaseid, 
		objectid, 
		Keyword 
FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)
ON		k.Keyword						IN (N'goto', N'xp_cmdshell')
AND		sca.KeywordID					= k.KeywordID
AND		sca.IsPartOfObjectDeclaration	= 0

UNION ALL

--	select * test case

SELECT	sca1.databaseid, 
		sca1.objectid, 
	    N'select *'
FROM tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)  
JOIN tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)  
ON   k1.Keyword		= N'select'
AND  k2.Keyword      = N'*'
JOIN tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca2 (NOLOCK)  
ON  k2.KeywordID     = sca2.KeywordID  
--  AND  sca2.databaseid     = @dbid  
AND  sca2.IsPartOfObjectDeclaration = 0  
JOIN tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca1 (NOLOCK)  
ON  sca1.KeywordID     = k1.KeywordID  
AND  sca1.IsPartOfObjectDeclaration = 0  
AND  sca1.databaseid     = sca2.databaseid  
AND  sca1.objectid     = sca2.objectid  
AND  sca1.LogicalStatementNumber  = sca2.LogicalStatementNumber  
AND  sca1.RowNumber     = sca2.RowNumber - 1  

UNION ALL

--	sp_ naming convention test case

SELECT	databaseid, 
		ObjectId, 
		N'sp_ naming convention' AS Keyword
FROM	tempdb.dbo.SQLRAP_SQLCensus_Objects obj (NOLOCK)
LEFT OUTER JOIN
(
	SELECT  N'sp_MSdel_%' AS CandidateReplSprocName
	UNION ALL
	SELECT  N'sp_MSins_%'
	UNION ALL
	SELECT  N'sp_MSupd_%'
	UNION ALL
	SELECT N'sp_%diagram%'
) c
ON		obj.ObjectName COLLATE Latin1_General_BIN LIKE c.CandidateReplSprocName
WHERE	LOWER(obj.ObjectName) COLLATE Latin1_General_BIN LIKE N'sp[_]%'
AND		c.CandidateReplSprocName IS NULL

UNION ALL

-- database exclusion messages
SELECT	databaseid, objectid, Keyword
FROM	tempdb.dbo.fnSQLRAP_SQLCensus_ExclusionMessagePresentation (N'other')
WHERE	objectid = -3	-- CR 468879

) AS SQLCensus

LEFT OUTER JOIN
		tempdb.dbo.SQLRAP_SQLCensus_Objects obj (NOLOCK)
ON		SQLCensus.databaseid	= obj.databaseid
AND		SQLCensus.objectid		= obj.ObjectId
LEFT OUTER JOIN tempdb.dbo.vwSQLRAP_SQLCensus_TestCaseIssue i (NOLOCK)
ON      SQLCensus.Keyword = i.Issue
AND     i.TestCase = N'other'
WHERE	ISNULL(CAST(obj.ObjectName AS nvarchar(255)), tempdb.dbo.fnSQLRAP_SQLCensus_ExclusionMessageCheck (SQLCensus.objectid, SQLCensus.databaseid)) IS NOT NULL
-- omit views from Missing WHEREs; allow from other test cases
AND
	(
			SQLCensus.Keyword		<> N'Missing WHEREs'
	OR
		(
				SQLCensus.Keyword		=  N'Missing WHEREs'
		AND		obj.ObjectType			<> N'V'
		)
	)

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

-- Missing WHEREs test case

(
SELECT
		DML.job_id,
		DML.step_id,
		N'Missing WHEREs' AS Keyword
FROM
(
(
--	SELECTs with FROMs (strips out memvar assignments and displayed messages)
SELECT	sca1.job_id,
		sca1.step_id,
		sca1.LogicalStatementNumber,
		sca1.StatementDepth,
		sca1.Iteration

FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca1 (NOLOCK)
ON		k.Keyword						= N'select'
AND		sca1.KeywordID					= k.KeywordID
AND		sca1.NewStatementStartsHere		= 1
JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)
ON		k.Keyword						= N'from'
JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca2 (NOLOCK)
ON		sca2.KeywordID					= k2.KeywordID
AND		sca1.job_id						= sca2.job_id
AND		sca1.step_id					= sca2.step_id
AND		sca1.LogicalStatementNumber		= sca2.LogicalStatementNumber
AND		sca1.StatementDepth				= sca2.StatementDepth
AND		sca1.Iteration					= sca2.Iteration
)

UNION ALL

--	DELETEs and UPDATEs (FROM is optional for these commands)
SELECT
		sca.job_id,
		sca.step_id,
		sca.LogicalStatementNumber,
		sca.StatementDepth,
		sca.Iteration

FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca (NOLOCK)
ON		k.Keyword						IN (N'delete', N'update')
AND		sca.KeywordID					= k.KeywordID
AND		sca.NewStatementStartsHere		= 1
) AS [DML]

LEFT OUTER JOIN
(
SELECT
		sca.job_id,
		sca.step_id,
		sca.LogicalStatementNumber,
		sca.StatementDepth,
		sca.Iteration

FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca (NOLOCK)
ON		k.Keyword						IN (N'join', N'where')
AND		sca.KeywordID					= k.KeywordID
)		[Conditionals]

ON		[DML].job_id					= [Conditionals].job_id
AND		[DML].step_id					= [Conditionals].step_id
AND		[DML].LogicalStatementNumber	= [Conditionals].LogicalStatementNumber
AND		[DML].StatementDepth			= [Conditionals].StatementDepth
AND		[DML].Iteration					= [Conditionals].Iteration

WHERE	[Conditionals].job_id IS NULL

UNION ALL

--	goto/xp_cmdshell test cases

SELECT	job_id, 
		step_id, 
		Keyword 
FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)
JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca (NOLOCK)
ON		k.Keyword						IN (N'goto', N'xp_cmdshell')
AND		sca.KeywordID					= k.KeywordID

UNION ALL

--	select * test case

SELECT	sca1.job_id, 
		sca1.step_id, 
	    N'select *'
FROM tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)  
JOIN tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)  
ON   k1.Keyword		= N'select'
AND  k2.Keyword      = N'*'
JOIN tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca2 (NOLOCK)  
ON  k2.KeywordID     = sca2.KeywordID  
--  AND  sca2.databaseid     = @dbid
JOIN tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca1 (NOLOCK)  
ON  sca1.KeywordID     = k1.KeywordID
AND  sca1.job_id     = sca2.job_id
AND  sca1.step_id     = sca2.step_id  
AND  sca1.LogicalStatementNumber  = sca2.LogicalStatementNumber  
AND  sca1.RowNumber     = sca2.RowNumber - 1  


) AS SQLCensus

JOIN	msdb.dbo.sysjobs j (NOLOCK)
ON		SQLCensus.job_id	= j.job_id
JOIN	msdb.dbo.sysjobsteps s (NOLOCK)
ON		SQLCensus.job_id	= s.job_id
AND		SQLCensus.step_id	= s.step_id

LEFT OUTER JOIN tempdb.dbo.vwSQLRAP_SQLCensus_TestCaseIssue i (NOLOCK)
ON      SQLCensus.Keyword = i.Issue
AND     i.TestCase = N'other'

ORDER BY [RuleName]
OPTION (MAXDOP 1)
