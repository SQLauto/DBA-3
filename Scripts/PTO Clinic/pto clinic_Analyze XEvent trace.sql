---------------------------------------------------------------
-- Setup
---------------------------------------------------------------
DECLARE @Message NVARCHAR(100)
SELECT @Message = CONVERT(VARCHAR, GETDATE(), 8) + ' - Setting up PTOCLINIC_XEventTrace database...'
RAISERROR (@Message, 10, 1) WITH NOWAIT

USE master
GO
SET NOCOUNT ON
GO
IF EXISTS (SELECT * FROM master.sys.databases WHERE name = 'PTOCLINIC_XEventTrace')
BEGIN
	ALTER DATABASE PTOCLINIC_XEventTrace
	SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE PTOCLINIC_XEventTrace;
END
GO
CREATE DATABASE [PTOCLINIC_XEventTrace]
GO
ALTER DATABASE [PTOCLINIC_XEventTrace] SET RECOVERY SIMPLE
GO
USE [PTOCLINIC_XEventTrace]
GO

DECLARE @Message NVARCHAR(100)
SELECT @Message = CONVERT(VARCHAR, GETDATE(), 8) + ' - Setting up database schema...'
RAISERROR (@Message, 10, 1) WITH NOWAIT

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[importxeventtrace]') AND type in (N'U'))
DROP TABLE [dbo].[importxeventtrace];
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[importxeventtrace]') AND type in (N'U'))
CREATE TABLE dbo.importxeventtrace (ID int IDENTITY(1,1) PRIMARY KEY, XEvent XML);

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[completed_batches]') AND type in (N'U'))
DROP TABLE [dbo].[completed_batches];
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[completed_batches]') AND type in (N'U'))
CREATE TABLE [dbo].[completed_batches](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[EventName] [varchar](50) NULL,
	[DateAndTime] [datetime] NOT NULL,
	[CPU_Time] [bigint] NULL,
	[Duration] [bigint] NULL,
	[Physical_Reads] [bigint] NULL,
	[Logical_Reads] [bigint] NULL,
	[Writes] [bigint] NULL,
	[Row_Count] [bigint] NULL,
	[Object_name] [varchar](500) NULL,
	[Statement] [nvarchar](max) NULL,
	[sql_text] [nvarchar](max) NULL,
	[database_id] [int] NULL,
	[database_name] [varchar](200) NULL,
	[client_app_name] [varchar](100) NULL,
	[client_hostname] [varchar](100) NULL,
	[server_principal_name] [varchar](100) NULL,
	[session_id] [int] NULL,
	[session_resource_group_id] [int] NULL,
	[session_resource_pool_id] [int] NULL,
	[attach_activity_id] [uniqueidentifier] NULL,
	[attach_activity_id_xfer] [uniqueidentifier] NULL,
	CONSTRAINT PK_rpc_completed PRIMARY KEY CLUSTERED (ID,DateAndTime)
);

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[query_plan_hash]') AND type in (N'U'))
DROP TABLE [dbo].query_plan_hash;
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[query_plan_hash]') AND type in (N'U'))
CREATE TABLE [dbo].query_plan_hash(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	query_hash [varchar](100),
	query_plan_hash [varchar](100),
    [attach_activity_id] [uniqueidentifier] NULL,
	[attach_activity_id_xfer] [uniqueidentifier] NULL,
	CONSTRAINT PK_query_plan_hash PRIMARY KEY CLUSTERED (ID,query_hash)
);

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[unique_batches]') AND type in (N'U'))
DROP TABLE [dbo].[unique_batches];
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[unique_batches]') AND type in (N'U'))
CREATE TABLE [dbo].[unique_batches](
	[ID] int IDENTITY (1,1),
	[QueryNumber] [int] NULL,
	[query_hash] [varchar](100) NOT NULL,
	[Executes] [bigint] NULL,
	[Total_CPU_Time_ms] [bigint] NULL,
	[Total_Duration] [bigint] NULL,
	[Total_Logical_Reads] [bigint] NULL,
	[Total_Physical_Reads] [bigint] NULL,
	[Total_Writes] [bigint] NULL,
	Total_Row_Count [bigint] NULL,
	[Attentions] [int] NULL,
	[sql_text] [nvarchar](max) NULL,
	CONSTRAINT PK_unique_batches PRIMARY KEY CLUSTERED (ID,query_hash)
);

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[interesting_events_warnings]') AND type in (N'U'))
DROP TABLE [dbo].[interesting_events_warnings];
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[interesting_events_warnings]') AND type in (N'U'))
CREATE TABLE [dbo].[interesting_events_warnings](
	[ID] int IDENTITY (1,1),
	[query_hash] [varchar](100),
	[DateAndTime] [datetime] NULL,
	[EventName] [varchar](50) NULL,
	[warning_type] [varchar](20) NULL,
	[sql_text] [nvarchar](max) NULL,
	[database_id] [int] NULL,
	[database_name] [varchar](100) NULL,
	[client_app_name] [varchar](100) NULL,
	[client_hostname] [varchar](100) NULL,
	[server_principal_name] [varchar](100) NULL,
	[session_id] [int] NULL,
	[session_resource_group_id] [int] NULL,
	[session_resource_pool_id] [int] NULL,
	[attach_activity_id] [uniqueidentifier] NULL,
	CONSTRAINT PK_interesting_events_warnings PRIMARY KEY CLUSTERED (ID,query_hash)
);

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[interesting_events_missing_column_statistics]') AND type in (N'U'))
DROP TABLE [dbo].[interesting_events_missing_column_statistics];
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[interesting_events_missing_column_statistics]') AND type in (N'U'))
CREATE TABLE [dbo].[interesting_events_missing_column_statistics](
	[ID] int IDENTITY (1,1) PRIMARY KEY,
	[DateAndTime] [datetime] NULL,
	[EventName] [varchar](50) NULL,
	[column_list] [varchar](max) NULL,
	[sql_text] [nvarchar](max) NULL,
	[database_id] [int] NULL,
	[database_name] [varchar](100) NULL,
	[client_app_name] [varchar](100) NULL,
	[client_hostname] [varchar](100) NULL,
	[server_principal_name] [varchar](100) NULL,
	[attach_activity_id] [uniqueidentifier] NULL
);

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[interesting_events_auto_stats]') AND type in (N'U'))
DROP TABLE [dbo].[interesting_events_auto_stats];
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[interesting_events_auto_stats]') AND type in (N'U'))
CREATE TABLE [dbo].[interesting_events_auto_stats](
	[ID] int IDENTITY (1,1) PRIMARY KEY,
	[DateAndTime] [datetime] NULL,
	[EventName] [varchar](50) NULL,
	[statistics_list] [varchar](255) NULL,
	[duration] [bigint] NULL,
	[retries] [bigint] NULL,
	[success] [varchar](10) NULL,
	[database_id] [int] NULL,
	[database_name] [varchar](100) NULL,
	[object_id] [bigint] NULL,
	[index_id] [int] NULL,
	[job_id] [int] NULL,
	[job_type] [varchar](50) NULL,
	[sql_text] [nvarchar](max) NULL,
	[client_app_name] [varchar](100) NULL,
	[client_hostname] [varchar](100) NULL,
	[server_principal_name] [varchar](100) NULL,
	[attach_activity_id] [uniqueidentifier] NULL
);

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[interesting_events_attention]') AND type in (N'U'))
DROP TABLE [dbo].[interesting_events_attention];
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[interesting_events_attention]') AND type in (N'U'))
CREATE TABLE [dbo].[interesting_events_attention](
	[ID] int IDENTITY (1,1) PRIMARY KEY,
	[DateAndTime] [datetime] NULL,
	[EventName] [varchar](50) NULL,
	[Duration] [bigint] NULL,
	[sql_text] [nvarchar](max) NULL,
	[database_id] [int] NULL,
	[database_name] [varchar](100) NULL,
	[client_app_name] [varchar](100) NULL,
	[client_hostname] [varchar](100) NULL,
	[server_principal_name] [varchar](100) NULL,
	[session_id] [int] NULL,
	[session_resource_group_id] [int] NULL,
	[session_resource_pool_id] [int] NULL,
	[attach_activity_id] [uniqueidentifier] NULL
);

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[interesting_events_deprecation]') AND type in (N'U'))
DROP TABLE [dbo].[interesting_events_deprecation];
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[interesting_events_deprecation]') AND type in (N'U'))
CREATE TABLE [dbo].[interesting_events_deprecation](
	[ID] int IDENTITY (1,1),
	[feature_id] [smallint],
	[DateAndTime] [datetime] NULL,
	[EventName] [varchar](50) NULL,
	[feature] [varchar](100) NULL,
	[message] [varchar](500) NULL,
	[sql_text] [nvarchar](max) NULL,
	[database_id] [int] NULL,
	[database_name] [varchar](100) NULL,
	[client_app_name] [varchar](100) NULL,
	[client_hostname] [varchar](100) NULL,
	[server_principal_name] [varchar](100) NULL,
	[session_id] [int] NULL,
	[session_resource_group_id] [int] NULL,
	[session_resource_pool_id] [int] NULL,
	[attach_activity_id] [uniqueidentifier] NULL,
	[attach_activity_id_xfer] [uniqueidentifier] NULL,
	CONSTRAINT PK_interesting_events_deprecation PRIMARY KEY CLUSTERED (ID,[feature_id])
);

