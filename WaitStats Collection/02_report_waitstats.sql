IF EXISTS (SELECT * FROM sys.objects WHERE [object_id] = OBJECT_ID(N'[dbo].[report_wait_stats_2008]') and OBJECTPROPERTY([object_id], N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[report_wait_stats_2008] ;
GO
CREATE PROCEDURE [dbo].[report_wait_stats_2008] 
(@First_Time DATETIME = NULL
,@Last_Time DATETIME = NULL
,@UseOLEDB INT = 0) 
/*
 --  Date & time of the last sample to use
 --  0 = Dont include OLEDB waits, 1 = Include OLEDB waits
*/
AS

SET NOCOUNT ON ;

IF OBJECT_ID( N'[dbo].[wait_stats]',N'U') IS NULL
BEGIN
		RAISERROR('Error [dbo].[wait_stats] table does not exist', 16, 1) WITH NOWAIT ;
		RETURN ;
END

DECLARE @Total_Wait numeric(20,1), @Total_SignalWait numeric(20,1), @Total_ResourceWait numeric(20,1)
	,@EndTime datetime, @Total_Requests Bigint ;

DECLARE @Waits TABLE ([wait_type] nvarchar(60) not null, 
    [waiting_tasks_count] bigint not null,
    [wait_time_ms] bigint not null,
    [max_wait_time_ms] bigint not null,
    [signal_wait_time_ms] bigint not null,
    [capture_time] datetime not null) ;

--  If no First time was specified then use the First sample
IF @First_Time IS NULL
    SET @First_Time = (SELECT MIN([capture_time]) FROM [dbo].[wait_stats]) ;
ELSE
BEGIN
    --  If the time was not specified exactly find the closest one
    IF NOT EXISTS(SELECT * FROM [dbo].[wait_stats] WHERE [capture_time] = @First_Time) 
    BEGIN
        DECLARE @FT DATETIME ;
        SET @FT = @First_Time ;

        SET @First_Time = (SELECT MIN([capture_time]) FROM [dbo].[wait_stats] WHERE [capture_time] <= @FT) ;
        IF @First_Time IS NULL
            SET @First_Time = (SELECT MIN([capture_time]) FROM [dbo].[wait_stats] WHERE [capture_time] >= @FT) ;
    END
END

--  If no Last time was specified then use the latest sample
IF @Last_Time IS NULL
    SET @Last_Time = (SELECT MAX([capture_time]) FROM [dbo].[wait_stats]) ;
ELSE
BEGIN
    --  If the time was not specified exactly find the closest one
    IF NOT EXISTS(SELECT * FROM [dbo].[wait_stats] WHERE [capture_time] = @Last_Time)
    BEGIN
        DECLARE @LT DATETIME ;
        SET @LT = @Last_Time ;

        SET @Last_Time = (SELECT MAX([capture_time]) FROM [dbo].[wait_stats] WHERE [capture_time] <= @LT) ;
        IF @Last_Time IS NULL
            SET @Last_Time = (SELECT MIN([capture_time]) FROM [dbo].[wait_stats] WHERE [capture_time] >= @LT) ;
    END
END


--  Get the relevant waits
INSERT INTO @Waits ([wait_type], [waiting_tasks_count], [wait_time_ms], [max_wait_time_ms], [signal_wait_time_ms], [capture_time])
    SELECT [wait_type], [waiting_tasks_count], [wait_time_ms], [max_wait_time_ms], [signal_wait_time_ms], [capture_time]
        FROM [dbo].[wait_stats] WHERE [capture_time] = @Last_Time ;

IF @@ROWCOUNT = 0
BEGIN
    RAISERROR('Error, there are no waits for the specified DateTime', 16, 1) WITH NOWAIT ;
    RETURN ;
END
    

--  Delete some of the misc types of waits and OLEDB if called for
IF @UseOLEDB = 0
    DELETE FROM @Waits 
        WHERE [wait_type] IN ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK'
	,'SLEEP_SYSTEMTASK','SQLTRACE_BUFFER_FLUSH','WAITFOR','LOGMGR_QUEUE'
    ,'REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TO_FLUSH','BROKER_TASK_STOP') ;
ELSE
    DELETE FROM @Waits 
        WHERE [wait_type] IN ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK'
	,'SLEEP_SYSTEMTASK','SQLTRACE_BUFFER_FLUSH','WAITFOR','LOGMGR_QUEUE'
    ,'REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TO_FLUSH','BROKER_TASK_STOP') ;

-- Get the delta
UPDATE a SET a.[waiting_tasks_count] = (a.[waiting_tasks_count] - b.[waiting_tasks_count])
                ,a.[wait_time_ms] = (a.[wait_time_ms] - b.[wait_time_ms])
                ,a.[signal_wait_time_ms] = (a.[signal_wait_time_ms] - b.[signal_wait_time_ms])
FROM @Waits AS a INNER JOIN [dbo].[wait_stats] AS b ON a.[wait_type] = b.[wait_type]
            AND b.[capture_time] = @First_Time ;


--  Get the totals
SELECT @Total_Wait = SUM([wait_time_ms]) + 1, @Total_SignalWait = SUM([signal_wait_time_ms]) + 1 
    FROM @Waits ;

SET @Total_ResourceWait = (1 + @Total_Wait) - @Total_SignalWait ;

SET @Total_Requests = (SELECT SUM([waiting_tasks_count]) FROM @Waits) ;

INSERT INTO @Waits ([wait_type], [waiting_tasks_count], [wait_time_ms], [max_wait_time_ms], [signal_wait_time_ms], [capture_time])
    SELECT '***Total***',@Total_Requests,@Total_Wait,0,@Total_SignalWait,@Last_Time ;


--  Display the results
SELECT @First_Time AS [Start Time], @Last_Time AS [End Time]
    ,CONVERT(varchar(50),@Last_Time - @First_Time,14) AS [Duration (hh:mm:ss:ms)] ;

select [wait_type] AS [Wait Type]
    ,[waiting_tasks_count] AS [Requests]
	,[wait_time_ms] AS [Total Wait Time (ms)]
    ,[max_wait_time_ms] AS [Max Wait Time (ms)]
	,CAST(100 * [wait_time_ms] / @Total_Wait as numeric(20,1)) AS [% Waits]
	,[wait_time_ms] - [signal_wait_time_ms] AS [Resource Waits (ms)]
	,CAST(100 * ([wait_time_ms] - [signal_wait_time_ms]) / @Total_ResourceWait as numeric(20,1)) AS [% Res Waits]
	,[signal_wait_time_ms] AS [Signal Waits (ms)]
	,CAST(100*[signal_wait_time_ms] / @Total_SignalWait as numeric(20,1)) AS [% Signal Waits]
FROM @Waits 
    ORDER BY [Total Wait Time (ms)] DESC, [Wait Type] ;


GO


