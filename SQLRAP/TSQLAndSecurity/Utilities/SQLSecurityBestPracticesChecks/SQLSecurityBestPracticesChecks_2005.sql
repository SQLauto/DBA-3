--Signature="4A3BA7969EEA9088" 

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    Report logins with security configuration issues for SQL Server 2005 instances                    ****/
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

 if  9 = (select substring(@version, 1, 1))
     begin

        select  serverproperty('machinename')                                        as 'Server Name',
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                name                                                                 as 'Login With Blank Password'
        from    master.sys.sql_logins
        where   pwdcompare('',password_hash)=1
        order by name
        option (maxdop 1)

        select  serverproperty('machinename')                                        as 'Server Name',
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                name                                                                 as 'Login With Password Same As Name'
        from    master.sys.sql_logins
        where   pwdcompare(name,password_hash) = 1
        order by name
        option (maxdop 1)

        select  distinct serverproperty('machinename')                                        as 'Server Name',
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
                lgn.name                                                             as 'Credential With Sysadmin Privilege'
        from    sys.server_role_members rm
        join    sys.server_principals lgn
        on      rm.member_principal_id           = lgn.principal_id
        and     rm.role_principal_id             >=3
        and     rm.role_principal_id             <=10
        and     SUSER_NAME(rm.role_principal_id) = 'sysadmin'
        and     lgn.name                         not in ('sa','NT AUTHORITY\SYSTEM')
        order by lgn.name
        option (maxdop 1)

        -- now go get the credentials with dbo/db_owner authority from each accessible user database.
        -- this will require a temp table (from which we'll ultimately report), a cursor, and dynamic SQL
        
        declare GetTheDatabases cursor for
        select name
        from master.sys.databases
        where   lower(name) NOT IN (N'master', N'tempdb', N'model', N'msdb', N'pubs', N'northwind', N'adventureworks', N'adventureworksdw')
        and		state_desc = N'ONLINE'
        and		is_distributor = 0 
        order by database_id
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
                    from    sys.database_principals member
                    join    sys.database_role_members rm
                    on      member.principal_id = rm.member_principal_id
                    join    sys.database_principals [role]
                    on      [role].principal_id = rm.role_principal_id
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