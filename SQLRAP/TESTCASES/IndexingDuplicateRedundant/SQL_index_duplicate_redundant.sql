--Signature="81BF64CAFAC304BB" 

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    Display tables with indexes containing redundant elements.                                        ****/
--/****                                                                                                      ****/
--/****    6/27/08 - Tim Wolff - Removed wildcards                                                           ****/
--/****    3/18/09 - Ward Pond - Bug 325763                                                                  ****/
--/****    4/01/09 - Ward Pond - Bug 337105                                                                  ****/
--/****    7/16/09 - Ward Pond - CR 375891                                                                   ****/
--/****    3/04/10 - Ward Pond - Bug 439881                                                                  ****/
--/****    9/09/10 - Ward Pond - Bug 468320 (child of bug 467936)                                            ****/
--/****    9/30/10 - Ward Pond - Bug 468780                                                                  ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright © Microsoft Corporation. All rights reserved.                                           ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

-- keep some house

set nocount on
set arithabort on

declare @version char(12);

declare   @spid           nvarchar(40)
        , @SQLString      nvarchar(4000)
        , @db_name        sysname
        , @dbcmptlevel    int

set @db_name = db_name();
 
select top 1 @dbcmptlevel = cmptlevel
from master.dbo.sysdatabases
where [name] = @db_name

set @spid = CAST(@@spid as nvarchar(40))
set @version =  convert(char(12),serverproperty('productversion'));

-- don't run this test case if database compatibility level is 70 or below
if @dbcmptlevel <= 70
begin
	select  serverproperty('machinename')																											as 'Server Name',                                           
			isnull(serverproperty('instancename'),serverproperty('machinename'))																	as 'Instance Name',  
			@db_name																																as 'Database Name',
			N'--'																																	as 'Owner Name',
			N'--'																																	as 'Object Name',
			N'--== Test case skipped because this database is at compatibility level ' + CAST(@dbcmptlevel as nvarchar) + N'; minimum is 80 ==--'	as 'Message',
			issues.Issue																															as 'Issue'
	from
	(
		select N'duplicate' as 'Issue'
		union all
		select N'redundant'
	) issues
end
else
begin
 if  '10' = (select substring(@version, 1, 2))  -- CR 375891
     begin

        -- create the helper function
        EXEC ('USE tempdb; IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N''fn_sqlrap_helpindex' + @spid + N''') DROP FUNCTION dbo.fn_sqlrap_helpindex' + @spid)
        EXEC ('USE tempdb; EXEC(''
        CREATE FUNCTION dbo.fn_sqlrap_helpindex' + @spid + N'
	        (@objid int, @indid int)
        RETURNS nvarchar(max)

        AS

        BEGIN

        DECLARE @ReturnVal nvarchar(max)

        ;WITH ColumnToPivot ([data()]) AS ( 
            SELECT CAST(ic.column_id AS nvarchar(10)) + ISNULL(x.secondary_type,N'''''''') + CASE WHEN ic.is_descending_key = 1 THEN N''''(-)'''' ELSE N'''''''' END + N''''|'''' 
            FROM [' + @db_name + N'].sys.index_columns ic
            JOIN [' + @db_name + N'].sys.indexes c 
            ON c.object_id = ic.object_id
            AND c.index_id = ic.index_id 
            LEFT OUTER JOIN [' + @db_name + N'].sys.xml_indexes x
            ON c.object_id = x.object_id
            AND c.index_id = x.index_id 
            WHERE c.object_id = @objid
	        AND   c.index_id = @indid
            ORDER BY ic.object_id, ic.index_id, ic.is_included_column, ic.key_ordinal 
            FOR XML PATH(''''''''), TYPE 
        ), 
            XmlRawData (CSVString) AS ( 
                SELECT (SELECT [data()] AS mydata FROM ColumnToPivot AS d FOR XML RAW, TYPE).value( ''''/row[1]/mydata[1]'''', ''''NVARCHAR(max)'''') AS CSV_Column 
        ) 
        SELECT @ReturnVal = CASE WHEN LEN(CSVString) <= 1 THEN NULL ELSE LEFT(CSVString, LEN(CSVString)-1) END
        FROM XmlRawData

        RETURN (@ReturnVal)

        END'')
        ')

        -- create the duplicate index concatenation function
        EXEC ('USE tempdb; IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N''fn_sqlrap_FindDuplicateIndexes' + @spid + N''') DROP FUNCTION dbo.fn_sqlrap_FindDuplicateIndexes' + @spid)
        EXEC ('USE tempdb; EXEC(''
        CREATE FUNCTION dbo.fn_sqlrap_FindDuplicateIndexes' + @spid + N'
	        (@objid int, @keylist nvarchar(max)
	        )
        	
        RETURNS nvarchar(max)

        AS

        BEGIN

        DECLARE @ReturnVal nvarchar(max)

        ;WITH ColumnToPivot ([data()]) AS ( 
            SELECT name + N'''', '''' 
            FROM [' + @db_name + N'].sys.indexes c 
	        WHERE tempdb.dbo.fn_sqlrap_helpindex' + @spid + N' (c.object_id, c.index_id) = @keylist
	        and object_id = @objid
            ORDER BY c.object_id, c.index_id 
            FOR XML PATH(''''''''), TYPE 
        ), 
            XmlRawData (CSVString) AS ( 
                SELECT (SELECT [data()] AS mydata FROM ColumnToPivot AS d FOR XML RAW, TYPE).value( ''''/row[1]/mydata[1]'''', ''''NVARCHAR(max)'''') AS CSV_Column 
        ) 
        SELECT @ReturnVal = CASE WHEN LEN(CSVString) <= 1 THEN NULL ELSE LEFT(CSVString, LEN(RTRIM(CSVString))-1) END
        FROM XmlRawData

        RETURN (@ReturnVal)

        END'')
        ')

        -- create the redundant index concatenation function
        EXEC ('USE tempdb; IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N''fn_sqlrap_FindRedundantIndexes' + @spid + N''') DROP FUNCTION dbo.fn_sqlrap_FindRedundantIndexes' + @spid)
        EXEC ('USE tempdb; EXEC(''
        CREATE FUNCTION dbo.fn_sqlrap_FindRedundantIndexes' + @spid + N'
	        (@objid int, @keylist nvarchar(max)
	        )
        	
        RETURNS nvarchar(max)

        AS

        BEGIN

        DECLARE @ReturnVal nvarchar(max)

        ;WITH ColumnToPivot ([data()]) AS ( 
            SELECT name + N'''', '''' 
            FROM [' + @db_name + N'].sys.indexes c 
	        WHERE dbo.fn_sqlrap_helpindex' + @spid + N' (c.object_id, c.index_id) COLLATE Latin1_General_BIN LIKE @keylist + N''''|%''''
	        and object_id = @objid
            ORDER BY c.object_id, c.index_id 
            FOR XML PATH(''''''''), TYPE 
        ), 
            XmlRawData (CSVString) AS ( 
                SELECT (SELECT [data()] AS mydata FROM ColumnToPivot AS d FOR XML RAW, TYPE).value( ''''/row[1]/mydata[1]'''', ''''NVARCHAR(max)'''') AS CSV_Column 
        ) 
        SELECT @ReturnVal = CASE WHEN LEN(CSVString) <= 1 THEN NULL ELSE LEFT(CSVString, LEN(RTRIM(CSVString))-1) END
        FROM XmlRawData

        RETURN (@ReturnVal)

        END'')
        ')

        -- get the results and drop the functions we just created
        EXEC('
        select  distinct serverproperty(''machinename'')                                            as ''Server Name'',                                           
                         isnull(serverproperty(''instancename''),serverproperty(''machinename''))   as ''Instance Name'',  
                         db_name()                                                                  as ''Database Name'',                                                              
                         SCHEMA_NAME(so.schema_id)                                                    as ''Owner Name'',       
                         so.name                                                                    as ''Object Name'',
                         N''The following indexes contain duplicate elements: '' COLLATE DATABASE_DEFAULT
                         + tempdb.dbo.fn_sqlrap_FindDuplicateIndexes' + @spid + N' (si.object_id, tempdb.dbo.fn_sqlrap_helpindex' + @spid + N'(si.object_id, si.index_id)) COLLATE DATABASE_DEFAULT
                                                                                                    as ''Message'',
                         N''duplicate''                                                             as ''Issue''
        from sys.objects so
        join sys.indexes si
        on so.object_id = si.object_id
        and not (si.name COLLATE Latin1_General_BIN LIKE ''_WA_%'')
        and so.is_ms_shipped = 0
        and     so.object_id not in (
			        select object_id(objname)
			        from   ::fn_listextendedproperty (''microsoft_database_tools_support'', default, default, default, default, NULL, NULL)
			        where value = 1)
        and tempdb.dbo.fn_sqlrap_FindDuplicateIndexes' + @spid + N' (si.object_id, tempdb.dbo.fn_sqlrap_helpindex' + @spid + '(si.object_id, si.index_id)) COLLATE Latin1_General_BIN LIKE N''%, %''

        union all

        select  distinct serverproperty(''machinename'')                                            as ''Server Name'',                                           
                         isnull(serverproperty(''instancename''),serverproperty(''machinename''))   as ''Instance Name'',  
                         db_name()                                                                  as ''Database Name'',                                                              
                         SCHEMA_NAME(so.schema_id)                                                    as ''Owner Name'',       
                         so.name                                                                    as ''Object Name'',
                         si.name + N'' is redundant to the following index(es): '' COLLATE DATABASE_DEFAULT
                         + tempdb.dbo.fn_sqlrap_FindRedundantIndexes' + @spid + N' (si.object_id, tempdb.dbo.fn_sqlrap_helpindex' + @spid + N'(si.object_id, si.index_id)) COLLATE DATABASE_DEFAULT
                                                                                                    as ''Message'',
                         N''redundant''                                                             as ''Issue''
        from sys.objects so
        join sys.indexes si
        on  so.object_id = si.object_id
        and not (si.name COLLATE Latin1_General_BIN LIKE ''_WA_%'')
        and so.is_ms_shipped = 0
        and     so.object_id not in (
			        select object_id(objname)
			        from   ::fn_listextendedproperty (''microsoft_database_tools_support'', default, default, default, default, NULL, NULL)
			        where value = 1)
        and tempdb.dbo.fn_sqlrap_FindRedundantIndexes' + @spid + N' (si.object_id, tempdb.dbo.fn_sqlrap_helpindex' + @spid + '(si.object_id, si.index_id)) COLLATE Latin1_General_BIN IS NOT NULL;
        
        use tempdb;drop function fn_sqlrap_helpindex' + @spid + N';drop function fn_sqlrap_FindDuplicateIndexes' + @spid + N';drop function fn_sqlrap_FindRedundantIndexes' + @spid
        )

     end
 else   -- CR 375891
 if  9 = (select substring(@version, 1, 1))
     begin

        -- create the helper function
        EXEC ('USE tempdb; IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N''fn_sqlrap_helpindex' + @spid + N''') DROP FUNCTION dbo.fn_sqlrap_helpindex' + @spid)
        EXEC ('USE tempdb; EXEC(''
        CREATE FUNCTION dbo.fn_sqlrap_helpindex' + @spid + N'
	        (@objid int, @indid int)
        RETURNS nvarchar(max)

        AS

        BEGIN

        DECLARE @ReturnVal nvarchar(max)

        ;WITH ColumnToPivot ([data()]) AS ( 
            SELECT CAST(ic.column_id AS nvarchar(10)) + ISNULL(x.secondary_type,N'''''''') + CASE WHEN ic.is_descending_key = 1 THEN N''''(-)'''' ELSE N'''''''' END + N''''|'''' 
            FROM [' + @db_name + N'].sys.index_columns ic
            JOIN [' + @db_name + N'].sys.indexes c 
            ON c.object_id = ic.object_id
            AND c.index_id = ic.index_id 
            LEFT OUTER JOIN [' + @db_name + N'].sys.xml_indexes x
            ON c.object_id = x.object_id
            AND c.index_id = x.index_id 
            WHERE c.object_id = @objid
	        AND   c.index_id = @indid
            ORDER BY ic.object_id, ic.index_id, ic.is_included_column, ic.key_ordinal 
            FOR XML PATH(''''''''), TYPE 
        ), 
            XmlRawData (CSVString) AS ( 
                SELECT (SELECT [data()] AS mydata FROM ColumnToPivot AS d FOR XML RAW, TYPE).value( ''''/row[1]/mydata[1]'''', ''''NVARCHAR(max)'''') AS CSV_Column 
        ) 
        SELECT @ReturnVal = CASE WHEN LEN(CSVString) <= 1 THEN NULL ELSE LEFT(CSVString, LEN(CSVString)-1) END
        FROM XmlRawData

        RETURN (@ReturnVal)

        END'')
        ')

        -- create the duplicate index concatenation function
        EXEC ('USE tempdb; IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N''fn_sqlrap_FindDuplicateIndexes' + @spid + N''') DROP FUNCTION dbo.fn_sqlrap_FindDuplicateIndexes' + @spid)
        EXEC ('USE tempdb; EXEC(''
        CREATE FUNCTION dbo.fn_sqlrap_FindDuplicateIndexes' + @spid + N'
	        (@objid int, @keylist nvarchar(max)
	        )
        	
        RETURNS nvarchar(max)

        AS

        BEGIN

        DECLARE @ReturnVal nvarchar(max)

        ;WITH ColumnToPivot ([data()]) AS ( 
            SELECT name + N'''', '''' 
            FROM [' + @db_name + N'].sys.indexes c 
	        WHERE tempdb.dbo.fn_sqlrap_helpindex' + @spid + N' (c.object_id, c.index_id) = @keylist
	        and object_id = @objid
            ORDER BY c.object_id, c.index_id 
            FOR XML PATH(''''''''), TYPE 
        ), 
            XmlRawData (CSVString) AS ( 
                SELECT (SELECT [data()] AS mydata FROM ColumnToPivot AS d FOR XML RAW, TYPE).value( ''''/row[1]/mydata[1]'''', ''''NVARCHAR(max)'''') AS CSV_Column 
        ) 
        SELECT @ReturnVal = CASE WHEN LEN(CSVString) <= 1 THEN NULL ELSE LEFT(CSVString, LEN(RTRIM(CSVString))-1) END
        FROM XmlRawData

        RETURN (@ReturnVal)

        END'')
        ')

        -- create the redundant index concatenation function
        EXEC ('USE tempdb; IF EXISTS (SELECT 1 FROM sys.objects WHERE name = N''fn_sqlrap_FindRedundantIndexes' + @spid + N''') DROP FUNCTION dbo.fn_sqlrap_FindRedundantIndexes' + @spid)
        EXEC ('USE tempdb; EXEC(''
        CREATE FUNCTION dbo.fn_sqlrap_FindRedundantIndexes' + @spid + N'
	        (@objid int, @keylist nvarchar(max)
	        )
        	
        RETURNS nvarchar(max)

        AS

        BEGIN

        DECLARE @ReturnVal nvarchar(max)

        ;WITH ColumnToPivot ([data()]) AS ( 
            SELECT name + N'''', '''' 
            FROM [' + @db_name + N'].sys.indexes c 
	        WHERE dbo.fn_sqlrap_helpindex' + @spid + N' (c.object_id, c.index_id) COLLATE Latin1_General_BIN LIKE @keylist + N''''|%''''
	        and object_id = @objid
            ORDER BY c.object_id, c.index_id 
            FOR XML PATH(''''''''), TYPE 
        ), 
            XmlRawData (CSVString) AS ( 
                SELECT (SELECT [data()] AS mydata FROM ColumnToPivot AS d FOR XML RAW, TYPE).value( ''''/row[1]/mydata[1]'''', ''''NVARCHAR(max)'''') AS CSV_Column 
        ) 
        SELECT @ReturnVal = CASE WHEN LEN(CSVString) <= 1 THEN NULL ELSE LEFT(CSVString, LEN(RTRIM(CSVString))-1) END
        FROM XmlRawData

        RETURN (@ReturnVal)

        END'')
        ')

        -- get the results and drop the functions we just created
        EXEC('
        select  distinct serverproperty(''machinename'')                                            as ''Server Name'',                                           
                         isnull(serverproperty(''instancename''),serverproperty(''machinename''))   as ''Instance Name'',  
                         db_name()                                                                  as ''Database Name'',                                                              
                         SCHEMA_NAME(so.schema_id)                                                    as ''Owner Name'',       
                         so.name                                                                    as ''Object Name'',
                         N''The following indexes contain duplicate elements: '' COLLATE DATABASE_DEFAULT
                         + tempdb.dbo.fn_sqlrap_FindDuplicateIndexes' + @spid + N' (si.object_id, tempdb.dbo.fn_sqlrap_helpindex' + @spid + N'(si.object_id, si.index_id)) COLLATE DATABASE_DEFAULT
                                                                                                    as ''Message'',
                        N''duplicate''                                                              as ''Issue''
        from sys.objects so
        join sys.indexes si
        on so.object_id = si.object_id
        and not (si.name COLLATE Latin1_General_BIN LIKE ''_WA_%'')
        and so.is_ms_shipped = 0
        and     so.object_id not in (
			        select object_id(objname)
			        from   ::fn_listextendedproperty (''microsoft_database_tools_support'', default, default, default, default, NULL, NULL)
			        where value = 1)
        and tempdb.dbo.fn_sqlrap_FindDuplicateIndexes' + @spid + N' (si.object_id, tempdb.dbo.fn_sqlrap_helpindex' + @spid + '(si.object_id, si.index_id)) COLLATE Latin1_General_BIN LIKE N''%, %''
        
        union all
        
        select  distinct serverproperty(''machinename'')                                            as ''Server Name'',                                           
                 isnull(serverproperty(''instancename''),serverproperty(''machinename''))   as ''Instance Name'',  
                 db_name()                                                                  as ''Database Name'',                                                              
                 SCHEMA_NAME(so.schema_id)                                                    as ''Owner Name'',       
                 so.name                                                                    as ''Object Name'',
                 si.name + N'' is redundant to the following index(es): '' COLLATE DATABASE_DEFAULT
                 + tempdb.dbo.fn_sqlrap_FindRedundantIndexes' + @spid + N' (si.object_id, tempdb.dbo.fn_sqlrap_helpindex' + @spid + N'(si.object_id, si.index_id)) COLLATE DATABASE_DEFAULT
                                                                                            as ''Message'',
                 ''redundant''                                                              as ''Issue''
        from sys.objects so
        join sys.indexes si
        on  so.object_id = si.object_id
        and not (si.name COLLATE Latin1_General_BIN LIKE ''_WA_%'')
        and so.is_ms_shipped = 0
        and     so.object_id not in (
			        select object_id(objname)
			        from   ::fn_listextendedproperty (''microsoft_database_tools_support'', default, default, default, default, NULL, NULL)
			        where value = 1)
        and tempdb.dbo.fn_sqlrap_FindRedundantIndexes' + @spid + N' (si.object_id, tempdb.dbo.fn_sqlrap_helpindex' + @spid + '(si.object_id, si.index_id)) COLLATE Latin1_General_BIN IS NOT NULL;

        use tempdb;drop function fn_sqlrap_helpindex' + @spid + N';drop function fn_sqlrap_FindDuplicateIndexes' + @spid + N';drop function fn_sqlrap_FindRedundantIndexes' + @spid
        )

     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin

         EXEC(N'USE tempdb;
         EXEC(N''
         if exists (select 1 from sysobjects where name = N''''sqlrap_helpindex' + @spid + N''''')
	drop proc sqlrap_helpindex' + @spid + N';'')
		 EXEC (N''create proc sqlrap_helpindex' + @spid + N'
	@objname nvarchar(776)		-- the table to check for indexes
as
	-- PRELIM
	set nocount on

	declare @objid int,			-- the object id of the table
			@indid smallint,	-- the index id of an index
			@groupid smallint,  -- the filegroup id of an index
			@indname sysname,
			@groupname sysname,
			@status int,
			@keys nvarchar(2126),
			@SQLString nvarchar(4000)

    CREATE TABLE #ObjectId (
        object_id int )

    EXEC (N''''USE [' + @db_name + N']; INSERT #ObjectId (object_id) SELECT OBJECT_ID('''''''''''' + @objname + '''''''''''')'''')

    select @objid = object_id
    from   #ObjectId

    DROP TABLE #ObjectId

	-- OPEN CURSOR OVER INDEXES (skip stats: bug shiloh_51196)
	declare ms_crs_ind cursor local static for
		select indid, groupid, name, status from [' + @db_name + N'].dbo.sysindexes
			where id = @objid and indid > 0 and indid < 255 and (status & 64)=0
			and name not like N''''_WA_%''''
			 order by indid
	open ms_crs_ind
	fetch ms_crs_ind into @indid, @groupid, @indname, @status

	-- IF NO INDEX, QUIT
	if @@fetch_status < 0
	begin
		deallocate ms_crs_ind
		return (0)
	end

	-- create temp table
	create table #spindtab
	(
		index_name			sysname	collate database_default NOT NULL,
		stats				int,
		groupname			sysname collate database_default NOT NULL,
		index_keys			nvarchar(2126)	collate database_default NOT NULL -- see @keys above for length descr
	)

	create table #IsDescending (
		result nvarchar(3)
		)
			

	-- Now check out each index, figure out its type and keys and
	--	save the info in a temporary table that we''''ll print out at the end.
	while @@fetch_status >= 0
	begin
		-- First we''''ll figure out what the keys are.
		declare @i int, @thiskey nvarchar(131) -- 128+3

		select @keys = cast(colid as nvarchar(10)), @i = 2
		from [' + @db_name + N'].dbo.sysindexkeys
		where id = @objid
		and   indid = @indid
		and   keyno = 1
		
		set @SQLString = N''''use [' + @db_name + N']; if 1 = (select indexkey_property('''' + 
			CAST(@objid as nvarchar(10)) + N'''', '''' + 
			CAST(@indid as nvarchar(10)) + N'''', 1, ''''''''isdescending''''''''))
			begin insert #IsDescending (result) values(''''''''(-)'''''''') end
			else
			begin insert #IsDescending (result) values('''''''''''''''') end'''' 

		exec (@SQLString)
		select	@keys = @keys + result
		from	#IsDescending

		delete  #IsDescending

		set @thiskey = NULL
		
		select @thiskey = cast(colid as nvarchar(10))
		from [' + @db_name + N'].dbo.sysindexkeys
		where id = @objid
		and   indid = @indid
		and   keyno = @i

		if @thiskey is not null
		begin

			set @SQLString = N''''use [' + @db_name + N']; if 1 = (select indexkey_property('''' + 
				CAST(@objid as nvarchar(10)) + N'''', '''' + 
				CAST(@indid as nvarchar(10)) + N'''', '''' + 
				CAST(@i as nvarchar(10)) + N'''', ''''''''isdescending''''''''))
				begin insert #IsDescending (result) values(''''''''(-)'''''''') end
				else
				begin insert #IsDescending (result) values('''''''''''''''') end''''

			exec (@SQLString)
			
			select	@keys = @keys + result
			from	#IsDescending

			delete  #IsDescending
		end
		
		while (@thiskey is not null )
		begin

			set @keys = @keys + ''''|'''' + @thiskey
			set @i = @i + 1
			set @thiskey = NULL

			select @thiskey = cast(colid as nvarchar(10))
			from [' + @db_name + N'].dbo.sysindexkeys
			where id = @objid
			and   indid = @indid
			and   keyno = @i

			if @thiskey is not null
			begin
				set @SQLString = N''''use [' + @db_name + N']; if 1 = (select indexkey_property('''' + 
					CAST(@objid as nvarchar(10)) + N'''', '''' + 
					CAST(@indid as nvarchar(10)) + N'''', '''' + 
					CAST(@i as nvarchar(10)) + N'''', ''''''''isdescending''''''''))
					begin insert #IsDescending (result) values(''''''''(-)'''''''') end
					else
					begin insert #IsDescending (result) values('''''''''''''''') end''''

				exec (@SQLString)

				select	@keys = @keys + result
				from	#IsDescending

				delete  #IsDescending
			end
		end

		select @groupname = groupname from [' + @db_name + N'].dbo.sysfilegroups where groupid = @groupid

		-- INSERT ROW FOR INDEX
		insert into #spindtab values (@indname, @status, @groupname, @keys)

		-- Next index
		fetch ms_crs_ind into @indid, @groupid, @indname, @status
	end
	deallocate ms_crs_ind

	-- DISPLAY THE RESULTS
	select
		index_name,
		groupname,
		index_keys
	from #spindtab
	order by index_name
         '')
         ')
         
        EXEC(N'create table #qtemp' + @spid + N' (
        qtemp_id int identity(1,1),
        index_name sysname,
        index_description nvarchar(256),
        index_keys varchar(4000),
        table_name nvarchar(256),
        partition_name AS lower(index_description)
        )

        create table #Code' + @spid + N' (
        CodeId int identity(1,1),
        SQLString nvarchar(4000),
        Processed bit default(0)
        )

        insert #Code' + @spid + N' (SQLString)
        select distinct N''INSERT #qtemp' + @spid + N' (index_name, index_description, index_keys)
        EXEC tempdb.dbo.sqlrap_helpindex' + @spid + N' N'' + CHAR(39) + N''['' + USER_NAME(so.uid) + N''].['' + so.name + N'']'' + CHAR(39) + N'';
        update #qtemp' + @spid + N' set table_name = N'' + CHAR(39) + so.name + CHAR(39) + N''
        where   table_name is null''
        from    sysobjects so
        join    sysindexes si
        on      si.id = so.id
        and     si.indid >= 1
        and		si.indid <= 254
		and		si.keys IS NOT NULL
        and     not (si.name COLLATE Latin1_General_BIN LIKE ''_WA_%'')
        and     OBJECTPROPERTYEX(so.id, ''IsMSShipped'') = 0
        and     so.id not in (
			select object_id(objname)
			from   ::fn_listextendedproperty (''microsoft_database_tools_support'', default, default, default, default, NULL, NULL)
			where value = 1)

        and     UPPER(so.type) = N''U'';

        declare @CodeId int, @SQLString nvarchar(4000)

        while exists (select Processed from #Code' + @spid + N' where Processed = 0)
        begin

            select  top 1 @CodeId = CodeId,
                    @SQLString = SQLString
            from    #Code' + @spid + N'
            where   Processed = 0

            EXEC(@SQLString)

            update  #Code' + @spid + N'
            set     Processed = 1
            where   CodeId = @CodeId
        end

        update #qtemp' + @spid + N'
        set    index_keys = lower(index_keys)

        select  distinct serverproperty(''machinename'')                               as ''Server Name'',                                           
                         isnull(serverproperty(''instancename''),serverproperty(''machinename'')) as ''Instance Name'',  
                         db_name()                                                            as ''Database Name'',                                                              
                         USER_NAME(c.uid)                                                     as ''Owner Name'',       
                         a.table_name                                                         as ''Object Name'',
                         a.index_name + N'' and '' + b.index_name + N'' contain duplicate elements.'' AS Message,
                         ''duplicate''                                                        as ''Issue''
        from   #qtemp' + @spid + N' a
        join   #qtemp' + @spid + N' b
        on     a.table_name = b.table_name
        and    a.partition_name = b.partition_name
        and    a.qtemp_id < b.qtemp_id
        and    patindex(a.index_keys + N'''',b.index_keys COLLATE Latin1_General_BIN) = 1
        join   sysobjects c
        on     a.table_name COLLATE DATABASE_DEFAULT = c.name COLLATE DATABASE_DEFAULT
        
        union all
        
        select  distinct serverproperty(''machinename'')                               as ''Server Name'',                                           
                         isnull(serverproperty(''instancename''),serverproperty(''machinename'')) as ''Instance Name'',  
                         db_name()                                                            as ''Database Name'',                                                              
                         user_name(c.uid)                                                     as ''Owner Name'',       
                         a.table_name                                                         as ''Object Name'',
                         a.index_name + N'' and '' + b.index_name + N'' contain redundant elements.'' AS Message,
                         ''redundant''                                                        as ''Issue''
        from   #qtemp' + @spid + N' a
        join   #qtemp' + @spid + N' b
        on     a.table_name = b.table_name
        and    a.partition_name = b.partition_name
        and    a.qtemp_id < b.qtemp_id
        and    (
                patindex(a.index_keys + N''%'',b.index_keys  COLLATE Latin1_General_BIN) = 1
                or
                patindex(b.index_keys + N''%'',a.index_keys  COLLATE Latin1_General_BIN) = 1
                )
        and    a.index_keys <> b.index_keys
        join   sysobjects c
        on     a.table_name COLLATE DATABASE_DEFAULT = c.name COLLATE DATABASE_DEFAULT
        
        drop table #qtemp' + @spid + N';
        drop table #Code' + @spid + N';
        use tempdb;drop procedure sqlrap_helpindex' + @spid + N';')

         end;
end