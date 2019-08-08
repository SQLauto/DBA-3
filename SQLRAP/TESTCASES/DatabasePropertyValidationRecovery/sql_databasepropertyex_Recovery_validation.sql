--Signature="F671850D3CAAE0FC" 

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    Database Property validation for Recovery. All databases are listed in order to do a              ****/
--/****    visual verification of which Recovery setting is used.                                            ****/
--/****                                                                                                      ****/
--/****    updated 2009.Jul.17 by wardp to add support for SQL2K8 (CR 375891)                                ****/
--/****                                                                                                      ****/
--/****    updated 2010.sept.24 by rajpo changed logic to report only DBs in simple recovery mode            ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright (c) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

declare @2008default int;
set     @2008default = 3;

declare @2005default int;
set     @2005default = 3;

declare @2000default nvarchar(11);
set     @2000default = 'SIMPLE';

declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));

 if  '10' = (select substring(@version, 1, 2)) -- CR 375891
     begin
         select  serverproperty('machinename')                                          as 'Server Name',                                            
                 isnull(serverproperty('instancename'),serverproperty('machinename'))   as 'Instance Name',
                 name                                                                   as 'Database Name',
                 (case recovery_model 
                       when 1 then 'FULL'
                       when 2 then 'BULK_LOGGED'
                       when 3 then 'SIMPLE'
                   end)                                                                 as 'Recovery Setting'
                   
           from  master.sys.databases
         where  recovery_model = @2008default
			AND name NOT IN ('master', 'model', 'msdb', 'model', 'tempdb', 'northwind', 'pubs', 'AdventureWorks', 
							'AdventureWorksDW', 'Adventure Works DW', 'publication', 'distribution', 'subscription')
          order  by 'Database Name'
     end
 else -- CR 375891
 if  9 = (select substring(@version, 1, 1))
     begin
         select  serverproperty('machinename')                                          as 'Server Name',                                            
                 isnull(serverproperty('instancename'),serverproperty('machinename'))   as 'Instance Name',
                 name                                                                   as 'Database Name',
                 (case recovery_model 
                       when 1 then 'FULL'
                       when 2 then 'BULK_LOGGED'
                       when 3 then 'SIMPLE'
                   end)                                                                 as 'Recovery Setting'
           from  master.sys.databases
          where  recovery_model = @2005default
			AND name NOT IN ('master', 'model', 'msdb', 'model', 'tempdb', 'northwind', 'pubs', 'AdventureWorks', 
							'AdventureWorksDW', 'Adventure Works DW', 'publication', 'distribution', 'subscription')
          order  by 'Database Name'
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin
             select  serverproperty('machinename')                                           as 'Server Name',                                            
                     isnull(serverproperty('instancename'),serverproperty('machinename'))    as 'Instance Name',
                     name                                                                    as 'Database Name',
                     databasepropertyex(name, 'Recovery')                                    as 'Recovery Setting'
               from  master..sysdatabases
              where  databasepropertyex(name, 'Recovery') = @2000default
			AND name NOT IN ('master', 'model', 'msdb', 'model', 'tempdb', 'northwind', 'pubs', 'AdventureWorks', 
							'AdventureWorksDW', 'Adventure Works DW', 'publication', 'distribution', 'subscription')
              order  by 'Database Name'
         end;


