---- Average stalls per read, write, total.sql

---- SQL Server 2005 Performance Tuning with DMVs - T. Davidson

---- Calculate Average Stalls per Read, Write and Total IO
---- If you do wait, how long do you wait on average?
---- adding 1.0 to avoid division by zero errors
---- The average read or write stall can be used to set sp_configure "blocked process threshold"
----
select  database_id,
        file_id,
        io_stall_read_ms,
        num_of_reads,
        cast(io_stall_read_ms / ( 1.0 + num_of_reads ) as numeric(10, 1)) as 'avg_read_stall_ms',
        io_stall_write_ms,
        num_of_writes,
        cast(io_stall_write_ms / ( 1.0 + num_of_writes ) as numeric(10, 1)) as 'avg_write_stall_ms',
        io_stall_read_ms + io_stall_write_ms as io_stalls,
        num_of_reads + num_of_writes as total_io,
        cast(( io_stall_read_ms + io_stall_write_ms ) / ( 1.0 + num_of_reads
                                                          + num_of_writes ) as numeric(10, 1)) as 'avg_io_stall_ms'
from    sys.dm_io_virtual_file_stats(null, null)
order by avg_io_stall_ms desc
