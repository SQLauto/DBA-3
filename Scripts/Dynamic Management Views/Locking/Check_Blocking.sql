set transaction isolation level read uncommitted

/*
select time, nt_username, cmd, sql, totalwaittime, maxwaittime, MaxWaitSQL
from DBA.dbo.head_blockers_v2
where time > '20/12/2006'
order by time
*/

select top 25 rtrim(nt_username), sysd.name as DB, 
	coalesce(syso_rdb.name, syso_dab.name, syso_lgt.name, /*syso_dist.name,*/ cast(objectid as varchar)) objectname,
	max(maxwaittime) as MaxBlockTime, max(NumBlocked) as MaxBlockedSPIDs, SQL, maxwaitsql
from DBA.dbo.head_blockers_v2 hb
	left join sys.sysdatabases sysd on hb.dbid = sysd.dbid
	left join retaildb.sys.sysobjects syso_rdb on hb.dbid = 5 and hb.objectid = syso_rdb.id
	left join ppdesignandbuy.sys.sysobjects syso_dab on hb.dbid = 7 and hb.objectid = syso_dab.id
	left join logistics.sys.sysobjects syso_lgt on hb.dbid = 6 and hb.objectid = syso_lgt.id
	--left join distribution.sys.sysobjects syso_dist on hb.dbid = 8 and hb.objectid = syso_dist.id
where time > '21/12/2006'
	and nt_username <> 'SQLEXECACCOUNT'
group by nt_username, sysd.name, coalesce(syso_rdb.name, syso_dab.name, syso_lgt.name, /*syso_dist.name,*/ cast(objectid as varchar)),
	SQL, maxwaitsql
order by max(maxwaittime) desc


-- Some reports
if object_id('tempdb..#temp') is not null drop table #temp

select spid, rtrim(nt_username) as nt_username, sysd.name as DB,
	max(maxwaittime) as MaxBlockTime, max(NumBlocked) as MaxBlockedSPIDs,
	coalesce(syso_rdb.name, syso_dab.name, syso_lgt.name, /*syso_dist.name,*/ cast(objectid as varchar)) objectname
into #temp
from DBA.dbo.head_blockers_v2 hb
	left join sys.sysdatabases sysd on hb.dbid = sysd.dbid
	left join retaildb.sys.sysobjects syso_rdb on hb.dbid = 5 and hb.objectid = syso_rdb.id
	left join ppdesignandbuy.sys.sysobjects syso_dab on hb.dbid = 7 and hb.objectid = syso_dab.id
	left join logistics.sys.sysobjects syso_lgt on hb.dbid = 6 and hb.objectid = syso_lgt.id
	--left join distribution.sys.sysobjects syso_dist on hb.dbid = 8 and hb.objectid = syso_dist.id
group by spid, rtrim(nt_username), sysd.name,
	coalesce(syso_rdb.name, syso_dab.name, syso_lgt.name, /*syso_dist.name,*/ cast(objectid as varchar))


select nt_username, DB, objectname, sum(MaxBlockTime) as TotalBlocking,
	sum(MaxBlockedSPIDs) as BlockedSpids, max(MaxBlockTime) as MaxBlockTime
from #temp temp
group by nt_username, DB, objectname
order by sum(MaxBlockTime) desc

-- Without the NT_USERNAME
select objectname, sum(MaxBlockTime) as TotalBlocking,
	sum(MaxBlockedSPIDs) as BlockedSpids, max(MaxBlockTime) as MaxBlockTime
from #temp temp
group by objectname
order by sum(MaxBlockTime) desc

-- Orderd by MaxBlockTime, not TotalBlocking
select objectname, sum(MaxBlockTime) as TotalBlocking,
	sum(MaxBlockedSPIDs) as BlockedSpids, max(MaxBlockTime) as MaxBlockTime
from #temp temp
group by objectname
order by max(MaxBlockTime) desc
