CREATE DATABASE iFTS
GO

USE iFTS
GO


--create a table to play with
SELECT * 
INTO Addresses
FROM AdventureWorks.Person.Address
go


--Integer PK
ALTER TABLE Addresses 
ADD CONSTRAINT PK_AddressId PRIMARY KEY (AddressId)
GO



--Another table
SELECT * 
INTO Addresses_Guid
FROM AdventureWorks.Person.Address
go


--Guid PK
ALTER TABLE Addresses_Guid
ADD CONSTRAINT PK_RowGuid PRIMARY KEY (RowGuid)
GO



--create a fulltext catalog
CREATE FULLTEXT CATALOG [test_catalog]
go


--Create a fulltext index on each table
CREATE FULLTEXT INDEX ON dbo.Addresses 
KEY INDEX PK_AddressId ON (test_catalog)
WITH (CHANGE_TRACKING AUTO);
GO

CREATE FULLTEXT INDEX ON dbo.Addresses_Guid
KEY INDEX PK_RowGuid ON (test_catalog)
WITH (CHANGE_TRACKING AUTO);
GO

--Add a column to each index
ALTER FULLTEXT INDEX ON dbo.Addresses 
ADD (AddressLine1)
GO

ALTER FULLTEXT INDEX ON dbo.Addresses_Guid
ADD (AddressLine1)
GO


--Enable both indexes
ALTER FULLTEXT INDEX ON dbo.Addresses
ENABLE
GO

ALTER FULLTEXT INDEX ON dbo.Addresses_Guid
ENABLE
GO


--Document ID Map in the query plan?
SELECT *
FROM dbo.Addresses 
WHERE
	CONTAINS(AddressLine1, 'Napa')
GO

SELECT *
FROM dbo.Addresses_Guid
WHERE
	CONTAINS(AddressLine1, 'Napa')
GO



--The trimming problem--fixed
SELECT *
FROM dbo.Addresses
WHERE
	AddressId > 20000
	AND CONTAINS(AddressLine1, 'Napa')
GO

SELECT *
FROM dbo.Addresses
WHERE
	AddressId > 99999
	AND CONTAINS(AddressLine1, 'Napa')
GO



--DML query plans modified
UPDATE Addresses 
SET AddressLine1 = AddressLine1
GO



--Internal tables
--Note: Parent object ID not populated for fragment table
SELECT *
FROM sys.internal_tables
WHERE 
	name like '%' + CONVERT(VARCHAR, OBJECT_ID('dbo.Addresses')) + '%'
GO


--See all of the keywords!
SELECT *
FROM sys.dm_fts_index_keywords(DB_ID(), OBJECT_ID('dbo.Addresses'))
GO


--See how the wordbreaker works...
SELECT *
FROM sys.dm_fts_parser
(
	--string
	'data-base AND Microsoft', 
	--language -- see sys.fulltext_languages
	1033, 
	--Stoplist -- see sys.fulltext_stoplists
	NULL, 
	--Accent-sensitive? Nah...
	0
)
GO


--What if we create a stoplist and call MS a noiseword?
CREATE FULLTEXT STOPLIST MS_stoplist;
GO

ALTER FULLTEXT STOPLIST MS_stoplist 
ADD 'Microsoft' LANGUAGE 1033;
GO


SELECT *
FROM sys.dm_fts_parser
(
	--string 
	'datastore AND Microsoft AND NT5', 
	--language -- see sys.fulltext_languages
	1033, 
	--Stoplist -- see sys.fulltext_stoplists
	5, 
	--Accent-sensitive? Nah...
	0
)
GO


--What if we make a thesaurus entry for database?
--Nothing; it doesn't work on my system.
EXEC sp_fulltext_load_thesaurus_file 1033
GO

