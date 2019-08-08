USE tempdb
GO


--Server-wide wait stats
SELECT *
FROM sys.dm_os_wait_stats
WHERE waiting_tasks_count > 0
GO



DECLARE @DB_ID VARCHAR(10) = CONVERT(VARCHAR, DB_ID('adventureworks2008'))
DECLARE @SPID VARCHAR(10) = CONVERT(VARCHAR, @@SPID)

DECLARE @SQL VARCHAR(MAX) =
'CREATE EVENT SESSION sql_text_and_waits
ON SERVER
ADD EVENT
    sqlserver.sql_statement_starting
    (
		ACTION
		(
			sqlserver.tsql_stack,
			sqlserver.sql_text
		)
        WHERE
        (
			sqlserver.database_id = ' + @DB_ID + '
			AND sqlserver.session_id = ' + @SPID + '
        )
    ),
ADD EVENT
    sqlserver.sql_statement_completed
    (
        WHERE
        (
			sqlserver.database_id = ' + @DB_ID + '
			AND sqlserver.session_id = ' + @SPID + '
        )
    ),
ADD EVENT
	sqlos.wait_info
	(
        WHERE
        (
			sqlserver.database_id = ' + @DB_ID + '
			AND sqlserver.session_id = ' + @SPID + '
			--We only want the END of the wait event, not the beginning
			AND opcode = 1
        )
	)
ADD TARGET 
    package0.ring_buffer
    (
        SET 
            max_memory=4096
    )
WITH 
(
    MAX_MEMORY = 4096KB, 
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS, 
    MAX_DISPATCH_LATENCY = 1 SECONDS, 
    MEMORY_PARTITION_MODE = NONE, 
    TRACK_CAUSALITY = ON, 
    STARTUP_STATE = OFF
)'

EXEC(@SQL)
GO


ALTER EVENT SESSION sql_text_and_waits
ON SERVER
STATE = START
GO


--Force some page IO waits
DBCC DROPCLEANBUFFERS
GO


USE AdventureWorks2008
GO

--execution 1
SELECT SUM(CONVERT(BIGINT, LineTotal))
FROM AdventureWorks2008.Sales.SalesOrderDetail
go

--execution 2
SELECT SUM(CONVERT(BIGINT, LineTotal))
FROM AdventureWorks2008.Sales.SalesOrderDetail
go

USE tempdb
GO


SELECT
	CONVERT(xml, target_data)
FROM sys.dm_xe_session_targets st
JOIN sys.dm_xe_sessions s ON 
	s.address = st.event_session_address
WHERE
	s.name = 'sql_text_and_waits'
GO


;WITH 
waits_xml (x) AS
(
	--Convert the XML
	SELECT
		(
			SELECT
				CONVERT(xml, target_data)
			FROM sys.dm_xe_session_targets st
			JOIN sys.dm_xe_sessions s ON 
				s.address = st.event_session_address
			WHERE
				s.name = 'sql_text_and_waits'
		) AS [x]
	FOR XML PATH(''), TYPE
),
raw_values AS
(
	--Pull the values we care about
	SELECT
		e.node.value('./@name', 'varchar(4000)') AS event_name,
		e.node.value('./@timestamp', 'datetime') as timestamp,
		CASE e.node.value('./@name', 'varchar(4000)')
			WHEN 'wait_info' THEN e.node.value('(./data/text)[1]', 'varchar(4000)')
			ELSE NULL
		END AS wait_type,
		CONVERT
		(
			INT,
			CASE e.node.value('./@name', 'varchar(4000)')
				WHEN 'wait_info' THEN e.node.value('(./data)[3]', 'varchar(4000)')
				ELSE NULL
			END
		) AS wait_duration,
		CONVERT
		(
			INT,
			CASE e.node.value('./@name', 'varchar(4000)')
				WHEN 'wait_info' THEN e.node.value('(./data)[6]', 'varchar(4000)')
				ELSE NULL
			END
		) AS signal_duration,
		CONVERT
		(
			INT,
			CASE e.node.value('./@name', 'varchar(4000)')
				WHEN 'sql_statement_completed' THEN e.node.value('(./data)[4]', 'varchar(4000)')
				ELSE NULL
			END
		) AS statement_cpu_time,
		CONVERT
		(
			INT,
			CASE e.node.value('./@name', 'varchar(4000)')
				WHEN 'sql_statement_completed' THEN e.node.value('(./data)[5]', 'varchar(4000)')
				ELSE NULL
			END
		) AS statement_duration,
		CASE 
			WHEN e.node.value('./@name', 'varchar(4000)') LIKE '%statement_starting' THEN 
				LEFT(node.value('(./action)[3]', 'varchar(4000)'), 36)
			ELSE LEFT(node.value('(./action)[1]', 'varchar(4000)'), 36)
		END AS activity_id,
		CASE 
			WHEN e.node.value('./@name', 'varchar(4000)') LIKE '%statement_starting' THEN 
				CONVERT(INT, RIGHT(node.value('(./action)[3]', 'varchar(4000)'), LEN(node.value('(./action)[3]', 'varchar(4000)')) - 37))
			ELSE CONVERT(INT, RIGHT(node.value('(./action)[1]', 'varchar(4000)'), LEN(node.value('(./action)[1]', 'varchar(4000)')) - 37))
		END AS sequence
	FROM waits_xml
	CROSS APPLY waits_xml.x.nodes('//event') e (node)
)
SELECT *
FROM
(
	SELECT
		event_name, 
		wait_type,
		activity_id,
		SUM(wait_duration) AS total_wait_duration,
		SUM(signal_duration) AS total_signal_duration,
		MAX(sequence) AS max_sequence,
		COUNT(*) AS num_waits,
		MIN(statement_cpu_time) AS statement_cpu_time,
		MIN(statement_duration) AS statement_duration,
		MIN(timestamp) AS min_timestamp
	FROM raw_values
	GROUP BY
		event_name,
		wait_type,
		activity_id
) x
ORDER BY
	MIN(min_timestamp) OVER
	(
		PARTITION BY activity_id
	),
	max_sequence
GO



DROP EVENT SESSION sql_text_and_waits
ON SERVER
GO
