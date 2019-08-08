/*============================================================================
  File:     AllActionsAudited.sql

  Summary:  Setup and invesigate a SQL Server Audit

  Date:     August 2008

  SQL Server Version: 10.0.2531.0 (SQL Server 2008 SP1)
------------------------------------------------------------------------------
  Written by Kimberly L. Tripp & Paul S. Randal, SQLskills.com

  For more scripts and sample code, check out http://www.SQLskills.com

  This script is intended as a supplement to the SQL Server 2008 Jumpstart or
  Metro training.
  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

-- Create a test database
USE master;
GO

CREATE DATABASE AuditTest;
GO

USE AuditTest;
GO

-- Create some test tables and insert some data
CREATE TABLE TestTable1 (c1 INT, c2 INT);
CREATE TABLE TestTable2 (Name VARCHAR (10), DateOfBirth SMALLDATETIME);
GO

INSERT INTO TestTable1 VALUES (1, 1);
INSERT INTO TestTable1 VALUES (2, 2);
INSERT INTO TestTable2 VALUES ('Katelyn', '2000-03-05 00:00:00.000');
INSERT INTO TestTable2 VALUES ('Kiera', '2001-09-27 00:00:00.000');
GO

-- Create a user, with SELECT but not INSERT privileges on one table, and
-- both privileges on the second table
CREATE LOGIN paul WITH PASSWORD = 'randal',
DEFAULT_DATABASE = AuditTest;
GO

CREATE USER paul FOR LOGIN paul;
GO

GRANT SELECT ON TestTable1 TO paul;
GO

GRANT SELECT ON TestTable2 TO paul;
GRANT INSERT ON TestTable2 TO paul;
GO

-- Create the audit and audit specification
USE master;
GO

CREATE SERVER AUDIT ExampleAudit TO FILE
(FILEPATH = 'C:\Metro Demos\Security Demos\',
 MAXSIZE = 2MB,
 RESERVE_DISK_SPACE = ON) -- Ensure we don't run out of space
WITH (ON_FAILURE = SHUTDOWN);
GO

CREATE SERVER AUDIT SPECIFICATION ExampleServerAuditSpec
FOR SERVER AUDIT ExampleAudit ADD
(SERVER_PRINCIPAL_IMPERSONATION_GROUP)
WITH (STATE = ON);

USE AuditTest;
GO

CREATE DATABASE AUDIT SPECIFICATION ExampleDBAuditSpec
FOR SERVER AUDIT ExampleAudit
ADD (SELECT, INSERT, UPDATE ON TestTable1 BY paul),
ADD (SELECT, INSERT, UPDATE ON TestTable2 BY paul)
WITH (STATE = ON);
GO

-- Turn the audit on
USE master;
GO

ALTER SERVER AUDIT ExampleAudit WITH (STATE = ON);
GO

-- Do some DML as paul

-- Determine the active audits
SELECT * FROM sys.dm_server_audit_status;
GO

-- Look in our audit file
SELECT AuditFile.* FROM sys.dm_server_audit_status AS AuditStatus
CROSS APPLY sys.fn_get_audit_file (
	AuditStatus.audit_file_path, default, default) AS AuditFile
WHERE AuditStatus.name = 'ExampleAudit';
GO

-- Let's change the audit specification to go to the
-- application event log
ALTER SERVER AUDIT ExampleAudit TO APPLICATION_LOG;
GO

-- ok, disable, alter, re-enable
ALTER SERVER AUDIT ExampleAudit WITH (STATE = OFF);
ALTER SERVER AUDIT ExampleAudit TO APPLICATION_LOG;
ALTER SERVER AUDIT ExampleAudit WITH (STATE = ON);
GO

-- Let's try some more stuff...

-- Can we use the fn_get_audit_file function again?
SELECT * FROM sys.dm_server_audit_status;
GO

SELECT AuditFile.* FROM sys.dm_server_audit_status AS AuditStatus
CROSS APPLY sys.fn_get_audit_file (
	AuditStatus.audit_file_path, default, default) AS AuditFile
WHERE AuditStatus.name = 'ExampleAudit';
GO

-- No, look in the application log