-- Signature="C0374A0C399D327A"

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    SQL Census Data Collector Status.sql											                     ****/
--/****    show the status of a SQL Census Data Collector run on the instance		                         ****/
--/****                                                                                                      ****/
--/****    Created by wardp 2010.Feb.25 (adapted from 3.0 Status script)                                     ****/
--/****    Updated by wardp 2010.Oct.07 (bug 468950)                                                         ****/
--/****    Updated by rajpo 2010.Dec.06 (bug#471301) case sensitivity fix                                    ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright  Microsoft Corporation. All rights reserved.                                            ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/
SET NOCOUNT ON
USE tempdb
SET NUMERIC_ROUNDABORT OFF
GO

-- keep some house
DECLARE @version char(12),
        @version_string nchar(4),
        @CurrentlyProcessingDatabase sysname

SET     @version =  CONVERT(CHAR(12),SERVERPROPERTY('PRODUCTVERSION'));

SET @version_string =
    CASE LEFT(@version,2)       -- CR 375891
        WHEN '8.' THEN N'2000'  -- CR 375891
        WHEN '9.' THEN N'2005'  -- CR 375891
        WHEN '10' THEN N'2008'  -- CR 375891
        ELSE N'!!!!'
    END

-- generate the appropriate output based on the state of the instance

if OBJECTPROPERTY(object_id(N'dbo.SQLRAP_SQLCensus_TimeAndSpace'), N'IsUserTable') IS NULL
-- TimeAndSpaceEstimator hasn't been run since last restart.
    BEGIN
        SELECT N'No SQLRAP data is present on this instance.' + NCHAR(13) + NCHAR(10) +
               N'Please run TimeAndSpaceEstimator_' + @version_string + N', followed by CommentPreprocessor_' + @version_string + N'.'
    END
ELSE IF OBJECTPROPERTY(OBJECT_ID(N'dbo.SQLRAP_SQLCensus_StaticCodeAnalysis'), N'IsUserTable') IS NULL
-- CommentPreprocessorTables hasn't been run since last restart.
    BEGIN
        SELECT N'No SQLRAP CommentPrepreprocessor data is present on this instance.' + NCHAR(13) + NCHAR(10) +
               N'Please run CommentPreprocessor_' + @version_string + N'.'
    END
ELSE --if left(@version,2) = '10' -- CR 375891
BEGIN                       -- CR 375891

    DECLARE @CurrentAggregate DECIMAL (12,6),
			@CurrentDatabase  DECIMAL (12,6),
            @NewEstimate int,
            @RestartCount int,
            @NumberOfObjects bigint,
            @Counter bigint,
            @TotalObjects bigint,
            @TotalCounter bigint
            
    SELECT  @RestartCount = MAX(Counter) - 1
	FROM
	(
		SELECT	databaseid, COUNT(*) AS Counter
		FROM	tempdb.dbo.SQLRAP_SQLCensus_Timings (NOLOCK)
		GROUP BY databaseid
	) a

    SELECT  @CurrentAggregate =
            ISNULL ( 
            CASE 
                WHEN (SELECT CAST (SUM(EstimatedRunTimeInSeconds) AS DECIMAL (12,4)) FROM tempdb.dbo.SQLRAP_SQLCensus_Summary (NOLOCK) WHERE ActualRunTimeInSeconds IS NOT NULL) = 0
                    THEN 1.0
                ELSE
                    (SELECT SUM(ISNULL(ActualRunTimeInSeconds,0)) FROM tempdb.dbo.SQLRAP_SQLCensus_Summary s (NOLOCK)
                     WHERE NumberOfObjects = (SELECT COUNT(*) FROM tempdb.dbo.SQLRAP_SQLCensus_Objects o (NOLOCK) WHERE o.databaseid = s.databaseid)
                     ) / 
                    CASE (SELECT CAST (SUM(EstimatedRunTimeInSeconds) AS DECIMAL (12,4)) FROM tempdb.dbo.SQLRAP_SQLCensus_Summary s (NOLOCK)
                     WHERE ActualRunTimeInSeconds IS NOT NULL
                     AND	NumberOfObjects = (SELECT COUNT(*) FROM tempdb.dbo.SQLRAP_SQLCensus_Objects o (NOLOCK) WHERE o.databaseid = s.databaseid))
                     WHEN 0 THEN 0.00001
                     ELSE (SELECT CAST (SUM(EstimatedRunTimeInSeconds) AS DECIMAL (12,4)) FROM tempdb.dbo.SQLRAP_SQLCensus_Summary s (NOLOCK)
							 WHERE ActualRunTimeInSeconds IS NOT NULL
							 AND	NumberOfObjects = (SELECT COUNT(*) FROM tempdb.dbo.SQLRAP_SQLCensus_Objects o (NOLOCK) WHERE o.databaseid = s.databaseid))
                     END
                END
            ,0)
    OPTION (MAXDOP 1)

	SELECT  @TotalObjects = SUM(NumberOfObjects)
	FROM	tempdb.dbo.SQLRAP_SQLCensus_Summary (NOLOCK)
    OPTION (MAXDOP 1)

	SELECT	@TotalCounter = COUNT(*)
	FROM	SQLRAP_SQLCensus_Objects (NOLOCK)
    OPTION (MAXDOP 1)

	SELECT	@TotalCounter = @TotalCounter +
	ISNULL(COUNT(DISTINCT CAST(job_id AS nvarchar(40))+'|'+CAST(step_id AS nvarchar)),0) 
	FROM dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs (NOLOCK)

	SELECT  @NumberOfObjects = NumberOfObjects
	FROM	tempdb.dbo.SQLRAP_SQLCensus_Summary (NOLOCK)
	WHERE	databaseid = (SELECT databaseid FROM dbo.SQLRAP_SQLCensus_Timings (NOLOCK) WHERE StartDateTime = (SELECT MAX(StartDateTime) FROM dbo.SQLRAP_SQLCensus_Timings (NOLOCK)))
    OPTION (MAXDOP 1)

	SELECT	@Counter = COUNT(*)
	FROM	SQLRAP_SQLCensus_Objects (NOLOCK)
	WHERE	databaseid = (SELECT databaseid FROM dbo.SQLRAP_SQLCensus_Timings (NOLOCK) WHERE StartDateTime = (SELECT MAX(StartDateTime) FROM dbo.SQLRAP_SQLCensus_Timings (NOLOCK)))
    OPTION (MAXDOP 1)

    SELECT  @NewEstimate = CAST (ISNULL(SUM(EstimatedRunTimeInSeconds),0) AS INT)
    FROM    tempdb.dbo.SQLRAP_SQLCensus_Summary t (NOLOCK)
    WHERE   ActualRunTimeInSeconds IS NULL
    OPTION (MAXDOP 1)
    
    SELECT @CurrentDatabase = EstimatedRunTimeInSeconds
    FROM    tempdb.dbo.SQLRAP_SQLCensus_Summary t (NOLOCK)
	WHERE	databaseid = (SELECT databaseid FROM dbo.SQLRAP_SQLCensus_Timings (NOLOCK) WHERE StartDateTime = (SELECT MAX(StartDateTime) FROM dbo.SQLRAP_SQLCensus_Timings (NOLOCK)))
	OPTION	(MAXDOP 1)
    
	SELECT	@CurrentDatabase = @CurrentDatabase - ISNULL(SUM(DATEDIFF(ms,StartDateTime,EndDateTime)),0)/1000.0
	FROM	tempdb.dbo.SQLRAP_SQLCensus_Timings (NOLOCK)
	WHERE	databaseid = (SELECT databaseid FROM dbo.SQLRAP_SQLCensus_Timings (NOLOCK) WHERE StartDateTime = (SELECT MAX(StartDateTime) FROM dbo.SQLRAP_SQLCensus_Timings (NOLOCK)))
	OPTION	(MAXDOP 1)

    SELECT  @NewEstimate = @NewEstimate + ISNULL(SUM(ActualRunTimeInSeconds),0) -- @CurrentDatabase
    FROM    tempdb.dbo.SQLRAP_SQLCensus_Summary (NOLOCK)
    WHERE   ActualRunTimeInSeconds IS NOT NULL
    OPTION (MAXDOP 1)

	IF @NumberOfObjects <> @Counter
	BEGIN
		SET @NewEstimate = @NewEstimate + @CurrentDatabase
	END

	SELECT @CurrentlyProcessingDatabase = DB_NAME(databaseid)
	FROM tempdb.dbo.SQLRAP_SQLCensus_Timings (NOLOCK)
	WHERE StartDateTime =
	 (
		SELECT MAX(StartDateTime)
		FROM tempdb.dbo.SQLRAP_SQLCensus_Timings (NOLOCK)
	 )
	OPTION (MAXDOP 1)

--  report summary data
    SELECT	
			CAST(SERVERPROPERTY('MachineName') AS sysname) AS ServerName,
			ISNULL(SERVERPROPERTY('InstanceName'),SERVERPROPERTY('MachineName')) AS InstanceName,
    
		   CASE WHEN SUM(CAST (t.EstimateRun AS int))= 0
			THEN '(no estimate run)'
		   ELSE
			CAST(
			CAST(
				SUM(CodebaseSizeInMB) * 8.5 -- SQLRAP_SQLCensus_StaticCodeAnalysis records
				+ 12.9  -- Numbers table
				AS DECIMAL(12,2)
                )
             AS nvarchar(20)
             ) + ' Mb'
            END
            AS EstimatedTempDBSpace,
            
		   CASE WHEN SUM(CAST (t.EstimateRun AS int))= 0
			THEN '(no estimate run)'
		   ELSE
		    CASE
		        WHEN SUM(EstimatedRunTimeInSeconds) >= 3600.0
                    THEN CONVERT(nvarchar(20),CONVERT(bigint,SUM(ISNULL(EstimatedRunTimeInSeconds,0)))/3600) + N' hr '
                ELSE N''
             END
           + CONVERT(nvarchar(2),CONVERT(bigint,(SUM(ISNULL(EstimatedRunTimeInSeconds,0))))%3600/60) + N' min '
           + CONVERT(nvarchar(3),CAST(SUM(ISNULL(EstimatedRunTimeInSeconds,0)) AS bigint)%60) + N' sec'
           END AS EstimatedRunTime,

		   CASE WHEN SUM(CAST (t.EstimateRun AS int))= 0
			THEN '(no estimate run)'
		   ELSE
		    CASE
		        WHEN @NewEstimate >= 3600
                    THEN CONVERT(nvarchar(10),@NewEstimate/3600) + N' hr '
                ELSE N''
            END
           + CONVERT(nvarchar(2),CONVERT(bigint,(@NewEstimate))%3600/60) + N' min '
           + CONVERT(nvarchar(3),CONVERT(bigint,(@NewEstimate))%60) + N' sec' 
           END AS RevisedEstimatedRunTime,

		   CASE WHEN SUM(CAST (t.EstimateRun AS int))= 0
			THEN '(no estimate run)'
		   ELSE
		    CASE
		        WHEN CONVERT(bigint,(@NewEstimate-SUM(ISNULL(ActualRunTimeInSeconds,0)))) >= 3600
                    THEN CONVERT(nvarchar(10),CONVERT(bigint,(@NewEstimate-SUM(ISNULL(ActualRunTimeInSeconds,0)))/3600)) + N' hr '
                ELSE N''
            END
           + CONVERT(nvarchar(3),CONVERT(bigint,((@NewEstimate-SUM(ISNULL(ActualRunTimeInSeconds,0)))))%3600/60) + N' min '
           + CONVERT(nvarchar(3),(CAST(@NewEstimate-SUM(ISNULL(ActualRunTimeInSeconds,0)) AS bigint))%60) + N' sec'
           END AS EstimatedTimeRemaining,

            CASE
                WHEN CONVERT(bigint,SUM(ISNULL(ActualRunTimeInSeconds,0))) >= 3600
                    THEN CONVERT(nvarchar(10),CONVERT(bigint,SUM(ISNULL(ActualRunTimeInSeconds,0))/3600)) + N' hr '
                ELSE N''
            END
           + CONVERT(nvarchar(2),CONVERT(bigint,(CAST(SUM(ISNULL(ActualRunTimeInSeconds,0)) AS bigint)%3600)/60)) + N' min '
           + CONVERT(nvarchar(3),CONVERT(bigint,SUM(ISNULL(ActualRunTimeInSeconds,0)))%60) + N' sec' AS ActualRunTime,

		   CASE WHEN SUM(CAST (t.EstimateRun AS int))= 0
		    THEN '(no estimate run)'
			ELSE
            LEFT(CAST(CAST(@CurrentAggregate AS DECIMAL(12,4)) * 100 AS NVARCHAR(10)),LEN(CAST(CAST(@CurrentAggregate AS DECIMAL(12,4)) * 100 AS NVARCHAR(10)))-2) + '% ' +
			CASE 
				WHEN @TotalObjects = @TotalCounter THEN
					CASE
						WHEN (CAST(@CurrentAggregate AS DECIMAL(12,4)) * 100) < 100 THEN '(ran FASTER than estimate)'
						WHEN (CAST(@CurrentAggregate AS DECIMAL(12,4)) * 100) > 100 THEN '(ran SLOWER than estimate)'
						ELSE '(ran AS PREDICTED by estimate'
					END
				ELSE
					CASE
						WHEN (CAST(@CurrentAggregate AS DECIMAL(12,4)) * 100) < 100 THEN '(running FASTER than estimate)'
						WHEN (CAST(@CurrentAggregate AS DECIMAL(12,4)) * 100) > 100 THEN '(running SLOWER than estimate)'
						ELSE '(running AS PREDICTED by estimate'
					END
				END
            END AS PercentOfEstimatedTimeUsedForCompletedDatabases,

			CASE
				WHEN @TotalObjects = @TotalCounter	THEN N'--==Processing Completed==--' 
				ELSE @CurrentlyProcessingDatabase
			END	
            AS CurrentlyProcessingDatabase,

            CASE
				WHEN @RestartCount = 0 THEN 'Process uninterrupted'
				ELSE '--==' + CAST(@RestartCount AS nvarchar(4)) + ' process restart' +
				CASE WHEN @RestartCount >= 2 THEN 's' ELSE '' END + ' detected==--'
			END AS ProcessStability

    FROM tempdb.dbo.SQLRAP_SQLCensus_Summary t (NOLOCK)
    OPTION (MAXDOP 1)

-- report detail data from SQLRAP_SQLCensus_StaticCodeAnalysis
    SELECT t.databaseid,
           CASE LOWER(t.DatabaseName)
			WHEN N'msdb' THEN 'msdb (Scheduled Job Steps)'
			ELSE t.DatabaseName
           END AS DatabaseName,
           CASE
			WHEN t.EstimateRun = 0 THEN '(n/a)'
			WHEN t.EstimatedRunTimeInSeconds IS NULL THEN '0 min 0 sec'
			ELSE t.FriendlyEstimatedRunTime
		   END AS EstimatedRunTime,

           CASE
            WHEN t.ActualRunTimeInSeconds IS NULL AND sca.[Count] IS NULL THEN '--== pending ==--'
			WHEN t.NumberOfObjects = sca.[Count] THEN t.FriendlyActualRunTime
			WHEN t.NumberOfObjects = 0 AND t.databaseid < (SELECT MAX(databaseid) FROM tempdb.dbo.SQLRAP_SQLCensus_Timings (NOLOCK)) THEN t.FriendlyActualRunTime
			WHEN t.ActualRunTimeInSeconds IS NOT NULL AND sca.[Count] IS NULL THEN t.FriendlyActualRunTime
			ELSE 'elapsed: ' + t.FriendlyActualRunTime
           END AS ActualRunTime,

           CASE
            WHEN t.databaseid = DB_ID('msdb') THEN 
				(SELECT CAST(ISNULL(COUNT (DISTINCT (CAST(job_id AS nvarchar(40)) + N'|' + CAST(step_id AS nvarchar(40)))),0) AS nvarchar(10))
				 FROM tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs (NOLOCK))
			WHEN t.NumberOfObjects <= -1 THEN '--== pending ==--'
			ELSE CAST(t.NumberOfObjects AS nvarchar(10))
		   END AS ObjectsToMap,

           CASE
            WHEN t.databaseid = DB_ID('msdb') THEN 
				(SELECT CAST(ISNULL(COUNT (DISTINCT (CAST(job_id AS nvarchar(40)) + N'|' + CAST(step_id AS nvarchar(40)))),0) AS nvarchar(10))
				 FROM tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysisForJobs (NOLOCK))
            WHEN t.ActualRunTimeInSeconds IS NULL AND sca.[Count] >= 1 THEN CAST(sca.[Count] AS nvarchar(10))
            WHEN t.ActualRunTimeInSeconds IS NULL AND t.databaseid < (SELECT MAX(s.databaseid) FROM tempdb.dbo.SQLRAP_SQLCensus_StaticCodeAnalysis s (NOLOCK)) THEN '0'
            WHEN t.ActualRunTimeInSeconds IS NULL THEN '--== pending ==--'
            ELSE CAST(ISNULL(sca.[Count],0) AS nvarchar(10)) 
           END AS ObjectsMapped,

           CASE
            WHEN t.EstimateRun = 0 THEN '(n/a)'
            WHEN t.databaseid = DB_ID('msdb') THEN ISNULL(CAST(CAST(((100 * t.ActualRunTimeInSeconds)/CASE WHEN t.EstimatedRunTimeInSeconds = 0.0 THEN 1 ELSE CAST(t.EstimatedRunTimeInSeconds AS DECIMAL(12,4)) END) AS DECIMAL(12,3)) AS nvarchar(30)) + '%', '0.000%')
            WHEN sca.[Count] >= 1 AND sca.[Count] < t.NumberOfObjects THEN LEFT(CAST((sca.[Count] * 100/CAST (t.NumberOfObjects  AS DECIMAL (12,5))) AS nvarchar(100)),5) + '% complete'
			WHEN t.ActualRunTimeInSeconds IS NOT NULL AND sca.[Count] IS NULL THEN CAST(CAST(((100 * t.ActualRunTimeInSeconds)/CASE WHEN t.EstimatedRunTimeInSeconds = 0.0 THEN 1 ELSE CAST(t.EstimatedRunTimeInSeconds AS DECIMAL(12,4)) END) AS DECIMAL(12,3)) AS nvarchar(30)) + '%'
            WHEN t.ActualRunTimeInSeconds IS NULL THEN '--== pending ==--'
			WHEN t.EstimatedRunTimeInSeconds IS NULL THEN '--'
            ELSE CAST(CAST(((100 * t.ActualRunTimeInSeconds)/CASE WHEN t.EstimatedRunTimeInSeconds = 0.0 THEN 1 ELSE CAST(t.EstimatedRunTimeInSeconds AS DECIMAL(12,4)) END) AS DECIMAL(12,3)) AS nvarchar(30)) + '%'
           END AS PercentOfEstimatedRunTimeUsed,
           
           CASE
				WHEN t.NumberOfObjects <= -1 THEN '--== pending ==--'
				WHEN t.NumberOfObjects = 0 THEN '0 bytes'
				WHEN t.CodebaseSizeInMB * 1024 < 1 THEN CAST(t.CodebaseSize AS nvarchar(9)) + ' bytes'
				WHEN t.CodebaseSizeInMB > .965 THEN CAST(CAST(t.CodebaseSizeInMB AS DECIMAL(12,3)) AS nvarchar(20)) + ' Mb'
				ELSE CAST(CAST(t.CodebaseSizeInMB * 1024 AS DECIMAL(12,3)) AS nvarchar(20)) + ' Kb'
			END AS CodebaseSize,

           CASE
				WHEN t.NumberOfObjects <= -1 THEN '--== pending ==--'
				WHEN t.NumberOfObjects = 0 THEN '0 bytes'
				WHEN t.CodebaseSizeInMB * 1024 * 8.5 < 1 THEN CAST(CAST(t.CodebaseSize * 8.5 AS int) AS nvarchar(9)) + ' bytes'
				WHEN t.CodebaseSizeInMB * 8.5 > .965 THEN CAST(CAST(t.CodebaseSizeInMB * 8.5 AS DECIMAL(12,3)) AS nvarchar(20)) + ' Mb'
				ELSE CAST(CAST(t.CodebaseSizeInMB * 1024 * 8.5 AS DECIMAL(12,3)) AS nvarchar(20)) + ' Kb'
			END AS EstimatedCodeMapSize,
			
			CASE 
				WHEN t.NumberOfObjects <= -1 THEN '--== pending ==--'
				WHEN t.NumberOfObjects = 0 THEN '0 bytes'
				WHEN t.CodebaseSize/t.NumberOfObjects <= 999 THEN CAST(t.CodebaseSize/t.NumberOfObjects AS nvarchar(20)) + ' bytes'
				WHEN t.CodebaseSizeInMB/t.NumberOfObjects > .965 THEN CAST(CAST(t.CodebaseSizeInMB/t.NumberOfObjects AS DECIMAL(12,2)) AS nvarchar(30)) + ' Mb'
				ELSE CAST(CAST((t.CodebaseSize/1024.0)/t.NumberOfObjects AS DECIMAL(12,2)) AS nvarchar(30)) + ' Kb'
			END AS AverageSizeOfObject
			
    FROM   (SELECT databaseid,
				COUNT(DISTINCT CONVERT(nvarchar,ObjectId) + N'|' + CONVERT(nvarchar, Number)) AS [Count]
            FROM   tempdb.dbo.SQLRAP_SQLCensus_Objects (NOLOCK)
            GROUP BY databaseid
            ) sca
    FULL OUTER JOIN
           tempdb.dbo.SQLRAP_SQLCensus_Summary t (NOLOCK)
    ON     t.databaseid = sca.databaseid
	WHERE  t.databaseid IS NOT NULL
    ORDER BY t.databaseid
    OPTION (MAXDOP 1)
END