--Signature="4F6E9648FB285EF3"

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****      Display configuration parameters different than default                                         ****/
--/****                                                                                                      ****/
--/****      10/06/08 - Ward Pond - CR 245579                                                                ****/
--/****      10/14/09 - djaiswal - CR 379851                                                                                                 ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright � Microsoft Corporation. All rights reserved.                                           ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/
declare @2008default int;
set     @2008default = 4096;

declare @2005default int;
set     @2005default = 4096;

declare @2000default int;
set     @2000default = 4096;

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
                     WHEN a.value >= 8096 THEN N'High'
                     ELSE N'Medium'
                 END as 'Risk'                                                            
           from  master.sys.configurations a
          where  a.configuration_id = 505
            and  a.value_in_use != @2008default
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
                     WHEN a.value >= 8096 THEN N'High'
                     ELSE N'Medium'
                 END as 'Risk'                                                            
           from  master.sys.configurations a
          where  a.configuration_id = 505
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
                     b.value as 'Run Value',
                     CASE
                         WHEN a.value >= 8096 THEN N'High'
                         ELSE N'Medium'
                     END as 'Risk'                                                                   
               from  master..sysconfigures a 
               join  master..syscurconfigs b on b.config = a.config
               join  master..spt_values c on b.config = c.number
              where  a.config = 505 
                and  c.type = 'C'
                and  b.value != @2000default
         end;