CREATE INDEX IX_interesting_events_deprecation
ON [dbo].[interesting_events_deprecation] ([attach_activity_id]);

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[interesting_events_blocked_process]') AND type in (N'U'))
DROP TABLE [dbo].[interesting_events_blocked_process];
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[interesting_events_blocked_process]') AND type in (N'U'))
CREATE TABLE [dbo].[interesting_events_blocked_process](
	[ID] int IDENTITY (1,1) PRIMARY KEY,
	[DateAndTime] [datetime] NULL,
	[EventName] [varchar](50) NULL,
	[resource_owner_type] [varchar](100) NULL,
	[blocked_spid] [int] NULL,
	[blocked_wait_resource] [varchar](100) NULL,
	[blocked_wait_time] [int] NULL,
	[blocked_database_id] [int] NULL,
	[blocked_object_id] [bigint] NULL,
	[blocked_index_id] [int] NULL,
	[blocked_transaction_name] [varchar](100) NULL,
	[blocked_lock_Mode] [varchar](10) NULL,
	[blocked_status] [varchar](10) NULL,
	[blocked_isolationlevel] [varchar](100) NULL,
	[blocked_client_app_name] [varchar](100) NULL,
	[blocked_client_hostname] [varchar](100) NULL,
	[blocked_login_name] [varchar](100) NULL,
	[blocked_inputbuf] [nvarchar](max) NULL,
	[blocking_spid] [int] NULL,
	[blocking_wait_time] [int] NULL,
	[blocking_database_id] [int] NULL,
	[blocking_lock_Mode] [varchar](10) NULL,
	[blocking_status] [varchar](10) NULL,
	[blocking_isolationlevel] [varchar](100) NULL,
	[blocking_client_app_name] [varchar](100) NULL,
	[blocking_client_hostname] [varchar](100) NULL,
	[blocking_login_name] [varchar](100) NULL,
	[blocking_inputbuf] [nvarchar](max) NULL
);

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[interesting_events_errors]') AND type in (N'U'))
DROP TABLE [dbo].[interesting_events_errors];
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[interesting_events_errors]') AND type in (N'U'))
CREATE TABLE [dbo].[interesting_events_errors](
	[ID] int IDENTITY (1,1) PRIMARY KEY,
	[query_hash] [varchar](100) NULL,
	[DateAndTime] [datetime] NULL,
	[EventName] [varchar](50) NULL,
	[error_number] [int] NULL,
	[error_severity] [int] NULL,
	[error_state] [int] NULL,
	[user_defined] [varchar](10) NULL,
	[message] [varchar](500) NULL,
	[sql_text] [nvarchar](max) NULL,
	[database_id] [int] NULL,
	[database_name] [varchar](100) NULL,
	[client_app_name] [varchar](100) NULL,
	[client_hostname] [varchar](100) NULL,
	[server_principal_name] [varchar](100) NULL,
	[session_id] [int] NULL,
	[session_resource_group_id] [int] NULL,
	[session_resource_pool_id] [int] NULL,
	[attach_activity_id] [uniqueidentifier] NULL
);

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[interesting_events_lock_escalation]') AND type in (N'U'))
DROP TABLE [dbo].[interesting_events_lock_escalation]
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[interesting_events_lock_escalation]') AND type in (N'U'))
CREATE TABLE [dbo].[interesting_events_lock_escalation](
	[ID] int IDENTITY (1,1) PRIMARY KEY,
	[DateAndTime] [datetime] NULL,
	[EventName] [varchar](50) NULL,
	[escalation_cause] [varchar](50) NULL,
	[resource_type] [varchar](100) NULL,
	[mode] [varchar](10) NULL,
	[owner_type] [varchar](50) NULL,
	[database_id] [int] NULL,
	[database_name] [varchar](100) NULL,
	[object_id] [bigint] NULL,
	[hobt_id] [bigint] NULL,
	[escalated_lock_count] [int] NULL,
	[hobt_lock_count] [int] NULL,
	[sql_text] [nvarchar](max) NULL,
	[query_hash] [varchar](100) NULL,
	[client_app_name] [varchar](100) NULL,
	[client_hostname] [varchar](100) NULL,
	[server_principal_name] [varchar](100) NULL,
	[session_id] [int] NULL,
	[session_resource_group_id] [int] NULL,
	[session_resource_pool_id] [int] NULL,
	[attach_activity_id] [uniqueidentifier] NULL,
	[attach_activity_id_xfer] [uniqueidentifier] NULL
);

