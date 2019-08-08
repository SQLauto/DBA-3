--Signature="D4CC3543AFB136BD"

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****      Display configuration parameters different than default                                         ****/
--/****                                                                                                      ****/
--/****      10/06/08 - Ward Pond - CR 245579                                                                ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright � Microsoft Corporation. All rights reserved.                                           ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

declare @2000default int;
set     @2000default = 1;

declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));
  
if  8 =  (select substring(@version, 1, 1))
 begin

	declare @sysadmin_only int, @OtherAccessGranted int

	EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
										 N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
										 N'SysAdminOnly',
										 @sysadmin_only OUTPUT,
										 N'no_output'
	SET @OtherAccessGranted =
	    CASE @sysadmin_only 
	        WHEN 1 THEN 0
	        WHEN 0 THEN 1
	     END

     select  serverproperty('machinename') as 'Server Name',                                         
             isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
             a.name as 'Configuration Name',                                                            
             @2000default as 'Target/Default Value',                                                   
             1 as 'Set Value',                                                                   
             1 as 'Run Value',
			 CASE
			     WHEN d.OtherAccessGranted = 1 THEN 1
			     WHEN @OtherAccessGranted = 1 THEN 1
			     ELSE 0
			 END AS OtherAccessGranted                                                                 
       from  master..sysobjects a 
	   join  (select case count(1) when 0 then 0 when null then 0 else 1 end as OtherAccessGranted
			  from master..syspermissions
			  where id = object_id(N'xp_cmdshell')
			  and (actmod = 32 or actadd = 32)) d
		 on  1=1
      where  a.name = N'xp_cmdshell'
        and  a.xtype = N'X' 
	and (d.OtherAccessGranted =1 or @OtherAccessGranted =1)
end;