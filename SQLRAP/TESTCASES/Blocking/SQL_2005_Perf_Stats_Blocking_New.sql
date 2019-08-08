--Signature="E89ACC58B26100A4" 

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****   Test case checks for Active Blocking in SQL Server 2005 instance                                   ****/
--/****   April 08 2009 rajpo Filtered the active queries to show only when blocking exists                  ****/
--/****   May 07 2009 rajpo Commented the messaged notable events and other messages                         ****/
--/****   Nov 03 2009 rajpo added wait duration column to output                                             ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright � Microsoft Corporation. All rights reserved.                                           ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/


--USE tempdb
--GO
SET NOCOUNT ON
SET QUOTED_IDENTIFIER ON
---GO
SET LANGUAGE us_english
--GO



DECLARE @servermajorversion int
DECLARE @BlockingFound nchar(1)

-- SERVERPROPERTY ('ProductVersion') returns e.g. "9.00.2198.00" --> 9
SET @servermajorversion = convert(int,REPLACE (LEFT (CONVERT (varchar, SERVERPROPERTY ('ProductVersion')), 2), '.', ''))

IF (@servermajorversion < 9)
  PRINT 'This script only runs on SQL Server 2005 and later. Exiting.'
ELSE 
	BEGIN
	
		DECLARE @msg varchar(100)
		DECLARE @querystarttime datetime
		DECLARE @queryduration int
		DECLARE @qrydurationwarnthreshold int
	  --DECLARE @servermajorversion int
		DECLARE @cpu_time_start bigint, @elapsed_time_start bigint
		DECLARE @sql nvarchar(max)
		DECLARE @cte nvarchar(max)
		DECLARE @rowcount bigint
		DECLARE @runtime datetime

		SELECT @cpu_time_start = cpu_time, @elapsed_time_start = total_elapsed_time FROM sys.dm_exec_requests WHERE session_id = @@SPID

		IF OBJECT_ID ('tempdb.dbo.#tmp_requests') IS NOT NULL DROP TABLE #tmp_requests
		IF OBJECT_ID ('tempdb.dbo.#tmp_requests2') IS NOT NULL DROP TABLE #tmp_requests2
	  
		IF @runtime IS NULL 
		BEGIN 
			SET @runtime = GETDATE()
			--SET @msg = 'Start time: ' + CONVERT (varchar(30), @runtime, 120)
			----RAISERROR (@msg, 0, 1) WITH NOWAIT rajpo 05/07/09 uncommented
		END
		
		SET @qrydurationwarnthreshold = 500
	  
	  -- SERVERPROPERTY ('ProductVersion') returns e.g. "9.00.2198.00" --> 9
		SET @servermajorversion = REPLACE (LEFT (CONVERT (varchar, SERVERPROPERTY ('ProductVersion')), 2), '.', '')

		--RAISERROR (@msg, 0, 1) WITH NOWAIT
		SET @querystarttime = GETDATE()
		SELECT
		sess.session_id, req.request_id, tasks.exec_context_id AS ecid, tasks.task_address, req.blocking_session_id, LEFT (tasks.task_state, 15) AS task_state, 
		tasks.scheduler_id, LEFT (ISNULL (req.wait_type, ''), 50) AS wait_type, LEFT (ISNULL (req.wait_resource, ''), 40) AS wait_resource, 
		LEFT (req.last_wait_type, 50) AS last_wait_type, 
		/* sysprocesses is the only way to get open_tran count for sessions w/o an active request (SQLBUD #487091) */
		CASE 
		  WHEN req.open_transaction_count IS NOT NULL THEN req.open_transaction_count 
		  ELSE (SELECT MAX(open_tran) FROM master.dbo.sysprocesses sysproc WHERE sess.session_id = sysproc.spid) 
		END AS open_trans, 
		LEFT (CASE COALESCE(req.transaction_isolation_level, sess.transaction_isolation_level)
		  WHEN 0 THEN '0-Read Committed' 
		  WHEN 1 THEN '1-Read Uncommitted (NOLOCK)' 
		  WHEN 2 THEN '2-Read Committed' 
		  WHEN 3 THEN '3-Repeatable Read' 
		  WHEN 4 THEN '4-Serializable' 
		  WHEN 5 THEN '5-Snapshot' 
		  ELSE CONVERT (varchar(30), req.transaction_isolation_level) + '-UNKNOWN' 
		END, 30) AS transaction_isolation_level, 
		sess.is_user_process, req.cpu_time AS request_cpu_time, 
		/* CASE stmts necessary to workaround SQLBUD #438189 (fixed in SP2) */
		CASE WHEN (@servermajorversion > 9) OR (@servermajorversion = 9 AND SERVERPROPERTY ('ProductLevel') >= 'SP2' COLLATE Latin1_General_BIN) 
		  THEN req.logical_reads ELSE req.logical_reads - sess.logical_reads END AS request_logical_reads, 
		CASE WHEN (@servermajorversion > 9) OR (@servermajorversion = 9 AND SERVERPROPERTY ('ProductLevel') >= 'SP2' COLLATE Latin1_General_BIN) 
		  THEN req.reads ELSE req.reads - sess.reads END AS request_reads, 
		CASE WHEN (@servermajorversion > 9) OR (@servermajorversion = 9 AND SERVERPROPERTY ('ProductLevel') >= 'SP2' COLLATE Latin1_General_BIN)
		  THEN req.writes ELSE req.writes - sess.writes END AS request_writes, 
		sess.memory_usage, sess.cpu_time AS session_cpu_time, sess.reads AS session_reads, sess.writes AS session_writes, sess.logical_reads AS session_logical_reads, 
		sess.total_scheduled_time, sess.total_elapsed_time, sess.last_request_start_time, sess.last_request_end_time, sess.row_count AS session_row_count, 
		sess.prev_error, req.open_resultset_count AS open_resultsets, req.total_elapsed_time AS request_total_elapsed_time, 
		CONVERT (decimal(5,2), req.percent_complete) AS percent_complete, req.estimated_completion_time AS est_completion_time, req.transaction_id, 
		req.start_time AS request_start_time, LEFT (req.status, 15) AS request_status, req.command, req.plan_handle, req.sql_handle, req.statement_start_offset, 
		req.statement_end_offset, req.database_id, req.[user_id], req.executing_managed_code, tasks.pending_io_count, sess.login_time, 
		LEFT (sess.[host_name], 20) AS [host_name], LEFT (ISNULL (sess.program_name, ''), 50) AS program_name, ISNULL (sess.host_process_id, 0) AS host_process_id, 
		ISNULL (sess.client_version, 0) AS client_version, LEFT (ISNULL (sess.client_interface_name, ''), 30) AS client_interface_name, 
		LEFT (ISNULL (sess.login_name, ''), 30) AS login_name, LEFT (ISNULL (sess.nt_domain, ''), 30) AS nt_domain, LEFT (ISNULL (sess.nt_user_name, ''), 20) AS nt_user_name, 
		ISNULL (conn.net_packet_size, 0) AS net_packet_size, LEFT (ISNULL (conn.client_net_address, ''), 20) AS client_net_address, conn.most_recent_sql_handle, 
		LEFT (sess.status, 15) AS session_status
		/* sys.dm_os_workers and sys.dm_os_threads removed due to perf impact, no predicate pushdown (SQLBU #488971) */
		--  workers.is_preemptive,
		--  workers.is_sick, 
		--  workers.exception_num AS last_worker_exception, 
		--  convert (varchar (20), master.dbo.fn_varbintohexstr (workers.exception_address)) AS last_exception_address
		--  threads.os_thread_id 
		INTO #tmp_requests
		FROM sys.dm_exec_sessions sess 
		/* Join hints are required here to work around bad QO join order/type decisions (ultimately by-design, caused by the lack of accurate DMV card estimates) */
		LEFT OUTER MERGE JOIN sys.dm_exec_requests req  ON sess.session_id = req.session_id
		LEFT OUTER MERGE JOIN sys.dm_os_tasks tasks ON tasks.session_id = sess.session_id AND tasks.request_id = req.request_id 
		/* The following two DMVs removed due to perf impact, no predicate pushdown (SQLBU #488971) */
		--  LEFT OUTER MERGE JOIN sys.dm_os_workers workers ON tasks.worker_address = workers.worker_address
		--  LEFT OUTER MERGE JOIN sys.dm_os_threads threads ON workers.thread_address = threads.thread_address
		LEFT OUTER MERGE JOIN sys.dm_exec_connections conn on conn.session_id = sess.session_id
		WHERE 
		/* Get execution state for all active queries... */
		(req.session_id IS NOT NULL AND (sess.is_user_process = 1 OR req.status COLLATE Latin1_General_BIN NOT IN ('background', 'sleeping')))
		/* ... and also any head blockers, even though they may not be running a query at the moment. */
		OR (sess.session_id IN (SELECT DISTINCT blocking_session_id FROM sys.dm_exec_requests WHERE blocking_session_id != 0))
		/* redundant due to the use of join hints, but added here to suppress warning message */
		OPTION (FORCE ORDER)  
		SET @rowcount = @@ROWCOUNT
		SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
		IF @queryduration > @qrydurationwarnthreshold
			PRINT 'DebugPrint: perfstats qry1 - ' + CONVERT (varchar, @queryduration) + 'ms, rowcount=' + CONVERT(varchar, @rowcount) + CHAR(13) + CHAR(10)

		--IF NOT EXISTS (SELECT * FROM #tmp_requests WHERE session_id <> @@SPID AND ISNULL (host_name, '') != @appname) BEGIN
		--PRINT 'No active queries'
		--END
		--ELSE BEGIN
		-- There are active queries (other than this one). 
		-- This query could be collapsed into the query above.  It is broken out here to avoid an excessively 
		-- large memory grant due to poor cardinality estimates (see previous bugs -- ultimate cause is the 
		-- lack of good stats for many DMVs). 
		SET @querystarttime = GETDATE()
		SELECT 
		  IDENTITY (int,1,1) AS tmprownum, 
		  r.session_id, r.request_id, r.ecid, r.blocking_session_id, ISNULL (waits.blocking_exec_context_id, 0) AS blocking_ecid, 
		  r.task_state, r.wait_type, ISNULL (waits.wait_duration_ms, 0) AS wait_duration_ms, r.wait_resource, 
		  LEFT (ISNULL (waits.resource_description, ''), 140) AS resource_description, r.last_wait_type, r.open_trans, 
		  r.transaction_isolation_level, r.is_user_process, r.request_cpu_time, r.request_logical_reads, r.request_reads, 
		  r.request_writes, r.memory_usage, r.session_cpu_time, r.session_reads, r.session_writes, r.session_logical_reads, 
		  r.total_scheduled_time, r.total_elapsed_time, r.last_request_start_time, r.last_request_end_time, r.session_row_count, 
		  r.prev_error, r.open_resultsets, r.request_total_elapsed_time, r.percent_complete, r.est_completion_time, 
		  -- r.tran_name, r.transaction_begin_time, r.tran_type, r.tran_state, 
		  LEFT (COALESCE (reqtrans.name, sesstrans.name, ''), 24) AS tran_name, 
		  COALESCE (reqtrans.transaction_begin_time, sesstrans.transaction_begin_time) AS transaction_begin_time, 
		  LEFT (CASE COALESCE (reqtrans.transaction_type, sesstrans.transaction_type)
			WHEN 1 THEN '1-Read/write'
			WHEN 2 THEN '2-Read only'
			WHEN 3 THEN '3-System'
			WHEN 4 THEN '4-Distributed'
			ELSE CONVERT (varchar(30), COALESCE (reqtrans.transaction_type, sesstrans.transaction_type)) + '-UNKNOWN' 
		  END, 15) AS tran_type, 
		  LEFT (CASE COALESCE (reqtrans.transaction_state, sesstrans.transaction_state)
			WHEN 0 THEN '0-Initializing'
			WHEN 1 THEN '1-Initialized'
			WHEN 2 THEN '2-Active'
			WHEN 3 THEN '3-Ended'
			WHEN 4 THEN '4-Preparing'
			WHEN 5 THEN '5-Prepared'
			WHEN 6 THEN '6-Committed'
			WHEN 7 THEN '7-Rolling back'
			WHEN 8 THEN '8-Rolled back'
			ELSE CONVERT (varchar(30), COALESCE (reqtrans.transaction_state, sesstrans.transaction_state)) + '-UNKNOWN'
		  END, 15) AS tran_state, 
		  r.request_start_time, r.request_status, r.command, r.plan_handle, r.sql_handle, r.statement_start_offset, 
		  r.statement_end_offset, r.database_id, r.[user_id], r.executing_managed_code, r.pending_io_count, r.login_time, 
		  r.[host_name], r.program_name, r.host_process_id, r.client_version, r.client_interface_name, r.login_name, r.nt_domain, 
		  r.nt_user_name, r.net_packet_size, r.client_net_address, r.most_recent_sql_handle, r.session_status, r.scheduler_id
		  -- r.is_preemptive, r.is_sick, r.last_worker_exception, r.last_exception_address, 
		  -- r.os_thread_id
		INTO #tmp_requests2
		FROM #tmp_requests r
		/* Join hints are required here to work around bad QO join order/type decisions (ultimately by-design, caused by the lack of accurate DMV card estimates) */
		/* Perf: no predicate pushdown on sys.dm_tran_active_transactions (SQLBU #489000) */
		LEFT OUTER MERGE JOIN sys.dm_tran_active_transactions reqtrans ON r.transaction_id = reqtrans.transaction_id
		/* No predicate pushdown on sys.dm_tran_session_transactions (SQLBU #489000) */
		LEFT OUTER MERGE JOIN sys.dm_tran_session_transactions sessions_transactions on sessions_transactions.session_id = r.session_id
		/* No predicate pushdown on sys.dm_tran_active_transactions (SQLBU #489000) */
		LEFT OUTER MERGE JOIN sys.dm_tran_active_transactions sesstrans ON sesstrans.transaction_id = sessions_transactions.transaction_id
		/* Suboptimal perf: see SQLBUD #449144. But we have to handle this in qry3 instead of here to avoid SQLBUD #489109. */
		LEFT OUTER MERGE JOIN sys.dm_os_waiting_tasks waits ON waits.waiting_task_address = r.task_address 
		ORDER BY r.session_id, blocking_ecid
		/* redundant due to the use of join hints, but added here to suppress warning message */
		OPTION (FORCE ORDER)  
		
		SET @rowcount = @@ROWCOUNT
		SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
		IF @queryduration > @qrydurationwarnthreshold
		  PRINT 'DebugPrint: perfstats qry2 - ' + CONVERT (varchar, @queryduration) + 'ms, rowcount=' + CONVERT(varchar, @rowcount) + CHAR(13) + CHAR(10)

		/* This index typically takes <10ms to create, and drops the head blocker summary query cost from ~250ms CPU down to ~20ms. */
		CREATE NONCLUSTERED INDEX idx1 ON #tmp_requests2 (blocking_session_id, session_id, wait_type, wait_duration_ms)
	    
		set @BlockingFound ='Y' ---rajpo added to eliminate notable events when no blocking found
		/* Resultset #2: Head blocker summary */
		/* Intra-query blocking relationships (parallel query waits) aren't "true" blocking problems that we should report on here. */
		IF NOT EXISTS (SELECT * FROM #tmp_requests2 WHERE blocking_session_id != 0 AND wait_type NOT IN ('WAITFOR', 'EXCHANGE', 'CXPACKET') AND wait_duration_ms > 0) 
		BEGIN 
		  PRINT ''
		  set @BlockingFound ='N'
		 -- PRINT '-- No blocking detected --'
		 -- PRINT ''
		END
		ELSE BEGIN
		  PRINT ''
	      
		  --RAISERROR ('-- headblockersummary --', 0, 1) WITH NOWAIT;
		  /* We need stats like the number of spids blocked, max waittime, etc, for each head blocker.  Use a recursive CTE to 
		  ** walk the blocking hierarchy. Again, explicitly parameterized dynamic SQL used to allow optional collection direct  
		  ** to a database. */
		  SET @cte = '
		  WITH BlockingHierarchy (head_blocker_session_id, session_id, blocking_session_id, wait_type, wait_duration_ms, 
			wait_resource, statement_start_offset, statement_end_offset, plan_handle, sql_handle, most_recent_sql_handle, [Level]) 
		  AS (
			SELECT head.session_id AS head_blocker_session_id, head.session_id AS session_id, head.blocking_session_id, 
			  head.wait_type, head.wait_duration_ms, head.wait_resource, head.statement_start_offset, head.statement_end_offset, 
			  head.plan_handle, head.sql_handle, head.most_recent_sql_handle, 0 AS [Level]
			FROM #tmp_requests2 head
			WHERE (head.blocking_session_id IS NULL OR head.blocking_session_id = 0) 
			  AND head.session_id IN (SELECT DISTINCT blocking_session_id FROM #tmp_requests2 WHERE blocking_session_id != 0) 
			UNION ALL 
			SELECT h.head_blocker_session_id, blocked.session_id, blocked.blocking_session_id, blocked.wait_type, 
			  blocked.wait_duration_ms, blocked.wait_resource, h.statement_start_offset, h.statement_end_offset, 
			  h.plan_handle, h.sql_handle, h.most_recent_sql_handle, [Level] + 1
			FROM #tmp_requests2 blocked
			INNER JOIN BlockingHierarchy AS h ON h.session_id = blocked.blocking_session_id 
			WHERE h.wait_type COLLATE Latin1_General_BIN NOT IN (''EXCHANGE'', ''CXPACKET'') 
		  )'
		  SET @sql = '
		  SELECT ''1'' as RSNo
		  , serverproperty(''machinename'')                                        as ''Server Name'',                                           
                     isnull(serverproperty(''instancename''),serverproperty(''machinename'')) as ''Instance Name''
                     , CONVERT (varchar(30), @runtime, 120) AS runtime, 
			head_blocker_session_id, COUNT(*) AS blocked_task_count, SUM (ISNULL (wait_duration_ms, 0)) AS tot_wait_duration_ms, 
			LEFT (CASE 
			  WHEN wait_type LIKE ''LCK%'' COLLATE Latin1_General_BIN AND wait_resource LIKE ''%\[COMPILE\]%'' ESCAPE ''\'' COLLATE Latin1_General_BIN 
				THEN ''COMPILE ('' + ISNULL (wait_resource, '''') + '')'' 
			  WHEN wait_type LIKE ''LCK%'' COLLATE Latin1_General_BIN THEN ''LOCK BLOCKING'' 
			  WHEN wait_type LIKE ''PAGELATCH%'' COLLATE Latin1_General_BIN THEN ''PAGELATCH_* WAITS'' 
			  WHEN wait_type LIKE ''PAGEIOLATCH%'' COLLATE Latin1_General_BIN THEN ''PAGEIOLATCH_* WAITS'' 
			  ELSE wait_type
			END, 40) AS blocking_resource_wait_type, AVG (ISNULL (wait_duration_ms, 0)) AS avg_wait_duration_ms, MAX(wait_duration_ms) AS max_wait_duration_ms, 
			MAX ([Level]) AS max_blocking_chain_depth, 
			MAX (ISNULL (CONVERT (nvarchar(60), CASE 
			  WHEN sql.objectid IS NULL THEN NULL 
			  ELSE REPLACE (REPLACE (SUBSTRING (sql.[text], CHARINDEX (''CREATE '', CONVERT (nvarchar(512), SUBSTRING (sql.[text], 1, 1000)) COLLATE Latin1_General_BIN), 50) COLLATE Latin1_General_BIN, CHAR(10), '' ''), CHAR(13), '' '')
			END), '''')) AS head_blocker_proc_name, 
			MAX (ISNULL (sql.objectid, 0)) AS head_blocker_proc_objid, MAX (ISNULL (CONVERT (nvarchar(1000), REPLACE (REPLACE (SUBSTRING (sql.[text], ISNULL (statement_start_offset, 0)/2 + 1, 
			  CASE WHEN ISNULL (statement_end_offset, 8192) <= 0 THEN 8192 
			  ELSE ISNULL (statement_end_offset, 8192)/2 - ISNULL (statement_start_offset, 0)/2 END + 1) COLLATE Latin1_General_BIN, 
			CHAR(13), '' ''), CHAR(10), '' '')), '''')) AS stmt_text
			
		  FROM BlockingHierarchy
		  OUTER APPLY sys.dm_exec_sql_text (ISNULL (sql_handle, most_recent_sql_handle)) AS sql
		  WHERE blocking_session_id != 0 AND [Level] > 0
		  GROUP BY head_blocker_session_id, 
			LEFT (CASE 
			  WHEN wait_type LIKE ''LCK%'' COLLATE Latin1_General_BIN AND wait_resource LIKE ''%\[COMPILE\]%'' ESCAPE ''\'' COLLATE Latin1_General_BIN 
				THEN ''COMPILE ('' + ISNULL (wait_resource, '''') + '')'' 
			  WHEN wait_type LIKE ''LCK%'' COLLATE Latin1_General_BIN THEN ''LOCK BLOCKING'' 
			  WHEN wait_type LIKE ''PAGELATCH%'' COLLATE Latin1_General_BIN THEN ''PAGELATCH_* WAITS'' 
			  WHEN wait_type LIKE ''PAGEIOLATCH%'' COLLATE Latin1_General_BIN THEN ''PAGEIOLATCH_* WAITS'' 
			  ELSE wait_type
			END, 40) 
		  ORDER BY SUM (wait_duration_ms) DESC'
	      
		   SET @sql = @cte + @sql
		  SET @querystarttime = GETDATE();
		 
		  EXEC sp_executesql @sql, N'@runtime datetime', @runtime = @runtime
		  SET @rowcount = @@ROWCOUNT
		  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
		  RAISERROR ('', 0, 1) WITH NOWAIT
		  IF @queryduration > @qrydurationwarnthreshold
			PRINT 'DebugPrint: perfstats qry4 - ' + CONVERT (varchar, @queryduration) + 'ms, rowcount=' + CONVERT(varchar, @rowcount) + CHAR(13) + CHAR(10)
		END

		/* Resultset #3: inputbuffers and query stats for "expensive" queries, head blockers, and "first-tier" blocked spids */
		--PRINT ''
		--RAISERROR ('-- notableactivequeries --', 0, 1) WITH NOWAIT
		
		SET @sql = '
		SELECT DISTINCT TOP 500 ''2'' AS RSNo
		, serverproperty(''machinename'')                                        as ''Server Name'',                                           
                     isnull(serverproperty(''instancename''),serverproperty(''machinename'')) as ''Instance Name'',
		  CONVERT (varchar(30), @runtime, 120) AS runtime, r.session_id AS session_id, r.blocking_session_id As blocking_session_id, r.wait_resource, 
		  r.wait_type,r.wait_duration_ms, 
		   
		  
		  LEFT (CASE 
			WHEN pa.value=32767 THEN ''ResourceDb''
			ELSE ISNULL (DB_NAME (CONVERT (sysname, pa.value)), CONVERT (sysname, pa.value))
		  END, 40) AS dbname, 
		  sql.objectid AS objectid, 
		  CONVERT (nvarchar(60), CASE 
			WHEN sql.objectid IS NULL THEN NULL 
			ELSE REPLACE (REPLACE (SUBSTRING (sql.[text] COLLATE Latin1_General_BIN, CHARINDEX (''CREATE '', SUBSTRING (sql.[text] COLLATE Latin1_General_BIN, 1, 1000)), 50), CHAR(10), '' ''), CHAR(13), '' '')
		  END) AS procname, 
		  CONVERT (nvarchar(300), REPLACE (REPLACE (CONVERT (nvarchar(300), SUBSTRING (sql.[text], ISNULL (r.statement_start_offset, 0)/2 + 1, 
			  CASE WHEN ISNULL (r.statement_end_offset, 8192) <= 0 THEN 8192 
			  ELSE ISNULL (r.statement_end_offset, 8192)/2 - ISNULL (r.statement_start_offset, 0)/2 END + 1)) COLLATE Latin1_General_BIN, 
			CHAR(13), '' ''), CHAR(10), '' '')) AS stmt_text
		  
		FROM #tmp_requests2 r
		LEFT OUTER JOIN sys.dm_exec_query_stats stat ON r.plan_handle = stat.plan_handle AND stat.statement_start_offset = r.statement_start_offset
		OUTER APPLY sys.dm_exec_plan_attributes (r.plan_handle) pa
		OUTER APPLY sys.dm_exec_sql_text (ISNULL (r.sql_handle, r.most_recent_sql_handle)) AS sql
		OUTER APPLY sys.dm_exec_query_plan (stat.plan_handle) qp
		WHERE (pa.attribute = ''dbid'' COLLATE Latin1_General_BIN OR pa.attribute IS NULL) 
		--AND ISNULL (host_name, '''') != @appname 
		AND r.session_id != @@SPID 
		  AND ( 
			/* We do not want to pull inputbuffers for everyone. The conditions below determine which ones we will fetch. */
			(r.session_id IN (SELECT blocking_session_id FROM #tmp_requests2 WHERE blocking_session_id != 0)) -- head blockers
			OR (r.blocking_session_id IN (SELECT blocking_session_id FROM #tmp_requests2 WHERE blocking_session_id != 0)) -- "first-tier" blocked requests
			OR (LTRIM (r.wait_type) <> '''' OR r.wait_duration_ms > 500) -- waiting for some resource
			OR (r.open_trans > 5) -- possible orphaned transaction
			OR (r.request_total_elapsed_time > 25000) -- long-running query
			OR (r.request_logical_reads > 1000000 OR r.request_cpu_time > 3000) -- expensive (CPU) query
			OR (r.request_reads + r.request_writes > 5000 OR r.pending_io_count > 400) -- expensive (I/O) query
			OR (r.memory_usage > 25600) -- expensive (memory > 200MB) query
			-- OR (r.is_sick > 0) -- spinloop
		  )
		'
		
	    if @BlockingFound ='Y' --rajpo added this to eliminate notableevents when no blocking found.
		BEGIN

			SET @querystarttime = GETDATE()
			--EXEC sp_executesql @sql, N'@runtime datetime, @appname sysname', @runtime = @runtime, @appname = @appname
			EXEC sp_executesql @sql, N'@runtime datetime', @runtime = @runtime--, @appname = @appname
			SET @rowcount = @@ROWCOUNT
			RAISERROR ('', 0, 1) WITH NOWAIT
			SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
			IF @rowcount >= 500 PRINT 'WARNING: notableactivequeries output artificially limited to 500 rows'
			IF @queryduration > @qrydurationwarnthreshold
			 PRINT 'DebugPrint: perfstats qry5 - ' + CONVERT (varchar, @queryduration) + 'ms, rowcount=' + CONVERT(varchar, @rowcount) + CHAR(13) + CHAR(10)

	   

			RAISERROR ('', 0, 1) WITH NOWAIT
		END
	  --END

	  -- Raise a diagnostic message if we use much more CPU than normal (a typical execution uses <300ms)
	  DECLARE @cpu_time bigint, @elapsed_time bigint
	  SELECT @cpu_time = cpu_time - @cpu_time_start, @elapsed_time = total_elapsed_time - @elapsed_time_start FROM sys.dm_exec_requests WHERE session_id = @@SPID
	  IF (@elapsed_time > 2000 OR @cpu_time > 750)
		PRINT 'DebugPrint: perfstats tot - ' + CONVERT (varchar, @elapsed_time) + 'ms elapsed, ' + CONVERT (varchar, @cpu_time) + 'ms cpu' + CHAR(13) + CHAR(10)  
	
END

