set-strictmode -version 2

function Copy-ZDatabase
{
  [cmdletbinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]

  param(
  [parameter(Mandatory=$true)] [string]$Database,
  [parameter] [string]$SourceSQLInstance = 'PSQL03\INSLOB01',
  [parameter] [string]$DestinationSqlInstance = 'SAZRWSQLP06\INSLOB01',
  [parameter] [string]$CopyDestinationFolder = '\\Sazrwsqlp06\ls',
  [parameter] [string]$SharedPath = '\\PSQL03\LogShipping',
  [parameter] [string]$LocalPath = 'X:\Program Files\Microsoft SQL Server\MSSQL10_50.INSLOB01\MSSQL\LogShipping'
  )

 # REMOVE Log Shipping jobs prior to running the below to avoid confusion...

     $params = @{
        SourceSqlInstance = $SourceSQLInstance
        DestinationSqlInstance = $DestinationSqlInstance
        CopyDestinationFolder = $CopyDestinationFolder

        Database = $Database
        SharedPath= $SharedPath
        LocalPath= $LocalPath

        BackupScheduleFrequencyType = 'Daily'
        BackupScheduleFrequencyInterval = 1
        CompressBackup = $true
        CopyScheduleFrequencyType = 'Daily'
        CopyScheduleFrequencyInterval = 1
        GenerateFullBackup = $true
        RestoreScheduleFrequencyType = 'Daily'
        RestoreScheduleFrequencyInterval = 1
        SecondaryDatabaseSuffix = 'DR'
        Force = $true
     } 
     
     # Invoke-DbaDbLogShipping @params -Verbose
    }

function Move-ZDatabase
{
  [cmdletbinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]

  param(
  [parameter(Mandatory=$true)] [string]$Database,
  [parameter] [string]$SourceSQLInstance = 'SWLGWSQLP06\INSLOB01',
  [parameter] [string]$DestinationSqlInstance = 'PSQL03\INSLOB01',
  [parameter] [string]$SharedPath = '\\psql03\backup'
  )

   # Test any migration consraints prior to actually migrating the database...
  Test-DbaMigrationConstraint -Source $SourceSQLInstance -Destination $DestinationSqlInstance  -Database $Database

  Copy-DbaDatabase -Source $SourceSQLInstance -Destination $DestinationSqlInstance -Database $Database `
       -BackupRestore -SharedPath $SharedPath -NumberFiles 1 -NoBackupCleanup -SetSourceOffline -Verbose

}

function Get-ZDatabase
{
  Write-Host 'Inside private helper function, Get-ZDatabase.'
}


