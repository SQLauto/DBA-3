/*============================================================================
  File:     Spatial Lab - Client 2 - TVP .sql

  Summary:  Scripts for Excercise 2 Scenario 2 of the Spatial Lab

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
Select GeoData.STAsText() from Geo
go
--Create table type to allow us to pass a table of data to a stored procedure
create type GeometryTable as table (GeoKey uniqueidentifier, Geodata Geometry)
go
--Create a procedure that takes a parameter with a data type of the table type just create
--Insert the data passed in into the Geo table
create procedure up_Geo_InsertByTable
  @GeoDataTable GeometryTable READONLY
as

    insert into Geo (GeoKey,GeoData)
    select GeoKey, GeoData
      from @GeoDataTable
go