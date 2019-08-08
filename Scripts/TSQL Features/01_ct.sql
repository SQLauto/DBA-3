CREATE DATABASE xyzzy
go


ALTER DATABASE xyzzy 
SET 
	CHANGE_TRACKING = ON
	(
		CHANGE_RETENTION = 2 DAYS, 
		AUTO_CLEANUP = ON
	)
go


USE xyzzy
go


CREATE TABLE track_this 
(
	i INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	abc VARCHAR(50)
)
go


ALTER TABLE track_this 
ENABLE CHANGE_TRACKING
go


INSERT track_this (abc)
VALUES ('track it?')
go


--Get all current data first
SELECT *
FROM track_this e
--Pass PK column(s) to CHANGETABLE
CROSS APPLY CHANGETABLE(VERSION track_this, (i), (e.i)) x
go


INSERT track_this (abc)
VALUES ('track it pt 2?')
go

UPDATE track_this
SET abc = 'track it pt 3?'
WHERE i = 1
GO


--Get next version(s)
--NET changes
DECLARE @last_sync_version bigint;
SET @last_sync_version = 1;

SELECT c.i,
    SYS_CHANGE_VERSION, SYS_CHANGE_OPERATION,
    SYS_CHANGE_COLUMNS, SYS_CHANGE_CONTEXT,
    t.*
FROM CHANGETABLE (CHANGES track_this, @last_sync_version) AS C
INNER JOIN track_this t ON t.i = c.i
go






ALTER DATABASE xyzzy
SET ALLOW_SNAPSHOT_ISOLATION ON
GO


SET TRANSACTION ISOLATION LEVEL SNAPSHOT

BEGIN TRANSACTION



--Check the min version against our version
SELECT CHANGE_TRACKING_MIN_VALID_VERSION(OBJECT_ID('track_this'))


DECLARE @last_sync_version bigint;
SET @last_sync_version = 1;

SELECT c.i,
    SYS_CHANGE_VERSION, SYS_CHANGE_OPERATION,
    SYS_CHANGE_COLUMNS, SYS_CHANGE_CONTEXT,
    t.*
FROM CHANGETABLE (CHANGES track_this, @last_sync_version) AS C
INNER JOIN track_this t ON t.i = c.i


--This is the version we should record
SELECT CHANGE_TRACKING_CURRENT_VERSION ()


COMMIT
go


--See the impact of the hidden column
create table x 
(
	id int not null primary key
)


--Insert 100k rows
insert x
select top 100000 
	ROW_NUMBER() over (order by a.number) 
from master..spt_values a, master..spt_values b


--Defrag, so we can see how much space is actually consumed
ALTER INDEX ALL ON x REBUILD
WITH (FILLFACTOR=100)
GO


--How much space is consumed?
exec sp_spaceused x


--Enable CT
alter table x enable change_tracking


--Force all of the rows to be re-written
update x 
set id=id


--Defrag again to get the final number
ALTER INDEX ALL ON x REBUILD
GO


--How much space is consumed?
exec sp_spaceused x
GO


--Clean up
USE master
go

DROP DATABASE xyzzy
go

