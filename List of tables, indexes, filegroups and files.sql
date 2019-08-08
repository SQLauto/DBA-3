---- List of tables, indexes, filegroups & file names
----
---- SQL Server 2005 Performance Tuning with DMVs - T. Davidson

--- This script is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
---
select 'table_name'=object_name(i.id)
		,i.indid
		,'index_name'=i.name
		,i.groupid
		,'filegroup'=f.name
		,'file_name'=d.physical_name
		,'dataspace'=s.name
from	sys.sysindexes i
		,sys.filegroups f
		,sys.database_files d
		,sys.data_spaces s
where objectproperty(i.id,'IsUserTable') = 1
and f.data_space_id = i.groupid
and f.data_space_id = d.data_space_id
and f.data_space_id = s.data_space_id
order by f.name,object_name(i.id),groupid
go
