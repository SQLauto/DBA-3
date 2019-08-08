USE master
GO

sp_configure 'show advanced options', '1'
GO

RECONFIGURE WITH OVERRIDE
GO

/* 0 = Allow Local Connection, 1 = Allow Remote Connections*/ 

sp_configure 'remote admin connections', '1' 
GO

RECONFIGURE WITH OVERRIDE
GO

