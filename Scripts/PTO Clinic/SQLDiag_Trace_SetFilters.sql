-- Set the Filters
DECLARE @intfilter int, @bigintfilter bigint, @TraceID int

-- get SQLDiag trace id
SELECT @TraceID = id FROM sys.traces WHERE [path] LIKE '%sp_trace.trc'

-- stop SQLDiag trace
EXEC sp_trace_setstatus @TraceID, 0

-- Set filters, below executions are set for DBID filter
/*
DBID = 3
NTUserName = 6
HostName = 8
LoginName = 11
*/
SET @intfilter = <filter_condition>
EXEC sp_trace_setfilter @TraceID, 3, 0, 0, @intfilter
SET @intfilter = <filter_condition>
EXEC sp_trace_setfilter @TraceID, 3, 1, 0, @intfilter
SET @intfilter = <filter_condition>
EXEC sp_trace_setfilter @TraceID, 3, 1, 0, @intfilter

-- restart SQLDiag trace
EXEC sp_trace_setstatus @TraceID, 1

-- display trace info
SELECT * FROM sys.traces WHERE id = @TraceID
SELECT * FROM fn_trace_getfilterinfo(@TraceID)