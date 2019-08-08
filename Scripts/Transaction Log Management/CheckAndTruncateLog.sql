-- Switch to your database

:SETVAR TargetServer (local)\sqldev02
:SETVAR TargetDB SalesDW
:SETVAR TargetBackupLogFile c:\sqlskills\backuplog.trn
:SETVAR TargetBackupDatabaseFile c:\sqlskills\backupdatabase.bak
:SETVAR TargetLogSize 50MB

:CONNECT $(TargetServer)

USE $(TargetDB)
GO

:ON ERROR EXIT
GO

declare @LogName varchar(255) = (select name from sys.database_files where type_desc = 'LOG')

-- Check VLF Count for current database
DBCC LogInfo;

-- Check individual File Sizes and space available for current database
SELECT name AS [File Name] , physical_name AS [Physical Name], size/128.0 AS [Total Size in MB],
size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS [Available Space In MB], [file_id]
FROM sys.database_files;

select * from sys.databases where name = '$(TargetDB)'

select @LogName

-- Step 1: Compressed backup of the transaction log (backup compression requires Enterprise Edition in SQL Server 2008)


BACKUP DATABASE $(TargetDB) TO  DISK = N'$(TargetBackupDatabaseFile)' WITH NOFORMAT, INIT,  
SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 1;

BACKUP LOG $(TargetDB) TO  DISK = N'$(TargetBackupLogFile)' WITH NOFORMAT, INIT,  
SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 1;


-- Step 2: Shrink the log file
DBCC SHRINKFILE (@LogName , 0, TRUNCATEONLY);

USE [master]

declare @execstr varchar(255) = 

'ALTER DATABASE ' + '$(TargetDB)' +
 ' MODIFY FILE (NAME = N''' + @LogName + ''',  SIZE = $(TargetLogSize))'
--select @execstr
exec (@execstr) 

-- Check VLF Count for current database
DBCC LogInfo;

-- Switch back to your database
USE $(TargetDB)
GO

-- Check VLF Count for current database after growing log file
DBCC LogInfo;

