/*
	SQL Services Health check script for SQL Server 2008+
	Script Name : HealthCheckv2.sql
	The purpose of this script is to collect data for the SQL Server Health Check Version 2 reporting process.
	******Ensure you are on the actual server that is hosting the instance (not connected to an instance from another server)*****

	1. Set the query to run in SQL Command Mode (From the Query menu select "SQLCMD Mode")
	2. Run the script (with results to Grid)
	3. Copy the Output (without headers), paste it into Notepad and Bring back to SQL Services!

	This script can take from between 20 and 200 seconds to execute, depending on configured parameters (see below)
	and system speed. It is not anticipated that this script cause any system or service outage or disruption.
	
	This Script will run on

	-- SQL Server 2008 + (All editions)
	-- Case sensitive servers	

	==========================================================================================================
	Date		Version		Who				
	==========================================================================================================
	01-05-2017	2.92		Dean McMillan	
	21-06-2017	2.93		Dean McMillan	
	14-07-2017	2.95		Dean McMillan
	05-12-2017	2.97		Dean McMillan
	01-06-2018	2.98		Dean McMillan
	05-06-2018	2.99		Dean McMillan
	11-03-2020	3.00		Sandeep Perera
	18-03-2020	3.01		Ron Pitts

	refer to changelog.txt file for details of changes in each version

	==========================================================================================================
*/

:setvar ScriptVersion "'3.01'"

---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-- START OF CONFIGURATION SECTION

-- Customer Code, replace the Customer with the meaningful agreed code.  Please dont use spaces, and if the client is contracted, use their CORRECT CODE.

:setvar CustCode "'XXX'"
:setvar CustName "'Enter the Customer Name here'"

-- Is the RPO and RTO known?  
	:setvar KnownRTOandRPO "'Y'"
-- What is the RPO setting?  Format is [N][m/h/d], e.g. 1m = 1 minute, 23h = 23 hours, 4d = 4 days
-- Failing to follow this format will not end well !
	:setvar RPO "'15m'"
-- What is the RTO setting?  Format is [N][m/h/d], e.g. 1m = 1 minute, 23h = 23 hours, 4d = 4 days
-- Failing to follow this format will not end well !
	:setvar RTO "'30m'"
-- If this server (where the instance is installed) a Domain Controller?
	:setvar IsDomainController "'N'"
-- Are 3rd party tools used for monitoring Alert conditions?
	:setvar ThirdPartyMonitoingToolsUsed "'N'"
-- Is this server a dedicated Data warehouse server?
	:setvar IsDwServer "'N'"
-- Is this an OLTP type server?  (NOTE:  A Server can be a DW and OLTP server)
	:setvar IsOLTPServer "'Y'"
-- Is there an aggreed maintenance window?  Set to Y or N
	:setvar AgreedMaintenanceWindow "'Y'"


-- default for max database size is 10GB / 10240MB.  Used for limiting the time it takes to gather index fragmentation
-- The larger you set this value the longer the script will take to run.  Treat with caution.
	:setvar MaxDBSizeMB 10240

-- default for used for limiting the number of objects returned for index fragmentation.  
-- Objects with a page count above this value and over the FragmentationPercent will be collected.
	:setvar ObjectPageCount 1000
-- default for used for limiting the number of objects returned for index fragmentation.  
-- Indexes with FragmentationPercent higher than this and are over the ObjectPageCount and will be collected.
	:setvar FragmentationPercent 50
-- Number of days to look back in the Windows Event Logs (System and Application)
	:setvar EventDaysToGet 5
-- Event log collection 
	:setvar GetEventLogs "'Y'"
-- Duration of database autogrow events that take longer than this value in seconds.  Can be set lower e.g. 0.25 is 0.25 seconds
	:setvar AutoGrowDurationSeconds 1.00
-- Number of days to look back for Autogrowth events.  May impact server if changed to a larger number.
	:setvar AutoGrowthDaysBack 30
-- Threshold for slow write time (milliseconds)
	:setvar SlowWriteThresholdMS 8
-- Threshold for slow read time (milliseconds)
	:setvar SlowReadThresholdMS 8
-- Do you want to Check Implicit Conversions in the query plan cache?  Be very careful turning this on ("'Y'"), it can take a long time to run and may impact the server
	:setvar CheckImplicitPlans "'N'"

-- Can we use powershell on the server?  Turn this off if we cannot (due to customer requiements or permissions etc).
-- If you don't use PowerShell, the following information will not be connected

--	Server Power settings
--	Windows Application logs and System Event logs
--	Browser Service is running
--	Is SSAS is Installed
--	SSIS Service Account details
--	List of SQL Server services running
--	Disk Cluster Size
--	Disk Space Readings

	:setvar UsePowershell "'Y'"


-- Is the server Internet facing?  Possible values are Y or N
	:setvar InternetFacing "'N'"
--Is the SA password known?  Possible values are Y or N
	:setvar SAPasswordKnown "'Y'"
-- set this to report whether Force Encryption is used for connections
	:setvar ForceEncryption "'N'"
/*
	NOTES on "NumberOfLogFilesToRead":	
 
		Set this number to match how many SQL Server Log files you see on the instance
		There can be between 6 and 99 SQL Server error log files.
		There will be a Current plus a series of Archive #s - e.g. 
	
				Current - dd/mm/yyyy hh:mm:ss
				Archive #1 - dd/mm/yyyy hh:mm:ss
				Archive #2 - dd/mm/yyyy hh:mm:ss
				Archive #3 - dd/mm/yyyy hh:mm:ss
				Archive #4 - dd/mm/yyyy hh:mm:ss
				Archive #5 - dd/mm/yyyy hh:mm:ss
				Archive #6 - dd/mm/yyyy hh:mm:ss
				Archive #7 - dd/mm/yyyy hh:mm:ss
				Archive #8 - dd/mm/yyyy hh:mm:ss
			
		The number to set the variable NumberOfLogFilesToRead is equal to the number of files (current and archive).  So in the above example NumberOfLogFilesToRead should be 9.
		The default is to read the first file only to avoid the possibility of killing the server from reading all entries into memory
*/		
	:setvar NumberOfLogFilesToRead 1
	-- Parameter for error log file size to look at in MB - ignore any SQL error log files bigger than this
	:setvar MaxErrorLogFileSizeMB 50
	-- search string for SQL and SQL Agent Error Log errors - change as required
	:setvar ErrorString1 "'error'"
	:setvar ErrorString2 "'fail'"

-- END OF CONFIGURATION SECTION
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

-- check for SQLCMD mode.  If SQLCmd mode is not enabled then stop.
:setvar SQLCmdMode "?"

go

if ('$(SQLCmdMode)' = '$' + '(SQLCmdMode)')
	begin
		declare @OutputMessage varchar(1000)
		set @OutputMessage = char(10)+char(13) + char(10)+char(13) + '>>>     This script must be run in SQLCMD mode.  Please select Query / SQLCMD mode from the main menu and try again!    <<<' + char(10)+char(13) + char(10)+char(13)
		raiserror (@OutputMessage , 16, 1) with nowait
	end
go


-- Check for Cust Code.  If Cust Code not changed from 'XXX' then stop
if $(CustCode) = 'XXX'
begin
	declare @NoCustCode varchar(1000)
	set @NoCustCode = char(10)+char(13) + char(10)+char(13) + 'Please change the Cust Code (Variable: CustCode) to something OTHER than the default of XXX.' + char(10)+char(13) + char(10)+char(13)
	raiserror (@NoCustCode , 16, 1) with nowait
	set noexec on
end


-- Check for Customer Name.  If Cust Code not changed from 'XXX' then stop
if $(CustName) = 'Enter the Customer Name here'
begin
	declare @NoCustName varchar(1000)
	set @NoCustName = char(10)+char(13) + char(10)+char(13) + 'Please change the Cust Name (Variable: CustName) to something OTHER than the default of "Enter the Customer Name here".' + char(10)+char(13) + char(10)+char(13)
	raiserror (@NoCustName , 16, 1) with nowait
	set noexec on
end


--------------------------------------------------------------------------------
-- Drop Working Temp Tables
--------------------------------------------------------------------------------
begin

	set nocount on

	if object_id('tempdb..#Problems') is not null
		drop table #Problems
	
	if object_id('tempdb..#SSL_Message') is not null
		drop table #SSL_Message

	if object_id('tempdb..#SSL_KVP') is not null
		drop table #SSL_KVP

	if object_id('tempdb..#SSL_Svr') is not null
		drop table #SSL_Svr

	if object_id('tempdb..#SSL_Counter') is not null
		drop table #SSL_Counter

	if object_id('tempdb..#SSL_DatabaseFiles') is not null
		drop table #SSL_DatabaseFiles

	if object_id('tempdb..#SSL_LastBackupLogs') is not null
		drop table #SSL_LastBackupLogs

	if object_id('tempdb..#SSL_LastBackups') is not null
		drop table #SSL_LastBackups

	if object_id('tempdb..#SSL_MSVer') is not null
		drop table #SSL_MSVer

	if object_id('tempdb..#SSL_DiskDrives') is not null
		drop table #SSL_DiskDrives

	if object_id('tempdb..#SSL_StartUpParameters') is not null
		drop table #SSL_StartUpParameters

	if object_id('tempdb..#SSL_Configuration') is not null
		drop table #SSL_Configuration

	if object_id('tempdb..#SSL_DBMailStatus') is not null
		drop table #SSL_DBMailStatus

	if object_id('tempdb..#SSL_BlankPasswords') is not null
		drop table #SSL_BlankPasswords

	if object_id('tempdb..#SSL_BuiltInAdmin') is not null
		drop table #SSL_BuiltInAdmin

	if object_id('tempdb..#SSL_NetStart') is not null
		drop table #SSL_NetStart

	if object_id('tempdb..#SSL_FailedJobs') is not null
		drop table #SSL_FailedJobs

	if object_id('tempdb..#SSL_Databases') is not null
		drop table #SSL_Databases

	if object_id('tempdb..#SSL_SystemInfo') is not null
		drop table #SSL_SystemInfo

	if object_id('tempdb..#UserDBSizing') is not null
		drop table #UserDBSizing

	if object_id('tempdb..#UserDatabases') is not null
		drop table #UserDatabases

	if object_id('tempdb..#TempForFileStats') is not null
		drop table #TempForFileStats

	if object_id('tempdb..#TempForDataFile') is not null
		drop table #TempForDataFile

	if object_id('tempdb..#TempForLogFile') is not null
		drop table #TempForLogFile

	if object_id('tempdb..#DBTable') is not null
		drop table #DBTable

	if object_id('tempdb..#GuestDatabases') is not null
		drop table #GuestDatabases

	if object_id('tempdb..#Registry') is not null
		drop table #Registry

	if object_id('tempdb..#JobsOwnedByUsers') is not null
		drop table #JobsOwnedByUsers

	if object_id('tempdb..#ForcedParameterization') is not null
		drop table #ForcedParameterization

	if object_id('tempdb..#HasReplication') is not null
		drop table #HasReplication;

	if object_id('tempdb..#LogShippingDetails') is not null
		drop table #LogShippingDetails

	if object_id('tempdb..#MirroringDetails') is not null
		drop table #MirroringDetails

	if object_id('tempdb..#TDEDatabases') is not null
		drop table #TDEDatabases

	if object_id('tempdb..#UserObjectsInModelDB') is not null
		drop table #UserObjectsInModelDB

	if object_id('tempdb..#LinkedServers') is not null
		drop table #LinkedServers

	if object_id('tempdb..#JobsWhichAutoStart') is not null
		drop table #JobsWhichAutoStart
		
	if object_id('tempdb..#UnusedCPUs') is not null
		drop table #UnusedCPUs

	if object_id('tempdb..#SlowGrowingDBs') is not null
		drop table #SlowGrowingDBs

	if object_id('tempdb..#CPUdata') is not null
		drop table #CPUdata

	if object_id('tempdb..#SlowReadsAndWrites') is not null
		drop table #SlowReadsAndWrites

	if object_id('tempdb..#ImplicitResults') is not null
		drop table #ImplicitResults

	if object_id('tempdb..#TheQueries') is not null
		drop table #TheQueries

	if object_id('tempdb..#currentReadings') is not null
		drop table #currentReadings

	if object_id('tempdb..#KeyLookups') is not null
		drop table #KeyLookups	

	if object_id('tempdb..#HighImpactIndexes') is not null
		drop table #HighImpactIndexes

	if object_id('tempdb..#UnusedIndexes') is not null
		drop table #UnusedIndexes

	if object_id('tempdb..#DuplicateIndexes') is not null
		drop table #DuplicateIndexes

	if object_id('tempdb..#tempdrives') is not null
		drop table #tempdrives

	if object_id('tempdb..#tempdbdata') is not null
		drop table #tempdbdata

	if object_id('tempdb..#MemoryTables') is not null
		drop table #MemoryTables

	if object_id('tempdb..#DelayedDurability') is not null
		drop table #DelayedDurability

	if object_id('tempdb..#AGDetails') is not null
		drop table #AGDetails

	if object_id('tempdb..#DatabaseNames') is not null
		drop table #DatabaseNames
		
	if object_id('tempdb..#AllDBs') is not null
		drop table #AllDBs

	if object_id('tempdb..#ColumnStoreIndexes') is not null
		drop table #ColumnStoreIndexes

	if object_id('tempdb..#DatabaseContainment') is not null
		drop table #DatabaseContainment

	if object_id('tempdb..#UserDefinedRoles') is not null
		drop table #UserDefinedRoles

	if object_id('tempdb..#LastRebuiltIndexes') is not null
		drop table #LastRebuiltIndexes

	if object_id('tempdb..#NonProdDBs') is not null
		drop table #NonProdDBs

	if object_id('tempdb..#SSL_SystemPolicies') is not null
		drop table #SSL_SystemPolicies

	if object_id('tempdb..#DBCCs') is not null
		drop table #DBCCs	

	if object_id('tempdb..#PowerSettings') is not null
		drop table #PowerSettings

	if object_id('tempdb..#Results') is not null
		drop table #Results

	if object_id('tempdb..#SSL_DBFileSizes') is not null
		drop table #SSL_DBFileSizes

	if object_id('tempdb..#SSL_OrphanedUsers') is not null
		drop table #SSL_OrphanedUsers

	if object_id('tempdb..#SQLAlerts') is not null
		drop table #SQLAlerts

	if object_id('tempdb..#EnterpriseFeatures') is not null
		drop table #EnterpriseFeatures

	if object_id('tempdb..#logs') is not null
		drop table #logs

	if object_id('tempdb..#agentlogs') is not null
		drop table #agentlogs

	if object_id('tempdb..#DatabaseCompression') is not null
		drop table #DatabaseCompression

	if object_id('tempdb..#ProcsThatAutoStart') is not null
		drop table #ProcsThatAutoStart

	if object_id('tempdb..#FTIndexes') is not null
		drop table #FTIndexes

	if object_id('tempdb..#SSL_Endpoint') is not null
		drop table #SSL_Endpoint;

	if object_id('tempdb..#XPCommandShell') is not null
		drop table #XPCommandShell

	if object_id('tempdb..#tmp_replication') is not null
		drop table #tmp_replication

end
go

--------------------------------------------------------------------------------
-- Set Environment Properties
--------------------------------------------------------------------------------
begin
	set nocount on
	if (select value_in_use from master.sys.configurations where configuration_id = 518) <> 1  
	begin
		execute master.dbo.sp_configure 'show advanced options', 1
		reconfigure with override
	end
	
end
go


begin
	set nocount on
	set quoted_identifier on
	set ansi_nulls on
	use master
end
go


declare @currentLangauge nvarchar(128)

-- okay, set up our working tables
begin
	
	-- first the counter table for set based operations
	create table #SSL_Counter
	(
		id		int	identity(2,1), -- starts at 2, cos we're inserting the first record
		data	int	null		
	);

	-- and the message table we are going to insert into
	create table #SSL_Message
	(
		MessageTypeID	int				not null,
		MessageID		int				not null,
		KeyID			int				not null,
		KeyValue		nvarchar(4000)	null,
		constraint pk_SSLMessage primary key (MessageTypeID, MessageID, KeyID)
	);

	
	-- this table holds Key Value Pair information
	create table #SSL_KVP
	(
		RecordID	int		identity(1,1),		
		KeyName		varchar(128)	not null,
		KeyValue	nvarchar(4000)	null,
		constraint pk_KVP primary key nonclustered (KeyName)
	);

	-- this table holds repeatable Single Value Records
	create table #SSL_Svr
	(
		RecordID		int		identity(1,1),		
		MessageTypeID	tinyint		not null,
		KeyValue		nvarchar(4000)	null,
	);

	create table #SSL_Configuration
	(
		RecordID	int	identity(1,1),
		[Name]		sysname,
		Minimum		int,
		Maximum		int,
		ConfigValue	int,
		RunValue	int
	);
	
	create table #XPCommandShell
	(
		IsEnabled bit
	)

	insert into #XPCommandShell select 0

	-- okay, get the configure results
	insert #SSL_Configuration execute master.dbo.sp_configure;

	-- can we run xps?
	if (select RunValue from #SSL_Configuration where [Name] = 'xp_cmdshell') = 0
	begin
		-- if not, temporarily turn on, then disable at completion
		-- we need to make sure the clients know this process would temporarily		
		-- enable then disable this setting, as we require it.

		update #XPCommandShell set IsEnabled = 1
	
		exec master.dbo.sp_configure 'xp_cmdshell', 1;
		reconfigure with override;

	end



	-- this table hold a "master list" of database names that is used over and over in the script.  
	-- Saves having to retrieve the data repeatedly, also allows atomatic filtering based on SQL Version (e.g. 2012+ with High Availability) and
	-- also the size limit based on $(MaxDBSizeMB)
	create table #DatabaseNames
	(
		DatabaseName sysname
		,DatabaseId int
		,Processed bit
	)


	-- this table is to record problems so we know what data may be missing
	create table #Problems 
	(	
		MessageType		varchar(50)
		,ProblemDesc	varchar(1000)	
	)


end
go


-- populate #DatabaseNames filtered on maximum size
begin
	declare @Cmd nvarchar(max)
	declare @MajorVersion tinyint

	set @MajorVersion = left(cast(serverproperty('productversion') as nvarchar(max)),charindex('.',cast(serverproperty('productversion') as nvarchar(max)))-1) 

	set @Cmd = 
		'set transaction isolation level read uncommitted;
		Insert into #DatabaseNames 
		 select distinct
			db_name(f.database_id)
			,f.database_id
			,0
		from 
			sys.master_files f
			inner join sys.databases db on db.database_id = f.database_id
		where
			db.state_desc = ''ONLINE'''

	if @MajorVersion >=11
		set @Cmd = @Cmd + ' and db.name not in (select distinct
								dbcs.database_name [DatabaseName]
							from 
								master.sys.availability_groups as AG
								left outer join master.sys.dm_hadr_availability_group_states as agstates on AG.group_id = agstates.group_id
								inner join master.sys.availability_replicas as AR on AG.group_id = AR.group_id
								inner join master.sys.dm_hadr_availability_replica_states as arstates on AR.replica_id = arstates.replica_id and arstates.is_local = 1
								inner join master.sys.dm_hadr_database_replica_cluster_states as dbcs on arstates.replica_id = dbcs.replica_id
								left outer join master.sys.dm_hadr_database_replica_states as dbrs on dbcs.replica_id = dbrs.replica_id and dbcs.group_database_id = dbrs.group_database_id
							where 
								isnull(arstates.role, 3) = 2 and isnull(dbcs.is_database_joined, 0) = 1)'

	set @Cmd = @Cmd + '	group by
			f.database_id
			,db_name(f.database_id)
		having 
			sum(f.size * 8.0 / 1024) <= $(MaxDBSizeMB)	
			or db_name(f.database_id) in (''tempdb'')' 

	exec sp_executesql @Cmd

end


-- get a list of all datbases
	create table #AllDBs
	(
		DatabaseName sysname
		,DatabaseId int
		,Processed bit
	)

	set @Cmd = 'set transaction isolation level read uncommitted;'
	set @Cmd = @Cmd + 	'insert into #AllDBs select name, database_id, 0 from sys.databases where state_desc = ''ONLINE'''
	

	if @MajorVersion >=11
		set @Cmd = @Cmd + ' and name not in (select distinct
								dbcs.database_name [DatabaseName]
							from 
								master.sys.availability_groups as AG
								left outer join master.sys.dm_hadr_availability_group_states as agstates on AG.group_id = agstates.group_id
								inner join master.sys.availability_replicas as AR on AG.group_id = AR.group_id
								inner join master.sys.dm_hadr_availability_replica_states as arstates on AR.replica_id = arstates.replica_id and arstates.is_local = 1
								inner join master.sys.dm_hadr_database_replica_cluster_states as dbcs on arstates.replica_id = dbcs.replica_id
								left outer join master.sys.dm_hadr_database_replica_states as dbrs on dbcs.replica_id = dbrs.replica_id and dbcs.group_database_id = dbrs.group_database_id
							where 
								isnull(arstates.role, 3) = 2 and isnull(dbcs.is_database_joined, 0) = 1)'

	--insert into #AllDBs select name, database_id, 0 from sys.databases where state_desc = 'ONLINE'
	exec sp_executesql @Cmd


-- Process all the KVP (Key Vaule Pair) information
print 'Getting all the key-value-pair information...'
print '--------------------------------------------'

insert #SSL_KVP select 'ScriptVersion', convert(varchar(100), $(ScriptVersion))
insert #SSL_KVP select 'EventLogDays', convert(varchar(100), $(EventDaysToGet))
insert #SSL_KVP select 'NumberOfLogFilesToRead', convert(varchar(100), $(NumberOfLogFilesToRead))
insert #SSL_KVP select 'MaxErrorLogFileSizeMB', convert(varchar(1000), $(MaxErrorLogFileSizeMB))
insert #SSL_KVP select 'SlowWriteThresholdMS', convert(varchar(100), $(SlowWriteThresholdMS))
insert #SSL_KVP select 'SlowReadThresholdMS', convert(varchar(100), $(SlowReadThresholdMS))


begin
	print 'Cust Code = ' + convert(varchar(20), $(CustCode))
	insert #SSL_Message select 1, 1, 1, convert(varchar, $(CustCode));

	declare @PsCmd varchar(4000)

	declare @PSResults table
	(
		PSOutput varchar(100)
	)

	set @PsCmd =  '@PowerShell -noprofile -command "$env:PROCESSOR_ARCHITECTURE"'

	insert into @PSResults execute master..xp_cmdshell @PsCmd
	delete from @PSResults where PSOutput is null
	
	if exists (select * from @PSResults)
	begin	
		insert #SSL_KVP select 'ServerArchitecture', PSOutput from @PSResults
	end
	else
	begin
		insert #SSL_KVP select 'ServerArchitecture', '!Not Collected!'
	end

	insert #SSL_KVP select 'CustName', convert(varchar, $(CustName));
end

begin	
	print 'AgreedMaintenanceWindow=' + convert(varchar(10), $(AgreedMaintenanceWindow))
	insert #SSL_KVP select 'AgreedMaintenanceWindow', $(AgreedMaintenanceWindow)
end

begin
	print 'Looking at Index Fragmentation for indexes larger than ' + convert(varchar, $(ObjectPageCount)) + ' pages'
	insert #SSL_KVP select 'ObjectPageCount', $(ObjectPageCount)
end

begin
	print 'Looking at Index Fragmentation over ' + convert(varchar, $(FragmentationPercent)) + ' percent'
	insert #SSL_KVP select 'FragmentationPercent', $(FragmentationPercent)
end

begin
	print 'KnownRTOandRPO=' + convert(varchar, $(KnownRTOandRPO))
	insert #SSL_KVP select 'KnownRTOandRPO', $(KnownRTOandRPO)
end

begin	
	if $(KnownRTOandRPO) = 'Y'
	begin
		print 'RTO=' + convert(varchar(10), $(RTO))
		insert #SSL_KVP select 'RTO', $(RTO)
	end
	else
	begin -- if it's N, then default to 1d
		print 'RTO=1d (default based on KnownRTOandRPO being N)'
		insert #SSL_KVP select 'RTO', '1d'
	end

end

begin	
	if $(KnownRTOandRPO) = 'Y'
	begin
		print 'RPO=' + convert(varchar, $(RPO))
		insert #SSL_KVP select 'RPO', $(RPO)
	end
	else
	begin -- if it's N, then default to 1d
		print 'RPO=1d (default based on KnownRTOandRPO being N)'
		insert #SSL_KVP select 'RPO', '1d'
	end
end

