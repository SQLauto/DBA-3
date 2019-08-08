--
-- Script to Set up database for Snapshot Lab
--
USE Master
GO
DROP DATABASE SILabDB
GO
CREATE DATABASE SILabDB
GO
USE SILabDB
GO
CREATE TABLE SnapshotData (
  RowNumber INT NOT NULL IDENTITY (1,1) PRIMARY KEY CLUSTERED,
  RowData INT NOT NULL DEFAULT 0
  )
GO
-- Insert 3 rows
INSERT SnapshotData DEFAULT VALUES
INSERT SnapshotData DEFAULT VALUES
INSERT SnapshotData DEFAULT VALUES
GO
-- Create the Locks View, Used to read lock info
CREATE VIEW dbo.LockView
AS
SELECT sp.program_name as N'Connection',
       sp.spid as N'SPID',
       dtl.resource_type as N'Type',
       N'Resource' = CASE WHEN dtl.resource_type = N'OBJECT' THEN 
                            object_name(dtl.resource_associated_entity_id)
                          ELSE dtl.resource_description
                     END,
       dtl.request_mode as N'Mode',
       dtl.request_status as N'Status'
FROM sys.dm_tran_locks as dtl
INNER JOIN sys.sysprocesses as sp
ON (dtl.request_session_id = sp.spid)
WHERE resource_database_id = db_id()
AND sp.program_name in (N'Left Connection', N'Right Connection')
GO
-- test Stuff
/*
alter database snaptest SET ALLOW_SNAPSHOT_ISOLATION ON
begin transaction
update snapdata set rowdata = 1 where rownumber = 2
rollback transaction
select object_name(72057594038321152)
select * from sys.dm_tran_locks
*/