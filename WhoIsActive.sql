SELECT --CPU, reads,
 start_time [start], [dd hh:mm:ss.mss] AS 'run duration', [program_name], login_name, database_name, session_id, blocking_session_id, wait_info, sql_text, *
FROM WhoIsActive
WHERE collection_time BETWEEN '2019-06-20 07:55:00.000' AND '2019-09-25 09:00:00.000'
AND database_name = 'DRMS_Config_adrms_gel_local_443'
AND program_name <> 'SQL Server Log Shipping'
AND CAST(sql_command as nvarchar(max)) NOT LIKE '%SSLDBA%'
AND CAST(sql_command as nvarchar(max)) NOT LIKE '%BACKUP DATABASE%'

--AND login_name NOT IN ('DomainName\sqlservice')
--AND CAST(sql_text AS varchar(max)) LIKE '%some query%'
ORDER BY [start] DESC

