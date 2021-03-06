/*============================================================================
  File:     TicketSalesDBMSetup.sql

  Summary:  Setup the TicketSales database for Database Mirroring 
			in the High Availability configuration.

  Date:     August 2008

  SQL Server Version: 10.0.2531.0 (SQL Server 2008 SP1)
------------------------------------------------------------------------------
  Written by Kimberly L. Tripp & Paul S. Randal, SQLskills.com
  All rights reserved.

  For more scripts and sample code, check out http://www.SQLskills.com

  This script is intended only as a supplement to demos and lectures
  given by SQLskills.com  
  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

:SETVAR PrincipalServer (local)\SQLDEV01
:SETVAR MirrorServer (local)\SQLDEV02
:SETVAR WitnessServer (local)\SQLDEV03
:SETVAR Database2Mirror TicketSalesDB
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

-- Backing up the database has already been done to save time and allow
-- a demonstration of automatic page repair in the later exercise.
/*:CONNECT $(PrincipalServer)

BACKUP DATABASE $(Database2Mirror)
TO DISK = 'C:\AlwaysOn Labs\Database Mirroring Lab\$(Database2Mirror).bak'
WITH INIT
GO
*/

:CONNECT $(MirrorServer)

DECLARE @InstanceName	sql_variant,
		@InstanceDir	sql_variant,
		@SQLDataRoot	nvarchar(512),
		@ExecStr		nvarchar(max)

SELECT @InstanceName = ISNULL(SERVERPROPERTY('InstanceName'), 'MSSQLServer')

EXECUTE master.dbo.xp_regread 'HKEY_LOCAL_MACHINE', 
   'SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL', 
    @InstanceName, @InstanceDir	OUTPUT

SELECT @ExecStr = 'EXECUTE master.dbo.xp_regread '
	+ '''HKEY_LOCAL_MACHINE'', ' 
	+ '''SOFTWARE\Microsoft\Microsoft SQL Server\' 
	+ convert(varchar, @InstanceDir) 
	+ '\Setup'', ''SQLDataRoot'', @SQLDataRoot	OUTPUT'

EXEC master.dbo.sp_executesql @ExecStr
	, N'@SQLDataRoot nvarchar(512) OUTPUT'
	, @SQLDataRoot OUTPUT

IF @SQLDataRoot IS NULL
BEGIN
	RAISERROR ('Did not find the correct SQL Data Root Directory. Cannot proceed. Databases backed up but not yet restored.', 16, -1)
END

CREATE TABLE #BackupFileList
( LogicalName	sysname	NULL
	, PhysicalName	sysname	NULL
	, [Type]	char(1)
	, FileGroupName	sysname NULL
	, Size	bigint
	, MaxSize	bigint
	, FileId	smallint
	, CreateLSN	numeric(25,0)
	, DropLSN	numeric(25,0)
	, UniqueId uniqueidentifier
	, ReadOnlyLSN	numeric(25,0)
	, ReadWriteLSN	numeric(25,0)
	, BackupSizeInBytes	bigint
	, SourceBlockSize	bigint
	, FileGroupId		smallint
	, LogGroupGUID	uniqueidentifier
	, DifferentialBaseLSN	numeric(25,0)
	, DifferentialBaseGUID	uniqueidentifier
	, IsReadOnly	bit
	, IsPresent	bit
	, TDEThumbprint varbinary (32) NULL
)

INSERT #BackupFileList
	EXEC('RESTORE FILELISTONLY FROM DISK = ''C:\AlwaysOn Labs\Database Mirroring Lab\$(Database2Mirror).bak''')

UPDATE #BackupFileList
	SET PhysicalName 
			= @SQLDataRoot 
				+ N'\Data\' 
				+ REVERSE(SUBSTRING(REVERSE(PhysicalName)
					, 1, PATINDEX('%\%', REVERSE(PhysicalName)) -1))

