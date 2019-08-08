--Signature="10253271B8AE0C05"

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    SQLCensus_Join_Issues.sql      											                         ****/
--/****    Return SQL Census Join Test Case Issues to UI                  		                             ****/
--/****                                                                                                      ****/
--/****    Created by wardp 2010.Feb.10                                                                      ****/
--/****    Updated by wardp 2010.Apr.26 (completed multi-platform support)                                   ****/
--/****    Updated by wardp 2010.Jul.22 (CR 168493)                                                          ****/
--/****    Updated by wardp 2010.Sep.29 (CR 468879)                                                          ****/
--/****    Updated by rajpo	2010.Nov.23 Case sensitivity issue                                               ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright  Microsoft Corporation. All rights reserved.                                            ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

DECLARE @dbid int,
		@idoc int,
		@Keywords1XML nvarchar(4000)

--SET @dbid = DB_ID()

SET @Keywords1XML = N'<Keywords><Keyword Keyword="=*"/><Keyword Keyword="*="/></Keywords>'

--	if this is a SQL 2000 instance, prepare XML for evaluation
IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),1) = '8'
BEGIN
	EXEC sp_xml_preparedocument @idoc OUTPUT, @Keywords1XML
END

-- return the results
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

FROM 	(
		SELECT databaseid, objectid, Keyword
		FROM tempdb.dbo.fnSQLRAP_SQLCensus_Presentation (@Keywords1XML, @dbid, @idoc) 

		UNION ALL
		
		-- database exclusion messages
		SELECT	databaseid, objectid, Keyword
		FROM	tempdb.dbo.fnSQLRAP_SQLCensus_ExclusionMessagePresentation (N'old style join')
		WHERE	objectid = -3	-- CR 468879
		) SQLCensus
LEFT OUTER JOIN
		tempdb.dbo.SQLRAP_SQLCensus_Objects obj (NOLOCK)
ON		SQLCensus.databaseid	= obj.databaseid
AND		SQLCensus.objectid		= obj.ObjectId
LEFT OUTER JOIN tempdb.dbo.vwSQLRAP_SQLCensus_TestCaseIssue i (NOLOCK)
ON      SQLCensus.Keyword = i.Issue
AND     i.TestCase = N'old style join'

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

FROM	tempdb.dbo.fnSQLRAP_SQLCensus_PresentationForJobs (@Keywords1XML, @dbid, @idoc) SQLCensus
JOIN	msdb.dbo.sysjobs j (NOLOCK)
ON		SQLCensus.job_id	= j.job_id
JOIN	msdb.dbo.sysjobsteps s (NOLOCK)
ON		SQLCensus.job_id	= s.job_id
AND		SQLCensus.step_id	= s.step_id
LEFT OUTER JOIN tempdb.dbo.vwSQLRAP_SQLCensus_TestCaseIssue i (NOLOCK)
ON      SQLCensus.Keyword = i.Issue
AND     i.TestCase = N'old style join'

ORDER BY [RuleName]
OPTION (MAXDOP 1)

--	if this is a SQL 2000 instance, remove XML from memory
IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),1) = '8'
BEGIN
	EXEC sp_xml_removedocument @idoc
END