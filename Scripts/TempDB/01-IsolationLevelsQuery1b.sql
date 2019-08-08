--4-- try to update the same row

USE Isolation; 
GO

UPDATE TestTable SET TestName = '3 updated from query 2' WHERE ID = 3;

-- query hangs waiting on the other user


--9-- update a row that has been read

UPDATE TestTable SET TestName = '3 updated again from query 2' 
WHERE ID = 3;

-- note that it isn't blocked

--12-- try to update a row that has been read with repeatable read

UPDATE TestTable SET TestName = '3 updated third time from query 2' WHERE ID = 3;

-- note that it is blocked

--17-- try to insert a row into the table

INSERT TestTable VALUES(10,'Entry 10');

-- succeeds

--18-- note the new entries

SELECT * FROM TestTable;

--21-- try to insert into the table

INSERT TestTable VALUES(8,'Entry 8');

-- hangs even though it's not that row being updated
 
