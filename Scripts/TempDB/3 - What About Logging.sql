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
GO

DECLARE @Target TABLE(ID int, Description char(100));

INSERT INTO @Target
  SELECT ID, Description FROM dbo.Source;

UPDATE @Target SET Description = REPLICATE('T',100);

-- look at the top 10 log records

SELECT TOP 10 operation, context, [log record fixed length], 
              [log record length], AllocUnitId, AllocUnitName 
  FROM fn_dblog(null, null) 
  WHERE AllocUnitName LIKE 'dbo.%'
  ORDER BY [Log Record Length] DESC;

CREATE TABLE #Target (ID int, Description char(100));
GO
 
INSERT INTO #Target
  SELECT ID, Description FROM dbo.Source;

UPDATE #Target SET Description = REPLICATE('T',100);

-- look at the top 10 log records

SELECT TOP 10 operation, context, [log record fixed length], 
              [log record length], AllocUnitId, AllocUnitName 
  FROM fn_dblog(null, null) 
  WHERE AllocUnitName LIKE 'dbo.%'
  ORDER BY [Log Record Length] DESC;

GO

DROP TABLE dbo.Source;
DROP TABLE #Target;
GO

-- and no indexes and no stats