--Signature="FE50A9D62570F551" 
--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****      List all databases not at appropriate compatibility level for release                           ****/
--/****      wardp 2008.Feb.28                                                                               ****/
--/****                                                                                                      ****/
--/****    wardp 2009.Jul.17 - add support for SQL2K8 (CR 375891)                                            ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright (c) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

declare @2008default nvarchar(50);
set     @2008default = '100';

declare @2005default nvarchar(50);
set     @2005default = '90';

declare @2000default nvarchar(50);
set     @2000default = '80';

declare @version nvarchar(12);
set     @version =  convert(nvarchar(12),serverproperty('productversion'));

 if  '10' = (select substring(@version, 1, 2))
     begin
             select  serverproperty('machinename') as 'Server Name',                                           
                     isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
					 @2008default as 'Default Compatibility Level',  
                     name as 'Database Name',                                       
                     compatibility_level as 'Compatibility Level'
          			 from	 master.sys.databases
             where   compatibility_level != @2008default                         
     end
 else 
 if  9 = (select substring(@version, 1, 1))
     begin
             select  serverproperty('machinename') as 'Server Name',                                           
                     isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
					 @2005default as 'Default Compatibility Level',  
                     name as 'Database Name',                                       
                     compatibility_level as 'Compatibility Level'
          			 from	 master.sys.databases
             where   compatibility_level != @2005default                         
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin
             select  serverproperty('machinename') as 'Server Name',                                           
                     isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
                     @2000default as 'Default Compatibility Level',
                     name as 'Database Name',                                                            
                     cmptlevel as 'Compatibility Level'                                                         
			 from	 master..sysdatabases
             where   cmptlevel != @2000default                         
         end

                              