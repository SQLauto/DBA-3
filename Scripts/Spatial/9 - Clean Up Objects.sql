USE master;
GO

IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'Spatial')
  DROP DATABASE Spatial;
GO

