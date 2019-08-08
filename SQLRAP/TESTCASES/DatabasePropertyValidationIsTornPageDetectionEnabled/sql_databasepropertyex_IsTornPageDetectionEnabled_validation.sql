--Signature="A56363E15833D59B" 
--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    Database Property validation for IsTornPageDetectionEnabled or CHECKSUM. All databases are listed ****/
--/****    in order to do a visual verification of which IsTornPageDetectionEnabled/CHECKSUM setting is not  ****/
--/****    enabled.                                                                                          ****/
--/****                                                                                                      ****/
--/****    Revised 2008.Mar.18 to return results only for SQL 2000 (wardp)                                   ****/
--/****      also changed and contents of 'Is The Checksum or TornPage Detection Setting Enabled?'           ****/
--/****    Revised 2009.Jul.17 by wardp to add support for SQL2K8 (CR 375891)                                ****/
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
         select  serverproperty('machinename')                                          as 'Server Name',                                            
                 isnull(serverproperty('instancename'),serverproperty('machinename'))   as 'Instance Name',
                 name                                                                   as 'Database Name',
                 'False'			                                                    as 'TornPage Detection Enabled'
           from  master.sys.databases
			where 1=2
     end
 else -- CR 375891
 if  9 = (select substring(@version, 1, 1))
     begin
         select  serverproperty('machinename')                                          as 'Server Name',                                            
                 isnull(serverproperty('instancename'),serverproperty('machinename'))   as 'Instance Name',
                 name                                                                   as 'Database Name',
                 'False'			                                                    as 'TornPage Detection Enabled'
           from  master.sys.databases
			where 1=2
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin
         select  serverproperty('machinename')                                          as 'Server Name',                                            
                 isnull(serverproperty('instancename'),serverproperty('machinename'))   as 'Instance Name',
                 name                                                                   as 'Database Name',
                 'False'			                                                    as 'TornPage Detection Enabled'
               from  master..sysdatabases
              where databasepropertyex(name, 'IsTornPageDetectionEnabled') = 0
			and name != 'tempdb'
			order  by 'Database Name'
         end;

