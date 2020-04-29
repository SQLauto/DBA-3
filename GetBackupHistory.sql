/* ==================================================================
 Author......:  hot2use 
 Date........:  25.04.2018
 Version.....:  0.1
 Server......:  localhost (first created for)
 Database....:  msdb
 Owner.......:  -
 Table.......:  various
 Type........:  Script
 Name........:  ADMIN_Retrieve_Backup_History_Information.sql
 Description.:  Retrieve backup history information from msdb database
 ............   
 ............   
 ............       
 History.....:   0.1    h2u First created
 ............       
 ............       
================================================================== */
SELECT /* Columns for retrieving information */
       -- CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS SRVNAME, 
       msdb.dbo.backupset.database_name,
       msdb.dbo.backupset.backup_start_date,
       msdb.dbo.backupset.backup_finish_date,
       -- msdb.dbo.backupset.expiration_date, 

       CASE msdb.dbo.backupset.type
            WHEN 'D' THEN 'Full'
            WHEN 'I' THEN 'Diff'
            WHEN 'L' THEN 'Log'
       END  AS backup_type,
       -- msdb.dbo.backupset.backup_size / 1024 / 1024 as [backup_size MB],  
       msdb.dbo.backupmediafamily.logical_device_name,
       msdb.dbo.backupmediafamily.physical_device_name,
       -- msdb.dbo.backupset.name AS backupset_name,
       -- msdb.dbo.backupset.description,
       msdb.dbo.backupset.is_copy_only,
       msdb.dbo.backupset.is_snapshot,
       msdb.dbo.backupset.checkpoint_lsn,
       msdb.dbo.backupset.database_backup_lsn,
       msdb.dbo.backupset.differential_base_lsn,
       msdb.dbo.backupset.first_lsn,
       msdb.dbo.backupset.fork_point_lsn,
       msdb.dbo.backupset.last_lsn
FROM   msdb.dbo.backupmediafamily
       INNER JOIN msdb.dbo.backupset
            ON  msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 

        /* ----------------------------------------------------------------------------
        Generic WHERE statement to simplify selection of more WHEREs    
        -------------------------------------------------------------------------------*/
WHERE  1 = 1

	    AND database_name = 'PC'
        AND msdb..backupset.type = 'I' 
ORDER BY
       --2,

       2       DESC,
       3       DESC 