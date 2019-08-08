USE tempdb;
GO

CREATE TABLE dbo.Source 
( ID int,
  Description char(100)
);
GO

DECLARE @Counter int = 0;

WHILE (@Counter < 100)
BEGIN
  INSERT INTO dbo.Source VALUES(@Counter,REPLICATE('G',100));
  SET @Counter += 1;
END;

CREATE TABLE #Target (ID int, Description char(100));
GO
 
BEGIN TRAN
  INSERT INTO #Target
    SELECT ID, Description
      FROM dbo.Source;

  DECLARE @Target TABLE(ID int, Description char(100));

  INSERT INTO @Target
    SELECT ID, Description FROM dbo.Source;

  SELECT dtl.request_session_id AS SPID,
         dtl.resource_type AS ResourceType,   
         (CASE resource_type 
          WHEN 'OBJECT' THEN OBJECT_NAME(dtl.resource_associated_entity_id) 
          WHEN 'DATABASE' THEN ' ' 
          ELSE (SELECT OBJECT_NAME(object_id)
                FROM sys.partitions  
                WHERE hobt_id=resource_associated_entity_id) 
          END) AS ObjectName,  
         dtl.resource_description AS Description,   
         dtl.request_mode AS Mode,  
         dtl.request_status AS Status,
         dowt.blocking_session_id
  FROM sys.dm_tran_locks AS dtl 
  LEFT OUTER JOIN sys.dm_os_waiting_tasks AS dowt
  ON dtl.lock_owner_address = dowt.resource_address
  WHERE dtl.resource_database_id = 2;
ROLLBACK;
  
SELECT COUNT(*) FROM #Target;
SELECT COUNT(*) FROM @Target;

GO

DROP TABLE dbo.Source;
DROP TABLE #Target;
GO

