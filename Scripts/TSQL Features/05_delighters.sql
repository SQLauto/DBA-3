use adventureworks
go

/*
declare and initialize
*/

DECLARE
	@i AS INT = 0,
	@s AS NVARCHAR(25) = 
	(
		SELECT LastName
		FROM AdventureWorks.Person.Contact as c
		WHERE ContactID = 5
	),
	@d AS DATETIME = CURRENT_TIMESTAMP;
  
SELECT @i AS [@i], @s AS [@s], @d AS [@d];
go

/*
compound assignment
*/
DECLARE @price AS MONEY = 10.00;
SET @price += 2.00;
SELECT @price;
go


/*
row constructors
*/
USE tempdb;

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
go


/*
even more...
*/
SELECT *
FROM
(
	VALUES
		(1, 'cust 1', '(111) 111-1111', 'address 1'),
		(2, 'cust 2', '(222) 222-2222', 'address 2'),
		(3, 'cust 3', '(333) 333-3333', 'address 3'),
		(4, 'cust 4', '(444) 444-4444', 'address 4'),
		(5, 'cust 5', '(555) 555-5555', 'address 5')
) AS C(custid, companyname, phone, address);
go


/*
binary conversions..?
*/
SELECT
	CONVERT(VARCHAR(4)  , 0x4164616D) AS [Bin to Char 0],
	CONVERT(VARBINARY(4), 'Adam')      AS [Char to Bin 0],
	CONVERT(VARCHAR(10)  , 0x4164616D, 1) AS [Bin to Char 1],
	CONVERT(VARBINARY(10), '0x4164616D', 1)      AS [Char to Bin 0];
go

