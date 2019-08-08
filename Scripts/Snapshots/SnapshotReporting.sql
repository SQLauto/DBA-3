SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[usp_ReportingSynoSnap]
    @sourceDbName      NVARCHAR( MAX )
    ,@reportDbName     NVARCHAR( MAX )
    ,@scriptOnly       BIT = 0
AS
BEGIN
 
    DECLARE
        @sqlStmt        NVARCHAR( MAX )
        ,@dtStamp       NVARCHAR( MAX )
        ,@prevRptSsName NVARCHAR( MAX )
        
    SET @dtStamp = REPLACE( REPLACE( REPLACE( CONVERT( NVARCHAR, GETDATE(), 120 ), '-', '' ), ' ', '_' ), ':', '' )
 

    SELECT @prevRptSsName = MAX( ssdb.name )
        FROM sys.databases ssdb JOIN sys.databases db ON db.database_id = ssdb.source_database_id
        WHERE db.name = @sourceDbName AND ssdb.name LIKE @sourceDbName + '_Rpt[_]%[_]ss'
        
    SET @sqlStmt = 
'
        DECLARE srcSchemaCursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT DISTINCT
                    TABLE_SCHEMA
                FROM   ' + @sourceDbName + '.INFORMATION_SCHEMA.TABLES
                
        DECLARE srcDbFileCursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT  f.name
                    ,f.physical_name
                FROM   sys.master_files f
                    JOIN      sys.databases d
                        ON   d.database_id = f.database_id
                WHERE d.name = ''' + @sourceDbName + '''
                    AND       f.type = 0
                
        DECLARE rptSynonymCursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT  sc_name = sc.name
                    ,syn_name = syn.name
                FROM   ' + @reportDbName + '.sys.schemas sc
                    JOIN      ' + @reportDbName + '.sys.synonyms syn
                        ON   syn.schema_id = sc.schema_id
                    
        DECLARE srcTableCursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT  TABLE_SCHEMA
                    ,TABLE_NAME
                FROM   ' + @sourceDbName + '.INFORMATION_SCHEMA.TABLES
                
        DECLARE
            @schema_name                NVARCHAR( MAX )
            ,@table_name          NVARCHAR( MAX )
            ,@syn_name                 NVARCHAR( MAX )
            ,@file_name                  NVARCHAR( MAX )
            ,@file_physical_name   NVARCHAR( MAX )
            ,@tmpSqlStmt          NVARCHAR( MAX )
            ,@synSqlStmt            NVARCHAR( MAX )
            ,@isFirstFile          BIT
 

        SET @tmpSqlStmt = 
''
CREATE DATABASE [' + @sourceDbName + '_Rpt_' + @dtStamp + '_ss] ON''
 

        SET @isFirstFile = 1
        OPEN srcDbFileCursor
        GOTO srcDbFileCursor_fetchFirst
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @tmpSqlStmt = @tmpSqlStmt + CASE WHEN @isFirstFile = 0 THEN '','' ELSE '''' END +
''
(NAME = ['' + @file_name + ''], FILENAME = '''''' + @file_physical_name + ''.Rpt_' + @dtstamp + '_ss'''')''
            SET @isFirstFile = 0
        
srcDbFileCursor_fetchFirst:
            FETCH NEXT FROM srcDbFileCursor INTO
                @file_name
                ,@file_physical_name
        END
        
        CLOSE srcDbFileCursor
        DEALLOCATE srcDbFileCursor
        
        SET @tmpSqlStmt = @tmpSqlStmt +
''
AS SNAPSHOT OF ' + @sourceDbName + '''
 

        SET @synSqlStmt = 
''
EXEC sys.sp_executesql N'''''' + REPLACE( @tmpSqlStmt, '''''''', '''''''''''' ) + ''''''
USE ' + @reportDbName + '''
            
        OPEN srcSchemaCursor
        GOTO srcSchemaCursor_fetchFirst
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF NOT EXISTS (SELECT * FROM ' + @reportDbName + '.sys.schemas WHERE name = @schema_name)
                SET @synSqlStmt = @synSqlStmt +
''
    EXEC sys.sp_executesql N''''CREATE SCHEMA ['' + @schema_name + ''] AUTHORIZATION [dbo]''''''
 

srcSchemaCursor_fetchFirst:
            FETCH NEXT FROM srcSchemaCursor INTO
                @schema_name
        END
        
        CLOSE srcSchemaCursor
        DEALLOCATE srcSchemaCursor
        
        SET @synSqlStmt = @synSqlStmt +
''
BEGIN TRANSACTION''
 

        OPEN rptSynonymCursor
        GOTO rptSynonymCursor_firstFetch
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @synSqlStmt = @synSqlStmt +
''
    DROP SYNONYM ['' + @schema_name + ''].['' + @syn_name + '']''
        
rptSynonymCursor_firstFetch:
            FETCH NEXT FROM rptSynonymCursor INTO
                @schema_name
                ,@syn_name
        END
        
        CLOSE rptSynonymCursor
        DEALLOCATE rptSynonymCursor
                
        OPEN srcTableCursor
        GOTO srcTableCursor_firstFetch
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @synSqlStmt = @synSqlStmt +
''
    CREATE SYNONYM ['' + @schema_name + ''].['' + @table_name + ''] FOR [' + @sourceDbName + '_Rpt_' + @dtStamp + '_ss].['' + @schema_name + ''].['' + @table_name + '']''
        
srcTableCursor_firstFetch:
            FETCH NEXT FROM srcTableCursor INTO
                @schema_name
                ,@table_name
        END
        
        CLOSE srcTableCursor
        DEALLOCATE srcTableCursor
        
        SET @synSqlStmt = @synSqlStmt +
''
COMMIT TRANSACTION''
'
 

    IF @prevRptSsName IS NOT NULL
        SET @sqlStmt = @sqlStmt +
'
        SET @synSqlStmt = @synSqlStmt +
''
 

DROP DATABASE [' + @prevRptSsName + ']''
'
 

    IF @scriptOnly = 1
        SET @sqlStmt = @sqlStmt +
'
        SELECT @synSqlStmt
'
    ELSE
        SET @sqlStmt = @sqlStmt +
'
        EXEC sys.sp_executesql @synSqlStmt
'
    --select @sqlStmt
    EXEC sys.sp_executesql @sqlStmt
 

END
