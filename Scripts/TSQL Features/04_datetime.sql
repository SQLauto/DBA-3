DECLARE
	--Date only -- 3 bytes
  @d   AS DATE           = '2009-02-12',
	--Time only -- 3-5 bytes -- TIME(n)
  @t   AS TIME           = '12:30:15.1234567',
	--High-precision date/time -- 6-8 bytes -- DATETIME2(n)
  @dt2 AS DATETIME2      = '2009-02-12 12:30:15.1234567',
	--High-precision date/time with offset -- 8-10 bytes
  @dto AS DATETIMEOFFSET = '2009-02-12 12:30:15.1234567 +02:00';

SELECT
  @d   AS [@d],
  @t   AS [@t],
  @dt2 AS [@dt2],
  @dto AS [@dto];
go


/*
date functions
*/
SELECT
	CONVERT(TIME, GETDATE()),
	--SYSDATETIME returns DATETIME2
	CONVERT(TIME, SYSDATETIME())
GO


/*
new datepart/datename options
*/
SELECT
	DATEPART(microsecond, SYSDATETIME()),
	DATEDIFF
	(
		nanosecond, 
		SYSDATETIME(), 
		DATEADD(microsecond, 1, SYSDATETIME())
	)
GO



/*
modify offsets
*/
SELECT 
	SYSDATETIMEOFFSET(),
	SWITCHOFFSET(SYSDATETIMEOFFSET(), '+05:00'),
	TODATETIMEOFFSET(GETDATE(), '+05:00')
GO


/*
upgrade issue
*/
SELECT GETDATE() + 1
GO

SELECT SYSDATETIME() + 1
GO



/*
query bonus
*/
USE tempdb
GO

CREATE TABLE some_dates 
(
	the_date DATETIME NOT NULL PRIMARY KEY
)
GO

INSERT some_dates 
(
	the_date
)
SELECT DATEADD(hour, -number, GETDATE())
FROM master..spt_values
WHERE 
	type = 'P'
UNION
SELECT DATEADD(hour, number, GETDATE())
FROM master..spt_values
WHERE 
	type = 'P'
GO


--What happened today? Bad way.
SELECT *
FROM some_dates
WHERE
	CONVERT(VARCHAR, the_date, 112) = 
		CONVERT(VARCHAR, GETDATE(), 112)
		

--What happened today? Tricky way.
SELECT *
FROM some_dates
WHERE 
	the_date BETWEEN
		DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0) AND
		DATEADD(dd, DATEDIFF(dd, 0, GETDATE())+1, 0)


--What happened today? Easy way.
SELECT *
FROM some_dates
WHERE 
	CONVERT(date, the_date) = GETDATE()
GO
