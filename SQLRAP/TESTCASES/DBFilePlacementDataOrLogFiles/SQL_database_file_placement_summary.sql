--Signature="F43458868FE787A3" 

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Report logical drives housing both logs and data for user databases                               ****/
--/****       and logical drives hosting both tempdb and user database objects                               ****/
--/****                                                                                                      ****/
--/****    CR 196645 - wardp - 07.Oct.08                                                                     ****/
--/****	   rajpo   23 Mar 2009 -Pilot testing by jaimeta: Fixed infinite loop for offline DBs for SQL2K      ****/
--/****    September 16th 2009: djaiswal, changed for SQL2K8 reference CR 379851                                                                                                   ****/
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
     
        select serverproperty('machinename')    as 'Server Name',                                           
           isnull(serverproperty('instancename'),serverproperty('machinename'))  as 'Instance Name', 
           drive_letter   as 'Drive Letter',
           DiagnosticMessage
        from
        (
        (
			select distinct 
		           UPPER(LEFT(LTRIM(physical_name),2)) AS drive_letter,
				   N'Device holds both tempdb and user database objects'   as 'DiagnosticMessage',
				   1 AS OrderBy
			from master.sys.master_files
			where lower(db_name(database_id)) = 'tempdb'
			and UPPER(LEFT(LTRIM(physical_name),2)) in
				(
				select UPPER(LEFT(LTRIM(physical_name),2))
				from master.sys.master_files
				where lower(db_name(database_id)) not in (N'tempdb', N'master', N'msdb', N'adventureworks', N'adventureworksdw', N'model', N'northwind', N'pubs')
				)
		 )
         union
         (
			select drive_letter,
				   N'Device holds both data and log objects'   as 'DiagnosticMessage',
				   2 AS OrderBy
			from
				(
				select drive_letter
				from 
					(
					select distinct UPPER(LEFT(LTRIM(physical_name),2)) AS drive_letter, type
					from master.sys.master_files
					where lower(db_name(database_id)) not in (/*N'tempdb',*/ N'master', N'msdb', N'adventureworks', N'adventureworksdw', N'model', N'northwind', N'pubs')
                    ) a
	            group by drive_letter
	            having count(1) >= 2
			    ) b
		)
		) a
		ORDER BY OrderBy, drive_letter

     end
 else
 if  9 = (select substring(@version, 1, 1))
     begin
     
        select serverproperty('machinename')    as 'Server Name',                                           
           isnull(serverproperty('instancename'),serverproperty('machinename'))  as 'Instance Name', 
           drive_letter   as 'Drive Letter',
           DiagnosticMessage
        from
        (
        (
			select distinct 
		           UPPER(LEFT(LTRIM(physical_name),2)) AS drive_letter,
				   N'Device holds both tempdb and user database objects'   as 'DiagnosticMessage',
				   1 AS OrderBy
			from master.sys.master_files
			where lower(db_name(database_id)) = 'tempdb'
			and UPPER(LEFT(LTRIM(physical_name),2)) in
				(
				select UPPER(LEFT(LTRIM(physical_name),2))
				from master.sys.master_files
				where lower(db_name(database_id)) not in (N'tempdb', N'master', N'msdb', N'adventureworks', N'adventureworksdw', N'model', N'northwind', N'pubs')
				)
		 )
         union
         (
			select drive_letter,
				   N'Device holds both data and log objects'   as 'DiagnosticMessage',
				   2 AS OrderBy
			from
				(
				select drive_letter
				from 
					(
					select distinct UPPER(LEFT(LTRIM(physical_name),2)) AS drive_letter, type
					from master.sys.master_files
					where lower(db_name(database_id)) not in (/*N'tempdb',*/ N'master', N'msdb', N'adventureworks', N'adventureworksdw', N'model', N'northwind', N'pubs')
                    ) a
	            group by drive_letter
	            having count(1) >= 2
			    ) b
		)
		) a
		ORDER BY OrderBy, drive_letter

     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin
                set quoted_identifier off
                
                set nocount on

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
                                              file_size nvarchar(25),
                                              drive_letter AS UPPER(LEFT(LTRIM(file_location),2)))

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
							Begin
								set @dbid = @dbid + 1
                               continue
							end
                           else 
                               begin 
                                    select @string = "insert #dbinfo_table (server_name, instance_name, database_name, database_id, file_type, file_location, file_size) "
                                                   + "select convert(sysname,(serverproperty('machinename'))), "
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
                       drive_letter   as 'Drive Letter',
                       DiagnosticMessage
                from
                (
                (
					select distinct 
				           server_name,                                           
						   instance_name, 
						   drive_letter,
						   N'Device holds both tempdb and user database objects'   as 'DiagnosticMessage',
						   1 AS OrderBy
					from #dbinfo_table
					where lower(database_name) = 'tempdb'
					and drive_letter in
						(
						select drive_letter
						from #dbinfo_table
						where lower(database_name) not in (N'tempdb', N'master', N'msdb', N'adventureworks', N'adventureworksdw', N'model', N'northwind', N'pubs')
						)
				 )
                 union
                 (
					select server_name,                                           
						   instance_name, 
						   drive_letter,
						   N'Device holds both data and log objects'   as 'DiagnosticMessage',
						   2 AS OrderBy
					from
						(
						select server_name, instance_name, drive_letter
						from 
							(
							select distinct server_name, instance_name, drive_letter, file_type
							from #dbinfo_table
							where lower(database_name) not in (/*N'tempdb',*/ N'master', N'msdb', N'adventureworks', N'adventureworksdw', N'model', N'northwind', N'pubs')
	                        ) a
			            group by drive_letter, server_name, instance_name
			            having count(1) = 2
					    ) b
				)
				) a 
				ORDER BY OrderBy, drive_letter

                drop table #dbinfo_table

                set quoted_identifier on
         end;