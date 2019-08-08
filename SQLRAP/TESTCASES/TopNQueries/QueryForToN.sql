--Signature="619D9F920175EFB9" 

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    This script is used to populate the top 50 queries										         ****/
--/****    Valid only for SQL Server 2005 and SQL Server 2008			                                     ****/
--/****                                                                                                      ****/
--/****														                                                 ****/
--/****    10/30/09 - Rajpo - add support for SQL2K8 (CR 375891) -also added logical reads column            ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright (c) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************
--set nocount on
--go

declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));
---Do the version check and create appropriate temp tables first.

if  '10' = (select substring(@version, 1, 2))  -- CR 375891
Begin

---Top 50 high total CPU Queries
SELECT TOP 50
'High CPU Queries' as Type,
serverproperty('machinename')                                        as 'Server Name',                                           
isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
SUBSTRING(qt.text,qs.statement_start_offset/2, 
                  (case when qs.statement_end_offset = -1 
                  then len(convert(nvarchar(max), qt.text)) * 2 
                  else qs.statement_end_offset end -qs.statement_start_offset)/2) 
            as query_text,qp.query_plan,
        qs.execution_count as [Execution Count],
	qs.total_worker_time/1000 as [Total CPU Time],
	(qs.total_worker_time/1000)/qs.execution_count as [Avg CPU Time],
	qs.total_elapsed_time/1000 as [Total Duration],
	(qs.total_elapsed_time/1000)/qs.execution_count as [Avg Duration],
	qs.total_physical_reads as [Total Physical Reads],
	qs.total_physical_reads/qs.execution_count as [Avg Physical Reads],
      qs.total_logical_reads as [Total Logical Reads],
	qs.total_logical_reads/qs.execution_count as [Avg Logical Reads],
        COALESCE(DB_NAME(qt.dbid),
                DB_NAME(CAST(pa.value as int)), 
                'Resource') AS DBNAME
             
           
	FROM sys.dm_exec_query_stats qs
	cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
	outer apply sys.dm_exec_query_plan (qs.plan_handle) qp
	outer APPLY sys.dm_exec_plan_attributes(qs.plan_handle) pa
	where attribute = 'dbid'   
	ORDER BY 
        [Total CPU Time] DESC
        
---Top 50 high total Duration Queries
SELECT TOP 50
'High Duration' as Type,
serverproperty('machinename')                                        as 'Server Name',                                           
isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
SUBSTRING(qt.text,qs.statement_start_offset/2, 
                  (case when qs.statement_end_offset = -1 
                  then len(convert(nvarchar(max), qt.text)) * 2 
                  else qs.statement_end_offset end -qs.statement_start_offset)/2) 
            as query_text,qp.query_plan,
        qs.execution_count as [Execution Count],
	qs.total_worker_time/1000 as [Total CPU Time],
	(qs.total_worker_time/1000)/qs.execution_count as [Avg CPU Time],
	qs.total_elapsed_time/1000 as [Total Duration],
	(qs.total_elapsed_time/1000)/qs.execution_count as [Avg Duration],
	qs.total_physical_reads as [Total Physical Reads],
	qs.total_physical_reads/qs.execution_count as [Avg Physical Reads],
	 qs.total_logical_reads as [Total Logical Reads],
	qs.total_logical_reads/qs.execution_count as [Avg Logical Reads],
      
        COALESCE(DB_NAME(qt.dbid),
                DB_NAME(CAST(pa.value as int)), 
                'Resource') AS DBNAME
             
           
	FROM sys.dm_exec_query_stats qs
	cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
	outer apply sys.dm_exec_query_plan (qs.plan_handle) qp
	outer APPLY sys.dm_exec_plan_attributes(qs.plan_handle) pa
	where attribute = 'dbid'   
	ORDER BY 
        [Total Duration] DESC
        
---Top 50 high total Physical Reads Queries
SELECT TOP 50
'High Physical Reads' as Type,
serverproperty('machinename')                                        as 'Server Name',                                           
isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
SUBSTRING(qt.text,qs.statement_start_offset/2, 
                  (case when qs.statement_end_offset = -1 
                  then len(convert(nvarchar(max), qt.text)) * 2 
                  else qs.statement_end_offset end -qs.statement_start_offset)/2) 
            as query_text,qp.query_plan,
        qs.execution_count as [Execution Count],
	qs.total_worker_time/1000 as [Total CPU Time],
	(qs.total_worker_time/1000)/qs.execution_count as [Avg CPU Time],
	qs.total_elapsed_time/1000 as [Total Duration],
	(qs.total_elapsed_time/1000)/qs.execution_count as [Avg Duration],
	qs.total_physical_reads as [Total Physical Reads],
	qs.total_physical_reads/qs.execution_count as [Avg Physical Reads],
	 qs.total_logical_reads as [Total Logical Reads],
	qs.total_logical_reads/qs.execution_count as [Avg Logical Reads],
      
        COALESCE(DB_NAME(qt.dbid),
                DB_NAME(CAST(pa.value as int)), 
                'Resource') AS DBNAME
             
           
	FROM sys.dm_exec_query_stats qs
	cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
	outer apply sys.dm_exec_query_plan (qs.plan_handle) qp
	outer APPLY sys.dm_exec_plan_attributes(qs.plan_handle) pa
	where attribute = 'dbid'   
	ORDER BY 
	[Total Physical Reads] DESC
	
end 

if  9 = (select substring(@version, 1, 1))
Begin

---Top 50 high total CPU Queries
SELECT TOP 50
'High CPU Queries' as Type,
serverproperty('machinename')                                        as 'Server Name',                                           
isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
SUBSTRING(qt.text,qs.statement_start_offset/2, 
                  (case when qs.statement_end_offset = -1 
                  then len(convert(nvarchar(max), qt.text)) * 2 
                  else qs.statement_end_offset end -qs.statement_start_offset)/2) 
            as query_text,qp.query_plan,
        qs.execution_count as [Execution Count],
	qs.total_worker_time/1000 as [Total CPU Time],
	(qs.total_worker_time/1000)/qs.execution_count as [Avg CPU Time],
	qs.total_elapsed_time/1000 as [Total Duration],
	(qs.total_elapsed_time/1000)/qs.execution_count as [Avg Duration],
	qs.total_physical_reads as [Total Physical Reads],
	qs.total_physical_reads/qs.execution_count as [Avg Physical Reads],
      qs.total_logical_reads as [Total Logical Reads],
	qs.total_logical_reads/qs.execution_count as [Avg Logical Reads],
        COALESCE(DB_NAME(qt.dbid),
                DB_NAME(CAST(pa.value as int)), 
                'Resource') AS DBNAME
             
           
	FROM sys.dm_exec_query_stats qs
	cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
	outer apply sys.dm_exec_query_plan (qs.plan_handle) qp
	outer APPLY sys.dm_exec_plan_attributes(qs.plan_handle) pa
	where attribute = 'dbid'   
	ORDER BY 
        [Total CPU Time] DESC
        
---Top 50 high total Duration Queries
SELECT TOP 50
'High Duration' as Type,
serverproperty('machinename')                                        as 'Server Name',                                           
isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
SUBSTRING(qt.text,qs.statement_start_offset/2, 
                  (case when qs.statement_end_offset = -1 
                  then len(convert(nvarchar(max), qt.text)) * 2 
                  else qs.statement_end_offset end -qs.statement_start_offset)/2) 
            as query_text,qp.query_plan,
        qs.execution_count as [Execution Count],
	qs.total_worker_time/1000 as [Total CPU Time],
	(qs.total_worker_time/1000)/qs.execution_count as [Avg CPU Time],
	qs.total_elapsed_time/1000 as [Total Duration],
	(qs.total_elapsed_time/1000)/qs.execution_count as [Avg Duration],
	qs.total_physical_reads as [Total Physical Reads],
	qs.total_physical_reads/qs.execution_count as [Avg Physical Reads],
	 qs.total_logical_reads as [Total Logical Reads],
	qs.total_logical_reads/qs.execution_count as [Avg Logical Reads],
      
        COALESCE(DB_NAME(qt.dbid),
                DB_NAME(CAST(pa.value as int)), 
                'Resource') AS DBNAME
             
           
	FROM sys.dm_exec_query_stats qs
	cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
	outer apply sys.dm_exec_query_plan (qs.plan_handle) qp
	outer APPLY sys.dm_exec_plan_attributes(qs.plan_handle) pa
	where attribute = 'dbid'   
	ORDER BY 
        [Total Duration] DESC
        
---Top 50 high total Physical Reads Queries
SELECT TOP 50
'High Physical Reads' as Type,
serverproperty('machinename')                                        as 'Server Name',                                           
isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
SUBSTRING(qt.text,qs.statement_start_offset/2, 
                  (case when qs.statement_end_offset = -1 
                  then len(convert(nvarchar(max), qt.text)) * 2 
                  else qs.statement_end_offset end -qs.statement_start_offset)/2) 
            as query_text,qp.query_plan,
        qs.execution_count as [Execution Count],
	qs.total_worker_time/1000 as [Total CPU Time],
	(qs.total_worker_time/1000)/qs.execution_count as [Avg CPU Time],
	qs.total_elapsed_time/1000 as [Total Duration],
	(qs.total_elapsed_time/1000)/qs.execution_count as [Avg Duration],
	qs.total_physical_reads as [Total Physical Reads],
	qs.total_physical_reads/qs.execution_count as [Avg Physical Reads],
	 qs.total_logical_reads as [Total Logical Reads],
	qs.total_logical_reads/qs.execution_count as [Avg Logical Reads],
      
        COALESCE(DB_NAME(qt.dbid),
                DB_NAME(CAST(pa.value as int)), 
                'Resource') AS DBNAME
             
           
	FROM sys.dm_exec_query_stats qs
	cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
	outer apply sys.dm_exec_query_plan (qs.plan_handle) qp
	outer APPLY sys.dm_exec_plan_attributes(qs.plan_handle) pa
	where attribute = 'dbid'   
	ORDER BY 
	[Total Physical Reads] DESC
END