begin	
	print 'SA Password Known=' + convert(varchar(10), $(SAPasswordKnown))
	insert #SSL_KVP select 'SA Password Known', $(SAPasswordKnown)
end

begin	
	print 'Internet Facing=' + convert(varchar(10), $(InternetFacing))
	insert #SSL_KVP select 'InternetFacing', $(InternetFacing)
end


begin	
	print '3rd Party Montoring tools used =' + convert(varchar(10), $(ThirdPartyMonitoingToolsUsed))
	insert #SSL_KVP select '3rdPartyMonitoingToolsused', $(ThirdPartyMonitoingToolsUsed)
end

begin
	insert #SSL_KVP select 'CPUCount', cpu_count from sys.dm_os_sys_info
end

begin
	insert #SSL_KVP select 'ProcessorsDisabled', count(is_online) from sys.dm_os_schedulers where is_online = 0
end

begin
	insert #SSL_KVP select 'HyperThreadRatio', hyperthread_ratio from sys.dm_os_sys_info
end

begin
	insert #SSL_KVP select 'MaxDatabaseSizeMB', convert(varchar, $(MaxDBSizeMB))
end

begin
	insert #SSL_KVP select 'IsDomainController', case when convert(varchar, $(IsDomainController)) = 'Y' then 1 else 0 end
end

begin
	insert #SSL_KVP select 'IsDwServer', case when convert(varchar, $(IsDwServer)) = 'Y' then 1 else 0 end
end

begin
	insert #SSL_KVP select 'IsOLTPServer', case when convert(varchar, $(IsOLTPServer)) = 'Y' then 1 else 0 end
end

begin
	insert #SSL_KVP select 'SystemCollation', convert(nvarchar, serverproperty('collation'))
end

begin
	if exists (select * from sys.dm_exec_connections where encrypt_option = 'TRUE')
		insert #SSL_KVP select 'ForceEncryption', 'Detected';
	else
		insert #SSL_KVP select 'ForceEncryption', 'Not Detected';
end

begin
	print 'Checking EKM Provider....'
	if exists (select * from sys.configurations where name = 'EKM provider enabled')
		insert into #SSL_KVP select 'EKM provider enabled', isnull(cast(value_in_use as varchar(11)), 0) from sys.configurations where name = 'EKM provider enabled'
	else
		insert into #SSL_KVP select 'EKM provider enabled', 0 

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
end

begin
	print 'Assessing FILESTREAM Access Level..'
	if exists (select * from sys.configurations where name = 'filestream access level')
		insert into #SSL_KVP select 'Filestream Access Level', cast(value_in_use as varchar(11)) from sys.configurations where name = 'filestream access level'
	else
		insert into #SSL_KVP select 'Filestream Access Level', 0 

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
end


begin
	print 'Looking at Index Create Memory...'

	if exists (select * from sys.configurations where name = 'Index create memory (KB)')
		insert into #SSL_KVP  select 'Index Create Memory', cast(value_in_use as varchar(11)) from sys.configurations where name = 'Index create memory (KB)'
	else
		insert into #SSL_KVP  select 'Index Create Memory', 0 

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
end

begin
	print 'Querying CPU Affinity Mask...'
	if exists (select * from sys.configurations where name = 'affinity mask')
		insert into #SSL_KVP  select 'affinity mask', cast(value_in_use as varchar(11)) from sys.configurations where name = 'affinity mask'
	else
		insert into #SSL_KVP  select 'affinity mask', 0

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
 end

begin
	print 'Scanning Scan for Startup Procedures...'
	if exists (select * from sys.configurations where name = 'scan for startup procs')
		insert into #SSL_KVP  select 'ScanStartupProcs', cast(value_in_use as varchar(11)) from sys.configurations where name = 'scan for startup procs'
	else
		insert into #SSL_KVP  select 'ScanStartupProcs', 0

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
end

begin
	print 'Looking at NUMA nodes...'
	insert into #SSL_KVP select 'NUMA_Nodes', count(*) from sys.dm_os_memory_nodes where memory_node_id <> 64
	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
end


begin

	print 'Checking average read and write latency....'
	declare @AvgReadTime bigint
	declare @AvgWriteTime bigint

	select
		@AvgReadTime = avg(io_stall_read_ms * 1.00 / num_of_reads ) 
		,@AvgWriteTime =avg(io_stall_write_ms * 1.00 / num_of_writes ) 
	from
		sys.dm_io_virtual_file_stats (NULL, NULL)
	where
		num_of_reads > 0 and num_of_writes > 0

	insert into #SSL_KVP select 'AvgReadLatency', @AvgReadTime
	insert into #SSL_KVP select 'AvgWriteLatency', @AvgWriteTime

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


begin

	print 'Investigating Windows Guest Account...'

	declare @GuestResult varchar(20)

	declare @PowerShellResult table
	(
		ResultLine varchar(255)
	)

	declare @XMLData table
	(
		GuestInfo xml
	)

	declare @PowerShellCmd varchar(255)
			, @XmlText varchar(max)

	set @PowerShellCmd = '@PowerShell -noprofile -command "$Filter=''"LocalAccount=True and Name = ''''Guest''''"'';  Get-WmiObject Win32_UserAccount -filter $Filter | Select @{Name=''Disabled''; E={$_.Disabled}} | ConvertTo-XML -As String"'
	--print @PowerShellCmd

	insert into @PowerShellResult execute master..xp_cmdshell @PowerShellCmd
	
	if exists (select * from @PowerShellResult where ResultLine like '%Get-WmiObject : Access is denied%')
	begin
		insert #Problems select top 1 'Windows Guest Account', 'There was a problem checking the Windows Guest Account access using powershell.  The error is :' + 'Access Denied'
		insert #SSL_KVP select top 1 'WindowsGuestAccountEnabled', '!Not Collected!'
	end
	else
	begin


		select @XmlText = ''
		select @XmlText = @XmlText + ltrim(rtrim(ResultLine)) from @PowerShellResult where left(ltrim(rtrim(ResultLine)), 1) = '<'
		select @XmlText = replace(@XmlText, '&#x0;', '')

		insert into @XMLData
		select cast(@XmlText as xml);

		select
			@GuestResult = m.c.value('(Property[@Name="Disabled"]/text())[1]', 'varchar(20)')
		from 
			@XMLData as x
			outer apply x.GuestInfo.nodes('Objects/Object') as m(c)

		insert into #SSL_KVP select 'WindowsGuestAccountEnabled', case when @GuestResult = 'True' then 0 else 1 end

	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


begin

	print 'Getting log backup frequency...'

	declare @LogBackupDurations table
	(
		DatabaseName varchar(128)
		,IntervalMins	int
	)

	declare @ServerLogBackupInterval int

	insert into @LogBackupDurations
	select 
		database_name
		,datediff(minute, min(msdb.dbo.backupset.backup_start_date), max(msdb.dbo.backupset.backup_start_date)) / count(*)
	from   
		msdb.dbo.backupmediafamily 
		inner join msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
		left outer join msdb.dbo.log_shipping_primary_databases lsp on database_name = lsp.primary_database
		left outer join msdb.dbo.log_shipping_secondary_databases lss on database_name = lss.secondary_database
	where  
		(convert(datetime, msdb.dbo.backupset.backup_start_date, 102) >= getdate() - 7) 
		and msdb..backupset.type = 'L'
		and lsp.primary_database is not null 
	group by
		database_name
		,lsp.primary_database
		,lss.secondary_database

	select @ServerLogBackupInterval = max(IntervalMins) from @LogBackupDurations

	insert into #SSL_KVP select 'LogBackupInt', @ServerLogBackupInterval

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end



begin

print 'Checking for multiple instances...'

	declare @GetInstances table
	( 
		Value nvarchar(100),
		InstanceNames nvarchar(100),
		Data nvarchar(100)
	)

	Insert into @GetInstances execute xp_regread
	  @rootkey = 'HKEY_LOCAL_MACHINE',
	  @key = 'SOFTWARE\Microsoft\Microsoft SQL Server',
	  @value_name = 'InstalledInstances'

	insert into #SSL_KVP select 'InstanceCount', count(InstanceNames) from @GetInstances 

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)	

end

go


--------------------------------------------------------------------------------
-- SQL Configuration: SQL Server Memory Settings
--------------------------------------------------------------------------------
begin
	set nocount on
	print 'Getting SQL Server Memory Settings...'
	print	'AWE ENABLED SETTING...'
	if exists (select * from sys.configurations where lower(name) = 'awe enabled')
		insert into #SSL_KVP select 'AWE Enabled', 1
	else
		insert into #SSL_KVP select 'AWE Enabled', 0


	print	'MIN SERVER MEMORY SETTING'
	insert into #SSL_KVP select 'min server memory (MB)', isnull(cast(value_in_use as varchar(11)), '!Not Collected!') from sys.configurations
	where name = 'min server memory (MB)'

	print	'MAX SERVER MEMORY SETTING'
	insert into #SSL_KVP select 'max server memory (MB)', isnull(cast(value_in_use as varchar(11)), '!Not Collected!') from sys.configurations
	where name = 'max server memory (MB)'

	print	'fixed/dynamic memory setting...'
	if
	(
		(select value from master.sys.configurations where name = 'Minimum size of server memory (MB)')
		=
		(select value from master.sys.configurations where name = 'Maximum size of server memory (MB)')
	)
	begin
		insert into #SSL_KVP select 'fixed/dynamic memory setting', 'fixed'
	end
	else
	begin
		insert into #SSL_KVP select 'fixed/dynamic memory setting', 'dynamic'
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


--------------------------------------------------------------------------------
-- SQL Configuration: Access Check Cache Bucket Count
--------------------------------------------------------------------------------
begin
	set nocount on

	print 'Finding Access Check Cache Bucket Count....'

	insert into #SSL_KVP select 'Access Check Cache Bucket Count', isnull(cast(value_in_use as varchar(11)), '!Not Collected!') from sys.configurations
	where name = 'Access Check Cache Bucket Count' 
	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

	print 'Access Check Cache Quota....'
	
	insert into #SSL_KVP select 'Access Check Cache Quota', isnull(cast(value_in_use as varchar(11)), '!Not Collected!') from sys.configurations
	where name = 'Access Check Cache Quota'
	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
end


Print 'Checking Virtualisation...'

begin	

	-- Hardware and operating System section
	--Server Application Response: Also known as Priority Control
	/*

	Read Application Response Setting (Priority Control)

	0          Foreground and background applications equally responsive
	1          Foreground applications more reponsive than background
	2          Best foreground application response time

	*/
	set nocount on

	declare @CmdString nvarchar(100) = N'SYSTEM\CurrentControlSet\Control\PriorityControl\'
	declare @val int = -1
	
	begin try
		exec master.dbo.xp_regread 
			N'HKEY_LOCAL_MACHINE', 
			@CmdString, 
			N'Win32PrioritySeparation',
			@param = @val output
	end try
	begin catch
	-- log the fact that we can't get the registry key in a table of error results
	end catch

	--select @val
	insert #SSL_KVP select 'ServerApplicationResponse', @val


	-- Virtualisation - Is the Server Virtualised 
	-- this check can only be done on builds above 10.50.1600
	-- Virtualisation can be retrieved from system views on 2008R2 SP1 and above.
	declare @SQLVersion varchar(50)
	declare @iver		float
	declare @subVer		varchar(10)


	select @SQLVersion =  convert(varchar, serverproperty('ProductVersion'))
	select @subVer = substring(@SQLVersion, 6, 20)


	select @subVer = substring(@SQLVersion, 6, 20)
	if Left(@subVer, 1) = '.'
	begin
		select @subVer = substring(@subVer, 2, 20)
	end

	-- now see if we can convert to a number
	if isnumeric(@subVer) = 1
	begin
		select @iver = convert(float, @subVer)
	end
	
	if (left(@SQLVersion, 4) = '10.5' and @iver <= 2500.0) or left(@SQLVersion, 4) = '10.0' -- 2008 and R2 have difference in DMV...
	begin	
		-- for anything 10.50.2500.0 or lower, just check the @@version string
		declare @VersionString nvarchar(max)
		select @VersionString = @@version

		--select @VersionString

		if charindex('Hypervisor', @VersionString) > 0
			insert #SSL_KVP select 'VirtualisationType', 'HyperVisor';  -- defaults to nothing
		else
			insert #SSL_KVP select 'VirtualisationType', 'NONE';  -- defaults to nothing
	end
	else
	begin
		declare @Virtualisation int
		declare @vtype nvarchar(60)
		declare @VirtualisationType nvarchar(60)
		declare @Cmd nvarchar(max)

		set @Cmd = 'select @VirtualisationType = virtual_machine_type_desc from sys.dm_os_sys_info'

		exec sp_executesql @Cmd, N'@VirtualisationType nvarchar(60) output',  @VirtualisationType = @vtype output

		insert #SSL_KVP select 'VirtualisationType', case @vtype when 'NONE' then 'Not Virtualised' else @vtype end

	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
end	


-- Power settings

