--Signature="EA5C44FF28DB94C1"

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

declare @2000default char(10);
set     @2000default = 'Enabled';

declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));

if  8 =  (select substring(@version, 1, 1))
 begin
	if not exists (select a.name from  master..sysobjects a 
      where  a.name = N'xp_cmdshell'
        and  a.xtype = N'X' )

     select  serverproperty('machinename') as 'Server Name',                                         
             isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
             'xp_cmdshell' as 'Configuration Name',                                                            
             @2000default as 'Target/Default Value',                                                   
             'Removed' as 'Set Value',                                                                   
             'Removed' as 'Run Value',
			0  as 'OtherAccessGranted'
		
end;