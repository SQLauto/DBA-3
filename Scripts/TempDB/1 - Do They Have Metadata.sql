USE tempdb;
GO

DECLARE @MyTable TABLE(ID int, Description char(8000));

SELECT * FROM sys.columns WHERE name = 'Description';
