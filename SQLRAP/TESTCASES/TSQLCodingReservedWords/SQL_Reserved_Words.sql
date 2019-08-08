--Signature="EA7EA869EC4642FA" 

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    SQLCensus_Reserved_Wordss.sql      											                     ****/
--/****    Search for use of T-SQL Reserved Words used as Column Names and Object Names                      ****/
--/****                                                                                                      ****/
--/****    Created by wardp 2010.Jun.28                                                                      ****/
--/****    Updated by wardp 2010.Jul.22 (CR 168493)                                                          ****/
--/****    Updated by wardp 2010.Sep.29 (bug 468888)                                                         ****/
--/****    Updated by rajpo	2010.Nov.23 Case sensitivity issue                                               ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright  Microsoft Corporation. All rights reserved.                                            ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

SET NOCOUNT ON

declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));

if  '10' = (select substring(@version, 1, 2))
     begin
        
         select distinct serverproperty('machinename')                               as 'Server Name',                                           
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                db_name()                                                            as 'Database Name',                                                              
                c.name                                                               as 'Owner Name',       
                b.name                                                               as 'Object Name',
                a.name                                                               as 'Column Name',
                CASE
                    WHEN obj.ObjectType = N'TR'
                        THEN obj.ExtendedProperties
                    ELSE
                        ISNULL(tempdb.dbo.fnSQLRAP_SQLCensus_ObjectTypePresentation(obj.ObjectType), 'Table (user-defined)')
                END COLLATE DATABASE_DEFAULT			                                                                            AS 'Object Type',
                N'Reserved Words - Columns'                                          as 'Issue',
                N'SQL_Reserved_Words_Column_Names'                                   as 'RuleName'
           from  sys.columns a (NOLOCK)
           join  sys.objects b (NOLOCK)
             on  b.object_id = a.object_id
           join  sys.schemas c (NOLOCK)
             on  c.schema_id = b.schema_id
           join  tempdb.dbo.SQLRAP_SQLCensus_ReservedWords rw (NOLOCK)
             on  UPPER(a.name) COLLATE DATABASE_DEFAULT = rw.ReservedWord COLLATE DATABASE_DEFAULT
            LEFT OUTER JOIN
		            tempdb.dbo.SQLRAP_SQLCensus_Objects obj (NOLOCK)
            ON		obj.databaseid          = DB_ID()
            AND		b.object_id		        = obj.ObjectId
            where  b.is_ms_shipped = 0
            and  b.object_id not in (select major_id from sys.extended_properties where name = N'microsoft_database_tools_support')

    union all

          select distinct serverproperty('machinename')                               as 'Server Name',                                           
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                db_name()                                                            as 'Database Name',                                                              
                b.name                                                               as 'Owner Name',       
                a.name                                                               as 'Object Name',
                N' '                                                                 as 'Column Name',
                CASE
                    WHEN obj.ObjectType = N'TR'
                        THEN obj.ExtendedProperties
                    ELSE
                        ISNULL(tempdb.dbo.fnSQLRAP_SQLCensus_ObjectTypePresentation(obj.ObjectType), 'Table (user-defined)')
                END COLLATE DATABASE_DEFAULT			                                                                            AS 'Object Type',
                N'Reserved Words - Objects'                                          as 'Issue',
                N'SQL_Reserved_Words_Object_Names'                                   as 'RuleName'
           from  sys.objects a (NOLOCK)
           join  sys.schemas b (NOLOCK)
             on  b.schema_id = a.schema_id
           join tempdb.dbo.SQLRAP_SQLCensus_ReservedWords rw (NOLOCK)
             on UPPER(a.name) COLLATE DATABASE_DEFAULT = rw.ReservedWord COLLATE DATABASE_DEFAULT
            LEFT OUTER JOIN
		            tempdb.dbo.SQLRAP_SQLCensus_Objects obj (NOLOCK)
            ON		obj.databaseid          = DB_ID()
            AND		a.object_id		        = obj.ObjectId
          where a.is_ms_shipped = 0
            and a.object_id not in (select major_id from sys.extended_properties where name = N'microsoft_database_tools_support')

          order by 'RuleName'

     end
 else 
 if  9 = (select substring(@version, 1, 1))
     begin

         select distinct serverproperty('machinename')                               as 'Server Name',                                           
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                db_name()                                                            as 'Database Name',                                                              
                c.name                                                               as 'Owner Name',       
                b.name                                                               as 'Object Name',
                a.name                                                               as 'Column Name',
                CASE
                    WHEN obj.ObjectType = N'TR'
                        THEN obj.ExtendedProperties
                    ELSE
                        ISNULL(tempdb.dbo.fnSQLRAP_SQLCensus_ObjectTypePresentation(obj.ObjectType), 'Table (user-defined)')
                END COLLATE DATABASE_DEFAULT			                                                                            AS 'Object Type',
                N'Reserved Words - Columns'                                          as 'Issue',
                N'SQL_Reserved_Words_Column_Names'                                   as 'RuleName'
           from  sys.columns a (NOLOCK)
           join  sys.objects b (NOLOCK)
             on  b.object_id = a.object_id
           join  sys.schemas c (NOLOCK)
             on  c.schema_id = b.schema_id
           join  tempdb.dbo.SQLRAP_SQLCensus_ReservedWords rw (NOLOCK)
             on  UPPER(a.name) COLLATE DATABASE_DEFAULT = rw.ReservedWord COLLATE DATABASE_DEFAULT
            LEFT OUTER JOIN
		            tempdb.dbo.SQLRAP_SQLCensus_Objects obj (NOLOCK)
            ON		obj.databaseid          = DB_ID()
            AND		b.object_id		        = obj.ObjectId
            where  b.is_ms_shipped = 0
            and  b.object_id not in (select major_id from sys.extended_properties where name = N'microsoft_database_tools_support')

    union all

          select distinct serverproperty('machinename')                               as 'Server Name',                                           
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                db_name()                                                            as 'Database Name',                                                              
                b.name                                                               as 'Owner Name',       
                a.name                                                               as 'Object Name',
                N' '                                                                 as 'Column Name',
                CASE
                    WHEN obj.ObjectType = N'TR'
                        THEN obj.ExtendedProperties
                    ELSE
                        ISNULL(tempdb.dbo.fnSQLRAP_SQLCensus_ObjectTypePresentation(obj.ObjectType), 'Table (user-defined)')
                END COLLATE DATABASE_DEFAULT			                                                                            AS 'Object Type',
                N'Reserved Words - Objects'                                          as 'Issue',
                N'SQL_Reserved_Words_Object_Names'                                   as 'RuleName'
           from  sys.objects a (NOLOCK)
           join  sys.schemas b (NOLOCK)
             on  b.schema_id = a.schema_id
           join tempdb.dbo.SQLRAP_SQLCensus_ReservedWords rw (NOLOCK)
             on UPPER(a.name) COLLATE DATABASE_DEFAULT = rw.ReservedWord COLLATE DATABASE_DEFAULT
            LEFT OUTER JOIN
		            tempdb.dbo.SQLRAP_SQLCensus_Objects obj (NOLOCK)
            ON		obj.databaseid          = DB_ID()
            AND		a.object_id		        = obj.ObjectId
          where a.is_ms_shipped = 0
            and a.object_id not in (select major_id from sys.extended_properties where name = N'microsoft_database_tools_support')

          order by 'RuleName'

     end
 else 
 if  8 =  (select substring(@version, 1, 1))

begin
     
     select distinct serverproperty('machinename')                               as 'Server Name',                                           
            isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
            db_name()                                                            as 'Database Name',                                                              
            user_name(b.uid)                                                     as 'Owner Name',       
            object_name(b.id)                                                    as 'Object Name',
            a.name                                                               as 'Column Name',
                CASE
                    WHEN obj.ObjectType = N'TR'
                        THEN obj.ExtendedProperties
                    ELSE
                        ISNULL(tempdb.dbo.fnSQLRAP_SQLCensus_ObjectTypePresentation(obj.ObjectType), 'Table (user-defined)')
                END COLLATE DATABASE_DEFAULT			                                                                            AS 'Object Type',
                N'Reserved Words - Columns'                                          as 'Issue',
                N'SQL_Reserved_Words_Column_Names'                                   as 'RuleName'
       from syscolumns a (NOLOCK)
       join sysobjects b (NOLOCK)
         on b.id = a.id
        and OBJECTPROPERTYEX(b.id, 'IsMSShipped') = 0
        and b.id not in (
			select object_id(objname)
			from   ::fn_listextendedproperty ('microsoft_database_tools_support', default, default, default, default, NULL, NULL)
			where value = 1)
       join tempdb.dbo.SQLRAP_SQLCensus_ReservedWords rw (NOLOCK)
         on UPPER(a.name) COLLATE DATABASE_DEFAULT = rw.ReservedWord COLLATE DATABASE_DEFAULT
            LEFT OUTER JOIN
		            tempdb.dbo.SQLRAP_SQLCensus_Objects obj (NOLOCK)
            ON		obj.databaseid          = DB_ID()
            AND		b.id		            = obj.ObjectId

    union all

     select distinct serverproperty('machinename')                               as 'Server Name',                                           
            isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
            db_name()                                                            as 'Database Name',                                                              
            user_name(a.uid)                                                     as 'Owner Name',       
            object_name(a.id)                                                    as 'Object Name',
            N' '                                                                 as 'Column Name',
                CASE
                    WHEN obj.ObjectType = N'TR'
                        THEN obj.ExtendedProperties
                    ELSE
                        ISNULL(tempdb.dbo.fnSQLRAP_SQLCensus_ObjectTypePresentation(obj.ObjectType), 'Table (user-defined)')
                END COLLATE DATABASE_DEFAULT			                                                                            AS 'Object Type',
            N'Reserved Words - Objects'                                          as 'Issue',
            N'SQL_Reserved_Words_Object_Names'                                   as 'RuleName'
       from sysobjects a (NOLOCK)
       join tempdb.dbo.SQLRAP_SQLCensus_ReservedWords rw (NOLOCK)
         on UPPER(a.name) COLLATE DATABASE_DEFAULT = rw.ReservedWord COLLATE DATABASE_DEFAULT
        LEFT OUTER JOIN
		        tempdb.dbo.SQLRAP_SQLCensus_Objects obj (NOLOCK)
        ON		obj.databaseid          = DB_ID()
        AND		a.id		            = obj.ObjectId
      where OBJECTPROPERTYEX(a.id, 'IsMSShipped') = 0
        and a.id not in (
		  select object_id(objname)
		  from   ::fn_listextendedproperty ('microsoft_database_tools_support', default, default, default, default, NULL, NULL)
		  where value = 1)
     order by 'RuleName'

end;