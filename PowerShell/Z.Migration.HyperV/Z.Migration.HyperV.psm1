set-strictmode -version 2

function Copy-ZDatabase
{
  [cmdletbinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]

  param(
  [parameter(Mandatory=$true)] [string]$Database,
  [string]$SourceSQLInstance = 'PSQL03\INSLOB01',
  [string]$DestinationSqlInstance = 'SAZRWSQLP06\INSLOB01',
  [string]$CopyDestinationFolder = '\\SAZRWSQLP06\LS',
  [string]$SharedPath = '\\PSQL03\LogShipping',
  [string]$LocalPath = 'X:\Program Files\Microsoft SQL Server\MSSQL10_50.INSLOB01\MSSQL\LogShipping'
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

        RestoreThreshold = 45        
        RestoreAlertThreshold = 45

     } 
     
      Invoke-DbaDbLogShipping @params -Verbose
  }

 function Backup-ZDatabase-CopyOnly
{
  [cmdletbinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]

  param(
  [parameter(Mandatory=$true)] [string]$SourceSqlInstance,
  [parameter(Mandatory=$true)] [string]$DatabaseName,
  [parameter(Mandatory=$true)] [string]$BackupFilePath
  )

  Try { 
       $ErrorActionPreference = 'Stop'      
       #Import-Module Sqlps -DisableNameChecking 3>$null      
       Write-Host "Backup $DatabaseName To Path $BackupFilePath" 
       Invoke-Sqlcmd -ServerInstance $SourceSqlInstance -Database $DatabaseName `
        -Query "BACKUP DATABASE $DatabaseName TO DISK = N'$BackupFilePath' `
                  WITH  COPY_ONLY, NOFORMAT, INIT, NAME = N'$($DatabaseName)-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10;"  
       Write-Host "Done" 
    } Catch { 
        Throw 
    }
}

