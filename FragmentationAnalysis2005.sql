Select *
From sys.dm_db_index_physical_stats(db_id(),object_id('Z_CS_WC_IND_COST_TRAN'),null,null,'detailed') AS SDDIPS
Inner join sys.sysindexes AS SI on SDDIPS.[object_id] = SI.id 
AND SDDIPS.index_id = SI.indid


Select *
From sys.dm_db_index_physical_stats(db_id(),object_id('Z_CS_WC_IND_WAL_COST_TRAN'),null,null,'detailed') AS SDDIPS
Inner join sys.sysindexes AS SI on SDDIPS.[object_id] = SI.id 
AND SDDIPS.index_id = SI.indid

