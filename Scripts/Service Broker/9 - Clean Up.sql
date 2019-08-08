USE master;
GO

IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'SBroker')
  DROP DATABASE SBroker;
GO

