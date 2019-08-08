/*============================================================================
  File:     DynamicStringExecution v sp_executesql

  Summary:  Can you get optimal perf or not?
  
  Date:     October 2008

  SQL Server Version: 10.00.1600.22 (RTM)
------------------------------------------------------------------------------
  Written by Kimberly L. Tripp, SYSolutions, Inc.
  
  For more scripts and sample code, check out 
    http://www.SQLskills.com

  This script is intended only as a supplement to demos and lectures
  given by Kimberly L. Tripp.  
  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

SET STATISTICS IO ON
-- Turn Graphical Showplan ON (Ctrl+K)

DBCC FREEPROCCACHE       --Clears all plans from cache
DBCC DROPCLEANBUFFERS    --Clears all data from cache

select * from master.dbo.syscacheobjects
where cacheobjtype = 'Compiled Plan'

select * from sys.system_objects
where name like '[dm_]%'

use master
go

SELECT st.text, qs.EXECUTION_COUNT, qs.*, p.* 
FROM sys.dm_exec_query_stats AS qs 
	CROSS APPLY sys.dm_exec_sql_text(sql_handle) st
	CROSS APPLY sys.dm_exec_query_plan(plan_handle) p
ORDER BY 1, qs.EXECUTION_COUNT DESC;

USE pubs
go

SELECT * FROM dbo.titles WHERE price = 17.99
SELECT * FROM dbo.titles WHERE price = 199.99
SELECT * FROM dbo.titles WHERE price = $19.99

-- or to force caching (caching by specification) 
-- use sp_executesql
DECLARE @ExecStr    nvarchar(4000)
SELECT @ExecStr = 'SELECT * FROM dbo.titles WHERE price = @price'
EXEC sp_executesql @ExecStr,
                      N'@price money',
                      199.99
                      
-- Dynamic String Execution vs sp_executesql
DECLARE @price      money,
        @ExecStr    nvarchar(4000)
SET @price = 19.99
SELECT @ExecStr = 'SELECT * FROM dbo.titles WHERE price = ' 
					+ convert(varchar(10), @price)
SELECT @ExecStr
EXEC(@ExecStr)

use credit
go

sp_help member
select COUNT(*) from member where lastname = 'Tripp'
update member	set lastname = 'Tripp' where member_no = 1234
create index test on member (lastname)
set statistics io on

DECLARE @ExecStr    nvarchar(4000)
SELECT @ExecStr = 'SELECT * FROM dbo.member WHERE lastname like @lastname OPTION (RECOMPILE)'
EXEC sp_executesql @ExecStr,
                      N'@lastname varchar(15)',
                      '%e%'

DECLARE @intDBID INTEGER
SET @intDBID = (SELECT dbid FROM master.dbo.sysdatabases WHERE name = 'credit')          
dbcc flushprocindb(@intDBID)                      

dbcc freeproccache
SELECT * FROM dbo.member WHERE lastname like 'Anderson'
go

dbcc freeproccache
SELECT * FROM dbo.member WHERE lastname like 'Tripp'
go

dbcc freeproccache
SELECT * FROM dbo.member WHERE lastname like '%e%'
go

dbcc freeproccache
SELECT * FROM dbo.member WHERE lastname like '%tr%'
go