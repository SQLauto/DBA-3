IF EXISTS (SELECT * FROM sys.objects WHERE [object_id] = OBJECT_ID(N'[dbo].[report_file_stats_2008]') and OBJECTPROPERTY([object_id], N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[report_file_stats_2008] ;
GO
CREATE PROCEDURE [dbo].[report_file_stats_2008] 
( @EndTime DATETIME = NULL
, @BeginTime DATETIME = NULL )
 --  Date & time of the last sample to use

AS

SET NOCOUNT ON ;

IF OBJECT_ID( N'[dbo].[file_stats]',N'U') IS NULL
BEGIN
		RAISERROR('Error [dbo].[file_stats] table does not exist', 16, 1) WITH NOWAIT ;
		RETURN ;
END

DECLARE @file_stats TABLE (
	    [database_id] [smallint] NOT NULL,
	    [file_id] [smallint] NOT NULL,
	    [num_of_reads] [bigint] NOT NULL,
	    [num_of_bytes_read] [bigint] NOT NULL,
	    [io_stall_read_ms] [bigint] NOT NULL,
	    [num_of_writes] [bigint] NOT NULL,
	    [num_of_bytes_written] [bigint] NOT NULL,
	    [io_stall_write_ms] [bigint] NOT NULL,
	    [io_stall] [bigint] NOT NULL,
	    [size_on_disk_bytes] [bigint] NOT NULL,
        [capture_time] [datetime] NOT NULL
        )  ;

--  If no time was specified then use the latest sample minus the first sample
IF @BeginTime IS NULL
    SET @BeginTime = (SELECT MIN([capture_time]) FROM [dbo].[file_stats]) ;
ELSE
BEGIN
    --  If the time was not specified exactly find the closest one
    IF NOT EXISTS(SELECT * FROM [dbo].[file_stats] WHERE [capture_time] = @BeginTime)
    BEGIN
        DECLARE @BT DATETIME ;
        SET @BT = @BeginTime ;

        SET @BeginTime = (SELECT MIN([capture_time]) FROM [dbo].[file_stats] WHERE [capture_time] >= @BT) ;
        IF @BeginTime IS NULL
            SET @BeginTime = (SELECT MAX([capture_time]) FROM [dbo].[file_stats] WHERE [capture_time] <= @BT) ;
    END
END

IF @EndTime IS NULL
    SET @EndTime = (SELECT MAX([capture_time]) FROM [dbo].[file_stats]) ;
ELSE
BEGIN
    --  If the time was not specified exactly find the closest one
    IF NOT EXISTS(SELECT * FROM [dbo].[file_stats] WHERE [capture_time] = @EndTime)
    BEGIN
        DECLARE @ET DATETIME ;
        SET @ET = @EndTime ;

        SET @EndTime = (SELECT MIN([capture_time]) FROM [dbo].[file_stats] WHERE [capture_time] >= @ET) ;
        IF @EndTime IS NULL
            SET @EndTime = (SELECT MAX([capture_time]) FROM [dbo].[file_stats] WHERE [capture_time] <= @ET) ;
    END
END


INSERT INTO @file_stats
      ([database_id],[file_id],[num_of_reads],[num_of_bytes_read],[io_stall_read_ms]
      ,[num_of_writes],[num_of_bytes_written],[io_stall_write_ms]
      ,[io_stall],[size_on_disk_bytes],[capture_time])
SELECT [database_id],[file_id],[num_of_reads],[num_of_bytes_read],[io_stall_read_ms]
      ,[num_of_writes],[num_of_bytes_written],[io_stall_write_ms]
      ,[io_stall],[size_on_disk_bytes],[capture_time]
FROM [dbo].[file_stats] 
    WHERE [capture_time] = @EndTime ;

IF @@ROWCOUNT = 0
BEGIN
    RAISERROR('Error, there are no waits for the specified DateTime', 16, 1) WITH NOWAIT ;
    RETURN ;
END

--  Subtract the starting numbers from the end ones to find the difference for that time period
UPDATE fs
        SET fs.[num_of_reads] = (fs.[num_of_reads] - a.[num_of_reads])
       , fs.[num_of_bytes_read] = (fs.[num_of_bytes_read] - a.[num_of_bytes_read])
       , fs.[io_stall_read_ms] = (fs.[io_stall_read_ms] - a.[io_stall_read_ms])
       , fs.[num_of_writes] = (fs.[num_of_writes] - a.[num_of_writes])
       , fs.[num_of_bytes_written] = (fs.[num_of_bytes_written] - a.[num_of_bytes_written])
       , fs.[io_stall_write_ms] = (fs.[io_stall_write_ms] - a.[io_stall_write_ms])
       , fs.[io_stall] = (fs.[io_stall] - a.[io_stall])
FROM @file_stats AS fs INNER JOIN (SELECT b.[database_id],b.[file_id],b.[num_of_reads],b.[num_of_bytes_read],b.[io_stall_read_ms]
                                        ,b.[num_of_writes],b.[num_of_bytes_written],b.[io_stall_write_ms],b.[io_stall]
                                    FROM [dbo].[file_stats] AS b
                                        WHERE b.[capture_time] = @BeginTime) AS a
                    ON (fs.[database_id] = a.[database_id] AND fs.[file_id] = a.[file_id]) ;



SELECT CONVERT(varchar(50),@BeginTime,120) AS [Start Time], CONVERT(varchar(50),@EndTime,120) AS [End Time]
    ,CONVERT(varchar(50),@EndTime - @BeginTime,108) AS [Duration (hh:mm:ss)] ;



SELECT fs.[database_id] AS [Database ID], fs.[file_id] AS [File ID], fs.[num_of_reads] AS [NumberReads],
     CONVERT(VARCHAR(20),CAST((fs.[num_of_bytes_read] / 1048576.0) AS MONEY),1) AS [MBs Read]
    ,fs.[io_stall_read_ms] AS [IoStallReadMS]
    ,fs.[num_of_writes] AS [NumberWrites]
    ,CONVERT(VARCHAR(20),CAST((fs.[num_of_bytes_written] / 1048576.0) AS MONEY),1) AS [MBs Written]
    ,fs.[io_stall_write_ms] AS [IoStallWriteMS]
    ,fs.[io_stall] AS [IoStallMS]
    ,CONVERT(VARCHAR(20),CAST((fs.[size_on_disk_bytes] / 1048576.0) AS MONEY),1) AS [MBsOnDisk]
    ,(SELECT c.[name] FROM [master].[sys].[databases] AS c WHERE c.[database_id] = fs.[database_id]) AS [DB Name]
    ,(SELECT RIGHT(d.[physical_name],CHARINDEX('\',REVERSE(d.[physical_name]))-1) 
            FROM [master].[sys].[master_files] AS d 
                WHERE d.[file_id] = fs.[file_id] AND d.[database_id] = fs.[database_id]) AS [File Name]
    ,fs.[capture_time] AS [Last Sample]
FROM @file_stats AS fs
    ORDER BY fs.[database_id], fs.[file_id] ;


GO
