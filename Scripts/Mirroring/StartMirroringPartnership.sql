
  -- Endpoints up and running.  Start a mirroring session.
  
:SETVAR PrincipalServer (local)\SQLDEV02
:SETVAR MirrorServer (local)\SQLDEV03
:SETVAR WitnessServer (local)

:SETVAR PrincipalEndPoint 'TCP://SQL2008ADMIN:5091'
:SETVAR MirrorEndPoint 'TCP://SQL2008ADMIN:5092'
:SETVAR WitnessEndPoint 'TCP://SQL2008ADMIN:5090'


:SETVAR Database2Mirror AdventureWorksLT


:ON ERROR EXIT
go


:CONNECT $(MirrorServer)
GO

-- Establish the mirroring partnership
ALTER DATABASE $(Database2Mirror)
    SET PARTNER = $(PrincipalEndPoint)
GO

:CONNECT $(PrincipalServer)

ALTER DATABASE $(Database2Mirror)
	SET PARTNER = $(MirrorEndPoint)
GO

/*
ALTER DATABASE $(Database2Mirror)
	SET WITNESS = $(WitnessEndPoint)
GO
*/

SELECT	db_name(sd.[database_id]) AS [Database Name], 
		sd.mirroring_role_desc, 
		sd.mirroring_partner_name, 
		sd.mirroring_state_desc, 
		sd.mirroring_witness_name, 
		sd.mirroring_witness_state_desc, 
		sd.mirroring_safety_level_desc
FROM	sys.database_mirroring AS sd
WHERE	sd.[database_id] = db_id(N'$(Database2Mirror)')
GO