if upper ($(UsePowerShell)) = 'Y'
begin

	print 'Checking power settings...'

	if object_id('tempdb..#PowerSettings') is not null
		drop table #PowerSettings
	
	create table #PowerSettings 
	(
		Details varchar(200)
	)

	declare @PowerSettingsCmd nvarchar(1000)

	set @PowerSettingsCmd = 'powershell.exe -command "Get-WmiObject -Class win32_powerplan -Namespace root\cimv2\power -filter "isactive=''true''" | format-table -Property elementName -autosize'

	insert into #PowerSettings exec xp_cmdshell @PowerSettingsCmd

	if exists 
		(select * from #PowerSettings where Details like '%Access%denied%')
		or exists (select * from #PowerSettings where Details like 'Get-WmiObject : %')
	begin
		insert #Problems select top 1 'PowerSetting', 'There was a problem getting the power settings for this server using powershell.  The error is :' + Details from #PowerSettings
		insert #SSL_KVP select top 1 'PowerSetting', '!Not Collected!'
	end
	else
	begin
		delete from #PowerSettings where Details is null or Details like '-----%' or Details like 'elementName%'
		if not exists(select top 1 'PowerSetting', Details from #PowerSettings)
		begin
			insert #Problems select 'PowerSetting', 'Could not get the Power Settings'
			insert #SSL_KVP select top 1 'PowerSetting', '!Not Collected!'
		end
		else
			insert #SSL_KVP select top 1 'PowerSetting', Details from #PowerSettings
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

--------------------------------------------------------------------------------
-- Hardware and Operating System: Paths and Installation Directories
--------------------------------------------------------------------------------
begin 

	print 'Getting Hardware and Operating System: Paths and Directories...'
	
	declare @sqlPath 		varchar(8000),
		@sqlFolder		varchar(8000),
		@sqlString		nvarchar(4000);

	select @sqlString = N'SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL\';
	execute master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', @sqlString, @@servicename, @param = @sqlFolder output;

	-- SQL Server Path	
	select	@sqlString = N'SOFTWARE\Microsoft\Microsoft SQL Server\' + @sqlFolder + '\Setup\';
	select	@sqlPath = 'Can not LOCATE REGISTRY KEY';
	execute master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', @sqlString, N'SQLPath', @param = @sqlPath output;

	insert #SSL_KVP select 'SQL Server Installation Directory', @sqlPath;

	-- Windows Path	
	select @sqlString = N'SOFTWARE\Microsoft\Windows NT\CurrentVersion\';
	select	@sqlPath = 'Can not LOCATE REGISTRY KEY';
	execute master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', @sqlString, N'PathName', @param = @sqlPath output;
	insert #SSL_KVP select 'Windows Installation Directory', @sqlPath;

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end;

--------------------------------------------------------------------------------
-- Server Particulars
--------------------------------------------------------------------------------
begin

	print 'Getting Hardware and Operating System: Server Type...'
	
	declare @CpuSpeed	integer,
		@BiosDate	varchar(25);


	create table #SSL_MSVer
	(
		[Index]		int		not null,
		[Name] 		varchar(255)	not null,
		InternalValue	varchar(255)	null,
		CharacterValue	varchar(255)	null
	);
	

	insert into #SSL_MSVer execute master.dbo.xp_msver;
	
	-- ok, now the KVPs from the msver data
	insert #SSL_KVP select 'PhysicalRAM', InternalValue from #SSL_MSVer (nolock) where [Name] = 'PhysicalMemory';
	insert #SSL_KVP select 'NumProcs', InternalValue from #SSL_MSVer (nolock) where [Name] = 'ProcessorCount';

	execute  master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', N'HARDWARE\DESCRIPTION\System', N'SystemBiosDate', @BiosDate output;
	insert #SSL_KVP select 'Bios Date', @BiosDate;

	-- sometimes the bios date is not there, so check in another known locatin:
	if @BiosDate is null
		execute  master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', N'HARDWARE\DESCRIPTION\System\BIOS', N'BiosReleaseDate', @BiosDate output;

	execute  master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', N'HARDWARE\DESCRIPTION\System\CentralProcessor\0\', N'~MHz', @param = @CpuSpeed output;
	insert #SSL_KVP select 'ProcSpeed', @CpuSpeed;

	
	
	--insert #SSL_KVP select 'Windows Version', CharacterValue from #SSL_MSVer (nolock) where [Name] = 'WindowsVersion'
	declare @PowerShellCmd varchar(1000)
	declare @PowerShellResult table
	(
		resultstring varchar(1000)
	)
	set @PowerShellCmd = '@PowerShell -noprofile -command "(Get-WmiObject win32_operatingsystem).version"'
	insert into @PowerShellResult execute master..xp_cmdshell @PowerShellCmd
	
	if exists (select * from @PowerShellResult where resultstring like '%Access is denied%')
	begin
		insert into #Problems select top 1 'Windows Version', 'There was a problem getting the power settings for this server using powershell.  The error is :' + resultstring from @PowerShellResult
		insert #SSL_KVP select top 1 'Windows Version', '!Not Collected!'
	end
	--else
	--begin
	--	insert #SSL_KVP select 'Windows Version',stuff(resultstring, 4, 1, ' (') + ')'  from @PowerShellResult where resultstring is not null


	-- handle the change from 2016 where the build format is no longer x.y.1234, it is now xx.y.1234
	if exists (select * from @PowerShellResult where substring(resultstring, 2,1) = '.')
		insert #SSL_KVP select 'Windows Version',stuff(resultstring, 4, 1, ' (') + ')'  from @PowerShellResult where resultstring is not null
	else
		insert #SSL_KVP select 'Windows Version',stuff(resultstring, 5, 1, ' (') + ')'  from @PowerShellResult where resultstring is not null
	
	declare @ProcNameString    varchar(255);
	execute  master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', N'HARDWARE\DESCRIPTION\System\CentralProcessor\0\', N'ProcessorNameString', @param = @ProcNameString output;
		insert #SSL_KVP select 'Processor Type', @ProcNameString;


	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end
GO

--------------------------------------------------------------------------------
-- Hardware and Operating System: Disk Space
--------------------------------------------------------------------------------
begin
	print 'Gathering Disk information...'

	if object_id('tempdb..#SSL_DiskDrives') is not null
		drop table #SSL_DiskDrives


	create table #SSL_DiskDrives 
	(
		RecordID		int	identity(1,1),
		Drive			varchar(5)	not null,
		TotalSpaceMB	bigint,
		FreeSpaceMB		bigint,
		FileSystem			varchar(255)
	);


	-- Once we have the basic disk info, get PS to go and find the volume types
	-- and then we can outer join 
	declare @PowerShellResult table
	(
		ResultLine varchar(255)
	)

	declare @RawVolumes table
	(
		VolumeInfo xml
	)

	declare @Volumes table
	(
		Volume varchar(255)
		,FileSystem varchar(15)
		,Capacity varchar(18)
		,FreeSpace varchar(18)
	)


	declare @PowerShellCmd varchar(255)
			, @XmlText varchar(max)

	set @PowerShellCmd = '@PowerShell -noprofile -command "get-WMIObject Win32_Volume | Select @{Name=''DriveLetter''; E={$_.DriveLetter}}, @{Name=''FileSystem''; E={$_.FileSystem}}, @{Name=''Capacity''; E={$_.Capacity}},  @{Name=''FreeSpace''; E={$_.FreeSpace}} | ConvertTo-XML -As String"'

	insert into @PowerShellResult execute master..xp_cmdshell @PowerShellCmd
	
	select @XmlText = ''
	select @XmlText = @XmlText + ltrim(rtrim(ResultLine)) from @PowerShellResult where left(ltrim(rtrim(ResultLine)), 1) = '<'
	select @XmlText = replace(@XmlText, '&#x0;', '')

	insert into @RawVolumes
	select cast(@XmlText as xml);

	insert into @Volumes
	select
		m.c.value('(Property[@Name="DriveLetter"]/text())[1]', 'varchar(255)'),
		m.c.value('(Property[@Name="FileSystem"]/text())[1]', 'varchar(15)'),
		m.c.value('(Property[@Name="Capacity"]/text())[1]', 'varchar(18)'),
		m.c.value('(Property[@Name="FreeSpace"]/text())[1]', 'varchar(18)')
	from 
		@RawVolumes as v
		outer apply v.VolumeInfo.nodes('Objects/Object') as m(c)
		

	insert into #SSL_DiskDrives
	select 
		v.Volume Drive
		,convert(bigint, v.Capacity) / 1024 /1024 TotalSpaceMB
		,convert(bigint, v.FreeSpace) / 1024 / 1024 FreeSpaceMB
		,v.FileSystem 
	from 
		@Volumes v
	where 
		Volume is not null
		and v.FileSystem <> 'CDFS'


	-- now denormalise
	insert #SSL_Message select 3, RecordID, 1, Drive from #SSL_DiskDrives;
	insert #SSL_Message select 3, RecordID, 2, TotalSpaceMB from #SSL_DiskDrives;
	insert #SSL_Message select 3, RecordID, 3, FreeSpaceMB from #SSL_DiskDrives;
	insert #SSL_Message select 3, RecordID, 4, isnull(FileSystem, '!Not Collected!') from #SSL_DiskDrives;

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

-- is the server clustered?
insert #SSL_KVP select 'IsClustered', convert(varchar(10),ServerProperty('IsClustered'));
if ServerProperty('IsClustered') = 1
begin
	print 'Getting Shared Cluster Drives and Nodes'

	declare @Clusternodes table
	(
		RecordID int identity(1,1)
		,NodeName sysname
		,NodeStatus varchar(30)
	)


	insert #SSL_Svr select 10, DriveName from sys.dm_io_cluster_shared_drives;
	--insert #SSL_Svr select 11, NodeName from sys.dm_os_cluster_nodes;

	;with ClusterActiveNode as 
	(
		select serverproperty('ComputerNamePhysicalNetBIOS') as NodeName
		, cast('Active' as varchar(10)) as Active
	),

	ClusterNodes as 
	(
		select NodeName from sys.dm_os_cluster_nodes
	)

	insert into @Clusternodes 
	select 
		b.NodeName as NodeName
		, isnull(Active,'Passive') as NodeStatus 
	from 
		ClusterNodes b 
		left join ClusterActiveNode a on a.NodeName = b.NodeName

	if @@rowcount <> 0
	begin
		insert #SSL_Message select 11, RecordID, 1, NodeName from @Clusternodes;
		insert #SSL_Message select 11, RecordID, 2, NodeStatus from @Clusternodes;
	end


	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
end




--------------------------------------------------------------------------------
-- Hardware and Operating Systems: Logins and Domains
--------------------------------------------------------------------------------
begin

	print 'Checking Login Auditing (audit level) and Authentication Mode (login mode)...'
	
	create table #SSL_LoginConfig
	(
		[Name]		varchar(100) not null,
		ConfigValue	varchar(100) null
	);

	insert #SSL_LoginConfig exec master.dbo.xp_loginconfig;

	insert #SSL_KVP select 'LoginAuditing', ConfigValue from #SSL_LoginConfig where [Name] = 'audit level';
	insert #SSL_KVP select 'AuthenticationMode', ConfigValue from #SSL_LoginConfig where [Name] = 'login mode';

	drop table #SSL_LoginConfig;

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

--------------------------------------------------------------------------------
-- SQL Configuration: SQL Server Edition and Version
--------------------------------------------------------------------------------
begin

	print 'Getting SQL Server Edition and Version...'

	declare @versionDetails varchar(255)
	select @versionDetails = @@version

	insert #SSL_KVP select 'SqlAtAtVersion', replace(replace(@versionDetails, char(13), ''), char(10), '');
	insert #SSL_KVP select 'SqlProductVersion', convert(nvarchar(4000), ServerProperty('ProductVersion'));
	insert #SSL_KVP select 'SqlEdition', convert(nvarchar(4000), ServerProperty('Edition'));
	insert #SSL_KVP select 'SqlEngineEdition', convert(nvarchar(4000), ServerProperty('EngineEdition'));
	insert #SSL_KVP select 'SqlSPLevel', convert(nvarchar(4000), ServerProperty('ProductLevel'));

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


--------------------------------------------------------------------------------
-- SQL Configuration: SQL Server Configuration
--------------------------------------------------------------------------------
begin
	set nocount on

	print 'Getting SQL Configuration...'

	declare @MajorVersion tinyint
	declare @SSISCmd nvarchar(max)
	declare @RowCountSysPackages int 
	declare @RowCountSSISDB int 

	set @MajorVersion = left(cast(serverproperty('productversion') as nvarchar(max)),charindex('.',cast(serverproperty('productversion') as nvarchar(max)))-1) 

	insert #SSL_Message select 14, RecordID, 1, [Name] from #SSL_Configuration;
	insert #SSL_Message select 14, RecordID, 2, ConfigValue from #SSL_Configuration;
	insert #SSL_Message select 14, RecordID, 3, RunValue from #SSL_Configuration;

	if (select RunValue from #SSL_Configuration where [Name] = 'min server memory (MB)') <>
		(select RunValue from #SSL_Configuration where [Name] = 'max server memory (MB)')
	begin
		insert #SSL_KVP select 'DynamicMemory', '1';
	end
	else
	begin
		insert #SSL_KVP select 'DynamicMemory', '0';
	end 

	
	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)	
	print 'Getting User Connections and SQL Licencing...'

	insert #SSL_KVP select 'SqlLicenceType', convert(varchar, ServerProperty('LicenseType'));
	insert #SSL_KVP select 'CurrentActiveConnections', count(*) from master.dbo.sysprocesses;

	-- specific for Web SOAP Integration
	--if not exists (select RunValue from #SSL_Configuration where [Name] = 'Web Assistant Procedures')
	--begin
	--	insert into #Problems select 'WebSOAPIntegration', 'Could not get Web Soap Integration Setting'
	--	insert #SSL_KVP select 'WebSOAPIntegration', '!Not Collected!'
	--end
	--else
	--	insert #SSL_KVP select 'WebSOAPIntegration', RunValue from #SSL_Configuration where [Name] = 'Web Assistant Procedures';

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

	-- check whether the resource databases are in the same location as master
	-- can cause SP install problems when in different paths
	declare @path varchar(1000), @exists int;
	select @path = physical_name from master.sys.database_files where file_id = 1;
	select @path = left(@path, len(@path) - charindex('\', reverse(@path)) + 1) where charindex('\', @path) > 0;
	select @path = @path + 'mssqlsystemresource.mdf';
	
	exec master.dbo.xp_fileexist @path, @exists output;

	insert #SSL_KVP select 'ResourceDBInMasterLocation', @exists;
	
	-- Check where (if any) SSIS packages are stored.  Possible locations are:

	--2008 / 2008 R2 - msdb.dbo.sysssispackages 
	--2012 (package deployment model) - msdb.dbo.sysssispackages
	--2012 (project deployment model) - ssisdb.catalog.packages
	--2014 (package deployment model) - msdb.dbo.sysssispackages
	--2014 (project deployment model) - ssisdb.catalog.packages
	--2016 (package deployment model) - msdb.dbo.sysssispackages
	--2016 (project deployment model) - ssisdb.catalog.packages

	-- So we can check all version first by looking in msdb.dbo.sysssispackages
	set @SSISCmd = N'select @RowCountSysPackages = count(*) from msdb.dbo.sysssispackages' 
	exec sp_executesql @SSISCmd, N'@RowCountSysPackages int output', @RowCountSysPackages output
	insert #SSL_KVP select 'SSISMSDBPackages', case when @RowCountSysPackages = 0 then 0 else 1 end;

	-- and if the are 2012+, also check ssisdb.catalog.packages, PROVIDED that SSIS is installed, otherwise this code will error
	if @MajorVersion >= 11 and exists (select * from sys.databases where name = 'SSISDB')
	begin
		set @SSISCmd = 'select @RowCountSSISDB = count(*)
					from   ssisdb.catalog.folders  f
					inner join ssisdb.catalog.projects pr on pr.folder_id = f.folder_id
					inner join ssisdb.catalog.packages pa on pa.project_id = pr.project_id'

		exec sp_executesql @SSISCmd, N'@RowCountSSISDB int output', @RowCountSSISDB output
		insert #SSL_KVP select 'SSIS_DB_Packages', case when @RowCountSSISDB = 0 then 0 else 1 end;
	end
	else
		insert #SSL_KVP select 'SSIS_DB_Packages', 0;

end


--------------------------------------------------------------------------------
-- SQL Configuration: SQL Server Mail
--------------------------------------------------------------------------------
begin

	print 'Getting SQL Server Mail details'

	declare	@error integer;

	-- check to see if sql mail xps are enabled, before running the testing sprocs
	if (select RunValue from #SSL_Configuration where [Name] = 'SQL Mail XPs') = 1
	begin
		insert #SSL_KVP select 'SQLMailEnabled', 1;

		execute @error = master.dbo.xp_sendmail 
				@recipients = 'dba@sqlservices.com', 
				@message = 'Testing SQL Server Mail for SQL Server Health Check. Please ignore this e-mail.',
				@subject = 'SQL Server Health Check - Please Ignore.';
		if (@@error <> 0 or @error <> 0)
		begin
			insert #SSL_KVP select 'SQLMailConfigured', 0;
		end
		else
		begin
			insert #SSL_KVP select 'SQLMailConfigured', 1;
		end
	end
	else
	begin
		insert #SSL_KVP select 'SQLMailEnabled', 0;
		insert #SSL_KVP select 'SQLMailConfigured', 0;
	end
	

	-- check Database Mail
	if (select RunValue from #SSL_Configuration where [Name] = 'Database Mail XPs') = 1
	begin
		insert #SSL_KVP select 'DBMailEnabled', 1;	

		-- now check the configuration
		create table #SSL_DBMailStatus
		(
			DBStatus	varchar(100)	not null
		);

		insert into #SSL_DBMailStatus execute msdb.dbo.sysmail_help_status_sp;

		if (select top 1 lower(DBStatus) from #SSL_DBMailStatus) = 'started'
		begin
			insert #SSL_KVP select 'DBMailConfigured', 1;	
		end
		else
		begin
			insert #SSL_KVP select 'DBMailConfigured', 0;
		end

	end
	else
	begin
		insert #SSL_KVP select 'DBMailEnabled', 0;
		insert #SSL_KVP select 'DBMailConfigured', 0;
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end
go


begin

	print 'Checking sa set and blank passwords'

	-- check the SA account
	insert #SSL_KVP select 'SAPasswordSet', case when pwdcompare('', password) = 1 then 0 else 1 end from master.sys.syslogins where [name] = 'sa';
	insert #SSL_KVP select 'SADefaultDB', dbname from master.sys.syslogins where [name] = 'sa';

	declare @SQLLoginCount int
	select @SQLLoginCount = count(*) from sys.sql_logins

	-- Status of the password policy - how many and whats enabled?	
	insert #SSL_KVP 
	select 
		'PwdPolicyEnabled', 
		case 
			when count(*) =  @SQLLoginCount then 'All' 
			else 
				case when @SQLLoginCount > 0 then 'Some' 
					else 'None' 
			end 
		end 
	from 
		sys.sql_logins
	where
		is_policy_checked = 0
		and name not in ('##MS_PolicySigningCertificate##','##MS_SmoExtendedSigningCertificate##')


	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


--------------------------------------------------------------------------------
-- SQL Configuration: SQL Server Data Replication
--------------------------------------------------------------------------------
begin

	print 'Checking SQL Server Data Replication...'

	insert #SSL_KVP select 'ReplicationPublishers', case when count(*) > 0 then 1 else 0 end 
		from master.sys.databases 
		where is_published = 1 or is_merge_published = 1;


	insert #SSL_KVP select 'ReplicationSubscribers', case when count(*) > 0 then 1 else 0 end 
		from master.sys.databases 
		where is_subscribed = 1;


	insert #SSL_KVP select 'ReplicationDistributors', case when count(*) > 0 then 1 else 0 end 
		from master.sys.databases 
		where is_distributor = 1;

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


begin

	print 'Getting Features of SQL Running...'



	create table #SSL_NetStart
	(
		OutputColumn	sysname	null
	);

	-- now capture the results
	insert #SSL_NetStart exec master..xp_cmdshell 'net start';


	-- is the SQL Browser Service Enabled?
	insert #SSL_KVP select 'SQLBrowserEnabled', case when count(*) > 0 then 1 else 0 end 
		from #SSL_NetStart where OutputColumn = '   SQL Server Browser';

	-- are SQL Server Integration Services running?
	insert #SSL_KVP select 'SSISEnabled', case when count(*) > 0 then 1 else 0 end 
		from #SSL_NetStart where OutputColumn = '   SQL Server Integration Services';

	-- are SQL Server Reporting Services running for this instance?
	insert #SSL_KVP select 'SSRSEnabled', case when count(*) > 0 then 1 else 0 end 
		from #SSL_NetStart where lower(OutputColumn) = '   sql server reporting services (' + lower(@@servicename) + ')';
	

	-- now, the information from  systeminfo
	print 'Server Make and Model, OS, Architecture & Domain...'

	create table #SSL_SystemInfo
	(
		data	varchar(1000)	null
	);

	-- now capture the results
	insert #SSL_SystemInfo exec master..xp_cmdshell 'systeminfo /fo list';
	
	-- "System Manufacturer" (ie. Compaq)
	-- If this is a Virtual Machine, this will be Microsoft, or VM Ware Inc.
	if not exists (select * from #SSL_SystemInfo where data like 'System Manufacturer:%')
		begin
			insert #SSL_KVP select 'ServerMake', '!Not Collected!'
			insert into #Problems select 'Server Make', 'Unable to get Server Make'
		end
	else
		insert #SSL_KVP select 'ServerMake', isnull(ltrim(substring(data, 25, 1000)), '!Not Collected!') from #SSL_SystemInfo where data like 'System Manufacturer:%'

	-- "System Model" (ie. ProLiant ML350G)
	-- or Virtual Machine if this is a virtual
	if not exists (select * from #SSL_SystemInfo where data like 'System Model:%')
		begin
			insert #SSL_KVP select 'ServerModel', '!Not Collected!'
			insert into #Problems select 'Server Model', 'Unable to get Server Model'
		end
	else
		insert #SSL_KVP select 'ServerModel', ltrim(substring(data, 25, 1000)) from #SSL_SystemInfo where data like 'System Model:%';


	-- "OS Name" (ie. Microsoft Windows Server 2003, Standard Edition)
	if not exists (select * from #SSL_SystemInfo where data like 'OS Name:%')
	begin
		insert #SSL_KVP select 'OS', '!Not Collected!'
		insert into #Problems select 'OS Name', 'Unable to get OS Name'
	end
		insert #SSL_KVP select 'OS', ltrim(substring(data, 25, 1000)) from #SSL_SystemInfo where data like 'OS Name:%';
	
	-- "Version" (ie. 5.2.3790 Service Pack 2)
	-- In this case, just enter the Service Pack 2 component
	if not exists (select * from #SSL_SystemInfo where data like 'OS Version:%')
	begin
		insert #SSL_KVP select 'OSSPLevel', '!Not Collected!'
		insert into #Problems select 'OS Service Pack Level', 'Unable to get OS Service Pack'
	end
	else
		insert #SSL_KVP select 'OSSPLevel', ltrim(substring(data, 25, 1000)) from #SSL_SystemInfo where data like 'OS Version:%';


	-- "System Type" (ie. X86-based PC)
	if not exists (select * from #SSL_SystemInfo where data like 'System Type:%')
	begin
		insert #SSL_KVP select 'OSArchitecture', '!Not Collected!'
		insert into #Problems select 'OS Architecture', 'Unable to get OS Architecture'	
	end
	else
		insert #SSL_KVP select 'OSArchitecture', ltrim(substring(data, 25, 1000)) from #SSL_SystemInfo where data like 'System Type:%';

	-- Server Role
	if not exists (select * from #SSL_SystemInfo where data like 'OS Configuration:%')
	begin
		insert #SSL_KVP select 'OSConfiguration', '!Not Collected!'
		insert into #Problems select 'OS Configuration', 'Unable to get OS Configuration'	
	end
	else
		insert #SSL_KVP select 'OSConfiguration', ltrim(substring(data, 25, 1000)) from #SSL_SystemInfo where data like 'OS Configuration:%';


	-- Domain
	if not exists (select * from #SSL_SystemInfo where data like 'Domain:%')
	begin
		insert #SSL_KVP select 'Domain', '!Not Collected!'
		insert into #Problems select 'Domain', 'Unable to get Domain'	
	end
	else
		insert #SSL_KVP select 'Domain', ltrim(substring(data, 25, 1000)) from #SSL_SystemInfo where data like 'Domain:%';
	-- and disable again, if we changed

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Getting Health Check Header data...'

begin	
	-- okay, this is a Type 1 Message - sets up the health check
	insert #SSL_Message select 1, 1, 2, convert(sysname, host_name()); 
	insert #SSL_Message select 1, 1, 3, convert(varchar(128), $(CustName)); 
	insert #SSL_Message select 1, 1, 4, convert(sysname, serverproperty('servername')); 
	insert #SSL_Message select 1, 1, 5, convert(sysname, @@servicename); 
	insert #SSL_Message select 1, 1, 6, convert(sysname, user_name());
	insert #SSL_Message select 1, 1, 7, convert(sysname, @@spid); 
	insert #SSL_Message select 1, 1, 8, convert(varchar(30), getdate(), 120); 

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


begin

	print 'Starting Database Files Section...'

	-- okay, get a temp table of the Databases, with their Files
	select	
		identity(int, 1, 1) as RecordID,
		db.name as [Name],
		mf.[file_id] as [FileID],
		mf.type as [FileType],
		mf.size as [FileSizePages],
		mf.data_space_id as GroupID,
		mf.physical_name as [FileName],
		mf.max_size as [MaxSize],
		mf.growth as [Growth]
	into
		#SSL_DatabaseFiles 
	from 
		sys.databases db
		inner join master.sys.master_files mf on db.database_id = mf.database_id
	order by
		db.name,
		mf.[file_id];

	
	-- now insert into message structure
	insert #SSL_Message select 8, RecordID, 1, [Name] from #SSL_DatabaseFiles; 
	insert #SSL_Message select 8, RecordID, 2, convert(varchar, FileID) from #SSL_DatabaseFiles;
	insert #SSL_Message select 8, RecordID, 3, convert(varchar, FileType) from #SSL_DatabaseFiles;
	insert #SSL_Message select 8, RecordID, 4, convert(varchar, FileSizePages) from #SSL_DatabaseFiles;
	insert #SSL_Message select 8, RecordID, 5, convert(varchar, GroupID) from #SSL_DatabaseFiles;
	insert #SSL_Message select 8, RecordID, 6, convert(varchar, [MaxSize]) from #SSL_DatabaseFiles;
	insert #SSL_Message select 8, RecordID, 7, convert(nvarchar(4000), [FileName]) from #SSL_DatabaseFiles;
	insert #SSL_Message select 8, RecordID, 8, convert(varchar, [Growth]) from #SSL_DatabaseFiles;

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

--------------------------------------------------------------------------------
-- Hardware and Operating System: User Database Backup Location
--------------------------------------------------------------------------------
begin

	print 'Looking at Historical Backup Location...'

	select
		identity(int, 1, 1) as RecordID,
		DatabaseName,
		BackupType,
		LastBackupPath,
		LastBackup,			
		convert(decimal(18,1), BackupSizeMB) as BackupSizeMB,
		convert(decimal(18,1), CompressedBackupSizeMB) as CompressedBackupSizeMB
	into
		#SSL_LastBackups
	from
		(select distinct
			case bs.type 
				when 'D' then 'Database'
				when 'L' then 'Log'
				when 'I' then 'Database Diff'
				when 'F' then 'File/Filegroup'
				when 'G' then 'File Diff'
				when 'P' then 'Partial'
				when 'Q' then 'Partial Diff'
				else '*** NO BACKUP ***'
			end as BackupType,
			s.name as DatabaseName, 
			isnull(bf.physical_device_name, '*** NO BACKUP ***') AS LastBackupPath, 
			isnull(isnull(convert(varchar(25), bs.backup_finish_date, 121), convert(varchar(25), bs.backup_start_date, 121)), '*** NO BACKUP ***') as LastBackup
			,(bs.backup_size / 1024.0 / 1024.0) as BackupSizeMB
			,(bs.compressed_backup_size / 1024.0 / 1024.0) as CompressedBackupSizeMB
		from
			sys.databases s
			left join msdb.dbo.backupset bs on bs.database_name = s.name
			left join msdb.dbo.backupmediaset ms on bs.media_set_id = ms.media_set_id
			left join msdb.dbo.backupmediafamily bf on ms.media_set_id = bf.media_set_id
		where
			bs.type in ('D', 'I', 'F', 'G', 'P', 'Q', 'L')
			and backup_set_id = (
				select	max(backup_set_id)
				from	msdb.dbo.backupset
				where	[type] = bs.type	
					and database_name = bs.database_name)
		) results;


	-- and denormalise
	insert #SSL_Message select 9, RecordID, 1, DatabaseName from #SSL_LastBackups;
	insert #SSL_Message select 9, RecordID, 2, BackupType from #SSL_LastBackups;
	insert #SSL_Message select 9, RecordID, 3, LastBackupPath from #SSL_LastBackups;
	insert #SSL_Message select 9, RecordID, 4, convert(varchar(30), LastBackup, 120) from #SSL_LastBackups
	insert #SSL_Message select 9, RecordID, 5, BackupSizeMB from #SSL_LastBackups
	insert #SSL_Message select 9, RecordID, 6, CompressedBackupSizeMB from #SSL_LastBackups

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


--------------------------------------------------------------------------------
-- SQL Configuration: SQL Server Startup Paramaters and Active Trace Flags
--------------------------------------------------------------------------------
begin
	set nocount on

	print 'Assessing SQL Server Startup Parameters and Trace Flags...'

	declare @sqlFolder	varchar(8000),
		@sqlString	nvarchar(4000),
		@count 		int,
		@value 		varchar(10),
		@regKey		nvarchar(3000),
		@error		int;


	create table #SSL_StartUpParameters
	(
		[Value]			varchar(10),
		ParameterValue 		varchar(500)
	);
	
	select @sqlString = N'SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL\';
	execute master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', @sqlString, @@SERVICENAME, @param = @sqlFolder output;
	
	select	@regKey = N'SOFTWARE\Microsoft\Microsoft SQL Server\'  + @sqlFolder + '\MSSQLServer\Parameters\';
	select	@count = 0;
	while (@count < 100)
	begin
		select	@value = 'SQLArg' + convert(varchar(3), @count);
		
		insert into #SSL_StartUpParameters
			exec @error = master.dbo.xp_regread @rootkey = 'HKEY_LOCAL_MACHINE', @key = @regKey, @value_name = @value;

		if (@@error <> 0 or @@rowcount = 0 or @error <> 0) select @count = 99;
		
		select	@count = @count + 1;
	end

	-- now insert into Svr
	insert #SSL_Svr select 12, ParameterValue from #SSL_StartUpParameters;

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
	
end
go



--------------------------------------------------------------------------------
-- SQL Configuration: SQL Server Network Protocols
--------------------------------------------------------------------------------
begin
	set nocount on
	

	print 'Getting SQL Server Network Protocols...'

	declare @sqlFolder	varchar(8000),
		@sqlString	nvarchar(4000),
		@value		varchar(4000),
		@iValue		int,
		@message	varchar(20);

	select @sqlString = N'SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL\';
	execute master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', @sqlString, @@servicename, @param = @sqlFolder output;

	select @sqlString = N'SOFTWARE\Microsoft\Microsoft SQL Server\' + @sqlFolder + '\MSSQLServer\SuperSocketNetLib\Sm';
	select @iValue = 0;

	-- and denormalise Shared Memory settings
	exec master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', @sqlString, N'Enabled', @param = @iValue output;
	if (@@rowcount = 0)
		select @message = 'Unavailable';
	else
	begin
		select @message = 'Enabled';
		if @iValue = 0 select @message = 'Disabled';	
	end


	-- okay, shared memory settings
	insert #SSL_Message select 13, 1, 1, 'Shared Memory';
	insert #SSL_Message select 13, 1, 2, @message;
	insert #SSL_Message select 13, 1, 3, 'None';


	-- now, named pipes
	select 
		@sqlString = N'SOFTWARE\Microsoft\Microsoft SQL Server\' + @sqlFolder + '\MSSQLServer\SuperSocketNetLib\Np',
		@iValue = 0;
	exec master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', @sqlString, N'Enabled', @param = @iValue output;

	if (@@rowcount = 0)
		select @message = 'Unavailable';
	else
	begin
		select @message = 'Enabled';
		if @iValue = 0 select @message = 'Disabled';			
	end

	exec master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', @sqlString, N'PipeName', @param = @value output;

	-- denorm the named pipe values
	insert #SSL_Message select 13, 2, 1, 'Named Pipes';
	insert #SSL_Message select 13, 2, 2, @message;
	insert #SSL_Message select 13, 2, 3, @value;


	-- now, TCP/IP
	select 
		@sqlString = N'SOFTWARE\Microsoft\Microsoft SQL Server\' + @sqlFolder + '\MSSQLServer\SuperSocketNetLib\Tcp',
		@iValue = 0;
	exec master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', @sqlString, N'Enabled', @param = @iValue output;
	if (@@rowcount = 0)
		select @message = 'Unavailable';
	else
	begin
		select @message = 'Enabled';
		if @iValue = 0 select @message = 'Disabled';		
	end

	-- denorm out the first 2 parts, will build the 3rd part last
	insert #SSL_Message select 13, 3, 1, 'TCP/IP';
	insert #SSL_Message select 13, 3, 2, @message;
	
	select @sqlString = @sqlString + '\IP1';
	exec master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', @sqlString, N'IpAddress', @param = @value output;

	select @message='';
	exec master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', @sqlString, N'TcpPort', @param = @message output;
	select @value = @value + isnull(nullif(':' + isnull(@message, ''), ':'), '');
	insert #SSL_Message select 13, 3, 3, @value;
	
	
	-- remote Admin connection
	
	insert #SSL_Message select 13, 4, 1, 'Admin Dynamic Port';

	if exists (select * from sys.configurations where name = 'remote admin connections')
	begin	
		insert into #SSL_Message  select 13, 4, 2, case when value_in_use = 1 then 'Enabled' else 'Disabled' end from sys.configurations where name = 'remote admin connections'
		insert #SSL_Message select 13, 4, 3, convert(nvarchar, value_in_use) from sys.configurations where name = 'remote admin connections'
	end
	else
	begin
		insert into #SSL_Message  select 13, 4, 2, 'Disabled' 
		insert #SSL_Message select 13, 4, 3, 0
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)	

/*
	
	insert #SSL_Message select 13, 4, 1, 'Admin Dynamic Port';
	select 
		@sqlString = N'SOFTWARE\Microsoft\Microsoft SQL Server\' + @sqlFolder + '\MSSQLServer\SuperSocketNetLib\AdminConnection',
		@iValue = 0;
	exec master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', @sqlString, N'TcpDynamicPorts', @param = @iValue output;
	if (@@rowcount = 0)
		select @message = 'Unavailable';
	else
	begin
		select @message = 'Enabled';
		if @iValue = 0 select @message = 'Disabled';			
	end
	insert #SSL_Message select 13, 4, 2, @message;
	insert #SSL_Message select 13, 4, 3, convert(varchar, @iValue);
	
	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)	
*/
end
go



--------------------------------------------------------------------------------
-- SQL Server Endpoint information
--------------------------------------------------------------------------------
begin
	print 'Checking SQL Server Endpoint Information...'

	create table #SSL_Endpoint
	(
		RecordID	int		identity(1,1),
		EPName	varchar(100)	not null,
		EPStatus	varchar(100)	not null
	);


	-- and capture
	insert into #SSL_Endpoint select name, state_desc from sys.endpoints;


	-- now denormalise
	insert #SSL_Message select 25, RecordID, 1, EPName from #SSL_Endpoint;
	insert #SSL_Message select 25, RecordID, 2, EPStatus from #SSL_Endpoint;


	drop table #SSL_Endpoint;

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

--------------------------------------------------------------------------------
-- SQL Configuration: SQL Server Alerts
--------------------------------------------------------------------------------
begin
	print 'Elaborating SQL Server Alerts and triggers...'
	-- are any demo alerts enabled?
	insert #SSL_KVP	select 'DemoAlerts', case count(1) when 0 then 0 else 1 end from msdb.dbo.sysalerts (nolock) where [enabled] = 1 and [name] like 'Demo%';
	-- are any other alerts there?
	insert #SSL_KVP	select 'SqlAlerts', case count(1) when 0 then 0 else 1 end from msdb.dbo.sysalerts (nolock) where [enabled] = 1 and [name] not like 'Demo%';

	-- server DDL Triggers
	insert #SSL_KVP select 'ServerDDLTriggers', isnull(sum(1), 0) from master.sys.server_triggers;
	insert #SSL_KVP select 'ServerCLRTriggers', isnull(sum(1), 0) from master.sys.server_assembly_modules;
	insert #SSL_KVP select 'ServerScopedEventNotifications', isnull(sum(1), 0) from master.sys.server_event_notifications;

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
	
end



print 'Checking for blank passwords...'

begin
	-- okay, a list of the SQL logins with blank passwords
	create table #SSL_BlankPasswords
	(
		RecordID	int	identity(1,1),
		[Name]		sysname,
		[Level]		varchar(10)
	);

	-- okay, get the accounts with blank passwords
	insert #SSL_BlankPasswords
	(
		[Name],
		[Level]
	)
	select
		LoginName,
		case sysadmin
			when 1 then 'Admin'
			else 'User'
		end
	from
		master.sys.syslogins
	where
		isntname <> 1
		and isntgroup <> 1
		and isntuser <> 1
		and (pwdcompare('', password) = 1 or password is null)
		and [name] not in ('sa', '##MS_SQLResourceSigningCertificate##', 
					'##MS_SQLReplicationSigningCertificate##', 
					'##MS_SQLAuthenticatorCertificate##', 
					'##MS_AgentSigningCertificate##');

	if @@rowcount <> 0
	begin
		-- now denormalise out any results
		insert #SSL_Message select 17, RecordID, 1, [Name] from #SSL_BlankPasswords;
		insert #SSL_Message select 17, RecordID, 2, [Level] from #SSL_BlankPasswords;
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

	print 'Finding Server System Admin Role Members...'

	insert #SSL_Svr select 15, loginname from master.sys.syslogins where sysadmin = 1;

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

	print 'Assessing Security : Windows Members of the BUILTIN\Administrators Group...'
	
	if exists (select * from master.sys.syslogins where [name] = 'BUILTIN\Administrators')
	begin
		create table #SSL_BuiltInAdmin
		(
			AccountName	sysname,
			[Type]		varchar(20),
			Priviledge	varchar(20),
			MappedName	sysname,
			PermissionPath	sysname
		);

		insert #SSL_BuiltInAdmin exec master.dbo.xp_logininfo  'BUILTIN\Administrators', 'members';
			
		insert #SSL_Svr select 16, AccountName from #SSL_BuiltInAdmin;
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
end



--------------------------------------------------------------------------------
-- SQL Configuration: SQL Server Failed Jobs
--------------------------------------------------------------------------------
begin
	set nocount on


	print 'Getting SQL Server Failed Job info...'

	create table #SSL_FailedJobs
	(
		RecordID		int	identity(1,1),
		[JobName]		sysname,
		NumberOfFailures	int
	);

	-- get the failed job list for the past 30 days
	insert
		#SSL_FailedJobs
	(
		[JobName],
		NumberOfFailures
	)
	select	
		j.[name],
		count(*)
	from	
		msdb.dbo.sysjobs j (nolock)
		inner join msdb.dbo.sysjobhistory jh (nolock) on j.job_id = jh.job_id
	where
		jh.run_status = 0 -- failed
		and datediff(dd, convert(datetime, 
				convert(varchar, run_date), 112), getdate()) <= 30  -- within last 30 days
	group by
		j.[name];


	-- okay, insert the denormed version
	insert #SSL_Message select 4, RecordID, 1, [JobName] from #SSL_FailedJobs;
	insert #SSL_Message select 4, RecordID, 2, NumberOfFailures from #SSL_FailedJobs;

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
	
end



print 'Getting Databases and Properties Section....'

--------------------------------------------------------------------------------
-- Databases: 
--------------------------------------------------------------------------------
begin

	declare @db sysname
	declare @Cmd nvarchar(1000)
	
	
	declare @DBSizes table
	(
		DatabaseName sysname
		,DatabaseSizeMB varchar(1000)
	)

	
	
	while exists (select * from #DatabaseNames where Processed = 0)
	begin

		select top 1 @db = DatabaseName from #DatabaseNames where Processed = 0 order by DatabaseName 

		set @Cmd = 
		'	use [' + @db + ']; ' + 
		'	declare @dbsize bigint ' +
		'	declare @logsize bigint ' + 
		'	select 
			@dbsize = sum(convert(bigint,case when status & 64 = 0 then size else 0 end))
			,@logsize = sum(convert(bigint,case when status & 64 <> 0 then size else 0 end))
			from dbo.sysfiles;

			select db_name(), str((convert (dec (15,2),@dbsize) + convert (dec (15,2),@logsize)) * 8192 / 1048576,15,2) '
		
		insert into @DBSizes exec sp_executesql @Cmd

		update #DatabaseNames set Processed = 1 where DatabaseName = @db
	end


	-- okay, get the info we want
	select
		identity(int, 1, 1) as RecordID,
		d.name as [Name],
		isnull(convert(decimal(15,2), dbs.DatabaseSizeMB), 0) as DatabaseSizeMB,
		case when d.name in ('master', 'model', 'msdb', 'tempdb') or is_distributor = 1 then 'System' else 'User' end as DBType,
		suser_sname(d.owner_sid) as DatabaseOwner,
		recovery_model_desc as RecoveryModel,
		is_auto_close_on as IsAutoClose,
		is_auto_shrink_on as IsAutoShrink,
		is_auto_create_stats_on as IsAutoCreateStats,
		is_auto_update_stats_on as IsAutoUpdateStats,
		is_auto_update_stats_async_on as IsAutoUpdateStatsAsync,
		page_verify_option_desc as PageVerifyOption,
		collation_name as [CollationName],
		user_access_desc as RestrictedAccess,
		is_read_only as IsReadOnly,
		state_desc as DatabaseStatus,  -- online
		case state when 6 then 1 else 0 end as IsOffline, -- offline
		case state when 5 then 1 else 0 end as IsInEmergencyMode, -- emergency
		is_in_standby as IsInStandby,
		compatibility_level as CompatibilityLevel,
		snapshot_isolation_state as SnapshotIsolationState,
		is_read_committed_snapshot_on as IsReadCommittedSnapshot,
		is_parameterization_forced as IsParameterizationForced,
		is_trustworthy_on as IsTrustworthyOn,
		isnull(sl.sysadmin, 0) as IsDboSysAdmin,
		convert(float, 0) as PercentageOfDatafileSize,
		case when source_database_id is null then 0 else 1 end as IsDatabaseSnapshot,
		convert(bit, 0) as ArePartitions,
		is_broker_enabled as IsBrokerEnabled,
		is_fulltext_enabled as IsFulltextEnabled,
		is_master_key_encrypted_by_server as IsMasterKeyEncryptedByServer,
		case when lsp.primary_id is null then 0 else 1 end as IsLogShippedFrom,
		case when lss.secondary_id is null then 0 else 1 end as IsLogShippedTo,
		case when mirroring_guid is null then 0 else 1 end as IsDatabaseMirrored,
		isnull(mirroring_role_desc, '') as MirroringRole,
		isnull(mirroring_state_desc, '') as MirroringState,
		isnull(mirroring_partner_instance, '') as MirroringPartnerInstance,
		isnull(mirroring_safety_level_desc, '') as MirroringSafetyLevel,
		convert(float, -1) as DataSizeMB,
		convert(float, -1) as LogSizeMB,
		convert(varchar(2000), '') as FullStatus,
		is_published,
		is_subscribed,
		is_merge_published,
		is_distributor,
		d.owner_sid,
		is_encrypted
	into
		#SSL_Databases
	from
		sys.databases d
		left join sys.syslogins sl on d.owner_sid = sl.sid
		inner join sys.database_mirroring dm on d.database_id = dm.database_id
		left outer join msdb.dbo.log_shipping_primary_databases lsp on d.name = lsp.primary_database
		left outer join msdb.dbo.log_shipping_secondary_databases lss on d.name = lss.secondary_database
		left outer join @DBSizes dbs on dbs.DatabaseName = d.name


	;with fs
	as
	(
		select database_id, type, size * 8.0 / 1024 size
		from sys.master_files
	)
	select 
		name
		,(select sum(size) from fs where type = 0 and fs.database_id = db.database_id) DataSizeMB
		,(select sum(size) from fs where type = 1 and fs.database_id = db.database_id) LogSizeMB
	into
		#SSL_DBFileSizes
	from 
		sys.databases db


	-- and now update
	update
		d
	set
		DataSizeMB = dfs.DataSizeMB,
		LogSizeMB = dfs.LogSizeMB
	from
		#SSL_Databases d
		inner join #SSL_DBFileSizes dfs on d.Name = dfs.name;


	create table #SSL_sp_helpdb (
		DatabaseName	sysname,
		dbsize		varchar(100),
		dbowner		varchar(100),
		[dbid]		int,
		created		varchar(100),
		FullStatus	varchar(2000),
		comp_level	int
	);

	insert #SSL_sp_helpdb exec sp_helpdb;


	-- and now update
	update
		d
	set
		FullStatus = st.FullStatus
	from
		#SSL_Databases d
		inner join #SSL_sp_helpdb st on d.Name = st.DatabaseName;

	drop table #SSL_sp_helpdb;

	-- now calculate the Are Partitions and Percentage of Data File Sizes

	-- and write the message out - type 5
	insert #SSL_Message select 5, RecordID, 1, [Name] from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 2, isnull([DatabaseSizeMB],0) from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 3, DBType from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 4, isnull(DatabaseOwner,'n/a') from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 5, RecoveryModel from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 6, IsAutoClose from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 7, isnull(IsAutoShrink, 0) from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 8, IsAutoCreateStats from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 9, IsAutoUpdateStats from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 10, IsAutoUpdateStatsAsync from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 11, PageVerifyOption from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 12, [CollationName] from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 13, RestrictedAccess from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 14, IsReadOnly from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 15, DatabaseStatus from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 16, IsOffline from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 17, IsInEmergencyMode from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 18, IsInStandby from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 19, CompatibilityLevel from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 20, SnapshotIsolationState from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 21, IsReadCommittedSnapshot from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 22, IsParameterizationForced from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 23, IsTrustworthyOn from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 24, IsDboSysAdmin from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 25, PercentageOfDatafileSize from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 26, IsDatabaseSnapshot from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 27, ArePartitions from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 28, IsBrokerEnabled from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 29, IsFulltextEnabled from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 30, IsMasterKeyEncryptedByServer from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 31, IsLogShippedFrom from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 32, IsLogShippedTo from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 33, IsDatabaseMirrored from #SSL_Databases;	
	insert #SSL_Message select 5, RecordID, 34, MirroringRole from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 35, MirroringState from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 36, MirroringPartnerInstance from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 37, MirroringSafetyLevel from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 38, ltrim(str(DataSizeMB)) from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 39, ltrim(str(LogSizeMB)) from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 40, FullStatus from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 41, is_published from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 42, is_subscribed from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 43, is_merge_published from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 44, is_distributor from #SSL_Databases;
	insert #SSL_Message select 5, RecordID, 45, is_encrypted from #SSL_Databases;

	-- locations of Drives with Data Files on them
	insert #SSL_Svr select distinct 18, left(upper(physical_name), 2) from master.sys.master_files where type=0;
	-- locations of Drives with Log Files on them
	insert #SSL_Svr select distinct 19, left(upper(physical_name), 2) from master.sys.master_files where type=1;

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Getting Orphaned Database Users...'

begin

	-- okay, need to cursor through
	create table #SSL_OrphanedUsers
	(
		RecordID	int identity(1,1),
		DatabaseName	sysname,
		UserName	sysname,
		TypeDesc	varchar(20)
	);


	declare @databaseName sysname, @statement nvarchar(4000);
	declare cuDatabases cursor for 
		select name from master.sys.databases;

	open cuDatabases;
	fetch from cuDatabases into @databaseName;
	while @@fetch_status >= 0
	begin
		if has_dbaccess(@databaseName) = 1
		begin
			select @statement = 'insert #SSL_OrphanedUsers
				select ''' + @databaseName + ''', dp.name, dp.type_desc
					from ' + quotename(@databaseName, N'[') + '.sys.database_principals dp 
					left outer join master.sys.server_principals sp on dp.sid = sp.sid
					where sp.sid is null
					and dp.type in (''U'', ''S'')
					and dp.name <> ''guest''
					and dp.sid is not null';
			
			execute (@statement);

			-- does the guest account have access, while we're checking
			--if @databaseName not in ('master', 'tempdb')
			--begin

				select @statement = 'insert #SSL_Svr select 21, ''' + @databaseName + '''
							from ' + quotename(@databaseName, N'[') + '.sys.sysusers
							where name=''guest'' and hasdbaccess=1'; 
				
				execute(@statement);
			--end
			
		end
		fetch from cuDatabases into @databaseName;
	end
	close cuDatabases;
	deallocate cuDatabases;
	-- and denorm out
	insert #SSL_Message select 7, RecordID, 1, DatabaseName from #SSL_OrphanedUsers;
	insert #SSL_Message select 7, RecordID, 2, UserName from #SSL_OrphanedUsers;
	insert #SSL_Message select 7, RecordID, 3, TypeDesc from #SSL_OrphanedUsers;

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end
go




if upper($(GetEventLogs)) = 'Y' and upper($(UsePowerShell)) = 'Y'
begin
	print 'Checking Windows Application log for errors...'	
	-- Get errors from Windows Application event logs.
	declare @Cmd			varchar(1000)
	declare @XmlText		varchar(max)
	declare @currentLangauge nvarchar(128)

    declare @PowerShellResult table
    (
		ResultLine varchar(1000),
		Orderline int identity(1,1)
    )

	declare @RawErrors table
	(
		ErrorXML xml 
	)

	declare @Errors table
	(	
		ErrorDate	varchar(25)
		,ErrorText	varchar(2000)
	)

	declare @AggregatedErrors table
	(
		RecordID		int identity(1,1)
		,ErrorText		varchar(250)
		,MostRecentTime	datetime
		,ErrorCount		int
	)


	-- capture the current language
	select @currentLangauge = @@language

	set @Cmd =  '@PowerShell -noprofile -command "$time = [DateTime]::Now.AddDays(-' + convert(varchar,$(EventDaysToGet)) + '); Get-WinEvent -maxevents 250 -FilterHashtable @{logname=''Application''; level=2; starttime=$time }| Select @{Name=''timecreated''; E={$_.timecreated.ToString(''yyyy-MM-dd hh:mm:ss'')}}, @{Name=''Message''; E={$_.Message}}| ConvertTo-XML -As String'
	insert @PowerShellResult exec xp_cmdshell @Cmd

	set @XmlText = '';
    select @XmlText = coalesce(@XmlText + '', '' ) + ResultLine from @PowerShellResult where ResultLine is not null
	order by Orderline

	if left(@XmlText, 12) not like 'Get-WinEvent%' -- There are errors found
	begin

		begin try
			insert into @RawErrors
			select cast(@XmlText as xml);
		end try
		begin catch
			declare @ErrMsg varchar(2000)
			set @ErrMsg = ERROR_MESSAGE()
			insert #Problems select 'Windows Event Log', 'There was a problem reading the Windows Event Log on this server using powershell: ' + @ErrMsg  
		end catch

		insert into @Errors
		select distinct
			m.c.value('(Property[@Name="timecreated"]/text())[1]', 'varchar(25)'),
			left(m.c.value('(Property[@Name="Message"]/text())[1]', 'varchar(2000)'), 250)
		from 
			@RawErrors as re
			outer apply re.ErrorXML.nodes('Objects/Object') as m(c)
		where
			m.c.value('(Property[@Name="Message"]/text())[1]', 'varchar(2000)') is not null

		insert into @AggregatedErrors
		select top 10
			ErrorText 
			,max(ErrorDate) as MostRecentTime
			,count(ErrorText) as ErrorCount
		from 
			@Errors
		group by
			ErrorText
		order by
			count(ErrorText) desc

		insert into #SSL_Message select 30, RecordID, 1, ErrorText from @AggregatedErrors
		insert into #SSL_Message select 30, RecordID, 2, MostRecentTime from @AggregatedErrors
		insert into #SSL_Message select 30, RecordID, 3, ErrorCount from @AggregatedErrors
		insert into #SSL_Message select 30, RecordID, 4, 'Application' from @AggregatedErrors

	end
	else
	begin
		insert #Problems select top 1 'Windows Event Log', 'There was a problem reading the Windows Event Log on this server using powershell.  The error is :' + ErrorText from @Errors
	end
		
	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

	print 'Checking Windows System event log for errors...'	

	delete from @PowerShellResult
	delete from @RawErrors
	delete from @Errors
	delete from @AggregatedErrors

	set @Cmd =  '@PowerShell -noprofile -command "$time = [DateTime]::Now.AddDays(-' + convert(varchar,$(EventDaysToGet)) + '); Get-WinEvent -maxevents 250 -FilterHashtable @{logname=''System''; level=2; starttime=$time }| Select @{Name=''timecreated''; E={$_.timecreated.ToString(''yyyy-MM-dd hh:mm:ss'')}}, @{Name=''Message''; E={$_.Message}}| ConvertTo-XML -As String'
	insert @PowerShellResult exec xp_cmdshell @Cmd
	
	set @XmlText = '';
    select @XmlText = coalesce(@XmlText + '', '' ) + ResultLine from @PowerShellResult where ResultLine is not null
	order by Orderline

	if left(@XmlText, 12) not like 'Get-WinEvent%' -- There are errors found
	begin

		begin try
			insert into @RawErrors
			select cast(@XmlText as xml);
		end try
		begin catch
			declare @ErrMsg1 varchar(2000)
			set @ErrMsg1 = ERROR_MESSAGE()
			insert #Problems select 'System Event Log', 'There was a problem reading the System Event Log on this server using powershell: ' + @ErrMsg1  
		end catch

		insert into @Errors
		select distinct
			m.c.value('(Property[@Name="timecreated"]/text())[1]', 'varchar(22)'),
			left(m.c.value('(Property[@Name="Message"]/text())[1]', 'varchar(2000)'), 250)
		from 
			@RawErrors as re
			outer apply re.ErrorXML.nodes('Objects/Object') as m(c)
		where
			m.c.value('(Property[@Name="Message"]/text())[1]', 'varchar(1000)') is not null

		insert into @AggregatedErrors
		select top 10
			ErrorText 
			,max(ErrorDate) as MostRecentTime
			,count(ErrorText) as ErrorCount
		from 
			@Errors
		group by
			ErrorText
		order by
			count(ErrorText) desc

		insert into #SSL_Message select 30, RecordID, 1, ErrorText from @AggregatedErrors
		insert into #SSL_Message select 30, RecordID, 2, MostRecentTime from @AggregatedErrors
		insert into #SSL_Message select 30, RecordID, 3, ErrorCount from @AggregatedErrors
		insert into #SSL_Message select 30, RecordID, 4, 'System' from @AggregatedErrors

	end
	else
	begin
		insert #Problems select top 1 'System Event Log', 'There was a problem reading the System Event Log on this server using powershell.  The error is :' + ErrorText from @Errors
	end
		
	set language @currentLangauge

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

go


print 'Investigating Lock Pages in Memory...	'

begin

	declare @LockPagesEnabled bit 

	select 
		@LockPagesEnabled = case when omn.locked_page_allocations_kb > 0 then 1 else 0 end 
	from 
		sys.dm_os_memory_nodes omn
		inner join sys.dm_os_nodes osn on omn.memory_node_id = osn.memory_node_id
	where 
		osn.node_state_desc <> 'ONLINE DAC'

	insert #SSL_KVP select 'Lock Pages in Memory', @LockPagesEnabled
	--insert into #SSL_Message select 33, 1, 1, 'Lock Pages In Memory' 
	--insert into #SSL_Message select 33, 2, 2, @LockPagesEnabled

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

go

print 'Getting Service Accounts...'

begin

	-- get the service account information
	declare @SQLName varchar(255) 
	declare @FTKey nvarchar(255)
	declare @DBEngineLogin varchar(100)
	declare @AgentLogin varchar(100)
	declare @BrowserLogin varchar(100)
	declare @FDLauncherLogin varchar(100)
 	declare @IsNamedInstance bit

	set @IsNamedInstance = 0

	if (select charindex('\', convert(varchar, serverproperty('servername')))) > 1 -- if there is a \ in the servername it is a named instance
	begin
		set @SQLName = @@servicename
		set @IsNamedInstance = 1
	end
	else
		set @SQLName = convert(varchar, serverproperty('servername'))

	exec master.dbo.xp_instance_regread
				  @rootkey      = N'HKEY_LOCAL_MACHINE',
				  @key          = N'SYSTEM\CurrentControlSet\Services\MSSQLServer',
				  @value_name   = N'ObjectName',
				  @value        = @DBEngineLogin output
 
	exec master.dbo.xp_instance_regread
				  @rootkey      = N'HKEY_LOCAL_MACHINE',
				  @key          = N'SYSTEM\CurrentControlSet\Services\SQLServerAgent',
				  @value_name   = N'ObjectName',
				  @value        = @AgentLogin output


	exec master.dbo.xp_regread
				  @rootkey      = N'HKEY_LOCAL_MACHINE',
				  @key          = N'SYSTEM\CurrentControlSet\Services\SQLBrowser',
				  @value_name   = N'ObjectName',
				  @value        = @BrowserLogin output


	--select @DBEngineLogin as SQLServiceAccount, @AgentLogin as AgentAccount, @BrowserLogin as BrowserAccount, @FDLauncherLogin as FullTextAccount
	insert #SSL_KVP select 'SQL Server Service Account', @DBEngineLogin
	insert #SSL_KVP select 'SQL Agent Service Account', @AgentLogin
	insert #SSL_KVP select 'SQL Browser Account', @BrowserLogin

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

go


print 'checking if Browser Service is running...'
if upper ($(UsePowerShell)) = 'Y'
begin

	declare @BrowserDetails table
	(
		LogDetail nvarchar(200)
	) 
 
	declare @Cmd varchar(1000)
	declare @IsRunning bit
	set @Cmd = 'powershell.exe -c "Get-Service | Where-Object {$_.Name -eq ''SQLBrowser''}"'

	insert into @BrowserDetails exec  master..xp_cmdshell @Cmd
	
	-- if there is a problem, log this
	if exists (select * from @BrowserDetails where LogDetail like '%Get-Service%')
	begin
		insert #Problems 
			select distinct 'SQLBrowser Service', 'There was a problem checking if the SQL Browser Services is running using powershell.  The full error is: ' + 
													left(stuff((
													select 
														',' + b.LogDetail
													from 
														@BrowserDetails b
													where 
														b.LogDetail = LogDetail
													order by 
														b.LogDetail for xml path('')),1,1,''), 895) as ErrorString
													from @BrowserDetails
													group by LogDetail
	end
	else
	begin

		if exists (select 1 from @BrowserDetails where LogDetail like 'Running%') 
			set @IsRunning = 1
		else
			set @IsRunning = 0

		insert #SSL_KVP select 'SQL Browser Enabled', @IsRunning
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

go

print 'Checking if SSAS is Installed...'
if upper ($(UsePowerShell)) = 'Y'
begin

	declare @MSOLAPDetails table
	(
		ServiceDetail nvarchar(200)
	) 
 
	declare @Cmd varchar(1000)
	declare @SSASInstalled bit


	set @Cmd = 'powershell.exe -c "Get-Service | Where-Object {$_.Name -like ''MSOLAP*''}"'

	insert into @MSOLAPDetails exec  master..xp_cmdshell @Cmd
	
	-- if there is a problem, log this
	if exists (select * from @MSOLAPDetails where ServiceDetail like '%Get-Service%')
	begin
		insert #Problems select distinct 'SQL Browser Service', 'There was a problem checking if SSAS is running using powershell.  The full error is: ' + 
													left(stuff((
													select 
														',' + b.ServiceDetail
													from 
														@MSOLAPDetails b
													where 
														b.ServiceDetail = ServiceDetail
													order by 
														b.ServiceDetail for xml path('')),1,1,''), 915) as ErrorString
													from @MSOLAPDetails
													group by ServiceDetail
	end
	else
	begin
		if exists (select 1 from @MSOLAPDetails where ServiceDetail like 'Running%') 
			set @SSASInstalled = 1
		else
			set @SSASInstalled = 0

		insert #SSL_KVP select 'SSAS Installed',  @SSASInstalled
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
	
end

go



if upper ($(UsePowerShell)) = 'Y'
begin
	print 'Getting SSIS Service Account...'

	set nocount on

	declare @SQLName varchar(255) 
	declare @SSISAccount varchar(100)
	declare @Cmd varchar(1000)

	declare @SSISDetails table
	(
		ServiceDetail nvarchar(1000)
	) 


	-- check if there is a SSIS service first
	set @Cmd = 'powershell.exe -c "Get-Service | Where-Object {$_.Name -like ''Msdts*''}"'

	insert into @SSISDetails exec master..xp_cmdshell @Cmd
	
	if exists (select * from @SSISDetails where ServiceDetail like '%Get-Service%')
	begin
		insert #Problems select distinct 'SSIS Service Account', 'There was a problem checking if SSIS is running using powershell.  The full error is: ' + 
													left(stuff((
													select 
														',' + b.ServiceDetail
													from 
														@SSISDetails b
													where 
														b.ServiceDetail = ServiceDetail
													order by 
														b.ServiceDetail for xml path('')),1,1,''), 915) as ErrorString
													from @SSISDetails
													group by ServiceDetail
		
	end
	else
	begin
	
		delete from @SSISDetails where ServiceDetail is null

		if exists (Select * from @SSISDetails where ServiceDetail  like '%MsDtsServer%')
		begin

			if (select charindex('\', convert(varchar, serverproperty('servername')))) > 1 -- if there is a \ in the servername it is a named instance
				set @SQLName = @@servicename
			else
				set @SQLName = convert(varchar, serverproperty('servername'))

			execute master.dbo.xp_instance_regread
					  @rootkey      = N'HKEY_LOCAL_MACHINE',
					  @key          = N'SYSTEM\CurrentControlSet\Services\MsDtsServer',
					  @value_name   = N'ObjectName',
					  @value        = @SSISAccount output
		end

		insert into #SSL_KVP select 'SSIS Service Account', @SSISAccount

	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

go



if upper ($(UsePowerShell)) = 'Y'
begin
	print 'Getting a list of services running...'	
	
	declare @Cmd			varchar(1000)
	declare @XmlText		varchar(max)

    declare @PowerShellResult table
    (
		ResultLine varchar(max)
    )

	declare @Services table
	(
		serviceXML XML 
	)

	declare @ServiceDetails table
	(	
		RecordID int identity(1,1)
		,DisplayName	varchar(128)
		,StartName	varchar(128)
	)

	set @Cmd = '@PowerShell -noprofile -command "Get-WmiObject win32_service | Where {$_.displayname -like ''SQL*''} | Select @{Name=''DisplayName''; E={$_.DisplayName}}, @{Name=''StartName''; E={$_.StartName}} | ConvertTo-XML -As String'
	insert @PowerShellResult exec xp_cmdshell @Cmd

	set @XmlText = '';
    select @XmlText = coalesce(@XmlText + '', '' ) + ResultLine from @PowerShellResult where ResultLine is not null

	if left(@XmlText, 13) not like 'Get-WmiObject%' -- There are errors found
	begin

		insert into @Services
		select cast(@XmlText as xml);

		insert into @ServiceDetails
		select distinct
			m.c.value('(Property[@Name="DisplayName"]/text())[1]', 'varchar(128)'),
			m.c.value('(Property[@Name="StartName"]/text())[1]', 'varchar(128)')
		from 
			@Services as re
			outer apply re.serviceXML.nodes('Objects/Object') as m(c)

		--select * from @ServiceDetails

		insert into #SSL_Message select 41, RecordID, 1, DisplayName from @ServiceDetails
		insert into #SSL_Message select 41, RecordID, 2, StartName from @ServiceDetails
	end
	else
	begin
		insert #Problems select top 1 'Services Running', 'There was a problem getting the list of services running using powershell.  The error is :' + left(@XmlText, 850) 
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

go


print 'Checking if SSRS Installed...'

begin


	if object_id('tempdb..#ssrs_candidates') is not null 
		drop table #ssrs_candidates;

	create table #ssrs_candidates 
	(
		c_id int identity
		,DatabaseName varchar(100)
		,Processed bit
	)

	declare @CmdSSRS nvarchar(max)
	declare @DatabaseNameSSRS varchar(128)
	declare @CurrentReportsExist bit
	declare @statement nvarchar(max)
	declare @IsInstalled bit
	declare @HasSSRSReports bit

	exec master.sys.sp_MSforeachdb'
		insert into #ssrs_candidates
		select TABLE_CATALOG, 0
		from [?].INFORMATION_SCHEMA.COLUMNS
		where   TABLE_NAME =      ''Subscriptions''
		and      COLUMN_NAME =      ''DeliveryExtension''
		and      ORDINAL_POSITION =   16
		and      DATA_TYPE=''nvarchar'''


	set @HasSSRSReports = 0
	set @IsInstalled = 0

	if exists (select * from #ssrs_candidates)
		set @IsInstalled = 1
	else
		set @IsInstalled = 0
		
	insert #SSL_KVP select 	'SSRS Installed' , @IsInstalled 

	if @IsInstalled = 1
	begin
		while exists (select * from #ssrs_candidates where Processed = 0)
		begin
	
			select top 1 @DatabaseNameSSRS = DatabaseName from #ssrs_candidates where Processed = 0 order by DatabaseName

			set @CmdSSRS = 'if exists (select 1 from ' + @DatabaseNameSSRS + '.dbo.[Catalog] where [Type] = 2) set @ParamReportsExist = 1 else set @ParamReportsExist = 0 '
			execute sp_executesql @statement = @CmdSSRS, @params = N'@ParamReportsExist bit output', @ParamReportsExist = @CurrentReportsExist output
	
			if @CurrentReportsExist = 1
				set @HasSSRSReports = 1

			update #ssrs_candidates set Processed = 1 where DatabaseName = @DatabaseNameSSRS
		end
	end

	insert #SSL_KVP select 	'SSRSHasReports' , @HasSSRSReports
	
	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

print 'Is Instant File Initialization enabled?...'	

begin
	
	declare @Results table
	(
		Detail varchar(1000)	
	)

	declare @IsEnabled bit = 0
	
	insert into @Results exec xp_cmdshell 'whoami /priv' 

	if exists (select * from @Results where Detail like '%Perform volume maintenance tasks%' and Detail like '%Enabled%')
		set @IsEnabled = 1
		
	insert #SSL_KVP select 'IFIEnabled' , @IsEnabled

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
	
end


print 'Getting data from SQL Log...'

begin
	
	declare @i int = 0
	
	if object_id('tempdb..#logs') is not null
		drop table #logs


	create table #logs
	(
		LogDate		datetime,
		ProcessInfo varchar(255),
		MessageText nvarchar(4000)
	)

	declare @StartingDetails table
	(
		LogDate		datetime,
		ProcessInfo varchar(255),
		MessageText nvarchar(4000)
	)


	declare @LogFiles table
	(
		ArchiveNumber	smallint
		,CreatedDate	datetime
		,SizeB			bigint
	)

	declare @AggregatedErrors table
	(
		RecordID	int identity(1,1)
		,ErrorDate	datetime
		,ErrorText nvarchar(max)
	)

	declare @currentLanguage nvarchar(128)

	set nocount on

	select @currentLanguage = @@language
	set language 'us_english'

	declare @StartingString nvarchar(100) 
	declare @ErrorString1 nvarchar(100) 
	declare @ErrorString2 nvarchar(20)
	declare @LogFileSizeMB int 
	declare @ActualLogFileCount int
	declare @LocalNumberOfLogFilesToRead int

	set @LocalNumberOfLogFilesToRead = $(NumberOfLogFilesToRead)

	insert into @LogFiles exec xp_enumerrorlogs  --grab file log file sizes
	
	set @ActualLogFileCount = @@rowcount
	
	-- If the user has selected	more than the actual number of log files, then set the max number to the number of log files
	if @LocalNumberOfLogFilesToRead > @ActualLogFileCount 
	begin
		print 'Setting the $NumberOfLogFilesToRead variable to ' + convert(varchar, @ActualLogFileCount) + ' as this is the actual log file count...' 
		set @LocalNumberOfLogFilesToRead = @ActualLogFileCount
	end

	set @ErrorString1 = '%' + convert(nvarchar(100), lower($(ErrorString1))) + '%'
	set @ErrorString2 = '%' + convert(nvarchar(100), lower($(ErrorString2))) + '%'

	while @i < @LocalNumberOfLogFilesToRead
	begin

		-- may have to check the size of the error log file before reading it.
		
		select 
			@LogFileSizeMB =  SizeB / 1024.0 / 1024.0 
		from 
			@LogFiles
		where 
			ArchiveNumber = @i
			

		If @LogFileSizeMB > $(MaxErrorLogFileSizeMB) -- If this file is bigger than what we want, skip it and log the fact
		begin
			Insert into #Problems select 'SQL Error Log File', 'The SQL Error log file #' + convert(varchar, @i) + ' was not parsed for errors because it was above the size threshold of ' + convert(varchar, $(MaxErrorLogFileSizeMB)) + 'MB'
		end
		else
			insert into #logs  exec xp_readerrorlog @i, 1 

		set @i = @i + 1

	end

	insert into #SSL_KVP select 'LastSQLRestart' , sqlserver_start_time FROM sys.dm_os_sys_info

	insert into @AggregatedErrors
	select
		LogDate
		,stuff(
			(select distinct ' ' + MessageText 
			from #logs
			where LogDate = a.LogDate and ProcessInfo = a.ProcessInfo 
			for xml path ('')), 1, 1, '') as MessageList
	from 
		#logs as a
	where 
		(MessageText like  @ErrorString1 or MessageText like  @ErrorString2)
		and MessageText not like '%without error%'
		and MessageText not like '%DBCC%found 0 errors%'
	group by 
		ProcessInfo
		,LogDate

	insert #SSL_Message select 94, RecordID, 1, convert(nvarchar(23), ErrorDate, 121) from @AggregatedErrors
	insert #SSL_Message select 94, RecordID, 2, replace(replace(convert(nvarchar(4000), ErrorText), char(13), ' '), char(10), ' ') from @AggregatedErrors


	--insert #SSL_Message select 94, RecordID, 1, convert(nvarchar(23), LogDate, 121) from #logs
	--insert #SSL_Message select 94, RecordID, 2, replace(replace(convert(nvarchar(4000), MessageText), char(13), ' '), char(10), ' ') from #logs

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
	
	print 'Getting data from SQL Agent Log...'

	declare @icount int = 0
	declare @agentlogfilecount int = 0
	declare @RestartCount int = 0
	declare @ErrorCount int = 0
	
	if object_id('tempdb..#agentlogs') is not null
		drop table #agentlogs

	create table #agentlogs
	(
		RecordID	int identity(1,1),
		LogDate		datetime,
		ErrorLevel	int,
		MessageText nvarchar(4000)
	)

	set nocount on

	declare @agentfiles table
	(
		ArchiveNumber int
		,FileDate	datetime
		,LogFileSize	bigint
	)

	insert into @agentfiles exec xp_enumerrorlogs 2
	select @agentlogfilecount = @@ROWCOUNT

	while @icount < @agentlogfilecount
	begin

		insert into #agentlogs  exec xp_readerrorlog @icount, 2
		set @icount = @icount + 1

	end

	delete from #agentlogs where ErrorLevel <> 1

	insert #SSL_Message select 95, RecordID, 1, convert(nvarchar(23), LogDate, 121) from #agentlogs 
	insert #SSL_Message select 95, RecordID, 2, replace(replace(convert(nvarchar(4000), MessageText), char(13), ' '), char(10), ' ') from #agentlogs 

	set language @currentLanguage

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
	
end



print 'Getting Hide Instance Setting...'

begin

	declare @getValue int 
	exec master..xp_instance_regread 
		  @rootkey = N'HKEY_LOCAL_MACHINE', 
		  @key= N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib', 
		  @value_name = N'HideInstance', 
		  @value = @getValue output 
	
	insert #SSL_KVP select 'Hide Instance', @getValue;

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end





print 'Checking Last known good DBCC...'

begin

	if object_id('tempdb..#DBCCs') is not null
		drop table #DBCCs;

	create table #DBCCs
	(
		RecordID int identity(1, 1)	primary key 
		,ParentObject			varchar(255) 
		,Object					varchar(255) 
		,Field					varchar(255) 
		,Value					varchar(255) 
		,DbName					nvarchar(128) null
	)
	
	exec sp_MSforeachdb N'USE [?];INSERT #DBCCs (ParentObject,Object,Field,Value) EXEC (''DBCC DBInfo() With TableResults, NO_INFOMSGS''); UPDATE #DBCCs SET DbName = N''?'' WHERE DbName IS NULL;';

	--select 
	--	DbName
	--	,Value 
	--from 
	--	#DBCCs 
	--where 
	--	Field ='dbi_dbccLastKnownGood'


	delete from #DBCCs where Field <> 'dbi_dbccLastKnownGood'

	insert #SSL_Message select 47, RecordID, 1, convert(varchar, DbName) from #DBCCs
	insert #SSL_Message select 47, RecordID, 2, convert(varchar, Value, 120) from #DBCCs;

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

update #DatabaseNames set processed = 0

-- get this first.....
print 'Checking Index Fragmentation...'

begin

	declare @DatabaseName sysname
	declare @Cmd nvarchar(max)

	if object_id('tempdb..#Results') is not null
		drop table #Results

	create table #Results 
	(
		RecordID				int identity(1,1)
		,DatabaseName			sysname
		,SchemaName				sysname
		,TableName				sysname
		,IndexName				sysname
		,FragmentationPercent	decimal(4,2)
		,ObjectPageCount		int
	)

	while exists (select * from #DatabaseNames where Processed = 0)
	begin

		select top 1 @DatabaseName = DatabaseName from #DatabaseNames where Processed = 0 order by DatabaseName 

		set @Cmd = 
		'	use [' + @DatabaseName + '];' +
		'	insert into #Results 
			select 
				quotename(db_name()),
				quotename(s.[name]), 
				quotename(t.[name]), 
				quotename(i.[name]),
				p.avg_fragmentation_in_percent,
				p.page_count
			from 
				sys.dm_db_index_physical_stats (db_id(), null, null, null, null) as p
				inner join sys.tables t on t.[object_id] = p.[object_id]
				inner join sys.schemas s on t.[schema_id] = s.[schema_id]
				inner join sys.indexes AS i ON i.[object_id] = p.[object_id] and p.index_id = i.index_id
			where	
				i.[name] is not null
			order by 
				p.avg_fragmentation_in_percent desc'

			exec sp_executesql @Cmd

		update #DatabaseNames set Processed = 1 where DatabaseName = @DatabaseName
	end


	-- clean out records we are not interested in
	delete from #Results where FragmentationPercent < $(FragmentationPercent)
	delete from #Results where ObjectPageCount < $(ObjectPageCount)

	if exists (Select 1 from #Results)
	begin
		insert #SSL_Message select 48, RecordID, 1, convert(varchar, DatabaseName) from #Results 
		insert #SSL_Message select 48, RecordID, 2, convert(varchar, SchemaName) from #Results;
		insert #SSL_Message select 48, RecordID, 3, convert(varchar, TableName) from #Results;
		insert #SSL_Message select 48, RecordID, 4, convert(varchar, IndexName) from #Results;
		insert #SSL_Message select 48, RecordID, 5, convert(varchar, FragmentationPercent) from #Results;
		insert #SSL_Message select 48, RecordID, 6, convert(varchar, ObjectPageCount) from #Results;
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Getting Jobs Owned By Users...'

begin

	if object_id('tempdb..#JobsOwnedByUsers') is not null
		drop table #JobsOwnedByUsers;

	create table #JobsOwnedByUsers
	(
		RecordID int identity(1, 1)	primary key 
		,JobName				sysname
		,JobOwner				nvarchar(128)
	)
	

	insert into #JobsOwnedByUsers
	select  
		j.name as JobName 
		,suser_sname(j.owner_sid) as JobOwner	
	from    
		msdb.dbo.sysjobs j 
	where   
		j.enabled = 1
		and suser_sname(j.owner_sid) <> suser_sname(0x01)

	--select * from #JobsOwnedByUsers
	insert #SSL_Message select 60, RecordID, 1, convert(varchar, JobName) from #JobsOwnedByUsers 
	insert #SSL_Message select 60, RecordID, 2, convert(varchar, JobOwner) from #JobsOwnedByUsers;

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Checking for Replication...'

begin

	if object_id('tempdb..#HasReplication') is not null
		drop table #HasReplication;

	create table #HasReplication
	(
		RecordID int identity(1, 1)	primary key 
		,DatabaseName		sysname
		,HasReplication		bit
	)
	

	-- replication
	insert into #HasReplication
	select  
		name
		,1	
	from    
		sys.databases s
	where   
		is_published = 1 
		or is_subscribed = 1 
		or is_merge_published = 1 
		or is_distributor = 1;

	if @@rowcount <> 0
	begin
		
		insert #SSL_Message select 62, RecordID, 1, convert(varchar, DatabaseName) from  #HasReplication 
		insert #SSL_Message select 62, RecordID, 2, convert(varchar, HasReplication) from  #HasReplication

	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Checking for Log Shipping...'
begin

	-- Check for Log Shipping
	if object_id('tempdb..#LogShippingDetails') is not null
		drop table #LogShippingDetails

	create table #LogShippingDetails
	(
		RecordID int identity(1, 1)	primary key 
		,PrimaryDatabase	sysname
		,PrimaryServer		sysname
		,SecondaryDatabase	sysname
		,SecondaryServer	sysname
	)

	insert into #LogShippingDetails
	select 
		pl.primary_database
		,lm.primary_server
		,sl.secondary_database
		,sl.secondary_server
		-- commented out, may be required:
		--,pl.backup_directory 
		--,pl.backup_share
		--,pl.monitor_server
		--,pl.last_backup_file
		--,pl.last_backup_date 
	from 
		msdb.dbo.log_shipping_primary_databases pl
		inner join msdb.dbo.log_shipping_primary_secondaries sl on pl.primary_id=sl.primary_id
		inner join msdb.dbo.log_shipping_monitor_primary lm on pl.primary_id=lm.primary_id
	order by
		primary_server
		,primary_database
		,secondary_database

	if @@rowcount <> 0
	begin
		insert #SSL_Message select 63, RecordID, 1, convert(varchar, PrimaryDatabase) from #LogShippingDetails
		insert #SSL_Message select 63, RecordID, 2, convert(varchar, PrimaryServer) from #LogShippingDetails
		insert #SSL_Message select 63, RecordID, 3, convert(varchar, SecondaryDatabase) from #LogShippingDetails
		insert #SSL_Message select 63, RecordID, 4, convert(varchar, SecondaryServer) from #LogShippingDetails
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Looking into Database Mirroring...'
begin

	if object_id('tempdb..#MirroringDetails') is not null
		drop table #MirroringDetails

	create table #MirroringDetails
	(
		RecordID int identity(1, 1)	primary key 
		,DatabaseName		sysname
		,MirroringState		nvarchar(60)
		,PartnerName		nvarchar(128)
		,MirroringRoleDesc	nvarchar(60)
		,SafelyLevelDesc	nvarchar(60)
		,MirrorWitnessName	nvarchar(128)
		,ConnectionTimeout	int
	)

	insert into #MirroringDetails
	select   
		db_name([database_id])           
		,mirroring_state_desc           
		,mirroring_partner_name         
		,mirroring_role_desc            
		,mirroring_safety_level_desc    
		,mirroring_witness_name         
		,mirroring_connection_timeout	
	from 
		sys.database_mirroring 
	where 
		mirroring_guid IS NOT null
	order by 
		db_name([database_id])           

	if @@rowcount <> 0
	begin
		insert #SSL_Message select 64, RecordID, 1, convert(varchar, DatabaseName) from #MirroringDetails
		insert #SSL_Message select 64, RecordID, 2, convert(varchar, MirroringState) from #MirroringDetails
		insert #SSL_Message select 64, RecordID, 3, convert(varchar, PartnerName) from #MirroringDetails
		insert #SSL_Message select 64, RecordID, 4, convert(varchar, MirroringRoleDesc) from #MirroringDetails
		insert #SSL_Message select 64, RecordID, 5, convert(varchar, SafelyLevelDesc) from #MirroringDetails
		insert #SSL_Message select 64, RecordID, 6, convert(varchar, MirrorWitnessName) from #MirroringDetails
		insert #SSL_Message select 64, RecordID, 7, convert(varchar, ConnectionTimeout) from #MirroringDetails
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Checking for Transparent Data Encryption (TDE)...'

begin
	if exists (select 1 from sys.databases where is_encrypted = 1)
	begin

		if object_id('tempdb..#TDEDatabases') is not null
			drop table #TDEDatabases

		create table #TDEDatabases
		(
			RecordID int identity(1, 1)	primary key 
			,DatabaseName		sysname
		)

		
		insert into #TDEDatabases
		select 
			d.[name]
		 from 
			sys.databases d 
		where 
			is_encrypted = 1

		if @@rowcount <> 0
		begin
			insert #SSL_Message select 65, RecordID, 1, convert(varchar, DatabaseName) from #TDEDatabases
		end

	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Checking for User Objects in Model...'

begin

	if exists (select 1 from model.sys.tables where  is_ms_shipped = 0)
	begin

		if object_id('tempdb..#UserObjectsInModelDB') is not null
			drop table #UserObjectsInModelDB

		create table #UserObjectsInModelDB
		(
			RecordID int identity(1, 1)	primary key 
			,ObjectName			sysname
			,TypeDesc			nvarchar(60)
			,DateCreated		varchar(20)
		)

		insert into #UserObjectsInModelDB
		select   
			name as ObjectName
			,type_desc as TypeDesc
			,cast(create_date as varchar(20)) as DateCreated
		from    
			model.sys.tables 
		where   
			is_ms_shipped = 0;

		if @@rowcount <> 0
		begin
			insert #SSL_Message select 66, RecordID, 1, convert(varchar, ObjectName) from #UserObjectsInModelDB
			insert #SSL_Message select 66, RecordID, 2, convert(varchar, TypeDesc) from #UserObjectsInModelDB
			insert #SSL_Message select 66, RecordID, 3, convert(varchar, DateCreated) from #UserObjectsInModelDB
		end

		
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

print 'Getting Linked Servers...'
begin
	if exists (select 1 from sys.servers s	inner join sys.linked_logins l on s.server_id = l.server_id where s.is_linked = 1)
	begin
		
		if object_id('tempdb..#LinkedServers') is not null
			drop table #LinkedServers

		create table #LinkedServers
		(
			RecordID int identity(1, 1)	primary key 
			,LinkedServerName		sysname
			,DataSource				nvarchar(4000)
			,IsLinked				bit
			,LocalLogin				varchar(128)
			,RemoteLogin			varchar(128)
		)

		insert into #LinkedServers
		select 
			s.name
			,data_source
			,is_linked
			,case sl.uses_self_credential when 1 then 'Uses Self Credentials' else ssp.name end 
			,sl.remote_name
		from    
			sys.servers s
			left join sys.linked_logins sl on s.server_id = sl.server_id 
			left join sys.server_principals ssp on ssp.principal_id = sl.local_principal_id
		where   
			s.is_linked = 1


		if @@rowcount <> 0
		begin
			insert #SSL_Message select 67, RecordID, 1, convert(varchar, LinkedServerName) from #LinkedServers
			insert #SSL_Message select 67, RecordID, 2, convert(varchar, DataSource) from #LinkedServers
			insert #SSL_Message select 67, RecordID, 3, convert(varchar, IsLinked) from #LinkedServers
			insert #SSL_Message select 67, RecordID, 4, convert(varchar, isnull(LocalLogin, 'n/a')) from #LinkedServers
			insert #SSL_Message select 67, RecordID, 5, convert(varchar, isnull(RemoteLogin, 'n/a')) from #LinkedServers
		end			

	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Getting jobs set to auto start...'

begin

	if exists (select  1
				from    
					msdb.dbo.sysschedules sched
					inner join msdb.dbo.sysjobschedules jsched on sched.schedule_id = jsched.schedule_id
					inner join msdb.dbo.sysjobs j on jsched.job_id = j.job_id
				where   
					sched.freq_type = 64)

	begin
		
		if object_id('tempdb..#JobsWhichAutoStart') is not null
			drop table #JobsWhichAutoStart

		create table #JobsWhichAutoStart
		(
			RecordID	int identity(1, 1)	primary key 
			,jobName	sysname
		)

		insert into #JobsWhichAutoStart
		select  
			j.name
		from    
			msdb.dbo.sysschedules sched
			inner join msdb.dbo.sysjobschedules jsched on sched.schedule_id = jsched.schedule_id
			inner join msdb.dbo.sysjobs j on jsched.job_id = j.job_id
		where   
			sched.freq_type = 64;

		if @@rowcount <> 0
		begin
			insert #SSL_Message select 68, RecordID, 1, convert(varchar, jobName) from #JobsWhichAutoStart
		end

	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


begin

	declare @Version nvarchar(1000)
	select @Version = @@VERSION 

	if @Version like '%64-bit%' and lower(@Version) like '%enterprise%'
	begin
		
		print 'Checking all CPU''s are being used for Enterprise 64-bit platforms...'

		if exists (select * from sys.dm_os_schedulers where is_online = 0)
		begin

			if object_id('tempdb..#UnusedCPUs') is not null
				drop table #UnusedCPUs

			create table #UnusedCPUs
			(
				RecordID	int identity(1, 1)	primary key 
				,CPUID		int
			)

			insert into #UnusedCPUs
			select distinct cpu_id from sys.dm_os_schedulers where is_online = 0

			if @@rowcount <> 0
			begin
				insert #SSL_Message select 69, RecordID, 1, convert(varchar, CPUID) from #UnusedCPUs
			end
		end

		print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

	end
end


print 'Checking deadlocks recorded since startup'

begin
	
	declare @DeadlockCount int

	select @DeadlockCount = p.cntr_value
	from 
		sys.dm_os_performance_counters p
		inner join sys.databases d on d.name = 'tempdb'
	where 
		rtrim(p.counter_name) = 'Number of Deadlocks/sec'
		and rtrim(p.instance_name) = '_Total'
		and p.cntr_value > 0


	insert #SSL_KVP select 'Deadlocks', convert(varchar, isnull(@DeadlockCount, 0))
							
	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

print 'Checking Database Autogrow events that take longer than ' + convert(varchar, $(AutoGrowDurationSeconds)) + ' seconds...'
begin

	declare @Path nvarchar(1000);
	declare @CutoffDate datetime

	if object_id('tempdb..#SlowGrowingDBs') is not null
		drop table #SlowGrowingDBs

	create table #SlowGrowingDBs
	(
		RecordID				int identity(1, 1)	primary key 
		,DatabaseName			sysname
		,LogicaName				varchar(512)
		,SizeMB					decimal(18,2)
		,IsPercentGrowth		bit
		,GrowthIncrement		varchar(100)
		,NextAutoGrowSizeMB		decimal(18,2)
		,MaxSize				varchar(100)
		,PhysicalName			nvarchar(1000)
		,DurationUs				bigint -- microseconds
		,StartTime				datetime
	)

	set @CutoffDate = dateadd(day, -$(AutoGrowthDaysBack), getdate())

	select 
		@Path = reverse(substring(reverse([path]), charindex('\', reverse([path])), 512)) + N'log.trc'
	from    
		sys.traces
	where   
		is_default = 1;

	insert into #SlowGrowingDBs
	select distinct
		f.name
		,f.name logical_name
		,convert (decimal (20,2) , (convert(decimal, size)/128)) [file_size_MB]
		,case f.is_percent_growth when 1 then 1 else 0 end [is_percent_growth]
		,case f.is_percent_growth when 1 then convert(varchar, f.growth) + '%'	when 0 then convert(varchar, f.growth/128) + ' MB' end [growth_in_increment_of]
		,case f.is_percent_growth when 1 then convert(decimal(20,2), (((convert(decimal, size)*growth)/100)*8)/1024) when 0 then convert(decimal(20,2), (convert(decimal, growth)/128)) end [next_auto_growth_size_MB]
		,case f.max_size when 0 then 'No growth is allowed' when -1 then 'File will grow until the disk is full' else convert(varchar, f.max_size) end [max_size]
		,physical_name
		,Duration
		,t.StartTime
	from 
		sys.fn_trace_gettable(@Path, default) t
		inner join sys.master_files f on f.database_id = db_id(t.DatabaseName)
	where
		Duration > ($(AutoGrowDurationSeconds) * 1000000)  -- the trace records duration as microseconds
		and EventClass in (92,93)
		and t.StartTime > @CutoffDate
	order by
		f.name
	
	if @@rowcount <> 0
	begin
		insert #SSL_Message select 70, RecordID, 1, convert(varchar, DatabaseName) from #SlowGrowingDBs
		insert #SSL_Message select 70, RecordID, 2, convert(varchar, LogicaName) from #SlowGrowingDBs		
		insert #SSL_Message select 70, RecordID, 3, convert(varchar, SizeMB) from #SlowGrowingDBs		
		insert #SSL_Message select 70, RecordID, 4, convert(varchar, IsPercentGrowth) from #SlowGrowingDBs		
		insert #SSL_Message select 70, RecordID, 5, convert(varchar, GrowthIncrement) from #SlowGrowingDBs		
		insert #SSL_Message select 70, RecordID, 6, convert(varchar, NextAutoGrowSizeMB) from #SlowGrowingDBs		
		insert #SSL_Message select 70, RecordID, 7, convert(varchar, MaxSize) from #SlowGrowingDBs		
		insert #SSL_Message select 70, RecordID, 8, convert(varchar, PhysicalName) from #SlowGrowingDBs		
		insert #SSL_Message select 70, RecordID, 9, convert(varchar, DurationUs) from #SlowGrowingDBs		
		insert #SSL_Message select 70, RecordID, 10, convert(varchar, StartTime) from #SlowGrowingDBs		
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
end


print 'Getting Page Life Expectancy (PLE)...'
begin
	-- KVP data

	insert into #SSL_KVP
	select 
		counter_name,
		cntr_value
	from 
		sys.dm_os_performance_counters
	where 
		object_name LIKE '%Manager%'	
		and counter_name = 'Page life expectancy'

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
end

print 'Getting memory information from server...'

begin
	
	insert into #SSL_KVP
	select 'total_physical_memory', total_physical_memory_kb from sys.dm_os_sys_memory

	insert into #SSL_KVP
	select 'available_physical_memory', available_physical_memory_kb from sys.dm_os_sys_memory

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
end


print 'Checking for High Impact Indexes...'

begin

	if object_id('tempdb..#HighImpactIndexes') is not null
		drop table #HighImpactIndexes

	create table #HighImpactIndexes
	(
		RecordID					int identity(1,1)
		,DatabaseName				sysname
		,ObjectID					int
		,FullyQualifiedObjectName	varchar(1000)
		,UniqueCompiles				bigint
		,UserSeeks					bigint
		,UserScans					bigint
		,LastUserSeekTime			datetime
		,LastUserScanTime			datetime
		,AvgTotalUserCost			float
		,AvgUserImpact				float
		,SystemSeeks				bigint
		,SystemScans				bigint
		,LastSystemSeekTime			datetime
		,LastSystemScanTime			datetime
		,AvgTotalSystemCost			float
		,AvgSystemImpact			float
		,IndexAdvantage				float
		,IndexDetails				varchar(4000)
	)

	set transaction isolation level read uncommitted

	insert into #HighImpactIndexes
	select 
		db.name as DatabaseName
		,id.object_id as ObjectID
		,id.statement as FullyQualifiedObjectName
		,gs.unique_compiles as UniqueCompiles
		,gs.user_seeks as UserSeeks
		,gs.user_scans as UserScans
		,gs.last_user_seek as LastUserSeekTime
		,gs.last_user_scan as LastUserScanTime
		,gs.avg_total_user_cost as AvgTotalUserCost
		,gs.avg_user_impact as AvgUserImpact
		,gs.system_seeks as SystemSeeks
		,gs.system_scans as SystemScans
		,gs.last_system_seek as LastSystemSeekTime
		,gs.last_system_scan as LastSystemScanTime
		,gs.avg_total_system_cost as AvgTotalSystemCost
		,gs.avg_system_impact as AvgSystemImpact
		,gs.user_seeks * gs.avg_total_user_cost * (gs.avg_user_impact * 0.01) as IndexAdvantage
		,isnull(id.[equality_columns], '') 
		+ case when id.[equality_columns] is not null and id.[inequality_columns] is not null
				then ','
				else ''end 
		+ isnull(id.inequality_columns, '') + ')' + isnull(' include (' + id.included_columns + ')', '') AS IndexDetails
	from 
		sys.dm_db_missing_index_group_stats gs 
		inner join sys.dm_db_missing_index_groups ig on gs.group_handle = ig.index_group_handle
		inner join sys.dm_db_missing_index_details id on ig.index_handle = id.index_handle
		inner join sys.databases db on db.database_id = id.database_id
		inner join #DatabaseNames n on n.DatabaseId = db.database_id
	where 
		id.database_id > 4 
	order by 
		IndexAdvantage desc
	option (recompile);

	if @@rowcount > 0
	begin
		insert #SSL_Message select 71, RecordID, 1, convert(nvarchar(4000), DatabaseName) from #HighImpactIndexes
		insert #SSL_Message select 71, RecordID, 2, convert(nvarchar(4000), ObjectID) from #HighImpactIndexes					
		insert #SSL_Message select 71, RecordID, 3, convert(nvarchar(4000), FullyQualifiedObjectName) from #HighImpactIndexes	
		insert #SSL_Message select 71, RecordID, 4, convert(nvarchar(4000), UniqueCompiles) from #HighImpactIndexes				
		insert #SSL_Message select 71, RecordID, 5, convert(nvarchar(4000), UserSeeks) from #HighImpactIndexes					
		insert #SSL_Message select 71, RecordID, 6, convert(nvarchar(4000), UserScans) from #HighImpactIndexes					
		insert #SSL_Message select 71, RecordID, 7, convert(varchar(30), LastUserSeekTime, 120) from #HighImpactIndexes			
		insert #SSL_Message select 71, RecordID, 8, convert(varchar(30), LastUserScanTime, 120) from #HighImpactIndexes			
		insert #SSL_Message select 71, RecordID, 9, convert(nvarchar(4000), AvgTotalUserCost) from #HighImpactIndexes			
		insert #SSL_Message select 71, RecordID, 10, convert(nvarchar(4000), AvgUserImpact) from #HighImpactIndexes				
		insert #SSL_Message select 71, RecordID, 11, convert(nvarchar(4000), SystemSeeks) from #HighImpactIndexes				
		insert #SSL_Message select 71, RecordID, 12, convert(nvarchar(4000), SystemScans) from #HighImpactIndexes				
		insert #SSL_Message select 71, RecordID, 13, convert(varchar(30), LastSystemSeekTime, 120) from #HighImpactIndexes			
		insert #SSL_Message select 71, RecordID, 14, convert(varchar(30), LastSystemScanTime, 120) from #HighImpactIndexes			
		insert #SSL_Message select 71, RecordID, 15, convert(nvarchar(4000), AvgTotalSystemCost) from #HighImpactIndexes			
		insert #SSL_Message select 71, RecordID, 16, convert(nvarchar(4000), AvgSystemImpact) from #HighImpactIndexes			
		insert #SSL_Message select 71, RecordID, 17, convert(nvarchar(4000), IndexAdvantage) from #HighImpactIndexes				
		insert #SSL_Message select 71, RecordID, 18, convert(nvarchar(4000), IndexDetails) from #HighImpactIndexes				
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Checking for Slow Disk reads and Writes...'

begin


	if object_id('tempdb..#SlowReadsAndWrites') is not null
		drop table #SlowReadsAndWrites

	create table #SlowReadsAndWrites
	(
		RecordID				int identity(1, 1)	primary key 
		,DatabaseName			sysname
		,PhysicalName			nvarchar(512)
		,Activity				char(1)
		,TimePer				decimal (18,6)
	)	

	-- get the recorded slow reads based on stall read time 

	insert into #SlowReadsAndWrites
	select
		db_name (vfs.database_id) as DatabaseName
		,mf.physical_name as [FileName]
		,'R' -- reads
		,case when num_of_reads = 0 then 0 else (io_stall_read_ms / num_of_reads) end as TimPer
	from
		sys.dm_io_virtual_file_stats (null,null) vfs
		inner join sys.master_files mf on vfs.database_id = mf.database_id
		and vfs.[file_id] = mf.[file_id]
	where
		case when num_of_reads = 0 then 0 else (io_stall_read_ms / num_of_reads) end > $(SlowReadThresholdMS) -- milliseconds



	insert into #SlowReadsAndWrites
	select
		db_name (vfs.database_id) as DatabaseName
		,mf.physical_name as [FileName]
		,'W' -- writes
		,case when num_of_writes = 0 then 0 else (io_stall_write_ms / num_of_writes) end as TimPer
	from
		sys.dm_io_virtual_file_stats (null,null) vfs
		inner join sys.master_files mf on vfs.database_id = mf.database_id
		and vfs.[file_id] = mf.[file_id]
	where
		case when num_of_writes = 0 then 0 else (io_stall_write_ms / num_of_writes)  end > $(SlowWriteThresholdMS) -- milliseconds

	-- 72 is slow reads
	insert #SSL_Message select 72, RecordID, 1, convert(varchar, DatabaseName) from #SlowReadsAndWrites where Activity = 'R'
	insert #SSL_Message select 72, RecordID, 2, convert(nvarchar(512), PhysicalName) from #SlowReadsAndWrites where Activity = 'R'		
	insert #SSL_Message select 72, RecordID, 3, convert(varchar, Activity) from #SlowReadsAndWrites	where Activity = 'R'	
	insert #SSL_Message select 72, RecordID, 4, convert(varchar, TimePer) from #SlowReadsAndWrites where Activity = 'R'		
	-- 73 is slow writes
	insert #SSL_Message select 73, RecordID, 1, convert(varchar, DatabaseName) from #SlowReadsAndWrites where Activity = 'W'
	insert #SSL_Message select 73, RecordID, 2, convert(nvarchar(512), PhysicalName) from #SlowReadsAndWrites where Activity = 'W'		
	insert #SSL_Message select 73, RecordID, 3, convert(varchar, Activity) from #SlowReadsAndWrites	where Activity = 'W'	
	insert #SSL_Message select 73, RecordID, 4, convert(varchar, TimePer) from #SlowReadsAndWrites where Activity = 'W'		


	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Finding the average Read and Write Performance of the disk'
begin

	declare @AverageReadTime decimal(12,6)
	declare @AverageWriteTime decimal(12,6)



	select @AverageWriteTime =
		avg((io_stall_write_ms) / num_of_writes) / 1000.0 
	from    
		sys.dm_io_virtual_file_stats(null, null) as fs
	where
		io_stall_write_ms > 0 and num_of_writes > 0



	select @AverageReadTime =
		avg((io_stall_read_ms) / num_of_reads) / 1000.0 
	from    
		sys.dm_io_virtual_file_stats(null, null) as fs
	where
		io_stall_read_ms > 0 and num_of_reads > 0



	insert into #SSL_KVP select 'AverageDiskReadMS', convert(nvarchar(4000), @AverageReadTime)
	insert into #SSL_KVP select 'AverageDiskWriteMS', convert(nvarchar(4000), @AverageWriteTime)


	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

print 'Getting query performance information...'

begin

	if object_id('tempdb..#TheQueries') is not null
		drop table #TheQueries

	if object_id('tempdb..#currentReadings') is not null
		drop table #currentReadings

	if object_id('tempdb..#KeyLookups') is not null
		drop table #KeyLookups	

	create table #TheQueries
	(
		RecordID			int identity(1, 1)	primary key 
		,DatabaseName		sysname
		,TotalWorkerTime	bigint
		,PlanHandle			varbinary(64)
		,ParentQuery		nvarchar(4000)
		,IndividualQuery	nvarchar(4000)
	)

	create table #KeyLookups
	(
		RecordID			int identity(1, 1)	primary key 
		,DatabaseName		sysname
		,SchemaName			varchar(128)
		,TableName			varchar(128)
		,IndexName			varchar(128)
		,sql_text			nvarchar(4000)
		,PhysicalOp			varchar(128)
		,output_columns		varchar(128)
		,seek_columns		varchar(128)
	)

	select 
		[sql_handle], 
		plan_handle,
		statement_start_offset, 
		statement_end_offset, 
		total_elapsed_time, 
		total_worker_time, 
		execution_count
	into
		#currentReadings
	from
		sys.dm_exec_query_stats s
		cross apply sys.dm_exec_sql_text(s.sql_handle) t
		inner join sys.databases db on db.database_id =t.dbid
	where		
		db.state_desc = 'ONLINE'
	order by
		execution_count desc

	-- top 100 poorest performing queries (based on time)
	insert into #TheQueries
	select top 100
		db_name(qt.dbid) 
		,cr.total_worker_time 
		,cr.plan_handle
		,left(qt.text, 4000) as [Parent]
		,left(substring (qt.text,cr.statement_start_offset/2 + 1, ((case when cr.statement_end_offset = -1
				then len(convert(nvarchar(max), qt.text)) * 2
				else cr.statement_end_offset end - cr.statement_start_offset)/2) + 1), 4000) AS [IndividualQuery]
		
	from
		#currentReadings cr
		cross apply sys.dm_exec_sql_text(cr.sql_handle) as qt
		inner join sys.databases db on db.database_id = qt.dbid
	where
		qt.dbid >= 5 -- User Databases
		and qt.text is not null
		and db_name(qt.dbid) is not null
		and db.state_desc = 'ONLINE'
	order by
		cr.total_elapsed_time desc;


	-- check for any cursors
	if exists (select * from #TheQueries where 
		ParentQuery like '%Cursor%' or ParentQuery like '%cursor%' or ParentQuery like '%CURSOR%'
		or IndividualQuery like '%Cursor%' or IndividualQuery like '%cursor%' or IndividualQuery like '%CURSOR%')
	begin
		insert #SSL_Message select 74, RecordID, 1, convert(varchar, DatabaseName) from #TheQueries where ParentQuery like '%Cursor%' or ParentQuery like '%cursor%' or ParentQuery like '%CURSOR%' or IndividualQuery like '%Cursor%' or IndividualQuery like '%cursor%' or IndividualQuery like '%CURSOR%'
		insert #SSL_Message select 74, RecordID, 2, convert(varchar, TotalWorkerTime) from #TheQueries where ParentQuery like '%Cursor%' or ParentQuery like '%cursor%' or ParentQuery like '%CURSOR%' or IndividualQuery like '%Cursor%' or IndividualQuery like '%cursor%' or IndividualQuery like '%CURSOR%'
		insert #SSL_Message select 74, RecordID, 3, replace(replace(ParentQuery, char(13), ' '), char(10), ' ') from #TheQueries where ParentQuery like '%Cursor%' or ParentQuery like '%cursor%' or ParentQuery like '%CURSOR%' 
		insert #SSL_Message select 74, RecordID, 4, replace(replace(IndividualQuery, char(13), ' '), char(10), ' ') from #TheQueries where IndividualQuery like '%Cursor%' or IndividualQuery like '%cursor%' or IndividualQuery like '%CURSOR%'
	end

	-- check for key lookups
	;with xmlnamespaces
	   (default 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
	insert into #KeyLookups
	select top 100
		convert(varchar(128), i.value('(./IndexScan/Object/@Database)[1]', 'varchar(128)')) DatabaseName,
		convert(varchar(128),i.value('(./IndexScan/Object/@Schema)[1]', 'varchar(128)')) SchemaName,
		convert(varchar(128),i.value('(./IndexScan/Object/@Table)[1]', 'varchar(128)')) TableName,
		convert(varchar(128),i.value('(./IndexScan/Object/@Index)[1]', 'varchar(128)')) IndexName,
		convert(varchar(4000),n.value('(@StatementText)[1]', 'varchar(4000)')) sql_text,
		convert(varchar(128),i.value('(@PhysicalOp)[1]', 'varchar(128)')) PhysicalOp,
		convert(varchar(128), stuff((select distinct ', ' + cg.value('(@Column)[1]', 'varchar(128)')
		   from i.nodes('./OutputList/ColumnReference') t(cg)
		   for xml path('')),1,2,'')) output_columns,
		convert(varchar(128), stuff((select distinct ', ' + cg.value('(@Column)[1]', 'varchar(128)')
		   from i.nodes('./IndexScan/SeekPredicates/SeekPredicateNew//ColumnReference') as t(cg)
		   for xml path('')),1,2,'')) seek_columns
	from 
		(select plan_handle, query_plan
			from 
				(select distinct 
					plan_handle
				from 
					#currentReadings) qs	outer apply sys.dm_exec_query_plan(qs.plan_handle) tp
											inner join sys.databases db on db.database_id = tp.dbid
											where db.state_desc = 'ONLINE'
					) tab (plan_handle, query_plan)
					inner join sys.dm_exec_cached_plans cp on tab.plan_handle = cp.plan_handle
					cross apply query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/*') q(n)
					cross apply n.nodes('.//RelOp[IndexScan[@Lookup="1"] and IndexScan/Object[@Schema!="[sys]"]]') s(i)

	if @@rowcount <> 0
	begin

		insert #SSL_Message select 75, RecordID, 1, convert(varchar, DatabaseName) from #KeyLookups
		insert #SSL_Message select 75, RecordID, 2, convert(varchar, SchemaName) from #KeyLookups
		insert #SSL_Message select 75, RecordID, 3, convert(varchar, TableName) from #KeyLookups
		insert #SSL_Message select 75, RecordID, 4, convert(varchar, IndexName)  from #KeyLookups
		insert #SSL_Message select 75, RecordID, 5, replace(replace(sql_text, char(13), ' '), char(10), ' ') from #KeyLookups
		insert #SSL_Message select 75, RecordID, 6, convert(varchar, PhysicalOp) from #KeyLookups
		insert #SSL_Message select 75, RecordID, 7, convert(varchar, output_columns) from #KeyLookups
		insert #SSL_Message select 75, RecordID, 8, convert(varchar, seek_columns) from #KeyLookups

	end
	
	if lower($(CheckImplicitPlans)) = 'y'
	begin

		--declare @DatabaseName sysname
		--declare @Cmd nvarchar(max)


		if object_id('tempdb..#ImplicitResults') is not null
			drop table #ImplicitResults

		if object_id('tempdb..#QueryPlans') is not null
			drop table #QueryPlans

		create table #ImplicitResults
		(
			RecordID int identity(1,1)
			,DatabaseName sysname
			,StatementText nvarchar(max)
			,SchemaName sysname
			,TableName sysname
			,ColumnName sysname
			,[From] varchar(100)
			,[Length] int
			,[To] varchar(100)
			,[ToLength] int
		)


		create table #QueryPlans 
		(
			PlanHandle varbinary(64)
			,AvgElapsedTime bigint
			,CreationTime datetime
		)

		-- get the top 20 slowest queries first
		insert into #QueryPlans
		select distinct top 20
			s.plan_handle,
			isnull(s.total_elapsed_time / s.execution_count, 0) as AvgElapsedTime,
			s.creation_time as LogCreatedOn
		from 
			sys.dm_exec_query_stats s
		order by
			isnull(s.total_elapsed_time / s.execution_count, 0) 
		desc

		update #AllDBs set Processed = 0

		while exists (select * from #AllDBs where Processed = 0)		
		begin

			select top 1 @DatabaseName = DatabaseName from #AllDBs where Processed = 0

			print 'Fetching details for ' + convert(varchar, @DatabaseName)

			Set @Cmd = '
			use ' + quotename(@DatabaseName) + ';
		
			set transaction isolation level read uncommitted 

			-- Now with these plans, check for any implicit conversions
			declare @dbname sysname 
			set @dbname = quotename(db_name()); 

			with xmlnamespaces 
			   (default ''http://schemas.microsoft.com/sqlserver/2004/07/showplan'') 
			insert into #ImplicitResults
			select 
				@dbname,
				stmt.value(''(@StatementText)[1]'', ''varchar(max)'') as StatementText, 
				t.value(''(ScalarOperator/Identifier/ColumnReference/@Schema)[1]'', ''varchar(128)'') as SchemaName, 
				t.value(''(ScalarOperator/Identifier/ColumnReference/@Table)[1]'', ''varchar(128)'') as TableName, 
				t.value(''(ScalarOperator/Identifier/ColumnReference/@Column)[1]'', ''varchar(128)'') as ColumnName, 
				ic.DATA_TYPE as [From], 
				ic.CHARACTER_MAXIMUM_LENGTH as [Length], 
				t.value(''(@DataType)[1]'', ''varchar(128)'') as [To], 
				t.value(''(@Length)[1]'', ''int'') as [ToLength] 
			FROM 
				#QueryPlans as cp 
				cross apply sys.dm_exec_query_plan(PlanHandle) as qp 
				cross apply query_plan.nodes(''/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple'') as batch(stmt) 
				cross apply stmt.nodes(''.//Convert[@Implicit="1"]'') as n(t) 
				inner join INFORMATION_SCHEMA.COLUMNS as ic 
					on quotename(ic.TABLE_SCHEMA) = t.value(''(ScalarOperator/Identifier/ColumnReference/@Schema)[1]'', ''varchar(128)'') 
					and quotename(ic.TABLE_NAME) = t.value(''(ScalarOperator/Identifier/ColumnReference/@Table)[1]'', ''varchar(128)'') 
					and ic.COLUMN_NAME = t.value(''(ScalarOperator/Identifier/ColumnReference/@Column)[1]'', ''varchar(128)'') 
			where 
				t.exist(''ScalarOperator/Identifier/ColumnReference[@Database=sql:variable("@dbname")][@Schema!="[sys]"]'') = 1'

			exec sp_executesql @Cmd;

			update #AllDBs set Processed = 1 where DatabaseName = @DatabaseName

		end;

		--select * from #ImplicitResults

		if (select count(1) from #ImplicitResults) > 0
		begin	
			insert #SSL_Message select 76, RecordID, 1, convert(varchar, DatabaseName) from #ImplicitResults
			insert #SSL_Message select 76, RecordID, 2, convert(nvarchar, left(replace(replace(StatementText, char(13), ''), char(10), ''), 4000)) from #ImplicitResults
			insert #SSL_Message select 76, RecordID, 3, convert(varchar, SchemaName)  from #ImplicitResults
			insert #SSL_Message select 76, RecordID, 4, convert(varchar, TableName) from #ImplicitResults
			insert #SSL_Message select 76, RecordID, 5, convert(varchar, ColumnName) from #ImplicitResults
			insert #SSL_Message select 76, RecordID, 6, convert(varchar, [From]) from #ImplicitResults
			insert #SSL_Message select 76, RecordID, 7, convert(varchar, [Length]) from #ImplicitResults
			insert #SSL_Message select 76, RecordID, 8, convert(varchar, [To]) from #ImplicitResults
			insert #SSL_Message select 76, RecordID, 9, convert(varchar, [ToLength]) from #ImplicitResults
		end

	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Checking for unused indexes...'
begin
	
	if object_id('tempdb..#UnusedIndexes') is not null
			drop table #UnusedIndexes

	create table #UnusedIndexes
	(
		RecordID			int identity(1,1)
		,DatabaseName		sysname
		,ObjectName			sysname
		,IndexName			sysname
		,IndexID			int
		,Reads				int
		,Writes				int
	)

	
	-- filter out system databases, and reset all others to show not processed
	update #DatabaseNames set Processed = case when DatabaseName in ('[msdb]','[tempdb]','[master]') then 1	else 0 end


	while exists (select * from #DatabaseNames where Processed = 0)
	begin

		select top 1 @DatabaseName = DatabaseName from #DatabaseNames where Processed = 0 order by DatabaseName

		--print 'Fetching details for ' + convert(varchar, @DatabaseName)

		Set @Cmd = 'use [' + @DatabaseName + '];
		
		set transaction isolation level read uncommitted
		
		insert into #UnusedIndexes	
		select top 100 
			db_name(db_id())
			,object_name(s.[object_id]) 
			,i.[name] 
			,i.index_id
			,user_seeks + user_scans + user_lookups 
			,user_updates 
		from   
			sys.dm_db_index_usage_stats s 
			inner join sys.indexes i on i.[object_id] = s.[object_id] and i.index_id = s.index_id 
		where  
			objectproperty(s.[object_id],''IsUserTable'') = 1
			and s.database_id = db_id()  -- Primary Keys not included
			and i.Name is not null
			and db_name(db_id()) not in (''tempdb'',''master'',''model'',''msdb'',''ReportServer'',''ReportServerTempDB'')
		order by
			user_updates / (user_seeks + user_scans + user_lookups + 1) desc'
		
		exec sp_executesql @Cmd;

		update #DatabaseNames set Processed = 1 where DatabaseName = @DatabaseName

	end;


	if exists (select 1 from #UnusedIndexes)
	begin	
		insert #SSL_Message select 77, RecordID, 1, convert(varchar(128), DatabaseName) from #UnusedIndexes
		insert #SSL_Message select 77, RecordID, 2, convert(varchar(128), ObjectName) from #UnusedIndexes
		insert #SSL_Message select 77, RecordID, 3, convert(varchar(128), IndexName)  from #UnusedIndexes
		insert #SSL_Message select 77, RecordID, 4, convert(varchar(128), IndexID) from #UnusedIndexes
		insert #SSL_Message select 77, RecordID, 5, convert(varchar(128), Reads) from #UnusedIndexes
		insert #SSL_Message select 77, RecordID, 6, convert(varchar(128), Writes) from #UnusedIndexes
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Checking for duplicate indexes...'
begin


	if object_id('tempdb..#DuplicateIndexes') is not null
		drop table #DuplicateIndexes

	create table #DuplicateIndexes
	(
		RecordID			int identity(1,1)
		,DatabaseName		sysname
		,SchemaName			sysname
		,TableName			sysname
		,IndexName			sysname
		,Writes				bigint
		,OverlappingIndex	nvarchar(128)
		,Col1				nvarchar(128)
		,Col2				nvarchar(128)
		,Col3				nvarchar(128)
		,Col4				nvarchar(128)
		,Col5				nvarchar(128)
		,Col6				nvarchar(128)
		,Col7				nvarchar(128)
		,Col8				nvarchar(128)
		,Col9				nvarchar(128)
		,Col10				nvarchar(128)
		,Col11				nvarchar(128)
		,Col12				nvarchar(128)
		,Col13				nvarchar(128)
		,Col14				nvarchar(128)
		,Col15				nvarchar(128)
		,Col16				nvarchar(128)
	)

	update #DatabaseNames set Processed = 0
	
	while exists (select * from #DatabaseNames where Processed = 0)	
	begin

		select top 1 @DatabaseName = DatabaseName from #DatabaseNames where Processed = 0
		--print 'Fetching details for ' + convert(varchar, @DatabaseName)

		Set @Cmd = '
		use [' + @DatabaseName + ']
		
		;with Duplicates as 
		(select 
			Sch.[name] SchemaName
			,Obj.[name] TableName
			,Idx.[name] IndexName
			,iu.user_updates + iu.system_updates Writes
			,index_col(Sch.[name] + ''.'' + Obj.[name], Idx.index_id, 1) Col1
			,index_col(Sch.[name] + ''.'' + Obj.[name], Idx.index_id, 2) Col2
			,index_col(Sch.[name] + ''.'' + Obj.[name], Idx.index_id, 3) Col3
			,index_col(Sch.[name] + ''.'' + Obj.[name], Idx.index_id, 4) Col4
			,index_col(Sch.[name] + ''.'' + Obj.[name], Idx.index_id, 5) Col5
			,index_col(Sch.[name] + ''.'' + Obj.[name], Idx.index_id, 6) Col6
			,index_col(Sch.[name] + ''.'' + Obj.[name], Idx.index_id, 7) Col7
			,index_col(Sch.[name] + ''.'' + Obj.[name], Idx.index_id, 8) Col8
			,index_col(Sch.[name] + ''.'' + Obj.[name], Idx.index_id, 9) Col9
			,index_col(Sch.[name] + ''.'' + Obj.[name], Idx.index_id, 10) Col10
			,index_col(Sch.[name] + ''.'' + Obj.[name], Idx.index_id, 11) Col11
			,index_col(Sch.[name] + ''.'' + Obj.[name], Idx.index_id, 12) Col12
			,index_col(Sch.[name] + ''.'' + Obj.[name], Idx.index_id, 13) Col13
			,index_col(Sch.[name] + ''.'' + Obj.[name], Idx.index_id, 14) Col14
			,index_col(Sch.[name] + ''.'' + Obj.[name], Idx.index_id, 15) Col15
			,index_col(Sch.[name] + ''.'' + Obj.[name], Idx.index_id, 16) Col16
		from 
			sys.indexes Idx
			inner join sys.objects Obj on Idx.object_id = Obj.object_id
			inner join sys.schemas Sch on Sch.schema_id = Obj.schema_id
			left outer join sys.dm_db_index_usage_stats iu on Idx.object_id = iu.object_id and Idx.index_id = iu.index_id
		where 
			iu.index_id > 0)

		insert into #DuplicateIndexes
		select	
				db_name(db_id()) 
				,d1.SchemaName
				,d1.TableName
				,d1.IndexName
				,d1.Writes
				,d2.IndexName OverLappingIndex,
				d1.Col1, d1.Col2, d1.Col3, d1.Col4, 
				d1.Col5, d1.Col6, d1.Col7, d1.Col8, 
				d1.Col9, d1.Col10, d1.Col11, d1.Col12, 
				d1.Col13, d1.Col14, d1.Col15, d1.Col16
		from 
			Duplicates d1
			inner join Duplicates d2 on d1.TableName = d2.TableName	
				and d1.IndexName <> d2.IndexName
				and d1.Col1 = d2.Col1
			and (d1.Col2 is null or d2.Col2 is null or d1.Col2 = d2.Col2)
			and (d1.Col3 is null or d2.Col3 is null or d1.Col3 = d2.Col3)
			and (d1.Col4 is null or d2.Col4 is null or d1.Col4 = d2.Col4)
			and (d1.Col5 is null or d2.Col5 is null or d1.Col5 = d2.Col5)
			and (d1.Col6 is null or d2.Col6 is null or d1.Col6 = d2.Col6)
			and (d1.Col7 is null or d2.Col7 is null or d1.Col7 = d2.Col7)
			and (d1.Col8 is null or d2.Col8 is null or d1.Col8 = d2.Col8)
			and (d1.Col9 is null or d2.Col9 is null or d1.Col9 = d2.Col9)
			and (d1.Col10 is null or d2.Col10 is null or d1.Col10 = d2.Col10)
			and (d1.Col11 is null or d2.Col11 is null or d1.Col11 = d2.Col11)
			and (d1.Col12 is null or d2.Col12 is null or d1.Col12 = d2.Col12)
			and (d1.Col13 is null or d2.Col13 is null or d1.Col13 = d2.Col13)
			and (d1.Col14 is null or d2.Col14 is null or d1.Col14 = d2.Col14)
			and (d1.Col15 is null or d2.Col15 is null or d1.Col15 = d2.Col15)
			and (d1.Col16 is null or d2.Col16 is null or d1.Col16 = d2.Col16)
		order by
			d1.SchemaName
			,d1.TableName
			,d1.IndexName'


			exec sp_executesql @Cmd;

			update #DatabaseNames set Processed = 1 where DatabaseName = @DatabaseName

		end;

		--select * from #DuplicateIndexes

		if exists (select * from #DuplicateIndexes)
		begin
			insert #SSL_Message select 78, RecordID, 1, convert(varchar, DatabaseName) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 2, convert(varchar, SchemaName) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 3, convert(varchar, TableName) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 4, convert(varchar, IndexName) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 5, convert(varchar, Writes) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 6, convert(varchar, OverlappingIndex) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 7, convert(varchar, Col1) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 8, convert(varchar, Col2) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 9, convert(varchar, Col3) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 10, convert(varchar, Col4) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 11, convert(varchar, Col5) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 12, convert(varchar, Col6) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 13, convert(varchar, Col7) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 14, convert(varchar, Col8) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 15, convert(varchar, Col9) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 16, convert(varchar, Col10) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 17, convert(varchar, Col11) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 18, convert(varchar, Col12) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 19, convert(varchar, Col13) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 20, convert(varchar, Col14) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 21, convert(varchar, Col15) from #DuplicateIndexes
			insert #SSL_Message select 78, RecordID, 22, convert(varchar, Col16) from #DuplicateIndexes
		end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Checking when indexes were last rebuilt...'
begin

	if object_id('tempdb..#LastRebuiltIndexes') is not null
		drop table #LastRebuiltIndexes

	create table #LastRebuiltIndexes
	(
		RecordID			int identity(1,1)
		,DatabaseName		sysname
		,LatestRebuildDate	datetime
	)

	update #DatabaseNames set Processed = 0
	
	while exists (select * from #DatabaseNames where Processed = 0)	
	begin

		select top 1 @DatabaseName = DatabaseName from #DatabaseNames where Processed = 0

		Set @Cmd = '
		use [' + @DatabaseName + '];
		insert into #LastRebuiltIndexes
		select 
			db_name(db_id())
			,max(isnull(stats_date(object_id, stats_id), ''1900-01-01'')) as LastIndexRebuild
		from		 
			sys.stats
		where 
			left(name,4)!= ''_WA_'''
	
		exec sp_executesql @Cmd
	
		update #DatabaseNames set Processed = 1 where DatabaseName = @DatabaseName

	end

	if exists (select * from #LastRebuiltIndexes)
	begin
		insert #SSL_Message select 79, RecordID, 1, convert(varchar, DatabaseName) from #LastRebuiltIndexes
		insert #SSL_Message select 79, RecordID, 2, convert(varchar, LatestRebuildDate) from #LastRebuiltIndexes
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

print 'Checking for single use adhoc plans...'
begin

	declare @SingleUsePlans table
	(
		PlanCount bigint
		,MemoryMB decimal(38,0)
	)


	insert into @SingleUsePlans
	select  
		count(*) as PlanCount
		,sum(convert(decimal(38,0), cp.size_in_bytes)) / 1024 / 1024 as MemoryMB
	from    
		sys.dm_exec_cached_plans cp
	where   
		cp.usecounts = 1
		and cp.objtype = 'Adhoc'
		and exists (select	1 from sys.configurations where	name = 'optimize for ad hoc workloads' and value_in_use = 0)
	having  
		count(*) > 1;

	if @@rowcount > 0
	begin
		insert into #SSL_KVP select 'SingleUsePlansCount', convert(varchar, PlanCount) from @SingleUsePlans
		insert into #SSL_KVP select 'SingleUsePlansMB', convert(varchar, MemoryMB) from @SingleUsePlans
	end
	else
	begin
		insert into #SSL_KVP select 'SingleUsePlansCount', '0' 
		insert into #SSL_KVP select 'SingleUsePlansMB', '0'
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Checking Virtual Log Files...'
begin

	declare @query varchar(max)  
	declare @vlfs int  
	declare @databases table (dbname sysname)  
	declare @dbname sysname
	declare @MajorVersion tinyint  

	--table variable to hold results  
	declare @vlfcounts table  
	(
		RecordID int identity(1,1)
		,dbname sysname
		,vlfcount int
	)  

	insert into @databases 
	select 
		name 
	from 
		sys.databases s
	where 
		[state] = 0  

	set @MajorVersion = left(cast(serverproperty('productversion') as nvarchar(max)),charindex('.',cast(serverproperty('productversion') as nvarchar(max)))-1) 
 
	if @MajorVersion < 11 -- pre-SQL2012 
	begin 
		declare @dbccloginfo table  
		(  
			fileid tinyint,  
			file_size bigint,  
			start_offset bigint,  
			fseqno int,  
			[status] tinyint,  
			parity tinyint,  
			create_lsn numeric(25,0)  
		)  
  
		while exists(select top 1 dbname from @databases)  
		begin  
  
			set @dbname = (select top 1 dbname from @databases)  
			set @query = 'dbcc loginfo ([' + @dbname + '])'  
  
			insert into @dbccloginfo  
			exec (@query)  
  
			set @vlfs = @@rowcount  
  
			insert @vlfcounts  
			values(@dbname, @vlfs)  
  
			delete from @databases where dbname = @dbname
  
		end 
	end 
	else 
	begin 
		declare @dbccloginfo2012 table  
		(  
			RecoveryUnitId int, 
			fileid tinyint,  
			file_size bigint,  
			start_offset bigint,  
			fseqno int,  
			[status] tinyint,  
			parity tinyint,  
			create_lsn numeric(25,0)  
		)  
  
		while exists(select top 1 dbname from @databases)  
		begin  
  
			set @dbname = (select top 1 dbname from @databases)  
			set @query = 'dbcc loginfo ([' + @dbname + ']) '  

			insert into @dbccloginfo2012  
			exec (@query)  

			set @vlfs = @@rowcount  

			insert @vlfcounts  
			values(@dbname, @vlfs)  

			delete from @databases where dbname = @dbname
  
		end 
	end 
  
	--output the full list  
	if exists (select * from @vlfcounts)
	begin
		insert #SSL_Message select 80, RecordID, 1, convert(varchar, dbname) from @vlfcounts
		insert #SSL_Message select 80, RecordID, 2, convert(varchar, vlfcount) from @vlfcounts
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Getting Disk Cluster Size...'
if upper ($(UsePowerShell)) = 'Y'
begin

	declare @PowerShellResult table
	(
		ResultLine varchar(255)
	)

	declare @RawVolumes table
	(
		VolumeInfo xml
	)

	declare @Volumes table
	(
		RecordID int identity(1,1)
		,DriveLetter varchar(3)
		,ClusterSize varchar(20)
	)


	declare @XmlText varchar(max)

	declare @PowerShellCmd varchar(1000)
	declare @DrivesWeCareAboutALot table
	(
		DriveLetter char(3)
	)

	insert into @DrivesWeCareAboutALot

	-- sys.master_files 
	select distinct
		left([physical_name], 3)  as 'DriveLetter'
	from 
		sys.master_files
	union  
	-- backup drives used in the last 24 hours
	select distinct  
		left(bf.physical_device_name,3) as 'DriveLetter'
	from 
		msdb.dbo.backupmediafamily bf
		inner join msdb.dbo.backupset bs on bs.media_set_id = bf.media_set_id
	where
		bs.backup_start_date >= dateadd(hour, -24, getdate())

	set @PowerShellCmd = 'powershell.exe -command "$wql = ''SELECT Blocksize, DriveLetter, FileSystem FROM Win32_Volume where DriveType <> 5 and DriveLetter is not null''; Get-WmiObject -Query $wql -ComputerName ''.'' | Select-Object DriveLetter, BlockSize | convertTo-XML -As String"'
		insert into @PowerShellResult execute master..xp_cmdshell @PowerShellCmd
	
	select @XmlText = ''
	select @XmlText = @XmlText + ltrim(rtrim(ResultLine)) from @PowerShellResult where left(ltrim(rtrim(ResultLine)), 1) = '<'
	select @XmlText = replace(@XmlText, '&#x0;', '')

	insert into @RawVolumes
	select cast(@XmlText as xml);

	insert into @Volumes
	select
		m.c.value('(Property[@Name="DriveLetter"]/text())[1]', 'varchar(255)') as DriveLetter,
		m.c.value('(Property[@Name="BlockSize"]/text())[1]', 'varchar(15)') as ClusterSize
	from 
		@RawVolumes as v
		outer apply v.VolumeInfo.nodes('Objects/Object') as m(c)
	where
		len(m.c.value('(Property[@Name="DriveLetter"]/text())[1]', 'varchar(255)')) <= 3

	insert into #SSL_Message 
	select distinct 81 ,RecordID, 1, v.DriveLetter 
	from @Volumes v inner join @DrivesWeCareAboutALot d on left(d.DriveLetter, 2) = v.DriveLetter

	insert into #SSL_Message 
	select distinct 81 ,RecordID, 2, v.ClusterSize 
	from @Volumes v inner join @DrivesWeCareAboutALot d on left(d.DriveLetter, 2) = v.DriveLetter


	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
end


print 'Getting tempdb files and sizes..'
begin

	if object_id('tempdb..#tempdbdata') is not null
		drop table #tempdbdata

	create table #tempdbdata
	(
		RecordID		int identity(1,1)
		,PhysicalName	varchar(2000)
		,FileSize		int
	)

	insert into #tempdbdata select physical_name, size from sys.master_files where db_name(database_id) = 'tempdb'

	if @@rowcount <> 0
	begin
		insert #SSL_Message select 82, RecordID, 1, convert(nvarchar(4000), PhysicalName) from #tempdbdata
		insert #SSL_Message select 82, RecordID, 2, convert(nvarchar(4000), FileSize) from #tempdbdata
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

if convert(int, left(convert(varchar, ServerProperty('ProductVersion')),2)) >=12
begin

	print 'Checking for in-memory tables...'

	if object_id('tempdb..#MemoryTables') is not null
		drop table #MemoryTables

	create table #MemoryTables 
	(
		RecordID		int identity(1,1)
		,DatabaseName	sysname
		,TableName		sysname
	)

	update #AllDBs set Processed = 0

	while exists (select * from #AllDBs where Processed = 0)
	begin

		select top 1 @DatabaseName = DatabaseName from #AllDBs where Processed = 0

		Set @Cmd = 'use [' + @DatabaseName + '];
	
		insert into #MemoryTables
		select 
			db_name(db_id())
			,name 
		from 
			sys.tables 
		where 
			is_memory_optimized = 1'

		exec sp_executesql @Cmd;

		update #AllDBs set Processed = 1 where DatabaseName = @DatabaseName

	end;
	
	if exists (select * from #MemoryTables)
	begin
		insert #SSL_Message select 83, RecordID, 1, convert(varchar, DatabaseName) from #MemoryTables
		insert #SSL_Message select 83, RecordID, 2, convert(varchar, TableName) from #MemoryTables
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end

if convert(int, left(convert(varchar, ServerProperty('ProductVersion')),2)) >=12
begin

	print 'Checking Delayed Durability...'
	
	if object_id('tempdb..#DelayedDurability') is not null
		drop table #DelayedDurability

	create table #DelayedDurability
	(
		RecordID					int identity(1,1)
		,DatabaseName				sysname
		,DurabilityDescription		nvarchar(60)
	)


	set @Cmd = 'select name, delayed_durability_desc from sys.databases where delayed_durability_desc <> ''DISABLED'''

	insert into #DelayedDurability
	exec(@Cmd)


	if @@Rowcount<> 0
	begin
		insert #SSL_Message select 84, RecordID, 1, convert(varchar, DatabaseName) from #DelayedDurability 
		insert #SSL_Message select 84, RecordID, 2, convert(varchar, DurabilityDescription) from #DelayedDurability 
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
end


begin

	if serverproperty ('IsHadrEnabled') = 1
	begin
		print 'Finding Availability Groups...'
		if object_id('tempdb..#AGDetails') is not null
			drop table #AGDetails
		

		create table #AGDetails
		(
			RecordID			int identity(1,1)
			,GroupName			sysname
			,ReplicaServerName	nvarchar(256)
			,ReplicaRole		nvarchar(60)
			,DatabaseName		varchar(128)
			,ListenerName		varchar(128)
			,Mode				nvarchar(60)
		)

		insert into #AGDetails
		select distinct
			a.name
			,rcs.replica_server_name
			,ars.role_desc
			,c.database_name
			,l.dns_name 
			,x.availability_mode_desc 
		from
			sys.availability_groups a
			inner join sys.availability_databases_cluster c on a.group_id = c.group_id
			inner join sys.dm_hadr_availability_replica_cluster_states rcs on rcs.group_id = a.group_id
			inner join sys.dm_hadr_availability_replica_states ars on ars.replica_id = rcs.replica_id
			inner join sys.availability_replicas x on x.group_id = a.group_id
			left outer join sys.availability_group_listeners l on a.group_id = l.group_id

		if @@rowcount <> 0
		begin
			insert #SSL_message select 85, RecordID, 1, convert(varchar, GroupName) from #AGDetails
			insert #SSL_message select 85, RecordID, 2, convert(varchar, ReplicaServerName) from #AGDetails
			insert #SSL_message select 85, RecordID, 3, convert(varchar, ReplicaRole) from #AGDetails
			insert #SSL_message select 85, RecordID, 4, convert(varchar, DatabaseName) from #AGDetails
			insert #SSL_message select 85, RecordID, 5, convert(varchar, ListenerName) from #AGDetails
			insert #SSL_message select 85, RecordID, 6, convert(varchar, Mode) from #AGDetails
		end

		print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

	end

end

if convert(int, left(convert(varchar, ServerProperty('ProductVersion')),2)) >=12
begin
	
	print 'Checking for columnstore indexes...'

	if object_id('tempdb..#ColumnStoreIndexes') is not null
		drop table #ColumnStoreIndexes

	create table #ColumnStoreIndexes
	(
		RecordID		int identity(1,1)
		,DatabaseName	sysname
		,IndexCount		int
	)

	update #AllDBs set Processed = 0
	
	while exists (select * from #AllDBs where Processed = 0)
	begin

		select top 1 @DatabaseName = DatabaseName from #AllDBs where Processed = 0 order by DatabaseName 

		set @Cmd = 
		'	use [' + @DatabaseName + ']; ' + 
		'	insert into #ColumnStoreIndexes 
			select db_name(db_id()) as DatabaseName, Count(*) as IndexCount from sys.indexes where type in (5,6)'
		exec sp_executesql @Cmd

		update #AllDBs set Processed = 1 where DatabaseName = @DatabaseName
	end

	delete from #ColumnStoreIndexes where IndexCount = 0

	if exists (Select 1 from #ColumnStoreIndexes)
	begin
		insert #SSL_Message select 86, RecordID, 1, convert(varchar, DatabaseName) from #ColumnStoreIndexes
		insert #SSL_Message select 86, RecordID, 2, convert(varchar, IndexCount) from #ColumnStoreIndexes
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


if convert(int, left(convert(varchar, ServerProperty('ProductVersion')),2)) >=12
begin

	print 'Checking Database Containment...'
	
	if object_id('tempdb..#DatabaseContainment') is not null
		drop table #DatabaseContainment

	create table #DatabaseContainment
	(
		RecordID					int identity(1,1)
		,DatabaseName				sysname
		,ContainmentDesc			nvarchar(60)
	)

	set @Cmd = 'select name, containment_desc from sys.databases where containment <> 0'

	insert into #DatabaseContainment
	exec(@Cmd)


	if @@Rowcount<> 0
	begin
		insert #SSL_Message select 87, RecordID, 1, convert(varchar(128), DatabaseName) from #DatabaseContainment 
		insert #SSL_Message select 87, RecordID, 2, convert(varchar, ContainmentDesc) from #DatabaseContainment 
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)
end





begin	

	if object_id('tempdb..#UserDefinedRoles') is not null
		drop table #UserDefinedRoles

	create table #UserDefinedRoles
	(
		RecordID	int identity(1,1)
		,RoleName	sysname
	)

	set @MajorVersion = left(cast(serverproperty('productversion') as nvarchar(max)),charindex('.',cast(serverproperty('productversion') as nvarchar(max)))-1) 

	if @MajorVersion >= 11
	begin
		
		print 'Checking User Defined Roles...'
		
		set @Cmd = 'set nocount on; insert into #UserDefinedRoles select name from sys.server_principals where type_desc = ''SERVER_ROLE'' and name <> ''public'' and is_fixed_role = 0'
	
		exec sp_executesql @Cmd

		if @@Rowcount<> 0
		begin
			insert #SSL_Message select 88, RecordID, 1, convert(varchar(128), RoleName) from #UserDefinedRoles 
		end

	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


--------------------------------------------------------------------------------
-- SQL Configuration: Policy Based Management
--------------------------------------------------------------------------------
begin
	set nocount on
	
	print 'Geting Policy Based Management details...'
		
	if object_id('tempdb..#SSL_SystemPolicies') is not null
		drop table #SSL_SystemPolicies


	create table #SSL_SystemPolicies
	(
		RecordID	int		identity(1,1),
		PolicyName	sysname		not null,
		IsEnabled	varchar(30)	not null,
		ExecutionMode	varchar(30)	not null,
		LastResult	varchar(30)	not null,
		LastRunDate	datetime	null
	);

	insert
		#SSL_SystemPolicies
	(
		PolicyName,
		IsEnabled,
		ExecutionMode,
		LastResult,
		LastRunDate
	)			
	select	
		p.name, 
		case 
			when p.is_enabled = 1 then 'Enabled'
			when p.is_enabled = 0 and p.execution_mode = 0 then 'Disabled (OnDemand)'
			when p.is_enabled = 0 and p.execution_mode <> 0 then 'Disabled'
		end,
		case p.execution_mode
			when 0 then 'OnDemand'
			when 1 then 'OnChange:Prevent'
			when 2 then 'OnChange:LogOnly'
			when 4 then 'OnSchedule'
		end, 
		case
			when ps.result = 0 then 'Critical'
			when ps.result = 1 then 'Successful'
			when ps.result is null and max(ph.start_date) is null then 'Not run'
			when ps.result is null and max(ph.start_date) is not null and p.execution_mode <> 0 then 'Successful'
			when ps.result is null and p.execution_mode = 0 then 'N/A'
		end, 
		max(ph.start_date)
	from 
		msdb.dbo.syspolicy_policies p 
		left outer join msdb.dbo.syspolicy_policy_execution_history ph 
			on p.policy_id = ph.policy_id
		left outer join msdb.dbo.syspolicy_system_health_state ps 
			on p.policy_id = ps.policy_id
	group by 
		p.policy_id, 
		p.name, 
		p.is_enabled, 
		p.execution_mode, 
		ph.policy_id, 
		ps.result;
			
	-- now denorm out - type 89
	insert #SSL_Message select 89, RecordID, 1, PolicyName from #SSL_SystemPolicies;
	insert #SSL_Message select 89, RecordID, 2, IsEnabled from #SSL_SystemPolicies;
	insert #SSL_Message select 89, RecordID, 3, ExecutionMode from #SSL_SystemPolicies;
	insert #SSL_Message select 89, RecordID, 4, LastResult from #SSL_SystemPolicies;
	insert #SSL_Message select 89, RecordID, 5, convert(varchar(30), LastRunDate, 120) from #SSL_SystemPolicies;
			

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


begin

	print 'Checking for non-production databases...'

	if object_id('tempdb..#NonProdDBs') is not null
		drop table #NonProdDBs

	create table #NonProdDBs
	(
		RecordID		int	identity(1,1),
		DatabaseName	sysname
	)

	insert into #NonProdDBs
	select	
		DatabaseName 
	from	
		#AllDBs
	where
		(upper(DatabaseName) like '%TEST%'
		or upper(DatabaseName) like '%DEV%'
		or upper(DatabaseName) like '%UAT%'
		or upper(DatabaseName) like '%OLD%'
		or upper(DatabaseName) = 'pubs'
		or upper(DatabaseName) = 'northwind'
		or upper(DatabaseName) like 'adventureworks%')
	order by
		DatabaseName

	if @@rowcount <> 0
	begin
		insert #SSL_Message select 90, RecordID, 1, DatabaseName from #NonProdDBs
	end


	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Getting CPU Usage for last 60 and 120 minutes...'

begin

	declare @now bigint 
	select @now = cpu_ticks/(cpu_ticks/ms_ticks) from sys.dm_os_sys_info

	if object_id('tempdb..#CPUdata') is not null
		drop table #CPUdata

	create table #CPUdata
	(
		RecordID				int identity(1,1)
		,Recorded				datetime 
		,SQLProcessCPU			tinyint
		,SystemCPU				tinyint
	)
		
	insert into #CPUdata
	select 
		dateadd(ms, -1 * (@now - [timestamp]), getdate()) 
		,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]','int') 
		,100-record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
	from 
		(select 
			[timestamp]
			,convert(xml, record) as [record]
		from 
			sys.dm_os_ring_buffers
		where 
			ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
			and record like N'%<SystemHealth>%') as x
	where
		dateadd(ms, -1 * (@now - [timestamp]), getdate())  > dateadd(minute, -120, getdate())
	
	insert #SSL_Message select 91, RecordID, 1, convert(varchar, Recorded) from #CPUdata
	insert #SSL_Message select 91, RecordID, 2, convert(varchar, SQLProcessCPU) from #CPUdata
	insert #SSL_Message select 91, RecordID, 3, convert(varchar, SystemCPU) from #CPUdata


	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Getting Enterprise Features...'
begin

	if object_id('tempdb..#EnterpriseFeatures') is not null
		drop table #EnterpriseFeatures

	create table #EnterpriseFeatures
	(
		RecordID		int identity(1,1)
		,DatabaseName	sysname
		,FeatureName	sysname
	)

	update #DatabaseNames set Processed = 0
	
	while exists (select * from #DatabaseNames where Processed = 0)
	begin

		select top 1 @DatabaseName = DatabaseName from #DatabaseNames where Processed = 0 order by DatabaseName 

		set @Cmd = 
		'	use [' + @DatabaseName + ']; ' + 
		'	insert into #EnterpriseFeatures 
			select db_name(db_id()) as DatabaseName, feature_name as FeatureName from sys.dm_db_persisted_sku_features'
		exec sp_executesql @Cmd

		update #DatabaseNames set Processed = 1 where DatabaseName = @DatabaseName

	end

	if exists (Select 1 from #EnterpriseFeatures)
	begin
		insert #SSL_Message select 92, RecordID, 1, convert(varchar, DatabaseName) from #EnterpriseFeatures
		insert #SSL_Message select 92, RecordID, 2, convert(varchar, FeatureName) from #EnterpriseFeatures
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Checking SQL Alerts...'
begin

	if object_id('tempdb..#SQLAlerts') is not null
		drop table #SQLAlerts

	create table #SQLAlerts
	(
		RecordID		int identity(1,1)
		,AlertName		sysname
		,Severity		int
		,IsEnabled		bit
	)


	insert into #SQLAlerts 
	select 
		name
		,severity
		,[enabled]
	from 
		msdb.dbo.sysalerts
	where
		severity in (19,20,21,22,23,24,25)


	if exists (Select 1 from #SQLAlerts)
	begin
		insert #SSL_Message select 93, RecordID, 1, convert(varchar, AlertName) from #SQLAlerts
		insert #SSL_Message select 93, RecordID, 2, convert(varchar, Severity) from #SQLAlerts
		insert #SSL_Message select 93, RecordID, 3, convert(varchar, IsEnabled) from #SQLAlerts
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Checking for database compression...'
begin

	if object_id('tempdb..#DatabaseCompression') is not null
		drop table #DatabaseCompression

	create table #DatabaseCompression
	(
		RecordID			int identity(1,1)
		,DatabaseName		sysname
		,CompressionDesc	nvarchar(60)
	)

	update #DatabaseNames set Processed = 0
	
	while exists (select * from #DatabaseNames where Processed = 0)
	begin

		select top 1 @DatabaseName = DatabaseName from #DatabaseNames where Processed = 0 order by DatabaseName 

		set @Cmd = 
		'	use [' + @DatabaseName + ']; ' + 
		'	insert into #DatabaseCompression
			select distinct
				db_name()
				,[data_compression_desc] 
			from 
				sys.partitions 
				inner join sys.objects on sys.partitions.object_id = sys.objects.object_id 
			where 
				data_compression > 0 
				and lower(schema_name(sys.objects.schema_id)) <> ''sys'''

		exec sp_executesql @Cmd

		update #DatabaseNames set Processed = 1 where DatabaseName = @DatabaseName

	end

	if exists (Select 1 from #DatabaseCompression)
	begin
		insert #SSL_Message select 96, RecordID, 1, convert(varchar, DatabaseName) from #DatabaseCompression
		insert #SSL_Message select 96, RecordID, 2, convert(nvarchar, CompressionDesc) from #DatabaseCompression
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


print 'Getting procedures set to autostart...'
begin

	if object_id('tempdb..#ProcsThatAutoStart') is not null
		drop table #ProcsThatAutoStart

	create table #ProcsThatAutoStart
	(
		RecordID			int identity(1,1)
		,ProcedureName		sysname
	)

	
	insert into #ProcsThatAutoStart
	select 
		name
	from 
		master.sys.procedures
	where 
		is_auto_executed = 1
	
	if @@rowcount <> 0
	begin
		insert #SSL_Message select 97, RecordID, 1, convert(nvarchar, ProcedureName) from #ProcsThatAutoStart
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end


begin

	print 'Getting Full Text Indexes (if there are any)...'

	if object_id('tempdb..#FTIndexes') is not null
		drop table #FTIndexes

	create table #FTIndexes
	(
		RecordID			int identity(1,1)
		,DatabaseName		sysname
		,TableName			sysname
		,FTCatalogName		sysname
		,UniqueIdxName		sysname
		,ColumnName			sysname
	)


	update #AllDBs set Processed = 0
	
	while exists (select * from #AllDBs where Processed = 0)
	begin

		select top 1 @DatabaseName = DatabaseName from #AllDBs where Processed = 0 order by DatabaseName 

		set @Cmd = 
		'	use [' + @DatabaseName + ']; ' + 
		'insert into #FTIndexes
		select 
			db_name(db_id()),
			t.name TableName, 
			c.name FTCatalogName,
			i.name UniqueIdxName,
			cl.name ColumnName
		from 
			sys.tables t 
			inner join sys.fulltext_indexes fi on t.object_id = fi.object_id 
			inner join sys.fulltext_index_columns ic on ic.object_id = t.object_id
			inner join sys.columns cl on ic.column_id = cl.column_id and ic.object_id = cl.object_id
			inner join sys.fulltext_catalogs c on fi.fulltext_catalog_id = c.fulltext_catalog_id
			inner join sys.indexes i on fi.unique_index_id = i.index_id and fi.object_id = i.object_id;'


		exec sp_executesql @Cmd

		update #AllDBs set Processed = 1 where DatabaseName = @DatabaseName

	end

	if exists (select * from #FTIndexes)
	begin
		insert #SSL_Message select 98, RecordID, 1, convert(nvarchar, DatabaseName) from #FTIndexes
		insert #SSL_Message select 98, RecordID, 2, convert(nvarchar, TableName) from #FTIndexes
		insert #SSL_Message select 98, RecordID, 3, convert(nvarchar, FTCatalogName) from #FTIndexes
		insert #SSL_Message select 98, RecordID, 4, convert(nvarchar, UniqueIdxName) from #FTIndexes
		insert #SSL_Message select 98, RecordID, 5, convert(nvarchar, ColumnName) from #FTIndexes
	end

	
	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)


end

print 'Looking for any logins withoug a password policy set...'
begin

	declare @Logins table
	(
		RecordID	int identity(1,1)
		,LoginName	varchar(128)
	)
	
	insert into @Logins 
	select 
		Name
	from 
		sys.sql_logins
	where
		is_policy_checked = 0
		and name not in ('##MS_PolicySigningCertificate##','##MS_SmoExtendedSigningCertificate##')

	if @@rowcount <> 0
	begin
		insert #SSL_Message select 99, RecordID, 1, LoginName from @Logins
	end

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end




print 'Examining replication details (if any replication present)...'
begin


	if object_id('tempdb..#tmp_replication') is not null
		drop table #tmp_replication

	-- Get Publisher and Subscriber
	create table #tmp_replication 
	( 
		RecordID				int identity(1,1),
		ArticleName				varchar(128),
		PublisherName			varchar(128), 
		SubscriberServerName	varchar(128)
	) 

	exec master..sp_MSforeachdb  
	'use [?]; 
	if databasepropertyex ( db_name() , ''IsPublished'' ) = 1 
	insert into #tmp_replication
	select  distinct
		case when ltrim(rtrim(isnull(sa.description, ''''))) = '''' then ''No Article Name set'' else sa.description end
		,sp.name as PublisherName 
		,upper(srv.srvname) as SubscriberServerName 
	from 
		dbo.syspublications sp  
		join dbo.sysarticles sa on sp.pubid = sa.pubid 
		join dbo.syssubscriptions s on sa.artid = s.artid 
		join master.dbo.sysservers srv on s.srvid = srv.srvid' 

	if exists (select * from #tmp_replication)
	begin
		insert #SSL_Message select 100, RecordID, 1, ArticleName from #tmp_replication
		insert #SSL_Message select 100, RecordID, 2, PublisherName from #tmp_replication
		insert #SSL_Message select 100, RecordID, 3, SubscriberServerName from #tmp_replication
	end

	if object_id('tempdb..#tmp_replication') is not null
		drop table #tmp_replication

	print 'Done! ' + 'time : ' + convert(varchar, getdate(), 120)

end




-- finally, insert the closing message time
insert #SSL_Message select 1, 1, 9, convert(varchar(30), getdate(), 120); 


-- clean up the KVP data:  If we have not managed to get it, log it as '!Not Collected!'
update #SSL_KVP set KeyValue = '!Not Collected!' 
where 
	KeyValue is null 
	or KeyValue = 'NULL'
	or ltrim(rtrim(KeyValue)) = ''


-- now get the data from the Kvp and Svr tables
insert #SSL_Message select 2, RecordID, 1, KeyName from #SSL_KVP;
insert #SSL_Message select 2, RecordID, 2, KeyValue from #SSL_KVP;

-- and the Single Value Records
insert #SSL_Message select MessageTypeID, RecordID, 1, KeyValue from #SSL_Svr;


-- now return the rows
select 
	s2.KeyValue as CustomerCode, 
	serverproperty('servername') as ServerName, 
	s1.MessageTypeID,
	s1.MessageID,
	s1.KeyID,
	s1.KeyValue 
from 
	#SSL_Message s1
	inner join #SSL_Message s2 on s2.MessageTypeID = 1 and s2.MessageID = 1 and s2.KeyID = 1
order by
	s1.MessageTypeID 




--------------------------------------------------------------------------------
-- Drop Working Temp Tables
--------------------------------------------------------------------------------

begin

	print 'Cleaning up Temp Tables...'

	if object_id('tempdb..#SSL_Message') is not null
		drop table #SSL_Message

	if object_id('tempdb..#SSL_KVP') is not null
		drop table #SSL_KVP

	if object_id('tempdb..#SSL_Svr') is not null
		drop table #SSL_Svr

	if object_id('tempdb..#SSL_Counter') is not null
		drop table #SSL_Counter

	if object_id('tempdb..#SSL_DatabaseFiles') is not null
		drop table #SSL_DatabaseFiles

	if object_id('tempdb..#SSL_LastBackupLogs') is not null
		drop table #SSL_LastBackupLogs

	if object_id('tempdb..#SSL_LastBackups') is not null
		drop table #SSL_LastBackups

	if object_id('tempdb..#SSL_MSVer') is not null
		drop table #SSL_MSVer

	if object_id('tempdb..#SSL_DiskDrives') is not null
		drop table #SSL_DiskDrives

	if object_id('tempdb..#SSL_StartUpParameters') is not null
		drop table #SSL_StartUpParameters

	if object_id('tempdb..#SSL_Configuration') is not null
		drop table #SSL_Configuration

	if object_id('tempdb..#SSL_DBMailStatus') is not null
		drop table #SSL_DBMailStatus

	if object_id('tempdb..#SSL_BlankPasswords') is not null
		drop table #SSL_BlankPasswords

	if object_id('tempdb..#SSL_BuiltInAdmin') is not null
		drop table #SSL_BuiltInAdmin

	if object_id('tempdb..#SSL_NetStart') is not null
		drop table #SSL_NetStart

	if object_id('tempdb..#SSL_FailedJobs') is not null
		drop table #SSL_FailedJobs

	if object_id('tempdb..#SSL_Databases') is not null
		drop table #SSL_Databases

	if object_id('tempdb..#SSL_SystemInfo') is not null
		drop table #SSL_SystemInfo

	if object_id('tempdb..#UserDBSizing') is not null
		drop table #UserDBSizing

	if object_id('tempdb..#UserDatabases') is not null
		drop table #UserDatabases

	if object_id('tempdb..#TempForFileStats') is not null
		drop table #TempForFileStats

	if object_id('tempdb..#TempForDataFile') is not null
		drop table #TempForDataFile

	if object_id('tempdb..#TempForLogFile') is not null
		drop table #TempForLogFile

	if object_id('tempdb..#DBTable') is not null
		drop table #DBTable

	if object_id('tempdb..#GuestDatabases') is not null
		drop table #GuestDatabases

	if object_id('tempdb..#Registry') is not null
		drop table #Registry

	if object_id('tempdb..#JobsOwnedByUsers') is not null
		drop table #JobsOwnedByUsers

	if object_id('tempdb..#ForcedParameterization') is not null
		drop table #ForcedParameterization

	if object_id('tempdb..#HasReplication') is not null
		drop table #HasReplication;

	if object_id('tempdb..#LogShippingDetails') is not null
		drop table #LogShippingDetails

	if object_id('tempdb..#MirroringDetails') is not null
		drop table #MirroringDetails

	if object_id('tempdb..#TDEDatabases') is not null
		drop table #TDEDatabases

	if object_id('tempdb..#UserObjectsInModelDB') is not null
		drop table #UserObjectsInModelDB

	if object_id('tempdb..#LinkedServers') is not null
		drop table #LinkedServers

	if object_id('tempdb..#JobsWhichAutoStart') is not null
		drop table #JobsWhichAutoStart
		
	if object_id('tempdb..#UnusedCPUs') is not null
		drop table #UnusedCPUs

	if object_id('tempdb..#SlowGrowingDBs') is not null
		drop table #SlowGrowingDBs

	if object_id('tempdb..#CPUdata') is not null
		drop table #CPUdata

	if object_id('tempdb..#SlowReadsAndWrites') is not null
		drop table #SlowReadsAndWrites

	if object_id('tempdb..#ImplicitResults') is not null
		drop table #ImplicitResults

	if object_id('tempdb..#TheQueries') is not null
		drop table #TheQueries

	if object_id('tempdb..#currentReadings') is not null
		drop table #currentReadings

	if object_id('tempdb..#KeyLookups') is not null
		drop table #KeyLookups	

	if object_id('tempdb..#HighImpactIndexes') is not null
		drop table #HighImpactIndexes	

	if object_id('tempdb..#AllDBs') is not null
		drop table #AllDBs

	if object_id('tempdb..#UnusedIndexes') is not null
		drop table #UnusedIndexes

	if object_id('tempdb..#DuplicateIndexes') is not null
		drop table #DuplicateIndexes

	if object_id('tempdb..#tempdrives') is not null
		drop table #tempdrives

	if object_id('tempdb..#tempdbdata') is not null
		drop table #tempdbdata

	if object_id('tempdb..#MemoryTables') is not null
		drop table #MemoryTables

	if object_id('tempdb..#DelayedDurability') is not null
		drop table #DelayedDurability

	if object_id('tempdb..#AGDetails') is not null
		drop table #AGDetails

	if object_id('tempdb..#DatabaseNames') is not null
		drop table #DatabaseNames
		
	if object_id('tempdb..#ColumnStoreIndexes') is not null
		drop table #ColumnStoreIndexes

	if object_id('tempdb..#DatabaseContainment') is not null
		drop table #DatabaseContainment

	if object_id('tempdb..#UserDefinedRoles') is not null
		drop table #UserDefinedRoles

	if object_id('tempdb..#LastRebuiltIndexes') is not null
		drop table #LastRebuiltIndexes

	if object_id('tempdb..#NonProdDBs') is not null
		drop table #NonProdDBs

	if object_id('tempdb..#SSL_SystemPolicies') is not null
		drop table #SSL_SystemPolicies

	if object_id('tempdb..#DBCCs') is not null
		drop table #DBCCs	

	if object_id('tempdb..#PowerSettings') is not null
		drop table #PowerSettings

	if object_id('tempdb..#Results') is not null
		drop table #Results

	if object_id('tempdb..#SSL_DBFileSizes') is not null
		drop table #SSL_DBFileSizes

	if object_id('tempdb..#SSL_OrphanedUsers') is not null
		drop table #SSL_OrphanedUsers

	if object_id('tempdb..#EnterpriseFeatures') is not null
		drop table #EnterpriseFeatures

	if object_id('tempdb..#SQLAlerts') is not null
		drop table #SQLAlerts

	if object_id('tempdb..#logs') is not null
		drop table #logs

	if object_id('tempdb..#agentlogs') is not null
		drop table #agentlogs

	if object_id('tempdb..#DatabaseCompression') is not null
		drop table #DatabaseCompression

	if object_id('tempdb..#ProcsThatAutoStart') is not null
		drop table #ProcsThatAutoStart

	if object_id('tempdb..#FTIndexes') is not null
		drop table #FTIndexes

	if object_id('tempdb..#SSL_Endpoint') is not null
		drop table #SSL_Endpoint;

	if object_id('tempdb..#tmp_replication') is not null
		drop table #tmp_replication


	if exists (select * from #XPCommandShell s where s.IsEnabled = 1)
	begin
		exec master.dbo.sp_configure 'xp_cmdshell', 0;
		reconfigure with override;
	end

	if object_id('tempdb..#XPCommandShell') is not null
		drop table #XPCommandShell


	-- select out the problems encountered
	if not exists (select * from #Problems)
		insert #Problems select 'Results', 'No issues have been encountered!'
	
	select * from #Problems order by MessageType
	
	if object_id('tempdb..#Problems') is not null
		drop table #Problems

	print 'Script has completed running : ' + 'time : ' + convert(varchar, getdate(), 120)

end

set noexec off