--DECLARE @Message NVARCHAR(100)
SELECT @Message = CONVERT(VARCHAR, GETDATE(), 8) + ' - Importing data...'
RAISERROR (@Message, 10, 1) WITH NOWAIT

--Note: takes 15min to import a 3GB trace file
INSERT dbo.importxeventtrace 
SELECT CAST(event_data AS XML) AS XEvent
FROM sys.fn_xe_file_target_read_file('C:\Temp\SQL_PTO_Clinic*.xel', NULL, NULL, NULL) AS src;

--DECLARE @Message NVARCHAR(100)
SELECT @Message = CONVERT(VARCHAR, GETDATE(), 8) + ' - Aggregating data for top queries...'
RAISERROR (@Message, 10, 1) WITH NOWAIT
---------------------------------------------------------------
-- Top queries
---------------------------------------------------------------
--Extract the Completed xml data into the Completed table
INSERT INTO dbo.[completed_batches]
SELECT XEvent.value('(event/@name)[1]', 'varchar(50)') AS [EventName]
      ,XEvent.value('(event/@timestamp)[1]', 'datetime') AS [DateAndTime]
	  ,XEvent.value('(event/data[@name="cpu_time"]/value)[1]', 'bigint') AS [CPU_Time]
	  ,XEvent.value('(event/data[@name="duration"]/value)[1]', 'bigint') AS [Duration]
	  ,XEvent.value('(event/data[@name="physical_reads"]/value)[1]', 'int') AS [Physical_Reads]
	  ,XEvent.value('(event/data[@name="logical_reads"]/value)[1]', 'int') AS [Logical_Reads]
	  ,XEvent.value('(event/data[@name="writes"]/value)[1]', 'int') AS [Writes]
	  ,XEvent.value('(event/data[@name="row_count"]/value)[1]', 'int') AS [Row_Count]
	  ,XEvent.value('(event/data[@name="object_name"]/value)[1]', 'varchar(500)') AS [Object_name]
	  ,XEvent.value('(event/data[@name="statement"]/value)[1]', 'nvarchar(max)') AS [Statement] -- RPC Completed only
	  ,XEvent.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS [sql_text] -- To be able to create an index on it
	  ,XEvent.value('(event/action[@name="database_id"]/value)[1]', 'int') AS [database_id]
	  ,XEvent.value('(event/action[@name="database_name"]/value)[1]', 'varchar(100)') AS [database_name]
	  ,XEvent.value('(event/action[@name="client_app_name"]/value)[1]', 'varchar(100)') AS [client_app_name]
	  ,XEvent.value('(event/action[@name="client_hostname"]/value)[1]', 'varchar(100)') AS [client_hostname]
	  ,XEvent.value('(event/action[@name="session_server_principal_name"]/value)[1]', 'varchar(100)') AS [server_principal_name]
	  ,XEvent.value('(event/action[@name="session_id"]/value)[1]', 'int') AS [session_id]
	  ,XEvent.value('(event/action[@name="session_resource_group_id"]/value)[1]', 'int') AS [session_resource_group_id]
	  ,XEvent.value('(event/action[@name="session_resource_pool_id"]/value)[1]', 'int') AS [session_resource_pool_id]
	  ,XEvent.value('(event/action[@name="attach_activity_id"]/value)[1]', 'uniqueidentifier ') AS [attach_activity_id]
	  ,XEvent.value('(event/action[@name="attach_activity_id_xfer"]/value)[1]', 'uniqueidentifier ') AS [attach_activity_id_xfer]
FROM dbo.importxeventtrace
WHERE XEvent.value('(event/@name)[1]', 'varchar(50)') in ('rpc_completed','sql_batch_completed','alwayson_ddl_executed')

CREATE INDEX IX_attach_activity_id
ON [dbo].[completed_batches] ([attach_activity_id]);

--Extract the query and plan hash data into the [query_plan_hash] table
INSERT INTO dbo.query_plan_hash
SELECT XEvent.value('(event/action[@name="query_hash"]/value)[1]', 'varchar(100)') AS [query_hash]
	,XEvent.value('(event/action[@name="query_plan_hash"]/value)[1]', 'varchar(100)') AS [query_plan_hash]
	,XEvent.value('(event/action[@name="attach_activity_id"]/value)[1]', 'uniqueidentifier ') AS [attach_activity_id]
	,XEvent.value('(event/action[@name="attach_activity_id_xfer"]/value)[1]', 'uniqueidentifier ') AS [attach_activity_id_xfer]
FROM dbo.importxeventtrace
WHERE XEvent.value('(event/action[@name="query_hash"]/value)[1]', 'varchar(100)') <> '0';

--Create a top 10 queries table, same as SQL Nexus
INSERT INTO unique_batches
SELECT ROW_NUMBER() OVER(ORDER BY [Total_CPU_Time_ms] DESC) AS QueryNumber, [query_hash], Executes, [Total_CPU_Time_ms], [Total_Duration], [Total_Logical_Reads], Total_Physical_Reads, Total_Writes, Total_Row_Count, Attentions, sql_text
FROM (SELECT DISTINCT qpes.[query_hash],MIN(rpc.sql_text) AS sql_text
	,SUM(rpc.[Logical_Reads]) AS [Total_Logical_Reads]
	,SUM(rpc.[CPU_Time]) AS [Total_CPU_Time_ms]
	,SUM(rpc.Duration) AS [Total_Duration]
	,SUM(rpc.Physical_Reads) AS Total_Physical_Reads
	,SUM(rpc.Writes) AS Total_Writes
	,SUM(rpc.Row_Count) AS Total_Row_Count
	,COUNT(qpes.[query_hash]) AS Executes
	,(SELECT COUNT(ied.ID) FROM [dbo].[interesting_events_attention] ied LEFT JOIN dbo.query_plan_hash qpes2 ON ied.[attach_activity_id]=qpes2.[attach_activity_id] WHERE qpes.query_hash=qpes2.query_hash) AS Attentions 
	,ROW_NUMBER() OVER(ORDER BY SUM(rpc.[CPU_Time]) desc) AS CPUDesc
	,ROW_NUMBER() OVER(ORDER BY SUM(rpc.[CPU_Time]) asc) AS CPUAsc
	,ROW_NUMBER() OVER(ORDER BY SUM(rpc.Duration) desc) AS DurationDesc
	,ROW_NUMBER() OVER(ORDER BY SUM(rpc.Duration) asc) AS DurationAsc
	,ROW_NUMBER() OVER(ORDER BY SUM(rpc.[Logical_Reads]) desc) AS ReadsDesc
	,ROW_NUMBER() OVER(ORDER BY SUM(rpc.[Logical_Reads]) asc) AS ReadsAsc
	,ROW_NUMBER() OVER(ORDER BY SUM(rpc.Writes) desc) AS WritesDesc
	,ROW_NUMBER() OVER(ORDER BY SUM(rpc.Writes) asc) AS WritesAsc
	FROM dbo.[completed_batches] rpc
	INNER JOIN dbo.query_plan_hash qpes ON rpc.[attach_activity_id]=qpes.[attach_activity_id] 
	WHERE rpc.[Logical_Reads] > 0 OR rpc.[CPU_Time] > 0
	GROUP BY qpes.[query_hash]
) AS Outcome
WHERE CPUDesc <= 10 OR CPUAsc <= 10 OR DurationDesc <= 10 OR DurationAsc <= 10 
	OR ReadsDesc <= 10 OR ReadsAsc <= 10 OR WritesDesc <= 10 OR WritesAsc <= 10
