SELECT 
  CONVERT (decimal (28,1), (
    migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) + 
    migs.avg_total_system_cost * migs.avg_system_impact * (migs.system_seeks + migs.system_scans) +
    COALESCE(SPs.total_elapsed_time*1.0/ 
      290/ --based on 'SELECT total_elapsed_time/(DATEDIFF(second, start_time, GETDATE())+1.0) FROM sys.dm_exec_requests' for my personal install of SQL Server
      1000/ --otherwise seems closer to ms; total seconds of execution to get here
      425 -- the approximate relationship between avg_total_user_cost and the average of total_elapsed_time for a stored procedure on my system
    , 0) * (migs.avg_user_impact + migs.avg_system_impact)
  )) AS improvement_measure,
  COALESCE(QUOTENAME(DB_NAME(SPs.database_id))+'.','') +
    COALESCE(QUOTENAME(OBJECT_SCHEMA_NAME(SPs.[object_id]))+'.','') +
    COALESCE(QUOTENAME(OBJECT_NAME(SPs.[object_id])),CAST(SPs.[object_id] as nvarchar(128)),'N/A') as [ProcedureAppliesTo], 
  '  CREATE INDEX
       [missing_index_' + CONVERT(varchar, mig.index_group_handle) + '_' + CONVERT(varchar, mid.index_handle) + ']
     ON ' + mid.statement + '
       (' + ISNULL (mid.equality_columns,'') +
            CASE WHEN mid.equality_columns IS NOT NULL
                  AND mid.inequality_columns IS NOT NULL 
              THEN ','
              ELSE ''
            END +
            ISNULL(mid.inequality_columns, '') + '
       )' + 
     ISNULL(' INCLUDE (' + mid.included_columns + ')', '') as [create_index_statement],
  COALESCE(QUOTENAME(SPs.referenced_schema_name)+'.',QUOTENAME(OBJECT_SCHEMA_NAME(mid.object_id))+'.','') +
    COALESCE(QUOTENAME(SPs.referenced_entity_name),QUOTENAME(OBJECT_NAME(mid.object_id)),'') as [TableName],
  SPs.exec_count,
  SPs.total_elapsed_time*1.0/ 
    290/ --based onselect total_elapsed_time/(DATEDIFF(second, start_time, GETDATE())+1.0) from sys.dm_exec_requests 
    1000/ --otherwise seems closer to ms
    SPs.exec_count as [avg_time_sp],
  SPs.total_elapsed_time*1.0/ 
    290/ --based onselect total_elapsed_time/(DATEDIFF(second, start_time, GETDATE())+1.0) from sys.dm_exec_requests 
    1000/ --otherwise seems closer to ms
    SPs.exec_count/
    425 as avg_total_user_cost_sp,
  SPs.cacheobjtype,
  SPs.objtype,
  CASE WHEN migs.last_user_seek>migs.last_system_seek THEN migs.last_user_seek ELSE COALESCE(migs.last_system_seek,migs.last_user_seek) END as last_seek,
  CASE WHEN migs.last_user_scan>migs.last_system_scan THEN migs.last_user_scan ELSE COALESCE(migs.last_system_scan,migs.last_user_scan) END as last_scan,
  SPs.last_execution_timestamp,
  CONVERT(varchar, getdate(), 121) AS this_query_time_of_exec
FROM
  sys.dm_db_missing_index_details AS mid
INNER JOIN sys.dm_db_missing_index_groups AS mig
  ON mig.index_handle = mid.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats as migs
  ON migs.group_handle = mig.index_group_handle
LEFT JOIN (
  SELECT
    CASE WHEN SUM(eps.execution_count)>=SUM(cp.usecounts) THEN SUM(eps.execution_count) ELSE COALESCE(SUM(cp.usecounts),SUM(eps.execution_count)) END as exec_count,
    SUM(eps.total_elapsed_time) as total_elapsed_time,
    MAX(cp.cacheobjtype) as cacheobjtype,
    MAX(cp.objtype) as objtype,
    MAX(eps.last_execution_time) as last_execution_timestamp,
    re.referenced_entity_name,
    re.referenced_schema_name,
    re.referenced_id,
    eps.database_id,
    eps.[object_id]
  FROM
    sys.dm_exec_procedure_stats AS eps
  INNER JOIN sys.dm_exec_cached_plans as cp
    ON cp.plan_handle=eps.plan_handle
  CROSS APPLY sys.dm_sql_referenced_entities (
    COALESCE(QUOTENAME(OBJECT_SCHEMA_NAME(eps.[object_id]))+'.','') +
      COALESCE(QUOTENAME(OBJECT_NAME(eps.[object_id])),CAST(eps.[object_id] as nvarchar(128)),''),
    'OBJECT'
  ) AS re
  GROUP BY
    re.referenced_entity_name,
    re.referenced_schema_name,
    re.referenced_id,
    eps.database_id,
    eps.[object_id]
) as SPs
  ON mid.[object_id] = SPs.referenced_id
  WHERE COALESCE(QUOTENAME(DB_NAME(SPs.database_id))+'.','') +
    COALESCE(QUOTENAME(OBJECT_SCHEMA_NAME(SPs.[object_id]))+'.','') +
    COALESCE(QUOTENAME(OBJECT_NAME(SPs.[object_id])),CAST(SPs.[object_id] as nvarchar(128)),'N/A') = '[ZEnergyStage].[dbo].[pERP_ExportTransactionalDetail]'
	order by improvement_measure desc