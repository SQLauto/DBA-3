-- Job names in PROD. Be careful: Only use during actual deployment
-- Full backup
-- SSL_Backup_FULL_AB
-- SSL_Backup_FULL_BC
-- SSL_Backup_FULL_PC

-- Diff Backup
-- SSL_Backup_Diff_AB
-- SSL_Backup_Diff_BC
-- SSL_Backup_Diff_PC

-- Log Backup
-- SSL_Backup_LOG_AB
-- SSL_Backup_LOG_BC
-- SSL_Backup_LOG_PC

-- Job names in E2E2
-- Backup_BC_ReleaseTest
-- Backup_PC_ReleaseTest
-- Backup_AB_ReleaseTest

USE msdb ;
GO

EXEC dbo.sp_start_job N'SSL_Backup_LOG_AB' ;   --<Name will need to be changed for PROD>
GO
EXEC dbo.sp_start_job N'SSL_Backup_LOG_BC' ;   --<Name will need to be changed for PROD>
GO
EXEC dbo.sp_start_job N'SSL_Backup_LOG_PC' ;   --<Name will need to be changed for PROD>
GO
