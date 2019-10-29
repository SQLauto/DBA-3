

SELECT [start_time]
	  ,[dd hh:mm:ss.mss] Duration
      ,[session_id]
      ,[sql_text]
      ,[sql_command]
      ,[login_name]
      ,[wait_info]
      ,[tran_log_writes]
      ,[CPU]
      ,[tempdb_allocations]
      ,[tempdb_current]
      ,[blocking_session_id]
      ,[reads]
      ,[writes]
      ,[physical_reads]
      ,[query_plan]
      ,[used_memory]
      ,[status]
      ,[tran_start_time]
      ,[open_tran_count]
      ,[percent_complete]
      ,[host_name]
      ,[database_name]
      ,[program_name]
      ,[login_time]
      ,[request_id]
      ,[collection_time]
  FROM DBAMON.[dbo].[WhoIsActive]
  WHERE collection_time BETWEEN '2019-09-25 07:55:00.000' AND '2019-09-25 13:00:00.000'
				AND database_name = 'AFO'
				--AND program_name <> 'SQL Server Log Shipping'
				--AND CAST(sql_command as nvarchar(max)) NOT LIKE '%SSLDBA%'
				--AND CAST(sql_command as nvarchar(max)) NOT LIKE '%BACKUP DATABASE%'
				--AND login_name NOT IN ('DomainName\sqlservice')
				--AND CAST(sql_text AS varchar(max)) LIKE '%some query%'
ORDER BY [start_time] DESC
GO


