/*============================================================================
  File:     Spatial Lab - Client 1 - Create Table.sql

  Summary:  Scripts for Excercise 2 Scenario 1 of the Spatial Lab

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
if object_id('Geo') is not null 
  drop table Geo
go
create table Geo(GeoKey uniqueidentifier not null, GeoData geometry)
go
--alter table Geo add constraint PK_Geo_GeoKey primary key (GeoKey)
go
create procedure up_Geo_InsertFromText
  @GeoKey  uniqueidentifier
 ,@GeoData varchar(max)
as
    insert into Geo (GeoKey,GeoData)
    values (@GeoKey,Geometry::STGeomFromText(@GeoData,0))
go
create procedure up_Geo_InsertFromWKB
  @GeoKey  uniqueidentifier
 ,@GeoData varbinary(max)
as

    insert into Geo (GeoKey,GeoData)
    values (@GeoKey,Geometry::STGeomFromWKB(@GeoData,0))
go
create procedure up_Geo_Insert
  @GeoKey  uniqueidentifier
 ,@GeoData Geometry
as

    insert into Geo (GeoKey,GeoData)
    values (@GeoKey,@GeoData)
go
