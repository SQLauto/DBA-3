--Signature="171A54CB8714DE15" 

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    SQL_indexes_by_indexes                                                                            ****/
--/****    Collect index-based index statistics (table-based index statistics collected in another script.)  ****/
--/****                                                                                                      ****/
--/****    Created 2010.Aug.04 by wardp                                                                      ****/
--/****    Updated 2010.Sep.09 by wardp (bug 468324)                                                         ****/
--/****    Updated 2010.Sep.29 by wardp (bug 468831)                                                         ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright (c) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/


declare @version char(12),
        @dbid int;
set     @version =  convert(char(12),serverproperty('productversion'));
set     @dbid = db_id()

 if  '10' = (select substring(@version, 1, 2)) -- CR 375891
 begin

      select distinct serverproperty('machinename')                               as 'Server Name',                                           
             isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
             db_name()                                                            as 'Database Name',                                                              
             su.name                                                              as 'Owner Name',       
             object_name(so.object_id)                                            as 'Object Name',
             case objectproperty(max(so.object_id), 'TableHasClustIndex')
                   when 1 then 'Clustered'
                   when 0 then 'Heap'
                   else 'Indexed View'
             end                                                                  as 'ClusteredHeap',
             case objectproperty(max(so.object_id), 'TableHasClustIndex')
                    when 0 then count(si.index_id) - 1 -- bug 468324
                    else count(si.index_id)
             end                                                                  as 'Index Count',
             max(d.ColumnCount)                                                   as 'Column Count',
             max(dmv.rows)                                                        as 'Approximate Rows'
        from sys.objects so (NOLOCK)
        join sys.indexes si (NOLOCK)
          on so.object_id = si.object_id
		 and so.type in (N'U',N'V')  -- bug 468831
            join sysindexes dmv (NOLOCK)
              on so.object_id = dmv.id
             and si.index_id  = dmv.indid
       full outer join (select object_id, count(1) as ColumnCount
			 from sys.columns (NOLOCK)
			 group by object_id) d 
       on d.object_id = so.object_id
        join sys.schemas su  (NOLOCK)
          on su.schema_id = so.schema_id
        where so.is_ms_shipped = 0
          and so.object_id not in (select major_id from sys.extended_properties (NOLOCK) where name = N'microsoft_database_tools_support')
          and indexproperty(so.object_id, si.name, 'IsStatistics') = 0
       group by su.name, 
                object_name(so.object_id),
               (case objectproperty(si.object_id, 'TableHasClustIndex')
                     when 1 then 'Clustered'
                     when 0 then 'Heap'
                     else 'Indexed View'
                 end)
        
       order by 'Owner Name', 'Object Name'
 end
else -- CR 375891
 if  9 = (select substring(@version, 1, 1))
     begin

      select distinct serverproperty('machinename')                               as 'Server Name',                                           
             isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
             db_name()                                                            as 'Database Name',                                                              
             su.name                                                              as 'Owner Name',       
             object_name(so.object_id)                                            as 'Object Name',
             case objectproperty(max(so.object_id), 'TableHasClustIndex')
                   when 1 then 'Clustered'
                   when 0 then 'Heap'
                   else 'Indexed View'
             end                                                                  as 'ClusteredHeap',
             case objectproperty(max(so.object_id), 'TableHasClustIndex')
                    when 0 then count(si.index_id) - 1 -- bug 468324
                    else count(si.index_id)
             end                                                                  as 'Index Count',
             max(d.ColumnCount)                                                   as 'Column Count',
             max(dmv.rows)                                                        as 'Approximate Rows'
        from sys.objects so (NOLOCK)
        join sys.indexes si (NOLOCK)
          on so.object_id = si.object_id
		 and so.type in (N'U',N'V')  -- bug 468831
            join sysindexes dmv (NOLOCK)
              on so.object_id = dmv.id
             and si.index_id  = dmv.indid
       full outer join (select object_id, count(1) as ColumnCount
			 from sys.columns (NOLOCK)
			 group by object_id) d 
       on d.object_id = so.object_id
        join sys.schemas su  (NOLOCK)
          on su.schema_id = so.schema_id
        where so.is_ms_shipped = 0
          and so.object_id not in (select major_id from sys.extended_properties (NOLOCK) where name = N'microsoft_database_tools_support')
          and indexproperty(so.object_id, si.name, 'IsStatistics') = 0
       group by su.name, 
                object_name(so.object_id),
               (case objectproperty(si.object_id, 'TableHasClustIndex')
                     when 1 then 'Clustered'
                     when 0 then 'Heap'
                     else 'Indexed View'
                 end)
        
       order by 'Owner Name', 'Object Name'

     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin

               select distinct serverproperty('machinename')                               as 'Server Name',                                           
                      isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                      db_name()                                                            as 'Database Name',                                                              
                      user_name(so.uid)                                                    as 'Owner Name',       
                      object_name(so.id)                                                   as 'Object Name',
                      case objectproperty(max(so.id), 'TableHasClustIndex')
                           when 1 then 'Clustered'
                           when 0 then 'Heap'
                       end                                                                 as 'ClusteredHeap',
                      case objectproperty(max(so.id), 'TableHasClustIndex')
                           when 0 then count(si.indid) - 1 -- bug 468324
                           else count(si.indid)
                      end                                                                  as 'Index Count',
                      sc.ColCount                                                          as 'Column Count',
                      max(si.rows)                                                         as 'Approximate Rows'
                from sysindexes si (NOLOCK)
                join sysobjects so (NOLOCK)
                     on so.id = si.id 
				    and so.xtype in (N'U',N'V')  -- bug 468831
                join (select id, count(colid) as ColCount
                      from syscolumns (NOLOCK)
                      group by id
                      ) sc
                     on so.id = sc.id
               where OBJECTPROPERTYEX(so.id, 'IsMSShipped') = 0
                 and so.id not in (
					select object_id(objname)
					from   ::fn_listextendedproperty ('microsoft_database_tools_support', default, default, default, default, NULL, NULL)
					where value = 1)
                 and si.indid < 255
                 and (si.status & (64 | 8388608)) = 0 
               group by user_name(so.uid), 
                        object_name(so.id),
                        case objectproperty(si.id, 'TableHasClustIndex')
                              when 1 then 'Clustered'
                              when 0 then 'Heap'
                          end,
                        sc.ColCount
                order by 'Owner Name', 'Object Name'
         end;