ORDER BY [Total_CPU_Time_ms] DESC
OPTION (RECOMPILE);

CREATE NONCLUSTERED INDEX [NCCI_unique_batches_reads] ON dbo.unique_batches ([Total_Logical_Reads] DESC);
CREATE NONCLUSTERED INDEX [NCCI_unique_batches_cpu] ON dbo.unique_batches ([Total_CPU_Time_ms] DESC);
CREATE NONCLUSTERED INDEX [NCCI_unique_batches_duration] ON dbo.unique_batches ([Total_Duration] DESC);
CREATE NONCLUSTERED INDEX [NCCI_unique_batches_execs] ON dbo.unique_batches (Executes DESC);
CREATE NONCLUSTERED INDEX [NCCI_unique_batches_writes] ON dbo.unique_batches (Total_Writes DESC);
GO

---------------------------------------------------------------
-- Interesting events
---------------------------------------------------------------
--DECLARE @Message NVARCHAR(100)
SELECT @Message = CONVERT(VARCHAR, GETDATE(), 8) + ' - Aggregating data for interesting events...'
RAISERROR (@Message, 10, 1) WITH NOWAIT
--Get sort warning events
INSERT INTO dbo.[interesting_events_warnings]
SELECT XEvent.value('(event/action[@name="query_hash"]/value)[1]', 'varchar(100)') AS [query_hash]
	  ,XEvent.value('(event/@timestamp)[1]', 'datetime') AS [DateAndTime]
	  ,XEvent.value('(event/@name)[1]', 'varchar(50)') AS [EventName]
      ,XEvent.value('(event/data[@name="sort_warning_type"]/text)[1]', 'varchar(20)') AS [sort_warning_type]
	  ,XEvent.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS [sql_text]
	  ,XEvent.value('(event/action[@name="database_id"]/value)[1]', 'int') AS [database_id]
	  ,XEvent.value('(event/action[@name="database_name"]/value)[1]', 'varchar(100)') AS [database_name]
	  ,XEvent.value('(event/action[@name="client_app_name"]/value)[1]', 'varchar(100)') AS [client_app_name]
	  ,XEvent.value('(event/action[@name="client_hostname"]/value)[1]', 'varchar(100)') AS [client_hostname]
	  ,XEvent.value('(event/action[@name="session_server_principal_name"]/value)[1]', 'varchar(100)') AS [server_principal_name]
	  ,XEvent.value('(event/action[@name="session_id"]/value)[1]', 'int') AS [session_id]
	  ,XEvent.value('(event/action[@name="session_resource_group_id"]/value)[1]', 'int') AS [session_resource_group_id]
	  ,XEvent.value('(event/action[@name="session_resource_pool_id"]/value)[1]', 'int') AS [session_resource_pool_id]
	  ,XEvent.value('(event/action[@name="attach_activity_id"]/value)[1]', 'varchar(100)') AS [attach_activity_id]
FROM dbo.importxeventtrace
WHERE XEvent.value('(event/@name)[1]', 'varchar(50)') = 'sort_warning'
UNION ALL
SELECT XEvent.value('(event/action[@name="query_hash"]/value)[1]', 'varchar(100)') AS [query_hash]
	  ,XEvent.value('(event/@timestamp)[1]', 'datetime') AS [DateAndTime]
	  ,XEvent.value('(event/@name)[1]', 'varchar(50)') AS [EventName]
      ,XEvent.value('(event/data[@name="hash_warning_type"]/text)[1]', 'varchar(20)') AS [hash_warning_type]
	  ,XEvent.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS [sql_text]
	  ,XEvent.value('(event/action[@name="database_id"]/value)[1]', 'int') AS [database_id]
	  ,XEvent.value('(event/action[@name="database_name"]/value)[1]', 'varchar(100)') AS [database_name]
	  ,XEvent.value('(event/action[@name="client_app_name"]/value)[1]', 'varchar(100)') AS [client_app_name]
	  ,XEvent.value('(event/action[@name="client_hostname"]/value)[1]', 'varchar(100)') AS [client_hostname]
	  ,XEvent.value('(event/action[@name="session_server_principal_name"]/value)[1]', 'varchar(100)') AS [server_principal_name]
	  ,XEvent.value('(event/action[@name="session_id"]/value)[1]', 'int') AS [session_id]
	  ,XEvent.value('(event/action[@name="session_resource_group_id"]/value)[1]', 'int') AS [session_resource_group_id]
	  ,XEvent.value('(event/action[@name="session_resource_pool_id"]/value)[1]', 'int') AS [session_resource_pool_id]
	  ,XEvent.value('(event/action[@name="attach_activity_id"]/value)[1]', 'varchar(100)') AS [attach_activity_id]
FROM dbo.importxeventtrace
WHERE XEvent.value('(event/@name)[1]', 'varchar(50)') = 'hash_warning'
UNION ALL
SELECT XEvent.value('(event/action[@name="query_hash"]/value)[1]', 'varchar(100)') AS [query_hash]
	  ,XEvent.value('(event/@timestamp)[1]', 'datetime') AS [DateAndTime]
	  ,XEvent.value('(event/@name)[1]', 'varchar(50)') AS [EventName]
      ,NULL
	  ,XEvent.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS [sql_text]
	  ,XEvent.value('(event/action[@name="database_id"]/value)[1]', 'int') AS [database_id]
	  ,XEvent.value('(event/action[@name="database_name"]/value)[1]', 'varchar(100)') AS [database_name]
	  ,XEvent.value('(event/action[@name="client_app_name"]/value)[1]', 'varchar(100)') AS [client_app_name]
	  ,XEvent.value('(event/action[@name="client_hostname"]/value)[1]', 'varchar(100)') AS [client_hostname]
	  ,XEvent.value('(event/action[@name="session_server_principal_name"]/value)[1]', 'varchar(100)') AS [server_principal_name]
	  ,XEvent.value('(event/action[@name="session_id"]/value)[1]', 'int') AS [session_id]
	  ,XEvent.value('(event/action[@name="session_resource_group_id"]/value)[1]', 'int') AS [session_resource_group_id]
	  ,XEvent.value('(event/action[@name="session_resource_pool_id"]/value)[1]', 'int') AS [session_resource_pool_id]
	  ,XEvent.value('(event/action[@name="attach_activity_id"]/value)[1]', 'varchar(100)') AS [attach_activity_id]
FROM dbo.importxeventtrace
WHERE XEvent.value('(event/@name)[1]', 'varchar(50)') = 'missing_join_predicate';

