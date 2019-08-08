--Signature="E27CD1465471AF13" 
SELECT convert (int,REPLACE (LEFT (CONVERT (varchar, SERVERPROPERTY ('ProductVersion')),2), '.', ''))


