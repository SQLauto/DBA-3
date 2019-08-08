/*============================================================================
  File:     ExtendedEvents.sql

  Summary:  Setup event monitoring, using the resource governor events as
				examples.

  Date:     August 2008

  SQL Server Version: 10.0.2531.0 (SQL Server 2008 SP1)
------------------------------------------------------------------------------
  Written by Kimberly L. Tripp & Paul S. Randal, SQLskills.com

  For more scripts and sample code, check out http://www.SQLskills.com

  This script is intended as a supplement to the SQL Server 2008 Jumpstart or
  Metro training.
  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

-- Building on the resource governor demo, I'd like to know
-- how much IO each resource pool is doing

-- First, what events are there that I can use?
SELECT * FROM sys.dm_xe_objects
	WHERE [object_type] = 'event'
	ORDER BY [name];
GO

-- We're going to user sql_statement_completed. What are the
-- columns?
SELECT * FROM sys.dm_xe_object_columns
	WHERE [object_name] = 'sql_statement_completed'
GO

-- What database and resource governor actions are there?
SELECT * FROM sys.dm_xe_objects
	WHERE [object_type] = 'action'
	ORDER BY [name];
GO

-- What targets are there?
SELECT * FROM sys.dm_xe_objects
	WHERE [object_type] = 'target'
	ORDER BY [name];
GO

-- Let's use the ring buffer. What can I customize about it?
SELECT * FROM sys.dm_xe_object_columns
	WHERE [object_name] = 'ring_buffer'
GO

-- Drop the session if it exists. 
IF EXISTS (
	SELECT * FROM sys.server_event_sessions
		WHERE name = 'MonitorIO')
    DROP EVENT SESSION MonitorIO ON SERVER
GO

-- Create the event session
CREATE EVENT SESSION MonitorIO ON SERVER
ADD EVENT sqlserver.sql_statement_completed
	(ACTION
		(sqlserver.session_resource_pool_id)
    )
ADD TARGET package0.ring_buffer
WITH (max_dispatch_latency = 1 seconds);
GO

-- Start the session
ALTER EVENT SESSION MonitorIO ON SERVER
STATE = START;
GO

-- Go back to two of the windows and run:
--   sqlcmd /E /S.\SQLDEV01 /dMarketingDB /iRunQueriesWithWait.sql
-- and then immediately in the other window
--   sqlcmd /E /S.\SQLDEV01 /dDevelopmentDB /iRunQueriesWithWait.sql
-- Only let them run for 5 seconds or so


-- Look at some of the output
SELECT CAST(xest.target_data AS XML) StatementData
	FROM sys.dm_xe_session_targets xest
JOIN sys.dm_xe_sessions xes ON
	xes.address = xest.event_session_address
WHERE xest.target_name = 'ring_buffer'
	AND xes.name = 'MonitorIO';
GO

-- Now do some processing on it
-- Kill the query after a few seconds
SELECT
	Data2.Results.value ('(data/.)[6]', 'bigint') AS Reads,
	Data2.Results.value ('(data/.)[7]', 'bigint') AS Writes,
	Data2.Results.value ('(action/.)[1]', 'int') AS ResourcePoolID
FROM
(SELECT CAST(xest.target_data AS XML) StatementData
	FROM sys.dm_xe_session_targets xest
	JOIN sys.dm_xe_sessions xes ON
		xes.address = xest.event_session_address
	WHERE xest.target_name = 'ring_buffer'
		AND xes.name = 'MonitorIO') Statements
CROSS APPLY StatementData.nodes ('//RingBufferTarget/event') AS Data2 (Results);
GO

-- Select the IO sums by resource pool using a derived table
SELECT DT.ResourcePoolID,
	SUM (DT.Reads) as TotalReads,
	SUM (DT.Writes) AS TotalWrites
FROM
(SELECT 
	Data2.Results.value ('(data/.)[6]', 'bigint') AS Reads,
	Data2.Results.value ('(data/.)[7]', 'bigint') AS Writes,
	Data2.Results.value ('(action/.)[1]', 'int') AS ResourcePoolID
FROM
(SELECT CAST(xest.target_data AS XML) StatementData
	FROM sys.dm_xe_session_targets xest
	JOIN sys.dm_xe_sessions xes ON
		xes.address = xest.event_session_address
	WHERE xest.target_name = 'ring_buffer'
		AND xes.name = 'MonitorIO') Statements
CROSS APPLY StatementData.nodes ('//RingBufferTarget/event') AS Data2 (Results)) AS DT
GROUP BY DT.ResourcePoolID;
GO

ALTER EVENT SESSION MonitorIO ON SERVER
STATE = STOP;
GO


