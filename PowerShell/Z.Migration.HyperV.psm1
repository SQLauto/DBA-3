set-strictmode -version 2
function Migrate-Database
{
  [cmdletbinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]

  param(
  [parameter(Mandatory=$true)] [string]$SourceSQLInstance,
  [parameter(Mandatory=$true)] [string]$TargetSQLInstance,
  [parameter(Mandatory=$true)] [string]$Database,
  [parameter(Mandatory=$true)] [string]$SharedPath
  )

    write-host "in migrate-ZDatabase"

    #Test-DbaMigrationConstraint -Source $SourceSQLInstance -Destination $TargetSQLInstance -Database $Database

    Copy-DbaDatabase -Source $SourceSQLInstance -Destination $TargetSQLInstance -Database $Database -BackupRestore -SharedPath $SharedPath -NumberFiles 1 -NoBackupCleanup
  
}

