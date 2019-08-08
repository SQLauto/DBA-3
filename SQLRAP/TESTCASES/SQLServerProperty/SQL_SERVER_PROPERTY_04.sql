--Signature="8ABE71A2DDA534D6" 

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****      Verify Comparison Style has been changed from the default                                       ****/
--/****      Added validation for SQL Server 2008 - djaiswal 9/14/2009 CR 375891                                                                                            ****/
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
set     @2008default = '196609';

declare @2005default nvarchar(50);
set     @2005default = '196609';

declare @2000default nvarchar(50);
set     @2000default = '196609';

declare @property nvarchar(50)
set     @property = 'ComparisonStyle'

declare @version nvarchar(12);
set     @version =  convert(nvarchar(12),serverproperty('productversion'));

if  '10' = (select substring(@version, 1, 2))
     begin
         select  serverproperty('machinename') as 'Server Name',                                           
                 isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name', 
                 @property as 'Server Property',                                                            
                 @2008default as 'Target/Default Value',                                                
                 convert(nvarchar(50), serverproperty('ComparisonStyle')) as 'Property Value'              
         where   convert(nvarchar(50), serverproperty('ComparisonStyle')) != @2008default            
     end
 else
	 if  9 = (select substring(@version, 1, 1))
     begin
         select  serverproperty('machinename') as 'Server Name',                                           
                 isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name', 
                 @property as 'Server Property',                                                            
                 @2005default as 'Target/Default Value',                                                
                 convert(nvarchar(50), serverproperty('ComparisonStyle')) as 'Property Value'              
         where   convert(nvarchar(50), serverproperty('ComparisonStyle')) != @2005default            
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin
             select  serverproperty('machinename') as 'Server Name',                                           
                     isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                     @property as 'Server Property',                                                           
                     @2000default as 'Target/Default Value',                                                   
                     convert(nvarchar(50), serverproperty('ComparisonStyle')) as 'Property Value'               
             where   convert(nvarchar(50), serverproperty('ComparisonStyle')) != @2000default                         
         end



