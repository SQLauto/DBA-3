USE sqlnexus
GO

--Mostly waiting on CXPacket
SELECT DISTINCT TOP 25 ISNULL(aq.[plan_total_exec_count],1) AS Nr_Execs, aq.dbname, tr.wait_type,
	CASE WHEN [resource_description] LIKE 'pagelock%' THEN 'Producer waiting on page lock'
		WHEN [resource_description] LIKE 'objectlock%' THEN 'Producer waiting on object lock'
		WHEN [resource_description] LIKE '%e_waitPipeNewRow%' THEN 'Producer waiting on consumer for a packet to fill'
		WHEN [resource_description] LIKE '%e_waitPipeGetRow%' THEN 'Consumer waiting on producer to fill a packet'
		ELSE 'Other' END AS [wait_resource_type],
	REPLACE(aq.procname, CHAR(9), ' ') AS procname, REPLACE(aq.stmt_text, CHAR(9), ' ') AS stmt_text,
	AVG(tr.wait_duration_ms) AS avg_wait_duration_ms, 
	(aq.plan_total_cpu_ms/ISNULL(aq.[plan_total_exec_count],1)) AS avg_cpu_ms,
	(aq.plan_total_logical_reads/ISNULL(aq.[plan_total_exec_count],1)) AS avg_logical_reads,
	MIN(tr.runtime) AS First_Requested_at, MAX(tr.runtime) AS Last_Requested_at,
	tr.[program_name], tr.login_name, tr.[host_name]
--,[resource_description]
FROM tbl_REQUESTS AS tr 
INNER JOIN tbl_NOTABLEACTIVEQUERIES AS aq ON tr.session_id = aq.session_id AND tr.request_id = aq.request_id AND tr.runtime = aq.runtime
WHERE (tr.wait_type = 'CXPACKET') AND dbname IS NOT NULL
GROUP BY aq.dbname, aq.procname, aq.stmt_text, tr.wait_type, tr.[program_name], tr.login_name, tr.[host_name],
	[plan_total_exec_count],[plan_total_logical_reads],[plan_total_cpu_ms],
	CASE WHEN [resource_description] LIKE 'pagelock%' THEN 'Producer waiting on page lock'
		WHEN [resource_description] LIKE 'objectlock%' THEN 'Producer waiting on object lock'
		WHEN [resource_description] LIKE '%e_waitPipeNewRow%' THEN 'Producer waiting on consumer for a packet to fill'
		WHEN [resource_description] LIKE '%e_waitPipeGetRow%' THEN 'Consumer waiting on producer to fill a packet'
		ELSE 'Other' END
--,[resource_description]
ORDER BY AVG(tr.wait_duration_ms) DESC
GO

--Mostly waiting on latches
SELECT DISTINCT TOP 25 ISNULL(aq.[plan_total_exec_count],1) AS Nr_Execs, aq.dbname, tr.wait_type,
	(SELECT CASE
		WHEN pageid = 1 OR pageid % 8088 = 0 THEN 'Is_PFS_Page'
		WHEN pageid = 2 OR pageid % 511232 = 0 THEN 'Is_GAM_Page'
		WHEN pageid = 3 OR (pageid - 1) % 511232 = 0 THEN 'Is_SGAM_Page'
		WHEN pageid IS NULL THEN NULL
		ELSE 'Is_not_PFS_GAM_SGAM_page' END
	FROM (SELECT CASE WHEN tr.[wait_type] LIKE 'PAGE%LATCH%' AND tr.[wait_resource] LIKE '%:%'
		THEN CAST(RIGHT(tr.[wait_resource], LEN(tr.[wait_resource]) - CHARINDEX(':', tr.[wait_resource], LEN(tr.[wait_resource])-CHARINDEX(':', REVERSE(tr.[wait_resource])))) AS int)
		ELSE NULL END AS pageid) AS latch_pageid
	) AS wait_resource_type,
	tr.[wait_resource],
	REPLACE(aq.procname, CHAR(9), ' ') AS procname, REPLACE(aq.stmt_text, CHAR(9), ' ') AS stmt_text,
	AVG(tr.wait_duration_ms) AS avg_wait_duration_ms, 
	(aq.plan_total_cpu_ms/ISNULL(aq.[plan_total_exec_count],1)) AS avg_cpu_ms,
	(aq.plan_total_logical_reads/ISNULL(aq.[plan_total_exec_count],1)) AS avg_logical_reads,
	MIN(tr.runtime) AS First_Requested_at, MAX(tr.runtime) AS Last_Requested_at,
	tr.[program_name], tr.login_name, tr.[host_name]
