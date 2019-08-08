

select db_name(mf.database_id) as databaseName, mf.physical_name, 
       num_of_reads, num_of_bytes_read, io_stall_read_ms, num_of_writes, 
       num_of_bytes_written, io_stall_write_ms, io_stall,size_on_disk_bytes,
	   cast(io_stall_read_ms/(1.0+num_of_reads) as numeric(10,1)) as 'avg_read_stall_ms',
	   cast(io_stall_write_ms/(1.0+num_of_writes) as numeric(10,1)) as 'avg_write_stall_ms',
	   cast((io_stall_read_ms+io_stall_write_ms)/(1.0+num_of_reads+num_of_writes) as numeric(10,1)) as 'avg_io_stall_ms'

from sys.dm_io_virtual_file_stats(null,null) as divfs
         join sys.master_files as mf
              on mf.database_id = divfs.database_id
                 and mf.file_id = divfs.file_id

order by avg_io_stall_ms desc







