--sp_readerrorlog 1,1, N'RESTORING'

CREATE TABLE #x(LogDate DATETIME, p SYSNAME, [Text] NVARCHAR(MAX));
INSERT #x EXEC sp_readerrorlog 1, 1, N'Restore', N'MB/sec';
-- repeat for 1, 2, 3, 4, 5, 6 if you want to capture more history:
--INSERT #x EXEC sp_readerrorlog 1, 1, N'Restore', N'MB/sec';
--INSERT #x EXEC sp_readerrorlog 2, 1, N'Restore', N'MB/sec';
--...

CREATE TABLE #y(LogDate DATETIME, p SYSNAME, [Text] NVARCHAR(MAX));
INSERT #y EXEC sp_readerrorlog 1, 1, N'is marked RESTORING', N'PC';
-- again repeat for 1, 2, 3, 4, 5, 6 like above

CREATE TABLE #z(LogDate DATETIME, p SYSNAME, [Text] NVARCHAR(MAX));
INSERT #z EXEC sp_readerrorlog 1, 1, N'Restore is complete',  N'PC';
-- one more time, you may need to repeat if you want more history

SELECT LogDate, [Text]
FROM 
(
  SELECT LogDate, [Text] FROM #x
  UNION ALL SELECT LogDate, [Text] FROM #y
  UNION ALL SELECT LogDate, [Text] FROM #z
) AS xyz
ORDER BY LogDate;

GO
DROP TABLE #x, #y, #z;