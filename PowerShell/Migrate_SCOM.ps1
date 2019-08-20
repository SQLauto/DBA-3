$SCOM_SOURCE = 'pscom01\scom'
$SCOM_TARGET = 'PCLU04\INSINF01'

$BackupFolder = "\\PCLU04\Backup"

Backup-DbaDatabase -SqlInstance $SCOM_SOURCE -Database OperationsManager -BackupDirectory $BackupFolder
Measure-DbaBackupThroughput -SqlInstance $SCOM_SOURCE

Test-DbaMigrationConstraint -Source $SCOM_SOURCE -Destination $SCOM_TARGET -Database 'OperationsManager'