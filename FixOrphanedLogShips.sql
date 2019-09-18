----- on primary
delete from [dbo].[log_shipping_monitor_primary]
where primary_database = 'DRMS_DirectoryServices_adrms_gel_local_443DR'       -- Change the database name 
go
delete from [dbo].[log_shipping_primary_databases]
where primary_database = 'DRMS_DirectoryServices_adrms_gel_local_443DR'        -- Change the database name
go
delete from [dbo].[log_shipping_primary_secondaries]
where secondary_database = 'DRMS_DirectoryServices_adrms_gel_local_443DR'      -- Change the database name


----- on Secondary
delete from [dbo].[log_shipping_monitor_secondary]
where secondary_database  = 'DRMS_DirectoryServices_adrms_gel_local_443DR'     -- Change the database name
go
delete from [dbo].[log_shipping_secondary]
where primary_database = 'DRMS_DirectoryServices_adrms_gel_local_443DR'        -- Change the database name
go
delete from [dbo].[log_shipping_secondary_databases]
where secondary_database = 'DRMS_DirectoryServices_adrms_gel_local_443DR'      -- Change the database name