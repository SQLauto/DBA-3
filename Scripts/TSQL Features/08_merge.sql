USE tempdb;
GO

IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL
	DROP TABLE dbo.Customers;
  
CREATE TABLE dbo.Customers
(
	custid      INT         NOT NULL,
	companyname VARCHAR(25) NOT NULL,
	phone       VARCHAR(20) NOT NULL,
	address     VARCHAR(50) NOT NULL,
	CONSTRAINT PK_Customers PRIMARY KEY(custid)
);
INSERT INTO dbo.Customers
(
	custid, 
	companyname, 
	phone, 
	address
)
VALUES
	(1, 'cust 1', '(111) 111-1111', 'address 1'),
	(2, 'cust 2', '(222) 222-2222', 'address 2'),
	(3, 'cust 3', '(333) 333-3333', 'address 3'),
	(4, 'cust 4', '(444) 444-4444', 'address 4'),
	(5, 'cust 5', '(555) 555-5555', 'address 5');
GO


IF OBJECT_ID('dbo.CustomersStage', 'U') IS NOT NULL
	DROP TABLE dbo.CustomersStage;
	
CREATE TABLE dbo.CustomersStage
(
	custid      INT         NOT NULL,
	companyname VARCHAR(25) NOT NULL,
	phone       VARCHAR(20) NOT NULL,
	address     VARCHAR(50) NOT NULL,
	CONSTRAINT PK_CustomersStage PRIMARY KEY(custid)
);

INSERT INTO dbo.CustomersStage
(
	custid, 
	companyname, 
	phone, 
	address
)
VALUES
	(2, 'AAAAA', '(222) 222-2222', 'address 2'),
	(3, 'cust 3', '(333) 333-3333', 'address 3'),
	(5, 'BBBBB', 'CCCCC', 'DDDDD'),
	(6, 'cust 6 (new)', '(666) 666-6666', 'address 6'),
	(7, 'cust 7 (new)', '(777) 777-7777', 'address 7');
GO


MERGE 
INTO dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
	ON TGT.custid = SRC.custid
WHEN MATCHED THEN 
	UPDATE 
	SET
		TGT.companyname = SRC.companyname,
		TGT.phone = SRC.phone,
		TGT.address = SRC.address
WHEN NOT MATCHED THEN 
	INSERT (custid, companyname, phone, address)
	VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address)
WHEN NOT MATCHED BY SOURCE THEN
	DELETE
OUTPUT 
	$action, deleted.custid AS del_custid, inserted.custid AS ins_custid;
GO


--When MATCHED AND... ?
MERGE 
INTO dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
	ON TGT.custid = SRC.custid
WHEN MATCHED 
	AND 
    (
		TGT.companyname <> SRC.companyname
		OR TGT.phone       <> SRC.phone
		OR TGT.address     <> SRC.address
	) THEN
	UPDATE
	SET
		TGT.companyname = SRC.companyname,
		TGT.phone = SRC.phone,
		TGT.address = SRC.address
WHEN NOT MATCHED THEN 
	INSERT (custid, companyname, phone, address)
	VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address)
WHEN NOT MATCHED BY SOURCE THEN
	DELETE
OUTPUT 
	$action, deleted.custid AS del_custid, inserted.custid AS ins_custid;
GO


--OUTPUT clause, return non-affected columns
ALTER TABLE CustomersStage
ADD SurrogateKey UNIQUEIDENTIFIER NOT NULL DEFAULT(NEWID())
GO

DELETE Customers
GO

MERGE INTO Customers AS tgt
USING CustomersStage AS src ON
	1=0
WHEN NOT MATCHED THEN
	INSERT (custid, companyname, phone, address)
	VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address)
OUTPUT 
	inserted.custid AS ins_custid, src.SurrogateKey;
GO


--Fix for UPDATE FROM...
CREATE TABLE #t1 (i INT, j CHAR(1))
CREATE TABLE #t2 (i INT, j CHAR(1))

INSERT #t1 
VALUES (1, 'a')

INSERT #t2
VALUES (1, 'b'), (1, 'c')

UPDATE t1
SET t1.j = t2.j
FROM #t1 AS t1
JOIN #t2 AS t2 ON t1.i = t2.i

SELECT * 
FROM #t1
GO


--Better:
UPDATE t1
SET 
	t1.j = 
	(
		SELECT 
			t2.j
		FROM #t2 AS t2 
		WHERE 
			t1.i = t2.i
	)
FROM #t1 AS t1
GO


--multiple columns? Use MERGE
MERGE INTO #t1 AS tgt
USING #t2 AS src ON
	src.i = tgt.i
WHEN MATCHED THEN 
	UPDATE
		SET tgt.j = src.j;
GO
