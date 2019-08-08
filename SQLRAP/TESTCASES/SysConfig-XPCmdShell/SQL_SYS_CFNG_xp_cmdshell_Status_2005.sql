--Signature="55C3F9FF319906A9"

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****      Display configuration parameters different than default                                         ****/
--/****                                                                                                      ****/
--/****      10/06/08 - Ward Pond - CR 245579                                                                ****/
--/****      Added validation for SQL Server 2008 - djaiswal 9/20/2009  Ref CR 375891                                                                                                  ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright � Microsoft Corporation. All rights reserved.                                           ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

declare @2005default int;
set     @2005default = 0;

declare @2008default int;
set     @2008default = 0;

declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));

if  '10' = (select substring(@version, 1, 2))
 begin
     select  serverproperty('machinename') as 'Server Name',                                           
             isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
             a.name as 'Configuration Name',                                                           
             @2008default as 'Target/Default Value',                                                 
             a.value as 'Set Value',                                                                  
             a.value_in_use as 'Run Value',
             CASE
                WHEN b.OtherAccessGranted = 1 THEN 1
                WHEN c.OtherAccessGranted = 1 THEN 1
                ELSE 0
             END  as 'OtherAccessGranted'
       from  master.sys.configurations a
	   join  (select case count(1) when 0 then 0 when null then 0 else 1 end as OtherAccessGranted
			  from sys.database_permissions
			  where major_id = object_id(N'xp_cmdshell')
			  and permission_name = N'EXECUTE'
			  and state_desc = N'GRANT') b
	   on    1=1
	   join  (select case count(1) when 0 then 0 when null then 0 else 1 end as OtherAccessGranted
                from sys.database_permissions p
                join sys.database_principals c
                on   p.major_id = object_id('xp_cmdshell')
                and  p.grantor_principal_id = c.principal_id
                and  lower(c.name) = N'##xp_cmdshell_proxy_account##') c
	     on  a.configuration_id = 16390
        and  a.value_in_use != @2008default
		and (b.OtherAccessGranted=0 and c.OtherAccessGranted=0)
 end
 else
 if  9 = (select substring(@version, 1, 1))
 begin
     select  serverproperty('machinename') as 'Server Name',                                           
             isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
             a.name as 'Configuration Name',                                                           
             @2005default as 'Target/Default Value',                                                 
             a.value as 'Set Value',                                                                  
             a.value_in_use as 'Run Value',
             CASE
                WHEN b.OtherAccessGranted = 1 THEN 1
                WHEN c.OtherAccessGranted = 1 THEN 1
                ELSE 0
             END  as 'OtherAccessGranted'
       from  master.sys.configurations a
	   join  (select case count(1) when 0 then 0 when null then 0 else 1 end as OtherAccessGranted
			  from sys.database_permissions
			  where major_id = object_id(N'xp_cmdshell')
			  and permission_name = N'EXECUTE'
			  and state_desc = N'GRANT') b
	   on    1=1
	   join  (select case count(1) when 0 then 0 when null then 0 else 1 end as OtherAccessGranted
                from sys.database_permissions p
                join sys.database_principals c
                on   p.major_id = object_id('xp_cmdshell')
                and  p.grantor_principal_id = c.principal_id
                and  lower(c.name) = N'##xp_cmdshell_proxy_account##') c
	     on  a.configuration_id = 16390
        and  a.value_in_use != @2005default
		and (b.OtherAccessGranted=0 and c.OtherAccessGranted=0)
 end