--Signature="44ABCE87FD374C0A" 

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    Database Property validation for IsAutoShrink. All databases are listed in order to do a          ****/
--/****    visual verification of which IsAutoShrink  setting is used.                                       ****/
--/****                                                                                                      ****/
--/****    6/20/08 - Tim Wolff - added code to exclude tempdb                                                ****/
--/****    7/17/09 - Ward Pond - add support for SQL2K8 (CR 375891)                                          ****/
--/****    11/02/09 - Devin Jaiswal - Changed @2008default = 0                                                                                                 ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright (c) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

declare @2008default int;
set     @2008default = 0;

declare @2005default int;
set     @2005default = 0;

declare @2000default int;
set     @2000default = 0;


declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));

 if  '10' = (select substring(@version, 1, 2))  -- CR 375891
     begin
         select  serverproperty('machinename')                                          as 'Server Name',                                            
                 isnull(serverproperty('instancename'),serverproperty('machinename'))   as 'Instance Name',
                 name                                                                   as 'Database Name',
                 'Yes'			                                                        as 'Is The Auto Shrink Setting On?'
           from  master.sys.databases
          where  is_auto_shrink_on != @2008default
          and name != 'tempdb'
          order  by 'Database Name'
     end
 else -- CR 375891
 if  9 = (select substring(@version, 1, 1))
     begin
         select  serverproperty('machinename')                                          as 'Server Name',                                            
                 isnull(serverproperty('instancename'),serverproperty('machinename'))   as 'Instance Name',
                 name                                                                   as 'Database Name',
                 'Yes'			                                                        as 'Is The Auto Shrink Setting On?'
           from  master.sys.databases
          where  is_auto_shrink_on != @2005default
          and name != 'tempdb'
          order  by 'Database Name'
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin
             select  serverproperty('machinename')                                           as 'Server Name',                                            
                     isnull(serverproperty('instancename'),serverproperty('machinename'))    as 'Instance Name',
                     name                                                                    as 'Database Name',
                     'Yes'			                                                         as 'Is The Auto Shrink Setting On?'
               from  master..sysdatabases
              where  databasepropertyex(name, 'IsAutoShrink') != @2000default
              and name != 'tempdb'
              order  by 'Database Name'
         end;

