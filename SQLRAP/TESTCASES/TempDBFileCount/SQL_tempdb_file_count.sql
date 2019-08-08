--Signature="B9A4E0EAAAA9EDFA" 

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****      Verify if tempdb file count < number of processors                                              ****/
--/****                                                                                                      ****/
--/****      6/16/08 - Tim Wolff - changed logic from not equals to less than                                            ****/
--/****      3/09/09 - Ward Pond - CR 319723 (add 'Tempdb Data Device Size Message' column.)                 ****/
--/****      4/01/09 - Ward Pond - CR 319723 revisited                                                       ****/
--/****      4/09/09 - Ward Pond - bug 340719                                                                ****/
--/****      Added validation for SQL Server 2008 - djaiswal 9/21/2009  Ref CR 375891                                                                                                ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright © Microsoft Corporation. All rights reserved.                                           ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/


 declare @version char(12);
 set     @version =  convert(char(12),serverproperty('productversion'));

 create table #msver_info(ID              int,  
                           Name            sysname, 
                           Internal_Value  int, 
                           Value           nvarchar(512))
 insert #msver_info exec master.dbo.xp_msver

if  '10' = (select substring(@version, 1, 2))
     begin
          select distinct serverproperty('machinename')                                               as 'Server Name',                                           
                 isnull(serverproperty('instancename'),serverproperty('machinename'))        as 'Instance Name', 
                 db_name(a.database_id)														 as 'Database Name',
                 a.database_id                                                               as 'Database ID',
                 (select Internal_Value from #msver_info where Name = N'ProcessorCount')    as 'Processor Count',
                 (select count(b.physical_name) 
                    from master.sys.master_files b 
                   where b.type = 0
                     and b.database_id = 2)                                                  as 'File Count',
                  case  
                        when (select count(c.physical_name) 
                              from master.sys.master_files c 
                              where c.type = 0
                              and c.database_id = 2)
                            < 
                            (select Internal_Value 
                             from #msver_info 
                             where Name = N'ProcessorCount')
                        then 'Fewer tempdb data device files than processors'
                        when 1 = (select count(1) from                     
                        (
                            select  c.size, count(1) as counter
                            from    master.sys.master_files c
                            where   c.type = 0
                            and c.database_id = 2
                            group by c.size
                        ) as c)
                        then 'All tempdb data device files sized identically'
                        else 'Different sized tempdb data device files detected'
                        end                                                                  as 'Tempdb Data Device Filecount/Size Message'
           from master.sys.master_files a
          where a.type = 0
            and a.database_id = 2
            and (
                (select count(c.physical_name) 
                    from master.sys.master_files c 
                   where c.type = 0
                     and c.database_id = 2) < (select Internal_Value 
                                                  from #msver_info 
                                                 where Name = N'ProcessorCount')
                 or
                 1 <> (select count(1) from                     
                        (
                            select  c.size, count(1) as counter
                            from    master.sys.master_files c
                            where   c.type = 0
                            and c.database_id = 2
                            group by c.size
                        ) as c)
                )
     end
 else 
 if  9 = (select substring(@version, 1, 1))
     begin
          select distinct serverproperty('machinename')                                               as 'Server Name',                                           
                 isnull(serverproperty('instancename'),serverproperty('machinename'))        as 'Instance Name', 
                 db_name(a.database_id)														 as 'Database Name',
                 a.database_id                                                               as 'Database ID',
                 (select Internal_Value from #msver_info where Name = N'ProcessorCount')    as 'Processor Count',
                 (select count(b.physical_name) 
                    from master.sys.master_files b 
                   where b.type = 0
                     and b.database_id = 2)                                                  as 'File Count',
                  case  
                        when (select count(c.physical_name) 
                              from master.sys.master_files c 
                              where c.type = 0
                              and c.database_id = 2)
                            < 
                            (select Internal_Value 
                             from #msver_info 
                             where Name = N'ProcessorCount')
                        then 'Fewer tempdb data device files than processors'
                        when 1 = (select count(1) from                     
                        (
                            select  c.size, count(1) as counter
                            from    master.sys.master_files c
                            where   c.type = 0
                            and c.database_id = 2
                            group by c.size
                        ) as c)
                        then 'All tempdb data device files sized identically'
                        else 'Different sized tempdb data device files detected'
                        end                                                                  as 'Tempdb Data Device Filecount/Size Message'
           from master.sys.master_files a
          where a.type = 0
            and a.database_id = 2
            and (
                (select count(c.physical_name) 
                    from master.sys.master_files c 
                   where c.type = 0
                     and c.database_id = 2) < (select Internal_Value 
                                                  from #msver_info 
                                                 where Name = N'ProcessorCount')
                 or
                 1 <> (select count(1) from                     
                        (
                            select  c.size, count(1) as counter
                            from    master.sys.master_files c
                            where   c.type = 0
                            and c.database_id = 2
                            group by c.size
                        ) as c)
                )
     end
 else 
     if  8 =  (select substring(@version, 1, 1)) 
         begin
                set quoted_identifier off

                declare @dbid    int
                declare @maxdbid int
                declare @string  nvarchar(4000)
                
                set @dbid    = 2 -- tempdb
 
                create table  #dbinfo_table (server_name nvarchar(256), 
                                              instance_name nvarchar(256), 
                                              database_name nvarchar(256), 
                                              database_id int, 
                                              file_type nvarchar(25), 
                                              file_location nvarchar(2556), 
                                              file_size nvarchar(25))

                select @string = "insert #dbinfo_table"
							   + " select convert(sysname,(serverproperty('machinename'))), "
                               + "isnull((convert(sysname,(serverproperty('instancename')))),convert(sysname,(serverproperty('machinename')))),"
                               + " N'tempdb', "
                               + convert(char(03),@dbid)
                               + ", (case status & 0x40 when 0x40 then 'Log File' else 'Data File' end), a.filename,"
                               + " ltrim(str((convert (dec (15,2),a.size)) * 8192 / 1048576,15,2) + ' MB') from ["
                               + db_name(@dbid)
                               + "]..sysfiles a"

                execute sp_executesql @string

                select distinct server_name                         as 'Server Name',                                           
                       instance_name                       as 'Instance Name', 
                       database_name                       as 'Database Name',
                       database_id                         as 'Database ID',
                      (select Internal_Value 
                         from #msver_info 
                        where Name = N'ProcessorCount')    as 'Processor Count',
                      (select count(file_location) 
                        from #dbinfo_table b 
                       where b.file_type = 'Data File'
                         and b.database_id = 2)            as 'File Count',

                  case  
                        when (select count(file_location) 
                              from #dbinfo_table c 
                              where c.file_type = 'data file'
                              and c.database_id = 2)
                            < 
                            (select Internal_Value 
                             from #msver_info 
                             where Name = N'ProcessorCount')
                        then 'Fewer tempdb data device files than processors'
                        when 1 = (select count(1) from                     
                        (
                            select  c.file_size, count(1) as counter
                            from    #dbinfo_table c
                            where   c.file_type = 'Data File'
                            group by c.file_size
                        ) as c)
                        then 'All tempdb data device files sized identically'
                        else 'Different sized tempdb data device files detected'
                        end                                                                  as 'Tempdb Data Device Filecount/Size Message'
                  from #dbinfo_table a
                 where a.file_type = 'Data File'
                   and a.database_id = 2
                   and (
                       (select count(file_location) 
                          from #dbinfo_table c 
                         where c.file_type = 'data file'
                           and c.database_id = 2) < (select Internal_Value 
                                                        from #msver_info 
                                                       where Name = N'ProcessorCount')
                 or
                 1 <> (select count(1) from                     
                        (
                            select  c.file_size, count(1) as counter
                            from    #dbinfo_table c
                            where   c.file_type = 'Data File'
                            group by c.file_size
                        ) as c)
                )

                drop table #dbinfo_table

                set quoted_identifier on
         end;

 drop table #msver_info;