--Get errors reported
INSERT INTO [interesting_events_errors]
SELECT XEvent.value('(event/action[@name="query_hash"]/value)[1]', 'varchar(100)') AS [query_hash]
	  ,XEvent.value('(event/@timestamp)[1]', 'datetime') AS [DateAndTime]
	  ,XEvent.value('(event/@name)[1]', 'varchar(50)') AS [EventName]
	  ,XEvent.value('(event/data[@name="error_number"]/value)[1]', 'int') AS [error_number]
	  ,XEvent.value('(event/data[@name="severity"]/value)[1]', 'int') AS [error_severity]
	  ,XEvent.value('(event/data[@name="state"]/value)[1]', 'int') AS [error_state]
	  ,XEvent.value('(event/data[@name="user_defined"]/value)[1]', 'varchar(10)') AS [user_defined]
	  ,XEvent.value('(event/data[@name="message"]/value)[1]', 'varchar(500)') AS [message]
	  ,XEvent.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS [sql_text]
	  ,XEvent.value('(event/action[@name="database_id"]/value)[1]', 'int') AS [database_id]
	  ,XEvent.value('(event/action[@name="database_name"]/value)[1]', 'varchar(100)') AS [database_name]
	  ,XEvent.value('(event/action[@name="client_app_name"]/value)[1]', 'varchar(100)') AS [client_app_name]
	  ,XEvent.value('(event/action[@name="client_hostname"]/value)[1]', 'varchar(100)') AS [client_hostname]
	  ,XEvent.value('(event/action[@name="session_server_principal_name"]/value)[1]', 'varchar(100)') AS [server_principal_name]
	  ,XEvent.value('(event/action[@name="session_id"]/value)[1]', 'int') AS [session_id]
	  ,XEvent.value('(event/action[@name="session_resource_group_id"]/value)[1]', 'int') AS [session_resource_group_id]
	  ,XEvent.value('(event/action[@name="session_resource_pool_id"]/value)[1]', 'int') AS [session_resource_pool_id]
	  ,XEvent.value('(event/action[@name="attach_activity_id"]/value)[1]', 'varchar(100)') AS [attach_activity_id]
FROM dbo.importxeventtrace
WHERE XEvent.value('(event/@name)[1]', 'varchar(50)') = 'error_reported';

--Get missing_column_statistics events
INSERT INTO interesting_events_missing_column_statistics
SELECT XEvent.value('(event/@timestamp)[1]', 'datetime') AS [DateAndTime]
	  ,XEvent.value('(event/@name)[1]', 'varchar(50)') AS [EventName]
	  ,XEvent.value('(event/data[@name="column_list"]/value)[1]', 'varchar(max)') AS [column_list]
	  ,XEvent.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS [sql_text]
	  ,XEvent.value('(event/action[@name="database_id"]/value)[1]', 'int') AS [database_id]
	  ,XEvent.value('(event/action[@name="database_name"]/value)[1]', 'varchar(100)') AS [database_name]
	  ,XEvent.value('(event/action[@name="client_app_name"]/value)[1]', 'varchar(100)') AS [client_app_name]
	  ,XEvent.value('(event/action[@name="client_hostname"]/value)[1]', 'varchar(100)') AS [client_hostname]
	  ,XEvent.value('(event/action[@name="session_server_principal_name"]/value)[1]', 'varchar(100)') AS [server_principal_name]
	  ,XEvent.value('(event/action[@name="attach_activity_id"]/value)[1]', 'varchar(100)') AS [attach_activity_id]
FROM dbo.importxeventtrace
WHERE XEvent.value('(event/@name)[1]', 'varchar(50)') = 'missing_column_statistics';

--Get auto_stats events
INSERT INTO interesting_events_auto_stats
SELECT XEvent.value('(event/@timestamp)[1]', 'datetime') AS [DateAndTime]
	  ,XEvent.value('(event/@name)[1]', 'varchar(50)') AS [EventName]
	  ,XEvent.value('(event/data[@name="statistics_list"]/value)[1]', 'varchar(255)') AS [statistics_list]
	  ,XEvent.value('(event/data[@name="duration"]/value)[1]', 'bigint') AS [duration]
	  ,XEvent.value('(event/data[@name="retries"]/value)[1]', 'bigint') AS [retries]
	  ,XEvent.value('(event/data[@name="success"]/value)[1]', 'varchar(10)') AS [success]
	  ,XEvent.value('(event/action[@name="database_id"]/value)[1]', 'int') AS [database_id]
	  ,XEvent.value('(event/action[@name="database_name"]/value)[1]', 'varchar(100)') AS [database_name]
	  ,XEvent.value('(event/data[@name="object_id"]/value)[1]', 'bigint') AS [object_id]
	  ,XEvent.value('(event/data[@name="index_id"]/value)[1]', 'int') AS [index_id]
	  ,XEvent.value('(event/data[@name="job_id"]/value)[1]', 'int') AS [job_id]
	  ,XEvent.value('(event/data[@name="job_type"]/text)[1]', 'varchar(50)') AS [job_type]
	  ,XEvent.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS [sql_text]
	  ,XEvent.value('(event/action[@name="client_app_name"]/value)[1]', 'varchar(100)') AS [client_app_name]
	  ,XEvent.value('(event/action[@name="client_hostname"]/value)[1]', 'varchar(100)') AS [client_hostname]
	  ,XEvent.value('(event/action[@name="session_server_principal_name"]/value)[1]', 'varchar(100)') AS [server_principal_name]
	  ,XEvent.value('(event/action[@name="attach_activity_id"]/value)[1]', 'varchar(100)') AS [attach_activity_id]
FROM dbo.importxeventtrace
WHERE XEvent.value('(event/@name)[1]', 'varchar(50)') = 'auto_stats';

--Get attention events
INSERT INTO dbo.[interesting_events_attention]
SELECT XEvent.value('(event/@timestamp)[1]', 'datetime') AS [DateAndTime]
	  ,XEvent.value('(event/@name)[1]', 'varchar(50)') AS [EventName]
	  ,XEvent.value('(event/data[@name="duration"]/value)[1]', 'bigint') AS [Duration]
	  ,XEvent.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS [sql_text]
	  ,XEvent.value('(event/action[@name="database_id"]/value)[1]', 'int') AS [database_id]
	  ,XEvent.value('(event/action[@name="database_name"]/value)[1]', 'varchar(100)') AS [database_name]
	  ,XEvent.value('(event/action[@name="client_app_name"]/value)[1]', 'varchar(100)') AS [client_app_name]
	  ,XEvent.value('(event/action[@name="client_hostname"]/value)[1]', 'varchar(100)') AS [client_hostname]
	  ,XEvent.value('(event/action[@name="session_server_principal_name"]/value)[1]', 'varchar(100)') AS [server_principal_name]
	  ,XEvent.value('(event/action[@name="session_id"]/value)[1]', 'int') AS [session_id]
	  ,XEvent.value('(event/action[@name="session_resource_group_id"]/value)[1]', 'int') AS [session_resource_group_id]
	  ,XEvent.value('(event/action[@name="session_resource_pool_id"]/value)[1]', 'int') AS [session_resource_pool_id]
	  ,XEvent.value('(event/action[@name="attach_activity_id"]/value)[1]', 'varchar(100)') AS [attach_activity_id]