DECLARE @LogicalName	sysname
	, @PhysicalName	sysname

DECLARE FileListCursor CURSOR FAST_FORWARD FOR 
	SELECT LogicalName, PhysicalName
	FROM #BackupFileList

OPEN FileListCursor

FETCH NEXT FROM FileListCursor INTO @LogicalName, @PhysicalName

SELECT @ExecStr = N'RESTORE DATABASE $(Database2Mirror)' +
				   N' FROM DISK = ''C:\AlwaysOn Labs\Database Mirroring Lab\$(Database2Mirror).bak''' +
				   N' WITH MOVE ''' + @LogicalName + N''' TO ''' + @PhysicalName + N''''
	
FETCH NEXT FROM FileListCursor INTO @LogicalName, @PhysicalName

WHILE @@FETCH_STATUS <> -1
BEGIN
	SELECT @ExecStr = @ExecStr + N', MOVE ''' + @LogicalName 
						+ ''' TO ''' + @PhysicalName + ''''
	FETCH NEXT FROM FileListCursor INTO @LogicalName, @PhysicalName
END

-- NORECOVERY is required for Database Mirroring, replace is not. 
-- Replace is used here solely to allow repetitive use of this script.

-- WHEREVER POSSIBLE USE SAME DIRECTORY AND FILE STRUCTURE AT MIRROR TO SUPPORT ALTER DATABASE ADD/REMOVE FILE!

SELECT @ExecStr = @ExecStr + N' , NORECOVERY, REPLACE'

-- Useful for testing
-- Only return the string and then comment out the EXEC line below.
-- SELECT @ExecStr

EXEC (@ExecStr)

DEALLOCATE FileListCursor
GO

:CONNECT $(PrincipalServer)

-- Backup the transaction log to get these two databases closer to current.
BACKUP LOG $(Database2Mirror)
TO DISK = 'C:\AlwaysOn Labs\Database Mirroring Lab\$(Database2Mirror)_Log.bak'
WITH INIT
GO

:CONNECT $(MirrorServer)

-- Restore the transaction log.
RESTORE LOG $(Database2Mirror)
FROM DISK = 'C:\AlwaysOn Labs\Database Mirroring Lab\$(Database2Mirror)_Log.bak'
WITH NORECOVERY
GO

-- Establish the mirroring partnership
ALTER DATABASE $(Database2Mirror)
    SET PARTNER = 'TCP://CHICAGO:5091'
GO

:CONNECT $(PrincipalServer)

ALTER DATABASE $(Database2Mirror)
	SET PARTNER = 'TCP://CHICAGO:5092'
GO

ALTER DATABASE $(Database2Mirror)
	SET WITNESS = 'TCP://CHICAGO:5090'
GO

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

--------------------------------------------------------------------
-- CLEAN UP SECTION
--------------------------------------------------------------------
--
---- BEGIN CLEANUP...
--:SETVAR PRINCIPALSERVER CHICAGO\SQLDEV01
--:SETVAR MIRRORSERVER CHICAGO\SQLDEV02
--:SETVAR WITNESSSERVER CHICAGO\SQLDEV03
--:SETVAR DATABASE2MIRROR TicketSalesDB
--GO
--
--:CONNECT $(PRINCIPALSERVER)
--
--USE MASTER
--GO
--
--ALTER DATABASE $(DATABASE2MIRROR)
--    SET PARTNER OFF
--GO
--
--DROP ENDPOINT MIRRORING
--GO
--
--:CONNECT $(MIRRORSERVER)
--
--DROP ENDPOINT MIRRORING
--GO
--
--ALTER DATABASE $(DATABASE2MIRROR)
--    SET PARTNER OFF
--GO
--DROP DATABASE $(DATABASE2MIRROR)
--GO
--
--:CONNECT $(WITNESSSERVER)
--
--DROP ENDPOINT MIRRORING
--GO
--
------ END CLEANUP...
