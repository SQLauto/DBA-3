/*============================================================================
  File:     Spatial Lab - Client 3 - Create Index.sql

  Summary:  Scripts for Excercise 2 Scenario 3 of the Spatial Lab

  Date:     August 2008

  SQL Server Version: 10.0.2531.0 (SQL Server 2008 SP1)
------------------------------------------------------------------------------
  Written By Simon Sabin, SYSolutions, Inc.
  http://www.sqlskills.com/blogs/Simon

  All rights reserved.

  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/
go
use SpatialLab
go
alter table Geo add constraint pk_Geo primary key (GeoKey)
go
create spatial index IXS_Geo_GeoData on dbo.Geo (GeoData )
using GEOMETRY_GRID 
with (BOUNDING_BOX =(0, 0, 20000, 20000))
go
create procedure up_SelectGeometries 
(
  @selection geometry = null, 
  @method varchar(20) = null
)
as

  declare @sql nvarchar(max)

  set @sql = 'select GeoKey, GeoData from dbo.Geo where GeoData.' + @method + '(@selection)=1'
 
  exec sp_executesql @sql, N'@selection geometry',@selection
go

go