FROM dbo.importxeventtrace
WHERE XEvent.value('(event/@name)[1]', 'varchar(50)') = 'attention';

--Get deprecated events
INSERT INTO [interesting_events_deprecation]
SELECT XEvent.value('(event/data[@name="feature_id"]/value)[1]', 'smallint') AS [feature_id]
	  ,XEvent.value('(event/@timestamp)[1]', 'datetime') AS [DateAndTime]
	  ,XEvent.value('(event/@name)[1]', 'varchar(50)') AS [EventName]
	  ,XEvent.value('(event/data[@name="feature"]/value)[1]', 'varchar(100)') AS [feature]
	  ,XEvent.value('(event/data[@name="message"]/value)[1]', 'varchar(500)') AS [message]
	  ,XEvent.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS [sql_text]
	  ,XEvent.value('(event/action[@name="database_id"]/value)[1]', 'int') AS [database_id]
	  ,XEvent.value('(event/action[@name="database_name"]/value)[1]', 'varchar(100)') AS [database_name]
	  ,XEvent.value('(event/action[@name="client_app_name"]/value)[1]', 'varchar(100)') AS [client_app_name]
	  ,XEvent.value('(event/action[@name="client_hostname"]/value)[1]', 'varchar(100)') AS [client_hostname]
	  ,XEvent.value('(event/action[@name="session_server_principal_name"]/value)[1]', 'varchar(100)') AS [server_principal_name]
	  ,XEvent.value('(event/action[@name="session_id"]/value)[1]', 'int') AS [session_id]
	  ,XEvent.value('(event/action[@name="session_resource_group_id"]/value)[1]', 'int') AS [session_resource_group_id]
	  ,XEvent.value('(event/action[@name="session_resource_pool_id"]/value)[1]', 'int') AS [session_resource_pool_id]
	  ,XEvent.value('(event/action[@name="attach_activity_id"]/value)[1]', 'uniqueidentifier ') AS [attach_activity_id]
	  ,XEvent.value('(event/action[@name="attach_activity_id_xfer"]/value)[1]', 'uniqueidentifier ') AS [attach_activity_id_xfer]
FROM dbo.importxeventtrace
WHERE XEvent.value('(event/@name)[1]', 'varchar(50)') IN ('deprecation_announcement','deprecation_final_support');

--Get lock escalation events
INSERT INTO [interesting_events_lock_escalation]
SELECT XEvent.value('(event/@timestamp)[1]', 'datetime') AS [DateAndTime]
	  ,XEvent.value('(event/@name)[1]', 'varchar(50)') AS [EventName]
	  ,XEvent.value('(event/data[@name="escalation_cause"]/text)[1]', 'varchar(50)') AS [escalation_cause]
	  ,XEvent.value('(event/data[@name="resource_type"]/text)[1]', 'varchar(100)') AS [resource_type]
	  ,XEvent.value('(event/data[@name="mode"]/text)[1]', 'varchar(10)') AS [mode]
	  ,XEvent.value('(event/data[@name="owner_type"]/text)[1]', 'varchar(50)') AS [owner_type]
	  ,XEvent.value('(event/data[@name="database_id"]/value)[1]', 'int') AS [database_id]
	  ,XEvent.value('(event/action[@name="database_name"]/value)[1]', 'varchar(100)') AS [database_name]
	  ,XEvent.value('(event/data[@name="object_id"]/value)[1]', 'bigint') AS [object_id]
	  ,XEvent.value('(event/data[@name="hobt_id"]/value)[1]', 'bigint') AS [hobt_id]
	  ,XEvent.value('(event/data[@name="escalated_lock_count"]/value)[1]', 'int') AS [escalated_lock_count]
	  ,XEvent.value('(event/data[@name="hobt_lock_count"]/value)[1]', 'int') AS [hobt_lock_count]
	  ,XEvent.value('(event/data[@name="statement"]/value)[1]', 'nvarchar(max)') AS [sql_text]
	  ,XEvent.value('(event/action[@name="query_hash"]/value)[1]', 'varchar(100)') AS [query_hash]
	  ,XEvent.value('(event/action[@name="client_app_name"]/value)[1]', 'varchar(100)') AS [client_app_name]
	  ,XEvent.value('(event/action[@name="client_hostname"]/value)[1]', 'varchar(100)') AS [client_hostname]
	  ,XEvent.value('(event/action[@name="session_server_principal_name"]/value)[1]', 'varchar(100)') AS [server_principal_name]
	  ,XEvent.value('(event/action[@name="session_id"]/value)[1]', 'int') AS [session_id]
	  ,XEvent.value('(event/action[@name="session_resource_group_id"]/value)[1]', 'int') AS [session_resource_group_id]
	  ,XEvent.value('(event/action[@name="session_resource_pool_id"]/value)[1]', 'int') AS [session_resource_pool_id]
	  ,XEvent.value('(event/action[@name="attach_activity_id"]/value)[1]', 'uniqueidentifier ') AS [attach_activity_id]
	  ,XEvent.value('(event/action[@name="attach_activity_id_xfer"]/value)[1]', 'uniqueidentifier ') AS [attach_activity_id_xfer]
FROM dbo.importxeventtrace
WHERE XEvent.value('(event/@name)[1]', 'varchar(50)') = 'lock_escalation';

