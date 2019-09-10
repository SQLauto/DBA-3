select @@servername, name, state_desc,
recovery_model_desc, log_reuse_wait_desc
 from sys.databases
 where database_id > 4
 order by name

