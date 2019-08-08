--Signature="2A33C717B543E3EB" 

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    Enumerate databases                                                                               ****/
--/****    updated 11 May 2009 (wardp) to exclude off-line databases                                         ****/
--/****    updated 24 Sep 2009 (wardp) for SQL Server 2008 (CR 375891)                                       ****/
--/****    updated 24 May 2010 (wardp) CR 458680                                                             ****/
--/****    updated 22 Jul 2010 (wardp) CR 466805                                                             ****/
--/****    updated 23 Mar 2011 (rajpo) Bug 473243 sorted by Database name                                    ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright (c) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

set nocount on
declare @version nvarchar(12),
        @ReportingServicesMaster sysname,
        @ReportingServicesTempdb sysname

SET		@ReportingServicesMaster = 'ReportServer' +
			CASE  
				WHEN CONVERT(sysname,SERVERPROPERTY('InstanceName')) IS NOT NULL
					THEN '$' + CONVERT(sysname,SERVERPROPERTY('InstanceName'))
				ELSE ''
			END
SET		@ReportingServicesTempdb = @ReportingServicesMaster + 'TempDB';
set     @version =  convert(nvarchar(12),serverproperty('productversion'));

if  8 = (select substring(@version, 1, 1))
begin

        declare @distribdb sysname
 
        exec sp_helpdistributor @distribdb = @distribdb output

        select  [name]                              AS [Name],
                suser_name(sid)                     AS [Owner],
                [cmptlevel]                         AS [CompatibilityLevel],
                serverproperty('productversion')    AS [SQLServerVersion]
        from master..sysdatabases
        where  (
	             (@distribdb is not null and lower(name) <> lower(@distribdb))
	             OR
	             (@distribdb IS NULL)
	           )
        -- omit databases which did not start up cleanly
        and		status & 32 = 0		-- loading
        and		status & 64 = 0		-- pre recovery
        and		status & 128 = 0	-- recovering
        and		status & 256 = 0	-- not recovered
        and		status & 512 = 0	-- offline
        and		status & 32768 = 0	-- emergency mode
        order by name

    return;

end

else

begin

    if  9 = (select substring(@version, 1, 1))
    begin

        select  [name]                              AS [Name],
                suser_name(owner_sid)               AS [Owner],
                [compatibility_level]               AS [CompatibilityLevel],
                serverproperty('productversion')    AS [SQLServerVersion]
        from master.sys.databases
        where   state_desc = N'ONLINE'
        and		is_distributor = 0
		and		name not in (@ReportingServicesMaster, @ReportingServicesTempdb, N'ReportServer', N'ReportServerTempDB')
		order by name

    end;

end

begin

    if  '10' = (select substring(@version, 1, 2))
    begin

        select  [name]                              AS [Name],
                suser_name(owner_sid)               AS [Owner],
                [compatibility_level]               AS [CompatibilityLevel],
                serverproperty('productversion')    AS [SQLServerVersion]
        from master.sys.databases
        where   state_desc = N'ONLINE'
        and		is_distributor = 0
		and		name not in (@ReportingServicesMaster, @ReportingServicesTempdb, N'ReportServer', N'ReportServerTempDB')
		order by name

    end;

end;