--Get blocked process reports
INSERT INTO [interesting_events_blocked_process]
SELECT XEvent.value('(event/@timestamp)[1]', 'datetime') AS [DateAndTime]
	,XEvent.value('(event/@name)[1]', 'varchar(50)') AS [EventName]
	,XEvent.value('(event/data[@name="resource_owner_type"]/text)[1]', 'varchar(100)') AS [resource_owner_type]
	,XEvent.value('(event/data/value/blocked-process-report/blocked-process/process/@spid)[1]', 'int') AS [blocked_spid]
	,XEvent.value('(event/data/value/blocked-process-report/blocked-process/process/@waitresource)[1]', 'varchar(100)') AS [blocked_wait_resource]
	,XEvent.value('(event/data/value/blocked-process-report/blocked-process/process/@waittime)[1]', 'int') AS [blocked_wait_time]
	,XEvent.value('(event/data[@name="database_id"]/value)[1]', 'int') AS [blocked_database_id]
	,XEvent.value('(event/data[@name="object_id"]/value)[1]', 'bigint') AS [blocked_object_id]
	,XEvent.value('(event/data[@name="index_id"]/value)[1]', 'int') AS [blocked_index_id]
	--,XEvent.value('(event/data/value/blocked-process-report/blocked-process/process/@currentdb)[1]', 'int') AS [database_id]
	,XEvent.value('(event/data/value/blocked-process-report/blocked-process/process/@transactionname)[1]', 'varchar(100)') AS [blocked_transaction_name]
	,XEvent.value('(event/data/value/blocked-process-report/blocked-process/process/@lockMode)[1]', 'varchar(10)') AS [blocked_lock_Mode]
	,XEvent.value('(event/data/value/blocked-process-report/blocked-process/process/@status)[1]', 'varchar(10)') AS [blocked_status]
	,XEvent.value('(event/data/value/blocked-process-report/blocked-process/process/@isolationlevel)[1]', 'varchar(100)') AS [blocked_isolationlevel]
	,XEvent.value('(event/data/value/blocked-process-report/blocked-process/process/@clientapp)[1]', 'varchar(100)') AS [blocked_client_app_name]
	,XEvent.value('(event/data/value/blocked-process-report/blocked-process/process/@hostname)[1]', 'varchar(100)') AS [blocked_client_hostname]
	,XEvent.value('(event/data/value/blocked-process-report/blocked-process/process/@loginname)[1]', 'varchar(100)') AS [blocked_login_name]
	,XEvent.value('(event/data/value/blocked-process-report/blocked-process/process/inputbuf)[1]', 'nvarchar(max)') AS [blocked_inputbuf]
	,XEvent.value('(event/data/value/blocked-process-report/blocking-process/process/@spid)[1]', 'int') AS [blocking_spid]
	,XEvent.value('(event/data/value/blocked-process-report/blocking-process/process/@waittime)[1]', 'int') AS [blocking_wait_time]
	,XEvent.value('(event/data/value/blocked-process-report/blocking-process/process/@currentdb)[1]', 'int') AS [blocking_database_id]
	,XEvent.value('(event/data/value/blocked-process-report/blocking-process/process/@lockMode)[1]', 'varchar(10)') AS [blocking_lock_Mode]
	,XEvent.value('(event/data/value/blocked-process-report/blocking-process/process/@status)[1]', 'varchar(10)') AS [blocking_status]
	,XEvent.value('(event/data/value/blocked-process-report/blocking-process/process/@isolationlevel)[1]', 'varchar(100)') AS [blocking_isolationlevel]
	,XEvent.value('(event/data/value/blocked-process-report/blocking-process/process/@clientapp)[1]', 'varchar(100)') AS [blocking_client_app_name]
	,XEvent.value('(event/data/value/blocked-process-report/blocking-process/process/@hostname)[1]', 'varchar(100)') AS [blocking_client_hostname]
	,XEvent.value('(event/data/value/blocked-process-report/blocking-process/process/@loginname)[1]', 'varchar(100)') AS [blocking_login_name]
	,XEvent.value('(event/data/value/blocked-process-report/blocking-process/process/inputbuf)[1]', 'nvarchar(max)') AS [blocking_inputbuf]
FROM dbo.importxeventtrace
WHERE XEvent.value('(event/@name)[1]', 'varchar(50)') = 'blocked_process_report';
GO

