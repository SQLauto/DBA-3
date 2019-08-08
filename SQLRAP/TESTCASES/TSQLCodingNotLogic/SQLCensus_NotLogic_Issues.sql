-- Signature="5C749FA9A54544BC"

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    SQLCensus_NotLogic_Issues.sql      											                     ****/
--/****    Return SQL Census Not Logic Test Case Issues to UI                  		                         ****/
--/****                                                                                                      ****/
--/****    Created by wardp 2010.Feb.11                                                                      ****/
--/****    Updated by wardp 2010.Jul.22 (CR 168493)                                                          ****/
--/****    Updated by wardp 2010.Sep.29 (CR 468879)                                                          ****/
--/****    Updated by rajpo	2010.Nov.23 Case sensitivity issue                                               ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright  Microsoft Corporation. All rights reserved.                                            ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

SET NOCOUNT ON

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
		SELECT	databaseid, objectid, Keyword
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)    
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis sca (NOLOCK)    
		ON		sca.KeywordID		= k.KeywordID    
		AND		k.Keyword			IN (N'<>', N'!=', N'!<', N'!>')
		AND		sca.IsPartOfObjectDeclaration = 0
		
		UNION ALL
		
		SELECT	sca1.databaseid, sca1.objectid, k1.Keyword + N' ' + k2.Keyword AS Keyword
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)  
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)  
		ON		k1.Keyword      = N'not'
		AND		k2.Keyword      IN (N'between',N'exists',N'in',N'like')
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

		UNION ALL
		
		-- database exclusion messages
		SELECT	databaseid, objectid, Keyword
		FROM	tempdb.dbo.fnSQLRAP_SQLCensus_ExclusionMessagePresentation (N'NOT logic')
		WHERE	objectid = -3	-- CR 468879

	)   SQLCensus

LEFT OUTER JOIN
		tempdb.dbo.SQLRAP_SQLCensus_Objects obj (NOLOCK)
ON		SQLCensus.databaseid	= obj.databaseid
AND		SQLCensus.objectid		= obj.ObjectId
LEFT OUTER JOIN tempdb.dbo.vwSQLRAP_SQLCensus_TestCaseIssue i (NOLOCK)
ON      SQLCensus.Keyword = i.Issue
AND     i.TestCase = N'NOT logic'
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
 		SELECT	job_id, step_id, Keyword
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k (NOLOCK)    
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca (NOLOCK)    
		ON		sca.KeywordID		= k.KeywordID    
		AND		k.Keyword			IN (N'<>', N'!=', N'!<', N'!>')
	 	
 		UNION ALL
		
		SELECT	sca1.job_id, sca1.step_id, k1.Keyword + N' ' + k2.Keyword AS Keyword
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Keywords k1 (NOLOCK)  
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_Keywords k2 (NOLOCK)  
		ON		k1.Keyword      = N'not'
		AND		k2.Keyword      IN (N'between',N'exists',N'in',N'like')
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca1 (NOLOCK)  
		ON		k1.KeywordID     = sca1.KeywordID 
		JOIN	tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs sca2 (NOLOCK)  
		ON		sca2.KeywordID     = k2.KeywordID
		AND		sca2.job_id     = sca1.job_id  
		AND		sca2.step_id     = sca1.step_id  
		AND		sca2.LogicalStatementNumber  = sca1.LogicalStatementNumber  
		AND		sca2.RowNumber     = sca1.RowNumber + 1  		
	)   SQLCensus

JOIN	msdb.dbo.sysjobs j (NOLOCK)
ON		SQLCensus.job_id	= j.job_id
JOIN	msdb.dbo.sysjobsteps s (NOLOCK)
ON		SQLCensus.job_id	= s.job_id
AND		SQLCensus.step_id	= s.step_id
LEFT OUTER JOIN tempdb.dbo.vwSQLRAP_SQLCensus_TestCaseIssue i (NOLOCK)
ON      SQLCensus.Keyword = i.Issue
AND     i.TestCase = N'NOT logic'

ORDER BY [RuleName]
OPTION (MAXDOP 1)