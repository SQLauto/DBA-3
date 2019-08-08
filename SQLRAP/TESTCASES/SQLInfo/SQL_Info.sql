--Signature="38E73D1F0FBA8C4D"
--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****      Extracts the SQL Server and Databases information                                               ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    2009.Mar.05 rajpo Moved the guest user to individual database levels.                             ****/
--/****                Fixed the target server memory counter that always show NULL for SQL2K                ****/                                                                                                 ****/
--/****                                                                                                      ****/
--/****    2009-Mar-27	rajpo	Fixed the NUMA config desciptions                                            ****/
--/****    2009-Apr-07  wardp   bug 339922                                                                   ****/
--/****    2009-Jul-27  wardp   CR 375891                                                                    ****/
--/****    2010-May-20  wardp   bug 458278                                                                   ****/
--/****    2011-May-10  rajpo	bug 475921                                                                   ****/
--/****    2011-Jun-06  rajpo   bug 475921 fixed for 32-bit SQL Server										 ****/
--/****    Copyright (c) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/
SET NOCOUNT ON
SET ANSI_WARNINGS OFF

DECLARE @Version CHAR(12),
        @InstanceName VARCHAR(128),
        @ServerServiceAccount VARCHAR(128),
        @AgentServiceAccount VARCHAR(128),
        @NUMAConfig INT,
	@NUMAString CHAR(10),
        @Param VARCHAR(200),
        @CONST_NOT_AVAILABLE VARCHAR(15),
        @Ctr1 INT, @Ctr2 INT, @Ctr3 INT, @Ctr4 INT, @Ctr5 INT, @Ctr6 INT, @Ctr7 INT, @Ctr8 INT,
		@databaseID int, @DatabaseName sysname


SET @Version = SUBSTRING(CONVERT(CHAR(12),SERVERPROPERTY('productversion')),1,2)
SET @CONST_NOT_AVAILABLE = 'Not Available'
--Instance Level details
IF SERVERPROPERTY('instancename') IS NULL
    begin   --Default Instance
        -- SQLServer
        EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 
            N'SYSTEM\CurrentControlSet\Services\MSSQLServer', N'ObjectName',
            @ServerServiceAccount OUTPUT,"no_output"

        -- SQLServer Agent
        EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 
            N'SYSTEM\CurrentControlSet\Services\SQLSERVERAGENT', N'ObjectName',
            @AgentServiceAccount OUTPUT,"no_output"
    end
ELSE
    begin   --Named Instance
        SET @InstanceName = CONVERT(VARCHAR(128),SERVERPROPERTY('instancename'))
        -- SQLServer
        SET @Param = 'SYSTEM\CurrentControlSet\Services\MSSQL$' + @InstanceName
        EXEC master.dbo.xp_instance_regread 'HKEY_LOCAL_MACHINE', @Param, 'ObjectName', @ServerServiceAccount OUTPUT

        -- SQLServer Agent
        SET @Param = 'SYSTEM\CurrentControlSet\Services\SQLAgent$' + @InstanceName
        EXEC master.dbo.xp_instance_regread 'HKEY_LOCAL_MACHINE', @Param, 'ObjectName', @AgentServiceAccount OUTPUT
    end
--NUMA (Non-uniform Memory Access)
IF @Version = '10'
BEGIN
    SELECT @NUMAConfig = COUNT(DISTINCT memory_node_id) FROM sys.dm_os_memory_clerks  where memory_node_id not in( 64,32)
	if @NUMAConfig =1 
		set @NUMAString ='Disabled'
	else 
		set @NUMAString =convert(char,@NUMAConfig)
END
ELSE IF @Version = '9.'
BEGIN
    SELECT @NUMAConfig = COUNT(DISTINCT memory_node_id) FROM sys.dm_os_memory_clerks  where memory_node_id not in( 64,32)
	if @NUMAConfig =1 
		set @NUMAString ='Disabled'
	else 
		set @NUMAString =convert(char,@NUMAConfig)
END
ELSE IF @Version = '8.'
    set @NUMAString ='Unknown'
--Guest Users
--Performance Counters
SELECT 
    @Ctr1 = Memory_Manager_Total_Server_Memory__KB_
    ,@Ctr2 = Memory_Manager_Target_Server_Memory__KB_
    ,@Ctr3 = Buffer_Manager_Page_life_expectancy
    ,@Ctr4 = Buffer_Manager_Stolen_pages
    ,@Ctr5 = Buffer_Manager_Database_pages
    ,@Ctr6 = Memory_Manager_Lock_Memory__KB_
    ,@Ctr7 = Memory_Manager_Granted_Workspace_Memory__KB_
    ,@Ctr8 = Memory_Manager_Optimizer_Memory__KB_
FROM(
SELECT 
    MAX(CASE WHEN  cntr_name='Memory_Manager_Total_Server_Memory__KB_' THEN cntr_value ELSE NULL END) Memory_Manager_Total_Server_Memory__KB_ ,
    MAX(CASE WHEN  cntr_name='Memory_Manager_Target_Server_Memory__KB_' THEN cntr_value  WHEN  cntr_name='Memory_Manager_Target_Server_Memory_KB_' THEN cntr_value ELSE NULL END) Memory_Manager_Target_Server_Memory__KB_,
    MAX(CASE WHEN  cntr_name='Buffer_Manager_Page_life_expectancy' THEN cntr_value ELSE NULL END) Buffer_Manager_Page_life_expectancy,
    MAX(CASE WHEN  cntr_name='Buffer_Manager_Stolen_pages' THEN cntr_value ELSE NULL END) Buffer_Manager_Stolen_pages,
    MAX(CASE WHEN  cntr_name='Buffer_Manager_Database_pages' THEN cntr_value ELSE NULL END) Buffer_Manager_Database_pages,
    MAX(CASE WHEN  cntr_name='Memory_Manager_Lock_Memory__KB_' THEN cntr_value ELSE NULL END) Memory_Manager_Lock_Memory__KB_,
    MAX(CASE WHEN  cntr_name='Memory_Manager_Granted_Workspace_Memory__KB_' THEN cntr_value ELSE NULL END) Memory_Manager_Granted_Workspace_Memory__KB_,
    MAX(CASE WHEN  cntr_name='Memory_Manager_Optimizer_Memory__KB_' THEN cntr_value ELSE NULL END) Memory_Manager_Optimizer_Memory__KB_
FROM (
SELECT REPLACE (REPLACE (REPLACE (REPLACE (REPLACE (
    LEFT (RTRIM (SUBSTRING ([object_name], CHARINDEX (':', [object_name]) + 1, 30)) + CASE WHEN [instance_name] != '' THEN '(' + RTRIM ([instance_name]) + ')' ELSE '' END + '\'  + RTRIM (counter_name), 80) 
    , ' ', '_'), '\', '_'), '/', '_'), '(', '_'), ')', '_') AS cntr_name, cntr_value
FROM master.dbo.sysperfinfo
WHERE 
    ([object_name] LIKE '%:Memory Manager%' COLLATE Latin1_General_BIN     AND counter_name COLLATE Latin1_General_BIN IN ('Connection Memory (KB)', 'Granted Workspace Memory (KB)', 'Lock Memory (KB)', 'Memory Grants Outstanding', 'Memory Grants Pending', 'Optimizer Memory (KB)', 'SQL Cache Memory (KB)', 'Total Server Memory (KB)', 'Target Server Memory (KB)','Target Server Memory(KB)'))
    OR ([object_name] LIKE '%:Buffer Manager%' COLLATE Latin1_General_BIN     AND counter_name COLLATE Latin1_General_BIN IN ('Buffer cache hit ratio', 'Buffer cache hit ratio base',  'Page life expectancy', 'Total pages', 'Target pages', 'Stolen pages', 'Database pages'))
    ) AS T1
WHERE T1.cntr_name IN ('Memory_Manager_Total_Server_Memory__KB_', 'Memory_Manager_Target_Server_Memory_KB_','Memory_Manager_Target_Server_Memory__KB_', 'Buffer_Manager_Page_life_expectancy',
    'Buffer_Manager_Stolen_pages', 'Buffer_Manager_Database_pages', 'Memory_Manager_Lock_Memory__KB_','Memory_Manager_Granted_Workspace_Memory__KB_',
    'Memory_Manager_Optimizer_Memory__KB_') ) AS Pvt

--Display Instance Related Details
SELECT '0' as RSNo
    ,SERVERPROPERTY('machinename') as 'Server Name'
    ,ISNULL(SERVERPROPERTY('instancename'), SERVERPROPERTY('machinename')) as 'Instance Name'
    ,@ServerServiceAccount AS SQLServerSvcAccount
    ,@AgentServiceAccount AS SQLServerAgentSvcAccount
    ,@NUMAString AS 'No of NUMA Nodes'
    ,SERVERPROPERTY('productversion') AS BuildNumber
    ,SERVERPROPERTY ('productlevel') AS ServicePack
    ,SERVERPROPERTY ('edition') AS Edition
    ,(CASE SERVERPROPERTY('IsClustered') 
        WHEN 1 THEN 'True'
        WHEN 0 THEN 'False'
        END) AS IsClustered
    ,@Ctr1 AS Memory_Manager_Total_Server_Memory__KB_
    ,@Ctr2 AS Memory_Manager_Target_Server_Memory__KB_
    ,@Ctr3 AS Buffer_Manager_Page_life_expectancy
    ,@Ctr4 AS Buffer_Manager_Stolen_pages
    ,@Ctr5 AS Buffer_Manager_Database_pages
    ,@Ctr6 AS Memory_Manager_Lock_Memory_KB_
    ,@Ctr7 AS Memory_Manager_Granted_Workspace_Memory__KB_
    ,@Ctr8 AS Memory_Manager_Optimizer_Memory__KB_

--Display Database Related Details

---Rajpo Populating the table variable for guest user access
if object_id ('tempdb.dbo.#temp_guest_user_tbl') is not null
	drop table #temp_guest_user_tbl
create table #temp_guest_user_tbl  (DatabaseID int,IsEnabled int)
declare cur_dbname cursor for select dbid,name from master.dbo.sysdatabases with (nolock) where DATABASEPROPERTYEX(name,'Status') ='ONLINE'
open cur_dbname

fetch next from cur_dbname into @databaseID, @DatabaseName
while (@@fetch_status =0)
Begin
	insert into #temp_guest_user_tbl execute ('SELECT '+@databaseID+', count(*) from ['+@DatabaseName+'].dbo.sysusers with (nolock) where Name=''guest'' AND hasdbaccess=1')
	
	fetch next from cur_dbname into @databaseID, @DatabaseName
end
close cur_dbname
deallocate cur_dbname


IF @Version = '10'
    SELECT '1' as RSNo
        ,name AS 'Database Name' 
        ,state_desc AS DatabaseStatus
        ,recovery_model_desc AS RecoveryModel,
		CAST(DATABASEPROPERTYEX(name, 'Collation') AS sysname) AS [Collation]
        ,(CASE is_auto_create_stats_on
            WHEN 1 THEN 'True'
            WHEN 0 THEN 'False'
            END) AS AutoCreateStats
        ,(CASE is_auto_update_stats_on 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END) AS AutoUpdateStats
        ,(CASE is_auto_update_stats_async_on 
			WHEN 1 THEN 'True'
			WHEN 0 THEN 'False'
			END )AS AutoUpdateStatsAsyncStatus
        ,page_verify_option_desc AS PageVerifyOption
        ,(CASE is_auto_shrink_on 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END) AS AutoShrinkStatus
        ,(CASE is_auto_close_on 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END) AS AutoCloseStatus
        ,(CASE is_db_chaining_on 
			WHEN 1 THEN 'True'
			WHEN 0 THEN 'False'
			END) AS DatabaseChaining
        ,compatibility_level AS CompatibilityLevel
        ,(CASE is_trustworthy_on 
			WHEN 1 THEN 'Enabled'
			WHEN 0 THEN 'Disabled'
			END) AS TrustworthyBit
        ,(CASE is_parameterization_forced 
			WHEN 1 THEN 'Forced'
			WHEN 0 THEN 'Simple'
			END) AS ForcedParameterization
        ,(CASE is_read_committed_snapshot_on 
			WHEN 1 THEN 'ON'
			WHEN 0 THEN 'OFF'
			END) AS ReadCommittedSnapshot
		,(CASE 
			WHEN mirroring_guid is null  THEN 'False'
			WHEN mirroring_guid is not null THEN 'True'
			ELSE 'N/A'
			END) As Mirrored
        ,(CASE is_published 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END)AS Publisher
        ,(CASE is_subscribed 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END) AS Subscriber
        ,(CASE is_distributor 
            WHEN 1 THEN 'Yes' 
            WHEN 0 THEN 'No'
            END) AS Distributor
        ,(CASE is_broker_enabled 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END) AS ServiceBrokerEnabled
        ,log_reuse_wait_desc AS LogReuseWait
        ,snapshot_isolation_state_desc AS SnapshotIsolationLevel
        ,(CASE is_merge_published 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END) AS MergePublished
		,(CASE IsEnabled 
			WHEN 1 THEN 'Enabled'
			WHEN 0 THEN 'Disabled'
			ELSE 'N/A'
			END) as GuestUser

    FROM master.sys.databases
	left outer join #temp_guest_user_tbl
		on database_id =DatabaseID
	left outer join sys.database_mirroring dbm
		on master.sys.databases.database_id = dbm.database_id

    ORDER BY 1
ELSE IF @Version = '9.'
    SELECT '1' as RSNo
        ,name AS 'Database Name' 
        ,state_desc AS DatabaseStatus
        ,recovery_model_desc AS RecoveryModel,
		CAST(DATABASEPROPERTYEX(name, 'Collation') AS sysname) AS [Collation]
        ,(CASE is_auto_create_stats_on
            WHEN 1 THEN 'True'
            WHEN 0 THEN 'False'
            END) AS AutoCreateStats
        ,(CASE is_auto_update_stats_on 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END) AS AutoUpdateStats
        ,(CASE is_auto_update_stats_async_on 
			WHEN 1 THEN 'True'
			WHEN 0 THEN 'False'
			END )AS AutoUpdateStatsAsyncStatus
        ,page_verify_option_desc AS PageVerifyOption
        ,(CASE is_auto_shrink_on 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END) AS AutoShrinkStatus
        ,(CASE is_auto_close_on 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END) AS AutoCloseStatus
        ,(CASE is_db_chaining_on 
			WHEN 1 THEN 'True'
			WHEN 0 THEN 'False'
			END) AS DatabaseChaining
        ,compatibility_level AS CompatibilityLevel
        ,(CASE is_trustworthy_on 
			WHEN 1 THEN 'Enabled'
			WHEN 0 THEN 'Disabled'
			END) AS TrustworthyBit
        ,(CASE is_parameterization_forced 
			WHEN 1 THEN 'Forced'
			WHEN 0 THEN 'Simple'
			END) AS ForcedParameterization
        ,(CASE is_read_committed_snapshot_on 
			WHEN 1 THEN 'ON'
			WHEN 0 THEN 'OFF'
			END) AS ReadCommittedSnapshot
		,(CASE 
			WHEN mirroring_guid is null  THEN 'False'
			WHEN mirroring_guid is not null THEN 'True'
			ELSE 'N/A'
			END) As Mirrored
        ,(CASE is_published 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END)AS Publisher
        ,(CASE is_subscribed 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END) AS Subscriber
        ,(CASE is_distributor 
            WHEN 1 THEN 'Yes' 
            WHEN 0 THEN 'No'
            END) AS Distributor
        ,(CASE is_broker_enabled 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END) AS ServiceBrokerEnabled
        ,log_reuse_wait_desc AS LogReuseWait
        ,snapshot_isolation_state_desc AS SnapshotIsolationLevel
        ,(CASE is_merge_published 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END) AS MergePublished
		,(CASE IsEnabled 
			WHEN 1 THEN 'Enabled'
			WHEN 0 THEN 'Disabled'
			ELSE 'N/A'
			END) as GuestUser

    FROM master.sys.databases
	left outer join #temp_guest_user_tbl
	on database_id =DatabaseID
	left outer join sys.database_mirroring dbm
	on master.sys.databases.database_id = dbm.database_id

    ORDER BY 1
ELSE IF @Version = '8.'
    SELECT '1' as RSNo 
		,name AS 'Database Name'
        ,DATABASEPROPERTYEX(name, 'Status') AS DatabaseStatus
        ,DATABASEPROPERTYEX(name, 'Recovery') AS RecoveryModel,
		CAST(DATABASEPROPERTYEX(name, 'Collation') AS sysname) AS [Collation]
        ,(CASE DATABASEPROPERTYEX(name, 'IsAutoCreateStatistics') 
            WHEN 1 THEN 'True'
            WHEN 0 THEN 'False'
            END) AS AutoCreateStats
        ,(CASE DATABASEPROPERTYEX(name, 'IsAutoUpdateStatistics')
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END) AS AutoUpdateStats
        ,@CONST_NOT_AVAILABLE AS AutoUpdateStatsAsyncStatus
        ,(CASE DATABASEPROPERTYEX(name, 'IsTornPageDetectionEnabled')
			WHEN 1 THEN 'True'
			WHEN 0 THEN 'False' 
		  END) AS PageVerifyOption
        ,(CASE DATABASEPROPERTYEX(name, 'IsAutoShrink') 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END) AS AutoShrinkStatus
        ,(CASE DATABASEPROPERTYEX(name, 'IsAutoClose') 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END) AS AutoCloseStatus
        ,@CONST_NOT_AVAILABLE AS DatabaseChaining
        ,cmptlevel AS CompatibilityLevel
        ,@CONST_NOT_AVAILABLE AS TrustworthyBit
        --,DATABASEPROPERTYEX(name, 'IsParameterizationForced') AS ForcedParameterization
        ,@CONST_NOT_AVAILABLE AS ForcedParameterization
        ,@CONST_NOT_AVAILABLE AS ReadCommittedSnapshot
        ,'N/A' as Mirrored
        ,(CASE DATABASEPROPERTYEX(name, 'IsPublished') 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END) AS Publisher
        ,(CASE DATABASEPROPERTYEX(name, 'IsSubscribed') 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END) AS Subscriber
        ,@CONST_NOT_AVAILABLE AS Distributor
        ,@CONST_NOT_AVAILABLE AS ServiceBrokerEnabled
        ,@CONST_NOT_AVAILABLE AS LogReuseWait
        ,@CONST_NOT_AVAILABLE AS SnapshotIsolationLevel
        ,(CASE DATABASEPROPERTYEX(name, 'IsMergePublished') 
            WHEN 1 THEN 'True' 
            WHEN 0 THEN 'False'
            END) AS MergePublished
		,(CASE IsEnabled 
			WHEN 1 THEN 'Enabled'
			WHEN 0 THEN 'Disabled'
			ELSE 'N/A'
			END) as GuestUser
    FROM master.dbo.sysdatabases 
	left outer join #temp_guest_user_tbl
	on dbid =DatabaseID
    ORDER BY 1


if object_id ('tempdb.dbo.#temp_guest_user_tbl') is not null
	drop table #temp_guest_user_tbl


