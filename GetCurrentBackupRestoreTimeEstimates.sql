SELECT 
	dmr.session_id,
	dmr.command,
	CONVERT(NUMERIC(6,2),dmr.percent_complete)AS [Percent Complete],
	CONVERT(VARCHAR(20),DATEADD(ms,dmr.estimated_completion_time,GetDate()),20) AS [ETA Completion Time],
	CONVERT(NUMERIC(10,2),dmr.total_elapsed_time/1000.0/60.0) AS [Elapsed Min],
	CONVERT(NUMERIC(10,2),dmr.estimated_completion_time/1000.0/60.0) AS [ETA Min],
	CONVERT(NUMERIC(10,2),dmr.estimated_completion_time/1000.0/60.0/60.0) AS [ETA Hours]
	,CONVERT(VARCHAR(1000),(SELECT SUBSTRING(text,dmr.statement_start_offset/2,	
								   CASE WHEN dmr.statement_end_offset = -1 THEN 1000 
								   ELSE (dmr.statement_end_offset-dmr.statement_start_offset)/2 END) 
							FROM sys.dm_exec_sql_text(sql_handle)
							)
					) [sqltxt]
FROM sys.dm_exec_requests dmr WHERE command IN ('BACKUP DATABASE')