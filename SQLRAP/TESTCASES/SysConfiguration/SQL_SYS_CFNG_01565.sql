--Signature="B779383871FAED07"

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****      Display configuration parameters different than default                                         ****/
--/****                                                                                                      ****/
--/****      10/06/08 - Ward Pond - CR 245579                                                                ****/
--/****      9/30/09 - Mohan Lavu - CR 375891                                                                ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright � Microsoft Corporation. All rights reserved.                                           ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

declare @2008default int;
set     @2008default = 100;

declare @2005default int;
set     @2005default = 100;

declare @2000default int;
set     @2000default = 100;

declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));

 if  '10' = (select substring(@version, 1, 2)) --CR 375891
     begin
         select  serverproperty('machinename') as 'Server Name',                                            
                 isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                 a.name as 'Configuration Name',                                                                  
                 @2008default as 'Target/Default Value',                                                           
                 a.value as 'Set Value',                                                                            
                 a.value_in_use as 'Run Value'                                                           
           from  master.sys.configurations a
          where  a.configuration_id = 1565
            and  a.value_in_use != @2008default
     end                         --CR 375891
 else
     if  9 = (select substring(@version, 1, 1))
     begin
         select  serverproperty('machinename') as 'Server Name',                                            
                 isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                 a.name as 'Configuration Name',                                                                  
                 @2005default as 'Target/Default Value',                                                           
                 a.value as 'Set Value',                                                                            
                 a.value_in_use as 'Run Value'                                                           
           from  master.sys.configurations a
          where  a.configuration_id = 1565
            and  a.value_in_use != @2005default
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin
             select  serverproperty('machinename') as 'Server Name',                                          
                     isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                     c.name as 'Configuration Name',                                                              
                     @2000default as 'Target/Default Value',                                                            
                     a.value as 'Set Value',                                                                              
                     b.value as 'Run Value'                                                                  
               from  master..sysconfigures a 
               join  master..syscurconfigs b on b.config = a.config
               join  master..spt_values c on b.config = c.number
              where  a.config = 1565 
                and  c.type = 'C'
                and  b.value != @2000default
         end;

