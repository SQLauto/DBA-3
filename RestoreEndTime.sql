/*
  
Query - Restore Duration Time for Database 
  
Uses MSDB..RestoreHistory table for Start time and ErrorLog for Finish Time
  
*/
  
-- Name of the Database you want restore name of:
DECLARE @databaseName VARCHAR(50)
SET @databaseName = 'PC'
 
 
 
DECLARE @TSQL NVARCHAR(2000)
DECLARE @lC INT
DECLARE @ErrorLogStart DATETIME
DECLARE @CurrentLogStart DATETIME
SET @CurrentLogStart = GETDATE()
  
-- Error Message for ErrorLog search
DECLARE @errorLogResult VARCHAR(4000)
SET @errorLogResult = 'Restore is complete on database ''' + @databaseName
    + '''.  The database is now available.'
  
-- Results Table 
CREATE TABLE #Restore
    (
      [database] VARCHAR(50) ,
      StartTime DATETIME ,
      EndTime DATETIME
    )
  
INSERT  INTO #Restore
        ( [database] )
VALUES  ( @databaseName )
  
-- Get start time by looking msdb..restorehistory and selecting the first record with your db
UPDATE  #Restore
SET     StartTime = ( SELECT TOP ( 1 )
                                restore_date
                      FROM      msdb.dbo.restorehistory
                      WHERE     destination_database_name = @databaseName
                    )
WHERE   [database] IS NOT NULL
  
-- Get end time by loading the errorlog into a temp table and filtering to find the restore command @errorLog Result 
 
 
-- SET ErrorLogStart Date to Restore Start Time
SET @ErrorLogStart = ( SELECT   StartTime
                       FROM     #Restore
                       WHERE    [database] = @databaseName
                     )
 
CREATE TABLE #TempLog
    (
      LogDate DATETIME ,
      ProcessInfo NVARCHAR(50) ,
      [Text] NVARCHAR(MAX)
    )
 
CREATE TABLE #logF
    (
      ArchiveNumber INT ,
      LogDate DATETIME ,
      LogSize INT
    )
 
INSERT  INTO #logF
        EXEC sp_enumerrorlogs
SELECT  @lC = MIN(ArchiveNumber)
FROM    #logF
 
WHILE @lC IS NOT NULL
    BEGIN
        IF EXISTS ( SELECT  1
                    FROM    #TempLog )
            BEGIN
                SET @CurrentLogStart = ( SELECT TOP ( 1 )
                                                LogDate
                                         FROM   #TempLog
                                         ORDER BY LogDate
                                       )
            END
        IF ( @CurrentLogStart > @ErrorLogStart )
            BEGIN
                INSERT  INTO #TempLog
                        EXEC sp_readerrorlog @lC
                SELECT  @lC = MIN(ArchiveNumber)
                FROM    #logF
                WHERE   ArchiveNumber > @lC
            END
        ELSE
            BEGIN
                BREAK
            END
    END
 
 
      
UPDATE  #Restore
SET     EndTime = ( SELECT TOP ( 1 )
                            LogDate
                    FROM    #TempLog
                    WHERE   ProcessInfo = 'Backup'
                            AND [Text] LIKE @errorLogResult
                  )
WHERE   [database] IS NOT NULL
  
  
  
-- Return the Restore information
SELECT  [database] ,
        StartTime ,
        EndTime ,
        DATEDIFF(MINUTE, StartTime, EndTime) AS 'Restore Duration in Minutes' ,
        DATEDIFF(SECOND, StartTime, EndTime) AS 'Restore Duration in Seconds'
FROM    #Restore
  
-- Clean up
DROP TABLE #Restore
DROP TABLE #TempLog
DROP TABLE #logF