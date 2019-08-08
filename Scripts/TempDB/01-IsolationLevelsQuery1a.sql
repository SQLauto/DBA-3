-- setup

USE Isolation;
GO

CREATE TABLE dbo.TestTable
( ID int PRIMARY KEY,
  TestName varchar(35)
);
GO

INSERT TestTable VALUES(1,'Entry 1');
INSERT TestTable VALUES(2,'Entry 2');
INSERT TestTable VALUES(3,'Entry 3');
INSERT TestTable VALUES(4,'Entry 4');
INSERT TestTable VALUES(5,'Entry 5');

--3-- start a transaction and update a row
  
BEGIN TRANSACTION;

UPDATE TestTable SET TestName = '3 updated from query 1' WHERE ID = 3;

--4 is in 2nd window

--5-- update another row

UPDATE TestTable SET TestName = '4 updated from query 1' WHERE ID = 4;

-- note query window 2 still hung

 
--6-- commit this transaction

COMMIT TRANSACTION;

-- note query 2 has now completed

--7-- check the current contents

SELECT * FROM TestTable;

--8-- now we try it with reading only

-- start the transaction and read the table

BEGIN TRANSACTION;

SELECT * FROM TestTable;

--9 is in 2nd window

--10-- cancel the transaction

ROLLBACK TRANSACTION;

--11-- start a repeatable read transaction

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
BEGIN TRANSACTION;

SELECT * FROM TestTable WHERE ID = 3;

--12 is in the 2nd window
 
--13-- update id 3

UPDATE TestTable SET TestName = '3 updated from query 1' WHERE ID = 3;

-- succeeds
-- note query 2 still blocked

--14-- then commit

COMMIT TRANSACTION;

-- note query 2 has now run and succeeded

--15-- see which update was last

SELECT * FROM TestTable;

--16-- start another transaction, read the data again 
-- (still repeatable read)

BEGIN TRANSACTION;

SELECT * FROM TestTable WHERE ID = 3;

--17 and 18 are in the 2nd window

--19-- roll back (nothing to roll back anyway)

ROLLBACK TRANSACTION;

--20-- start a transaction with serializable

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE 
BEGIN TRANSACTION;

SELECT * FROM TestTable WHERE ID BETWEEN 5 AND 10;

--21 is in the 2nd window

--22-- then roll back

ROLLBACK TRANSACTION;

-- note query 2 has now completed

--23-- see the results

SELECT * FROM TestTable;

--24 and clean up

DROP TABLE TestTable;
