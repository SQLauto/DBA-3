SELECT DatabaseName,DataSize,LogSize,DataSize+LogSize AS TotalSize, Collation, RecoveryType,AutoClose,AutoShrink
FROM 
	(SELECT DBID,
		CASE Sum(size*8/1024) 
			WHEN 0 THEN 1 
			ELSE Sum(size*8/1024) 
		END AS DataSize
	FROM master..sysaltfiles
	WHERE GroupID <> 0
	GROUP BY DBID) q1
INNER JOIN
	(SELECT DBID,
		CASE Sum(size*8/1024) 
			WHEN 0 THEN 1 
			ELSE Sum(size*8/1024)
		END AS LogSize
	FROM master..sysaltfiles
	WHERE GroupID = 0
	GROUP BY DBID) q2 
ON q1.DBID = q2.DBID
INNER JOIN
	(SELECT DBID, [name] AS DatabaseName,
		CONVERT(varchar(100),DATABASEPROPERTYEX([Name], 'Collation')) AS Collation,
		CONVERT(varchar(100),DATABASEPROPERTYEX([Name], 'Recovery')) AS RecoveryType,
		CASE CONVERT(varchar(10),DATABASEPROPERTYEX([Name], 'IsAutoClose'))
			WHEN 0 THEN '-'
			WHEN 1 THEN 'Yes'
		END  AS AutoClose,
	  	CASE CONVERT(varchar(10),DATABASEPROPERTYEX([Name], 'IsAutoShrink'))
			WHEN 0 THEN '-'
			WHEN 1 THEN 'Yes'
		END AS AutoShrink
	FROM master.dbo.sysdatabases) q3
ON q1.DBID = q3.dbid
ORDER BY DatabaseName 

