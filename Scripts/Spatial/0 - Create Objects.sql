USE master;
GO

IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'Spatial')
  DROP DATABASE Spatial;
GO

RESTORE DATABASE Spatial FROM DISK = 'C:\VPC Shared Data\Demos 2008\Spatial\SpatialDB.bak'
  WITH MOVE 'Spatial' TO 'C:\SQLData\Spatial.mdf',
       MOVE 'Spatial_log' TO 'C:\SQLData\Spatial.ldf';
GO