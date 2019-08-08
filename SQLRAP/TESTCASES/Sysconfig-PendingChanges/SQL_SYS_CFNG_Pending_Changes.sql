--Signature="35DDAE6653EB43E8"

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****      Display configuration parameters with pending changes                                           ****/
--/****                                                                                                      ****/
--/****      10/06/08 - Ward Pond                                                                            ****/
--/****      03/12/09 - Ward Pond (resolve bug 365059)                                                       ****/
--/****      10/13/09 - djaiswal - CR 379851                                                                                                 ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright � Microsoft Corporation. All rights reserved.                                           ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));

 if  '10' = (select substring(@version, 1, 2))
     begin
         select  serverproperty('machinename') as 'Server Name',                                            
                 isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                 a.name as 'Configuration Name',                                                                                  
                 a.value as 'Configured Value',                                                                                 
                 a.value_in_use as 'Run Value'                                                             
           from  master.sys.configurations a
          where  a.value != a.value_in_use
            and  a.is_dynamic = 0 -- bug 365059
     end
 else
 if  9 = (select substring(@version, 1, 1))
     begin
         select  serverproperty('machinename') as 'Server Name',                                            
                 isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                 a.name as 'Configuration Name',                                                                                  
                 a.value as 'Configured Value',                                                                                 
                 a.value_in_use as 'Run Value'                                                             
           from  master.sys.configurations a
          where  a.value != a.value_in_use
            and  a.is_dynamic = 0 -- bug 365059
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin
             select  serverproperty('machinename') as 'Server Name',                                            
                     isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',   
                     c.name as 'Configuration Name',                                                                                    
                     a.value as 'Configured Value',                                                                                  
                     b.value as 'Run Value'                                                                  
               from  master..sysconfigures a 
               join  master..syscurconfigs b
                 on  b.config = a.config
               join  master..spt_values c 
                 on  b.config = c.number
              where  c.type = 'C'
                and  a.value != b.value
         end;