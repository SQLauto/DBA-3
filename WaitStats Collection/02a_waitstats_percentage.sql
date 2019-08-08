use master
go

IF EXISTS (SELECT * FROM SYS.PROCEDURES WHERE name = 'sproc_get_waitstats_percentage')
  DROP PROC dbo.sproc_get_waitstats_percentage
GO

CREATE PROC dbo.sproc_get_waitstats_percentage
	@hours tinyint = null,
	@minutes  tinyint = null,
	@seconds  tinyint = null
AS

SET NOCOUNT ON

IF @hours IS NULL
	SET @hours = 0
IF @minutes IS NULL
	SET @minutes = 0
IF @seconds IS NULL
	SET @seconds = 0

--
-- initial validations
--
IF @hours < 0 OR @hours > 24
BEGIN
   RAISERROR ('Hours range is not valid.', 16, 1 )
   RETURN
END

IF @minutes < 0 OR @minutes > 60
BEGIN
   RAISERROR ('Minutes range is not valid.', 16, 1 )
   RETURN
END

IF @seconds < 0 OR @seconds > 60
BEGIN
   RAISERROR ('Seconds range is not valid.', 16, 1 )
   RETURN
END

IF @hours = 0 and @minutes = 0 and @seconds = 0
BEGIN
   RAISERROR ('The measure time must be greater than zero.', 16, 1 )
   RETURN
END

-- 
-- table variable definition
--
DECLARE @t TABLE (
id int identity
, wait_type nvarchar(60)
, waiting_tasks_count bigint
, wait_time_ms bigint
, signal_wait_time_ms bigint)

-- 
-- first capture
--
INSERT @t
(	wait_type
	, waiting_tasks_count
	, wait_time_ms
	, signal_wait_time_ms )
SELECT 
	wait_type
	, waiting_tasks_count
	, wait_time_ms
	, signal_wait_time_ms
FROM
	sys.dm_os_wait_stats
WHERE 
	wait_type not in
	('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK'
	,'SLEEP_SYSTEMTASK','SQLTRACE_BUFFER_FLUSH','WAITFOR'
    ,'REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TO_FLUSH','BROKER_TASK_STOP')
	and wait_type not like 'PREEMPTIVE%'


--
-- wait for n time
--
DECLARE @s CHAR(8)
SET @s = 
      RIGHT ('00' + CAST (@hours as VARCHAR(2)), 2) + ':'
	+ RIGHT ('00' + CAST (@minutes as VARCHAR(2)), 2) + ':'
	+ RIGHT ('00' + CAST (@seconds as VARCHAR(2)), 2)

WAITFOR DELAY @s

-- 
-- second capture
--
INSERT @t
(	wait_type
	, waiting_tasks_count
	, wait_time_ms
	, signal_wait_time_ms )
SELECT 
	wait_type
	, waiting_tasks_count
	, wait_time_ms
	, signal_wait_time_ms
FROM
	sys.dm_os_wait_stats
WHERE 
	wait_type not in
	('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK'
	,'SLEEP_SYSTEMTASK','SQLTRACE_BUFFER_FLUSH','WAITFOR'
    ,'REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TO_FLUSH','BROKER_TASK_STOP')
	and wait_type not like 'PREEMPTIVE%'

--
-- deltas calculation
--
;WITH details AS ( 
SELECT * FROM (
SELECT 
	T1.wait_type
	, AVG(T2.waiting_tasks_count - T1.waiting_tasks_count) waiting_tasks_count
	, AVG(T2.wait_time_ms - T1.wait_time_ms) wait_time_ms
	, AVG(T2.signal_wait_time_ms - T1.signal_wait_time_ms) signal_wait_time_ms
FROM @T t1
JOIN @T t2
  ON T1.wait_type = T2.wait_type
 AND T1.id < T2.id
GROUP BY T1.wait_type
) v
WHERE 
	wait_time_ms <> 0
),
 sums AS (
SELECT 
	SUM(waiting_tasks_count) waiting_tasks_count
	, SUM(wait_time_ms) wait_time_ms
	, SUM(signal_wait_time_ms) signal_wait_time_ms
FROM details
)
SELECT 
	details.*
	, details.wait_time_ms * 1.00 / details.waiting_tasks_count as wait_per_request
	, CASE WHEN sums.waiting_tasks_count = 0 THEN 0 ELSE details.waiting_tasks_count * 1.00 / sums.waiting_tasks_count END as porcen_waiting_tasks_count
	, CASE WHEN sums.wait_time_ms = 0 THEN 0 ELSE details.wait_time_ms * 1.00 /  sums.wait_time_ms END as porcen_wait_time_ms
	, CASE WHEN sums.signal_wait_time_ms = 0 THEN 0 ELSE details.signal_wait_time_ms * 1.00 /  sums.signal_wait_time_ms END as porcen_signal_wait_time_ms
FROM details
, sums
 where CASE WHEN sums.waiting_tasks_count = 0 THEN 0 ELSE details.waiting_tasks_count * 1.00 / sums.waiting_tasks_count END > 0.01
GO
