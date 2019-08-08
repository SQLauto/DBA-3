/*============================================================================
  File:     LogClearing2.sql

  Summary:  This script helps with the log
			clearing demo

  Date:     June 2009

  SQL Server Versions:
		10.0.2531.00 (SS2008 SP1)
		9.00.4035.00 (SS2005 SP3)
------------------------------------------------------------------------------
  Written by Paul S. Randal, SQLskills.com

  For more scripts and sample code, check out 
    http://www.SQLskills.com

  You may alter this code for your own *non-commercial* purposes. You may
  republish altered code as long as you give due credit.
  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

USE master;
GO

SET NOCOUNT ON;
GO

-- Start the long-running transaction
BEGIN TRAN;
GO

INSERT INTO DBMaint2008..BigTable DEFAULT VALUES;
GO 1000

-- Now switch-back...

COMMIT TRAN;
GO