FROM tbl_REQUESTS AS tr 
INNER JOIN tbl_NOTABLEACTIVEQUERIES AS aq ON tr.session_id = aq.session_id AND tr.request_id = aq.request_id AND tr.runtime = aq.runtime
WHERE (tr.wait_type LIKE '%LATCH%') AND dbname IS NOT NULL
GROUP BY aq.dbname, aq.procname, aq.stmt_text, tr.wait_type, tr.[program_name], tr.login_name, tr.[host_name], wait_resource,
	[plan_total_exec_count],[plan_total_logical_reads],[plan_total_cpu_ms]
ORDER BY AVG(tr.wait_duration_ms) DESC
GO

--Mostly waiting on locks
SELECT DISTINCT TOP 25 ISNULL(aq.[plan_total_exec_count],1) AS Nr_Execs, aq.dbname, tr.wait_type, tr.[wait_resource],
	REPLACE(aq.procname, CHAR(9), ' ') AS procname, REPLACE(aq.stmt_text, CHAR(9), ' ') AS stmt_text,
	AVG(tr.wait_duration_ms) AS avg_wait_duration_ms, 
	(aq.plan_total_cpu_ms/ISNULL(aq.[plan_total_exec_count],1)) AS avg_cpu_ms,
	(aq.plan_total_logical_reads/ISNULL(aq.[plan_total_exec_count],1)) AS avg_logical_reads,
	MIN(tr.runtime) AS First_Requested_at, MAX(tr.runtime) AS Last_Requested_at,
	tr.[program_name], tr.login_name, tr.[host_name]
FROM tbl_REQUESTS AS tr 
INNER JOIN tbl_NOTABLEACTIVEQUERIES AS aq ON tr.session_id = aq.session_id AND tr.request_id = aq.request_id AND tr.runtime = aq.runtime
WHERE (tr.wait_type LIKE '%LCK%') AND dbname IS NOT NULL
GROUP BY aq.dbname, aq.procname, aq.stmt_text, tr.wait_type, tr.[program_name], tr.login_name, tr.[host_name], [wait_resource],
	[plan_total_exec_count],[plan_total_logical_reads],[plan_total_cpu_ms]
ORDER BY AVG(tr.wait_duration_ms) DESC
GO

--Mostly waiting on writelog
SELECT DISTINCT TOP 25 ISNULL(aq.[plan_total_exec_count],1) AS Nr_Execs, aq.dbname, tr.wait_type, tr.[wait_resource],
	REPLACE(aq.procname, CHAR(9), ' ') AS procname, REPLACE(aq.stmt_text, CHAR(9), ' ') AS stmt_text,
	AVG(tr.wait_duration_ms) AS avg_wait_duration_ms, 
	(aq.plan_total_cpu_ms/ISNULL(aq.[plan_total_exec_count],1)) AS avg_cpu_ms,
	(aq.plan_total_logical_reads/ISNULL(aq.[plan_total_exec_count],1)) AS avg_logical_reads,
	MIN(tr.runtime) AS First_Requested_at, MAX(tr.runtime) AS Last_Requested_at,
	tr.[program_name], tr.login_name, tr.[host_name]
FROM tbl_REQUESTS AS tr 
INNER JOIN tbl_NOTABLEACTIVEQUERIES AS aq ON tr.session_id = aq.session_id AND tr.request_id = aq.request_id AND tr.runtime = aq.runtime
WHERE (tr.wait_type LIKE 'WRITELOG%') AND dbname IS NOT NULL
GROUP BY aq.dbname, aq.procname, aq.stmt_text, tr.wait_type, tr.[program_name], tr.login_name, tr.[host_name], [wait_resource],
	[plan_total_exec_count],[plan_total_logical_reads],[plan_total_cpu_ms]
ORDER BY AVG(tr.wait_duration_ms) DESC
GO