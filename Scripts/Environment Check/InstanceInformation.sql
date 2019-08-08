/*
Script to provide useful contextual information about a given instance.
PJM. July 2010.
*/


:SETVAR DBNAME Master
:SETVAR TARGETSERVER (local)

:CONNECT $(TARGETSERVER)

USE $(DBNAME)

select * from sys.endpoints
select * from sys.database_mirroring_endpoints
select * from sys.service_broker_endpoints

GO

sp_configure 'show advanced options', 1
reconfigure
go
sp_configure

GO

-- CHECK SQL AGENT STATUS
use tempdb
go
sp_helpfile
