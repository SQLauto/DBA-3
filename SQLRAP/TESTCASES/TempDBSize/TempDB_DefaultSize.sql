 --Signature="D46CF94AE56FCA91" 
 
--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****   Test case checks if the tempdb is created with less or default size of 8MB                         ****/
--/****                                                                                                      ****/
--/****   Updated 07.Apr.09 (wardp) - bug 339922                                                             ****/
--/****   Updated 10.Apr.09 (wardp) - bug 341782 (add signature)                                             ****/
--/****   Updated 17 Jul.09 (wardp) - add SQL2K8 support (CR 375891)                                         ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright (C) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

SET NOCOUNT ON; 

declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));
---Do the version check and create appropriate temp tables first.
if  '10' = (select substring(@version, 1, 2))
begin
	select  distinct serverproperty('machinename')                               as 'Server Name',                                           
    isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
	 'tempdb' as 'Database Name',name as 'Logical Name', physical_name as 'Physical path',(size*8/1024) as 'Size in MB' from sys.master_files [files]
	where database_id =2 and 1024 >= 
	(select sum(size) from sys.master_files 
	where  database_id =2 and type=0)
	
end
else 
if  9 = (select substring(@version, 1, 1))
begin
	select  distinct serverproperty('machinename')                               as 'Server Name',                                           
    isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
	 'tempdb' as 'Database Name',name as 'Logical Name', physical_name as 'Physical path',(size*8/1024) as 'Size in MB' from sys.master_files [files]
	where database_id =2 and 1024 >= 
	(select sum(size) from sys.master_files 
	where  database_id =2 and type=0)
	
end
else 
if 8 = (select substring(@version, 1, 1))
begin

	select  distinct serverproperty('machinename')                               as 'Server Name',                                           
    isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
	'tempdb' as 'Database Name', name as 'Logical Name', filename as 'Physical path',(size*8/1024) as 'Size in MB' from master..sysaltfiles 
	where dbid =2 and 1024 >= 
	(select sum(size) from master..sysaltfiles  
	where  dbid =2 and groupid!=0)
end

--select * from sysaltfiles