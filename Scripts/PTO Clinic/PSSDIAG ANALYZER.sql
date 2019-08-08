SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Amit Banerjee
-- Create date: 26/11/2007
-- Description:	SQL Nexus Data Analyzer : This can be used to analyze SQL Nexus Data
-- =============================================
CREATE PROCEDURE usp_nexus_analyze 
	@attention int = 0,			-- For enabling attention analysis
	@blocking int = 0,			-- For blocking analysis
	@memory int = 0,			-- For memory analysis
	@longrunning int = 0		-- For long running queries analysis
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT OFF;
	DECLARE @data_share varchar(200)
	print '#################################### PSSDIAG ANALYZER #################################### '+char(13)

	-- Getting file share information here
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_IMPORTEDFILES]') AND type in (N'U'))
	BEGIN
		select @data_share='PSSDIAG WAS LOADED FROM:'+space(1)+substring(input_file_name,1,(charindex('output\',input_file_name)+6)) from dbo.tbl_IMPORTEDFILES
		print @data_share+char(13)
	END
    ELSE 
	BEGIN
		print '[tbl_IMPORTEDFILES] table not found'
	END

	-- Performing Attention Analysis

	IF (@attention = 1)
	BEGIN
		print '#################################### Attention Analysis ####################################'+char(13)
		print 'Batches that received an attention with their Normalized Query Text and MilliSecondsToAttention greater than 30,000 ms'+char(13) 
		IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ReadTrace].[vwCancelledBatches]') AND type in (N'V'))
		BEGIN 
				IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ReadTrace].[tblUniqueBatches]') AND type in (N'U'))
				BEGIN
					select 
					a.batchseq as [Batch Seq Num],
					c.dbid as [Database ID],
					a.session as [session],
					a.hashid as [HASH ID],
					a.batchstarttime as [Batch Start Time],
					a.attentiontime as [Attention Time],
					a.millisecondstoattention as [Milliseconds To Attention],
					b.NormText as [Normalized Query Text]
					from ReadTrace.vwCancelledBatches a,ReadTrace.tblUniqueBatches b,ReadTrace.tblBatches c
					where a.hashid = b.HashId
					and a.hashid = c.hashid
					and a.batchstarttime = c.starttime
					and a.millisecondstoattention > 30000
				END
				ELSE
				BEGIN
					print 'ReadTrace.tblUniqueBatches table not found'+char(13)
				END
		END
		ELSE
		BEGIN
			print 'ReadTrace.vwCancelledBatches view not found'+char(13)
		END
	END
	
	-- Performing Interesting Events Analysis Here
	print '#################################### Interesting Events Analysis ####################################'+char(13)
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ReadTrace].[tblUniqueBatches]') AND type in (N'U'))
	BEGIN
		select b.name  as [Event Name],count(*) as occurrences
		from ReadTrace.tblInterestingEvents a	
		inner join sys.trace_events b 
		on b.trace_event_id = a.EventID
		group by b.name
		order by occurrences desc
		
		-- Getting Event SubClass Information for the above interesting events with the help of event_cursor
		declare @eventname varchar(100)
		
		DECLARE event_cursor CURSOR FOR 
		select distinct(b.name) as EventName 
		from ReadTrace.tblInterestingEvents a	
		inner join sys.trace_events b 
		on b.trace_event_id = a.EventID

		OPEN event_cursor

		FETCH NEXT FROM event_cursor 
		INTO @eventname

		while (@@fetch_status = 0)
		begin
			print '~~~~~~~~~~~~~~ Event Drill Down for: '+@eventname+char(13)
			if (@eventname = 'Auto Stats')
			begin
				select dbid,
				case eventsubclass
					when 1 then 'Statistics created/updated synchronously.'
					when 2 then 'Asynchronous statistics update; job queued.'
					when 3 then 'Asynchronous statistics update; job starting.'
					when 4 then 'Asynchronous statistics update; job completed.'
					else 'Unknown'
				end as subclass_name
				,count(*) as occurrences
				from readtrace.tblinterestingevents 
				where eventid=58
				group by dbid,eventsubclass 
				order by dbid,occurrences desc
			end

			else if (@eventname = 'Exception')
			begin
				select a.dbid,(cast(b.error as varchar(10))+':'+b.description) as subclass_name,count(*)  as occurrences
				from ReadTrace.tblInterestingEvents a,sys.sysmessages b
				where a.eventid=33 and a.error=b.error and b.msglangid=1033
				group by b.description,b.error,a.dbid
				order by occurrences desc,a.dbid asc
			end

			else if (@eventname = 'Log File Auto Grow')
			begin
				select dbid,count(*) as occurrences
				from readtrace.tblinterestingevents 
				where eventid=93
				group by dbid,eventsubclass
				order by occurrences desc
			end

			else if (@eventname = 'Missing Column Statistics')
			begin
				select dbid,textdata as subclass_name,count(*) as occurrences
				from readtrace.tblinterestingevents 
				where eventid=79
				group by dbid,textdata
				order by occurrences desc
			end

			else if (@eventname = 'Attention')
			begin	
				print 'Attention drill down already done above'+char(13)
			end

			else
			begin
				select b.dbid,a.subclass_name,b.eventsubclass,count(*) as occurrences
				from sys.trace_subclass_values a,readtrace.tblinterestingevents b
				where b.eventid = (select trace_event_id from sys.trace_events where [name]=@eventname)
				and b.eventid=a.trace_event_id
				and a.trace_event_id = (select trace_event_id from sys.trace_events where [name]=@eventname)
				and a.subclass_value=b.eventsubclass
				group by b.dbid,a.subclass_name,b.eventsubclass
				order by occurrences desc
			end
			FETCH NEXT FROM event_cursor 
			INTO @eventname
		END -- End of cursor while loop
		CLOSE event_cursor
		DEALLOCATE event_cursor

	END
	ELSE 
	BEGIN
		print 'Readtrace.tblinterestingevents table not found'+char(13)
	END
	
	-- Checking for non-default sp_configure settings

	print '#################################### Non-default sp_configure values ####################################'+char(13)
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_spconfigure]') AND type in (N'U'))
	BEGIN
		create table #default_config_pss(config_name varchar(200),run_value varchar(20))
		
		insert into #default_config_pss values('Ad Hoc Distributed Queries',1)
		insert into #default_config_pss values('affinity I/O mask',0)
		insert into #default_config_pss values('affinity mask',0)
		insert into #default_config_pss values('Agent XPs',0)
		insert into #default_config_pss values('awe enabled',0)
		insert into #default_config_pss values('blocked process threshold',0)
		insert into #default_config_pss values('c2 audit mode',0)
		insert into #default_config_pss values('clr enabled',0)
		insert into #default_config_pss values('cost threshold for parallelism',5)
		insert into #default_config_pss values('cross db ownership chaining',0)
		insert into #default_config_pss values('cursor threshold',-1)
		insert into #default_config_pss values('Database Mail XPs',0)
		insert into #default_config_pss values('default full-text language',1033)
		insert into #default_config_pss values('default language',0)
		insert into #default_config_pss values('default trace enabled',1)
		insert into #default_config_pss values('disallow results from triggers',0)
		insert into #default_config_pss values('fill factor (%)',0)
		insert into #default_config_pss values('ft crawl bandwidth (max)',100)
		insert into #default_config_pss values('ft crawl bandwidth (min)',0)
		insert into #default_config_pss values('ft notify bandwidth (max)',100)
		insert into #default_config_pss values('ft notify bandwidth (min)',0)
		insert into #default_config_pss values('index create memory (KB)',0)
		insert into #default_config_pss values('in-doubt xact resolution',0)
		insert into #default_config_pss values('lightweight pooling',0)
		insert into #default_config_pss values('locks',0)
		insert into #default_config_pss values('max degree of parallelism',0)
		insert into #default_config_pss values('max full-text crawl range',4)
		insert into #default_config_pss values('max server memory (MB)',2147483647)
		insert into #default_config_pss values('max text repl size (B)',65536)
		insert into #default_config_pss values('max worker threads',0)
		insert into #default_config_pss values('media retention',0)
		insert into #default_config_pss values('min memory per query (KB)',1024)
		insert into #default_config_pss values('min server memory (MB)',8)
		insert into #default_config_pss values('nested triggers',1)
		insert into #default_config_pss values('network packet size (B)',4096)
		insert into #default_config_pss values('Ole Automation Procedures',0)
		insert into #default_config_pss values('open objects',0)
		insert into #default_config_pss values('PH timeout (s)',60)
		insert into #default_config_pss values('precompute rank',0)
		insert into #default_config_pss values('priority boost',0)
		insert into #default_config_pss values('query governor cost limit',0)
		insert into #default_config_pss values('query wait (s)',-1)
		insert into #default_config_pss values('recovery interval (min)',0)
		insert into #default_config_pss values('remote access',1)
		insert into #default_config_pss values('remote admin connections',0)
		insert into #default_config_pss values('remote login timeout (s)',20)
		insert into #default_config_pss values('remote proc trans',0)
		insert into #default_config_pss values('remote query timeout (s)',600)
		insert into #default_config_pss values('Replication XPs',0)
		insert into #default_config_pss values('scan for startup procs',0)
		insert into #default_config_pss values('server trigger recursion',1)
		insert into #default_config_pss values('set working set size',0)
		insert into #default_config_pss values('show advanced options',1)
		insert into #default_config_pss values('SMO and DMO XPs',1)
		insert into #default_config_pss values('SQL Mail XPs',1)
		insert into #default_config_pss values('transform noise words',0)
		insert into #default_config_pss values('two digit year cutoff',2049)
		insert into #default_config_pss values('user connections',0)
		insert into #default_config_pss values('user options',0)
		insert into #default_config_pss values('Web Assistant Procedures',0)
		insert into #default_config_pss values('xp_cmdshell',0)

		select a.[name],a.run_value
		from  dbo.tbl_SPCONFIGURE a,#default_config_pss b
		where a.[name]=b.config_name
		and cast (a.run_value as bigint) <> cast (b.run_value as bigint)
		
		drop table #default_config_pss
	END	

	ELSE 
	BEGIN
		print 'sp_configure was not imported into SQL Nexus'+char(13)
	END
	
	-- Blocking analysis
	if (@blocking = 1)
	
	begin
		print '#################################### Blocking Analysis ####################################'+char(13)
		if (object_id('tbl_BLOCKING_CHAINS') is not null)
		begin
			print '~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Blocking Information '
			select head_blocker_session_id,head_blocker_session_id_orig,blocking_wait_type,max_blocked_task_count as blk_count,
			(datepart(ms,(blocking_end-blocking_start))+
			datepart(s,(blocking_end-blocking_start))*1000+
			datepart(mi,(blocking_end-blocking_start))*1000*60) as [blk_duration(ms)]
			from dbo.tbl_BLOCKING_CHAINS
			order by blk_count desc

			print '~~~~~~~~~~~~~~~~~~~~~~~~~~~ Different blocking types and their count '
			select blocking_wait_type,count(*) as occurrences
			from dbo.tbl_BLOCKING_CHAINS
			group by blocking_wait_type
		end 
		if (object_id('tbl_SYSPROCESSES') is not null)
		begin	
			print '~~~~~~~~~~~~~~~ Sysprocesses output for blocked column having non-zero value'
			select * 
			from tbl_sysprocesses 
			where blocked <> 0
			order by waittime desc
			print '~~~~~~~~~~~~~~~ Different CMDs running as per Sysprocesses during data capture'
			select cmd,count(*) as [count]
			from tbl_sysprocesses 
			group by cmd
			order by [count] desc
			print '~~~~~~~~~~~~~~~ Sum of last waittypes for processes as per Sysprocesses during data capture'
			select lastwaittype,count(*) as [count]
			from tbl_sysprocesses 
			group by lastwaittype
			order by [count] desc
		end
		if (object_id('tbl_OS_WAIT_STATS') is not null)
		begin
			print '~~~~~~~~~~~~~~~~ TOP 10 waittype rollup w.r.t. Sum of waittimes'
			select TOP 10 wait_type, sum(waiting_tasks_count) as task_wait_count,sum(wait_time_ms) as sum_wait_time_ms,sum(wait_time_ms)/sum(waiting_tasks_count) as avg_wait_time_ms
			from dbo.tbl_OS_WAIT_STATS
			group by wait_type
			order by sum_wait_time_ms desc
		end
		if (object_id('tbl_WAITSTATS') is not null)
		begin
			print '~~~~~~~~~~~~~~~~ TOP 10 waittypes rollup w.r.t. Sum of waittimes'
			select TOP 10 [wait type], sum([wait time]) as sum_wait_time,sum([wait time])/(sum(requests)+1) as avg_wait_time
			from dbo.tbl_WAITSTATS
			where [wait type] <> 'Total'
			group by [wait type]
			order by avg_wait_time desc
		end
	end
	
	-- Indexes and Statitics rollup
	if (object_id('tbl_sysindexes') is not null and object_id ('tbl_sysobjects') is not null)
	begin
			print '#################################### Database Statistics Information ####################################'+char(13)
			select  TOP 20 a.dbid as dbid,a.indid as indexid,a.name as objectname,b.name as table_name,a.dpages as dpages,a.rowcnt as rowcnt,a.rowmodctr as rowmodctr
			from tbl_sysindexes a, tbl_sysobjects b
			where a.id=b.id
			and a.rowmodctr > 10000
			order by a.rowmodctr desc
	end
	
	if (@memory=1)
	begin
		if (object_id('tbl_DM_OS_MEMORY_CLERKS') is not null)
			begin
				print '#################################### Memory DMV data rollup ####################################'
				print '~~~~~~~~~~~~~~~~~~~~~~~ Memory status analysis for sys.DM_OS_MEMORY_CLERK DMV output'+char(13)
				select type,name,
				min(single_pages_kb) as single_pages_kb_min,
				min(multi_pages_kb) as multi_pages_kb_min,
				min(virtual_memory_reserved_kb) as virtual_memory_reserved_kb_min,
				min(awe_allocated_kb) as awe_allocated_kb_min,
				min(virtual_memory_committed_kb) as virtual_memory_committed_kb_min,
				avg(single_pages_kb) as single_pages_kb_avg,
				avg(multi_pages_kb) as multi_pages_kb_avg,
				avg(virtual_memory_reserved_kb) as virtual_memory_reserved_kb_avg,
				avg(awe_allocated_kb) as awe_allocated_kb_avg,
				avg(virtual_memory_committed_kb) as virtual_memory_committed_kb_avg,
				max(single_pages_kb) as single_pages_kb_max,
				max(multi_pages_kb) as multi_pages_kb_max,
				max(virtual_memory_reserved_kb) as virtual_memory_reserved_kb_max,
				max(awe_allocated_kb) as awe_allocated_kb_max,
				max(virtual_memory_committed_kb) as virtual_memory_committed_kb_max
				from dbo.tbl_DM_OS_MEMORY_CLERKS
				group by type,name
				order by avg(single_pages_kb) desc
		end

		if (object_id('tbl_DM_OS_MEMORY_CACHE_COUNTERS') is not null)
		begin
				print '~~~~~~~~~~~~~~~~~~~ Memory status analysis for sys.DM_OS_MEMORY_CACHE_COUNTERS DMV output'+char(13)
				select type,name,
				min(single_pages_kb) as single_pages_kb_min,
				min(multi_pages_kb) as multi_pages_kb_min,
				min(single_pages_in_use_kb) as single_pages_in_use_kb_min,
				min(multi_pages_in_use_kb) as multi_pages_in_use_kb_min,
				min(entries_in_use_count) as entries_in_use_count_min,
				avg(single_pages_kb) as single_pages_kb_avg,
				avg(multi_pages_kb) as multi_pages_kb_avg,
				avg(single_pages_in_use_kb) as single_pages_in_use_kb_avg,
				avg(multi_pages_in_use_kb) as multi_pages_in_use_kb_avg,
				avg(entries_in_use_count) as entries_in_use_count_avg,
				max(single_pages_kb) as single_pages_kb_max,
				max(multi_pages_kb) as multi_pages_kb_max,
				max(single_pages_in_use_kb) as single_pages_in_use_kb_max,
				max(multi_pages_in_use_kb) as multi_pages_in_use_kb_max,
				max(entries_in_use_count) as entries_in_use_count_max				
				from dbo.tbl_DM_OS_MEMORY_CACHE_COUNTERS
				group by type,name
				order by avg(single_pages_kb) desc
		end
	end
	
	-- Long running batch and statement analysis
	if(@longrunning = 1)
	begin
		if (object_id('readtrace.tblbatches') is not null and object_id('ReadTrace.tblUniqueBatches') is not null) 
		print '#################################### Long Running Batch Analysis ####################################'
		begin
			 declare @TotalCPU decimal
			 declare @TotalReads decimal
			 declare @TotalWrites decimal
			 declare @TotalDuration decimal

			print replicate ('*',150)
			Print '                                            Analyzing Batches'
			Print replicate ('*',150)
			 
			select 	@TotalCPU = sum(isnull (TotalCPU,0)) ,
				@TotalReads = sum(isnull (TotalReads,0)), 
				@TotalWrites = sum(isnull (TotalWrites,0)), 
				@TotalDuration = sum(isnull (TotalDuration,0)) 
			from readtrace.tblbatchPartialAggs

			select
			  b.HashId as HashId,
			  cast(b.NormText as varchar(200)) as NormText,
			  Sum(CompletedEvents) as Executes,
			  sum(isnull (TotalCPU,0)) as TotalCPU,
			  sum(isnull (TotalDuration,0)) as TotalDuration,
			  sum(isnull (TotalReads,0)) as TotalReads, 
			  sum(isnull (TotalWrites,0)) as TotalWrites, 
			  cast(sum(isnull (TotalCPU,0))as float )/@TotalCPU * 100 as PercentCPU, 
			  cast(sum(isnull (TotalReads,0))as float )/@TotalReads * 100 as PercentReads,
			  cast(sum(isnull (TotalWrites,0))as float )/@TotalWrites * 100 as PercentWrites, 
			  cast(sum(isnull (TotalDuration,0))as float )/@TotalDuration * 100 as PercentDuration 
			into #Batches 
			from readtrace.tblbatchPartialAggs a  inner join  readtrace.tblUniqueBatches b  on a.HashId = b.HashId
			group by b.HashId,cast(b.NormText as varchar(200))

			Print replicate ('*',150)
			Print '                                            Top CPU Batches'
			Print replicate ('*',150)
			select Top 20 * from #Batches order by PercentCPU desc

			Print replicate ('*',150)
			Print '                                            Top Reads Batches'
			Print replicate ('*',150)
			select Top 20 * from #Batches order by PercentReads desc

			Print replicate ('*',150)
			Print '                                            Top Writes Batches'
			Print replicate ('*',150)
			select Top 20 * from #Batches order by PercentWrites desc

			Print replicate ('*',150)
			Print '                                            Top Duration Batches'
			Print replicate ('*',150)
			select Top 20 * from #Batches order by PercentDuration desc

			Print replicate ('*',150)
			Print '                                            Analyzing Statements'
			Print replicate ('*',150)


			select 	@TotalCPU = sum(isnull (TotalCPU,0)) ,
				@TotalReads = sum(isnull (TotalReads,0)), 
				@TotalWrites = sum(isnull (TotalWrites,0)), 
				@TotalDuration = sum(isnull (TotalDuration,0)) 
			from readtrace.tblStmtPartialAggs


			select
			  b.HashId as HashId,
			  cast(b.NormText as varchar(200)) as NormText,
			  Sum(CompletedEvents) as Executes,
			  sum(isnull (TotalCPU,0)) as TotalCPU,
			  sum(isnull (TotalDuration,0)) as TotalDuration,
			  sum(isnull (TotalReads,0)) as TotalReads, 
			  sum(isnull (TotalWrites,0)) as TotalWrites, 
			  cast(sum(isnull (TotalCPU,0))as float )/@TotalCPU * 100 as PercentCPU, 
			  cast(sum(isnull (TotalReads,0))as float )/@TotalReads * 100 as PercentReads,
			  cast(sum(isnull (TotalWrites,0))as float )/@TotalWrites * 100 as PercentWrites, 
			  cast(sum(isnull (TotalDuration,0))as float )/@TotalDuration * 100 as PercentDuration 
			into #Statements 
			from readtrace.tblStmtPartialAggs a  inner join  readtrace.tblUniqueStatements b  on a.HashId = b.HashId
			group by b.HashId,cast(b.NormText as varchar(200))

			Print replicate ('*',150)
			Print '                                            Top CPU Statements'
			Print replicate ('*',150)
			select Top 20 * from #Statements order by PercentCPU desc

			Print replicate ('*',150)
			Print '                                            Top Reads Statements'
			Print replicate ('*',150)
			select Top 20 * from #Statements order by PercentReads desc

			Print replicate ('*',150)
			Print '                                            Top Writes Statements'
			Print replicate ('*',150)
			select Top 20 * from #Statements order by PercentWrites desc

			Print replicate ('*',150)
			Print '                                            Top Duration Statements'
			Print replicate ('*',150)
			select Top 20 * from #Statements order by PercentDuration desc
			drop table #statements
			drop table #batches
		end
	end
		
	SET NOCOUNT OFF;
	SET XACT_ABORT ON;
END
GO


	