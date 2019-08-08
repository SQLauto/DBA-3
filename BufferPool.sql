--Buffer Pool
--Number of pages in the buffer pool by database and page type 

select db_name(database_id), page_type, count(page_id)as number_pages
 from sys.dm_os_buffer_descriptors 
where database_id !=32767
group by database_id, page_type
order by database_id


--Number of pages in the buffer pool by database

select db_name(database_id), 
count(page_id)as number_pages
 from sys.dm_os_buffer_descriptors 
where database_id !=32767
group by database_id
order by database_id


--Number of pages in the buffer pool by page type

select page_type, count(page_id) as number_pages
from sys.dm_os_buffer_descriptors
group by page_type



--Number of dirty pages in the buffer pool

SELECT count(page_id) AS number_pages
FROM sys.dm_os_buffer_descriptors
WHERE is_modified =1