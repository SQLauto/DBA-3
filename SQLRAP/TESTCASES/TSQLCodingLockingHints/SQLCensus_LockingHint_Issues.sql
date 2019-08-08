-- Signature="D872CA4C2C179EB9"

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    SQLCensus_LockingHint_Issues.sql      											                 ****/
--/****    Return SQL Locking Hint Cursor Test Case Issues to UI                  		                     ****/
--/****                                                                                                      ****/
--/****    Created by wardp 2010.Feb.23                                                                      ****/
--/****    Updated by wardp 2010.Jul.22 (CR 168493)                                                          ****/
--/****    Updated by wardp 2010.Sep.29 (CR 468879)                                                          ****/
--/****    Updated by rajpo	2010.Nov.23 Case sensitivity issue                                               ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright  Microsoft Corporation. All rights reserved.                                            ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

DECLARE @dbid  int

--SET @dbid = DB_ID()

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
	SELECT	sca.databaseid, sca.objectid, k.Keyword + N' tran level' AS Keyword
	FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)  
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)  
	ON		k.Keyword		  IN (N'holdlock',N'nolock',N'paglock',N'readcommitted',N'readpast',N'readuncommitted',
									N'repeatableread',N'rowlock',N'serializable',N'tablock',N'tablockx',N'updlock',N'xlock')
	AND		sca.KeywordID     = k.KeywordID  
	AND		sca.IsPartOfObjectDeclaration = 0  
	JOIN	(
			SELECT	sca1.databaseid,  
					sca1.objectid,  
					sca1.LogicalStatementNumber,  
					N'set transaction' AS Keyword  
			FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)  
			JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)  
			ON		k1.Keyword      = N'set'
			AND		k2.Keyword      = N'transaction'
			JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca1 (NOLOCK)  
			ON		k1.KeywordID     = sca1.KeywordID  
			AND		sca1.IsPartOfObjectDeclaration = 0  
			JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca2 (NOLOCK)  
			ON		sca2.KeywordID     = k2.KeywordID  
			AND		sca2.IsPartOfObjectDeclaration = 0  
			AND		sca2.databaseid     = sca1.databaseid  
			AND		sca2.objectid     = sca1.objectid  
			AND		sca2.LogicalStatementNumber  = sca1.LogicalStatementNumber  
			AND		sca2.RowNumber     = sca1.RowNumber + 1  
			) cursorlines1
	ON		sca.databaseid				= cursorlines1.databaseid
	AND		sca.objectid					= cursorlines1.objectid
	AND		sca.LogicalStatementNumber	= cursorlines1.LogicalStatementNumber

	UNION ALL

	SELECT	sca.databaseid, sca.objectid, k.Keyword + N' mod' as Keyword
	FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)  
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)  
	ON		k.Keyword		  IN (N'holdlock',N'nolock',N'paglock',N'readcommitted',N'readpast',N'readuncommitted',
									N'repeatableread',N'rowlock',N'serializable',N'tablock',N'tablockx',N'updlock',N'xlock')
	AND		sca.KeywordID     = k.KeywordID  
	AND		sca.IsPartOfObjectDeclaration = 0  
	JOIN
	(
		SELECT	sca.databaseid, sca.objectid, sca.LogicalStatementNumber
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)  
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)  
		ON		sca.KeywordID     = k.KeywordID
		AND		k.Keyword			IN (N'delete',N'update')
		AND		sca.IsPartOfObjectDeclaration = 0
		UNION
		SELECT	sca2.databaseid, sca2.objectid, sca2.LogicalStatementNumber
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)  
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)  
		ON		k1.Keyword      = N'insert'
		AND		k2.Keyword      = N'select'
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca1 (NOLOCK)  
		ON		k1.KeywordID     = sca1.KeywordID  
		AND		sca1.IsPartOfObjectDeclaration = 0  
		AND		sca1.NewStatementStartsHere     = 1  
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca2 (NOLOCK)  
		ON		sca2.KeywordID     = k2.KeywordID  
		AND		sca2.IsPartOfObjectDeclaration = 0  
		AND		sca2.NewStatementStartsHere  = 1  
		AND		sca2.databaseid     = sca1.databaseid  
		AND		sca2.objectid     = sca1.objectid  
		AND		sca2.LogicalStatementNumber  = sca1.LogicalStatementNumber + 1  
	) cursorlines2
	ON		sca.databaseid				= cursorlines2.databaseid
	AND		sca.objectid				= cursorlines2.objectid
	AND		sca.LogicalStatementNumber	= cursorlines2.LogicalStatementNumber
	
	UNION ALL
	
	SELECT	sca.databaseid, sca.objectid, k.Keyword + N' no mod' as Keyword
	FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)  
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)  
	ON		k.Keyword		  IN (N'holdlock',N'nolock',N'paglock',N'readcommitted',N'readpast',N'readuncommitted',
									N'repeatableread',N'rowlock',N'serializable',N'tablock',N'tablockx',N'updlock',N'xlock')
	AND		sca.KeywordID     = k.KeywordID  
	AND		sca.IsPartOfObjectDeclaration = 0  
	LEFT OUTER JOIN
	(
		SELECT	sca.databaseid, sca.objectid, sca.LogicalStatementNumber
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)  
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)  
		ON		sca.KeywordID		= k.KeywordID  
		AND		k.Keyword			IN (N'delete',N'transaction',N'update')
		AND		sca.IsPartOfObjectDeclaration = 0  
		UNION ALL
		SELECT	sca2.databaseid, sca2.objectid, sca2.LogicalStatementNumber
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)  
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)  
		ON		k1.Keyword      = N'insert'
		AND		k2.Keyword      = N'select'
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca1 (NOLOCK)  
		ON		k1.KeywordID     = sca1.KeywordID  
		AND		sca1.IsPartOfObjectDeclaration = 0  
		AND		sca1.NewStatementStartsHere     = 1  
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca2 (NOLOCK)  
		ON		sca2.KeywordID     = k2.KeywordID  
		AND		sca2.IsPartOfObjectDeclaration = 0  
		AND		sca2.NewStatementStartsHere  = 1  
		AND		sca2.databaseid     = sca1.databaseid  
		AND		sca2.objectid     = sca1.objectid  
		AND		sca2.LogicalStatementNumber  = sca1.LogicalStatementNumber + 1  
	) cursorlines3
	ON		sca.databaseid				= cursorlines3.databaseid
	AND		sca.objectid					= cursorlines3.objectid
	AND		sca.LogicalStatementNumber	= cursorlines3.LogicalStatementNumber
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Objects o (NOLOCK)
	ON		sca.databaseid				= o.databaseid
	AND		sca.objectid					= o.ObjectId
	WHERE	o.ObjectType						<> N'V'
	AND		cursorlines3.databaseid				IS NULL

	UNION ALL
	
	SELECT	sca.databaseid, sca.objectid, k.Keyword + N' nolock' as Keyword
	FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)  
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)  
	ON		sca.KeywordID     = k.KeywordID
	AND		k.Keyword		  IN (N'paglock', N'readcommitted', N'readpast', N'readuncommitted', N'repeatableread',
									N'rowlock', N'serializable', N'tablock')
	AND		sca.IsPartOfObjectDeclaration = 0  
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca1 (NOLOCK)
	ON		sca.databaseid				= sca1.databaseid
	AND		sca.objectid					= sca1.objectid
	AND		sca.LogicalStatementNumber	= sca1.LogicalStatementNumber
	AND		sca1.IsPartOfObjectDeclaration		= 0
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)
	ON		k1.Keyword							= N'nolock'
	AND		sca1.KeywordID						= k1.KeywordID
	
	UNION ALL

	-- database exclusion messages
	SELECT	databaseid, objectid, Keyword
	FROM	tempdb.dbo.fnSQLRAP_SQLCensus_ExclusionMessagePresentation ('locking hints')
	WHERE	objectid = -3	-- CR 468879

) SQLCensus
LEFT OUTER JOIN
		tempdb.dbo.SQLRAP_SQLCensus_Objects obj (NOLOCK)
ON		SQLCensus.databaseid	= obj.databaseid
AND		SQLCensus.objectid		= obj.ObjectId
LEFT OUTER JOIN tempdb.dbo.vwSQLRAP_SQLCensus_TestCaseIssue i (NOLOCK)
ON      SQLCensus.Keyword = i.Issue
AND     i.TestCase = N'locking hints'

WHERE	ISNULL(CAST(obj.ObjectName AS nvarchar(255)), tempdb.dbo.fnSQLRAP_SQLCensus_ExclusionMessageCheck (SQLCensus.objectid, SQLCensus.databaseid)) IS NOT NULL

UNION ALL

SELECT DISTINCT
	SERVERPROPERTY('machinename')																						AS 'Server Name',
    ISNULL(SERVERPROPERTY('instancename'),SERVERPROPERTY('machinename'))												AS 'Instance Name',
    'msdb (Scheduled Job Steps)'																							AS 'Database Name',
    USER_NAME(j.owner_sid)																								AS 'Owner Name',
	N'Job Name [' + j.name + N']; Step Name [' + s.step_name + N']'														AS 'Object Name',
    N'Scheduled Job Step'																								AS 'Object Type',
    SQLCensus.Keyword																									AS 'Issue',
    i.RuleName                                                                                                          AS 'RuleName'

FROM
(
	SELECT	sca.job_id, sca.step_id, k.Keyword + N' tran level' AS Keyword
	FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)  
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca (NOLOCK)  
	ON		k.Keyword		  IN (N'holdlock',N'nolock',N'paglock',N'readcommitted',N'readpast',N'readuncommitted',
									N'repeatableread',N'rowlock',N'serializable',N'tablock',N'tablockx',N'updlock',N'xlock')
	AND		sca.KeywordID     = k.KeywordID  
	JOIN	(
			SELECT	sca1.job_id,  
					sca1.step_id,  
					sca1.LogicalStatementNumber,  
					N'set transaction' AS Keyword  
			FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)  
			JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)  
			ON		k1.Keyword      = N'set'
			AND		k2.Keyword      = N'transaction'
			JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca1 (NOLOCK)  
			ON		k1.KeywordID     = sca1.KeywordID
			JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca2 (NOLOCK)  
			ON		sca2.KeywordID		= k2.KeywordID  
			AND		sca2.job_id			= sca1.job_id  
			AND		sca2.step_id     = sca1.step_id
			AND		sca2.LogicalStatementNumber  = sca1.LogicalStatementNumber  
			AND		sca2.RowNumber     = sca1.RowNumber + 1  
			) cursorlines1
	ON		sca.job_id					= cursorlines1.job_id
	AND		sca.step_id					= cursorlines1.step_id
	AND		sca.LogicalStatementNumber	= cursorlines1.LogicalStatementNumber

	UNION ALL

	SELECT	sca.job_id, sca.step_id, k.Keyword + N' mod' as Keyword
	FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)  
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca (NOLOCK)  
	ON		k.Keyword		  IN (N'holdlock',N'nolock',N'paglock',N'readcommitted',N'readpast',N'readuncommitted',
									N'repeatableread',N'rowlock',N'serializable',N'tablock',N'tablockx',N'updlock',N'xlock')
	AND		sca.KeywordID     = k.KeywordID  
	JOIN
	(
		SELECT	sca.job_id, sca.step_id, sca.LogicalStatementNumber
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)  
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca (NOLOCK)  
		ON		sca.KeywordID     = k.KeywordID
		AND		k.Keyword			IN (N'delete',N'update')
		UNION
		SELECT	sca2.job_id, sca2.step_id, sca2.LogicalStatementNumber
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)  
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)  
		ON		k1.Keyword      = N'insert'
		AND		k2.Keyword      = N'select'
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca1 (NOLOCK)  
		ON		k1.KeywordID     = sca1.KeywordID  
		AND		sca1.NewStatementStartsHere     = 1  
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca2 (NOLOCK)  
		ON		sca2.KeywordID     = k2.KeywordID  
		AND		sca2.NewStatementStartsHere  = 1  
		AND		sca2.job_id     = sca1.job_id  
		AND		sca2.step_id     = sca1.step_id  
		AND		sca2.LogicalStatementNumber  = sca1.LogicalStatementNumber + 1  
	) cursorlines2
	ON		sca.job_id					= cursorlines2.job_id
	AND		sca.step_id					= cursorlines2.step_id
	AND		sca.LogicalStatementNumber	= cursorlines2.LogicalStatementNumber
	
	UNION ALL
	
	SELECT	sca.job_id, sca.step_id, k.Keyword + N' no mod' as Keyword
	FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)  
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca (NOLOCK)  
	ON		k.Keyword		  IN (N'holdlock',N'nolock',N'paglock',N'readcommitted',N'readpast',N'readuncommitted',
									N'repeatableread',N'rowlock',N'serializable',N'tablock',N'tablockx',N'updlock',N'xlock')
	AND		sca.KeywordID     = k.KeywordID  
	LEFT OUTER JOIN
	(
		SELECT	job_id, step_id, LogicalStatementNumber
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)  
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca (NOLOCK)  
		ON		sca.KeywordID		= k.KeywordID  
		AND		k.Keyword			IN (N'delete',N'transaction',N'update')
		UNION
		SELECT	sca2.job_id, sca2.step_id, sca2.LogicalStatementNumber
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)  
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)  
		ON		k1.Keyword      = N'insert'
		AND		k2.Keyword      = N'select'
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca1 (NOLOCK)  
		ON		k1.KeywordID     = sca1.KeywordID  
		AND		sca1.NewStatementStartsHere     = 1  
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca2 (NOLOCK)  
		ON		sca2.KeywordID     = k2.KeywordID  
		AND		sca2.NewStatementStartsHere  = 1  
		AND		sca2.job_id     = sca1.job_id  
		AND		sca2.step_id     = sca1.step_id  
		AND		sca2.LogicalStatementNumber  = sca1.LogicalStatementNumber + 1  
	) cursorlines3
	ON		sca.job_id					= cursorlines3.job_id
	AND		sca.step_id					= cursorlines3.step_id
	AND		sca.LogicalStatementNumber	= cursorlines3.LogicalStatementNumber
	WHERE	cursorlines3.job_id				IS NULL

	UNION ALL
	
	SELECT	sca.job_id, sca.step_id, k.Keyword + N' nolock' as Keyword
	FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)  
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca (NOLOCK)  
	ON		sca.KeywordID     = k.KeywordID
	AND		k.Keyword		  IN (N'paglock', N'readcommitted', N'readpast', N'readuncommitted', N'repeatableread',
									N'rowlock', N'serializable', N'tablock')
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca1 (NOLOCK)
	ON		sca.job_id					= sca1.job_id
	AND		sca.step_id					= sca1.step_id
	AND		sca.LogicalStatementNumber	= sca1.LogicalStatementNumber
	JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)
	ON		k1.Keyword							= N'nolock'
	AND		sca1.KeywordID						= k1.KeywordID

) SQLCensus

JOIN	msdb.dbo.sysjobs j (NOLOCK)
ON		SQLCensus.job_id	= j.job_id
JOIN	msdb.dbo.sysjobsteps s (NOLOCK)
ON		SQLCensus.job_id	= s.job_id
AND		SQLCensus.step_id	= s.step_id
LEFT OUTER JOIN tempdb.dbo.vwSQLRAP_SQLCensus_TestCaseIssue i (NOLOCK)
ON      SQLCensus.Keyword = i.Issue
AND     i.TestCase = N'locking hints'

ORDER BY [RuleName]
OPTION (MAXDOP 1)