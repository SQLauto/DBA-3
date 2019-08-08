-- Signature="CC75CC603E0298C5"

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    SQL Census Bootstrap.sql															                 ****/
--/****    build ExcludedDatabase infrastructure on an instance                                              ****/
--/****                                                                                                      ****/
--/****    2010.Apr.27 - created (wardp) - new work						                                     ****/
--/****    2010.Sep.15 - created (wardp) - platform-specific versions consolidated into single script        ****/
--/****    2010.Oct.26 - changed (rajpo) the rule name to sql_select_star from sql_select_*                  ****/
--/****    2010.Dec.06 - updated (rajpo) -Bug# 471301 case sensitivity fix                                   ****/                                                                                                  
--/****    2010.Jan.11 - updated (rajpo) -Took the old version that worked with the RAPID intigration and    ****/
--/****                                   Added case sensitive fixes back to that version.                   ****/
--/****                                                                                                      ****/
--/****    Copyright (c) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

SET NOCOUNT ON
USE tempdb
GO


USE tempdb
-- first do tasks which are common to all platforms

-- drop the spSQLRAP_SQLCensus_ExcludedDatabases procedure
-- (the procedure is created in the platform-specific branches below)
IF OBJECT_ID('dbo.spSQLRAP_SQLCensus_ExcludedDatabases') IS NOT NULL
BEGIN
	DROP PROCEDURE dbo.spSQLRAP_SQLCensus_ExcludedDatabases
END
GO


USE tempdb
-- create the SQLRAP_SQLCensus_ExcludedDatabases table
IF OBJECT_ID('dbo.SQLRAP_SQLCensus_ExcludedDatabases') IS NULL
BEGIN
	EXEC('
		CREATE TABLE dbo.SQLRAP_SQLCensus_ExcludedDatabases (
			databaseid			 int,
			DateInserted		 datetime,
			LastUpdated			 datetime,
			ExcludeDatabase		 bit
			PRIMARY KEY (databaseid)
		)
	')
END
GO

USE tempdb

-- create the SQLRAP_SQLCensus_Issue table
IF OBJECT_ID('dbo.SQLRAP_SQLCensus_Issue') IS NOT NULL
BEGIN
	DROP TABLE dbo.SQLRAP_SQLCensus_Issue
END
GO

USE tempdb
CREATE TABLE dbo.SQLRAP_SQLCensus_Issue
(
	IssueId	int identity(1,1),
	TestCaseId	int,
	Issue		sysname,
	RuleName    sysname
	PRIMARY KEY (TestCaseId, IssueId)
)
GO

USE tempdb

-- create the SQLRAP_SQLCensus_ReservedWords table
IF OBJECT_ID('dbo.SQLRAP_SQLCensus_ReservedWords') IS NOT NULL
BEGIN
	DROP TABLE dbo.SQLRAP_SQLCensus_ReservedWords
END
GO

USE tempdb
CREATE TABLE dbo.SQLRAP_SQLCensus_ReservedWords
(
    ReservedWord nvarchar(256)
)
GO

USE tempdb
-- create the SQLRAP_SQLCensus_TestCase table
IF OBJECT_ID('SQLRAP_SQLCensus_TestCase') IS NOT NULL
BEGIN
	DROP TABLE dbo.SQLRAP_SQLCensus_TestCase
END
GO

USE tempdb
CREATE TABLE dbo.SQLRAP_SQLCensus_TestCase
(
	TestCaseId	int identity(1,1),
	TestCase	sysname
	PRIMARY KEY (TestCaseId)
)
GO

USE tempdb
-- create the vwSQLRAP_SQLCensus_TestCaseIssue view
IF OBJECT_ID('dbo.vwSQLRAP_SQLCensus_TestCaseIssue') IS NOT NULL
BEGIN
	DROP VIEW dbo.vwSQLRAP_SQLCensus_TestCaseIssue
END
GO


CREATE VIEW [vwSQLRAP_SQLCensus_TestCaseIssue]
AS
SELECT	t.TestCaseId,
		i.IssueId,
		t.TestCase,
		i.Issue,
		i.RuleName
FROM	tempdb.dbo.SQLRAP_SQLCensus_TestCase t (NOLOCK)
JOIN	tempdb.dbo.SQLRAP_SQLCensus_Issue i (NOLOCK)
ON		t.TestCaseId = i.TestCaseId
GO

USE tempdb
-- build test case records
INSERT	dbo.SQLRAP_SQLCensus_TestCase (TestCase)
SELECT	'cursors'
UNION ALL
SELECT  'join hints'
UNION ALL
SELECT	'locking hints'
UNION ALL
SELECT	'NOT logic'
UNION ALL
SELECT	'old style join'
UNION ALL
SELECT	'other'
UNION ALL
SELECT	'query hints'
UNION ALL
SELECT	'xml'
UNION ALL
SELECT  'reserved words'

-- build issue records
BEGIN TRAN

INSERT	dbo.SQLRAP_SQLCensus_Issue (TestCaseId, Issue, RuleName)
SELECT	t.TestCaseId,
		i.Issue,
		i.RuleName
FROM	dbo.SQLRAP_SQLCensus_TestCase t (NOLOCK)
JOIN	(
		SELECT	'dynamic' AS Issue, 'SQL_cursor_dynamic_statement' AS RuleName
		UNION ALL
		SELECT	'external fetch from global', 'SQL_cursor_global_fetch_statement'
		UNION ALL
		SELECT	'global', 'SQL_cursor_global_statement'
		UNION ALL
		SELECT	'internal fetch from global', 'SQL_cursor_fetch_global_statement'
		UNION ALL
		SELECT	'insensitive', 'SQL_cursor_insensitive_statement'
		UNION ALL
		SELECT	'keyset', 'SQL_cursor_keyset_statement'
		UNION ALL
		SELECT	'static', 'SQL_cursor_static_statement'
		UNION ALL
		SELECT	'missing close', 'SQL_cursor_not_closed_statement'
		UNION ALL
		SELECT	'missing deallocate', 'SQL_cursor_not_deallocated_statement'
		) i
ON		t.TestCase = N'cursors'

UNION ALL

SELECT	t.TestCaseId,
		i.Issue,
		i.RuleName
FROM	dbo.SQLRAP_SQLCensus_TestCase t (NOLOCK)
JOIN	(
		SELECT	'hash join' AS Issue, 'SQL_join_hints_hash' AS RuleName
		UNION ALL
		SELECT	'loop join', 'SQL_join_hints_loop'
		UNION ALL
		SELECT	'merge join', 'SQL_join_hints_merge'
		UNION ALL
		SELECT	'remote join', 'SQL_join_hints_remote'
		) i
ON		t.TestCase = N'join hints'

UNION ALL

SELECT	t.TestCaseId,
		i.Issue,
		i.RuleName
FROM	dbo.SQLRAP_SQLCensus_TestCase t (NOLOCK)
JOIN	(
		SELECT	'holdlock mod' AS Issue, 'SQL_locking_hints_holdlock_mod' AS RuleName
		UNION ALL
		SELECT	'nolock mod', 'SQL_locking_hints_nolock_mod'
		UNION ALL
		SELECT	'paglock mod', 'SQL_locking_hints_paglock_mod'
		UNION ALL
		SELECT	'readcommitted mod', 'SQL_locking_hints_readcommitted_mod'
		UNION ALL
		SELECT	'readpast mod', 'SQL_locking_hints_readpast_mod'
		UNION ALL
		SELECT	'readuncommitted mod', 'SQL_locking_hints_readuncommitted_mod'
		UNION ALL
		SELECT	'repeatableread mod', 'SQL_locking_hints_repeatableread_mod'
		UNION ALL
		SELECT	'rowlock mod', 'SQL_locking_hints_rowlock_mod'
		UNION ALL
		SELECT	'serializable mod', 'SQL_locking_hints_serializable_mod'
		UNION ALL
		SELECT	'tablock mod', 'SQL_locking_hints_tablock_mod'
		UNION ALL
		SELECT	'tablockx mod', 'SQL_locking_hints_tablockx_mod'
		UNION ALL
		SELECT	'updlock mod', 'SQL_locking_hints_updlock_mod'
		UNION ALL
		SELECT	'xlock mod', 'SQL_locking_hints_xlock_mod'
		UNION ALL
		SELECT	'holdlock no mod', 'SQL_locking_hints_holdlock_no_mod'
		UNION ALL
		SELECT	'nolock no mod', 'SQL_locking_hints_nolock_no_mod'
		UNION ALL
		SELECT	'paglock no mod', 'SQL_locking_hints_paglock_no_mod'
		UNION ALL
		SELECT	'readcommitted no mod', 'SQL_locking_hints_readcommitted_no_mod'
		UNION ALL
		SELECT	'readpast no mod', 'SQL_locking_hints_readpast_no_mod'
		UNION ALL
		SELECT	'readuncommitted no mod', 'SQL_locking_hints_readuncommitted_no_mod'
		UNION ALL
		SELECT	'repeatableread no mod', 'SQL_locking_hints_repeatableread_no_mod'
		UNION ALL
		SELECT	'rowlock no mod', 'SQL_locking_hints_rowlock_no_mod'
		UNION ALL
		SELECT	'serializable no mod', 'SQL_locking_hints_serializable_no_mod'
		UNION ALL
		SELECT	'tablock no mod', 'SQL_locking_hints_tablock_no_mod'
		UNION ALL
		SELECT	'tablockx no mod', 'SQL_locking_hints_tablockx_no_mod'
		UNION ALL
		SELECT	'updlock no mod', 'SQL_locking_hints_updlock_no_mod'
		UNION ALL
		SELECT	'xlock no mod', 'SQL_locking_hints_xlock_no_mod'
		UNION ALL
		SELECT	'holdlock tran level', 'SQL_locking_hints_holdlock'
		UNION ALL
		SELECT	'nolock tran level', 'SQL_locking_hints_nolock'
		UNION ALL
		SELECT	'paglock tran level', 'SQL_locking_hints_paglock'
		UNION ALL
		SELECT	'readcommitted tran level', 'SQL_locking_hints_readcommitted'
		UNION ALL
		SELECT	'readpast tran level', 'SQL_locking_hints_readpast'
		UNION ALL
		SELECT	'readuncommitted tran level', 'SQL_locking_hints_readuncommitted'
		UNION ALL
		SELECT	'repeatableread tran level', 'SQL_locking_hints_repeatableread'
		UNION ALL
		SELECT	'rowlock tran level', 'SQL_locking_hints_rowlock'
		UNION ALL
		SELECT	'serializable tran level', 'SQL_locking_hints_serializable'
		UNION ALL
		SELECT	'tablock tran level', 'SQL_locking_hints_tablock'
		UNION ALL
		SELECT	'tablockx tran level', 'SQL_locking_hints_tablockx'
		UNION ALL
		SELECT	'updlock tran level', 'SQL_locking_hints_updlock'
		UNION ALL
		SELECT	'xlock tran level', 'SQL_locking_hints_xlock'
		UNION ALL
		SELECT 'paglock nolock', 'SQL_locking_hints_paglock_nolock'
		UNION ALL
		SELECT 'readcommitted nolock', 'SQL_locking_hints_readcommitted_nolock'
		UNION ALL
		SELECT 'readpast nolock', 'SQL_locking_hints_readpast_nolock'
		UNION ALL
		SELECT 'readuncommitted nolock', 'SQL_locking_hints_readuncommitted_nolock'
		UNION ALL
		SELECT 'repeatableread nolock', 'SQL_locking_hints_repeatableread_nolock'
		UNION ALL
		SELECT 'rowlock nolock', 'SQL_locking_hints_rowlock_nolock'
		UNION ALL
		SELECT 'serializable nolock', 'SQL_locking_hints_serializable_nolock'
		UNION ALL
		SELECT 'tablock nolock', 'SQL_locking_hints_tablock_nolock'
		UNION ALL
		SELECT 'tablockx nolock', 'SQL_locking_hints_tablockx_nolock'
		UNION ALL
		SELECT 'xlock nolock', 'SQL_locking_hints_xlock_nolock'
		) i
ON		t.TestCase = N'locking hints'

UNION ALL

SELECT	t.TestCaseId,
		i.Issue,
		i.RuleName
FROM	dbo.SQLRAP_SQLCensus_TestCase t (NOLOCK)
JOIN	(
		SELECT	'<>' AS Issue, 'SQL_Not_logic_not_equal_01' AS RuleName
		UNION ALL
		SELECT	'!=', 'SQL_Not_logic_not_equal_02'
		UNION ALL
		SELECT	'!>', 'SQL_Not_logic_not_greater'
		UNION ALL
		SELECT	'!<', 'SQL_Not_logic_not_less'
		UNION ALL
		SELECT	'not between', 'SQL_Not_logic_not_between'
		UNION ALL
		SELECT	'not in', 'SQL_Not_logic_not_in'
		UNION ALL
		SELECT	'not like', 'SQL_Not_logic_not_like'
		UNION ALL
		SELECT	'not exists', 'SQL_Not_logic_not_exists'
		) i
ON		t.TestCase = N'NOT logic'

UNION ALL

SELECT	t.TestCaseId,
		i.Issue,
		i.RuleName
FROM	dbo.SQLRAP_SQLCensus_TestCase t (NOLOCK)
JOIN	(
		SELECT	'=*' AS Issue, 'SQL_old_style_join_syntax_01' AS RuleName
		UNION ALL
		SELECT	'*=', 'SQL_old_style_join_syntax_02'
		) i
ON		t.TestCase = N'old style join'

UNION ALL

SELECT	t.TestCaseId,
		i.Issue,
		i.RuleName
FROM	dbo.SQLRAP_SQLCensus_TestCase t (NOLOCK)
JOIN	(
		SELECT	'Missing WHEREs' AS Issue, 'SQL_missing_where_statement' AS RuleName
		UNION ALL
		SELECT	'goto', 'sql_goto'
		UNION ALL
		SELECT	'xp_cmdshell', 'SQL_xp_cmdshell'
		UNION ALL
		SELECT	'select *', 'sql_select_star'
		UNION ALL
		SELECT	'sp_ naming convention', 'SQL_sp_naming_convention'
		) i
ON		t.TestCase = N'other'

UNION ALL

SELECT	t.TestCaseId,
		i.Issue,
		i.RuleName
FROM	dbo.SQLRAP_SQLCensus_TestCase t (NOLOCK)
JOIN	(
		SELECT 'concat union' AS Issue, 'SQL_query_hints_concat_union' AS RuleName
		UNION ALL
		SELECT 'expand views', 'SQL_query_hints_expand_views'
 		UNION ALL
		SELECT 'force order', 'SQL_query_hints_force_order'
		UNION ALL
		SELECT 'hash group', 'SQL_query_hints_hash_group'
		UNION ALL
		SELECT 'hash join', 'SQL_query_hints_hash_join'
		UNION ALL
		SELECT 'hash union', 'SQL_query_hints_hash_union'
		UNION ALL
		SELECT 'keep plan', 'SQL_query_hints_keep_plan'
		UNION ALL
		SELECT 'keepfixed plan', 'SQL_query_hints_keepfixed_plan'
		UNION ALL
		SELECT 'loop join', 'SQL_query_hints_loop_join'
		UNION ALL
		SELECT 'merge join', 'SQL_query_hints_merge_join'
		UNION ALL
		SELECT 'merge union', 'SQL_query_hints_merge_union'
		UNION ALL
		SELECT 'optimize for', 'SQL_query_hints_optimize_for'
		UNION ALL
		SELECT 'order group', 'SQL_query_hints_order_group'
		UNION ALL
		SELECT 'parameterization forced', 'SQL_query_hints_parameterization_forced'
		UNION ALL
		SELECT 'parameterization simple', 'SQL_query_hints_parameterization_simple'
		UNION ALL
		SELECT 'robust plan', 'SQL_query_hints_robust_plan'
		UNION ALL
		SELECT 'use plan', 'SQL_query_hints_use_plan'
		UNION ALL
		SELECT 'fast', 'SQL_query_hints_fast'
		UNION ALL
		SELECT 'maxdop', 'SQL_query_hints_maxdop'
		UNION ALL
		SELECT 'maxrecursion', 'SQL_query_hints_maxrecursion'
		UNION ALL
		SELECT 'recompile', 'SQL_query_hints_recompile'
		) i
ON		t.TestCase = N'query hints'

UNION ALL

SELECT	t.TestCaseId,
		i.Issue,
		i.RuleName
FROM	dbo.SQLRAP_SQLCensus_TestCase t (NOLOCK)
JOIN	(
		SELECT 'for xml' AS Issue, 'SQL_XML_FOR_XML_EXPLICIT' AS RuleName
		UNION ALL
		SELECT 'openxml', 'SQL_XML_OPENXML'
 		UNION ALL
		SELECT 'sp_xml_removedocument', 'SQL_XML_Prepare_Remove_Document'
		UNION ALL
		SELECT 'single root node', 'SQL_XML_SingleRootNode'
		UNION ALL
		SELECT 'parent axis access', 'SQL_XML_ParentAxisAccess'
		UNION ALL
		SELECT 'intrinsics', 'SQL_XML_Intrinsics'
		UNION ALL
		SELECT 'expanded paths', 'SQL_XML_ExpandedPaths'
		) i
ON		t.TestCase = N'xml'

UNION ALL

SELECT	t.TestCaseId,
		i.Issue,
		i.RuleName
FROM	dbo.SQLRAP_SQLCensus_TestCase t (NOLOCK)
JOIN	(
		SELECT 'Reserved Words - Columns' AS Issue, 'SQL_Reserved_Words_Column_Names' AS RuleName
		UNION ALL
		SELECT 'Reserved Words - Objects', 'SQL_Reserved_Words_Object_Names'
		) i
ON		t.TestCase = N'reserved words'
COMMIT TRAN
GO

USE tempdb

-- SQL Server 2000 branch
IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),2) = '8.'
BEGIN

    EXEC('
    -- create the spSQLRAP_SQLCensus_ExcludedDatabases stored procedure
    CREATE PROCEDURE dbo.spSQLRAP_SQLCensus_ExcludedDatabases
	    (@ExcludedDatabases NTEXT)
    AS

    SET NOCOUNT ON

    DECLARE @idoc INT

    EXEC sp_xml_preparedocument @idoc OUTPUT, @ExcludedDatabases

    -- place the input xml into a temp table (less XML overhead)
	SELECT	d.dbid AS databaseid
	INTO	#SQLRAP_SQLCensus_ExcludedDatabases
	FROM
	(
		SELECT	[db] AS name
		FROM	OPENXML (@idoc, ''/SQLRAP_SQLCensus_Exclusions[1]/Exclude'')
		WITH	([db] sysname)
	) input
	JOIN	master.dbo.sysdatabases d (NOLOCK)
	ON		input.name = d.name
		
    EXEC sp_xml_removedocument @idoc

    --	logically "re-include" databases in the SQLRAP_SQLCensus_ExcludedDatabases table
    --	which are "excluded" in the table and aren''t present in the XML
    UPDATE	db
		    SET	LastUpdated		= GETDATE(),
			    ExcludeDatabase	= 0
    FROM	dbo.SQLRAP_SQLCensus_ExcludedDatabases db
    LEFT OUTER JOIN #SQLRAP_SQLCensus_ExcludedDatabases input (NOLOCK)
    ON		db.databaseid = input.databaseid
    WHERE	input.databaseid IS NULL

    --	logically "exclude" databases in the SQLRAP_SQLCensus_ExcludedDatabases table
    --	which are present in the XML and "included" in the table
    UPDATE	db
		    SET	LastUpdated		= GETDATE(),
			    ExcludeDatabase	= 1
    FROM	dbo.SQLRAP_SQLCensus_ExcludedDatabases db
    JOIN	#SQLRAP_SQLCensus_ExcludedDatabases input (NOLOCK)
    ON		db.databaseid = input.databaseid

    --	add new records to SQLRAP_SQLCensus_ExcludedDatabases table
    INSERT	dbo.SQLRAP_SQLCensus_ExcludedDatabases
	    (
		    databaseid,
		    DateInserted,
		    LastUpdated,
		    ExcludeDatabase
	    )
    SELECT	input.databaseid,
		    GETDATE(),
		    GETDATE(),
		    1
    FROM	#SQLRAP_SQLCensus_ExcludedDatabases input (NOLOCK)
    LEFT OUTER JOIN dbo.SQLRAP_SQLCensus_ExcludedDatabases db (NOLOCK)
    ON		input.databaseid = db.databaseid
    WHERE	db.databaseid IS NULL

    DROP TABLE #SQLRAP_SQLCensus_ExcludedDatabases
    ')

    -- ReservedWords
    BEGIN TRAN
         
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ABSOLUTE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ACTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ADA')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ADD')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ADMIN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AFTER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AGGREGATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ALIAS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ALL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ALLOCATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ALTER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AND')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ANY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ARE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ARRAY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ASC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ASSERTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AUTHORIZATION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AVG')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BACKUP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BEFORE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BEGIN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BETWEEN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BINARY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BIT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BIT_LENGTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BLOB')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BOOLEAN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BOTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BREADTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BREAK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BROWSE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BULK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CALL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CASCADE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CASCADED')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CASE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CAST')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CATALOG')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CHAR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CHAR_LENGTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CHARACTER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CHARACTER_LENGTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CHECK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CHECKPOINT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CLASS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CLOB')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CLOSE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CLUSTERED')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COALESCE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COLLATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COLLATION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COLUMN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COMMIT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COMPLETION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COMPUTE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONNECT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONNECTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONSTRAINT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONSTRAINTS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONSTRUCTOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONTAINS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONTAINSTABLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONTINUE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONVERT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CORRESPONDING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COUNT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CREATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CROSS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CUBE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT_DATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT_PATH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT_ROLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT_TIME')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT_TIMESTAMP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT_USER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURSOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CYCLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DATA')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DATABASE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DAY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DBCC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEALLOCATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DECIMAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DECLARE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEFAULT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEFERRABLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEFERRED')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DELETE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DENY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEPTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEREF')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DESC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DESCRIBE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DESCRIPTOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DESTROY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DESTRUCTOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DETERMINISTIC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DIAGNOSTICS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DICTIONARY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DISCONNECT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DISK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DISTINCT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DISTRIBUTED')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DOMAIN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DOUBLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DROP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DUMMY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DUMP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DYNAMIC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EACH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ELSE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('END')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('END-EXEC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EQUALS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ERRLVL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ESCAPE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EVERY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXCEPT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXCEPTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXEC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXECUTE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXISTS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXIT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXTERNAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXTRACT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FALSE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FETCH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FILE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FILLFACTOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FIRST')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FLOAT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FOREIGN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FORTRAN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FOUND')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FREE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FREETEXT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FREETEXTTABLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FROM')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FULL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FULLTEXTTABLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FUNCTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GENERAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GET')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GLOBAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GO')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GOTO')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GRANT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GROUP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GROUPING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('HAVING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('HOLDLOCK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('HOST')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('HOUR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IDENTITY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IDENTITY_INSERT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IDENTITYCOL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IF')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IGNORE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IMMEDIATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INCLUDE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INDEX')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INDICATOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INITIALIZE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INITIALLY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INNER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INOUT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INPUT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INSENSITIVE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INSERT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INTEGER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INTERSECT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INTERVAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INTO')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ISOLATION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ITERATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('JOIN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ( 'KEY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('KILL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LANGUAGE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LARGE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LAST')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LATERAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LEADING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LEFT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LESS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LEVEL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LIKE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LIMIT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LINENO')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LOAD')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LOCAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LOCALTIME')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LOCALTIMESTAMP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LOCATOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LOWER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MAP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MATCH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MAX')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MIN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MINUTE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MODIFIES')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MODIFY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MODULE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MONTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NAMES')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NATIONAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NATURAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NCHAR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NCLOB')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NEW')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NEXT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NO')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NOCHECK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NONCLUSTERED')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NONE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NOT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NULL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NULLIF')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NUMERIC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OBJECT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OCTET_LENGTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OF')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OFF')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OFFSETS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OLD')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ON')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ONLY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPEN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPENDATASOURCE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPENQUERY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPENROWSET')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPENXML')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPERATION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ORDER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ORDINALITY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OUT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OUTER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OUTPUT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OVER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OVERLAPS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PAD')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PARAMETER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PARAMETERS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PARTIAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PASCAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PATH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PERCENT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PLAN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('POSITION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('POSTFIX')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PRECISION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PREFIX')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PREORDER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PREPARE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PRESERVE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PRIMARY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PRINT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PRIOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PRIVILEGES')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PROC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PROCEDURE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PUBLIC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RAISERROR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('READ')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('READS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('READTEXT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('REAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RECONFIGURE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RECURSIVE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('REF')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('REFERENCES')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('REFERENCING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RELATIVE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('REPLICATION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RESTORE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RESTRICT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RESULT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RETURN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RETURNS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('REVOKE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RIGHT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROLLBACK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROLLUP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROUTINE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROW')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROWCOUNT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROWGUIDCOL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROWS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RULE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SAVE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SAVEPOINT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SCHEMA')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SCOPE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SCROLL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SEARCH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SECOND')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SECTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SELECT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SEQUENCE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SESSION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SESSION_USER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SET')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SETS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SETUSER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SHUTDOWN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SIZE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SMALLINT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SOME')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SPACE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SPECIFIC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SPECIFICTYPE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQLCA')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQLCODE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQLERROR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQLEXCEPTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQLSTATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQLWARNING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('START')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('STATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('STATEMENT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('STATIC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('STATISTICS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('STRUCTURE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SUBSTRING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SUM')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SYSTEM_USER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TABLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TEMPORARY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TERMINATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TEXTSIZE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('THAN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('THEN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TIME')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TIMESTAMP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TIMEZONE_HOUR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TIMEZONE_MINUTE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TO')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TOP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRAILING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRAN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRANSACTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRANSLATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRANSLATION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TREAT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRIGGER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRIM')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRUE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRUNCATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UNDER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UNION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UNIQUE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UNKNOWN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UNNEST')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UPDATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UPDATETEXT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UPPER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('USAGE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('USE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('USER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('USING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('VALUE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('VALUES')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('VARCHAR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('VARIABLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('VARYING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('VIEW')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WAITFOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WHEN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WHENEVER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WHERE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WHILE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WITH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WITHOUT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WORK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WRITE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WRITETEXT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('YEAR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ZONE')
         
    COMMIT TRAN
END

ELSE IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),2) = '9.'
BEGIN

    EXEC('
    -- create the spSQLRAP_SQLCensus_ExcludedDatabases stored procedure
    CREATE PROCEDURE dbo.spSQLRAP_SQLCensus_ExcludedDatabases
	    (@ExcludedDatabases XML)
    AS

    SET NOCOUNT ON

    -- place the input xml into a temp table (less XML overhead)
    SELECT	d.database_id AS databaseid
    INTO	#SQLRAP_SQLCensus_ExcludedDatabases    
    FROM
    (
		SELECT	ref.value(''@db'',''sysname'') AS name
		FROM	@ExcludedDatabases.nodes(''/SQLRAP_SQLCensus_Exclusions[1]/Exclude'') node(ref)  
	) input
	JOIN	master.sys.databases d
	ON		input.name = d.name
	
    --	logically "re-include" databases in the SQLRAP_SQLCensus_ExcludedDatabases table
    --	which are "excluded" in the table and aren''t present in the XML
    UPDATE	db
		    SET	LastUpdated		= GETDATE(),
			    ExcludeDatabase	= 0
    FROM	dbo.SQLRAP_SQLCensus_ExcludedDatabases db
    LEFT OUTER JOIN #SQLRAP_SQLCensus_ExcludedDatabases input (NOLOCK)
    ON		db.databaseid = input.databaseid
    WHERE	input.databaseid IS NULL

    --	logically "exclude" databases in the SQLRAP_SQLCensus_ExcludedDatabases table
    --	which are present in the XML and "included" in the table
    UPDATE	db
		    SET	LastUpdated		= GETDATE(),
			    ExcludeDatabase	= 1
    FROM	dbo.SQLRAP_SQLCensus_ExcludedDatabases db
    JOIN	#SQLRAP_SQLCensus_ExcludedDatabases input (NOLOCK)
    ON		db.databaseid = input.databaseid

    --	add new records to SQLRAP_SQLCensus_ExcludedDatabases table
    INSERT	dbo.SQLRAP_SQLCensus_ExcludedDatabases
	    (
		    databaseid,
		    DateInserted,
		    LastUpdated,
		    ExcludeDatabase
	    )
    SELECT	input.databaseid,
		    GETDATE(),
		    GETDATE(),
		    1
    FROM	#SQLRAP_SQLCensus_ExcludedDatabases input (NOLOCK)
    LEFT OUTER JOIN dbo.SQLRAP_SQLCensus_ExcludedDatabases db
    ON		input.databaseid = db.databaseid
    WHERE	db.databaseid IS NULL

    DROP TABLE #SQLRAP_SQLCensus_ExcludedDatabases
    ')

    -- ReservedWords
    BEGIN TRAN
     
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ABSOLUTE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ACTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ADA')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ADD')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ADMIN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AFTER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AGGREGATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ALIAS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ALL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ALLOCATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ALTER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AND')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ANY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ARE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ARRAY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ASC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ASSERTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AUTHORIZATION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AVG')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BACKUP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BEFORE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BEGIN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BETWEEN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BINARY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BIT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BIT_LENGTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BLOB')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BOOLEAN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BOTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BREADTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BREAK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BROWSE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BULK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CALL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CASCADE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CASCADED')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CASE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CAST')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CATALOG')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CHAR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CHAR_LENGTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CHARACTER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CHARACTER_LENGTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CHECK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CHECKPOINT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CLASS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CLOB')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CLOSE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CLUSTERED')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COALESCE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COLLATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COLLATION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COLUMN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COMMIT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COMPLETION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COMPUTE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONNECT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONNECTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONSTRAINT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONSTRAINTS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONSTRUCTOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONTAINS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONTAINSTABLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONTINUE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONVERT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CORRESPONDING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COUNT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CREATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CROSS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CUBE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT_DATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT_PATH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT_ROLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT_TIME')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT_TIMESTAMP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT_USER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURSOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CYCLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DATA')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DATABASE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DAY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DBCC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEALLOCATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DECIMAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DECLARE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEFAULT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEFERRABLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEFERRED')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DELETE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DENY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEPTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEREF')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DESC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DESCRIBE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DESCRIPTOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DESTROY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DESTRUCTOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DETERMINISTIC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DIAGNOSTICS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DICTIONARY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DISCONNECT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DISK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DISTINCT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DISTRIBUTED')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DOMAIN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DOUBLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DROP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DUMMY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DUMP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DYNAMIC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EACH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ELSE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('END')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('END-EXEC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EQUALS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ERRLVL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ESCAPE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EVERY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXCEPT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXCEPTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXEC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXECUTE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXISTS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXIT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXTERNAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXTRACT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FALSE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FETCH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FILE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FILLFACTOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FIRST')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FLOAT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FOREIGN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FORTRAN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FOUND')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FREE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FREETEXT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FREETEXTTABLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FROM')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FULL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FULLTEXTTABLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FUNCTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GENERAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GET')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GLOBAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GO')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GOTO')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GRANT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GROUP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GROUPING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('HAVING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('HOLDLOCK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('HOST')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('HOUR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IDENTITY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IDENTITY_INSERT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IDENTITYCOL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IF')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IGNORE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IMMEDIATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INCLUDE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INDEX')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INDICATOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INITIALIZE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INITIALLY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INNER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INOUT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INPUT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INSENSITIVE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INSERT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INTEGER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INTERSECT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INTERVAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INTO')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ISOLATION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ITERATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('JOIN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ( 'KEY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('KILL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LANGUAGE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LARGE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LAST')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LATERAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LEADING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LEFT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LESS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LEVEL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LIKE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LIMIT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LINENO')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LOAD')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LOCAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LOCALTIME')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LOCALTIMESTAMP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LOCATOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LOWER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MAP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MATCH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MAX')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MIN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MINUTE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MODIFIES')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MODIFY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MODULE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MONTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NAMES')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NATIONAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NATURAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NCHAR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NCLOB')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NEW')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NEXT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NO')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NOCHECK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NONCLUSTERED')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NONE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NOT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NULL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NULLIF')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NUMERIC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OBJECT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OCTET_LENGTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OF')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OFF')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OFFSETS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OLD')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ON')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ONLY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPEN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPENDATASOURCE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPENQUERY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPENROWSET')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPENXML')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPERATION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ORDER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ORDINALITY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OUT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OUTER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OUTPUT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OVER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OVERLAPS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PAD')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PARAMETER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PARAMETERS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PARTIAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PASCAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PATH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PERCENT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PLAN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('POSITION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('POSTFIX')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PRECISION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PREFIX')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PREORDER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PREPARE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PRESERVE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PRIMARY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PRINT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PRIOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PRIVILEGES')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PROC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PROCEDURE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PUBLIC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RAISERROR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('READ')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('READS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('READTEXT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('REAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RECONFIGURE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RECURSIVE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('REF')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('REFERENCES')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('REFERENCING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RELATIVE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('REPLICATION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RESTORE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RESTRICT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RESULT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RETURN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RETURNS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('REVOKE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RIGHT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROLLBACK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROLLUP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROUTINE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROW')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROWCOUNT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROWGUIDCOL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROWS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RULE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SAVE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SAVEPOINT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SCHEMA')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SCOPE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SCROLL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SEARCH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SECOND')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SECTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SELECT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SEQUENCE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SESSION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SESSION_USER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SET')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SETS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SETUSER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SHUTDOWN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SIZE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SMALLINT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SOME')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SPACE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SPECIFIC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SPECIFICTYPE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQLCA')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQLCODE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQLERROR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQLEXCEPTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQLSTATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQLWARNING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('START')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('STATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('STATEMENT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('STATIC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('STATISTICS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('STRUCTURE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SUBSTRING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SUM')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SYSTEM_USER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TABLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TEMPORARY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TERMINATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TEXTSIZE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('THAN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('THEN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TIME')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TIMESTAMP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TIMEZONE_HOUR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TIMEZONE_MINUTE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TO')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TOP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRAILING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRAN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRANSACTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRANSLATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRANSLATION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TREAT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRIGGER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRIM')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRUE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRUNCATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UNDER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UNION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UNIQUE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UNKNOWN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UNNEST')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UPDATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UPDATETEXT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UPPER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('USAGE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('USE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('USER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('USING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('VALUE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('VALUES')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('VARCHAR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('VARIABLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('VARYING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('VIEW')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WAITFOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WHEN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WHENEVER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WHERE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WHILE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WITH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WITHOUT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WORK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WRITE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WRITETEXT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('YEAR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ZONE')

    COMMIT TRAN
END
ELSE IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),2) = '10'
BEGIN

    EXEC('
    -- create the spSQLRAP_SQLCensus_ExcludedDatabases stored procedure
    CREATE PROCEDURE dbo.spSQLRAP_SQLCensus_ExcludedDatabases
	    (@ExcludedDatabases XML)
    AS

    SET NOCOUNT ON

    -- place the input xml into a temp table (less XML overhead)
    SELECT	d.database_id AS databaseid
    INTO	#SQLRAP_SQLCensus_ExcludedDatabases    
    FROM
    (
		SELECT	ref.value(''@db'',''sysname'') AS name
		FROM	@ExcludedDatabases.nodes(''/SQLRAP_SQLCensus_Exclusions[1]/Exclude'') node(ref)  
	) input
	JOIN	master.sys.databases d
	ON		input.name = d.name

    --	logically "re-include" databases in the SQLRAP_SQLCensus_ExcludedDatabases table
    --	which are "excluded" in the table and aren''t present in the XML
    UPDATE	db
		    SET	LastUpdated		= GETDATE(),
			    ExcludeDatabase	= 0
    FROM	dbo.SQLRAP_SQLCensus_ExcludedDatabases db
    LEFT OUTER JOIN #SQLRAP_SQLCensus_ExcludedDatabases input (NOLOCK)
    ON		db.databaseid = input.databaseid
    WHERE	input.databaseid IS NULL

    --	logically "exclude" databases in the SQLRAP_SQLCensus_ExcludedDatabases table
    --	which are present in the XML and "included" in the table
    UPDATE	db
		    SET	LastUpdated		= GETDATE(),
			    ExcludeDatabase	= 1
    FROM	dbo.SQLRAP_SQLCensus_ExcludedDatabases db
    JOIN	#SQLRAP_SQLCensus_ExcludedDatabases input
    ON		db.databaseid = input.databaseid

    --	add new records to SQLRAP_SQLCensus_ExcludedDatabases table
    INSERT	dbo.SQLRAP_SQLCensus_ExcludedDatabases
	    (
		    databaseid,
		    DateInserted,
		    LastUpdated,
		    ExcludeDatabase
	    )
    SELECT	input.databaseid,
		    GETDATE(),
		    GETDATE(),
		    1
    FROM	#SQLRAP_SQLCensus_ExcludedDatabases input
    LEFT OUTER JOIN dbo.SQLRAP_SQLCensus_ExcludedDatabases db (NOLOCK)
    ON		input.databaseid = db.databaseid
    WHERE	db.databaseid IS NULL

    DROP TABLE #SQLRAP_SQLCensus_ExcludedDatabases
    ')

    -- ReservedWords
    BEGIN TRAN
        
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ABSOLUTE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ACTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ADA')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ADD')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ADMIN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AFTER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AGGREGATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ALIAS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ALL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ALLOCATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ALTER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AND')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ANY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ARE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ARRAY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ASC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ASSERTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AUTHORIZATION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('AVG')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BACKUP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BEFORE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BEGIN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BETWEEN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BINARY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BIT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BIT_LENGTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BLOB')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BOOLEAN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BOTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BREADTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BREAK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BROWSE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BULK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('BY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CALL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CASCADE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CASCADED')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CASE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CAST')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CATALOG')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CHAR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CHAR_LENGTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CHARACTER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CHARACTER_LENGTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CHECK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CHECKPOINT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CLASS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CLOB')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CLOSE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CLUSTERED')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COALESCE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COLLATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COLLATION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COLUMN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COMMIT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COMPLETION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COMPUTE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONNECT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONNECTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONSTRAINT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONSTRAINTS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONSTRUCTOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONTAINS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONTAINSTABLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONTINUE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CONVERT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CORRESPONDING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('COUNT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CREATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CROSS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CUBE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT_DATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT_PATH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT_ROLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT_TIME')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT_TIMESTAMP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURRENT_USER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CURSOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('CYCLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DATA')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DATABASE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DAY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DBCC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEALLOCATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DECIMAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DECLARE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEFAULT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEFERRABLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEFERRED')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DELETE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DENY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEPTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DEREF')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DESC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DESCRIBE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DESCRIPTOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DESTROY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DESTRUCTOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DETERMINISTIC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DIAGNOSTICS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DICTIONARY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DISCONNECT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DISK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DISTINCT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DISTRIBUTED')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DOMAIN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DOUBLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DROP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DUMMY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DUMP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('DYNAMIC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EACH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ELSE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('END')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('END-EXEC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EQUALS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ERRLVL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ESCAPE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EVERY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXCEPT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXCEPTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXEC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXECUTE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXISTS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXIT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXTERNAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('EXTRACT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FALSE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FETCH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FILE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FILLFACTOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FIRST')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FLOAT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FOREIGN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FORTRAN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FOUND')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FREE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FREETEXT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FREETEXTTABLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FROM')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FULL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FULLTEXTTABLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('FUNCTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GENERAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GET')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GLOBAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GO')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GOTO')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GRANT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GROUP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('GROUPING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('HAVING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('HOLDLOCK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('HOST')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('HOUR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IDENTITY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IDENTITY_INSERT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IDENTITYCOL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IF')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IGNORE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IMMEDIATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INCLUDE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INDEX')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INDICATOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INITIALIZE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INITIALLY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INNER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INOUT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INPUT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INSENSITIVE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INSERT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INTEGER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INTERSECT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INTERVAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('INTO')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('IS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ISOLATION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ITERATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('JOIN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ( 'KEY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('KILL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LANGUAGE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LARGE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LAST')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LATERAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LEADING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LEFT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LESS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LEVEL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LIKE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LIMIT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LINENO')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LOAD')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LOCAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LOCALTIME')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LOCALTIMESTAMP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LOCATOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('LOWER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MAP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MATCH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MAX')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MIN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MINUTE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MODIFIES')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MODIFY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MODULE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('MONTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NAMES')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NATIONAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NATURAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NCHAR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NCLOB')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NEW')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NEXT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NO')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NOCHECK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NONCLUSTERED')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NONE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NOT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NULL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NULLIF')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('NUMERIC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OBJECT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OCTET_LENGTH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OF')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OFF')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OFFSETS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OLD')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ON')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ONLY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPEN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPENDATASOURCE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPENQUERY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPENROWSET')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPENXML')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPERATION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OPTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ORDER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ORDINALITY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OUT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OUTER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OUTPUT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OVER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('OVERLAPS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PAD')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PARAMETER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PARAMETERS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PARTIAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PASCAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PATH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PERCENT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PLAN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('POSITION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('POSTFIX')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PRECISION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PREFIX')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PREORDER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PREPARE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PRESERVE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PRIMARY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PRINT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PRIOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PRIVILEGES')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PROC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PROCEDURE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('PUBLIC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RAISERROR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('READ')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('READS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('READTEXT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('REAL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RECONFIGURE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RECURSIVE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('REF')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('REFERENCES')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('REFERENCING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RELATIVE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('REPLICATION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RESTORE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RESTRICT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RESULT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RETURN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RETURNS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('REVOKE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RIGHT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROLLBACK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROLLUP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROUTINE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROW')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROWCOUNT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROWGUIDCOL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ROWS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('RULE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SAVE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SAVEPOINT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SCHEMA')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SCOPE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SCROLL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SEARCH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SECOND')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SECTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SELECT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SEQUENCE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SESSION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SESSION_USER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SET')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SETS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SETUSER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SHUTDOWN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SIZE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SMALLINT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SOME')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SPACE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SPECIFIC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SPECIFICTYPE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQL')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQLCA')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQLCODE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQLERROR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQLEXCEPTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQLSTATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SQLWARNING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('START')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('STATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('STATEMENT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('STATIC')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('STATISTICS')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('STRUCTURE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SUBSTRING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SUM')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('SYSTEM_USER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TABLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TEMPORARY')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TERMINATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TEXTSIZE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('THAN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('THEN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TIME')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TIMESTAMP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TIMEZONE_HOUR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TIMEZONE_MINUTE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TO')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TOP')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRAILING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRAN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRANSACTION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRANSLATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRANSLATION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TREAT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRIGGER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRIM')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRUE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('TRUNCATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UNDER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UNION')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UNIQUE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UNKNOWN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UNNEST')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UPDATE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UPDATETEXT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('UPPER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('USAGE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('USE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('USER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('USING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('VALUE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('VALUES')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('VARCHAR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('VARIABLE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('VARYING')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('VIEW')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WAITFOR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WHEN')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WHENEVER')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WHERE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WHILE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WITH')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WITHOUT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WORK')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WRITE')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('WRITETEXT')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('YEAR')
    INSERT dbo.SQLRAP_SQLCensus_ReservedWords (ReservedWord) VALUES ('ZONE')

    COMMIT TRAN
END

GO






