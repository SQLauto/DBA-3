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

       /* ----------------------------------------------------------------------------
       WHERE statement to find Device Backups with '{' and date n days back
       ------------------------------------------------------------------------------- */
       -- AND     physical_device_name LIKE '{%'

       /* -------------------------------------------------------------------------------
       WHERE statement to find Backups saved in standard directories, msdb.dbo.backupfile AS b 
       ---------------------------------------------------------------------------------- */
       -- AND     physical_device_name  LIKE '[fF]:%'                          -- STANDARD F: Backup Directory
       -- AND     physical_device_name  NOT LIKE '[nN]:%'                      -- STANDARD N: Backup Directory

       -- AND     physical_device_name  NOT LIKE '{%'                          -- Outstanding Analysis
       -- AND     physical_device_name  NOT LIKE '%$\Sharepoint$\%' ESCAPE '$' -- Sharepoint Backs up to Share
       -- AND     backupset_name NOT LIKE '%Galaxy%'                           -- CommVault Sympana Backup


       /* -------------------------------------------------------------------------------
       WHERE Statement to find backup information for a certain period of time, msdb.dbo.backupset AS b 
       ---------------------------------------------------------------------------------- 
       AND    (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 7)  -- 7 days old or younger
       AND    (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) <= GETDATE())  -- n days old or older

       */

       /* -------------------------------------------------------------------------------
       WHERE Statement to find backup information for (a) given database(s) 
       ---------------------------------------------------------------------------------- */
       AND database_name IN ('ZIntegrationControl') -- database names
       -- AND     database_name IN ('rtc')  -- database names

        /* -------------------------------------------------------------------------------
        ORDER Clause for other statements
        ---------------------------------------------------------------------------------- */
        --ORDER BY        msdb.dbo.backupset.database_name, msdb.dbo.backupset.backup_finish_date -- order clause

        ---WHERE msdb..backupset.type = 'I' OR  msdb..backupset.type = 'D'
ORDER BY
       --2,

       2       DESC,
       3       DESC 