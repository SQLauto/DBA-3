--Signature="CBFDB58591F1DCBB" 
--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****      Verify that SQL Server security is set to integrated security only                              ****/
--/****      September 16th 2009: djaiswal, changed for SQL2K8 reference CR 379851                                                                                                ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright � Microsoft Corporation. All rights reserved.                                           ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

declare @2008default nvarchar(50);
set     @2008default = '0';

declare @2005default nvarchar(50);
set     @2005default = '0';

declare @2000default nvarchar(50);
set     @2000default = '0';

declare @property nvarchar(50)
set     @property = 'IsIntegratedSecurityOnly'

declare @version nvarchar(12);
set     @version =  convert(nvarchar(12),serverproperty('productversion'));

 if  '10' = (select substring(@version, 1, 2))
     begin
         select  serverproperty('machinename') as 'Server Name',                                           
                 isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                 @property as 'Server Property',                                                           
                 1 as 'Target Value',                                                      
                 convert(nvarchar(50), serverproperty('IsIntegratedSecurityOnly')) as 'Property Value'     
         where   convert(nvarchar(50), serverproperty('IsIntegratedSecurityOnly')) = @2008default            
     end
 else 
 if  9 = (select substring(@version, 1, 1))
     begin
         select  serverproperty('machinename') as 'Server Name',                                           
                 isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                 @property as 'Server Property',                                                           
                 1 as 'Target Value',                                                      
                 convert(nvarchar(50), serverproperty('IsIntegratedSecurityOnly')) as 'Property Value'     
         where   convert(nvarchar(50), serverproperty('IsIntegratedSecurityOnly')) = @2005default            
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin
             select  serverproperty('machinename') as 'Server Name',                                           
                     isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                     @property as 'Server Property',                                                           
                     1 as 'Target Value',                                                       
                     convert(nvarchar(50), serverproperty('IsIntegratedSecurityOnly')) as 'Property Value'    
             where   convert(nvarchar(50), serverproperty('IsIntegratedSecurityOnly')) = @2000default                         
         end