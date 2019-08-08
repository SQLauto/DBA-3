--Signature="964DD8F8973F4E4D" 


--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****   Enumeration and aggregation of all Errors reported within all SQL Server errorlogs..               ****/
--/****   (this includes current and archived errorlogs)                                                     ****/
--/****                                                                                                      ****/
--/****   Updated 16.Oct.2008 (wardp): substantial rewrite for filtering and new grid control                ****/
--/****   Updated 2008.Dec.09 (wardp) CR 259074 (move ReservedWords and ErrorLogFilters to pertinent scripts) ****/
--/****   Updated 2009.Feb.12 (wardp) bug 295557 (second result set for oldest errorlog entry)               ****/
--/****   Updated 2009.Mar.19 (wardp) bug 325322                                                             ****/
--/****   Updated 2009.Apr.01 (wardp) bug 325322 again                                                       ****/
--/****   Updated 2009.Apr.07 (wardp) bug 339922                                                             ****/
--/****   Updated 2009.Apr.22 (wardp) bug 325322: add to exclusion lists                                     ****/
--/****   Updated 2009.Jul.10 (wardp) bug 358124: remove from exclusion lists                                ****/
--/****   Updated 2009.Jul.16 (wardp) CR 375891: include support for SQL2K8                                  ****/
--/****   Updated 2009.Sep.17 (wardp) CR 399562: delete ErrorLogFilters if it exists                         ****/
--/****   Updated 2010.Apr.16 (wardp) bug 448114: SUBSTRING out of range in SQL2K                            ****/
--/****   Updated 2010.Apr.21 (wardp) bug 449079: gracefully handle stack dump and deadlock reports          ****/
--/****   Updated 2010.Jun.16 (wardp) bug 449079: suppress blank lines in output                             ****/
--/****   Updated 2010.Dec.22 (rajpo) bug 472178:  Fixed for non-English SQL instances                       ****/
--/****	  Updated 2011.Mar.09 (rajpo) bug 403282: Applid filters to readly only last 15 days entries         ****/
--/****	  Updated 2011.Apr.19 (rajpo) bug 475083:  Fixed the invalid column Event Date for SQL2K             ****/
--/****	  Updated 2011.Oct.17 (rajpo) bug 472178:  Added set for US english									 ****/
--/****    Copyright (c) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

set nocount on
SET LANGUAGE N'us_english'
use tempdb

declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));

declare @spid nvarchar(10)
select	@spid = @@spid

-- create the UDF to implement the filtering.
-- note this code is the same for all platforms..
IF OBJECT_ID('dbo.ErrorLogFilters') IS NOT NULL
BEGIN
    DROP TABLE dbo.ErrorLogFilters
END

CREATE TABLE dbo.ErrorLogFilters (
	ErrorLogFilterId int identity(1,1) PRIMARY KEY,
	ErrorLogFilter nvarchar(2000)
	)

exec(N'
create function dbo.udfErrorLogFilter' + @spid + N' (@errorlog_text nvarchar(2000))
    returns bit
as
begin

    declare @returnvalue bit
    if exists 
        (SELECT ErrorLogFilter
         FROM   dbo.ErrorLogFilters
         WHERE  @errorlog_text COLLATE Latin1_General_BIN LIKE ErrorLogFilter
        )
        set @returnvalue = 1
    else
        set @returnvalue = 0
    
    return (@returnvalue)
 end
')

 if  '10' = (select substring(@version, 1, 2)) -- CR 375891
     begin
     
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%This is an informational message%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Database backed up.%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Log was backed up.%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Database differential changes backed up%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%17824, Severity%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%17832, Severity%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%A network error was encountered while sending results to the front end%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Unable to read login packet%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%The specified network name is no longer available%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%109, The pipe has been ended.%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%232, The pipe is being closed%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%1608, Severity%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Unable to write to ListenOn connection%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Login failed%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Login succeeded%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Recovery progress on database ''distribution''%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%DBCC TRACEON 8510%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%DBCC TRACEON -1%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%mounted on tape drive%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%DBCC TRACEOFF 3604%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%DBCC TRACEON 3604%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%found 0 errors and repaired 0 errors%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Database backed up:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Log backed up:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%DBCC TRACEON 208%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%is full. Back up the transaction log%')
-- bug 358124			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Error: 9002%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Opening file%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Creating file%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Closing file%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Starting up database%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Recovery progress%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%transactions rolled%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%SQL server listening on TCP, Shared Memory, Named Pipes%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%SQL Server is ready for client connections%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Using dynamic lock allocation%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%SQL Server configured for thread mode processing%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Using ''SQLEVN70.DLL'' version%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Using ''OPENDS60.DLL'' version%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%VDI%')

			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('*')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('* *******************************************************************************')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('* -------------------------------------------------------------------------------')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Clearing tempdb database.')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%-d %:\%') 
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%-e %:\%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%-l %:\%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Logging SQL Server messages in file%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Registry startup parameters:')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('(c) 2005 Microsoft Corporation.')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('All rights reserved.')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Server process ID is%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Warning ******************')

			-- new for deadlocks
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES (' Requested By%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Node:')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Grant List%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Input Buf:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('TAB:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Victim Resource Owner%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Wait-for grap%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Owner:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%ResType:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%SPID:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%RID:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Wait List%')
    
			-- new for stack dumps
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('% 00') -- all hex lines end with a hard null
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('% Frame: %')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('eax=%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('esi=%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('ebp=%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('cs=%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Address=%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('AvailableVirtualMemory = %')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('TotalPhysicalMemory = %')

          exec(N'create table #sql_log_info_2005(log_number int,
                                               log_date   nvarchar(100),
                                               log_size   int)

              insert into #sql_log_info_2005 exec sp_enumerrorlogs 
              
              delete from #sql_log_info_2005 where DATEDIFF(dd,log_date,GETDATE()) > 15

              declare @sql_log_number_2005 int
              declare @cntr_2005           int
              declare @max_iterations_2005 int

              set @sql_log_number_2005 = 0
              set @cntr_2005 = 1
              
              select @max_iterations_2005 = count(log_number) + 1
              from #sql_log_info_2005

              create table #errorlog_scratch_2005(prog_id int identity(1,1),
									               log_date      datetime,
                                                   process_info  nvarchar(200),
                                                   errorlog_text nvarchar(4000),
                                                   sql_log_number int
                                                   primary key (prog_id))
              
              create index sqlrap_errorlog_chec_temp_index_1 on #errorlog_scratch_2005 (process_info)

			  create table #processed_records (prog_id int primary key,
												prog_id_plus_one int)
			  
              while @cntr_2005 < @max_iterations_2005
                    begin

                         insert into #errorlog_scratch_2005 (log_date, process_info, errorlog_text) EXEC sp_readerrorlog @sql_log_number_2005
                        ----Delete all the entries beyond 15 days----- 
                        
                         delete from #errorlog_scratch_2005 where DATEDIFF(dd,log_date,GETDATE()) >15
                         
                         UPDATE #errorlog_scratch_2005
                         SET	sql_log_number = @sql_log_number_2005
                         WHERE	sql_log_number IS NULL

                         set @sql_log_number_2005 = @sql_log_number_2005 + 1
               
                         set @cntr_2005 = @cntr_2005 + 1
                    end

            --	remove leading and trailing spaces from errorlog_text (eliminates need for leading wildcard in LIKE below)
            --	(not sure whether this is necessary but it''s a fine failsafe)

            update  #errorlog_scratch_2005
            set     errorlog_text = RTRIM(LTRIM(errorlog_text))

			-- populate the driver table.  we''ll use this table to drive the select statement
			-- note that the driver table is unfiltered; this way we don''t process those records twice

            insert #processed_records (prog_id, prog_id_plus_one)
            select e2.prog_id, e1.prog_id
            from #errorlog_scratch_2005 e1
            join #errorlog_scratch_2005 e2
            on e1.prog_id = e2.prog_id+1
            and e1.process_info = e2.process_info
            join
            (
              select  
                      e2.errorlog_text AS ErrorString,
                      e1.errorlog_text AS SpecificInstance,
                      count(1) AS NumberOfReports,
                      min(e1.log_date) AS FirstReport,
                      max(e1.log_date) AS MostRecentReport
              from    #errorlog_scratch_2005 e1
              join #errorlog_scratch_2005 e2
              on e1.prog_id = e2.prog_id+1
              and e1.process_info = e2.process_info
              where e2.errorlog_text COLLATE Latin1_General_BIN like N''Error:%Severity:%State:%''
              group by e2.errorlog_text, e1.errorlog_text
            ) Aggregates
            ON Aggregates.ErrorString = e2.errorlog_text
            AND Aggregates.SpecificInstance = e1.errorlog_text
            where e2.errorlog_text COLLATE Latin1_General_BIN like N''Error:%Severity:%State:%'' 

            select serverproperty(''machinename'') as ''Server Name'',
	            isnull(serverproperty(''instancename''),serverproperty(''machinename'')) as ''Instance Name'',
	            CASE WHEN e2.errorlog_text COLLATE Latin1_General_BIN not like N''Error:%Severity:%State:%''
	                THEN NULL
                    WHEN e2.errorlog_text COLLATE Latin1_General_BIN LIKE N''%1008(Userenv)%'' THEN ''1008''	                
					ELSE SUBSTRING(e2.errorlog_text,8,CHARINDEX(N'', '',e2.errorlog_text,1)-8)
					END
				as ''Event Id\Error Id'',
	            CASE WHEN e2.errorlog_text COLLATE Latin1_General_BIN like N''Error:%Severity:%State:%''
					THEN SUBSTRING(e2.errorlog_text,CHARINDEX(N''Severity:'',e2.errorlog_text,1),LEN(e2.errorlog_text)-CHARINDEX(N''Severity:'',e2.errorlog_text,1)+5)
					ELSE NULL
					END
				as ''Level'',
	            e1.errorlog_text as ''Error Description'',
	            (select top 1 text from master.sys.messages where message_id = CAST(SUBSTRING(e2.errorlog_text,8,CHARINDEX(N'', '',e2.errorlog_text,1)-8) as int)) as ''Generic Error Description'',
	            Aggregates.NumberOfReports as ''Number of Reports'',
	            Aggregates.FirstReport as ''First Report'',
	            Aggregates.MostRecentReport as ''Most Recent Report''
            from #processed_records pr
            join #errorlog_scratch_2005 e1
            on	 pr.prog_id_plus_one = e1.prog_id
            join #errorlog_scratch_2005 e2
            on pr.prog_id = e2.prog_id
            join
            (
              select  
                      e2.errorlog_text AS ErrorString,
                      e1.errorlog_text AS SpecificInstance,
                      count(1) AS NumberOfReports,
                      min(e1.log_date) AS FirstReport,
                      max(e1.log_date) AS MostRecentReport
              from    #errorlog_scratch_2005 e1
              join #errorlog_scratch_2005 e2
              on e1.prog_id = e2.prog_id+1
              and e1.process_info = e2.process_info
              where e2.errorlog_text COLLATE Latin1_General_BIN like N''Error:%Severity:%State:%''
              and tempdb.dbo.udfErrorLogFilter' + @spid + N'(e1.errorlog_text) = 0
              and tempdb.dbo.udfErrorLogFilter' + @spid + N'(e2.errorlog_text) = 0
              group by e2.errorlog_text, e1.errorlog_text
            ) Aggregates
            ON Aggregates.ErrorString = e2.errorlog_text
            AND Aggregates.SpecificInstance = e1.errorlog_text
            where e2.errorlog_text COLLATE Latin1_General_BIN like N''Error:%Severity:%State:%'' 
            and tempdb.dbo.udfErrorLogFilter' + @spid + N'(e1.errorlog_text) = 0
            and tempdb.dbo.udfErrorLogFilter' + @spid + N'(e2.errorlog_text) = 0

			union all

            select serverproperty(''machinename'') as ''Server Name'',
	            isnull(serverproperty(''instancename''),serverproperty(''machinename'')) as ''Instance Name'',
	            ''(n/a)'' as ''Event Id\Error Id'',
	            ''(n/a)'' as ''Level'',
	            CASE e1.errorlog_text 
					WHEN  N''Deadlock encountered .... Printing deadlock information''
					THEN ''Deadlock found in ERRORLOG #'' + CAST(e1.sql_log_number AS nvarchar) + CASE WHEN sql_log_number = 0 THEN N'' (current ERRORLOG)'' ELSE '''' END
					ELSE  e1.errorlog_text
				END as ''Error Description'',
	            CASE e1.errorlog_text 
					WHEN  N''Deadlock encountered .... Printing deadlock information''
					THEN ''Deadlock found in ERRORLOG #'' + CAST(e1.sql_log_number AS nvarchar) + CASE WHEN sql_log_number = 0 THEN N'' (current ERRORLOG)'' ELSE '''' END
					ELSE  e1.errorlog_text
				END as ''Generic Error Description'',
	            Aggregates.NumberOfReports as ''Number of Reports'',
	            Aggregates.FirstReport as ''First Report'',
	            Aggregates.MostRecentReport as ''Most Recent Report''
            from #errorlog_scratch_2005 e1
            join
            (
              select  e1.errorlog_text AS SpecificInstance,
                      count(1) AS NumberOfReports,
                      min(e1.log_date) AS FirstReport,
                      max(e1.log_date) AS MostRecentReport
              from    #errorlog_scratch_2005 e1
              where e1.prog_id not in (select prog_id from #processed_records)
              and   e1.prog_id not in (select prog_id_plus_one from #processed_records)
			-- delete the deadlock records
			  and	e1.prog_id not in
				(
					select prog_id 
					from #errorlog_scratch_2005 a 
					join
					(
						select log_date, process_info
						from #errorlog_scratch_2005 
						where errorlog_text = N''Deadlock encountered .... Printing deadlock information''
						or errorlog_text COLLATE Latin1_General_BIN like N''Node:%''
						or errorlog_text = N''deadlock-list''
					) b
					on a.log_date = b.log_date
					and a.process_info = b.process_info
					and a.errorlog_text != N''Deadlock encountered .... Printing deadlock information''
				)
              and tempdb.dbo.udfErrorLogFilter' + @spid + N'(e1.errorlog_text) = 0
              group by e1.errorlog_text
            ) Aggregates
            ON Aggregates.SpecificInstance = e1.errorlog_text
              where e1.prog_id not in (select prog_id from #processed_records union all select prog_id_plus_one from #processed_records)
              and tempdb.dbo.udfErrorLogFilter' + @spid + N'(e1.errorlog_text) = 0
			  and LEN(RTRIM(LTRIM(e1.errorlog_text))) >= 1

            order by ''Most Recent Report'' desc, ''Number of Reports'' desc, ''Event Id\Error Id'', ''Level'', ''Generic Error Description'', ''Error Description''

            select serverproperty(''machinename'') as ''Server Name'',
	            isnull(serverproperty(''instancename''),serverproperty(''machinename'')) as ''Instance Name'',
                min(log_date) as ''TimeStampOfOldestSQLErrorLogEntryCollected'',
                GETDATE() as ''CurrentLocalTimeOnServer'',
                DATEDIFF (hh,min(log_date),GETDATE())/24 as ''ErrorLogAgeInDays''
                from #errorlog_scratch_2005

             drop   table #errorlog_scratch_2005
             drop   table #sql_log_info_2005
             drop   table #processed_records
             drop   function udfErrorLogFilter' + @spid +N'
			')
                      
     end
 else -- CR 375891
 if  9 = (select substring(@version, 1, 1))  -- CR 375891
     begin
     
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%This is an informational message%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Database backed up.%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Log was backed up.%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Database differential changes backed up%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%17824, Severity%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%17832, Severity%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%A network error was encountered while sending results to the front end%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Unable to read login packet%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%The specified network name is no longer available%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%109, The pipe has been ended.%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%232, The pipe is being closed%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%1608, Severity%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Unable to write to ListenOn connection%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Login failed%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Login succeeded%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Recovery progress on database ''distribution''%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%DBCC TRACEON 8510%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%DBCC TRACEON -1%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%mounted on tape drive%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%DBCC TRACEOFF 3604%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%DBCC TRACEON 3604%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%found 0 errors and repaired 0 errors%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Database backed up:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Log backed up:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%DBCC TRACEON 208%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%is full. Back up the transaction log%')
-- bug 358124			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Error: 9002%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Opening file%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Creating file%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Closing file%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Starting up database%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Recovery progress%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%transactions rolled%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%SQL server listening on TCP, Shared Memory, Named Pipes%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%SQL Server is ready for client connections%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Using dynamic lock allocation%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%SQL Server configured for thread mode processing%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Using ''SQLEVN70.DLL'' version%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Using ''OPENDS60.DLL'' version%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%VDI%')

			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('*')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('* *******************************************************************************')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('* -------------------------------------------------------------------------------')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Clearing tempdb database.')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%-d %:\%') 
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%-e %:\%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%-l %:\%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Logging SQL Server messages in file%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Registry startup parameters:')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('(c) 2005 Microsoft Corporation.')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('All rights reserved.')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Server process ID is%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Warning ******************')
    
			-- new for deadlocks
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES (' Requested By%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Node:')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Grant List%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Input Buf:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('TAB:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Victim Resource Owner%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Wait-for grap%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Owner:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%ResType:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%SPID:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%RID:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Wait List%')

			-- new for stack dumps
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('% 00') -- all hex lines end with a hard null
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('% Frame: %')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('eax=%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('esi=%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('ebp=%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('cs=%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Address=%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('AvailableVirtualMemory = %')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('TotalPhysicalMemory = %')
    
          exec(N'create table #sql_log_info_2005(log_number int,
                                               log_date   nvarchar(100),
                                               log_size   int)

              insert into #sql_log_info_2005 exec sp_enumerrorlogs 
              delete from #sql_log_info_2005 where DATEDIFF(dd,log_date,GETDATE()) > 15

              declare @sql_log_number_2005 int
              declare @cntr_2005           int
              declare @max_iterations_2005 int

              set @sql_log_number_2005 = 0
              set @cntr_2005 = 1
              
              select @max_iterations_2005 = count(log_number) + 1
              from #sql_log_info_2005

              create table #errorlog_scratch_2005(prog_id int identity(1,1),
									               log_date      datetime,
                                                   process_info  nvarchar(200),
                                                   errorlog_text nvarchar(4000),
                                                   sql_log_number int
                                                   primary key (prog_id))
              
              create index sqlrap_errorlog_chec_temp_index_1 on #errorlog_scratch_2005 (process_info)

			  create table #processed_records (prog_id int primary key,
												prog_id_plus_one int)
			  
              while @cntr_2005 < @max_iterations_2005
                    begin

                         insert into #errorlog_scratch_2005 (log_date, process_info, errorlog_text) EXEC sp_readerrorlog @sql_log_number_2005
                         delete from #errorlog_scratch_2005 where  DATEDIFF(dd,log_date,GETDATE()) >15
                         
                         UPDATE #errorlog_scratch_2005
                         SET	sql_log_number = @sql_log_number_2005
                         WHERE	sql_log_number IS NULL

                         set @sql_log_number_2005 = @sql_log_number_2005 + 1
               
                         set @cntr_2005 = @cntr_2005 + 1
                    end

            --	remove leading and trailing spaces from errorlog_text (eliminates need for leading wildcard in LIKE below)
            --	(not sure whether this is necessary but it''s a fine failsafe)

            update  #errorlog_scratch_2005
            set     errorlog_text = RTRIM(LTRIM(errorlog_text))

			-- populate the driver table.  we''ll use this table to drive the select statement
			-- note that the driver table is unfiltered; this way we don''t process those records twice

            insert #processed_records (prog_id, prog_id_plus_one)
            select e2.prog_id, e1.prog_id
            from #errorlog_scratch_2005 e1
            join #errorlog_scratch_2005 e2
            on e1.prog_id = e2.prog_id+1
            and e1.process_info = e2.process_info
            join
            (
              select  
                      e2.errorlog_text AS ErrorString,
                      e1.errorlog_text AS SpecificInstance,
                      count(1) AS NumberOfReports,
                      min(e1.log_date) AS FirstReport,
                      max(e1.log_date) AS MostRecentReport
              from    #errorlog_scratch_2005 e1
              join #errorlog_scratch_2005 e2
              on e1.prog_id = e2.prog_id+1
              and e1.process_info = e2.process_info
              where e2.errorlog_text COLLATE Latin1_General_BIN like N''Error:%Severity:%State:%''
              group by e2.errorlog_text, e1.errorlog_text
            ) Aggregates
            ON Aggregates.ErrorString = e2.errorlog_text
            AND Aggregates.SpecificInstance = e1.errorlog_text
            where e2.errorlog_text COLLATE Latin1_General_BIN like N''Error:%Severity:%State:%'' 

            select serverproperty(''machinename'') as ''Server Name'',
	            isnull(serverproperty(''instancename''),serverproperty(''machinename'')) as ''Instance Name'',
	            CASE WHEN e2.errorlog_text COLLATE Latin1_General_BIN not like N''Error:%Severity:%State:%''
	                THEN NULL
                    WHEN e2.errorlog_text COLLATE Latin1_General_BIN LIKE N''%1008(Userenv)%'' THEN ''1008''	                
					ELSE SUBSTRING(e2.errorlog_text,8,CHARINDEX(N'', '',e2.errorlog_text,1)-8)
					END
				as ''Event Id\Error Id'',
	            CASE WHEN e2.errorlog_text COLLATE Latin1_General_BIN like N''Error:%Severity:%State:%''
					THEN SUBSTRING(e2.errorlog_text,CHARINDEX(N''Severity:'',e2.errorlog_text,1),LEN(e2.errorlog_text)-CHARINDEX(N''Severity:'',e2.errorlog_text,1)+5)
					ELSE NULL
					END
				as ''Level'',
	            e1.errorlog_text as ''Error Description'',
	            (select top 1 text from master.sys.messages where message_id = CAST(SUBSTRING(e2.errorlog_text,8,CHARINDEX(N'', '',e2.errorlog_text,1)-8) as int)) as ''Generic Error Description'',
	            Aggregates.NumberOfReports as ''Number of Reports'',
	            Aggregates.FirstReport as ''First Report'',
	            Aggregates.MostRecentReport as ''Most Recent Report''
            from #processed_records pr
            join #errorlog_scratch_2005 e1
            on	 pr.prog_id_plus_one = e1.prog_id
            join #errorlog_scratch_2005 e2
            on pr.prog_id = e2.prog_id
            join
            (
              select  
                      e2.errorlog_text AS ErrorString,
                      e1.errorlog_text AS SpecificInstance,
                      count(1) AS NumberOfReports,
                      min(e1.log_date) AS FirstReport,
                      max(e1.log_date) AS MostRecentReport
              from    #errorlog_scratch_2005 e1
              join #errorlog_scratch_2005 e2
              on e1.prog_id = e2.prog_id+1
              and e1.process_info = e2.process_info
              where e2.errorlog_text COLLATE Latin1_General_BIN like N''Error:%Severity:%State:%''
              and tempdb.dbo.udfErrorLogFilter' + @spid + N'(e1.errorlog_text) = 0
              and tempdb.dbo.udfErrorLogFilter' + @spid + N'(e2.errorlog_text) = 0
              group by e2.errorlog_text, e1.errorlog_text
            ) Aggregates
            ON Aggregates.ErrorString = e2.errorlog_text
            AND Aggregates.SpecificInstance = e1.errorlog_text
            where e2.errorlog_text COLLATE Latin1_General_BIN like N''Error:%Severity:%State:%'' 
            and tempdb.dbo.udfErrorLogFilter' + @spid + N'(e1.errorlog_text) = 0
            and tempdb.dbo.udfErrorLogFilter' + @spid + N'(e2.errorlog_text) = 0

			union all

            select serverproperty(''machinename'') as ''Server Name'',
	            isnull(serverproperty(''instancename''),serverproperty(''machinename'')) as ''Instance Name'',
	            ''(n/a)'' as ''Event Id\Error Id'',
	            ''(n/a)'' as ''Level'',
	            CASE e1.errorlog_text 
					WHEN  N''Deadlock encountered .... Printing deadlock information''
					THEN ''Deadlock found in ERRORLOG #'' + CAST(e1.sql_log_number AS nvarchar) + CASE WHEN sql_log_number = 0 THEN N'' (current ERRORLOG)'' ELSE '''' END
					ELSE  e1.errorlog_text
				END as ''Error Description'',
	            CASE e1.errorlog_text 
					WHEN  N''Deadlock encountered .... Printing deadlock information''
					THEN ''Deadlock found in ERRORLOG #'' + CAST(e1.sql_log_number AS nvarchar) + CASE WHEN sql_log_number = 0 THEN N'' (current ERRORLOG)'' ELSE '''' END
					ELSE  e1.errorlog_text
				END as ''Generic Error Description'',
	            Aggregates.NumberOfReports as ''Number of Reports'',
	            Aggregates.FirstReport as ''First Report'',
	            Aggregates.MostRecentReport as ''Most Recent Report''
            from #errorlog_scratch_2005 e1
            join
            (
              select  e1.errorlog_text AS SpecificInstance,
                      count(1) AS NumberOfReports,
                      min(e1.log_date) AS FirstReport,
                      max(e1.log_date) AS MostRecentReport
              from    #errorlog_scratch_2005 e1
              where e1.prog_id not in (select prog_id from #processed_records)
              and   e1.prog_id not in (select prog_id_plus_one from #processed_records)
			-- delete the deadlock records
			  and	e1.prog_id not in
				(
					select prog_id 
					from #errorlog_scratch_2005 a 
					join
					(
						select log_date, process_info
						from #errorlog_scratch_2005 
						where errorlog_text = N''Deadlock encountered .... Printing deadlock information''
						or errorlog_text COLLATE Latin1_General_BIN like N''Node:%''
						or errorlog_text = N''deadlock-list''
					) b
					on a.log_date = b.log_date
					and a.process_info = b.process_info
					and a.errorlog_text != N''Deadlock encountered .... Printing deadlock information''
				)
              and tempdb.dbo.udfErrorLogFilter' + @spid + N'(e1.errorlog_text) = 0
              group by e1.errorlog_text
            ) Aggregates
            ON Aggregates.SpecificInstance = e1.errorlog_text
              where e1.prog_id not in (select prog_id from #processed_records union select prog_id_plus_one from #processed_records)
              and tempdb.dbo.udfErrorLogFilter' + @spid + N'(e1.errorlog_text) = 0
			  and LEN(RTRIM(LTRIM(e1.errorlog_text))) >= 1

            order by ''Most Recent Report'' desc, ''Number of Reports'' desc, ''Event Id\Error Id'', ''Level'', ''Generic Error Description'', ''Error Description''

            select serverproperty(''machinename'') as ''Server Name'',
	            isnull(serverproperty(''instancename''),serverproperty(''machinename'')) as ''Instance Name'',
                min(log_date) as ''TimeStampOfOldestSQLErrorLogEntryCollected'',
                GETDATE() as ''CurrentLocalTimeOnServer'',
                DATEDIFF (hh,min(log_date),GETDATE())/24 as ''ErrorLogAgeInDays''
                from #errorlog_scratch_2005

             drop   table #errorlog_scratch_2005
             drop   table #sql_log_info_2005
             drop   table #processed_records
             drop   function udfErrorLogFilter' + @spid +N'
			')
                      
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin

 			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Database backed up with following information%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Log backed up with following information%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Database differential changes backed up%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%17824, Severity%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%17832, Severity%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%A network error was encountered while sending results to the front end%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Unable to read login packet%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%The specified network name is no longer available%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%109, The pipe has been ended.%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%232, The pipe is being closed%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%1608, Severity%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Unable to write to ListenOn connection%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Login failed%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Login succeeded%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Recovery progress on database ''distribution''%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%DBCC TRACEON 8510%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%DBCC TRACEON -1%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%mounted on tape drive%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%DBCC TRACEOFF 3604%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%DBCC TRACEON 3604%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%found 0 errors and repaired 0 errors%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Database backed up:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Log backed up:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%DBCC TRACEON 208%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%is full. Back up the transaction log%')
-- bug 358124			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Error: 9002%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Opening file%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Creating file%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Closing file%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Starting up database%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Recovery progress%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%transactions rolled%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%SQL server listening on TCP, Shared Memory, Named Pipes%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%SQL Server is ready for client connections%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Using dynamic lock allocation%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%SQL Server configured for thread mode processing%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Using ''SQLEVN70.DLL'' version%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Using ''OPENDS60.DLL'' version%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%VDI%')

			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Recovery complete')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Analysis of database%is 100%complete%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Clearing tempdb database')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('SQL Server is ready for client connection')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Server name is%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Attempting to initialize Distributed Transaction Coordinator')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('SQL Server is starting at priority class%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('All rights reserved')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Copyright (C) 1988-2002 Microsoft Corporation')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Copyright (c) 1988-2003 Microsoft Corporation')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Logging SQL Server messages in file%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Dec 16 2008 19:46:53 ')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Developer Edition on%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('%Enterprise Edition on%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Server Process ID is%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Using ''xplog70.dll'' version%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Using ''xpstar.dll'' version%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Using ''SSNETLIB.DLL'' version%')

			-- new for deadlocks
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES (' Requested By%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Node:')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES (' Grant List%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('  %Input Buf:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('TAB:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Victim Resource Owner%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Wait-for grap%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('  %Owner:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES (' %ResType:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('  %SPID:%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES (' %Wait List%')

			-- new for stack dumps
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('% 00') -- all hex lines end with a hard null
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('% Frame: %')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('eax=%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('esi=%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('ebp=%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('cs=%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('Address=%')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('AvailableVirtualMemory = %')
			INSERT dbo.ErrorLogFilters (ErrorLogFilter) VALUES ('TotalPhysicalMemory = %')

			EXEC('
              create table #sql_log_info_2000(log_number int,
                                               log_date   nvarchar(100),
                                               log_size   int)

              insert into #sql_log_info_2000 exec sp_enumerrorlogs
              
              delete from #sql_log_info_2000 where DATEDIFF(dd,log_date,GETDATE()) > 15

              declare @sql_log_number_2000 int
              declare @cntr_2000           int
              declare @max_iterations_2000 int

              set @sql_log_number_2000 = 0
              set @cntr_2000 = 1
              set @max_iterations_2000 = (select count(log_number) from #sql_log_info_2000) + 1

              create table #errorlog_scratch_2000( prog_id int identity (1,1) primary key,
                                                   errorlog_text    nvarchar(2000),
                                                   continuation_row int,
                                                    [Error Id] AS CASE 
                                                        WHEN errorlog_text COLLATE Latin1_General_BIN NOT LIKE N''%Error:%Severity:%State:%'' 
                                                            THEN CAST(NULL AS int)
                                                        WHEN errorlog_text COLLATE Latin1_General_BIN LIKE N''%1008(Userenv)%'' THEN 1008
                                                        ELSE CAST(substring(errorlog_text,41,PATINDEX(N''%,%'',errorlog_text)-41) AS int)
                                                        END,
                                                        [Event Date] AS CASE
														  WHEN errorlog_text COLLATE Latin1_General_BIN NOT LIKE N''[0123456789][0123456789][0123456789][0123456789]-[0123456789][0123456789]-[0123456789][0123456789] [0123456789][0123456789]:[0123456789][0123456789]:[0123456789][0123456789].[0123456789][0123456789]%'' 
															THEN NULL
                                                            ELSE CONVERT(datetime,LEFT(errorlog_text,22),121)
                                                        END,
                                                        [Error String] AS CAST(substring(errorlog_text,34,36) AS nvarchar(36)),
                                                        [Formatted Error Message] AS CASE
                                                          WHEN errorlog_text COLLATE Latin1_General_BIN LIKE N''Deadlock encountered%'' THEN ''Deadlock found in ERRORLOG #'' + CAST(sql_log_number AS nvarchar) + CASE WHEN sql_log_number = 0 THEN N'' (current ERRORLOG)'' ELSE '''' END
                                                          WHEN errorlog_text COLLATE Latin1_General_BIN LIKE N''%Stack Overflow%'' THEN ''Stack Overflow found in ERRORLOG #'' + CAST(sql_log_number AS nvarchar) + CASE WHEN sql_log_number = 0 THEN N'' (current ERRORLOG)'' ELSE '''' END
														  WHEN errorlog_text COLLATE Latin1_General_BIN LIKE N''[0123456789][0123456789][0123456789][0123456789]-[0123456789][0123456789]-[0123456789][0123456789] [0123456789][0123456789]:[0123456789][0123456789]:[0123456789][0123456789].[0123456789][0123456789]%'' 
															THEN CASE 
																	WHEN RIGHT(errorlog_text, 3) = N'' 00'' THEN SUBSTRING(errorlog_text,34,LEN(errorlog_text)-33) 
																	WHEN LEN(errorlog_text) >= 34 THEN SUBSTRING(errorlog_text,34,LEN(errorlog_text)-34) 
																	ELSE NULL 
																END -- bug 448114
															ELSE errorlog_text
														END,
														[Level] AS CASE
														     WHEN errorlog_text COLLATE Latin1_General_BIN like N''%Error:%Severity:%State:%''
																THEN SUBSTRING(errorlog_text,CHARINDEX(N''Severity:'',errorlog_text,1),LEN(e2.errorlog_text)-CHARINDEX(N''Severity:'',errorlog_text,1)+5)
															 ELSE NULL
															 END,
													    sql_log_number int
                                                        )

			  create table #processed_records (prog_id int primary key,
												prog_id_plus_one int)
			  

              while @cntr_2000 < @max_iterations_2000
                    begin

                         insert into #errorlog_scratch_2000 (errorlog_text, continuation_row) EXEC sp_readerrorlog @sql_log_number_2000
                         
                         delete from #sql_log_info_2000 where DATEDIFF(dd,[log_date] ,GETDATE()) > 15
                         
                         update #errorlog_scratch_2000
                         set sql_log_number = @sql_log_number_2000
                         where sql_log_number IS NULL

                         set @sql_log_number_2000 = @sql_log_number_2000 + 1
           
                         set @cntr_2000 = @cntr_2000 + 1
                    end

			  --create index qtest1 on #errorlog_scratch_2000([Error Id], [Event Date])
--select * from #errorlog_scratch_2000
--order by prog_id

			  insert #processed_records (prog_id, prog_id_plus_one)
              SELECT a.prog_id,
                     next_entry.prog_id
               FROM #errorlog_scratch_2000 a 
               JOIN #errorlog_scratch_2000 next_entry
               ON next_entry.prog_id = a.prog_id + 1
               AND  a.[Error Id] IS NOT NULL
               JOIN
                (
                  select  
                          min(e1.[Error String]) AS ErrorString,
                          min(e2.[Formatted Error Message]) AS SpecificInstance,
                          min(e1.[Error Id]) AS ErrorId,
                          count(1) AS NumberOfReports,
                          min(e1.[Event Date]) AS FirstReport,
                          max(e1.[Event Date]) AS MostRecentReport
                   FROM    #errorlog_scratch_2000 e1
                   FULL OUTER JOIN #errorlog_scratch_2000 e2
                   ON e2.prog_id = e1.prog_id + 1
                   WHERE  e1.[Error Id] IS NOT NULL
                   AND    e1.errorlog_text COLLATE Latin1_General_BIN like N''%Error:%Severity:%State:%'' 
                   GROUP BY e1.[Error Id], e2.[Formatted Error Message]
                ) Aggregates
                ON Aggregates.ErrorString = a.[Error String]
                AND Aggregates.SpecificInstance = next_entry.[Formatted Error Message]
               WHERE  a.[Error Id] IS NOT NULL
               AND    a.errorlog_text COLLATE Latin1_General_BIN like N''%Error:%Severity:%State:%'' 

			  insert #processed_records (prog_id, prog_id_plus_one)
              SELECT a.prog_id,
                     next_entry.prog_id
               FROM #errorlog_scratch_2000 a 
               JOIN #errorlog_scratch_2000 next_entry
               ON next_entry.prog_id = a.prog_id + 1
               JOIN
                (
                  select  
                          min(e1.[Formatted Error Message]) AS ErrorString,
                          min(e1.[Formatted Error Message]) AS SpecificInstance,
                          NULL AS ErrorId,
                          count(1) AS NumberOfReports,
                          min(e2.[Event Date]) AS FirstReport,
                          max(e2.[Event Date]) AS MostRecentReport
                   FROM    #errorlog_scratch_2000 e1
                   FULL OUTER JOIN #errorlog_scratch_2000 e2
                   ON e2.prog_id = e1.prog_id + 1
                   WHERE  e1.[Formatted Error Message] COLLATE Latin1_General_BIN like N''Deadlock found in ERRORLOG %'' 
                   GROUP BY e1.[Formatted Error Message]
                ) Aggregates
                ON Aggregates.ErrorString = a.[Formatted Error Message]
--                AND Aggregates.SpecificInstance = next_entry.[Formatted Error Message]
               WHERE  a.[Formatted Error Message] COLLATE Latin1_General_BIN like N''Deadlock found in ERRORLOG %'' 


              SELECT serverproperty(''machinename'')                                        as ''Server Name'',                                           
                     isnull(serverproperty(''instancename''),serverproperty(''machinename'')) as ''Instance Name'', 
                     CAST(a.[Error Id] as nvarchar)                                     as ''Event Id\Error Id'',
                     a.[Level]										      as ''Level'',
                     next_entry.[Formatted Error Message]											as ''Error Description'',
                    (select top 1 description from master..sysmessages where error = a.[Error Id]) as ''Generic Error Description'',
                     Aggregates.NumberOfReports                                               as ''Number of Reports'' ,
                     Aggregates.FirstReport             as ''First Report'',
                     Aggregates.MostRecentReport             as ''Most Recent Report''

				from #processed_records pr
				join #errorlog_scratch_2000 a
				on	 pr.prog_id = a.prog_id
				join #errorlog_scratch_2000 next_entry
				on pr.prog_id_plus_one = next_entry.prog_id
                AND  a.[Error Id] IS NOT NULL
               JOIN
                (
                  select  
                          min(e1.[Error String]) AS ErrorString,
                          min(e2.[Formatted Error Message]) AS SpecificInstance,
                          min(e1.[Error Id]) AS ErrorId,
                          count(1) AS NumberOfReports,
                          min(e1.[Event Date]) AS FirstReport,
                          max(e1.[Event Date]) AS MostRecentReport
                   FROM    #errorlog_scratch_2000 e1
                   FULL OUTER JOIN #errorlog_scratch_2000 e2
                   ON e2.prog_id = e1.prog_id + 1
                   WHERE  e1.[Error Id] IS NOT NULL
                   AND    e1.errorlog_text COLLATE Latin1_General_BIN like N''%Error:%Severity:%State:%'' 
		            and tempdb.dbo.udfErrorLogFilter' + @spid + N'(e1.errorlog_text) = 0
				    and tempdb.dbo.udfErrorLogFilter' + @spid + N'(e2.errorlog_text) = 0
                   GROUP BY e1.[Error Id], e2.[Formatted Error Message]
                ) Aggregates
                ON Aggregates.ErrorString = a.[Error String]
                AND Aggregates.SpecificInstance = next_entry.[Formatted Error Message]
            
               WHERE  a.[Error Id] IS NOT NULL
               AND    a.errorlog_text COLLATE Latin1_General_BIN like N''%Error:%Severity:%State:%'' 
               and    tempdb.dbo.udfErrorLogFilter' + @spid + N'(a.errorlog_text) = 0
               and    tempdb.dbo.udfErrorLogFilter' + @spid + N'(next_entry.errorlog_text) = 0

			union all

            select serverproperty(''machinename'') as ''Server Name'',
	            isnull(serverproperty(''instancename''),serverproperty(''machinename'')) as ''Instance Name'',
	            ''(n/a)'' as ''Event Id\Error Id'',
	            ''(n/a)'' as ''Level'',
	            e1.[Formatted Error Message] as ''Error Description'',
	            e1.[Formatted Error Message] as ''Generic Error Description'',
	            Aggregates.NumberOfReports as ''Number of Reports'',
	            Aggregates.FirstReport as ''First Report'',
	            Aggregates.MostRecentReport as ''Most Recent Report''
            from #errorlog_scratch_2000 e1
            join
            (
              select  e1.[Formatted Error Message] AS SpecificInstance,
                      count(1) AS NumberOfReports,
                      min(e1.[Event Date]) AS FirstReport,
                      max(e1.[Event Date]) AS MostRecentReport
              from    #errorlog_scratch_2000 e1
              where e1.prog_id not in (select prog_id from #processed_records)
              and   e1.prog_id not in (select prog_id_plus_one from #processed_records)
              and tempdb.dbo.udfErrorLogFilter' + @spid + N'(e1.[Formatted Error Message]) = 0
              group by e1.[Formatted Error Message]
            ) Aggregates
            ON Aggregates.SpecificInstance = e1.[Formatted Error Message]
              where e1.prog_id not in (select prog_id from #processed_records union select prog_id_plus_one from #processed_records)
              and tempdb.dbo.udfErrorLogFilter' + @spid + N'(e1.[Formatted Error Message]) = 0
              and Aggregates.FirstReport IS NOT NULL

			union all

              SELECT serverproperty(''machinename'')                                        as ''Server Name'',                                           
                     isnull(serverproperty(''instancename''),serverproperty(''machinename'')) as ''Instance Name'', 
                     ''(n/a)''                                     as ''Event Id\Error Id'',
                     ''(n/a)''										      as ''Level'',
                     a.[Formatted Error Message]											as ''Error Description'',
                     ''Deadlock found''										as ''Generic Error Description'',
                     Aggregates2.NumberOfReports                                               as ''Number of Reports'' ,
                     Aggregates2.FirstReport             as ''First Report'',
                     Aggregates2.MostRecentReport             as ''Most Recent Report''

				from #processed_records pr
				join #errorlog_scratch_2000 a
				on	 pr.prog_id = a.prog_id
				join #errorlog_scratch_2000 next_entry
				on pr.prog_id_plus_one = next_entry.prog_id
               JOIN
                (
                  select  
                          min(e1.[Formatted Error Message]) AS ErrorString,
                          min(e1.[Formatted Error Message]) AS SpecificInstance,
                          NULL AS ErrorId,
                          count(1) AS NumberOfReports,
                          min(e2.[Event Date]) AS FirstReport,
                          max(e2.[Event Date]) AS MostRecentReport
                   FROM    #errorlog_scratch_2000 e1
                   FULL OUTER JOIN #errorlog_scratch_2000 e2
                   ON e2.prog_id = e1.prog_id + 1
                   WHERE  e1.[Formatted Error Message] COLLATE Latin1_General_BIN like N''Deadlock found in ERRORLOG %'' 
                   GROUP BY e1.[Formatted Error Message]
                ) Aggregates2
                ON Aggregates2.ErrorString = a.[Formatted Error Message]
--                AND Aggregates2.SpecificInstance = next_entry.[Formatted Error Message]
               WHERE  a.[Formatted Error Message] COLLATE Latin1_General_BIN like N''Deadlock found in ERRORLOG %'' 
			  and LEN(RTRIM(LTRIM(a.errorlog_text))) >= 1

            order by ''Most Recent Report'' desc, ''Number of Reports'' desc, ''Event Id\Error Id'', ''Level'', ''Generic Error Description'', ''Error Description''

			-- report errorlog age
            select serverproperty(''machinename'') as ''Server Name'',
	            isnull(serverproperty(''instancename''),serverproperty(''machinename'')) as ''Instance Name'',
                min([Event Date]) as ''TimeStampOfOldestSQLErrorLogEntryCollected'',
                GETDATE() as ''CurrentLocalTimeOnServer'',
                DATEDIFF (hh,min([Event Date]),GETDATE())/24 as ''ErrorLogAgeInDays''
                from #errorlog_scratch_2000

              drop   table #errorlog_scratch_2000
              drop   table #sql_log_info_2000
              drop   table #processed_records
              drop   function dbo.udfErrorLogFilter' + @spid)
         end;
         
DROP TABLE dbo.ErrorLogFilters