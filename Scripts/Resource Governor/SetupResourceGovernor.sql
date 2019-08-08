/*============================================================================
  File:     SetupResourceGovernor.sql

  Summary:  Setup a couple of resource pools and workload groups to show
				throttling in action

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

USE master;
GO

-- Examine the current configuration
SELECT * FROM sys.dm_resource_governor_configuration;
GO

-- Define two resource pools, one with 10% CPU max, and the
-- other with 90%
CREATE RESOURCE POOL MarketingPool
WITH (MAX_CPU_PERCENT = 10);
GO

CREATE RESOURCE POOL DevelopmentPool
WITH (MAX_CPU_PERCENT = 90);
GO

-- Look at our configuration
SELECT * FROM sys.dm_resource_governor_resource_pools;
GO

-- Need to reconfigure
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO
SELECT * FROM sys.dm_resource_governor_resource_pools;
GO

-- Add two workload groups which make use of the two
-- defined resource pools
CREATE WORKLOAD GROUP MarketingGroup
USING MarketingPool;
GO

CREATE WORKLOAD GROUP DevelopmentGroup
USING DevelopmentPool;
GO

-- Look at our configuration
SELECT * FROM sys.dm_resource_governor_workload_groups;
GO

-- Need to reconfigure again
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO
SELECT * FROM sys.dm_resource_governor_workload_groups;
GO

-- Create some dummy databases. The classifier function will
-- use the database name in the connection string to decide
-- which group to put the connection in.
IF DB_ID ('MarketingDB') IS NULL
	CREATE DATABASE MarketingDB;
GO
IF DB_ID ('DevelopmentDB') IS NULL
	CREATE DATABASE DevelopmentDB;
GO

-- Define a simple classifier function
IF OBJECT_ID ('dbo.MyClassifier') IS NOT NULL
	DROP FUNCTION dbo.MyClassifier;
GO

CREATE FUNCTION dbo.MyClassifier ()
RETURNS SYSNAME WITH SCHEMABINDING
AS
BEGIN
	DECLARE @GroupName SYSNAME;
	IF ORIGINAL_DB_NAME () = 'MarketingDB'
		SET @GroupName = 'MarketingGroup';
	ELSE IF  ORIGINAL_DB_NAME () = 'DevelopmentDB'
		SET @GroupName = 'DevelopmentGroup';
	ELSE SET @GroupName = 'Default';
	RETURN @GroupName;
END;
GO

-- Register the classifier function. This enables the
-- resource governor
ALTER RESOURCE GOVERNOR
	WITH (CLASSIFIER_FUNCTION = dbo.MyClassifier);
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

-- Look at our configuration again
SELECT * FROM sys.dm_resource_governor_configuration;
GO

-- Now open System Monitor, Action | New Window From Here.
-- Add the SQLDEV01 Resource Pools counters for Marketing
-- and Development

-- Open 4 Command Prompt windows
-- In each windows, change directory to:
--   C:\Metro Demos\Troubleshooting Demos\Troubleshooting Demos
-- In the first two windows:
--   sqlcmd /E /S.\SQLDEV01 /dMarketingDB /iRunQueries.sql
-- and
--   sqlcmd /E /S.\SQLDEV01 /dMarketingDB /iRunQueries2.sql
-- Watch the System Monitor graph go to 100%
-- In the second two windows:
--   sqlcmd /E /S.\SQLDEV01 /dDevelopmentDB /iRunQueries.sql
-- and
--   sqlcmd /E /S.\SQLDEV01 /dDevelopmentDB /iRunQueries2.sql
-- Watch the graph switch over.
