/*============================================================================
  File:     DDLTrigger.sql

  Summary:  This script creates an audit table and a DDL trigger to show
			how DDL triggers can prevent accidental data modifications.
			Additionally, this script shows some of the uses of the
			new XML EVENTDATA() function.

  Date:     August 2008

  SQL Server Version: 10.0.2531.0 (SQL Server 2008 SP1)
------------------------------------------------------------------------------
  Written by Kimberly L. Tripp & Paul S. Randal, SQLskills.com

  For more scripts and sample code, check out 
    http://www.SQLskills.com

  This script is intended only as a supplement to demos and lectures
  written/presented by SQLskills.com  
  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

------------------------------------------------------------------------------
-- ** STEP 1 Begin **
------------------------------------------------------------------------------
USE AdventureWorks2008;
GO

--Create a login/user - just for this exercise
CREATE LOGIN Paul WITH PASSWORD = 'PxKoJ29!07';
GO

CREATE USER Paul FOR LOGIN Paul;
GO

sp_addrolemember 'db_ddladmin', 'Paul'
GO
 
CREATE SCHEMA SecurityAdministration
GO

CREATE TABLE SecurityAdministration.AuditDDLOperations
(
            OpID				int				NOT NULL identity     
													CONSTRAINT AuditDDLOperationsPK
														PRIMARY KEY CLUSTERED,
            OriginalLoginName	sysname			NOT NULL,
            LoginName			sysname			NOT NULL,
            UserName			sysname			NOT NULL,
            PostTime			datetime		NOT NULL,
            EventType			nvarchar(100)	NOT NULL,
            DDLOp				nvarchar(2000)  NOT NULL
);
GO

GRANT INSERT ON SecurityAdministration.AuditDDLOperations TO public;
GO

CREATE TRIGGER PreventAllDDL
ON DATABASE
WITH ENCRYPTION
FOR DDL_DATABASE_LEVEL_EVENTS
AS 
DECLARE @data XML
SET @data = EVENTDATA()
RAISERROR ('DDL Operations are prohibited on this production database. Please contact ITOperations for proper policies and change control procedures.', 16, -1)
ROLLBACK
INSERT SecurityAdministration.AuditDDLOperations
                        (OriginalLoginName,
                         LoginName, 
                         UserName,
                         PostTime,
                         EventType,
                         DDLOp)
VALUES   (ORIGINAL_LOGIN(), SYSTEM_USER, CURRENT_USER, GETDATE(), 
   @data.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(100)'), 
   @data.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'nvarchar(2000)') ) 
RETURN;
GO
------------------------------------------------------------------------------
-- ** STEP 1 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** STEP 2 Begin **
------------------------------------------------------------------------------
-- Try to create a table.
CREATE TABLE TestTable (column1 INT);
GO
------------------------------------------------------------------------------
-- ** STEP 2 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** STEP 3 Begin **
------------------------------------------------------------------------------
-- Try to delete the audit table.
DROP TABLE SecurityAdministration.AuditDDLOperations;
GO
------------------------------------------------------------------------------
-- ** STEP 3 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** STEP 4 Begin **
------------------------------------------------------------------------------
EXECUTE AS LOGIN = 'Paul' -- note: Remember, Paul is a DDL_admin
GO

DROP TABLE SecurityAdministration.AuditDDLOperations;
GO

REVERT;
GO
------------------------------------------------------------------------------
-- ** STEP 4 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** STEP 5 Begin **
------------------------------------------------------------------------------
-- Examine the audit table.
SELECT * FROM SecurityAdministration.AuditDDLOperations;
GO
------------------------------------------------------------------------------
-- ** STEP 5 End **
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- ** CLEANUP **
------------------------------------------------------------------------------

DROP TRIGGER PreventAllDDL ON DATABASE;
GO

DROP TABLE SecurityAdministration.AuditDDLOperations;
GO

DROP SCHEMA SecurityAdministration;
GO

DROP USER Paul;
GO

USE master
GO

DROP LOGIN Paul;
GO
------------------------------------------------------------------------------
-- ** CLEANUP End **
------------------------------------------------------------------------------