/*
--Finally we can now get the top consuming queries, grouping on the query_hash:

--Get top consuming queries, ordered by reads
SELECT QueryNumber,[Total_CPU_Time_ms] AS CPU,[Total_Duration] AS Duration,[Total_Logical_Reads] AS Reads
,Total_Physical_Reads AS PReads,Total_Writes AS Writes,Executes,Attentions,Total_Row_Count AS RowCnt,[query_hash],sql_text
FROM dbo.[unique_batches]
ORDER BY [Total_Logical_Reads] DESC;

-- Get top consuming queries, ordered by writes
SELECT QueryNumber,[Total_CPU_Time_ms] AS CPU,[Total_Duration] AS Duration,[Total_Logical_Reads] AS Reads
,Total_Physical_Reads AS PReads,Total_Writes AS Writes,Executes,Attentions,Total_Row_Count AS RowCnt,[query_hash],sql_text
FROM dbo.[unique_batches]
ORDER BY [Total_Writes] DESC;

-- Get top consuming queries, ordered by cpu
SELECT QueryNumber,[Total_CPU_Time_ms] AS CPU,[Total_Duration] AS Duration,[Total_Logical_Reads] AS Reads
,Total_Physical_Reads AS PReads,Total_Writes AS Writes,Executes,Attentions,Total_Row_Count AS RowCnt,[query_hash],sql_text
FROM dbo.[unique_batches]
ORDER BY [Total_CPU_Time_ms] DESC;

-- Get top consuming queries, ordered by duration
SELECT QueryNumber,[Total_CPU_Time_ms] AS CPU,[Total_Duration] AS Duration,[Total_Logical_Reads] AS Reads
,Total_Physical_Reads AS PReads,Total_Writes AS Writes,Executes,Attentions,Total_Row_Count AS RowCnt,[query_hash],sql_text
FROM dbo.[unique_batches]
ORDER BY [Total_Duration] DESC;

-- Get top queries, ordered by number of executions
SELECT QueryNumber,[Total_CPU_Time_ms] AS CPU,[Total_Duration] AS Duration,[Total_Logical_Reads] AS Reads
,Total_Physical_Reads AS PReads,Total_Writes AS Writes,Executes,Attentions,Total_Row_Count AS RowCnt,[query_hash],sql_text
FROM dbo.[unique_batches]
ORDER BY Executes DESC;

-- Get Warnings
SELECT COUNT([query_hash]) AS [Events],[EventName],[warning_type],MIN([sql_text]) AS [sql_text],[query_hash],[database_id],[database_name],[client_app_name],[client_hostname],[server_principal_name]
FROM [dbo].[interesting_events_warnings]
GROUP BY [EventName],[warning_type],[database_id],[database_name],[client_app_name],[client_hostname],[server_principal_name],[query_hash]
ORDER BY COUNT([query_hash]) DESC,[EventName],[warning_type];

-- Get Error events
SELECT COUNT([query_hash]) AS [Events],[error_number],[error_severity],[error_state]
FROM [dbo].[interesting_events_errors]
GROUP BY [EventName],[error_number],[error_severity],[error_state]
ORDER BY COUNT([query_hash]) DESC,[error_number];

SELECT COUNT([query_hash]) AS [Events],[EventName],[error_number],[error_severity],[error_state]
	,[user_defined],[message],MIN([sql_text]) AS [sql_text],[query_hash]
	,[database_id],[database_name],[client_app_name],[client_hostname]
	,[server_principal_name],[session_id],[session_resource_group_id],[session_resource_pool_id]
FROM [dbo].[interesting_events_errors]
GROUP BY [EventName],[error_number],[error_severity],[error_state],[query_hash]
	,[user_defined],[message],[database_id],[database_name],[client_app_name],[client_hostname]
	,[server_principal_name],[session_id],[session_resource_group_id],[session_resource_pool_id]
ORDER BY COUNT([query_hash]) DESC,[error_number];

-- Get missing column statistics events
SELECT COUNT([DateAndTime]) AS [Events],[EventName],[column_list],MIN([sql_text]) AS [sql_text],qpes.query_hash,[database_id],[database_name],[client_app_name],[client_hostname],[server_principal_name]
FROM [dbo].interesting_events_missing_column_statistics ied
LEFT JOIN dbo.query_plan_hash qpes ON ied.[attach_activity_id]=qpes.[attach_activity_id] 
GROUP BY [EventName],[column_list],[database_id],[database_name],[client_app_name],[client_hostname],[server_principal_name],qpes.query_hash
ORDER BY COUNT([DateAndTime]) DESC,[EventName];

-- Get AutoStats events
SELECT COUNT([DateAndTime]) AS [Events],[EventName],[statistics_list],AVG([Duration]) AS [Average_Duration],AVG([retries]) AS [Average_retries],[success],[database_id],[database_name]
	,[object_id],OBJECT_NAME([object_id],[database_id]) AS [object_name],[index_id],[job_id],[job_type],MIN([sql_text]) AS [sql_text],qpes.query_hash,[client_app_name],[client_hostname],[server_principal_name]
FROM [dbo].interesting_events_auto_stats ied
LEFT JOIN dbo.query_plan_hash qpes ON ied.[attach_activity_id]=qpes.[attach_activity_id] 
GROUP BY [EventName],[statistics_list],[success],[database_id],[database_name]
	,[object_id],[index_id],[job_id],[job_type],[client_app_name],[client_hostname],[server_principal_name],qpes.query_hash
ORDER BY COUNT([DateAndTime]) DESC,[EventName];

-- Get attention events
SELECT COUNT([DateAndTime]) AS [Events],[EventName],AVG([Duration]) AS [Average_Duration_before_Attention],MIN([sql_text]) AS [sql_text],qpes.query_hash,[database_id],[database_name],[client_app_name],[client_hostname],[server_principal_name]
FROM [dbo].[interesting_events_attention] ied
LEFT JOIN dbo.query_plan_hash qpes ON ied.[attach_activity_id]=qpes.[attach_activity_id] 
GROUP BY [EventName],[database_id],[database_name],[client_app_name],[client_hostname],[server_principal_name],qpes.query_hash
ORDER BY COUNT([DateAndTime]) DESC;

-- Get deprecated events
SELECT COUNT([DateAndTime]) AS [Events],[EventName],[feature],[message],MIN([sql_text]) AS [sql_text],qpes.query_hash,[database_id],[database_name],[client_app_name],[client_hostname],[server_principal_name]
FROM [dbo].[interesting_events_deprecation] ied
LEFT JOIN dbo.query_plan_hash qpes ON ied.[attach_activity_id]=qpes.[attach_activity_id] 
GROUP BY [EventName],[feature],[message],[database_id],[database_name],[client_app_name],[client_hostname],[server_principal_name],qpes.query_hash
ORDER BY COUNT([DateAndTime]) DESC;

-- Get lock escalation information
SELECT COUNT([DateAndTime]) AS [Events],[EventName],[escalation_cause],AVG([escalated_lock_count]) AS Average_escalated_lock_count
	,AVG([hobt_lock_count]) AS Average_hobt_lock_count, MIN([sql_text]) AS [sql_text],qpes.query_hash,[database_id],[database_name]
	,[client_app_name],[client_hostname],[server_principal_name]
FROM [dbo].[interesting_events_lock_escalation] ied
LEFT JOIN dbo.query_plan_hash qpes ON ied.[attach_activity_id]=qpes.[attach_activity_id] 
GROUP BY [EventName],[escalation_cause],[database_id],[database_name],[client_app_name],[client_hostname],[server_principal_name],qpes.query_hash
ORDER BY COUNT([DateAndTime]) DESC;

SELECT COUNT([DateAndTime]) AS [Events],[EventName],[escalation_cause],AVG([escalated_lock_count]) AS Average_escalated_lock_count,
	AVG([hobt_lock_count]) AS Average_hobt_lock_count,[resource_type],[mode],[owner_type],MIN([sql_text]) AS [sql_text],qpes.query_hash
	,[database_id],[database_name],[object_id],OBJECT_NAME([object_id],[database_id]) AS [object_name]
	,[hobt_id],[client_app_name],[client_hostname],[server_principal_name]
FROM [dbo].[interesting_events_lock_escalation] ied
LEFT JOIN dbo.query_plan_hash qpes ON ied.[attach_activity_id]=qpes.[attach_activity_id] 
GROUP BY [EventName],[escalation_cause],[resource_type],[mode],[owner_type],[database_id],[database_name],[object_id],[hobt_id],[client_app_name],[client_hostname],[server_principal_name],qpes.query_hash
ORDER BY COUNT([DateAndTime]) DESC;

-- Get blocked processes
SELECT COUNT([DateAndTime]) AS [Events],[EventName],[resource_owner_type]
	,[blocked_spid],[blocked_wait_resource],AVG([blocked_wait_time]) AS [blocked_Average_wait_time],[blocked_database_id]
	,DB_NAME([blocked_database_id]) AS [blocked_database_name],[blocked_object_id]
	,OBJECT_NAME([blocked_object_id],[blocked_database_id]) AS [blocked_object_name]
	,[blocked_index_id],[blocked_transaction_name],[blocked_lock_Mode],[blocked_status],[blocked_isolationlevel]
	,[blocked_client_app_name],[blocked_client_hostname],[blocked_login_name],[blocked_inputbuf]
	,[blocking_spid],AVG([blocking_wait_time]) AS [blocking_Average_wait_time]
	,[blocking_database_id],DB_NAME([blocking_database_id]) AS [blocking_database_name],[blocking_lock_Mode],[blocking_status]
	,[blocking_isolationlevel],[blocking_client_app_name],[blocking_client_hostname],[blocking_login_name],[blocking_inputbuf]
FROM [dbo].[interesting_events_blocked_process]
GROUP BY [EventName],[resource_owner_type]
	,[blocked_spid],[blocked_wait_resource],[blocked_database_id],[blocked_object_id]
	,[blocked_index_id],[blocked_transaction_name],[blocked_lock_Mode],[blocked_status],[blocked_isolationlevel]
	,[blocked_client_app_name],[blocked_client_hostname],[blocked_login_name],[blocked_inputbuf]
	,[blocking_spid],[blocking_database_id],[blocking_lock_Mode],[blocking_status]
	,[blocking_isolationlevel],[blocking_client_app_name],[blocking_client_hostname],[blocking_login_name],[blocking_inputbuf];
GO
*/

--Get other warning events - need examples, anyone care to send one?
SELECT XEvent.value('(event/@name)[1]', 'varchar(50)') AS [EventName], *
FROM dbo.importxeventtrace
WHERE XEvent.value('(event/@name)[1]', 'varchar(50)') 
	IN ('additional_memory_grant','bad_memory_detected','bad_memory_fixed',
		'batch_hash_table_build_bailout','exchange_spill','execution_warning',
		'oledb_error','progress_report_online_index_operation')
GO