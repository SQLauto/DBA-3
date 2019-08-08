--Signature="7A27DAE68D6C0857" 


--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    Display all databases with auto update stats async enabled                                        ****/
--/****                                                                                                      ****/
--/****    created 2008.Mar.06 by wardp                                                                      ****/
--/****    updated 2008.May.01 by wardp to test for exactly the opposite of what we were testing for before  ****/
--/****    updated 2009.Jul.17 by wardo to add support for SQL2K8 (CR 375891)                                ****/
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


 if  '10' = (select substring(@version, 1, 2))
     begin
         select distinct serverproperty('machinename')                               as 'Server Name',                                           
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
                name                                                                 as 'Database Name',
                N'TRUE'                                                              as 'Async Auto Update Stats Enabled'
           from master.sys.databases
           where is_auto_update_stats_async_on = 1
           order by name
     end
 else -- CR 375891
 if  9 = (select substring(@version, 1, 1))
     begin
         select distinct serverproperty('machinename')                               as 'Server Name',                                           
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
                name                                                                 as 'Database Name',
                N'TRUE'                                                              as 'Async Auto Update Stats Enabled'
           from master.sys.databases
           where is_auto_update_stats_async_on = 1
           order by name
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin

         select distinct serverproperty('machinename')                               as 'Server Name',                                           
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
                ''                                                                   as 'Database Name',
                ''                                                                   as 'Async Auto Update Stats Enabled'
          where 1 = 2
         end;