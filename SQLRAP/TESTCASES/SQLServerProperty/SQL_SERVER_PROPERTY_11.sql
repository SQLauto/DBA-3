--Signature="B5F0A3766E3F16EC" 
--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****      Verify SQL Server Full Text Indexing is installed                                               ****/
--/****      Default is not-installed and is prefered unless dictated by application or by design.           ****/
--/****      September 15th 2009: djaiswal, changed for SQL2K8 reference CR 379851                           ****/
--/****      Nov 19th 2009 -rajpo -Free text service in SQL 2008 is part of the engine and always installed  ****/
--/****      So setting the default value for SQL2008 as 1 so the issue never fires                          ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright � Microsoft Corporation. All rights reserved.                                           ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/
declare @2008default nvarchar(50);
set     @2008default = '1';

declare @2005default nvarchar(50);
set     @2005default = '0';

declare @2000default nvarchar(50);
set     @2000default = '0';

declare @property nvarchar(50)
set     @property = 'IsFullTextInstalled'

declare @version nvarchar(12);
set     @version =  convert(nvarchar(12),serverproperty('productversion'));

 if  '10' = (select substring(@version, 1, 2))
     begin
         select  serverproperty('machinename') as 'Server Name',                                           
                 isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                 @property as 'Server Property',                                                           
                 @2008default as 'Target/Default Value',                                                    
                 convert(nvarchar(50), serverproperty('IsFullTextInstalled')) as 'Property Value'           
         where   convert(nvarchar(50), serverproperty('IsFullTextInstalled')) != @2008default            
     end
 else
	 if  9 = (select substring(@version, 1, 1))
     begin
         select  serverproperty('machinename') as 'Server Name',                                           
                 isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                 @property as 'Server Property',                                                           
                 @2005default as 'Target/Default Value',                                                    
                 convert(nvarchar(50), serverproperty('IsFullTextInstalled')) as 'Property Value'           
         where   convert(nvarchar(50), serverproperty('IsFullTextInstalled')) != @2005default            
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin
             select  serverproperty('machinename') as 'Server Name',                                          
                     isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                     @property as 'Server Property',                                                          
                     @2000default as 'Target/Default Value',                                                   
                     convert(nvarchar(50), serverproperty('IsFullTextInstalled')) as 'Property Value'          
             where   convert(nvarchar(50), serverproperty('IsFullTextInstalled')) != @2000default                         
         end