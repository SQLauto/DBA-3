  -- Just create mirroring endpoints and query the catalog to determine states
  
:SETVAR PrincipalServer (local)\SQLDEV02
:SETVAR MirrorServer (local)\SQLDEV03
:SETVAR WitnessServer (local)

:SETVAR Database2Mirror AdventureWorksLT
go

:ON ERROR EXIT
go

:CONNECT $(PrincipalServer)


-- Mirroring ONLY supports the FULL Recovery Model
IF DATABASEPROPERTYEX ('$(Database2Mirror)', 'Recovery') != N'FULL'
	ALTER DATABASE $(Database2Mirror) SET RECOVERY FULL
go

CREATE ENDPOINT Mirroring
    STATE=STARTED 
    AS TCP (LISTENER_PORT=5091) 
    FOR DATABASE_MIRRORING (ROLE=ALL)
GO

:CONNECT $(MirrorServer)

CREATE ENDPOINT Mirroring
    STATE=STARTED 
    AS TCP (LISTENER_PORT=5092) 
    FOR DATABASE_MIRRORING (ROLE=ALL)
GO

:CONNECT $(WitnessServer)

CREATE ENDPOINT Mirroring
    STATE=STARTED 
    AS TCP (LISTENER_PORT=5090) 
    FOR DATABASE_MIRRORING (ROLE=WITNESS)
GO



:CONNECT $(PrincipalServer)
Select * from sys.database_mirroring_endpoints
GO


:CONNECT $(MirrorServer)
Select * from sys.database_mirroring_endpoints
GO


:CONNECT $(WitnessServer)
Select * from sys.database_mirroring_endpoints
GO
