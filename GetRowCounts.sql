--dbcc updateusage(0)

SELECT      T.name TableName,i.Rows NumberOfRows
FROM        sys.tables T
JOIN        sys.sysindexes I ON T.OBJECT_ID = I.ID
WHERE       indid IN (0,1) and i.rows > 1000000
and t.name in (SELECT TBL.name AS TableName 
FROM sys.tables AS TBL 
     INNER JOIN sys.schemas AS SCH 
         ON TBL.schema_id = SCH.schema_id 
     INNER JOIN sys.indexes AS IDX 
         ON TBL.object_id = IDX.object_id 
            AND IDX.type = 0) -- = Heap )
--ORDER BY TableName)
ORDER BY    i.Rows DESC,T.name