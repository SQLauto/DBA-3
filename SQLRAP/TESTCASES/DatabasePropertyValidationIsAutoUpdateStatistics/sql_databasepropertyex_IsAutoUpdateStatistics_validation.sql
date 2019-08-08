--Signature="740F24C62F045F8B" 


--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    Database Property validation for IsAutoUpdateStatistics. All databases are listed in order        ****/
--/****    to do a visual verification of which IsAutoUpdateStatistics setting is used.                      ****/
--/****                                                                                                      ****/
--/****    7/17/09 - Ward Pond - add support for SQL2K8 (CR 375891)                                          ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright (c) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

declare @2008default int;
set     @2008default = 1;

declare @2005default int;
set     @2005default = 1;

declare @2000default int;
set     @2000default = 1;

declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));


 if  '10' = (select substring(@version, 1, 2))  -- CR 375891
     begin
         select  serverproperty('machinename')                                          as 'Server Name',                                            
                 isnull(serverproperty('instancename'),serverproperty('machinename'))   as 'Instance Name',
                 name                                                                   as 'Database Name',
                 'Yes'					                                                as 'Is The Auto Update Statistics Setting Off?'
           from  master.sys.databases
          where  is_auto_update_stats_on != @2008default
          order  by 'Database Name'
     end
 else -- CR 375891
 if  9 = (select substring(@version, 1, 1))
     begin
         select  serverproperty('machinename')                                          as 'Server Name',                                            
                 isnull(serverproperty('instancename'),serverproperty('machinename'))   as 'Instance Name',
                 name                                                                   as 'Database Name',
                 'Yes'					                                                as 'Is The Auto Update Statistics Setting Off?'
           from  master.sys.databases
          where  is_auto_update_stats_on != @2005default
          order  by 'Database Name'
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin
             select  serverproperty('machinename')                                           as 'Server Name',                                            
                     isnull(serverproperty('instancename'),serverproperty('machinename'))    as 'Instance Name',
                     name                                                                    as 'Database Name',
                     'Yes'					                                                 as 'Is The Auto Update Statistics Setting Off?'
               from  master..sysdatabases
              where  databasepropertyex(name, 'IsAutoUpdateStatistics') != @2000default
              order  by 'Database Name'
         end;

