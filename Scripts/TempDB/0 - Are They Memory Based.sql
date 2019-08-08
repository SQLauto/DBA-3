-- Note: Scripts based on blog posts from Conor Cunningham

USE tempdb;
GO

CREATE TABLE #MyTable
( ID int,
  Description char(8000)
);
GO

DECLARE @Counter int = 0;

WHILE (@Counter < 1000)
BEGIN
  INSERT INTO #MyTable VALUES(@Counter,REPLICATE('G',100));
  SET @Counter += 1;
END;

DECLARE @MyTable TABLE (ID int, Description char(8000));

INSERT INTO @MyTable (ID, Description)
  SELECT ID,Description FROM #MyTable;
  
-- Note the size
SELECT SUM(unallocated_extent_page_count)
       + SUM(user_object_reserved_page_count)
       + SUM(internal_object_reserved_page_count) 
       + SUM(version_store_reserved_page_count)
       + SUM(mixed_extent_page_count),
       SUM(unallocated_extent_page_count) AS FreeSpacePages,
       SUM(user_object_reserved_page_count) AS UserObjectPages,
       SUM(internal_object_reserved_page_count) AS InternalObjectPages,
       SUM(version_store_reserved_page_count) AS VersionStorePages,
       SUM(mixed_extent_page_count) AS MixedExtentPages
  FROM sys.dm_db_file_space_usage;
GO

-- Note the size when we leave out the table variable -> half the space
SELECT SUM(unallocated_extent_page_count)
       + SUM(user_object_reserved_page_count)
       + SUM(internal_object_reserved_page_count) 
       + SUM(version_store_reserved_page_count)
       + SUM(mixed_extent_page_count),
       SUM(unallocated_extent_page_count) AS FreeSpacePages,
       SUM(user_object_reserved_page_count) AS UserObjectPages,
       SUM(internal_object_reserved_page_count) AS InternalObjectPages,
       SUM(version_store_reserved_page_count) AS VersionStorePages,
       SUM(mixed_extent_page_count) AS MixedExtentPages
  FROM sys.dm_db_file_space_usage;
GO

DROP TABLE #MyTable;
GO
