--Signature="19B2480A7F257841" 

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    Display index-oriented index data                                                                 ****/
--/****                                                                                                      ****/
--/****    Created 2010.Aug.06 (wardp)                                                                       ****/
--/****    Updated 2010.Sep.09 (wardp) - bug 468323                                                          ****/
--/****    Updated 2010.Oct.01 (wardp) - bug 468923                                                          ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright (c) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

set nocount on

declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));

 if  '10' = (select substring(@version, 1, 2)) -- CR 375891
     begin
     exec('
        DECLARE @dbid int;
        SET     @dbid = DB_ID()

        SELECT DISTINCT serverproperty(''machinename'')                               AS ''Server Name'',                                           
                isnull(serverproperty(''instancename''),serverproperty(''machinename'')) AS ''Instance Name'',  
                db_name()                                                            AS ''Database Name'',
                e.name                                                               AS ''Owner Name'',   
                OBJECT_NAME(a.object_id)                                             AS ''Table Name'',
                b.name                                                               AS ''Index Name'',
                p.partition_number                                                   AS ''Partition Number'',
                sum(max_length)                                                      AS ''Index Row Length'',
                indexproperty(a.object_id, b.name, ''IndexFillFactor'')              AS ''Index Fillfactor'',
                indexproperty(a.object_id, b.name, ''IsHypothetical'')               AS ''Hypothetical Index'',
                ISNULL(CAST(s.avg_fragmentation_in_percent AS DECIMAL(10,2)),0.0)    AS ''Percent Page Fragmentation'',
                ISNULL(CAST(s.avg_fragment_size_in_pages AS DECIMAL(10,2)),0.0)      AS ''Average Fragment Size In Pages'',
                ISNULL(INDEXPROPERTY(a.object_id, b.name,''IndexDepth''),0)          AS ''Index Depth'',
                INDEXPROPERTY(a.object_id, b.name, ''IsStatistics'')                 AS ''Is Statistics'',
                ISNULL(s.page_count,0)                                               AS ''Page Count'',
                COALESCE(fg1.name,fg2.name,N'''')                                    AS ''File Group Name'',
                ISNULL(ps.name,N'''')                                                AS ''Partition Scheme Name'',
                ISNULL(pf.name,N'''')                                                AS ''Partition Function Name'',
                CASE align.ReportOrder
                    WHEN 1 THEN N''Misaligned Partition Range Values''
                    WHEN 2 THEN N''Misaligned Partition Parameters''
                    WHEN 3 THEN N''Misaligned Partition Functions''
                    ELSE N''''
                END                                                                  AS ''Partition Message''
            FROM    sys.objects a (NOLOCK)
            JOIN    sys.indexes b (NOLOCK) 
            ON      b.object_id             = a.object_id
            AND     a.is_ms_shipped         = 0
            AND     a.object_id NOT IN
                    (
                    SELECT  major_id
                    FROM    sys.extended_properties (NOLOCK)
                    WHERE   name            = N''microsoft_database_tools_support''
                    )
            JOIN sys.index_columns c (NOLOCK)
            ON      c.object_id             = b.object_id
            AND     c.index_id              = b.index_id
            AND     c.is_included_column    = 0
            JOIN    sys.columns d (NOLOCK)
            ON      d.object_id             = c.object_id
            AND     d.column_id             = c.column_id
            JOIN    sys.schemas e (NOLOCK)
            ON      e.schema_id             = a.schema_id
            LEFT OUTER JOIN
                    sys.dm_db_index_physical_stats(@dbid,null,null,null,''LIMITED'') s
            ON      b.object_id             = s.object_id
            AND     b.index_id              = s.index_id
            LEFT OUTER JOIN
                    sys.partitions p (NOLOCK)
            ON      p.object_id             = b.object_id
            AND     p.index_id              = b.index_id
            AND     p.partition_number      = s.partition_number
            LEFT OUTER JOIN
                    sys.data_spaces ds (NOLOCK)
            ON      b.data_space_id         = ds.data_space_id
            LEFT OUTER JOIN
                    sys.destination_data_spaces dds (NOLOCK)
            ON      ds.data_space_id        = dds.partition_scheme_id
            AND     p.partition_number      = dds.destination_id
            LEFT OUTER JOIN
                    sys.partition_schemes ps (NOLOCK)
            ON      dds.partition_scheme_id = ps.data_space_id
            LEFT OUTER JOIN
                    sys.partition_functions pf (NOLOCK)
            ON      ps.function_id          = pf.function_id
            LEFT OUTER JOIN
                    sys.database_files fg1 (NOLOCK)
            ON      b.data_space_id         = fg1.data_space_id
            LEFT OUTER JOIN
                    sys.database_files fg2 (NOLOCK)
            ON      dds.data_space_id       = fg2.data_space_id
            LEFT OUTER JOIN
            (
                SELECT  lfunction_id,
                        rfunction_id,
                        MIN(ReportOrder) AS ReportOrder
                FROM
                (
                -- mismatched partition range values
                    SELECT
                        fnleft.function_id  AS lfunction_id,
                        fnright.function_id AS rfunction_id,
                        3                   AS ReportOrder
                    FROM    sys.partition_range_values fnleft (NOLOCK)
                    FULL OUTER JOIN
                            sys.partition_range_values fnright (NOLOCK)
                    ON      fnleft.boundary_id  = fnright.boundary_id
                    AND     fnleft.parameter_id <> fnright.parameter_id
                    AND     fnleft.value        <> fnright.value
                    WHERE   fnleft.function_id  <> fnright.function_id

                    UNION ALL

                    -- mismatched partition parameters
                    SELECT
                        fnleft.function_id,
                        fnright.function_id,
                        2   AS ReportOrder
                    FROM    sys.partition_parameters fnleft (NOLOCK)
                    FULL OUTER JOIN
                            sys.partition_parameters fnright (NOLOCK)
                    ON      fnleft.parameter_id     = fnright.parameter_id
                    AND     fnleft.collation_name   <> fnright.collation_name
                    AND     fnleft.max_length       <> fnright.max_length
                    AND     fnleft.precision        <> fnright.precision
                    AND     fnleft.scale            <> fnright.scale
                    AND     fnleft.system_type_id   <> fnright.system_type_id  -- present in 2K8, not in 2K5
                    AND     fnleft.user_type_id     <> fnright.user_type_id  -- present in 2K8, not in 2K5
                    WHERE   fnleft.function_id      <> fnright.function_id

                    UNION ALL

                    -- mismatched partition functions
                    SELECT
                        fnleft.function_id,
                        fnright.function_id,
                        1   AS ReportOrder
                    FROM    sys.partition_functions fnleft (NOLOCK)
                    FULL OUTER JOIN
                            sys.partition_functions fnright (NOLOCK)
                    ON      fnleft.type                     <> fnright.type
                    AND     fnleft.type_desc                <> fnright.type_desc
                    AND     fnleft.fanout                   <> fnright.fanout
                    AND     fnleft.boundary_value_on_right  <> fnright.boundary_value_on_right
                    WHERE   fnleft.function_id              <> fnright.function_id
                ) a
                GROUP BY lfunction_id, rfunction_id
            ) align
            ON      align.lfunction_id  = pf.function_id

            WHERE   a.type = N''U''
            OR      a.type = N''V''

            GROUP BY
                    e.name, 
                    a.object_id, 
                    b.name, 
                    p.partition_number,
                    s.avg_fragmentation_in_percent,
                    s.avg_fragment_size_in_pages,
                    s.avg_fragmentation_in_percent,
                    s.page_count,
                    align.ReportOrder,
                    fg1.name,
                    fg2.name,
                    ps.name,
                    pf.name

--          order by ''Index Row Length'' desc, e.name, a.name, b.name
        ')
     end
 else -- CR 375891
 if  9 = (select substring(@version, 1, 1))
     begin
     exec ('
        DECLARE @dbid int;
        SET     @dbid = DB_ID()

        SELECT DISTINCT serverproperty(''machinename'')                               AS ''Server Name'',                                           
                isnull(serverproperty(''instancename''),serverproperty(''machinename'')) AS ''Instance Name'',  
                db_name()                                                            AS ''Database Name'',
                e.name                                                               AS ''Owner Name'',   
                OBJECT_NAME(a.object_id)                                             AS ''Table Name'',
                b.name                                                               AS ''Index Name'',
                p.partition_number                                                   AS ''Partition Number'',
                sum(max_length)                                                      AS ''Index Row Length'',
                indexproperty(a.object_id, b.name, ''IndexFillFactor'')              AS ''Index Fillfactor'',
                indexproperty(a.object_id, b.name, ''IsHypothetical'')               AS ''Hypothetical Index'',
                ISNULL(CAST(s.avg_fragmentation_in_percent AS DECIMAL(10,2)),0.0)    AS ''Percent Page Fragmentation'',
                ISNULL(CAST(s.avg_fragment_size_in_pages AS DECIMAL(10,2)),0.0)      AS ''Average Fragment Size In Pages'',
                ISNULL(INDEXPROPERTY(a.object_id, b.name,''IndexDepth''),0)          AS ''Index Depth'',
                INDEXPROPERTY(a.object_id, b.name, ''IsStatistics'')                 AS ''Is Statistics'',
                ISNULL(s.page_count,0)                                               AS ''Page Count'',
                COALESCE(fg1.name,fg2.name,N'''')                                    AS ''File Group Name'',
                ISNULL(ps.name,N'''')                                                AS ''Partition Scheme Name'',
                ISNULL(pf.name,N'''')                                                AS ''Partition Function Name'',
                CASE align.ReportOrder
                    WHEN 1 THEN N''Misaligned Partition Range Values''
                    WHEN 2 THEN N''Misaligned Partition Parameters''
                    WHEN 3 THEN N''Misaligned Partition Functions''
                    ELSE N''''
                END                                                                  AS ''Partition Message''
            FROM    sys.objects a (NOLOCK)
            JOIN    sys.indexes b (NOLOCK) 
            ON      b.object_id             = a.object_id
            AND     a.is_ms_shipped         = 0
            AND     a.object_id NOT IN
                    (
                    SELECT  major_id
                    FROM    sys.extended_properties (NOLOCK)
                    WHERE   name            = N''microsoft_database_tools_support''
                    )
            JOIN sys.index_columns c (NOLOCK)
            ON      c.object_id             = b.object_id
            AND     c.index_id              = b.index_id
            AND     c.is_included_column    = 0
            JOIN    sys.columns d (NOLOCK)
            ON      d.object_id             = c.object_id
            AND     d.column_id             = c.column_id
            JOIN    sys.schemas e (NOLOCK)
            ON      e.schema_id             = a.schema_id
            LEFT OUTER JOIN
                    sys.dm_db_index_physical_stats(@dbid,null,null,null,''LIMITED'') s
            ON      b.object_id             = s.object_id
            AND     b.index_id              = s.index_id
            LEFT OUTER JOIN
                    sys.partitions p (NOLOCK)
            ON      p.object_id             = b.object_id
            AND     p.index_id              = b.index_id
            AND     p.partition_number      = s.partition_number
            LEFT OUTER JOIN
                    sys.data_spaces ds (NOLOCK)
            ON      b.data_space_id         = ds.data_space_id
            LEFT OUTER JOIN
                    sys.destination_data_spaces dds (NOLOCK)
            ON      ds.data_space_id        = dds.partition_scheme_id
            AND     p.partition_number      = dds.destination_id
            LEFT OUTER JOIN
                    sys.partition_schemes ps (NOLOCK)
            ON      dds.partition_scheme_id = ps.data_space_id
            LEFT OUTER JOIN
                    sys.partition_functions pf (NOLOCK)
            ON      ps.function_id          = pf.function_id
            LEFT OUTER JOIN
                    sys.database_files fg1 (NOLOCK)
            ON      b.data_space_id         = fg1.data_space_id
            LEFT OUTER JOIN
                    sys.database_files fg2 (NOLOCK)
            ON      dds.data_space_id       = fg2.data_space_id
            LEFT OUTER JOIN
            (
                SELECT  lfunction_id,
                        rfunction_id,
                        MIN(ReportOrder) AS ReportOrder
                FROM
                (
                -- mismatched partition range values
                    SELECT
                        fnleft.function_id  AS lfunction_id,
                        fnright.function_id AS rfunction_id,
                        3                   AS ReportOrder
                    FROM    sys.partition_range_values fnleft (NOLOCK)
                    FULL OUTER JOIN
                            sys.partition_range_values fnright (NOLOCK)
                    ON      fnleft.boundary_id  = fnright.boundary_id
                    AND     fnleft.parameter_id <> fnright.parameter_id
                    AND     fnleft.value        <> fnright.value
                    WHERE   fnleft.function_id  <> fnright.function_id

                    UNION ALL

                    -- mismatched partition parameters
                    SELECT
                        fnleft.function_id,
                        fnright.function_id,
                        2   AS ReportOrder
                    FROM    sys.partition_parameters fnleft (NOLOCK)
                    FULL OUTER JOIN
                            sys.partition_parameters fnright (NOLOCK)
                    ON      fnleft.parameter_id     = fnright.parameter_id
                    AND     fnleft.collation_name   <> fnright.collation_name
                    AND     fnleft.max_length       <> fnright.max_length
                    AND     fnleft.precision        <> fnright.precision
                    AND     fnleft.scale            <> fnright.scale
--                    AND     fnleft.system_type_id   <> fnright.system_type_id  -- present in 2K8, not in 2K5
--                    AND     fnleft.user_type_id     <> fnright.user_type_id  -- present in 2K8, not in 2K5
                    WHERE   fnleft.function_id      <> fnright.function_id

                    UNION ALL

                    -- mismatched partition functions
                    SELECT
                        fnleft.function_id,
                        fnright.function_id,
                        1   AS ReportOrder
                    FROM    sys.partition_functions fnleft (NOLOCK)
                    FULL OUTER JOIN
                            sys.partition_functions fnright (NOLOCK)
                    ON      fnleft.type                     <> fnright.type
                    AND     fnleft.type_desc                <> fnright.type_desc
                    AND     fnleft.fanout                   <> fnright.fanout
                    AND     fnleft.boundary_value_on_right  <> fnright.boundary_value_on_right
                    WHERE   fnleft.function_id              <> fnright.function_id
                ) a
                GROUP BY lfunction_id, rfunction_id
            ) align
            ON      align.lfunction_id  = pf.function_id

            WHERE   a.type = N''U''
            OR      a.type = N''V''

            GROUP BY
                    e.name, 
                    a.object_id, 
                    b.name, 
                    p.partition_number,
                    s.avg_fragmentation_in_percent,
                    s.avg_fragment_size_in_pages,
                    s.avg_fragmentation_in_percent,
                    s.page_count,
                    align.ReportOrder,
                    fg1.name,
                    fg2.name,
                    ps.name,
                    pf.name

--          order by ''Index Row Length'' desc, e.name, a.name, b.name
        ')
     end
 else 
 if  8 =  (select substring(@version, 1, 1))
     begin

        CREATE TABLE [dbo].[#tbl_INDEX_FRAGMENTATION] (
            [ObjectName] [Nchar] (255) NOT NULL ,
            [ObjectID] [int] NOT NULL ,
            [IndexName] [Nchar] (255) NOT NULL ,
            [Indexid] [int] NOT NULL ,
            [Lvl] [int] NULL ,
            [CountPages] [int] NULL ,
            [CountRows] [int] NULL ,
            [MinRecSize] [int] NULL ,
            [MaxRecSize] [int] NULL ,
            [AvgRecSize] [int] NULL ,
            [ForRecCount] [int] NULL ,
            [Extents] [int] NULL ,
            [ExtentSwitches] [int] NULL ,
            [AvgFreeBytes] [int] NULL ,
            [AvgPageDensity] [int] NULL ,
            [ScanDensity] [decimal](18, 0) NULL ,
            [BestCount] [int] NULL ,
            [ActualCount] [int] NULL ,
            [LogicalFrag] [decimal](18, 0) NULL ,
            [ExtentFrag] [decimal](18, 0) NULL ,
            [Database_Name] [NVARCHAR] (150) NOT NULL DEFAULT (db_name()),
            [Index_depth] [int] NULL ,
            [Auto_Statistics] [bit] NULL ,
            [Statistic] [bit] NULL
        ) ON [PRIMARY]

        CREATE TABLE [dbo].[#tmp_fraglist] (
            [ObjectName] [Nchar] (255) NULL ,
            [ObjectID] [int] NULL ,
            [IndexName] [Nchar] (255) NULL ,
            [Indexid] [int] NULL ,
            [Lvl] [int] NULL ,
            [CountPages] [int] NULL ,
            [CountRows] [int] NULL ,
            [MinRecSize] [int] NULL ,
            [MaxRecSize] [int] NULL ,
            [AvgRecSize] [int] NULL ,
            [ForRecCount] [int] NULL ,
            [Extents] [int] NULL ,
            [ExtentSwitches] [int] NULL ,
            [AvgFreeBytes] [int] NULL ,
            [AvgPageDensity] [int] NULL ,
            [ScanDensity] [decimal](18, 0) NULL ,
            [BestCount] [int] NULL ,
            [ActualCount] [int] NULL ,
            [LogicalFrag] [decimal](18, 0) NULL ,
            [ExtentFrag] [decimal](18, 0) NULL ,
            [Database_Name] [NVARCHAR] (150) NULL DEFAULT (db_name()),
            [Index_depth] [int] NULL ,
            [Auto_Statistics] [bit] NULL ,
            [Statistic] [bit] NULL
        ) ON [PRIMARY]

        DECLARE 
            @SQLSTR NVARCHAR(4000),
            @Database_Name NVARCHAR(200),
            @TableName NVARCHAR (300),
            @TableName2 NVARCHAR (300),
			@Owner		NVARCHAR(255),
            @execstr   VARCHAR (255),
            @ObjectID  INT,
            @indexid   INT,
            @frag      DECIMAL,
            @indexname varchar (255),
            @NumberToDefrag INT,
            @NumberToReindex INT,
            @NoIndex Bit,
            @NoClusteredIndex Bit,
            @DuplicateIndex Bit,
            @IndexColumnRatio Bit,
            @HypotheticalIndex Bit,
            @PinTable Bit,
            @UserObjects Bit,
            @LogicalFragmentation Bit,
            @CheckSingleDB Bit,
            @SingleDBName NVARCHAR(255),
            @InstanceID INT,
            @NumberOfDB INT

        /* Declare cursor*/
        DECLARE tables CURSOR FOR
           SELECT DISTINCT name, USER_NAME(uid)
           FROM   sysobjects
           WHERE  OBJECTPROPERTYEX(id, 'IsMSShipped') = 0
           AND    id NOT IN (
				    SELECT object_id(objname)
				    FROM   ::fn_listextendedproperty ('microsoft_database_tools_support', default, default, default, default, NULL, NULL)
				    WHERE value = 1)
           AND    UPPER(type) = N'U'

        /* Open the cursor*/
        OPEN tables

        /* Loop through all the TABLEs in the DATAbase*/
        FETCH NEXT
           FROM tables
           INTO @TableName,
				@Owner

        WHILE @@FETCH_STATUS = 0
        BEGIN
        /* Do the showcontig of all indexes of the TABLE*/
           IF CHARINDEX(@TableName,CHAR(39),0)=0 -- bug 367932; CHAR(39) is a single quote
              BEGIN  
                 SELECT @TableName2=REPLACE(@TableName,CHAR(39),CHAR(39)+CHAR(39)) -- bug 367932
                 INSERT INTO #tmp_fraglist 
            (ObjectName, ObjectID, IndexName, Indexid, Lvl, CountPages, CountRows, MinRecSize, MaxRecSize, AvgRecSize, ForRecCount, Extents, ExtentSwitches, AvgFreeBytes, AvgPageDensity, ScanDensity, BestCount, ActualCount, LogicalFrag, ExtentFrag)
                 EXEC ('DBCC SHOWCONTIG (''[' + @Owner + N'].[' + @TableName2 + ']'') WITH /* FAST, */ TABLERESULTS, ALL_INDEXES, NO_INFOMSGS')
                 /* catch indexes FROM tables which are empty (by default no fragmention)*/
                 SET @SQLSTR='IF NOT EXISTS(SELECT * FROM [' + @Owner + N'].[' + @TableName + '] (NOLOCK)) AND NOT EXISTS(SELECT * FROM #tmp_fraglist (NOLOCK) WHERE ObjectID=Object_id(''[' + @Owner + N'].[' + @TableName2 + ']''))
           BEGIN
              INSERT INTO #tmp_fraglist (ObjectName,ObjectID,IndexName,Indexid,Database_Name,LogicalFrag,Index_depth)
              SELECT sysobjects.name,sysobjects.id,sysindexes.name,sysindexes.indid,db_name(),0,1 FROM sysindexes (NOLOCK) INNER JOIN sysobjects (NOLOCK) on sysindexes.id=sysobjects.id WHERE sysindexes.indid>0 AND NOT(sysindexes.name COLLATE Latin1_General_BIN LIKE ''_WA_%'') AND sysobjects.id=object_id(''['+ @Owner + N'].[' + @TableName2 + ']'')
           END '
              END
           ELSE
              BEGIN
                 INSERT INTO #tmp_fraglist 
            (ObjectName, ObjectID, IndexName, Indexid, Lvl, CountPages, CountRows, MinRecSize, MaxRecSize, AvgRecSize, ForRecCount, Extents, ExtentSwitches, AvgFreeBytes, AvgPageDensity, ScanDensity, BestCount, ActualCount, LogicalFrag, ExtentFrag)
                 EXEC ('DBCC SHOWCONTIG (''[' + @Owner + N'].[' + @TableName + ']'') WITH /*FAST, */ TABLERESULTS, ALL_INDEXES, NO_INFOMSGS')
                 /* catch indexes FROM tables which are empty (by default no fragmention)*/
                 SET @SQLSTR='IF NOT EXISTS(SELECT * FROM [' + @Owner + N'].[' + @TableName + '] (NOLOCK)) AND NOT EXISTS(SELECT * FROM #tmp_fraglist (NOLOCK) WHERE ObjectID=Object_id(''[' + @Owner + N'].[' + @TableName + ']''))
           BEGIN
              INSERT INTO #tmp_fraglist (ObjectName,ObjectID,IndexName,Indexid,Database_Name,LogicalFrag,Index_depth)
              SELECT sysobjects.name,sysobjects.id,sysindexes.name,sysindexes.indid,db_name(),0,1 FROM sysindexes (NOLOCK) INNER JOIN sysobjects (NOLOCK) on sysindexes.id=sysobjects.id WHERE sysindexes.indid>0 AND NOT(sysindexes.name COLLATE Latin1_General_BIN LIKE ''_WA_%'') AND sysobjects.id=object_id(''['+ @Owner + N'].[' + @TableName + ']'')
           END '
              END

           EXEC sp_executesql @SQLSTR

           UPDATE
            #tmp_fraglist
           SET 
            Database_Name=@Database_Name
           WHERE 
            Database_Name IS NULL

           SET @execstr='UPDATE #tmp_fraglist SET Index_depth=INDEXPROPERTY (ObjectID, IndexName, ''IndexDepth'') WHERE Index_depth IS null'

           EXEC (@execstr)

           SET @execstr='UPDATE #tmp_fraglist SET Auto_Statistics=INDEXPROPERTY (ObjectID, IndexName, ''IsAutoStatistics'') WHERE Auto_Statistics IS null'
           EXEC (@execstr)

           SET @execstr='UPDATE #tmp_fraglist SET Statistic=INDEXPROPERTY (ObjectID, IndexName, ''IsStatistics'') WHERE Statistic IS null'
           EXEC (@execstr)


        DELETE FROM #tmp_fraglist WHERE ObjectName='dtproperties'

        INSERT INTO #tbl_INDEX_FRAGMENTATION
            (ObjectName, ObjectID, IndexName, Indexid, Lvl, CountPages, CountRows, MinRecSize, MaxRecSize, AvgRecSize, ForRecCount, Extents, ExtentSwitches, AvgFreeBytes, AvgPageDensity, ScanDensity, BestCount, ActualCount, LogicalFrag, ExtentFrag, Database_Name, Index_depth, Auto_Statistics, Statistic)
        SELECT 
            ObjectName, ObjectID, IndexName, Indexid, Lvl, CountPages, CountRows, MinRecSize, MaxRecSize, AvgRecSize, ForRecCount, Extents, ExtentSwitches, AvgFreeBytes, AvgPageDensity, ScanDensity, BestCount, ActualCount, LogicalFrag, ExtentFrag, Database_Name, Index_depth, Auto_Statistics, Statistic
        FROM 
            #tmp_fraglist (NOLOCK)

        TRUNCATE TABLE #tmp_fraglist

           FETCH NEXT
              FROM tables
              INTO @TableName,
				   @Owner
        END

        CLOSE tables
        DEALLOCATE tables

           select distinct serverproperty('machinename')                               AS 'Server Name',                                           
                  isnull(serverproperty('instancename'),serverproperty('machinename')) AS 'Instance Name',  
                  db_name()                                                            AS 'Database Name',                                                           
                  user_name(a.uid)                                                     AS 'Owner Name',   
                  OBJECT_NAME(a.id)                                                    AS 'Table Name',
                  b.name                                                               AS 'Index Name',
                  1                                                                    AS 'Partition Number',
                  sum(isnull(c.length,0))                                              AS 'Index Row Length',
                  isnull(indexproperty(a.id, b.name, 'IndexFillFactor'),
                            b.OrigFillFactor)                                          AS 'Index Fillfactor',
                  isnull(indexproperty(a.id, b.name, 'IsHypothetical'),0) AS 'Hypothetical Index',
                  ISNULL(CAST(s.LogicalFrag AS DECIMAL(10,2)),0.0)                     AS 'Percent Page Fragmentation',
                  0.0                                                                  AS 'Average Fragment Size In Pages',
                  ISNULL(INDEXPROPERTY(a.id, b.name, 'IndexDepth'),0)                  AS 'Index Depth',
                  ISNULL(INDEXPROPERTY(a.id, b.name, 'IsStatistics'),0)                AS 'Is Statistics',
                  ISNULL(s.CountPages,0)                                               AS 'Page Count',
                  ISNULL(sf.name,N'')                                                  AS 'File Group Name',
                  N''                                                                  AS 'Partition Scheme Name',
                  N''                                                                  AS 'Partition Function Name',
                  N''                                                                  AS 'Partition Message'
             from sysobjects a
             join sysindexes b 
                  on b.id = a.id
                 and OBJECTPROPERTYEX(a.id,'IsMSShipped') = 0
                 and a.id not in (
				   select object_id(objname)
				   from   ::fn_listextendedproperty ('microsoft_database_tools_support', default, default, default, default, NULL, NULL)
				   where value = 1)
             join syscolumns c 
                  on c.id = a.id
                INNER JOIN
                        #tbl_INDEX_FRAGMENTATION s
                ON      b.[id]=s.[ObjectID]
                and     s.Indexid > 0  -- bug 260575
                and     b.indid=s.Indexid
			  and OBJECTPROPERTYEX(a.id, 'IsMSShipped') = 0
              and ((b.status & 64) = 0
               or  (b.status & 32) = 0
               or  (b.status & 8388608) = 0
               and (b.status & 2097152) = 0)
              and (colid = INDEXKEY_PROPERTY(b.id,b.indid,1,'ColumnId')
               or  colid = INDEXKEY_PROPERTY(b.id,b.indid,2,'ColumnId')
               or  colid = INDEXKEY_PROPERTY(b.id,b.indid,3,'ColumnId')
               or  colid = INDEXKEY_PROPERTY(b.id,b.indid,4,'ColumnId')
               or  colid = INDEXKEY_PROPERTY(b.id,b.indid,5,'ColumnId')
               or  colid = INDEXKEY_PROPERTY(b.id,b.indid,6,'ColumnId')
               or  colid = INDEXKEY_PROPERTY(b.id,b.indid,7,'ColumnId')
               or  colid = INDEXKEY_PROPERTY(b.id,b.indid,8,'ColumnId')
               or  colid = INDEXKEY_PROPERTY(b.id,b.indid,9,'ColumnId')
               or  colid = INDEXKEY_PROPERTY(b.id,b.indid,10,'ColumnId')
               or  colid = INDEXKEY_PROPERTY(b.id,b.indid,11,'ColumnId')
               or  colid = INDEXKEY_PROPERTY(b.id,b.indid,12,'ColumnId')
               or  colid = INDEXKEY_PROPERTY(b.id,b.indid,13,'ColumnId')
               or  colid = INDEXKEY_PROPERTY(b.id,b.indid,14,'ColumnId')
               or  colid = INDEXKEY_PROPERTY(b.id,b.indid,15,'ColumnId')
               or  colid = INDEXKEY_PROPERTY(b.id,b.indid,16,'ColumnId'))
            join sysfiles sf (NOLOCK)
            on b.groupid = sf.groupid
            group by user_name(a.uid), a.id, b.name, s.CountPages, s.LogicalFrag, sf.name, b.OrigFillFactor
--            order by 'Index Row Length' desc, user_name(a.uid), a.name, b.name

            drop table #tmp_fraglist
            drop table #tbl_INDEX_FRAGMENTATION

     end;