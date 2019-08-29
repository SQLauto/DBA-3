<#
Copy-DbaDatabase -Source 'SWLGWSQLP06\INSLOB01' -Destination 'PSQL03\INSLOB01' -Database 'WorkOrderPortal' `
     -BackupRestore -SharedPath '\\psql03\backup' -NumberFiles 1 -NoBackupCleanup -SetSourceOffline -Verbose
 #>

 # REMOVE Log Shipping jobs prior to running the below to avoid confusion...

     $params = @{
        SourceSqlInstance = 'PSQL03\INSLOB01'
        DestinationSqlInstance = 'SAZRWSQLP06\INSLOB01'
        Database = 'WorkOrderPortal'
        SharedPath= '\\PSQL03\LogShipping'
        LocalPath= 'X:\Program Files\Microsoft SQL Server\MSSQL10_50.INSLOB01\MSSQL\LogShipping'
        BackupScheduleFrequencyType = 'Daily'
        BackupScheduleFrequencyInterval = 1
        CompressBackup = $true
        CopyScheduleFrequencyType = 'Daily'
        CopyScheduleFrequencyInterval = 1
        GenerateFullBackup = $true
        RestoreScheduleFrequencyType = 'Daily'
        RestoreScheduleFrequencyInterval = 1
        SecondaryDatabaseSuffix = 'DR'
        CopyDestinationFolder = '\\Sazrwsqlp06\ls'
        Force = $true
     } 
     
     Invoke-DbaDbLogShipping @params -Verbose