function Rebuild-ZDatabase-Indexes
{
  [cmdletbinding()]

  param(
  [parameter(Mandatory=$true)] [string]$SourceSqlInstance,
  [parameter(Mandatory=$true)] [string]$DatabaseName
  )

  Try { 
       $ErrorActionPreference = 'Stop'      
       Write-Host "Rebuilding all indexes for $DatabaseName." 
       Invoke-Sqlcmd -ServerInstance $SourceSqlInstance -Database $DatabaseName `
        -Query "Exec sp_msforeachtable 'SET QUOTED_IDENTIFIER ON; ALTER INDEX ALL ON ? REBUILD'"  
       Write-Host "Done" 
    } Catch { 
        Throw 
    }
}

function Move-ZDatabase
{
  [cmdletbinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]
  param(
  [parameter(Mandatory=$true)] [string]$Database,
  [string]$SourceSQLInstance = 'SWLGWSQLP06\INSLOB01',
  [string]$DestinationSqlInstance = 'PSQL03\INSLOB01',
  [string]$SharedPath = '\\psql03\backup'
  )

   # Test any migration consraints prior to actually migrating the database...
  Test-DbaMigrationConstraint -Source $SourceSQLInstance -Destination $DestinationSqlInstance  -Database $Database

  Copy-DbaDatabase -Source $SourceSQLInstance -Destination $DestinationSqlInstance -Database $Database `
       -BackupRestore -SharedPath $SharedPath -NumberFiles 1 -NoBackupCleanup -SetSourceOffline -Verbose

}

function Set-ZStorage-BlobContent
{
  [cmdletbinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]

  param(
  [string]$StorageAccountName = 'zsainfrap01std',
  [string]$StorageAccountKey = 'L+9MtmM3ehteOw/bpwLDPqjJXNO6ojeNNkVbib6+OwqzrSMNjMQdalDCaMx2mmdv9tA/j6oFf2AC8EVmv7yvuw==',
  [string]$ContainerToStoreFile = 'archive-databases',
  [string]$BLOBLocation = 'Z-Backups',
  [parameter(Mandatory=$true)] [string]$FileToStore,
  [parameter(Mandatory=$true)] [string]$FileLocation
  )

  $sc = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
  Set-AzureStorageBlobContent -File "$($FileLocation)$($FileToStore)" -Container $ContainerToStoreFile -Blob "$($BLOBLocation)/$($FileToStore)" -Context $sc -Force 

}

function Delete-ZStorage-Blob
{
  [cmdletbinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]

  param(
  [string]$StorageAccountName = 'zsainfrap01std',
  [string]$StorageAccountKey = 'L+9MtmM3ehteOw/bpwLDPqjJXNO6ojeNNkVbib6+OwqzrSMNjMQdalDCaMx2mmdv9tA/j6oFf2AC8EVmv7yvuw==',
  [string]$ContainerName = 'archive-databases',
  [parameter(Mandatory=$true,ValueFromPipelineByPropertyName)] [string]$Names
  )

  Begin { 
    $sc = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
  }

  Process {
    ForEach ($Name in $Names) {
      Remove-AzureStorageBlob -Blob $Name -Container $ContainerName -Context $sc
    }
  }

  End {
    Write-Host "Processed $Names deletions."
  }

}


function Get-ZStorage-ContainerContent
{
    param(
    [string]$StorageAccountName = 'zsainfrap01std',
    [string]$StorageAccountKey = 'L+9MtmM3ehteOw/bpwLDPqjJXNO6ojeNNkVbib6+OwqzrSMNjMQdalDCaMx2mmdv9tA/j6oFf2AC8EVmv7yvuw==',
    [string]$Container = 'archive-databases'
    )

    $sc = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    Get-AzureStorageBlob -Container $Container -Context $sc
}

function Archive-ZDatabase 
{
  [cmdletbinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]

  param(
  [parameter(Mandatory=$true)] [string]$DatabaseName,
  [string]$SourceSQLInstance = 'SWLGWSQLP06\INSLOB01',
  [string]$SQLBackupLocation ='L:\DatabaseBackups\',
  [string]$LocalBackupLocation = '\\swlgwsqlp06\databasebackups\',
  [string]$ArchiveSQLInstance = 'SAZRWSQLA01\INSARC01'
)

  $FileToArchive = "$DatabaseName" + "_$(Get-Date -Format 'dd.MMM.yyyy').bak"

  <#
  Write-Host "Bringing $DatabaseName online."
  Invoke-Sqlcmd -ServerInstance $SourceSQLInstance -Query "ALTER DATABASE [$DatabaseName] SET ONLINE;"
  Write-Host "Done"

  Backup-ZDatabase-CopyOnly -SourceSqlInstance $SourceSQLInstance -DatabaseName $DatabaseName -BackupFilePath "$($SQLBackupLocation)$($FileToArchive)"
  
  Write-Host "Taking $DatabaseName offline."
  Invoke-Sqlcmd -ServerInstance $SourceSQLInstance -Query "ALTER DATABASE [$DatabaseName] SET OFFLINE WITH ROLLBACK IMMEDIATE;"
  Write-Host "Done"

  Write-Host "Uploading backup file to Azure Blob storage"
  Set-ZStorage-BlobContent -FileToStore $FileToArchive -FileLocation $LocalBackupLocation 
  Write-Host "Done"
  #>

  Write-Host "Restoring backup file to Azure archive SQL instance"
  Restore-DbaDatabase -SqlInstance $ArchiveSQLInstance -Path "$($LocalBackupLocation)$($FileToArchive)"  `
      -DestinationDataDirectory 'U:\Program Files\Microsoft SQL Server\MSSQL13.INSARC01\MSSQL\Data' `
      -DestinationLogDirectory 'L:\Program Files\Microsoft SQL Server\MSSQL13.INSARC01\MSSQL\TLog' `
      -WithReplace 
  Write-Host "Done"  

}


function Test-Archive-ZDatabase
{
  Write-Host 'Inside private helper function, Test-Archive-ZDatabase.'
  Archive-ZDatabase -DatabaseName 'CardData'
}

