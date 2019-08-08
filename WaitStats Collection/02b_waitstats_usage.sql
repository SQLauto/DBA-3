/* Usage scenario for stats gathering

-- Creates snapshot table if it doesn't exist
-- Clears both Wait Stats & (truncates) table and snapshots current waits
[dbo].[gather_wait_stats_2008] (@Clear INT = 0)

-- Adds a new waitstats snapshot to snapshot table based on current time
[dbo].[gather_wait_stats_2008]

-- Report on wait stats between first and last date ranges
[dbo].[report_wait_stats_2008]
 @First_Time = '2009-10-19 11:48:51.360',
 @Last_Time  = '2009-10-19 11:48:51.360'
*/

Declare @ClearTable int = 0;

exec [dbo].[gather_wait_stats_2008] @Clear = @ClearTable

-- Some time later

exec [dbo].[gather_wait_stats_2008]

-- Some time later

exec [dbo].[gather_wait_stats_2008]

-- When required...

exec [dbo].[report_wait_stats_2008]
 @First_Time = '2009-10-19 11:48:51.360',
 @Last_Time  = '2009-10-19 11:48:51.360'


 
