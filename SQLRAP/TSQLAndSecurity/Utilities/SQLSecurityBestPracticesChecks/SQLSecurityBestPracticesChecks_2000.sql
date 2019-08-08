--Signature="1B02FE863E91000F" 

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    Report logins with security configuration issues for SQL Server 2000 instances                    ****/
--/****                                                                                                      ****/
--/****    created 04 May 2009 (wardp) - convert Raj's draft to SQLRAP form                                  ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copryright (c) Microsoft Corporation.  All rights reserved.                                       ****/                                                                                                  ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/
set nocount on

declare @version char(12),
        @dbname sysname,
        @SQLString nvarchar(4000)

set     @version =  convert(char(12),serverproperty('productversion'));

create table #SQLRAP_DBSecurityCheck (
    DBSecurityCheckId   int identity(1,1),
    DatabaseName        sysname,
    DatabaseCredential  sysname,
    DatabasePrivilege   nvarchar(10)
)

 if  8 =  (select substring(@version, 1, 1))
     begin

        select  distinct serverproperty('machinename')                               as 'Server Name',
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
                a.name                                                               as 'Login With Blank Password'
        from    master.dbo.syslogins a
        join    master.dbo.sysxlogins b
        on      a.sid = b.sid
        where   a.isntuser !=1
        and     a.isntgroup !=1
        and     b.password is null
        and     a.name !='distributor_admin'
        and     b.srvid IS NULL
        order by a.name
        option (maxdop 1)

        select  serverproperty('machinename')                                        as 'Server Name',
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                name                                                                 as 'Login With Password Same As Name'
        from    master.dbo.sysxlogins sxl
        where   srvid is NULL
        and     pwdcompare(sxl.name, sxl.password, (CASE WHEN sxl.xstatus & 2048 = 2048 THEN 1 ELSE 0 END)) = 1
        order by name
        option (maxdop 1)

        select  serverproperty('machinename')                                        as 'Server Name',
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
                lgn.name                                                             as 'Credential With Sysadmin Privilege'
        from    master.dbo.spt_values spv
        join    master.dbo.sysxlogins lgn
        on      spv.number & lgn.xstatus = spv.number
		where   spv.low = 0
		and     spv.type = 'SRV'
		and     lgn.srvid IS NULL
        and     spv.name = 'sysadmin'
        and     lgn.name not in ('sa','NT AUTHORITY\SYSTEM')
        order by lgn.name
        option (maxdop 1)

        -- now go get the credentials with dbo/db_owner authority from each accessible user database.
        -- this will require a temp table (from which we'll ultimately report), a cursor, and dynamic SQL
        
        -- find the distribution database so we can exclude it
        declare @distribdb sysname
 
        exec sp_helpdistributor @distribdb = @distribdb output
        
        declare GetTheDatabases cursor for
        select  name
        from    master.dbo.sysdatabases
        where   lower(name) NOT IN (N'master', N'tempdb', N'model', N'msdb', N'pubs', N'northwind', N'adventureworks', N'adventureworksdw')
        AND  (
	         (@distribdb is not null and lower(name) <> lower(@distribdb))
	         OR
	         (@distribdb IS NULL)
	         )
        -- omit databases which did not start up cleanly
        and		status & 32 = 0		-- loading
        and		status & 64 = 0		-- pre recovery
        and		status & 128 = 0	-- recovering
        and		status & 256 = 0	-- not recovered
        and		status & 512 = 0	-- offline
        and		status & 32768 = 0	-- emergency mode
        order by dbid
        option (maxdop 1)

        open GetTheDatabases

        fetch next from GetTheDatabases
        into @dbname
        
        while @@fetch_status = 0

        begin
        
            exec('use [' + @dbname + '];
                    insert #SQLRAP_DBSecurityCheck (DatabaseName, DatabaseCredential, DatabasePrivilege)
                    select  db_name(),
                            member.name,
                            [role].name
                    from    sysusers member
                    join    sysmembers rm
                    on      member.uid = rm.memberuid
                    join    sysusers [role]
                    on      [role].uid = rm.groupuid
                    and     [role].name in (''dbo'',''db_owner'')
                    and     member.name not in (''dbo'',''db_owner'')
                    order by member.name, [role].name
                    option (maxdop 1)')

            fetch next from GetTheDatabases
            into @dbname
                
        end
        
        close GetTheDatabases
        
        deallocate GetTheDatabases

        select  serverproperty('machinename')                                        as 'Server Name',
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
                DatabaseName                                                         as 'Database Name',
                DatabaseCredential                                                   as 'Credential With Elevated Privilege',
                DatabasePrivilege                                                    as 'Privilege Held By Credential'
        from    #SQLRAP_DBSecurityCheck
        order by DatabaseName, DatabaseCredential
        option (maxdop 1)

     end

    drop table #SQLRAP_DBSecurityCheck