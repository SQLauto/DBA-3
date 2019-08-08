DROP EVENT SESSION [SQL_PTO_Clinic] ON SERVER
GO

CREATE EVENT SESSION [SQL_PTO_Clinic] ON SERVER 
ADD EVENT sqlserver.additional_memory_grant(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_resource_group_id,sqlserver.session_resource_pool_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username)),
ADD EVENT sqlserver.alwayson_ddl_executed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_resource_group_id,sqlserver.session_resource_pool_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username)),
ADD EVENT sqlserver.attention(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.session_id,sqlserver.session_resource_group_id,sqlserver.session_resource_pool_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username)),
ADD EVENT sqlserver.auto_stats(SET collect_database_name=(1)
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username)),
ADD EVENT sqlserver.bad_memory_detected,
ADD EVENT sqlserver.bad_memory_fixed,
ADD EVENT sqlserver.batch_hash_table_build_bailout(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_resource_group_id,sqlserver.session_resource_pool_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username)),
ADD EVENT sqlserver.blocked_process_report,
ADD EVENT sqlserver.deprecation_announcement(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_resource_group_id,sqlserver.session_resource_pool_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username)),
ADD EVENT sqlserver.deprecation_final_support(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_resource_group_id,sqlserver.session_resource_pool_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username)),
ADD EVENT sqlserver.error_reported(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_resource_group_id,sqlserver.session_resource_pool_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username)
    WHERE ([error_number]<>(5701) AND [error_number]<>(5703))),
ADD EVENT sqlserver.exchange_spill(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_resource_group_id,sqlserver.session_resource_pool_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username)),
ADD EVENT sqlserver.execution_warning(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_resource_group_id,sqlserver.session_resource_pool_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username)),
ADD EVENT sqlserver.hash_warning(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_resource_group_id,sqlserver.session_resource_pool_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username)),
ADD EVENT sqlserver.lock_escalation(SET collect_database_name=(1),collect_statement=(1)
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_resource_group_id,sqlserver.session_resource_pool_id,sqlserver.session_server_principal_name,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username)),
ADD EVENT sqlserver.missing_column_statistics(SET collect_column_list=(1)
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username)),
ADD EVENT sqlserver.missing_join_predicate(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_resource_group_id,sqlserver.session_resource_pool_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username)),
ADD EVENT sqlserver.oledb_error(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_resource_group_id,sqlserver.session_resource_pool_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username)),
ADD EVENT sqlserver.progress_report_online_index_operation(SET collect_database_name=(1)),
ADD EVENT sqlserver.rpc_completed(SET collect_output_parameters=(1)
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_resource_group_id,sqlserver.session_resource_pool_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username)),
ADD EVENT sqlserver.sort_warning(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_resource_group_id,sqlserver.session_resource_pool_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username)),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_resource_group_id,sqlserver.session_resource_pool_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username)),
ADD EVENT sqlserver.xml_deadlock_report 
-- Use below with caution, it can still become a performance hit.
-- http://connect.microsoft.com/SQLServer/feedback/details/732870/sqlserver-query-post-execution-showplan-performance-impact
--,ADD EVENT sqlserver.query_post_execution_showplan(SET collect_database_name=(1)
--    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_resource_group_id,sqlserver.session_resource_pool_id,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.transaction_sequence,sqlserver.tsql_frame,sqlserver.tsql_stack,sqlserver.username))
ADD TARGET package0.event_file(SET filename=N'C:\Temp\SQL_PTO_Clinic.xel',max_file_size=(1024))
WITH (MAX_MEMORY=10240 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)
GO



