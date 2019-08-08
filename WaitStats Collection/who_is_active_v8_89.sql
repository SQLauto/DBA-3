USE master 
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_WhoIsActive')
	DROP PROC sp_WhoIsActive
GO

/*********************************************************************************************
Who Is Active? v8.89 (2009-09-15)
(C) 2007-2009, Adam Machanic

Feedback: mailto:amachanic@gmail.com
Updates: http://sqlblog.com/blogs/adam_machanic/archive/tags/who+is+active/default.aspx
"Beta" Builds: http://sqlblog.com/files/folders/beta/tags/who+is+active/default.aspx

License: 
	Who is Active? is free to download and use for personal, educational, and internal 
	corporate purposes, provided that this header is preserved. Redistribution or sale 
	of Who is Active?, in whole or in part, is prohibited without the author's express 
	written consent.
*********************************************************************************************/
CREATE PROC dbo.sp_WhoIsActive
(
--~
	--Set filter to '' to disable
	--Valid filter types are session, program, database, login, and host
	--Session is a session ID, and either 0 or '' can be used for all sessions
	--All other filter types support % or _ as wildcards
	@filter VARCHAR(128) = '',
	@filter_type VARCHAR(10) = 'session',

	--Show your own SPID?
	@show_own_spid BIT = 0,

	--If 1, gets the full stored procedure or running batch, when available
	--If 0, gets only the actual statement that is currently running in the batch or procedure
	@get_full_inner_text BIT = 0,

	--Get associated query plans for running tasks, if available
	--If @get_plans = 1, gets the plan based on the request's statement offset
	--If @get_plans = 2, gets the entire plan based on the request's plan_handle
	@get_plans TINYINT = 0,

	--Get the associated outer ad hoc query or stored procedure call, if available
	@get_outer_command BIT = 0,

	--Controls how sleeping SPIDs are handled, based on the idea of levels of interest
	--0 does not pull any sleeping SPIDs
	--1 pulls only those sleeping SPIDs that also have an open transaction
	--2 pulls all sleeping SPIDs
	@get_sleeping_spids TINYINT = 1,

	--Enables pulling transaction log write info and transaction duration
	@get_transaction_info BIT = 0,

	--Gets associated locks for each request, aggregated in an XML format
	@get_locks BIT = 0,

	--Get average time for past runs of an active query
	--(based on the combination of plan handle, sql handle, and offset)
	@get_avg_time BIT = 0,

	--Walk the blocking chain and count the number of 
	--total SPIDs blocked all the way down by a given session
	@find_block_leaders BIT = 0,
	
	--Pull deltas on various metrics
	--Interval in seconds to wait before doing the second data pull
	@delta_interval TINYINT = 0,

	--Column by which to sort output. Valid choices:
		--session_id, physical_io, reads, physical_reads, writes, tempdb_writes,
		--tempdb_current, CPU, context_switches, used_memory, physical_io_delta, 
		--reads_delta, physical_reads_delta, writes_delta, tempdb_writes_delta, 
		--tempdb_current_delta, CPU_delta, context_switches_delta, used_memory_delta, 
		--tasks, tran_start_time, open_tran_count, blocking_session_id, blocked_session_count,
		--percent_complete, host_name, login_name, database_name, start_time
	@sort_column VARCHAR(255) = '[start_time]',

	--Sort direction. Valid choices are ASC or DESC
	@sort_column_direction VARCHAR(4) = 'DESC',

	--Formats some of the output columns in a more "human readable" form
	--0 disables output format
	--1 formats the output for variable-width fonts
	--2 formats the output for fixed-width fonts
	@format_output TINYINT = 1,

	--List of desired output columns, in desired order
	--Note that the final output will be the intersection of all enabled features and all 
	--columns in the list. Therefore, only columns associated with enabled features will 
	--actually appear in the output. Likewise, removing columns from this list may effectively
	--disable features, even if they are turned on
	--
	--Each element in this list must be one of the valid output column names. Names must be
	--delimited by square brackets. White space, formatting, and additional characters are
	--allowed, as long as the list contains exact matches of delimited valid column names.
	@output_column_list VARCHAR(8000) = '[%]',
	
	--If set to a non-blank value, the script will attempt to insert into the specified 
	--destination table. Please note that the script will not verify that the table exists, 
	--or that it has the correct schema, before doing the insert.
	--Table can be specified in one, two, or three-part format
	@destination_table VARCHAR(4000) = '',

	--If set to 1, no data collection will happen and no result set will be returned; instead,
	--a CREATE TABLE statement will be returned via the @schema parameter, which will match 
	--the schema of the result set that would be returned by using the same collection of the
	--rest of the parameters. The CREATE TABLE statement will have a placeholder token of 
	--<table_name> in place of an actual table name.
	@return_schema BIT = 0,
	@schema VARCHAR(MAX) = NULL OUTPUT,
	
	@help BIT = 0
--~
)
/*
OUTPUT COLUMNS
--------------
Formatted/Non:	[session_id] [smallint] NOT NULL
	Session ID (a.k.a. SPID)

Formatted:		[dd hh:mm:ss.mss] [varchar](15) NULL
Non-Formatted:	<not returned>
	For an active request, time the query has been running
	For a sleeping session, time the session has been connected

Formatted:		[dd hh:mm:ss.mss (avg)] [varchar](15) NULL
Non-Formatted:	[avg_elapsed_time] [int] NULL
	(Requires @get_avg_time option)
	How much time has the active portion of the query taken in the past, on average?
	Note: This column's name becomes [avg_elapsed_time] in non-formatted mode

Formatted:		[physical_io] [varchar](30) NULL
Non-Formatted:	[physical_io] [bigint] NULL
	Shows the number of physical I/Os, for active requests

Formatted:		[reads] [varchar](30) NOT NULL
Non-Formatted:	[reads] [bigint] NOT NULL
	For an active request, number of reads done for the current query
	For a sleeping session, total number of reads done over the lifetime of the session

Formatted:		[physical_reads] [varchar](30) NOT NULL
Non-Formatted:	[physical_reads] [bigint] NOT NULL
	For an active request, number of physical reads done for the current query
	For a sleeping session, total number of physical reads done over the lifetime of the session

Formatted:		[writes] [varchar](30) NOT NULL
Non-Formatted:	[writes] [bigint] NOT NULL
	For an active request, number of writes done for the current query
	For a sleeping session, total number of writes done over the lifetime of the session

Formatted:		[tempdb_writes] [varchar](30) NOT NULL
Non-Formatted:	[tempdb_writes] [bigint] NOT NULL
	For an active request, number of TempDB writes done for the current query
	For a sleeping session, total number of TempDB writes done over the lifetime of the session

Formatted:		[tempdb_current] [varchar](30) NOT NULL
Non-Formatted:	[tempdb_current] [bigint] NOT NULL
	For an active request, number of TempDB pages currently allocated for the query
	For a sleeping session, number of TempDB pages currently allocated for the session

Formatted:		[CPU] [varchar](30) NOT NULL
Non-Formatted:	[CPU] [int] NOT NULL
	For an active request, total CPU time consumed by the current query
	For a sleeping session, total CPU time consumed over the lifetime of the session

Formatted:		[context_switches] [varchar](30) NULL
Non-Formatted:	[context_switches] [bigint] NULL
	Shows the number of context switches, for active requests

Formatted:		[used_memory] [varchar](30) NOT NULL
Non-Formatted:	[used_memory] [bigint] NOT NULL
	For an active request, total memory consumption for the current query
	For a sleeping session, total current memory consumption

Formatted:		[physical_io_delta] [varchar](30) NULL
Non-Formatted:	[physical_io_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of physical I/Os reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[reads_delta] [varchar](30) NULL
Non-Formatted:	[reads_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of reads reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[physical_reads_delta] [varchar](30) NULL
Non-Formatted:	[physical_reads_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of physical reads reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[writes_delta] [varchar](30) NULL
Non-Formatted:	[writes_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of writes reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[tempdb_writes_delta] [varchar](30) NULL
Non-Formatted:	[tempdb_writes_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of TempDB writes reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[tempdb_current_delta] [varchar](30) NULL
Non-Formatted:	[tempdb_current_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of allocated TempDB pages reported on the first and second 
	collections. If the request started after the first collection, the value will be NULL

Formatted:		[CPU_delta] [varchar](30) NULL
Non-Formatted:	[CPU_delta] [int] NULL
	(Requires @delta_interval option)
	Difference between the CPU time reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[context_switches_delta] [varchar](30) NULL
Non-Formatted:	[context_switches_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the context switches count reported on the first and second collections
	If the request started after the first collection, the value will be NULL

Formatted:		[used_memory_delta] [varchar](30) NULL
Non-Formatted:	[used_memory_delta] [bigint] NULL
	Difference between the memory usage reported on the first and second collections
	If the request started after the first collection, the value will be NULL

Formatted:		[tasks] [varchar](30) NULL
Non-Formatted:	[tasks] [smallint] NULL
	Number of worker tasks currently allocated, for active requests

Formatted/Non:	[status] [varchar](30) NOT NULL
	Activity status for the session (running, sleeping, etc)
	
Formatted/Non:	[wait_info] [varchar](4000) NULL
	Aggregates wait information, in the following format:
		(Ax: Bms/Cms/Dms)E
	A is the number of waiting tasks currently waiting on resource type E. B/C/D are wait
	times, in milliseconds. If only one thread is waiting, its wait time will be shown as B.
	If two tasks are waiting, each of their wait times will be shown (B/C). If three or more 
	tasks are waiting, the minimum, average, and maximum wait times will be shown (B/C/D).
	If wait type E is a page latch wait and the page is of a "special" type (e.g. PFS, GAM, SGAM), 
	the page type will be identified.
	
Formatted/Non:	[locks] [xml] NULL
	(Requires @get_locks option)
	Aggregates lock information, in XML format.
	The lock XML includes the lock mode, locked object, and aggregates the number of requests. 
	Attempts are made to identify locked objects by name

Formatted/Non:	[tran_start_time] [datetime] NULL
	(Requires @get_transaction_info option)
	Date and time that the first transaction opened by a session caused a transaction log 
	write to occur.

Formatted/Non:	[tran_log_writes] [varchar](4000) NULL
	(Requires @get_transaction_info option)
	Aggregates transaction log write information, in the following format:
	A:B
	A is a database that has been touched by an active transaction
	B is the number of log writes that have been made in the database as a result of the transaction

Formatted:		[open_tran_count] [varchar](30) NULL
Non-Formatted:	[open_tran_count] [int] NULL
	Shows the number of open transactions the session has open

Formatted:		[sql_command] [xml] NULL
Non-Formatted:	[sql_command] [varchar](max) NULL
	(Requires @get_outer_command option)
	Shows the "outer" SQL command, i.e. the text of the batch or RPC sent to the server, 
	if available

Formatted:		[sql_text] [xml] NULL
Non-Formatted:	[sql_text] [varchar](max) NULL
	Shows the SQL text for active requests or the last statement executed
	for sleeping sessions, if available in either case.
	If @get_full_inner_text option is set, shows the full text of the batch.
	Otherwise, shows only the active statement within the batch.
	If the query text is locked, a special timeout message will be sent, in the following format:
		<timeout_exceeded />
	If an error occurs, an error message will be sent, in the following format:
		<error message="message" />

Formatted/Non:	[query_plan] [xml] NULL
	(Requires @get_plans option)
	Shows the query plan for the request, if available.
	If the plan is locked, a special timeout message will be sent, in the following format:
		<timeout_exceeded />
	If an error occurs, an error message will be sent, in the following format:
		<error message="message" />

Formatted/Non:	[blocking_session_id] [smallint] NULL
	When applicable, shows the blocking SPID

Formatted:		[blocked_session_count] [varchar](30) NULL
Non-Formatted:	[blocked_session_count] [smallint] NULL
	(Requires @find_block_leaders option)
	The total number of SPIDs blocked by this session,
	all the way down the blocking chain.

Formatted:		[percent_complete] [varchar](30) NULL
Non-Formatted:	[percent_complete] [real] NULL
	When applicable, shows the percent complete (e.g. for backups, restores, and some rollbacks)

Formatted/Non:	[host_name] [varchar](128) NOT NULL
	Shows the host name for the connection

Formatted/Non:	[login_name] [varchar](128) NOT NULL
	Shows the login name for the connection

Formatted/Non:	[database_name] [varchar](128) NULL
	Shows the connected database

Formatted/Non:	[program_name] [varchar](128) NULL
	Shows the connected database

Formatted/Non:	[start_time] [datetime] NOT NULL
	For active requests, shows the time the request started
	For sleeping sessions, shows the time the connection was made
	
Formatted/Non:	[request_id] [int] NULL
	For active requests, shows the request_id
	Should be 0 unless MARS is being used

Formatted/Non:	[collection_time] [datetime] NOT NULL
	Time that this script's final SELECT ran
*/
AS
BEGIN
	SET NOCOUNT ON; 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET QUOTED_IDENTIFIER ON;
	SET ANSI_PADDING ON;

	IF
		@filter IS NULL
		OR @filter_type IS NULL
		OR @show_own_spid IS NULL
		OR @get_full_inner_text IS NULL
		OR @get_plans IS NULL
		OR @get_outer_command IS NULL
		OR @get_sleeping_spids IS NULL
		OR @get_transaction_info IS NULL
		OR @get_locks IS NULL
		OR @get_avg_time IS NULL
		OR @find_block_leaders IS NULL
		OR @delta_interval IS NULL
		OR @sort_column IS NULL
		OR @sort_column_direction IS NULL
		OR @format_output IS NULL
		OR @output_column_list IS NULL
		OR @return_schema IS NULL
		OR @destination_table IS NULL
		OR @help IS NULL
	BEGIN;
		RAISERROR('Input parameters cannot be NULL', 16, 1);
		RETURN;
	END;
	
	IF @filter_type NOT IN ('session', 'program', 'database', 'login', 'host')
	BEGIN;
		RAISERROR('Valid filter types are: session, program, database, login, host', 16, 1);
		RETURN;
	END;
	
	IF @filter_type = 'session' AND @filter LIKE '%[^0123456789]%'
	BEGIN;
		RAISERROR('Session filters must be valid integers', 16, 1);
		RETURN;
	END;
	
	IF @get_plans NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @get_plans are: 0, 1, or 2', 16, 1);
		RETURN;
	END;
	
	IF @get_sleeping_spids NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @get_sleeping_spids are: 0, 1, or 2', 16, 1);
		RETURN;
	END;

	IF @format_output NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @format_output are: 0, 1, or 2', 16, 1);
		RETURN;
	END;
	
	IF @help = 1
	BEGIN;
		DECLARE @params VARCHAR(MAX);
		SET @params =
			(
				SELECT
					CHAR(13) +
						REPLACE
						(
							REPLACE
							(
								CONVERT
								(
									VARCHAR(MAX),
									SUBSTRING
									(
										t.text, 
										CHARINDEX('--~', t.text) + 5, 
										CHARINDEX('--~', t.text, CHARINDEX('--~', t.text) + 5) - (CHARINDEX('--~', t.text) + 5)
									)
								),
								CHAR(13)+CHAR(10),
								CHAR(13)
							),
							'	',
							''
						) +
						CHAR(13) AS param_text
				FROM sys.dm_exec_requests AS r
				CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
				WHERE
					r.session_id = @@SPID
			);
		
		WITH
		a0 AS
		(SELECT 1 AS n UNION ALL SELECT 1),
		a1 AS
		(SELECT 1 AS n FROM a0 AS a, a0 AS b),
		a2 AS
		(SELECT 1 AS n FROM a1 AS a, a1 AS b),
		a3 AS
		(SELECT 1 AS n FROM a2 AS a, a2 AS b),
		a4 AS
		(SELECT 1 AS n FROM a3 AS a, a3 AS b),
		numbers AS
		(
			SELECT 
				ROW_NUMBER() OVER
				(
					ORDER BY n
				) AS number
			FROM a4
		),
		tokens AS
		(
			SELECT
				RTRIM(LTRIM(
					SUBSTRING
					(
						@params,
						number + 1,
						CHARINDEX(CHAR(13), @params, number + 1) - number - 1
					)
				)) AS token,
				number,
				CHARINDEX(CHAR(13) + '@', @params, number) AS param_group,
				ROW_NUMBER() OVER
				(
					PARTITION BY CHARINDEX(CHAR(13) + '@', @params, number)
					ORDER BY number
				) AS group_order
			FROM numbers
			WHERE
				number < LEN(@params)
				AND SUBSTRING(@params, number, 1) = CHAR(13)
		),
		parsed_tokens AS
		(
			SELECT
				CASE
					WHEN group_order = MIN(group_order) OVER (PARTITION BY param_group) THEN
						MIN(CASE WHEN number = param_group THEN token ELSE NULL END) OVER (PARTITION BY param_group)
					ELSE ''
				END AS parameter,
				RIGHT(token, LEN(token) - 2) AS description,
				number,
				param_group
			FROM tokens
			WHERE 
				token <> ''
		)
		SELECT
			CASE
				WHEN number = param_group AND parameter = '' THEN '-------------------------------------------------------------------------'
				ELSE 
					CASE 
						WHEN RIGHT(parameter, 1) = ',' THEN LEFT(parameter, LEN(parameter) - 1)
						ELSE parameter
					END
			END AS [------parameter----------------------------------------------------------],
			CASE
				WHEN number = param_group THEN '----------------------------------------------------------------------------------------------------------------------'
				ELSE COALESCE(description, '')
			END AS [------description-----------------------------------------------------------------------------------------------------]
		FROM parsed_tokens
		ORDER BY
			number;
			
		RETURN;
	END;

	IF
		@sort_column NOT IN
		(
			'[session_id]',
			'[physical_io]',
			'[reads]',
			'[physical_reads]',
			'[writes]',
			'[tempdb_writes]',
			'[tempdb_current]',
			'[CPU]',
			'[context_switches]',
			'[used_memory]',
			'[physical_io_delta]',
			'[reads_delta]',
			'[physical_reads_delta]',
			'[writes_delta]',
			'[tempdb_writes_delta]',
			'[tempdb_current_delta]',
			'[CPU_delta]',
			'[context_switches_delta]',
			'[used_memory_delta]',
			'[tasks]',
			'[tran_start_time]',
			'[open_tran_count]',
			'[blocking_session_id]',
			'[blocked_session_count]',
			'[percent_complete]',
			'[host_name]',
			'[login_name]',
			'[database_name]',
			'[program_name]',
			'[start_time]'
		)
	BEGIN;
		RAISERROR('Invalid column passed to @sort_column', 16, 1, @sort_column);
		RETURN;
	END;

	IF @sort_column_direction NOT IN ('ASC', 'DESC')
	BEGIN;
		RAISERROR('Valid values for @SORT_DIRECTION are: ASC and DESC', 16, 1);
		RETURN;
	END;

	WITH
	a0 AS
	(SELECT 1 AS n UNION ALL SELECT 1),
	a1 AS
	(SELECT 1 AS n FROM a0 AS a, a0 AS b),
	a2 AS
	(SELECT 1 AS n FROM a1 AS a, a1 AS b),
	a3 AS
	(SELECT 1 AS n FROM a2 AS a, a2 AS b),
	a4 AS
	(SELECT 1 AS n FROM a3 AS a, a3 AS b),
	numbers AS
	(
		SELECT 
			ROW_NUMBER() OVER
			(
				ORDER BY n
			) AS number
		FROM a4
	),
	tokens AS
	(
		SELECT
			'|[' +
				SUBSTRING
				(
					@output_column_list,
					number + 1,
					CHARINDEX(']', @output_column_list, number) - number - 1
				) + '|]' AS token,
			number
		FROM numbers
		WHERE
			number <= LEN(@output_column_list)
			AND SUBSTRING(@output_column_list, number, 1) = '['
	),
	ordered_columns AS
	(
		SELECT
			x.column_name,
			ROW_NUMBER() OVER
			(
				PARTITION BY
					x.column_name
				ORDER BY
					tokens.number,
					x.default_order
			) AS r,
			ROW_NUMBER() OVER
			(
				ORDER BY
					tokens.number,
					x.default_order
			) AS s
		FROM tokens
		JOIN
		(
			SELECT '[session_id]' AS column_name, 1 AS default_order
			UNION ALL
			SELECT '[dd hh:mm:ss.mss]', 2
			WHERE
				@format_output = 1
			UNION ALL
			SELECT '[dd hh:mm:ss.mss (avg)]', 3
			WHERE
				@format_output = 1
				AND @get_avg_time = 1
			UNION ALL
			SELECT '[avg_elapsed_time]', 4
			WHERE
				@format_output = 0
				AND @get_avg_time = 1
			UNION ALL
			SELECT '[physical_io]', 5
			UNION ALL
			SELECT '[reads]', 6
			UNION ALL
			SELECT '[physical_reads]', 7
			UNION ALL
			SELECT '[writes]', 8
			UNION ALL
			SELECT '[tempdb_writes]', 9
			UNION ALL
			SELECT '[tempdb_current]', 10
			UNION ALL
			SELECT '[CPU]', 11
			UNION ALL
			SELECT '[context_switches]', 12
			UNION ALL
			SELECT '[used_memory]', 13
			UNION ALL
			SELECT '[physical_io_delta]', 14
			WHERE
				@delta_interval > 0	
			UNION ALL
			SELECT '[reads_delta]', 15
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[physical_reads_delta]', 16
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[writes_delta]', 17
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[tempdb_writes_delta]', 18
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[tempdb_current_delta]', 19
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[CPU_delta]', 20
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[context_switches_delta]', 21
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[used_memory_delta]', 22
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[tasks]', 23
			UNION ALL
			SELECT '[status]', 24
			UNION ALL
			SELECT '[wait_info]', 25
			UNION ALL
			SELECT '[locks]', 26
			WHERE
				@get_locks = 1
			UNION ALL
			SELECT '[tran_start_time]', 27
			WHERE
				@get_transaction_info = 1
			UNION ALL
			SELECT '[tran_log_writes]', 28
			WHERE
				@get_transaction_info = 1
			UNION ALL
			SELECT '[open_tran_count]', 29
			UNION ALL
			SELECT '[sql_command]', 30
			WHERE
				@get_outer_command = 1
			UNION ALL
			SELECT '[sql_text]', 31
			UNION ALL
			SELECT '[query_plan]', 32
			WHERE
				@get_plans >= 1
			UNION ALL
			SELECT '[blocking_session_id]', 33
			UNION ALL
			SELECT '[blocked_session_count]', 34
			WHERE
				@find_block_leaders = 1
			UNION ALL
			SELECT '[percent_complete]', 35
			UNION ALL
			SELECT '[host_name]', 36
			UNION ALL
			SELECT '[login_name]', 37
			UNION ALL
			SELECT '[database_name]', 38
			UNION ALL
			SELECT '[program_name]', 39
			UNION ALL
			SELECT '[start_time]', 40
			UNION ALL
			SELECT '[request_id]', 41
			UNION ALL
			SELECT '[collection_time]', 42
		) AS x ON 
			x.column_name LIKE token ESCAPE '|'
	)
	SELECT
		@output_column_list =
			STUFF
			(
				(
					SELECT
						',' + column_name as [text()]
					FROM ordered_columns
					WHERE
						r = 1
					ORDER BY
						s
					FOR XML PATH('')
				),
				1,
				1,
				''
			);
	
	IF COALESCE(RTRIM(@output_column_list), '') = ''
	BEGIN
		RAISERROR('No valid column matches found in @output_column_list or no columns remain due to selected options.', 16, 1);
		RETURN;
	END;
	
	IF @destination_table <> ''
	BEGIN
		SET @destination_table = 
			--database
			COALESCE(QUOTENAME(PARSENAME(@destination_table, 3)) + '.', '') +
			--schema
			COALESCE(QUOTENAME(PARSENAME(@destination_table, 2)) + '.', '') +
			--table
			COALESCE(QUOTENAME(PARSENAME(@destination_table, 1)), '');
			
		IF COALESCE(RTRIM(@destination_table), '') = ''
		BEGIN
			RAISERROR('Destination table not properly formatted.', 16, 1);
			RETURN;
		END;
	END;

	CREATE TABLE #sessions
	(
		recursion SMALLINT NOT NULL,
		session_id SMALLINT NOT NULL,
		request_id INT NULL,
		session_number INT NOT NULL,
		elapsed_time INT NOT NULL,
		avg_elapsed_time INT NULL,
		physical_io BIGINT NULL,
		reads BIGINT NOT NULL,
		physical_reads BIGINT NOT NULL,
		writes BIGINT NOT NULL,
		tempdb_writes BIGINT NOT NULL,
		tempdb_current BIGINT NOT NULL,
		CPU INT NOT NULL,
		context_switches BIGINT NULL,
		used_memory BIGINT NOT NULL, 
		tasks SMALLINT NULL,
		status VARCHAR(30) NOT NULL,
		wait_info VARCHAR(4000) NULL,
		locks XML NULL,
		tran_start_time DATETIME NULL,
		tran_log_writes VARCHAR(4000) NULL,
		open_tran_count INT NULL,
		sql_command XML NULL,
		sql_handle VARBINARY(64) NULL,
		statement_start_offset INT NULL,
		statement_end_offset INT NULL,
		sql_text XML NULL,
		plan_handle VARBINARY(64) NULL,
		query_plan XML NULL,
		blocking_session_id SMALLINT NULL,
		blocked_session_count SMALLINT NULL,
		percent_complete REAL NULL,
		host_name VARCHAR(128) NOT NULL,
		login_name VARCHAR(128) NOT NULL,
		database_name VARCHAR(128) NULL,
		program_name VARCHAR(128) NULL,
		start_time DATETIME NOT NULL,
		last_request_start_time DATETIME NOT NULL,
		UNIQUE CLUSTERED (session_id, request_id, recursion) 
	);

	IF @return_schema = 0
	BEGIN;
		--Disable unnecessary autostats on the table
		CREATE STATISTICS s_session_id ON #sessions (session_id)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_request_id ON #sessions (request_id)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_session_number ON #sessions (session_number)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_status ON #sessions (status)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_start_time ON #sessions (start_time)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_last_request_start_time ON #sessions (last_request_start_time)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_recursion ON #sessions (recursion)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;

		DECLARE @recursion SMALLINT;
		SET @recursion = 
			CASE @delta_interval
				WHEN 0 THEN 1
				ELSE -1
			END;

		--Used for the delta pull
		REDO:;
		
		IF 
			@get_locks = 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[locks|]%' ESCAPE '|'
		BEGIN;
			SELECT
				y.resource_type,
				y.db_name,
				y.object_id,
				y.file_id,
				y.page_type,
				y.hobt_id,
				y.allocation_unit_id,
				y.index_id,
				y.schema_id,
				y.principal_id,
				y.request_mode,
				y.request_status,
				y.session_id,
				y.resource_description,
				y.request_count,
				COALESCE(s.request_id, -1) AS request_id,
				s.start_time,
				CONVERT(sysname, NULL) AS object_name,
				CONVERT(sysname, NULL) AS index_name,
				CONVERT(sysname, NULL) AS schema_name,
				CONVERT(sysname, NULL) AS principal_name
			INTO #locks
			FROM
			(
				SELECT
					s1.session_id,
					r.request_id,
					COALESCE(r.start_time, s1.last_request_start_time) AS start_time
				FROM sys.dm_exec_sessions AS s1
				INNER HASH JOIN
				(
					SELECT
						s1.spid,
						MIN(s1.dbid) AS dbid
					FROM sys.sysprocesses AS s1
					GROUP BY
						s1.spid
				) sp ON
					sp.spid = s1.session_id
				LEFT OUTER HASH JOIN sys.dm_exec_requests AS r ON
					r.session_id = s1.session_id
				WHERE
					(
						@show_own_spid = 1
						OR s1.session_id <> @@SPID
					)
					AND 1 =
						CASE
							WHEN @filter <> '' THEN
								CASE @filter_type
									WHEN 'session' THEN
										CASE
											WHEN
												CONVERT(TINYINT, @filter) = 0
												OR s1.session_id = CONVERT(TINYINT, @filter)
													THEN 1
											ELSE 0
										END
									WHEN 'program' THEN
										CASE
											WHEN s1.program_name LIKE @filter THEN 1
											ELSE 0
										END
									WHEN 'login' THEN
										CASE
											WHEN s1.login_name LIKE @filter THEN 1
											ELSE 0
										END
									WHEN 'host' THEN
										CASE
											WHEN s1.host_name LIKE @filter THEN 1
											ELSE 0
										END
									WHEN 'database' THEN
										CASE
											WHEN DB_NAME(COALESCE(r.database_id, sp.dbid)) LIKE @filter THEN 1
											ELSE 0
										END
									ELSE 0
								END
							ELSE 1
						END
			) AS s
			INNER HASH JOIN
			(
				SELECT
					x.resource_type,
					x.db_name,
					x.object_id,
					x.file_id,
					CASE
						WHEN x.page_no = 1 OR x.page_no % 8088 = 0 THEN 'PFS'
						WHEN x.page_no = 2 OR x.page_no % 511232 = 0 THEN 'GAM'
						WHEN x.page_no = 3 OR x.page_no % 511233 = 0 THEN 'SGAM'
						WHEN x.page_no = 6 OR x.page_no % 511238 = 0 THEN 'DCM'
						WHEN x.page_no = 7 OR x.page_no % 511239 = 0 THEN 'BCM'
						WHEN x.page_no IS NOT NULL THEN '*'
						ELSE NULL
					END AS page_type,
					x.hobt_id,
					x.allocation_unit_id,
					x.index_id,
					x.schema_id,
					x.principal_id,
					x.request_mode,
					x.request_status,
					x.session_id,
					x.request_id,
					CASE
						WHEN COALESCE(x.object_id, x.file_id, x.hobt_id, x.allocation_unit_id, x.index_id, x.schema_id, x.principal_id) IS NULL THEN NULLIF(resource_description, '')
						ELSE NULL
					END AS resource_description,
					COUNT(*) AS request_count
				FROM
				(
					SELECT
						tl.resource_type +
							CASE
								WHEN tl.resource_subtype = '' THEN ''
								ELSE '.' + tl.resource_subtype
							END AS resource_type,
						COALESCE(DB_NAME(tl.resource_database_id), '(null)') AS db_name,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_type = 'OBJECT' THEN tl.resource_associated_entity_id
								WHEN tl.resource_description LIKE '%object_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('object_id = ', tl.resource_description) + 12), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('object_id = ', tl.resource_description) + 12),
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('object_id = ', tl.resource_description) + 12)
										)
									)
								ELSE NULL
							END
						) AS object_id,
						CONVERT
						(
							INT,
							CASE 
								WHEN tl.resource_type = 'FILE' THEN CONVERT(INT, tl.resource_description)
								WHEN tl.resource_type IN ('PAGE', 'EXTENT', 'RID') THEN LEFT(tl.resource_description, CHARINDEX(':', tl.resource_description)-1)
								ELSE NULL
							END
						) AS file_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_type IN ('PAGE', 'EXTENT', 'RID') THEN 
									SUBSTRING
									(
										tl.resource_description, 
										CHARINDEX(':', tl.resource_description) + 1, 
										COALESCE
										(
											NULLIF
											(
												CHARINDEX(':', tl.resource_description, CHARINDEX(':', tl.resource_description) + 1), 
												0
											), 
											DATALENGTH(tl.resource_description)+1
										) - (CHARINDEX(':', tl.resource_description) + 1)
									)
								ELSE NULL
							END
						) AS page_no,
						CASE
							WHEN tl.resource_type IN ('PAGE', 'KEY', 'RID', 'HOBT') THEN tl.resource_associated_entity_id
							ELSE NULL
						END AS hobt_id,
						CASE
							WHEN tl.resource_type = 'ALLOCATION_UNIT' THEN tl.resource_associated_entity_id
							ELSE NULL
						END AS allocation_unit_id,
						CONVERT
						(
							INT,
							CASE
								WHEN
									/*TODO: Deal with server principals*/ 
									tl.resource_subtype <> 'SERVER_PRINCIPAL' 
									AND tl.resource_description LIKE '%index_id or stats_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('index_id or stats_id = ', tl.resource_description) + 23), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('index_id or stats_id = ', tl.resource_description) + 23), 
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('index_id or stats_id = ', tl.resource_description) + 23)
										)
									)
								ELSE NULL
							END 
						) AS index_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_description LIKE '%schema_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('schema_id = ', tl.resource_description) + 12), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('schema_id = ', tl.resource_description) + 12), 
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('schema_id = ', tl.resource_description) + 12)
										)
									)
								ELSE NULL
							END 
						) AS schema_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_description LIKE '%principal_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('principal_id = ', tl.resource_description) + 15), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('principal_id = ', tl.resource_description) + 15), 
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('principal_id = ', tl.resource_description) + 15)
										)
									)
								ELSE NULL
							END
						) AS principal_id,
						tl.request_mode,
						tl.request_status,
						tl.request_session_id AS session_id,
						tl.request_request_id AS request_id,

						/*TODO: Applocks, other resource_descriptions*/
						RTRIM(tl.resource_description) AS resource_description,
						tl.resource_associated_entity_id
						/*********************************************/
					FROM 
					(
						SELECT 
							request_session_id,
							CONVERT(VARCHAR(120), resource_type) COLLATE Latin1_General_Bin2 AS resource_type,
							CONVERT(VARCHAR(120), resource_subtype) COLLATE Latin1_General_Bin2 AS resource_subtype,
							resource_database_id,
							CONVERT(VARCHAR(512), resource_description) COLLATE Latin1_General_Bin2 AS resource_description,
							resource_associated_entity_id,
							CONVERT(VARCHAR(120), request_mode) COLLATE Latin1_General_Bin2 AS request_mode,
							CONVERT(VARCHAR(120), request_status) COLLATE Latin1_General_Bin2 AS request_status,
							request_request_id
						FROM sys.dm_tran_locks
					) AS tl
				) AS x
				GROUP BY
					x.resource_type,
					x.db_name,
					x.object_id,
					x.file_id,
					CASE
						WHEN x.page_no = 1 OR x.page_no % 8088 = 0 THEN 'PFS'
						WHEN x.page_no = 2 OR x.page_no % 511232 = 0 THEN 'GAM'
						WHEN x.page_no = 3 OR x.page_no % 511233 = 0 THEN 'SGAM'
						WHEN x.page_no = 6 OR x.page_no % 511238 = 0 THEN 'DCM'
						WHEN x.page_no = 7 OR x.page_no % 511239 = 0 THEN 'BCM'
						WHEN x.page_no IS NOT NULL THEN '*'
						ELSE NULL
					END,
					x.hobt_id,
					x.allocation_unit_id,
					x.index_id,
					x.schema_id,
					x.principal_id,
					x.request_mode,
					x.request_status,
					x.session_id,
					x.request_id,
					CASE
						WHEN COALESCE(x.object_id, x.file_id, x.hobt_id, x.allocation_unit_id, x.index_id, x.schema_id, x.principal_id) IS NULL THEN NULLIF(resource_description, '')
						ELSE NULL
					END
			) AS y ON
				y.session_id = s.session_id
				AND y.request_id = COALESCE(s.request_id, 0)
			OPTION (HASH GROUP);
			
			--Disable unnecessary autostats on the table
			CREATE STATISTICS s_db_name ON #locks (db_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_object_id ON #locks (object_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_hobt_id ON #locks (hobt_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_allocation_unit_id ON #locks (allocation_unit_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_index_id ON #locks (index_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_schema_id ON #locks (schema_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_principal_id ON #locks (principal_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_id ON #locks (request_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_start_time ON #locks (start_time)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_resource_type ON #locks (resource_type)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_object_name ON #locks (object_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_schema_name ON #locks (schema_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_page_type ON #locks (page_type)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_mode ON #locks (request_mode)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_status ON #locks (request_status)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_resource_description ON #locks (resource_description)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_index_name ON #locks (index_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_principal_name ON #locks (principal_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
		END;
		
		DECLARE 
			@sql VARCHAR(MAX), 
			@sql_n NVARCHAR(MAX);

		SET @sql = 
			--Column list
			CONVERT
			(
				VARCHAR(MAX),
				'SELECT ' +
					'@recursion AS recursion, ' +
					'x.session_id, ' +
					'x.request_id, ' +
					'DENSE_RANK() OVER  ' +
					'( ' +
						'ORDER BY ' +
							'x.session_id ' +
					') AS session_number, ' +
					CASE
						WHEN @output_column_list LIKE '%|[dd hh:mm:ss.mss|]%' ESCAPE '|' THEN 'x.elapsed_time '
						ELSE '0 '
					END + 'AS elapsed_time, ' +
					CASE
						WHEN
							(
								@output_column_list LIKE '%|[dd hh:mm:ss.mss (avg)|]%' ESCAPE '|' OR 
								@output_column_list LIKE '%|[avg_elapsed_time|]%' ESCAPE '|'
							)
							AND @recursion = 1
								THEN 'x.avg_elapsed_time / 1000 '
						ELSE 'NULL '
					END + 'AS avg_elapsed_time, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[physical_io|]%' ESCAPE '|'
							OR @output_column_list LIKE '%|[physical_io_delta|]%' ESCAPE '|'
								THEN 'x.physical_io '
						ELSE 'NULL '
					END + 'AS physical_io, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[reads|]%' ESCAPE '|'
							OR @output_column_list LIKE '%|[reads_delta|]%' ESCAPE '|'
								THEN 'x.reads '
						ELSE '0 '
					END + 'AS reads, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[physical_reads|]%' ESCAPE '|'
							OR @output_column_list LIKE '%|[physical_reads_delta|]%' ESCAPE '|'
								THEN 'x.physical_reads '
						ELSE '0 '
					END + 'AS physical_reads, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[writes|]%' ESCAPE '|'
							OR @output_column_list LIKE '%|[writes_delta|]%' ESCAPE '|'
								THEN 'x.writes '
						ELSE '0 '
					END + 'AS writes, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[tempdb_writes|]%' ESCAPE '|'
							OR @output_column_list LIKE '%|[tempdb_writes_delta|]%' ESCAPE '|'
								THEN 'x.tempdb_writes '
						ELSE '0 '
					END + 'AS tempdb_writes, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[tempdb_current|]%' ESCAPE '|'
							OR @output_column_list LIKE '%|[tempdb_current_delta|]%' ESCAPE '|'
								THEN 'x.tempdb_current '
						ELSE '0 '
					END + 'AS tempdb_current, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[CPU|]%' ESCAPE '|'
							OR @output_column_list LIKE '%|[CPU_delta|]%' ESCAPE '|'
								THEN 'x.CPU '
						ELSE '0 '
					END + 'AS CPU, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[context_switches|]%' ESCAPE '|'
							OR @output_column_list LIKE '%|[context_switches_delta|]%' ESCAPE '|'
								THEN 'x.context_switches '
						ELSE 'NULL '
					END + 'AS context_switches, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[used_memory|]%' ESCAPE '|'
							OR @output_column_list LIKE '%|[used_memory_delta|]%' ESCAPE '|'
								THEN 'x.used_memory '
						ELSE '0 '
					END + 'AS used_memory, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[tasks|]%' ESCAPE '|'
							AND @recursion = 1
								THEN 'x.tasks '
						ELSE 'NULL '
					END + 'AS tasks, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[status|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'x.status '
						ELSE ''''' '
					END + 'AS status, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[wait_info|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'x.wait_info '
						ELSE 'NULL '
					END + 'AS wait_info, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[tran_start_time|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 
								'CONVERT ' +
								'( ' +
									'DATETIME, ' +
									'LEFT ' +
									'( ' +
										'x.tran_log_writes, ' +
										'NULLIF(CHARINDEX(CHAR(254), x.tran_log_writes) - 1, -1) ' +
									') ' +
								') '
						ELSE 'NULL '
					END + 'AS tran_start_time, ' +				
					CASE
						WHEN 
							@output_column_list LIKE '%|[tran_log_writes|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 
								'RIGHT ' +
								'( ' +
									'x.tran_log_writes, ' +
									'LEN(x.tran_log_writes) - CHARINDEX(CHAR(254), x.tran_log_writes) ' +
								') '
						ELSE 'NULL '
					END + 'AS tran_log_writes, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[open_tran_count|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'x.open_tran_count '
						ELSE 'NULL '
					END + 'AS open_tran_count, ' + 
					CASE
						WHEN 
							@output_column_list LIKE '%|[sql_text|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'x.sql_handle '
						ELSE 'NULL '
					END + 'AS sql_handle, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[sql_text|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'x.statement_start_offset '
						ELSE 'NULL '
					END + 'AS statement_start_offset, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[sql_text|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'x.statement_end_offset '
						ELSE 'NULL '
					END + 'AS statement_end_offset, ' +
					'NULL AS sql_text, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[query_plan|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'x.plan_handle '
						ELSE 'NULL '
					END + 'AS plan_handle, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[blocking_session_id|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'NULLIF(x.blocking_session_id, 0) '
						ELSE 'NULL '
					END + 'AS blocking_session_id, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[percent_complete|]%' ESCAPE '|'
							AND @recursion = 1
								THEN 'x.percent_complete '
						ELSE 'NULL '
					END + 'AS percent_complete, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[host_name|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'x.host_name '
						ELSE ''''' '
					END + 'AS host_name, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[login_name|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'x.login_name '
						ELSE ''''' '
					END + 'AS login_name, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[database_name|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'DB_NAME(x.database_id) '
						ELSE 'NULL '
					END + 'AS database_name, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[program_name|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'x.program_name '
						ELSE ''''' '
					END + 'AS program_name, ' +
					'x.start_time, ' +
					'x.last_request_start_time '
			--End column list
			) +
			--Derived table "y"
			CONVERT
			(
				VARCHAR(MAX),
				'FROM ' +
				'( ' +
					'SELECT ' +
						'y.*, ' +
						'tasks.physical_io, ' +
						'COALESCE(tempdb_info.tempdb_writes, 0) AS tempdb_writes, ' +
						'COALESCE ' +
						'( ' +
							'CASE ' +
								'WHEN tempdb_info.tempdb_current < 0 THEN 0 ' +
								'ELSE tempdb_info.tempdb_current ' + 
							'END, ' +
							'0 ' +
						') AS tempdb_current, ' +
						'tasks.context_switches, ' + 
						'tasks.tasks, ' +
						'tasks.wait_info, ' +
						'tasks.blocking_session_id, ' +
						CASE 
							WHEN NOT (@get_avg_time = 1 AND @recursion = 1) THEN 'CONVERT(INT, NULL) '
							ELSE 'qs.total_elapsed_time / qs.execution_count '
						END + 'AS avg_elapsed_time ' +
					'FROM ' +
					'( ' +
						'SELECT ' +
							's.session_id, ' +
							'r.request_id, ' +
							--r.total_elapsed_time AS elapsed_time,
							--total_elapsed_time appears to be way off in some cases
							'CASE ' +
								--if there are more than 24 days, return a negative number of seconds rather than
								--positive milliseconds, in order to avoid overflow errors
								'WHEN DATEDIFF(day, COALESCE(r.start_time, s.login_time), GETDATE()) > 24 THEN ' +
									'DATEDIFF(second, GETDATE(), COALESCE(r.start_time, s.login_time)) ' +
								'ELSE DATEDIFF(ms, COALESCE(r.start_time, s.login_time), GETDATE()) ' +
							'END AS elapsed_time, ' +
							'COALESCE(r.logical_reads, s.logical_reads) AS reads, ' +
							'COALESCE(r.reads, s.reads) AS physical_reads, ' +
							'COALESCE(r.writes, s.writes) AS writes, ' +
							'COALESCE(r.CPU_time, s.CPU_time) AS CPU, ' +
							'COALESCE(CONVERT(BIGINT, mg.used_memory_kb / 8), 0) + s.memory_usage AS used_memory, ' +
							'LOWER(COALESCE(r.status, s.status)) AS status, ' +
							'COALESCE(r.sql_handle, sp.sql_handle) AS sql_handle, ' +
							'CASE ' +
								'WHEN r.command = ''CREATE INDEX'' THEN 0 ' +
								'ELSE r.statement_start_offset ' +
							'END AS statement_start_offset, ' +
							'CASE ' +
								'WHEN r.command = ''CREATE INDEX'' THEN -1 ' +
								'ELSE r.statement_end_offset ' +
							'END AS statement_end_offset, ' +
							'r.plan_handle, ' +
							'NULLIF(r.percent_complete, 0) AS percent_complete, ' +
							's.host_name, ' +
							's.login_name, ' +
							's.program_name, ' +
							'COALESCE(r.start_time, s.login_time) AS start_time, ' +
							's.last_request_start_time, ' +
							'r.transaction_id, ' +
							'COALESCE ' +
							'( ' +
								'r.database_id, ' +
								'sp.dbid ' + 
							') AS database_id, ' +
							'sp.open_tran_count, ' +
							'( ' +
								CASE 
									WHEN NOT (@get_transaction_info = 1 AND @recursion = 1) THEN 'CONVERT(VARCHAR(4000), NULL) '
									ELSE
										'SELECT ' +
											'REPLACE ' +
											'( ' +
												'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
												'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
												'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
													'CONVERT ' +
													'( ' +
														'VARCHAR(MAX), ' +
														'CASE ' +
															'WHEN u_trans.database_id IS NOT NULL THEN ' +
																'CASE u_trans.r ' +
																	'WHEN 1 THEN COALESCE(CONVERT(VARCHAR, u_trans.transaction_start_time, 121) + CHAR(254), '''') ' +
																	'ELSE '''' ' +
																'END + ' + 
																'COALESCE(DB_NAME(u_trans.database_id), ''(null)'') + '':'' + ' +
																'CONVERT(VARCHAR, u_trans.log_record_count) + ' +
																''','' ' +
															'ELSE ' +
																'''N/A,'' ' +
														'END COLLATE Latin1_General_BIN2 ' +
													'), ' +
													'CHAR(31),''''),CHAR(30),''''),CHAR(29),''''),CHAR(28),''''),CHAR(27),''''),CHAR(26),''''),CHAR(25),''''),CHAR(24),''''),CHAR(23),''''),CHAR(22),''''), ' +
													'CHAR(21),''''),CHAR(20),''''),CHAR(19),''''),CHAR(18),''''),CHAR(17),''''),CHAR(16),''''),CHAR(15),''''),CHAR(14),''''),CHAR(12),''''), ' +
													'CHAR(11),''''),CHAR(8),''''),CHAR(7),''''),CHAR(6),''''),CHAR(5),''''),CHAR(4),''''),CHAR(3),''''),CHAR(2),''''),CHAR(1),''''), ' +
												'CHAR(0), ' +
												''''' ' +
											') AS [text()] ' +
										'FROM ' +
										'( ' +
											'SELECT ' +
												'trans.*, ' +
												'ROW_NUMBER() OVER (ORDER BY trans.transaction_start_time DESC) AS r ' +
											'FROM ' +
											'( ' +
												'SELECT ' +
													's_tran.database_id, ' +
													'COALESCE(SUM(s_tran.database_transaction_log_record_count), 0) AS log_record_count, ' +
													'MIN(s_tran.database_transaction_begin_time) AS transaction_start_time ' +
												'FROM sys.dm_tran_database_transactions AS s_tran ' +
												'LEFT OUTER JOIN sys.dm_tran_session_transactions AS tst ON ' +
													's_tran.transaction_id = tst.transaction_id ' +
													'AND s_tran.database_id < 32767 ' +
												'WHERE ' +
													's_tran.transaction_id = r.transaction_id ' + 
													'OR ' +
													'( ' +
														'COALESCE(r.request_id, 0) = 0 ' +
														'AND s.session_id = tst.session_id ' +
													') ' +
												'GROUP BY ' +
													's_tran.database_id ' +
											') AS trans ' +
										') AS u_trans ' +
										'FOR XML PATH('''') '
								END +
							') AS tran_log_writes ' +
						'FROM sys.dm_exec_sessions AS s ' +
						'LEFT OUTER JOIN sys.dm_exec_requests AS r ON ' +
							's.session_id = r.session_id ' +
						'INNER JOIN ' +
						'(' +
							'SELECT ' +
								'sp1.spid, ' +
								'sp1.request_id, ' +
								'MIN(sp1.dbid) AS dbid, ' +
								'SUM(sp1.open_tran) AS open_tran_count, ' +
								'MIN(sp1.sql_handle) AS sql_handle ' +
							'FROM sys.sysprocesses AS sp1 ' +
							'GROUP BY ' +
								'sp1.spid, ' +
								'sp1.request_id ' +
						') AS sp ON ' +
							's.session_id = sp.spid ' +
							'AND COALESCE(r.request_id, 0) = sp.request_id ' +
							CASE @get_sleeping_spids
								WHEN 0 THEN
									'AND r.request_id IS NOT NULL '
								WHEN 1 THEN
									'AND ' +
									'( ' +
										'r.request_id IS NOT NULL ' +
										'OR sp.open_tran_count > 0 ' +
									') '
								ELSE ''
							END +
						'LEFT OUTER JOIN ' +
						'( ' +
							'SELECT ' +
								'qmg.session_id, ' +
								'qmg.request_id, ' +
								'SUM(qmg.used_memory_kb) AS used_memory_kb ' +
							'FROM sys.dm_exec_query_memory_grants AS qmg ' +
							'GROUP BY ' +
								'qmg.session_id, ' +
								'qmg.request_id ' +
						') AS mg ON ' +
							'r.session_id = mg.session_id ' +
							'AND r.request_id = mg.request_id ' +
						'WHERE ' +
							's.host_name IS NOT NULL ' +
							CASE
								WHEN @filter <> '' THEN
									CASE @filter_type
										WHEN 'session' THEN
											CASE
												WHEN CONVERT(TINYINT, @filter) <> 0 THEN
													'AND s.session_id = CONVERT(TINYINT, @filter) '
												ELSE ''
											END
										WHEN 'program' THEN
											'AND s.program_name LIKE @filter '
										WHEN 'login' THEN
											'AND s.login_name LIKE @filter '
										WHEN 'host' THEN
											'AND s.host_name LIKE @filter '
										WHEN 'database' THEN
											'AND DB_NAME(COALESCE(r.database_id, sp.dbid)) LIKE @filter '
										ELSE ''
									END
								ELSE ''
							END +
							CASE @show_own_spid
								WHEN 1 THEN ''
								ELSE
									'AND s.session_id <> @@spid '
							END +
					') AS y '
				--End derived table "y"
				) +
				--Derived table "x"
				CONVERT
				(
					VARCHAR(MAX),
					'LEFT OUTER JOIN ' +
					'( ' +
						'SELECT ' +
							'session_id, ' +
							'request_id, ' +
							'SUM(tempdb_writes) AS tempdb_writes, ' +
							'SUM(tempdb_current) AS tempdb_current ' +
						'FROM ' +
						'( ' +
							'SELECT ' +
								'tsu.session_id, ' +
								'tsu.request_id, ' +
								'tsu.user_objects_alloc_page_count + ' +
									'tsu.internal_objects_alloc_page_count AS tempdb_writes,' +
								'tsu.user_objects_alloc_page_count + ' +
									'tsu.internal_objects_alloc_page_count - ' +
									'tsu.user_objects_dealloc_page_count - ' +
									'tsu.internal_objects_dealloc_page_count AS tempdb_current ' +
							'FROM sys.dm_db_task_space_usage AS tsu ' +
							'' +
							'UNION ALL ' +
							'' +
							'SELECT ' +
								'ssu.session_id, ' +
								'NULL AS request_id, ' +
								'ssu.user_objects_alloc_page_count + ' +
									'ssu.internal_objects_alloc_page_count AS tempdb_writes, ' +
								'ssu.user_objects_alloc_page_count + ' +
									'ssu.internal_objects_alloc_page_count - ' +
									'ssu.user_objects_dealloc_page_count - ' +
									'ssu.internal_objects_dealloc_page_count AS tempdb_current ' +
							'FROM sys.dm_db_session_space_usage AS ssu ' +
						') AS t_info ' +
						'GROUP BY ' +
							'session_id, ' +
							'request_id ' +
					') AS tempdb_info ON ' +
						'tempdb_info.session_id = y.session_id ' +
						'AND COALESCE(tempdb_info.request_id, -1) = COALESCE(y.request_id, -1) ' +
					'OUTER APPLY ' +
					'( ' +
						'SELECT ' +
							'tasks_final.task_xml.value(''(tasks/physical_io/text())[1]'', ''BIGINT'') AS physical_io, ' +
							'tasks_final.task_xml.value(''(tasks/context_switches/text())[1]'', ''BIGINT'') AS context_switches, ' +
							'tasks_final.task_xml.value(''(tasks/tasks/text())[1]'', ''INT'') AS tasks, ' +
							'tasks_final.task_xml.value(''(tasks/blocking_session_id/text())[1]'', ''SMALLINT'') AS blocking_session_id, ' +
							'tasks_final.task_xml.value(''(tasks/text())[1]'', ''VARCHAR(8000)'') AS wait_info ' +
						'FROM ' +
						'( ' +
							'SELECT ' +
								'CONVERT ' +
								'( ' +
									'XML, ' +
									'REPLACE( ' +
										'REPLACE( ' +
											'REPLACE( ' +
												'CONVERT(VARCHAR(MAX), tasks_raw.task_xml_raw) COLLATE Latin1_General_Bin2, ' +
												'''</tasks><tasks>'', ''''), ' +
											'''<waits>'', ''''), ' +
										'''</waits>'', '', '') ' +
								') AS task_xml ' +
							'FROM ' +
							'( ' +
								'SELECT ' +
									'CASE waits.r ' +
										'WHEN 1 THEN waits.physical_io ' +
										'ELSE NULL ' +
									'END AS [physical_io], ' +
									'CASE waits.r ' +
										'WHEN 1 THEN waits.context_switches ' +
										'ELSE NULL ' +
									'END AS [context_switches], ' +
									'CASE waits.r ' +
										'WHEN 1 THEN waits.tasks ' +
										'ELSE NULL ' +
									'END AS [tasks], ' +
									'CASE waits.r ' +
										'WHEN 1 THEN waits.blocking_session_id ' +
										'ELSE NULL ' +
									'END AS [blocking_session_id], ' +
									'REPLACE ' +
									'( ' +
										'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
											'CONVERT ' +
											'( ' +
												'VARCHAR(MAX), ' +
												'''('' + ' +
													'CONVERT(VARCHAR, num_waits) + ''x: '' + ' +
													'CASE num_waits ' +
														'WHEN 1 THEN CONVERT(VARCHAR, min_wait_time) + ''ms'' ' +
														'WHEN 2 THEN ' +
															'CASE ' +
																'WHEN min_wait_time <> max_wait_time THEN CONVERT(VARCHAR, min_wait_time) + ''/'' + CONVERT(VARCHAR, max_wait_time) + ''ms'' ' +
																'ELSE CONVERT(VARCHAR, max_wait_time) + ''ms'' ' +
															'END ' +
														'ELSE ' +
															'CASE ' +
																'WHEN min_wait_time <> max_wait_time THEN CONVERT(VARCHAR, min_wait_time) + ''/'' + CONVERT(VARCHAR, avg_wait_time) + ''/'' + CONVERT(VARCHAR, max_wait_time) + ''ms'' ' +
																'ELSE CONVERT(VARCHAR, max_wait_time) + ''ms'' ' +
															'END ' +
													'END + ' +
												''')'' + wait_type COLLATE Latin1_General_BIN2 ' +
											'), ' +
											'CHAR(31),''''),CHAR(30),''''),CHAR(29),''''),CHAR(28),''''),CHAR(27),''''),CHAR(26),''''),CHAR(25),''''),CHAR(24),''''),CHAR(23),''''),CHAR(22),''''), ' +
											'CHAR(21),''''),CHAR(20),''''),CHAR(19),''''),CHAR(18),''''),CHAR(17),''''),CHAR(16),''''),CHAR(15),''''),CHAR(14),''''),CHAR(12),''''), ' +
											'CHAR(11),''''),CHAR(8),''''),CHAR(7),''''),CHAR(6),''''),CHAR(5),''''),CHAR(4),''''),CHAR(3),''''),CHAR(2),''''),CHAR(1),''''), ' +
										'CHAR(0), ' +
										''''' ' +
									') AS [waits] ' +
								'FROM ' +
								'( ' +
									'SELECT ' +
										'w2.*, ' +
										'ROW_NUMBER() OVER (ORDER BY w2.num_waits DESC, w2.wait_type) AS r ' +
									'FROM ' +
									'( ' +
										'SELECT DISTINCT ' +
											'w1.physical_io, ' +
											'w1.context_switches, ' +
											'MAX(w1.num_tasks) OVER () AS tasks, ' +
											'w1.wait_type, ' +
											'MAX(w1.num_waits) OVER (PARTITION BY w1.wait_type) AS num_waits, ' +
											'w1.min_wait_time, ' +
											'w1.avg_wait_time, ' +
											'w1.max_wait_time, ' +
											'w1.blocking_session_id ' +
										'FROM ' +
										'( ' +
											'SELECT ' +
												'SUM(CONVERT(BIGINT, t.pending_io_count)) OVER () AS physical_io, ' +
												'SUM(CONVERT(BIGINT, t.context_switches_count)) OVER () AS context_switches, ' +
												'ROW_NUMBER() OVER (ORDER BY t.exec_context_id) AS num_tasks, ' +
												'wt2.wait_type, ' +
												'CASE ' +
													'WHEN wt2.waiting_task_address IS NOT NULL THEN ' +
														'DENSE_RANK() OVER (PARTITION BY wt2.wait_type ORDER BY wt2.waiting_task_address)  ' +
													'ELSE NULL ' +
												'END AS num_waits, ' +
												'MIN(wt2.wait_duration_ms) OVER (PARTITION BY wt2.wait_type) AS min_wait_time, ' +
												'AVG(wt2.wait_duration_ms) OVER (PARTITION BY wt2.wait_type) AS avg_wait_time, ' +
												'MAX(wt2.wait_duration_ms) OVER (PARTITION BY wt2.wait_type) AS max_wait_time, ' +
												'MAX(wt2.blocking_session_id) OVER () AS blocking_session_id ' +
											'FROM sys.sysprocesses AS sp2 ' +
											'INNER JOIN sys.dm_os_tasks AS t ON ' +
												't.session_id = sp2.spid ' +
											'INNER JOIN sys.dm_os_threads AS th ON ' +
												'sp2.kpid = th.os_thread_id ' +
											'INNER JOIN sys.dm_os_workers AS w ON ' +
												'w.thread_address = th.thread_address ' +
												'AND t.worker_address = w.worker_address ' +
											'LEFT OUTER JOIN ' +
											'( ' +
												'SELECT ' +
													'wt1.wait_type, ' +
													'wt1.waiting_task_address, ' +
													'SUM(wt1.wait_duration_ms) AS wait_duration_ms, ' +
													'MAX(wt1.blocking_session_id) AS blocking_session_id ' +
												'FROM ' +
												'( ' +
													'SELECT DISTINCT ' +
														'wt.wait_type + ' +
															--TODO: What else can be pulled from the resource_description?
															'CASE ' +
																'WHEN wt.wait_type LIKE ''PAGE%LATCH_%'' THEN ' +
																	''':'' + ' +
																	--database name
																	'COALESCE(DB_NAME(CONVERT(INT, LEFT(wt.resource_description, CHARINDEX('':'', wt.resource_description) - 1))), ''(null)'') + ' +
																	''':'' + ' +
																	--file id
																	'SUBSTRING(wt.resource_description, CHARINDEX('':'', wt.resource_description) + 1, LEN(wt.resource_description) - CHARINDEX('':'', REVERSE(wt.resource_description)) - CHARINDEX('':'', wt.resource_description)) + ' +
																	--page # for special pages
																	'''('' + ' +
																		'CASE ' +
																			'WHEN ' +
																				'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) = 1 OR ' +
																				'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) % 8088 = 0 THEN ''PFS'' ' +
																			'WHEN ' +
																				'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) = 2 OR ' +
																				'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) % 511232 = 0 THEN ''GAM'' ' +
																			'WHEN ' +
																				'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) = 3 OR ' +
																				'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) % 511233 = 0 THEN ''SGAM'' ' +
																			'WHEN ' +
																				'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) = 6 OR ' +
																				'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) % 511238 = 0 THEN ''DCM'' ' +
																			'WHEN ' +
																				'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) = 7 OR ' +
																				'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) % 511239 = 0 THEN ''BCM'' ' +
																			'ELSE ''*'' ' +
																		'END + ' +
																	''')'' ' +
																'ELSE '''' ' +
															'END COLLATE Latin1_General_Bin2 AS wait_type, ' +
														'wt.wait_duration_ms, ' +
														'wt.waiting_task_address, ' +
														'wt.blocking_session_id ' +
													'FROM ' +
													'( ' +
														'SELECT ' +
															'CONVERT(VARCHAR(120), wt0.wait_type) COLLATE Latin1_General_Bin2 AS wait_type, ' +
															'CONVERT(VARCHAR(2048), wt0.resource_description) COLLATE Latin1_General_Bin2 AS resource_description, ' +
															'wt0.wait_duration_ms, ' +
															'wt0.waiting_task_address, ' +
															'CASE ' +
																'WHEN wt0.blocking_session_id <> wt0.session_id THEN wt0.blocking_session_id ' +
																'ELSE NULL ' +
															'END AS blocking_session_id ' +
														'FROM sys.dm_os_waiting_tasks AS wt0 ' +
													') AS wt ' +
												') AS wt1 ' +
												'GROUP BY ' +
													'wt1.wait_type, ' +
													'wt1.waiting_task_address ' +
												'' +
												'UNION ALL ' + 
												'' + 
												'SELECT ' +
													'state, ' +
													'task_address, ' +
													'( ' +
														'SELECT ' +
															'ms_ticks ' +
														'FROM sys.dm_os_sys_info ' +
													') - ' +
														'wait_resumed_ms_ticks, ' +
													'NULL ' +
												'FROM sys.dm_os_workers ' +
												'WHERE ' +
													'state = ''RUNNABLE'' ' +
											') AS wt2 ON ' +
												'wt2.waiting_task_address = t.task_address ' +
												'AND wt2.wait_duration_ms > 0 ' +
												'AND ' +
												'( ' +
													'( ' +
														't.task_state = ''SUSPENDED'' ' +
														'AND wt2.wait_type <> ''RUNNABLE'' ' +
													') ' +
													'OR ' +
													'( ' +
														't.task_state = ''RUNNABLE'' ' +
														'AND wt2.wait_type = ''RUNNABLE'' ' +
													') ' +
												') ' +
											'WHERE ' +
												'sp2.spid = y.session_id ' + 
												'AND sp2.request_id = y.request_id ' +
										') AS w1 ' +
									') AS w2 ' +
								') AS waits ' +
								'ORDER BY ' +
									'waits.r ' +
								'FOR XML PATH(''tasks'') ' +
							') AS tasks_raw (task_xml_raw) ' +
						') AS tasks_final ' +
					') AS tasks ' +
					CASE 
						WHEN NOT (@get_avg_time = 1 AND @recursion = 1) THEN ''
						ELSE
							'LEFT OUTER JOIN sys.dm_exec_query_stats AS qs ON ' +
								'qs.sql_handle = y.sql_handle ' + 
								'AND qs.plan_handle = y.plan_handle ' + 
								'AND qs.statement_start_offset = y.statement_start_offset ' +
								'AND qs.statement_end_offset = y.statement_end_offset '
						END + 
				') x; '
			--End derived table "x"
			);

		SET @sql_n = CONVERT(NVARCHAR(MAX), @sql);

		INSERT #sessions
		(
			recursion,
			session_id,
			request_id,
			session_number,
			elapsed_time,
			avg_elapsed_time,
			physical_io,
			reads,
			physical_reads,
			writes,
			tempdb_writes,
			tempdb_current,
			CPU,
			context_switches,
			used_memory,
			tasks,
			status,
			wait_info,
			tran_start_time,
			tran_log_writes,
			open_tran_count,
			sql_handle,
			statement_start_offset,
			statement_end_offset,		
			sql_text,
			plan_handle,
			blocking_session_id,
			percent_complete,
			host_name,
			login_name,
			database_name,
			program_name,
			start_time,
			last_request_start_time
		)
		EXEC sp_executesql 
			@sql_n,
			N'@recursion SMALLINT, @filter VARCHAR(128)',
			@recursion, @filter;

		--Variables for text and plan collection
		DECLARE	
			@sql_handle VARBINARY(64),
			@plan_handle VARBINARY(64),
			@statement_start_offset INT,
			@statement_end_offset INT;
						
		IF 
			@recursion = 1
			AND @output_column_list LIKE '%|[sql_text|]%' ESCAPE '|'
		BEGIN
			DECLARE sql_cursor
			CURSOR LOCAL FORWARD_ONLY DYNAMIC OPTIMISTIC
			FOR 
				SELECT 
					sql_handle,
					statement_start_offset,
					statement_end_offset
				FROM #sessions
				WHERE
					recursion = 1
			FOR UPDATE OF 
				sql_text
			OPTION (KEEPFIXED PLAN);

			OPEN sql_cursor;

			FETCH NEXT FROM sql_cursor
			INTO 
				@sql_handle,
				@statement_start_offset,
				@statement_end_offset;

			--Wait up to 5 ms for the SQL text, then give up
			SET LOCK_TIMEOUT 5;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					UPDATE s
					SET
						s.sql_text =
						(
							SELECT
								REPLACE
								(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
										CONVERT
										(
											VARCHAR(MAX),
											'--' + CHAR(13) + CHAR(10) +
											CASE @get_full_inner_text
												WHEN 1 THEN est.text
												ELSE
													CASE
														WHEN @statement_start_offset > 0 THEN
															SUBSTRING
															(
																CONVERT(VARCHAR(MAX), est.text),
																((@statement_start_offset/2) + 1),
																(
																	CASE
																		WHEN @statement_end_offset = -1 THEN 2147483647
																		ELSE ((@statement_end_offset - @statement_start_offset)/2) + 1
																	END
																)
															)
														ELSE RTRIM(LTRIM(est.text))
													END
											END +
											CHAR(13) + CHAR(10) + '--' COLLATE Latin1_General_BIN2
										),
										CHAR(31),''),CHAR(30),''),CHAR(29),''),CHAR(28),''),CHAR(27),''),CHAR(26),''),CHAR(25),''),CHAR(24),''),CHAR(23),''),CHAR(22),''),
										CHAR(21),''),CHAR(20),''),CHAR(19),''),CHAR(18),''),CHAR(17),''),CHAR(16),''),CHAR(15),''),CHAR(14),''),CHAR(12),''),
										CHAR(11),''),CHAR(8),''),CHAR(7),''),CHAR(6),''),CHAR(5),''),CHAR(4),''),CHAR(3),''),CHAR(2),''),CHAR(1),''),
									CHAR(0),
									''
								) AS [processing-instruction(query)]
							FROM sys.dm_exec_sql_text(@sql_handle) AS est
							FOR XML PATH(''), TYPE
					)
					FROM #sessions s
					WHERE 
						CURRENT OF sql_cursor
					OPTION (KEEPFIXED PLAN);
				END TRY
				BEGIN CATCH;
					UPDATE s
					SET
						s.sql_text = 
							CASE ERROR_NUMBER() 
								WHEN 1222 THEN '<timeout_exceeded />'
								ELSE '<error message="' + ERROR_MESSAGE() + '" />'
							END
					FROM #sessions AS s
					WHERE 
						CURRENT OF sql_cursor
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT FROM sql_cursor
				INTO
					@sql_handle,
					@statement_start_offset,
					@statement_end_offset;
			END;

			--Return this to the default
			SET LOCK_TIMEOUT -1;

			CLOSE sql_cursor;
			DEALLOCATE sql_cursor;
		END;

		IF 
			@get_outer_command = 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[sql_command|]%' ESCAPE '|'
		BEGIN;
			DECLARE 
				@session_id INT,
				@start_time DATETIME;

			DECLARE @buffer_results TABLE
			(
				EventType VARCHAR(30),
				Parameters INT,
				EventInfo VARCHAR(4000),
				start_time DATETIME,
				session_number INT IDENTITY(1,1) NOT NULL PRIMARY KEY
			);

			DECLARE buffer_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT 
					session_id,
					MAX(start_time) AS start_time
				FROM #sessions
				WHERE
					recursion = 1
				GROUP BY
					session_id
				ORDER BY
					session_id
				OPTION (KEEPFIXED PLAN);

			OPEN buffer_cursor;

			FETCH NEXT FROM buffer_cursor
			INTO 
				@session_id,
				@start_time;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					--In SQL Server 2008, DBCC INPUTBUFFER will throw 
					--an exception if the session no longer exists
					INSERT @buffer_results
					(
						EventType,
						Parameters,
						EventInfo
					)
					EXEC sp_executesql
						N'DBCC INPUTBUFFER(@session_id) WITH NO_INFOMSGS;',
						N'@session_id INT',
						@session_id;

					UPDATE br
					SET
						br.start_time = @start_time
					FROM @buffer_results AS br
					WHERE
						br.session_number = 
						(
							SELECT MAX(br2.session_number)
							FROM @buffer_results br2
						);
				END TRY
				BEGIN CATCH
				END CATCH;

				FETCH NEXT FROM buffer_cursor
				INTO 
					@session_id,
					@start_time;
			END;

			UPDATE s
			SET
				sql_command = 
				(
					SELECT 
						REPLACE
						(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								CONVERT
								(
									VARCHAR(MAX),
									'--' + CHAR(13) + CHAR(10) + br.EventInfo + CHAR(13) + CHAR(10) + '--' COLLATE Latin1_General_BIN2
								),
								CHAR(31),''),CHAR(30),''),CHAR(29),''),CHAR(28),''),CHAR(27),''),CHAR(26),''),CHAR(25),''),CHAR(24),''),CHAR(23),''),CHAR(22),''),
								CHAR(21),''),CHAR(20),''),CHAR(19),''),CHAR(18),''),CHAR(17),''),CHAR(16),''),CHAR(15),''),CHAR(14),''),CHAR(12),''),
								CHAR(11),''),CHAR(8),''),CHAR(7),''),CHAR(6),''),CHAR(5),''),CHAR(4),''),CHAR(3),''),CHAR(2),''),CHAR(1),''),
							CHAR(0),
							''
						) AS [processing-instruction(query)]
					FROM @buffer_results AS br
					WHERE 
						br.session_number = s.session_number
						AND br.start_time = s.start_time
						AND 
						(
							(
								s.start_time = s.last_request_start_time
								AND EXISTS
								(
									SELECT *
									FROM sys.dm_exec_requests r2
									WHERE
										r2.session_id = s.session_id
										AND r2.request_id = s.request_id
										AND r2.start_time = s.start_time
								)
							)
							OR 
							(
								s.status = 'sleeping'
								AND EXISTS
								(
									SELECT *
									FROM sys.dm_exec_sessions s2
									WHERE
										s2.session_id = s.session_id
										AND s2.last_request_start_time = s.last_request_start_time
								)
							)
						)
					FOR XML PATH(''), TYPE
				)
			FROM #sessions AS s
			WHERE
				recursion = 1
			OPTION (KEEPFIXED PLAN);

			CLOSE buffer_cursor;
			DEALLOCATE buffer_cursor;
		END;

		IF 
			@get_plans >= 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[query_plan|]%' ESCAPE '|'
		BEGIN;
			DECLARE plan_cursor
			CURSOR LOCAL FORWARD_ONLY DYNAMIC OPTIMISTIC
			FOR 
				SELECT 
					plan_handle,
					statement_start_offset,
					statement_end_offset
				FROM #sessions
				WHERE
					recursion = 1
			FOR UPDATE OF 
				query_plan
			OPTION (KEEPFIXED PLAN);

			OPEN plan_cursor;

			FETCH NEXT FROM plan_cursor
			INTO 
				@plan_handle,
				@statement_start_offset,
				@statement_end_offset;

			--Wait up to 5 ms for a query plan, then give up
			SET LOCK_TIMEOUT 5;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					UPDATE s
					SET
						s.query_plan =
						(
							SELECT CONVERT(xml, query_plan)
							FROM sys.dm_exec_text_query_plan(@plan_handle, @statement_start_offset, @statement_end_offset)
							WHERE
								@get_plans = 1

							UNION ALL

							SELECT query_plan
							FROM sys.dm_exec_query_plan(@plan_handle)
							WHERE
								@get_plans = 2
						)
					FROM #sessions AS s
					WHERE 
						CURRENT OF plan_cursor
					OPTION (KEEPFIXED PLAN);
				END TRY
				BEGIN CATCH;
					UPDATE s
					SET
						s.query_plan = 
							CASE ERROR_NUMBER() 
								WHEN 1222 THEN '<timeout_exceeded />'
								ELSE '<error message="' + ERROR_MESSAGE() + '" />'
							END
					FROM #sessions AS s
					WHERE 
						CURRENT OF plan_cursor
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT FROM plan_cursor
				INTO
					@plan_handle,
					@statement_start_offset,
					@statement_end_offset;
			END;

			--Return this to the default
			SET LOCK_TIMEOUT -1;

			CLOSE plan_cursor;
			DEALLOCATE plan_cursor;
		END;

		IF 
			@get_locks = 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[locks|]%' ESCAPE '|'
		BEGIN;
			DECLARE @DB_NAME sysname;

			DECLARE locks_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT DISTINCT
					db_name
				FROM #locks
				WHERE
					EXISTS
					(
						SELECT *
						FROM #sessions AS s
						WHERE
							s.session_id = #locks.session_id
							AND recursion = 1
					)
					AND db_name <> '(null)'
				OPTION (KEEPFIXED PLAN);

			OPEN locks_cursor;

			FETCH NEXT  FROM locks_cursor
			INTO @DB_NAME;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					SET @sql_n = CONVERT(NVARCHAR(MAX), '') +
						'UPDATE l ' +
						'SET ' +
							'object_name = o.name, ' +
							'index_name = i.name, ' +
							'schema_name = s.name, ' +
							'principal_name = dp.name ' +
						'FROM #locks AS l ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.allocation_units AS au ON ' +
							'au.allocation_unit_id = l.allocation_unit_id ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.partitions AS p ON ' +
							'p.hobt_id = ' +
								'COALESCE ' +
								'( ' +
									'l.hobt_id, ' +
									'CASE ' +
										'WHEN au.type IN (1, 3) THEN au.container_id ' +
										'ELSE NULL ' +
									'END ' +
								') ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.partitions AS p1 ON ' +
							'l.hobt_id IS NULL ' +
							'AND au.type = 2 ' +
							'AND p1.partition_id = au.container_id ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.objects AS o ON ' +
							'o.object_id = COALESCE(l.object_id, p.object_id, p1.object_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.indexes AS i ON ' +
							'i.object_id = COALESCE(l.object_id, p.object_id, p1.object_id) ' +
							'AND i.index_id = COALESCE(l.index_id, p.index_id, p1.index_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.schemas AS s ON ' +
							's.schema_id = COALESCE(l.schema_id, o.schema_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.database_principals AS dp ON ' +
							'dp.principal_id = l.principal_id ' +
						'WHERE ' +
							'l.db_name = @DB_NAME ' +
						'OPTION (KEEPFIXED PLAN); ';
					
					EXEC sp_executesql
						@sql_n,
						N'@DB_NAME sysname',
						@DB_NAME;
				END TRY
				BEGIN CATCH;
					UPDATE #locks
					SET 
						object_name = '(db_inaccessible)'
					WHERE 
						db_name = @DB_NAME
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT  FROM locks_cursor
				INTO @DB_NAME;
			END;

			CLOSE locks_cursor;
			DEALLOCATE locks_cursor;

			CREATE CLUSTERED INDEX IX_SRD ON #locks (session_id, request_id, db_name);

			UPDATE s
			SET 
				s.locks =
				(
					SELECT 
						REPLACE
						(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								CONVERT
								(
									VARCHAR(MAX), 
									l1.db_name COLLATE Latin1_General_BIN2
								),
								CHAR(31),''),CHAR(30),''),CHAR(29),''),CHAR(28),''),CHAR(27),''),CHAR(26),''),CHAR(25),''),CHAR(24),''),CHAR(23),''),CHAR(22),''),
								CHAR(21),''),CHAR(20),''),CHAR(19),''),CHAR(18),''),CHAR(17),''),CHAR(16),''),CHAR(15),''),CHAR(14),''),CHAR(12),''),
								CHAR(11),''),CHAR(8),''),CHAR(7),''),CHAR(6),''),CHAR(5),''),CHAR(4),''),CHAR(3),''),CHAR(2),''),CHAR(1),''),
							CHAR(0),
							''
						) AS [Database/@name],
						(
							SELECT 
								l2.request_mode AS [Lock/@request_mode],
								l2.request_status AS [Lock/@request_status],
								COUNT(*) AS [Lock/@request_count]
							FROM #locks AS l2
							WHERE 
								l1.session_id = l2.session_id
								AND l1.request_id = l2.request_id
								AND l2.db_name = l1.db_name
								AND l2.resource_type = 'DATABASE'
							GROUP BY
								l2.request_mode,
								l2.request_status
							FOR XML PATH(''), TYPE
						) AS [Database/Locks],
						(
							SELECT
								COALESCE(l3.object_name, '(null)') AS [Object/@name],
								l3.schema_name AS [Object/@schema_name],
								(
									SELECT
										l4.resource_type AS [Lock/@resource_type],
										l4.page_type AS [Lock/@page_type],
										REPLACE
										(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
												CONVERT
												(
													VARCHAR(MAX), 
													l4.index_name COLLATE Latin1_General_BIN2
												),
												CHAR(31),''),CHAR(30),''),CHAR(29),''),CHAR(28),''),CHAR(27),''),CHAR(26),''),CHAR(25),''),CHAR(24),''),CHAR(23),''),CHAR(22),''),
												CHAR(21),''),CHAR(20),''),CHAR(19),''),CHAR(18),''),CHAR(17),''),CHAR(16),''),CHAR(15),''),CHAR(14),''),CHAR(12),''),
												CHAR(11),''),CHAR(8),''),CHAR(7),''),CHAR(6),''),CHAR(5),''),CHAR(4),''),CHAR(3),''),CHAR(2),''),CHAR(1),''),
											CHAR(0),
											''
										) AS [Lock/@index_name],
										REPLACE
										(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
												CONVERT
												(
													VARCHAR(MAX), 								
													CASE 
														WHEN l4.object_name IS NULL THEN l4.schema_name
														ELSE NULL
													END COLLATE Latin1_General_BIN2
												),
												CHAR(31),''),CHAR(30),''),CHAR(29),''),CHAR(28),''),CHAR(27),''),CHAR(26),''),CHAR(25),''),CHAR(24),''),CHAR(23),''),CHAR(22),''),
												CHAR(21),''),CHAR(20),''),CHAR(19),''),CHAR(18),''),CHAR(17),''),CHAR(16),''),CHAR(15),''),CHAR(14),''),CHAR(12),''),
												CHAR(11),''),CHAR(8),''),CHAR(7),''),CHAR(6),''),CHAR(5),''),CHAR(4),''),CHAR(3),''),CHAR(2),''),CHAR(1),''),
											CHAR(0),
											''
										) AS [Lock/@schema_name],
										REPLACE
										(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
												CONVERT
												(
													VARCHAR(MAX), 								
													l4.principal_name COLLATE Latin1_General_BIN2
												),
												CHAR(31),''),CHAR(30),''),CHAR(29),''),CHAR(28),''),CHAR(27),''),CHAR(26),''),CHAR(25),''),CHAR(24),''),CHAR(23),''),CHAR(22),''),
												CHAR(21),''),CHAR(20),''),CHAR(19),''),CHAR(18),''),CHAR(17),''),CHAR(16),''),CHAR(15),''),CHAR(14),''),CHAR(12),''),
												CHAR(11),''),CHAR(8),''),CHAR(7),''),CHAR(6),''),CHAR(5),''),CHAR(4),''),CHAR(3),''),CHAR(2),''),CHAR(1),''),
											CHAR(0),
											''
										) AS [Lock/@principal_name],
										l4.resource_description AS [Lock/@resource_description],
										l4.request_mode AS [Lock/@request_mode],
										l4.request_status AS [Lock/@request_status],
										SUM(l4.request_count) AS [Lock/@request_count]
									FROM #locks AS l4
									WHERE 
										l4.session_id = l3.session_id
										AND l4.request_id = l3.request_id
										AND l3.db_name = l4.db_name
										AND COALESCE(l3.object_name, '(null)') = COALESCE(l4.object_name, '(null)')
										AND COALESCE(l3.schema_name, '') = COALESCE(l4.schema_name, '')
										AND l4.resource_type <> 'DATABASE'
									GROUP BY
										l4.resource_type,
										l4.page_type,
										l4.index_name,
										CASE 
											WHEN l4.object_name IS NULL THEN l4.schema_name
											ELSE NULL
										END,
										l4.principal_name,
										l4.resource_description,
										l4.request_mode,
										l4.request_status
									FOR XML PATH(''), TYPE
								) AS [Object/Locks]
							FROM #locks AS l3
							WHERE 
								l3.session_id = l1.session_id
								AND l3.request_id = l1.request_id
								AND l3.db_name = l1.db_name
								AND l3.resource_type <> 'DATABASE'
							GROUP BY 
								l3.session_id,
								l3.request_id,
								l3.db_name,
								COALESCE(l3.object_name, '(null)'),
								l3.schema_name
							FOR XML PATH(''), TYPE
						) AS [Database/Objects]
					FROM #locks AS l1
					WHERE
						l1.session_id = s.session_id
						AND l1.request_id = COALESCE(s.request_id, -1)
						AND 
						(
							(
								s.request_id IS NULL 
								AND l1.start_time = s.last_request_start_time
							)
							OR
							(
								s.request_id IS NOT NULL 
								AND l1.start_time = s.start_time
							)
						)
						AND s.recursion = 1
					GROUP BY 
						l1.session_id,
						l1.request_id,
						l1.db_name
					FOR XML PATH(''), TYPE
				)
			FROM #sessions s
			OPTION (KEEPFIXED PLAN);
		END;

		IF 
			@find_block_leaders = 1
			AND @recursion = 1
			AND @output_column_list LIKE '%|[blocked_session_count|]%' ESCAPE '|'
		BEGIN;
			WITH
			blockers AS
			(
				SELECT
					session_id,
					session_id AS top_level_session_id
				FROM #sessions
				WHERE
					recursion = 1

				UNION ALL

				SELECT
					s.session_id,
					b.top_level_session_id
				FROM blockers AS b
				JOIN #sessions AS s ON
					s.blocking_session_id = b.session_id
					AND s.recursion = 1
			)
			UPDATE s
			SET
				s.blocked_session_count = x.blocked_session_count
			FROM #sessions AS s
			JOIN
			(
				SELECT
					b.top_level_session_id AS session_id,
					COUNT(*) - 1 AS blocked_session_count
				FROM blockers AS b
				GROUP BY
					b.top_level_session_id
			) x ON
				s.session_id = x.session_id
			WHERE
				s.recursion = 1;
		END;
		
		IF 
			@delta_interval > 0 
			AND @recursion <> 1
		BEGIN;
			SET @recursion = 1;

			DECLARE @delay_time CHAR(12);
			SET @delay_time = CONVERT(VARCHAR, DATEADD(second, @delta_interval, 0), 114);
			WAITFOR DELAY @delay_time;

			GOTO REDO;
		END;
	END;

	SET @sql = 
		--Outer column list
		CONVERT
		(
			VARCHAR(MAX),
			CASE
				WHEN 
					@destination_table <> '' 
					AND @return_schema = 0 
						THEN 'INSERT ' + @destination_table + ' '
				ELSE ''
			END +
			'SELECT ' +
				@output_column_list + ' ' +
			CASE @return_schema
				WHEN 1 THEN 'INTO #session_schema '
				ELSE ''
			END
		--End outer column list
		) + 
		--Inner column list
		CONVERT
		(
			VARCHAR(MAX),
			'FROM ' +
			'( ' +
				'SELECT ' +
					'session_id, ' +
					--[dd hh:mm:ss.mss]
					CASE @format_output
						WHEN 1 THEN
							'CASE ' +
								'WHEN elapsed_time < 0 THEN ' +
									'RIGHT ' +
									'( ' +
										'''00'' + CONVERT(VARCHAR, (-1 * elapsed_time) / 86400), ' +
										'2 ' +
									') + ' +
										'RIGHT ' +
										'( ' +
											'CONVERT(VARCHAR, DATEADD(second, (-1 * elapsed_time), 0), 120), ' +
											'9 ' +
										') + ' +
										'''.000'' ' +
								'ELSE ' +
									'RIGHT ' +
									'( ' +
										'''00'' + CONVERT(VARCHAR, elapsed_time / 86400000), ' +
										'2 ' +
									') + ' +
										'RIGHT ' +
										'( ' +
											'CONVERT(VARCHAR, DATEADD(second, elapsed_time / 1000, 0), 120), ' +
											'9 ' +
										') + ' +
										'''.'' + ' + 
										'RIGHT(''000'' + CONVERT(VARCHAR, elapsed_time % 1000), 3) ' +
							'END AS [dd hh:mm:ss.mss], '
						ELSE
							''
					END +
					--[dd hh:mm:ss.mss (avg)] / avg_elapsed_time
					CASE @format_output
						WHEN 1 THEN 
							'RIGHT ' +
							'( ' +
								'''00'' + CONVERT(VARCHAR, avg_elapsed_time / 86400000), ' +
								'2 ' +
							') + ' +
								'RIGHT ' +
								'( ' +
									'CONVERT(VARCHAR, DATEADD(second, avg_elapsed_time / 1000, 0), 120), ' +
									'9 ' +
								') + ' +
								'''.'' + ' +
								'RIGHT(''000'' + CONVERT(VARCHAR, avg_elapsed_time % 1000), 3) AS [dd hh:mm:ss.mss (avg)], '
						ELSE
							'avg_elapsed_time, '
					END +
					--physical_io
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_io))) OVER() - LEN(CONVERT(VARCHAR, physical_io))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io), 1), 19)) AS '
						ELSE ''
					END + 'physical_io, ' +
					--reads
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, reads))) OVER() - LEN(CONVERT(VARCHAR, reads))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads), 1), 19)) AS '
						ELSE ''
					END + 'reads, ' +
					--physical_reads
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_reads))) OVER() - LEN(CONVERT(VARCHAR, physical_reads))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads), 1), 19)) AS '
						ELSE ''
					END + 'physical_reads, ' +
					--writes
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, writes))) OVER() - LEN(CONVERT(VARCHAR, writes))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes), 1), 19)) AS '
						ELSE ''
					END + 'writes, ' +
					--tempdb_writes
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_writes))) OVER() - LEN(CONVERT(VARCHAR, tempdb_writes))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_writes), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_writes), 1), 19)) AS '
						ELSE ''
					END + 'tempdb_writes, ' +
					--tempdb_current
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_current))) OVER() - LEN(CONVERT(VARCHAR, tempdb_current))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current), 1), 19)) AS '
						ELSE ''
					END + 'tempdb_current, ' +
					--CPU
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, CPU))) OVER() - LEN(CONVERT(VARCHAR, CPU))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU), 1), 19)) AS '
						ELSE ''
					END + 'CPU, ' +
					--context_switches
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, context_switches))) OVER() - LEN(CONVERT(VARCHAR, context_switches))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches), 1), 19)) AS '
						ELSE ''
					END + 'context_switches, ' +
					--used_memory
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, used_memory))) OVER() - LEN(CONVERT(VARCHAR, used_memory))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory), 1), 19)) AS '
						ELSE ''
					END + 'used_memory, ' +
					--physical_io_delta			
					'CASE ' +
						'WHEN ' +
							'first_request_start_time = last_request_start_time ' + 
							'AND num_events = 2 ' +
							'AND physical_io_delta >= 0 ' +
								'THEN ' +
								CASE @format_output
									WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_io_delta))) OVER() - LEN(CONVERT(VARCHAR, physical_io_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io_delta), 1), 19)) ' 
									WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io_delta), 1), 19)) '
									ELSE 'physical_io_delta '
								END +
						'ELSE NULL ' +
					'END AS physical_io_delta, ' +
					--reads_delta
					'CASE ' +
						'WHEN ' +
							'first_request_start_time = last_request_start_time ' + 
							'AND num_events = 2 ' +
							'AND reads_delta >= 0 ' +
								'THEN ' +
								CASE @format_output
									WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, reads_delta))) OVER() - LEN(CONVERT(VARCHAR, reads_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads_delta), 1), 19)) '
									WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads_delta), 1), 19)) '
									ELSE 'reads_delta '
								END +
						'ELSE NULL ' +
					'END AS reads_delta, ' +
					--physical_reads_delta
					'CASE ' +
						'WHEN ' +
							'first_request_start_time = last_request_start_time ' + 
							'AND num_events = 2 ' +
							'AND physical_reads_delta >= 0 ' +
								'THEN ' +
								CASE @format_output
									WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_reads_delta))) OVER() - LEN(CONVERT(VARCHAR, physical_reads_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads_delta), 1), 19)) '
									WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads_delta), 1), 19)) '
									ELSE 'physical_reads_delta '
								END + 
						'ELSE NULL ' +
					'END AS physical_reads_delta, ' +
					--writes_delta
					'CASE ' +
						'WHEN ' +
							'first_request_start_time = last_request_start_time ' + 
							'AND num_events = 2 ' +
							'AND writes_delta >= 0 ' +
								'THEN ' +
								CASE @format_output
									WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, writes_delta))) OVER() - LEN(CONVERT(VARCHAR, writes_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes_delta), 1), 19)) '
									WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes_delta), 1), 19)) '
									ELSE 'writes_delta '
								END + 
						'ELSE NULL ' +
					'END AS writes_delta, ' +
					--tempdb_writes_delta
					'CASE ' +
						'WHEN ' +
							'first_request_start_time = last_request_start_time ' + 
							'AND num_events = 2 ' +
							'AND tempdb_writes_delta >= 0 ' +
								'THEN ' +
								CASE @format_output
									WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_writes_delta))) OVER() - LEN(CONVERT(VARCHAR, tempdb_writes_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_writes_delta), 1), 19)) '
									WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_writes_delta), 1), 19)) '
									ELSE 'tempdb_writes_delta '
								END + 
						'ELSE NULL ' +
					'END AS tempdb_writes_delta, ' +
					--tempdb_current_delta
					--this is the only one that can (legitimately) go negative 
					'CASE ' +
						'WHEN ' +
							'first_request_start_time = last_request_start_time ' + 
							'AND num_events = 2 ' +
								'THEN ' +
								CASE @format_output
									WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_current_delta))) OVER() - LEN(CONVERT(VARCHAR, tempdb_current_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current_delta), 1), 19)) '
									WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current_delta), 1), 19)) '
									ELSE 'tempdb_current_delta '
								END + 
						'ELSE NULL ' +
					'END AS tempdb_current_delta, ' +
					--CPU_delta
					'CASE ' +
						'WHEN ' +
							'first_request_start_time = last_request_start_time ' + 
							'AND num_events = 2 ' +
							'AND CPU_delta >= 0 ' +
								'THEN ' +
								CASE @format_output
									WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, CPU_delta))) OVER() - LEN(CONVERT(VARCHAR, CPU_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU_delta), 1), 19)) '
									WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU_delta), 1), 19)) '
									ELSE 'CPU_delta '
								END + 
						'ELSE NULL ' +
					'END AS CPU_delta, ' +
					--context_switches_delta
					'CASE ' +
						'WHEN ' +
							'first_request_start_time = last_request_start_time ' + 
							'AND num_events = 2 ' +
							'AND context_switches_delta >= 0 ' +
								'THEN ' +
								CASE @format_output
									WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, context_switches_delta))) OVER() - LEN(CONVERT(VARCHAR, context_switches_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches_delta), 1), 19)) '
									WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches_delta), 1), 19)) '
									ELSE 'context_switches_delta '
								END + 
						'ELSE NULL ' +
					'END AS context_switches_delta, ' +
					--used_memory_delta
					'CASE ' +
						'WHEN ' +
							'first_request_start_time = last_request_start_time ' + 
							'AND num_events = 2 ' +
							'AND used_memory_delta >= 0 ' +
								'THEN ' +
								CASE @format_output
									WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, used_memory_delta))) OVER() - LEN(CONVERT(VARCHAR, used_memory_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory_delta), 1), 19)) '
									WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory_delta), 1), 19)) '
									ELSE 'used_memory_delta '
								END + 
						'ELSE NULL ' +
					'END AS used_memory_delta, ' +
					--tasks
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tasks))) OVER() - LEN(CONVERT(VARCHAR, tasks))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tasks), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tasks), 1), 19)) '
						ELSE ''
					END + 'tasks, ' +
					'status, ' +
					'LEFT(wait_info, LEN(wait_info) - 1) AS wait_info, ' +
					'locks, ' +
					'tran_start_time, ' +
					'LEFT(tran_log_writes, LEN(tran_log_writes) - 1) AS tran_log_writes, ' +
					--open_tran_count
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, open_tran_count))) OVER() - LEN(CONVERT(VARCHAR, open_tran_count))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, open_tran_count), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, open_tran_count), 1), 19)) AS '
						ELSE ''
					END + 'open_tran_count, ' +
					--sql_command
					CASE @format_output 
						WHEN 0 THEN 'REPLACE(REPLACE(CONVERT(VARCHAR(MAX), sql_command), ''<?query --''+CHAR(13)+CHAR(10), ''''), CHAR(13)+CHAR(10)+''--?>'', '''') AS '
						ELSE ''
					END + 'sql_command, ' +
					--sql_text
					CASE @format_output 
						WHEN 0 THEN 'REPLACE(REPLACE(CONVERT(VARCHAR(MAX), sql_text), ''<?query --''+CHAR(13)+CHAR(10), ''''), CHAR(13)+CHAR(10)+''--?>'', '''') AS '
						ELSE ''
					END + 'sql_text, ' +
					'query_plan, ' +
					'blocking_session_id, ' +
					--blocked_session_count
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, blocked_session_count))) OVER() - LEN(CONVERT(VARCHAR, blocked_session_count))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, blocked_session_count), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, blocked_session_count), 1), 19)) AS '
						ELSE ''
					END + 'blocked_session_count, ' +
					--percent_complete
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, CONVERT(MONEY, percent_complete), 2))) OVER() - LEN(CONVERT(VARCHAR, CONVERT(MONEY, percent_complete), 2))) + CONVERT(CHAR(22), CONVERT(MONEY, percent_complete), 2)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, CONVERT(CHAR(22), CONVERT(MONEY, blocked_session_count), 1)) AS '
						ELSE ''
					END + 'percent_complete, ' +
					'host_name, ' +
					'login_name, ' +
					'database_name, ' +
					'program_name, ' +
					'start_time, ' +
					'request_id, ' +
					'GETDATE() AS collection_time '
		--End inner column list
		) +
		--Derived table and INSERT specification
		CONVERT
		(
			VARCHAR(MAX),
				'FROM ' +
				'( ' +
					'SELECT TOP(2147483647) ' +
						'*, ' +
						'MAX(physical_io * recursion) OVER (PARTITION BY session_id, request_id) + ' +
							'MIN(physical_io * recursion) OVER (PARTITION BY session_id, request_id) AS physical_io_delta, ' +
						'MAX(reads * recursion) OVER (PARTITION BY session_id, request_id) + ' +
							'MIN(reads * recursion) OVER (PARTITION BY session_id, request_id) AS reads_delta, ' +
						'MAX(physical_reads * recursion) OVER (PARTITION BY session_id, request_id) + ' +
							'MIN(physical_reads * recursion) OVER (PARTITION BY session_id, request_id) AS physical_reads_delta, ' +
						'MAX(writes * recursion) OVER (PARTITION BY session_id, request_id) + ' +
							'MIN(writes * recursion) OVER (PARTITION BY session_id, request_id) AS writes_delta, ' +
						'MAX(tempdb_writes * recursion) OVER (PARTITION BY session_id, request_id) + ' +
							'MIN(tempdb_writes * recursion) OVER (PARTITION BY session_id, request_id) AS tempdb_writes_delta, ' +
						'MAX(tempdb_current * recursion) OVER (PARTITION BY session_id, request_id) + ' +
							'MIN(tempdb_current * recursion) OVER (PARTITION BY session_id, request_id) AS tempdb_current_delta, ' +
						'MAX(CPU * recursion) OVER (PARTITION BY session_id, request_id) + ' +
							'MIN(CPU * recursion) OVER (PARTITION BY session_id, request_id) AS CPU_delta, ' +
						'MAX(context_switches * recursion) OVER (PARTITION BY session_id, request_id) + ' +
							'MIN(context_switches * recursion) OVER (PARTITION BY session_id, request_id) AS context_switches_delta, ' +
						'MAX(used_memory * recursion) OVER (PARTITION BY session_id, request_id) + ' +
							'MIN(used_memory * recursion) OVER (PARTITION BY session_id, request_id) AS used_memory_delta, ' +
						'MIN(last_request_start_time) OVER (PARTITION BY session_id, request_id) AS first_request_start_time, ' +
						'COUNT(*) OVER (PARTITION BY session_id, request_id) AS num_events ' +
					'FROM #sessions AS s1 ' +
					'ORDER BY ' +
						@sort_column + ' ' +
						@sort_column_direction + ' ' +
				') AS s ' +
				'WHERE ' +
					's.recursion = 1 ' +
			') x ' +
			'OPTION (KEEPFIXED PLAN); ' +
			'' +
			CASE @return_schema
				WHEN 1 THEN
					'SET @schema = ' +
						'''CREATE TABLE <table_name> ( '' + ' +
							'STUFF ' +
							'( ' +
								'( ' +
									'SELECT ' +
										''','' + ' +
										'QUOTENAME(COLUMN_NAME) + '' '' + ' +
										'DATA_TYPE + ' + 
										'CASE DATA_TYPE ' +
											'WHEN ''varchar'' THEN ''('' + COALESCE(NULLIF(CONVERT(VARCHAR, CHARACTER_MAXIMUM_LENGTH), ''-1''), ''max'') + '') '' ' +
											'ELSE '' '' ' +
										'END + ' +
										'CASE IS_NULLABLE ' +
											'WHEN ''NO'' THEN ''NOT '' ' +
											'ELSE '''' ' +
										'END + ''NULL'' AS [text()] ' +
									'FROM tempdb.INFORMATION_SCHEMA.COLUMNS ' +
									'WHERE ' +
										'TABLE_NAME = (SELECT name FROM tempdb.sys.objects WHERE object_id = OBJECT_ID(''tempdb..#session_schema'')) ' +
										'ORDER BY ' +
											'ORDINAL_POSITION ' +
									'FOR XML PATH('''') ' +
								'), + ' +
								'1, ' +
								'1, ' +
								''''' ' +
							') + ' +
						''')''; ' 
				ELSE ''
			END
		--End derived table and INSERT specification
		);

	SET @sql_n = CONVERT(NVARCHAR(MAX), @sql);

	EXEC sp_executesql
		@sql_n,
		N'@schema VARCHAR(MAX) OUTPUT',
		@schema OUTPUT;
END;
GO

dbo.sp_WhoIsActive