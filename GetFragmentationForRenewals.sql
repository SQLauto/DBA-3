USE [PC]
GO
 
DECLARE @Loop Int 
DECLARE @StartTime Datetime
DECLARE @EndTime Datetime
DECLARE @Exec VARCHAR(MAX) 
DECLARE @DB_ID SMALLINT
 
SET @Loop = 1
SET @DB_ID = DB_ID(N'PC')
 
 -- Note, care should be taken with use of MAXDOP = 8 below as this would allow all Guidewire CPUs to be used for the rebuild. 
SELECT  ROW_NUMBER() OVER(ORDER BY ind.name ASC) AS RowNum,
                                OBJECT_NAME(ind.OBJECT_ID) AS TableName,
                                'SET QUOTED_IDENTIFIER ON;ALTER INDEX ' + ind.name + ' ON [dbo].' + OBJECT_NAME(ind.OBJECT_ID) +
								' REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = ON, MAXDOP = 8, PAD_INDEX = OFF)' as [RebuildScript],
                                ind.name AS IndexName, 
                                indexstats.index_type_desc AS IndexType,
                                CONVERT(Decimal (10,2),indexstats.avg_fragmentation_in_percent) as avg_fragmentation_in_percent
INTO #TempFragmentationStats
FROM sys.dm_db_index_physical_stats(@DB_ID, NULL, NULL, NULL, 'LIMITED') indexstats
INNER JOIN sys.indexes ind ON ind.object_id = indexstats.object_id AND ind.index_id = indexstats.index_id
WHERE indexstats.avg_fragmentation_in_percent > 25 and indexstats.index_type_desc <> 'HEAP'
	AND OBJECT_NAME(ind.OBJECT_ID) IN ( 'pc.dbo.pc_job', 'pc.dbo.policyaddress','pc.dbo.pc_policyperiod', 'pc.dbo.pc_workflow', 'pc.dbo.pc_message',
                                    'pc.dbo.pc_messagehistory','pc.dbo.pc_standardworkqueue','pc.dbo.pc_workflowworkitem','pc.dbo.pc_account',
									'pc.dbo.pc_activity','pc.dbo.pc_address')

ORDER BY indexstats.avg_fragmentation_in_percent DESC
 
WHILE @Loop <= (SELECT MAX(RowNum) FROM #TempFragmentationStats ) 
BEGIN  
SET @Exec = (SELECT [RebuildScript] FROM #TempFragmentationStats WHERE RowNum = @Loop)
SET @StartTime = GETDATE()
 
 
--EXEC (@Exec)
PRINT @Exec
 
SET @EndTime = GETDATE()
 
SET @Loop = @Loop + 1
 
END 
 
SELECT * FROM #TempFragmentationStats order by avg_fragmentation_in_percent DESC
 
DROP TABLE #TempFragmentationStats
