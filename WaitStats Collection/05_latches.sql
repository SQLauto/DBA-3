--
-- quick report on memory latches
-- configure @waittime parameter and wait for results
--

DECLARE @waittime VARCHAR(10)
SET @waittime = '00:00:01'

DECLARE @t TABLE (
id int identity
	, latch_class sysname
	, waiting_requests_count bigint
	, wait_time_ms bigint
	, max_wait_time_ms bigint
)

INSERT @t
( 	latch_class 
	, waiting_requests_count
	, wait_time_ms
	, max_wait_time_ms
)
SELECT 
	latch_class 
	, waiting_requests_count
	, wait_time_ms
	, max_wait_time_ms
FROM
sys.dm_os_latch_stats

WAITFOR DELAY @waittime

INSERT @t
( 	latch_class 
	, waiting_requests_count
	, wait_time_ms
	, max_wait_time_ms
)
SELECT 
	latch_class 
	, waiting_requests_count
	, wait_time_ms
	, max_wait_time_ms
FROM
sys.dm_os_latch_stats


SELECT v.*
, v.wait_time_ms * 1. / v.waiting_requests_count as wait_time_ms_per_request
FROM (
SELECT 
	T1.latch_class
	, (AVG(T2.waiting_requests_count - T1.waiting_requests_count)) waiting_requests_count
	, (AVG(T2.wait_time_ms - T1.wait_time_ms)) wait_time_ms
	, (AVG(T2.max_wait_time_ms - T1.max_wait_time_ms)) max_wait_time_ms
FROM @T t1
JOIN @T t2
ON T1.latch_class = T2.latch_class
AND t1.id < T2.id
GROUP BY 
	T1.latch_class
) v
where waiting_requests_count > 0
ORDER BY 3 DESC, 2 DESC
