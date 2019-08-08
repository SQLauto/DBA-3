/*============================================================================
  File:     PaulQueries.sql

  Summary:  Impersonate 'paul' and run some DML queries to be audited

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

-- Pretend to be 'paul'
USE AuditTest;
GO

EXECUTE AS LOGIN = 'paul';
GO

-- Do some things we're allowed to
SELECT * FROM TestTable1;
GO
SELECT * FROM TestTable2;
GO
INSERT INTO TestTable2 VALUES ('Coco', '2005-03-27 00:00:00.000');
GO

-- And try some things we're not allowed to
INSERT INTO TestTable1 VALUES (3,3);
GO
UPDATE TestTable2 SET DateOfBirth = NULL WHERE Name = 'Coco';
GO

-- Stop pretending
REVERT;
GO
