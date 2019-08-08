--Signature="4F57D673A4B4059B" 

declare @version nvarchar(12);
set     @version =  convert(nvarchar(12),serverproperty('productversion'));

if  '8' <> (select substring(@version, 1, 1))
	begin
		USE [master];

		SELECT   serverproperty('machinename')                                          as 'Server Name',                                            
						 isnull(serverproperty('instancename'),serverproperty('machinename'))   as 'Instance Name',
						 t1.session_id,login_name  FROM   sys.dm_exec_sessions [sessions],
		(SELECT session_id, SUM(internal_objects_alloc_page_count + user_objects_alloc_page_count) AS task_alloc
		FROM sys.dm_db_task_space_usage GROUP BY session_id) AS t1	where sessions.session_id = t1.session_id AND 
		 ((task_alloc * 8) / 1024) > 500 AND -- (((#pages * 8192) / (1024 * 1024)) > 500)
		 ((task_alloc * 8) / 1024) >   (
		  SELECT  
		 ((sum([size]) * 8 * 5) / (1024 * 100)) -- (5% of [(#pages * 8192) / (1024 * 1024)])
		FROM   sys.sysaltfiles [files] where groupid = 1 AND db_name([files].[dbid]) = 'tempdb')
end