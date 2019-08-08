--Signature="80AC308955E209A8" 
 
--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    This test case lists the database files that are                                                  ****/
--/****    configured to auto grow in %growth and the                                                        ****/
--/****    next growth >1024 MB.                                                                             ****/
--/****     March 26th 2009:  rajpo Fixed several bugs, Growth shows 0, if growth <1MB                       ****/
--/****     Fixed SQL2K protion, Database name same as logical file name, took care of huge next growth      ****/
--/****     April 7th 2009:  wardp  added signature (bug 339890); addressed bug 339922                       ****/
--/****     April 28th 2009: rajpo  fixed the SQL2K portion to address database names that may have special  ****/
--/****      characters like - etc...                                                                        ****/
--/****      May 5th 2009: rajpo fixed bug#348446							                                 ****/
--/****		Fixed SQL2005 case sensitivity issue  							                                 ****/
--/****		06/24 Fixed error with offline databases in SQL2K                                                ****/                                                       ****/
--/****     July 17, 2009:  wardp  add SQL2K8 support (CR 375891)                                            ****/
--/****     Oct 01, 2010: rajpo fixed the case for ReadonlyBIT  (Bug# 468882)                                ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright (C) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

SET NOCOUNT ON; 

declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));
declare @databasename sysname
---Do the version check and create appropriate temp tables first.
if  '10' = (select substring(@version, 1, 2))  -- CR 375891
begin
	select distinct serverproperty('machinename')                               as 'Server Name',                                           
    isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
	t.[database_name] as 'Database Name',t.[Logical_Name] as 'Logical Name', t.NextGrowthSize as 'Next Growth MB',
	t.[is_read_only] as 'Read Only' from
	(

	SELECT
	db_name([files].[database_id]) as [database_name],
	[files].[name] as [Logical_Name],NextGrowthSize=
	case [is_percent_growth]
		when 1 then convert(numeric(18,2),(((convert(Numeric,size)*growth)/100)*8)/1024)
		when 0 then convert(numeric(18,2),(convert(numeric,[growth])*8)/1024)
	end ,
	is_read_only=
	case [is_read_only]
		when 1 then 'Yes'
		when 0 then 'No'
	end
	FROM
	sys.master_files [files]
	WHERE 
	[files].[type] in(0,1) AND                    -- data and log files check
	[files].growth != 0 AND	                  -- autogrow enabled check
  
	  lower(db_name(database_id))  NOT IN (N'master', N'tempdb', N'model', N'msdb', N'pubs', N'northwind', N'adventureworks', N'adventureworksdw')
    ) t  
	where t.NextGrowthSize >=1024
	order by [Server Name],[Instance Name],[Database Name],[Next Growth MB],[Read Only]
end -- CR 375891
else if  9 = (select substring(@version, 1, 1))
begin
	select distinct serverproperty('machinename')                               as 'Server Name',                                           
    isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
	t.[database_name] as 'Database Name',t.[Logical_Name] as 'Logical Name', t.NextGrowthSize as 'Next Growth MB',
	t.[is_read_only] as 'Read Only' from
	(

	SELECT
	db_name([files].[database_id]) as [database_name],
	[files].[name] as [Logical_Name],NextGrowthSize=
	case [is_percent_growth]
		when 1 then convert(numeric(18,2),(((convert(Numeric,size)*growth)/100)*8)/1024)
		when 0 then convert(numeric(18,2),(convert(numeric,[growth])*8)/1024)
	end ,
	is_read_only=
	case [is_read_only]
		when 1 then 'Yes'
		when 0 then 'No'
	end
	FROM
	sys.master_files [files]
	WHERE 
	[files].[type] in(0,1) AND                    -- data and log files check
	[files].growth != 0 AND	                  -- autogrow enabled check
  
	  lower(db_name(database_id))  NOT IN (N'master', N'tempdb', N'model', N'msdb', N'pubs', N'northwind', N'adventureworks', N'adventureworksdw')
    ) t  
	where t.NextGrowthSize >=1024
	order by [Server Name],[Instance Name],[Database Name],[Next Growth MB],[Read Only]
end
else 
if 8 = (select substring(@version, 1, 1))
begin

---for SQL Server 2000
	set quoted_identifier off
	declare @MaxDatabases int
	declare @currentDBID int
	declare @SQLStmt nvarchar(500)

	if object_id('tempdb.dbo.#FileGPInfo') is not null
		Drop table #FileGPInfo

	create table #FileGPInfo
	(databaseid int,
	FileGroupID int,
	ReadonlyBIT char(3)
	)

	if object_id('tempdb.dbo.#FilesInfo') is not null
		Drop table #FilesInfo

	create table #FilesInfo
	(databaseid int,
	FileGroupID int,
	FileStatus int,
	FileSize int,
	FileGrowth int,
	FileName nvarchar(128)
	)

	set @currentDBID =5
	select @MaxDatabases = max(dbid) from master..sysdatabases
	while (@currentDBID <= @MaxDatabases)
	begin
		select @databasename =db_name(@currentDBID)
		if DATABASEPROPERTYEX(@databasename,'status') ='ONLINE'
		begin

			set @SQLStmt = ' insert into #FileGPInfo SELECT '+
			convert(varchar,@currentDBID)+',groupid,''Yes'' from ['+  db_name(@currentDBID)+ '].dbo.sysfilegroups where status & 0x8 =0x8' +
			'insert into #FilesInfo SELECT ' +convert(varchar,@currentDBID)+',groupid,status,size,growth,name from ['+db_name(@currentDBID)+'].dbo.sysfiles'
			--select @SQLStmt
			exec ( @SQLStmt)
			
		end
		set @currentDBID=@currentDBID+1
	end
	
	select  distinct serverproperty('machinename')                               as 'Server Name',                                           
    isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
	t.[database_name] as 'Database Name',t.[Logical_Name] as 'Logical Name', t.NextGrowthSize as 'Next Growth MB',
	t.[is_read_only] as 'Read Only' from

	(SELECT 	db_name([files].databaseid) as [database_name],
	[files].FileName as [Logical_Name],
	NextGrowthSize=
	case 
		when files.FileStatus &0x100000 = 0x100000 then convert(numeric(18,2),(((convert(Numeric,files.FileSize)*files.FileGrowth)/100)*8)/1024) ---set to % growth
		else   convert(numeric(18,2),(convert(numeric,files.FileGrowth)*8)/1024) ---set to fixed growth%
	end ,
	is_read_only =
	case FG.ReadonlyBIT
		when 'Yes' then 'Yes'
		else 'No'
	end 
	FROM
	#FilesInfo  [files]
	Left outer join #FileGPInfo FG
	on [files].databaseid=FG.databaseid and [Files].FileGroupID=FG.FileGroupID
	WHERE [files].FileGrowth != 0 )t 
	WHERE	          
	NextGrowthSize>=1024 and t.[database_name] not in (N'master', N'tempdb', N'model', N'msdb', N'pubs', N'northwind', N'adventureworks', N'adventureworksdw') 
	order by [Server Name],[Instance Name],[Database Name],[Next Growth MB],[Read Only]
end

