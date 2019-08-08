--Signature="45DFE40D6C67E5BA" 
--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    Display jobs owned by the sa credential.                                                          ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright (C) Microsoft Corporation. All rights reserved.                                         ****/
--/****                                                                                                      ****/
--/**** created 19 Nov 2008 wardp: CR 255772                                                                 ****/
--/**** updated 07 Jan 2009 wardp: bug 292850                                                                ****/
--/**** updated 13 Jan 2009 wardp: bug 292849                                                                ****/
--/**** updated 04 Feb 2009 wardp: bug 292849                                                                ****/
--/**** updated 16 Feb 2009 wardp: bug 292849 again                                                          ****/
--/**** updated 04 Mar 2009 wardp: bug 292849 yet again (this should be it)                                  ****/
--/**** updated 11 Mar 2009 wardp: bug 292849 once again (edge case for non-null sid with null suser_sname)  ****/
--/**** updated	27 Mar 2008 rajpo: Made significant changes to SQL2005 tree to diplay only job steps that are****/
--/**** not configured proxy, configured proxy but proxy runs under sysadmin account, for T-SQL steps whose  ****/
--/**** job owners is the member of sysadmin role.                                                           ****/
--/**** updated 16 Jul 2009 wardp: CR 375891 (SQL Server 2008 support)                                       ****/
--/**** updated 17 feb 2010 rajpo:  Added the column is enabled                                              ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

-- keep some house

set nocount on
    
declare @version char(12),
        @spid nvarchar(40),
        @db_id nvarchar(12)

set @spid = CAST(@@spid as nvarchar(40))
set @version =  convert(char(12),serverproperty('productversion'));
set @db_id = db_id(db_name())

 if  '10' = (select substring(@version, 1, 2))  -- CR 375891
     begin

        EXEC('
        DECLARE @UserName sysname,
                @SQLString nvarchar(4000)
        
        -- load a temp table with credentials for all branches of the query
        -- use of UNION operator will strip out all duplicates, which is what we want  
		IF OBJECT_ID (''tempdb.dbo.#Credentials'' ) IS NOT NULL
			DROP TABLE   #Credentials

		CREATE TABLE #Credentials (
			CredentialId int identity(1,1) primary key,
			Credential_sid varbinary(max),
			UserName nvarchar(256),
			IsAliasedToSysAdmin bit
			)

        INSERT  #Credentials (Credential_sid, UserName)
        (
        SELECT  owner_sid, suser_sname(owner_sid)  -- all branches
        FROM    msdb.dbo.sysjobs
        --WHERE   owner_sid IS NOT NULL
        
        UNION
        
        SELECT  user_sid, suser_sname(user_sid) -- branch 3
        FROM    msdb.dbo.sysproxies
        --WHERE   user_sid IS NOT NULL
        )

		-- build a cursor to traverse the credentials and run a piece of dynamic SQL        
        DECLARE TraverseTheCredentials CURSOR FAST_FORWARD
        FOR
        SELECT	UserName
        FROM	#Credentials
        --WHERE	UserName IS NOT NULL
        ORDER BY CredentialId
        
        OPEN TraverseTheCredentials
        
        FETCH NEXT FROM TraverseTheCredentials
        INTO @UserName
        
        WHILE @@FETCH_STATUS = 0
        
        BEGIN
            -- build the dynamic SQL which will impersonate the user and check access to CONTROL SERVER permission
            -- CONTROL SERVER is orthoganol to SysAdmin but equivalent, according to Raul Garcia of the SQL PG
			SET  @SQLString =N''
			begin try
			    if len('''''' + ISNULL(@UserName,'''') + N'''''') = 0 -- @UserName is NULL
			    begin
				    update  #Credentials
				    set     IsAliasedToSysAdmin = 0
				    where   UserName is NULL
			    end
			    else
                begin
				    execute as login = '''''' + @UserName + N'''''';

				    update  #Credentials
				    set     IsAliasedToSysAdmin =
				    case 
					    when suser_sid('''''' + @UserName + N'''''') is NULL  -- the credential is unknown to the database
						    then 0 
					    else
						    has_perms_by_name (NULL, NULL, ''''CONTROL SERVER'''')
				    end
				    where   UserName = N'''''' + @UserName + N''''''
				    ;
				    revert
				end
			end try
			begin catch  -- the credential is unknown to the instance; therefore cannot be a member of SysAdmin
				update  #Credentials
				set     IsAliasedToSysAdmin = 0
				where   UserName = N'''''' + @UserName + N''''''
			end catch;''
	        
			--SELECT @SQLString
	        
			EXEC (@SQLString)
	        	        
			FETCH NEXT
			FROM TraverseTheCredentials
			INTO @UserName
		
		END
		
		CLOSE TraverseTheCredentials
		
		DEALLOCATE TraverseTheCredentials

        -- Proxy is set, but the proxy is created based on on an admin account -non-TSQL job systems
		SELECT	serverproperty(''machinename'')                                        AS ''Server Name'',                                           
                isnull(serverproperty(''instancename''),serverproperty(''machinename'')) AS ''Instance Name'',  
				px.name as ''Run Context'',j.name AS ''Job Name'',js.step_name As ''Job Step'',
				case j.enabled
				when 1 then ''Yes''
				when 0 then ''No''
				else ''Unknown''
				end as ''Job Enabled''
		FROM	msdb.dbo.sysjobs j
		LEFT OUTER JOIN msdb.dbo.sysjobsteps js ON (j.job_id =js.job_id)
		LEFT OUTER JOIN msdb.dbo.sysproxies px ON (js.proxy_id =px.proxy_id) 
		JOIN #Credentials Cr ON (px.user_sid =Cr.Credential_sid and Cr.IsAliasedToSysAdmin=1)
		WHERE js.subsystem NOT IN (''TSQL'') AND js.proxy_id is not null

		UNION

---Proxy is set to NULL for non-T-SQL job systems
		SELECT	serverproperty(''machinename'')                                        AS ''Server Name'',                                           
                isnull(serverproperty(''instancename''),serverproperty(''machinename'')) AS ''Instance Name'',
				''SQLAgentAccount'' AS ''Run Context'' ,j.name AS ''Job Name'',js.step_name AS ''Job Step'',
				case j.enabled
				when 1 then ''Yes''
				when 0 then ''No''
				else ''Unknown''
				end as ''Job Enabled''
		FROM msdb.dbo.sysjobs j
		LEFT OUTER JOIN msdb.dbo.sysjobsteps js ON (j.job_id =js.job_id)
		WHERE js.subsystem NOT IN (''TSQL'') AND js.proxy_id is null

---For T-SQL job systems
		UNION

		SELECT	serverproperty(''machinename'')                                        AS ''Server Name'',                                           
                isnull(serverproperty(''instancename''),serverproperty(''machinename'')) AS ''Instance Name'',
				suser_sname(j.owner_sid) AS ''Run Context'',j.name AS ''Job Name'',js.step_name AS ''Job Step'',
				case j.enabled
				when 1 then ''Yes''
				when 0 then ''No''
				else ''Unknown''
				end as ''Job Enabled''
		FROM msdb.dbo.sysjobs j
		LEFT OUTER JOIN msdb.dbo.sysjobsteps js on (j.job_id =js.job_id)
		JOIN #Credentials Cr on (j.owner_sid =Cr.Credential_sid and Cr.IsAliasedToSysAdmin=1)
		WHERE js.subsystem IN (''TSQL'') AND js.proxy_id is null

		IF OBJECT_ID (''tempdb.dbo.#Credentials'' ) IS NOT NULL
			DROP TABLE #Credentials'

		)
		
     end
 else -- CR 375891        
 if  9 = (select substring(@version, 1, 1))
     begin

        EXEC('
        DECLARE @UserName sysname,
                @SQLString nvarchar(4000)
        
        -- load a temp table with credentials for all branches of the query
        -- use of UNION operator will strip out all duplicates, which is what we want  
		IF OBJECT_ID (''tempdb.dbo.#Credentials'' ) IS NOT NULL
			DROP TABLE   #Credentials

		CREATE TABLE #Credentials (
			CredentialId int identity(1,1) primary key,
			Credential_sid varbinary(max),
			UserName nvarchar(256),
			IsAliasedToSysAdmin bit
			)

        INSERT  #Credentials (Credential_sid, UserName)
        (
        SELECT  owner_sid, suser_sname(owner_sid)  -- all branches
        FROM    msdb.dbo.sysjobs
        --WHERE   owner_sid IS NOT NULL
        
        UNION
        
        SELECT  user_sid, suser_sname(user_sid) -- branch 3
        FROM    msdb.dbo.sysproxies
        --WHERE   user_sid IS NOT NULL
        )

		-- build a cursor to traverse the credentials and run a piece of dynamic SQL        
        DECLARE TraverseTheCredentials CURSOR FAST_FORWARD
        FOR
        SELECT	UserName
        FROM	#Credentials
        --WHERE	UserName IS NOT NULL
        ORDER BY CredentialId
        
        OPEN TraverseTheCredentials
        
        FETCH NEXT FROM TraverseTheCredentials
        INTO @UserName
        
        WHILE @@FETCH_STATUS = 0
        
        BEGIN
            -- build the dynamic SQL which will impersonate the user and check access to CONTROL SERVER permission
            -- CONTROL SERVER is orthoganol to SysAdmin but equivalent, according to Raul Garcia of the SQL PG
			SET  @SQLString =N''
			begin try
			    if len('''''' + ISNULL(@UserName,'''') + N'''''') = 0 -- @UserName is NULL
			    begin
				    update  #Credentials
				    set     IsAliasedToSysAdmin = 0
				    where   UserName is NULL
			    end
			    else
                begin
				    execute as login = '''''' + @UserName + N'''''';

				    update  #Credentials
				    set     IsAliasedToSysAdmin =
				    case 
					    when suser_sid('''''' + @UserName + N'''''') is NULL  -- the credential is unknown to the database
						    then 0 
					    else
						    has_perms_by_name (NULL, NULL, ''''CONTROL SERVER'''')
				    end
				    where   UserName = N'''''' + @UserName + N''''''
				    ;
				    revert
				end
			end try
			begin catch  -- the credential is unknown to the instance; therefore cannot be a member of SysAdmin
				update  #Credentials
				set     IsAliasedToSysAdmin = 0
				where   UserName = N'''''' + @UserName + N''''''
			end catch;''
	        
			--SELECT @SQLString
	        
			EXEC (@SQLString)
	        	        
			FETCH NEXT
			FROM TraverseTheCredentials
			INTO @UserName
		
		END
		
		CLOSE TraverseTheCredentials
		
		DEALLOCATE TraverseTheCredentials

        -- Proxy is set, but the proxy is created based on on an admin account -non-TSQL job systems
		SELECT	serverproperty(''machinename'')                                        AS ''Server Name'',                                           
                isnull(serverproperty(''instancename''),serverproperty(''machinename'')) AS ''Instance Name'',  
				px.name as ''Run Context'',j.name AS ''Job Name'',js.step_name As ''Job Step'',
				case j.enabled
				when 1 then ''Yes''
				when 0 then ''No''
				else ''Unknown''
				end as ''Job Enabled''
		FROM	msdb.dbo.sysjobs j
		LEFT OUTER JOIN msdb.dbo.sysjobsteps js ON (j.job_id =js.job_id)
		LEFT OUTER JOIN msdb.dbo.sysproxies px ON (js.proxy_id =px.proxy_id) 
		JOIN #Credentials Cr ON (px.user_sid =Cr.Credential_sid and Cr.IsAliasedToSysAdmin=1)
		WHERE js.subsystem NOT IN (''TSQL'') AND js.proxy_id is not null

		UNION

---Proxy is set to NULL for non-T-SQL job systems
		SELECT	serverproperty(''machinename'')                                        AS ''Server Name'',                                           
                isnull(serverproperty(''instancename''),serverproperty(''machinename'')) AS ''Instance Name'',
				''SQLAgentAccount'' AS ''Run Context'' ,j.name AS ''Job Name'',js.step_name AS ''Job Step'',
				case j.enabled
				when 1 then ''Yes''
				when 0 then ''No''
				else ''Unknown''
				end as ''Job Enabled''
		FROM msdb.dbo.sysjobs j
		LEFT OUTER JOIN msdb.dbo.sysjobsteps js ON (j.job_id =js.job_id)
		WHERE js.subsystem NOT IN (''TSQL'') AND js.proxy_id is null

---For T-SQL job systems
		UNION

		SELECT	serverproperty(''machinename'')                                        AS ''Server Name'',                                           
                isnull(serverproperty(''instancename''),serverproperty(''machinename'')) AS ''Instance Name'',
				suser_sname(j.owner_sid) AS ''Run Context'',j.name AS ''Job Name'',js.step_name AS ''Job Step'',
				case j.enabled
				when 1 then ''Yes''
				when 0 then ''No''
				else ''Unknown''
				end as ''Job Enabled''
		FROM msdb.dbo.sysjobs j
		LEFT OUTER JOIN msdb.dbo.sysjobsteps js on (j.job_id =js.job_id)
		JOIN #Credentials Cr on (j.owner_sid =Cr.Credential_sid and Cr.IsAliasedToSysAdmin=1)
		WHERE js.subsystem IN (''TSQL'') AND js.proxy_id is null

		IF OBJECT_ID (''tempdb.dbo.#Credentials'' ) IS NOT NULL
			DROP TABLE #Credentials'

		)
		
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin

            SELECT  serverproperty('machinename')                                        AS 'Server Name',                                           
                    isnull(serverproperty('instancename'),serverproperty('machinename')) AS 'Instance Name',  
                    suser_sname(owner_sid)  AS 'Run Context',  
                    name          AS 'Job Name',
                    'All'         AS 'Job Step',
                    case enabled
				when 1 then 'Yes'
				when 0 then 'No'
				else 'Unknown'
				end as 'Job Enabled'

            FROM    msdb.dbo.sysjobs
            WHERE   is_srvrolemember('sysadmin',suser_sname(owner_sid)) = 1

            UNION

            SELECT  serverproperty('machinename')                                        AS 'Server Name',                                           
                    isnull(serverproperty('instancename'),serverproperty('machinename')) AS 'Instance Name',  
                    js.database_user_name  AS 'Run Context',  
                    j.name        AS 'Job Name',
                    js.step_name  AS 'Job Step',
                     case j.enabled
				when 1 then 'Yes'
				when 0 then 'No'
				else 'Unknown'
				end as 'Job Enabled'

            FROM    msdb.dbo.sysjobsteps js
            JOIN    msdb.dbo.sysjobs j
            ON      j.job_id = js.job_id
            WHERE   is_srvrolemember('sysadmin',js.database_user_name) = 1
            AND     is_srvrolemember('sysadmin',suser_sname(j.owner_sid)) <> 1

         end;