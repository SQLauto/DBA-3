--Signature="7B4CA9185A865521" 

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    Determine the date of "last known good" execution of DBCC CHECKDB                                 ****/
--/****    This script will list all databases where no DBCC Checkdb has been run within the last 7 days.    ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    updated 2009.Jan.12 wardp (resolve bug 218089)                                                    ****/
--/****    updated 2009.Jul.17 wardo (add support for SQL2K8 (CR 375891))                                    ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright (c) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));

declare @dbid    int
declare @maxdbid int
declare @string  nvarchar(4000)
declare @dbname  sysname 

create table  #dbinfo_table (server_name   nvarchar(255), 
                           instance_name nvarchar(255), 
                           database_name nvarchar(255), 
                           database_id   int, 
                           value         nvarchar(255))

create table #dbinfo_2000(ParentObject  varchar(255),
                              Object        varchar(255),
                              Field         varchar(255),
                              value         varchar(255))

 if  '10' = (select substring(@version, 1, 2))  -- CR 375891
     begin
          set quoted_identifier off
          set nocount on 

          set @dbid    = 1
          set @maxdbid = (select max(dbid) from master..sysdatabases)

          while @dbid <= @maxdbid
                begin
                     if  null = (select db_name(@dbid))
                         set @dbid = @dbid + 1
                     else if lower(db_name(@dbid)) = N'tempdb'
						 set @dbid = @dbid + 1
                     else if N'ONLINE' <> (select state_desc from sys.databases where database_id = @dbid)
                         set @dbid = @dbid + 1
                     else 
                         begin 
                              set @dbname = db_name(@dbid)

                              set @string = "INSERT INTO #dbinfo_2000 EXEC('DBCC DBINFO(''" + rtrim(ltrim(@dbname)) + "'') WITH TABLERESULTS, NO_INFOMSGS')";
 
                              execute sp_executesql @string

                              insert into #dbinfo_table
                              select distinct  -- distinct added in CR 375891
                                     convert(sysname,(serverproperty('machinename'))),
                                     isnull((convert(sysname,(serverproperty('instancename')))),convert(sysname,(serverproperty('machinename')))),
                                     db_name(@dbid),
                                     @dbid,
                                     value
                                from #dbinfo_2000
                               where Field = 'dbi_dbccLastKnownGood'

                              delete from #dbinfo_2000

							  set @dbid = @dbid + 1

                         end
                end

                select server_name                      as 'Server Name',                                           
                       instance_name                    as 'Instance Name', 
                       database_name                    as 'Database Name',
                       database_id                      as 'Database ID',
                       CASE value
						WHEN N'1900-01-01 00:00:00.000' THEN 'Never'
						ELSE value
                       END								as 'Date of last DBCC CHECKDB',
                       CASE value
						WHEN N'1900-01-01 00:00:00.000' THEN 'Never'
                        ELSE CONVERT(nvarchar(10),DATEDIFF(day,convert(datetime,([value])),GETDATE()))
					   END								as 'Days Since Last DBCC CHECKDB'
                  from #dbinfo_table
                 where DATEDIFF(day,convert(datetime,([value])),GETDATE()) > 7
                 order by 'Server Name','Instance Name','Database Name'

                set quoted_identifier on
     end
 else -- CR 375891
 if  9 = (select substring(@version, 1, 1))
     begin
          set quoted_identifier off
          set nocount on 

          set @dbid    = 1
          set @maxdbid = (select max(dbid) from master..sysdatabases)

          while @dbid <= @maxdbid
                begin
                     if  null = (select db_name(@dbid))
                         set @dbid = @dbid + 1
                     else if lower(db_name(@dbid)) = N'tempdb'
						 set @dbid = @dbid + 1
                     else if N'ONLINE' <> (select state_desc from sys.databases where database_id = @dbid)
                         set @dbid = @dbid + 1
                     else 
                         begin 
                              set @dbname = db_name(@dbid)

                              set @string = "INSERT INTO #dbinfo_2000 EXEC('DBCC DBINFO(''" + rtrim(ltrim(@dbname)) + "'') WITH TABLERESULTS, NO_INFOMSGS')";
 
                              execute sp_executesql @string

                              insert into #dbinfo_table
                              select convert(sysname,(serverproperty('machinename'))),
                                     isnull((convert(sysname,(serverproperty('instancename')))),convert(sysname,(serverproperty('machinename')))),
                                     db_name(@dbid),
                                     @dbid,
                                     value
                                from #dbinfo_2000
                               where Field = 'dbi_dbccLastKnownGood'

                              delete from #dbinfo_2000

							  set @dbid = @dbid + 1

                         end
                end

                select server_name                      as 'Server Name',                                           
                       instance_name                    as 'Instance Name', 
                       database_name                    as 'Database Name',
                       database_id                      as 'Database ID',
                       CASE value
						WHEN N'1900-01-01 00:00:00.000' THEN 'Never'
						ELSE value
                       END								as 'Date of last DBCC CHECKDB',
                       CASE value
						WHEN N'1900-01-01 00:00:00.000' THEN 'Never'
                        ELSE CONVERT(nvarchar(10),DATEDIFF(day,convert(datetime,([value])),GETDATE()))
					   END								as 'Days Since Last DBCC CHECKDB'
                  from #dbinfo_table
                 where DATEDIFF(day,convert(datetime,([value])),GETDATE()) > 7
                 order by 'Server Name','Instance Name','Database Name'

                set quoted_identifier on
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin
               select ''  as 'Server Name',                                           
                      ''  as 'Instance Name', 
                      ''  as 'Database Name',
                      ''  as 'Database ID',
                      ''  as 'Date of last DBCC CHECKDB',
                      ''  as 'Days Since Last DBCC CHECKDB'
               where 1=2
              /*Need to determine if there is a viable way to determine this programatically within SQL 2000 */
         end

drop table #dbinfo_table
drop table #dbinfo_2000