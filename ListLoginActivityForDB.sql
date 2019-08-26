USE [DBAMON]
GO

declare @DatabaseName varchar(255)
set @DatabaseName = 'ConrebatesProd'

SELECT [SPID]
      ,[Status]
      ,[LOGIN]
      ,[HostName]
      ,[BlkBy]
      ,[DBName]
      ,[Command]
      ,[CPUTime]
      ,[DiskIO]
      ,[LastBatch]
      ,[ProgramName]
      ,[SPID2]
      ,[RequestID]
      ,[InsertedDate]
  FROM [dbo].[tmp_sp_who2]
  where dbname = @DatabaseName
  order by InsertedDate desc

select distinct [login], count(inserteddate) AccessCount, max(inserteddate) LastAccess
  FROM [dbo].[tmp_sp_who2]
  where dbname = @DatabaseName
  group by login
  order by LastAccess desc



