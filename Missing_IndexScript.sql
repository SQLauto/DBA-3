WITH misind (improvement_measure, database_id, table_name, create_index_statement)
AS
(
SELECT TOP 20
CONVERT (decimal (28,1),
migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)
) AS improvement_measure,
mid.database_id, object_name(mid.object_id,mid.database_id) as [table_name],
'CREATE INDEX [ix_' + object_name(mid.object_id,mid.database_id) + '__'
+ REPLACE(REPLACE(REPLACE(ISNULL(mid.equality_columns,''),', ','__'),'[',''),']','') +
CASE
	WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN '__'
	ELSE ''
END
+ REPLACE(REPLACE(REPLACE(ISNULL(mid.inequality_columns,''),', ','__'),'[',''),']','')
+ ']'
+ ' ON ' + mid.statement
+ ' (' + ISNULL (mid.equality_columns,'')
+ CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE
'' END
+ ISNULL (mid.inequality_columns, '')
+ ')'
+ ISNULL (' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs
ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid
ON mig.index_handle = mid.index_handle
WHERE CONVERT (decimal (28,1), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks
+ migs.user_scans)) > 10000
AND last_user_seek>DATEADD(wk,-1,GETDATE())
ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC
)
SELECT
	--improvement_measure,
	create_index_statement
FROM misind
ORDER BY database_id, table_name
