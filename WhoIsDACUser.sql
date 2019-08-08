select t2.session_id as SPID, login_name as 'Login Name', "host_name" as 'Host Name'
from sys.tcp_endpoints as t1 JOIN sys.dm_exec_sessions as t2
ON t1.endpoint_id = t2.endpoint_id
Where t1.name='Dedicated Admin Connection'
