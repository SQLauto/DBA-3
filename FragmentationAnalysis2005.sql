use adventureworks;

select index_id, avg_fragmentation_in_percent, avg_page_space_used_in_percent
from sys.dm_db_index_physical_stats (DB_ID('AdventureWorks'),
                                     object_id('HumanResources.Employee'),
                                     null, null, 'detailed')
where index_id <> 0; -- no heap analysis performed

alter index all on HumanResources.Employee
 rebuild with (fillfactor = 90, online = on);

select index_id, avg_fragmentation_in_percent, avg_page_space_used_in_percent
from sys.dm_db_index_physical_stats (DB_ID('AdventureWorks'),
                                     object_id('HumanResources.Employee'),
                                     null, null, 'detailed')
where index_id <> 0; -- no heap analysis performed

alter index all on HumanResources.Employee
reorganize;

-- 60 < page_space < 75 OR 10 < fragmentation < 15 - REORGANIZE
-- page_space < 60 OR fragmentation > 15 - REBUILD