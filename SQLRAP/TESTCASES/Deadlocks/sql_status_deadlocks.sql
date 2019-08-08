--Signature="DBD5900ACAB052CA" 




--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    Number of deadlocks per minute since server was started                                           ****/
--/****    6/1/08 - Tim Wolff - Removed 'Number of Deadlocks/sec' column from results set                    ****/
--/****    9/19/08 - Ward Pond - Removed 'Database Name' column from results set (CR 242960)                 ****/
--/****    7/16/09 - Ward Pond - add support for SQL2K8 (CR 375891)                                          ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright (c) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/


declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));

 if  '10' = (select substring(@version, 1, 2))  -- CR 375891
     begin
         select distinct serverproperty('machinename')                               as 'Server Name',                                           
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                pc.cntr_value                                                        as 'Total Deadlocks'
           from master.sys.dm_os_performance_counters pc
          where pc.counter_name  = 'Number of Deadlocks/sec'
            and pc.instance_name = '_Total'
            and pc.cntr_value >= 1  
     end
 else -- CR 375891
 if  9 = (select substring(@version, 1, 1))
     begin
         select distinct serverproperty('machinename')                               as 'Server Name',                                           
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                pc.cntr_value                                                        as 'Total Deadlocks'
           from master.sys.dm_os_performance_counters pc
          where pc.counter_name  = 'Number of Deadlocks/sec'
            and pc.instance_name = '_Total'
            and pc.cntr_value >= 1  
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin
         select distinct serverproperty('machinename')                               as 'Server Name',                                           
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                pc.cntr_value                                                        as 'Total Deadlocks' 
           from master..sysperfinfo pc
          where pc.counter_name  = 'Number of Deadlocks/sec'
            and pc.instance_name = '_Total'
            and pc.cntr_value >= 1          
         end;
