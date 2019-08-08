create database cdc_test
go

use cdc_test
go


--Enable CDC for the database
EXECUTE sys.sp_cdc_enable_db;
go


CREATE TABLE dbo.Employees
(
	empid  INT         NOT NULL PRIMARY KEY,
	name   VARCHAR(30) NOT NULL,
	salary MONEY       NOT NULL
);


EXEC sys.sp_cdc_enable_table
	@source_schema = N'dbo',
	@source_name = N'Employees',
	--role used to protect access to the data
	--can be set to NULL
	@role_name = N'cdc_Admin';
GO


--to get data we need a starting LSN, so grab one
select sys.fn_cdc_map_time_to_lsn('largest less than or equal', getdate())
--0x00000020000001F20001


--make some changes
INSERT INTO dbo.Employees(empid, name, salary) 
VALUES(1, 'Emp1', 1000.00);
go

INSERT INTO dbo.Employees(empid, name, salary) 
VALUES(2, 'Emp2', 1400.00);
go

UPDATE Employees
SET salary = 2200.00
WHERE empid = 1
go

DELETE Employees
WHERE empid = 1
go


--ending LSN?
select sys.fn_cdc_map_time_to_lsn('largest less than or equal', getdate())
--0x00000020000001F20001
go


--Now we can get the changes
select * 
from cdc.fn_cdc_get_all_changes_dbo_Employees
(
	--starting LSN
	0x00000020000001F20001, 
	--ending LSN
	0x00000021000000150004, 
	--Show both old and new data
	'all update old'
)
go


--Now we can get the changes
select * 
from cdc.fn_cdc_get_all_changes_dbo_Employees
(
	--starting LSN
	0x00000020000001F20001, 
	--ending LSN
	0x00000021000000150004, 
	--Show both old and new data
	'all update old'
)
go


--Get net changes
select * 
from cdc.fn_cdc_get_net_changes_dbo_Employees
(
	--starting LSN
	0x00000020000001F20001, 
	--ending LSN
	0x00000021000000150004, 
	--Show both old and new data
	'all'
)
go




--Change the retention time?
EXEC sys.sp_cdc_change_job
	--which job to change?
	@job_type = 'cleanup',
	--retention time, in seconds
	@retention = 52494800;
GO



--Monitor the scans?
select * 
from sys.dm_cdc_log_scan_sessions



--tricky scenario to keep in mind
ALTER TABLE Employees 
ADD Department VARCHAR(50)
GO


UPDATE Employees 
SET Department = 'IT'
GO


select * 
from cdc.fn_cdc_get_all_changes_dbo_Employees
(
	--starting LSN
	sys.fn_cdc_map_time_to_lsn('smallest greater than or equal', getdate()-1), 
	--ending LSN
	sys.fn_cdc_map_time_to_lsn('largest less than or equal', getdate()), 
	--Show both old and new data
	'all update old'
)
go


--solution

--First save off the current data
select *
into #old_emp_data
from cdc.dbo_employees_ct
go


--Now grab the starting LSN from the cdc.change_tables view
SELECT start_lsn
FROM cdc.change_tables
WHERE 
	capture_instance = 'dbo_Employees'
--0x000000190000014A0039
go


--Now stop and restart CDC on the table
EXEC sys.sp_cdc_disable_table
	@source_schema = N'dbo',
	@source_name = N'Employees',
	@capture_instance = 'dbo_Employees';
GO

EXEC sys.sp_cdc_enable_table
	@source_schema = N'dbo',
	@source_name = N'Employees',
	@role_name = N'cdc_Admin';
GO


--Now re-insert the saved data
INSERT cdc.dbo_Employees_CT
(
	__$start_lsn,
	__$end_lsn,
	__$seqval,
	__$operation,
	__$update_mask,
	empid,
	name,
	salary
)
SELECT *
FROM #old_emp_data
GO


--Now update the start_lsn to the old one we captured
UPDATE cdc.change_tables
SET start_lsn = 0x000000190000014A0039
WHERE capture_instance = 'dbo_Employees';
GO


--Re-run this update to see if it worked
UPDATE Employees 
SET Department = 'IT_2'
GO


--Now we have a full change history!
select * 
from cdc.fn_cdc_get_all_changes_dbo_Employees
(
	--starting LSN
	sys.fn_cdc_map_time_to_lsn('smallest greater than or equal', getdate()-1), 
	--ending LSN
	sys.fn_cdc_map_time_to_lsn('largest less than or equal', getdate()), 
	--Show both old and new data
	'all'
)
go






--Clean up
EXECUTE sys.sp_cdc_disable_db;
go
use master
go
drop database cdc_test
go
