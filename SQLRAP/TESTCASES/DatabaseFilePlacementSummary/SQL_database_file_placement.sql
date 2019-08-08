--Signature="30644166AA2B619F" 

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    updated 10 Oct 2008 - CR 224905                                                                   ****/
--/****    rajpo   23 Mar 2009 -Pilot testing by jaimeta: Filtered OFF line DBs for SQL2K                    ****/
--/****    djaiswal   03 Nov 2009 - CR 379851                                                                ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright © Microsoft Corporation. All rights reserved.                                           ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

 declare @version char(12);
 set     @version =  convert(char(12),serverproperty('productversion'));

if  '10' = (select substring(@version, 1, 2))
     begin
          select distinct serverproperty('machinename')                                  as 'Server Name',                                           
                 isnull(serverproperty('instancename'),serverproperty('machinename'))    as 'Instance Name', 
                 db_name(a.database_id)                                                  as 'Database Name',
                 a.database_id                                                           as 'Database ID',
                 (case a.type
                       when 0 then 'Data File'
                       when 1 then 'Log File'
                       when 4 then 'Full Text Catalog File'
                       else null
                  end)                                                                   as 'File Type',
                 a.physical_name                                                         as 'File Physical Location',
                 ltrim(str((convert (dec (15,2),a.size)) * 8192 / 1048576,15,2) + ' MB') as 'File Size'
          from master.sys.master_files a
          where lower(db_name(a.database_id)) not in (/*N'tempdb',*/ N'master', N'msdb', N'adventureworks', N'adventureworksdw', N'model', N'northwind', N'pubs')
          order by 'Database Name', 'File Type', 'File Physical Location'
     end
 else 
 if  9 = (select substring(@version, 1, 1))
     begin
          select distinct serverproperty('machinename')                                  as 'Server Name',                                           
                 isnull(serverproperty('instancename'),serverproperty('machinename'))    as 'Instance Name', 
                 db_name(a.database_id)                                                  as 'Database Name',
                 a.database_id                                                           as 'Database ID',
                 (case a.type
                       when 0 then 'Data File'
                       when 1 then 'Log File'
                       when 4 then 'Full Text Catalog File'
                       else null
                  end)                                                                   as 'File Type',
                 a.physical_name                                                         as 'File Physical Location',
                 ltrim(str((convert (dec (15,2),a.size)) * 8192 / 1048576,15,2) + ' MB') as 'File Size'
          from master.sys.master_files a
          where lower(db_name(a.database_id)) not in (/*N'tempdb',*/ N'master', N'msdb', N'adventureworks', N'adventureworksdw', N'model', N'northwind', N'pubs')
          order by 'Database Name', 'File Type', 'File Physical Location'
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin
                set quoted_identifier off

                declare @dbid    int
                declare @maxdbid int
                declare @string  nvarchar(4000)
                
                set @dbid    = 1
                set @maxdbid = (select max(dbid) from master..sysdatabases)

                create table  #dbinfo_table (server_name nvarchar(256), 
                                              instance_name nvarchar(256), 
                                              database_name nvarchar(256), 
                                              database_id int, 
                                              file_type nvarchar(25), 
                                              file_location nvarchar(2556), 
                                              file_size nvarchar(25))

                while @dbid <= @maxdbid
                      begin
                           if  null = (select db_name(@dbid))
							or
                               exists (select 1 from master..sysdatabases
                                       where dbid = @dbid
                                       and
                                       (		status & 32 <> 0		-- loading
										or		status & 64 <> 0		-- pre recovery
										or		status & 128 <> 0	-- recovering
										or		status & 256 <> 0	-- not recovered
										or		status & 512 <> 0	-- offline
										or		status & 32768 <> 0	-- emergency mode
										)
									   )
							begin
								set @dbid=@dbid +1
                               continue
							end
                           else 
                               begin 
                                    select @string = "insert #dbinfo_table select convert(sysname,(serverproperty('machinename'))), "
                                                   + "isnull((convert(sysname,(serverproperty('instancename')))),convert(sysname,(serverproperty('machinename')))),"
                                                   + " N'" + db_name(@dbid) + "', "
                                                   + convert(char(03),@dbid)
                                                   + ", (case status & 0x40 when 0x40 then 'Log File' else 'Data File' end), a.filename,"
                                                   + " ltrim(str((convert (dec (15,2),a.size)) * 8192 / 1048576,15,2) + ' MB') from ["
                                                   + db_name(@dbid)
                                                   + "]..sysfiles a"

                                    execute sp_executesql @string

                               end

                           set @dbid = @dbid + 1

                      end

                select server_name    as 'Server Name',                                           
                       instance_name  as 'Instance Name', 
                       database_name  as 'Database Name',
                       database_id    as 'Database ID',
                       file_type      as 'File Type',
                       file_location  as 'File Physical Location',
                       file_size      as 'File Size'
                  from #dbinfo_table
                  where lower(database_name) not in (/*N'tempdb',*/ N'master', N'msdb', N'adventureworks', N'adventureworksdw', N'model', N'northwind', N'pubs')
                 order by 'Database Name', 'File Type', 'File Physical Location'

                drop table #dbinfo_table

                set quoted_identifier on
         end;