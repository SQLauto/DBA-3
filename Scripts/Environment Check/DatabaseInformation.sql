/*
Script to provide useful contextual information about a given database.
PJM. July 2010.
*/


:SETVAR DBNAME SalesDB
:SETVAR TARGETSERVER (local)

:CONNECT $(TARGETSERVER)

USE $(DBNAME)

exec sp_helpdb '$(DBNAME)'

select * from sys.databases where database_id = db_id('$(DBNAME)')
select * from sys.master_files where database_id = db_id('$(DBNAME)')

SELECT * FROM sys.filegroups

select * from sys.certificates
select * from sys.symmetric_keys
select * from sys.asymmetric_keys

--select * from sys.sql_logins
--select * from sys.database_principals
--select * from sys.certificates

--select * from sys.tables

--exec sp_spaceused 
--exec sp_helpfile

GO