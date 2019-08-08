/*============================================================================
  File:     Spatial Lab - TSQL 2 - Properties and Methods.sql

  Summary:  Scripts for Excercise 1 Scenario 2 of the Spatial Lab

  Date:     January 2008

  SQL Server Version 2008 (RTM)
------------------------------------------------------------------------------
  Written By Simon Sabin, SYSolutions, Inc.
  http://www.sqlskills.com/blogs/simon

  All rights reserved.

  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/
go
use SpatialLab
go
/*###################################################################################
  
   In the previous excercise we looked at creating geometry variables in this exercise 
   we will look at the properties and methods of the geometry and geograhy types
  
   Most of the methods are from the OpenGIS standard. 

#####################################################################################*/
--
-- STAsText(), ToString() - What is the text presetnation of the geometry 
--  
-- These both return the WKT representation of the geometry
--
-------------------------------------------------------------------------------------

declare @p geometry = geometry::STGeomFromWKB(0x010100000000000000000024400000000000002440,0);
select  @p.ToString(), @p.STAsText();

--This will return POINT (10 10)
go
--If you want the Z and M values then you will need to use the AsTextZM() method
--The points of a geometry are readonly and so you the only way to set them is at creation time. This includes the 
--Z and M values. set @p.Z = 99 is not valid

declare @p geometry = 'POINT(10 10 100 999)'
select  @p.ToString(), @p.STAsText(), @p.AsTextZM(), @p.Z

go
--###########################################################################################################################
--
-- STAsBinary() - What is the binary representation of the geometry
--
-- This is NOT the value returned if you include a Geometry or Geography value in a select without using a method
------------------------------------------------------------------------------------------------------------------------
--
declare @glasses geometry = 'GEOMETRYCOLLECTION(LINESTRING(0 20,5 10),POLYGON((5 5,5 15,10 20,20 20,25 15,25 5,20 0,10 0,5 5)),POLYGON((35 5,35 15,40 20,50 20,55 15,55 5,50 0,40 0,35 5)),LINESTRING(55 10,60 20),LINESTRING(25 15,35 15))' 

select @glasses.STAsBinary() BinaryValue, @glasses DefaultValue

--You will see that that the value in the first column is different to that in the second.
go

--###########################################################################################################################
--
-- STX, STY, Long and Lat - What is the point ?
--
-- These properties return the X and Y for a point geometry, they only return a value when
-- the geometry is a POINT gemetry for all other geometries they return null. 
-- Long and Lat return the same values for the Geography type. Again it only returns a value
-- if the sub type is POINT
----------------------------------------------------------------------------------------------------------------------------

declare @geog geography = 'Point (100 50)'
declare @geom geometry = 'Point (10 30)'

select @geog.Long Long, @geog.Lat Lat
     , @geom.STX STX, @geom.STY STY


go
--###########################################################################################################################
--
-- STDimension() - What is the dimensionality of the geometry.
--
-- This is very useful when understanding how the relationship methods work. It returns the 
-- maximum dimension of the geometry
----------------------------------------------------------------------------------------------------------------------------

declare @point geometry = 'POINT (10 10 1 99)' 
declare @line geometry = 'LINESTRING (0 0, 10 10)'
declare @polygon geometry = 'POLYGON ((0 0, 10 10,10 0, 0 0))'

--Whilst this geometry has lines and polygons the maximum dimension is 2, that of a polygon
declare @glasses geometry = 'GEOMETRYCOLLECTION(LINESTRING(0 20,5 10),POLYGON((5 5,5 15,10 20,20 20,25 15,25 5,20 0,10 0,5 5)),POLYGON((35 5,35 15,40 20,50 20,55 15,55 5,50 0,40 0,35 5)),LINESTRING(55 10,60 20),LINESTRING(25 15,35 15))' 

select  @point.STDimension() PointDimension
       ,@line.STDimension() LineDimension
       ,@polygon.STDimension() PolygonDimension
       ,@glasses.STDimension() GlassesDimension
go

--###########################################################################################################################
--
-- STLength() - How long is your geometry
--
------------------------------------------------------------------------------------------------------------------------
--
declare @line geometry = 'LINESTRING (0 0,0 10)'

select @line.STLength() LineLength
go

--Its fairly easy to calculate the length of a line for a geometry. However for a Geogrpahy type its more diffifult because 
--of the curve of the earth.

--Create a line half from pole to the pole
/*
--This fails because you cannot have spatial instance that spans both hemispheres. This is a restriction you have to live with.
*/
declare @PoleToPole geography = 'LINESTRING (0 90,0 -90)'

print @PoleToPole.STLength()

go
declare @EquatorToPole geography = Geography::STGeomFromText('LINESTRING (0 90,0 0)',4326)

select @EquatorToPole.STLength() EquatorToPoleDistance

--result should be 10001965.6701831 which is ~10,000,000 metres = 10,000 Kms. The cirumference of the earth is ~40,000Kms therefore
--from pole to the equator is the 1/4 the circumference
go

--###########################################################################################################################
--
-- STArea() - How big is the surface or your geometry
--
-- This will return 0 for any shape with a dimension less than 2, i.e. a point and a line
--
-- A MULTIPOLYGON is invalid if contain overlapping shapes, when made valid it will be converted to one or more POLYGONs
-- using the same rules for STSymDifference, i.e. the intersecting area is removed
------------------------------------------------------------------------------------------------------------------------

declare @point geometry = 'POINT (10 10 1 99)' 
declare @line geometry = 'LINESTRING (0 0, 10 10)'
declare @polygon geometry = 'POLYGON ((0 0, 10 10,10 0, 0 0))'
declare @MultiPolygon geometry = 'MULTIPOLYGON (((0 0, 10 10,10 0, 0 0)),((0 0, 10 10,10 0, 0 0)))'
declare @MultiPolygonGeomCol geometry = 'GEOMETRYCOLLECTION(POLYGON ((0 0, 10 10,10 0, 0 0)),POLYGON((0 0, 10 10,10 0, 0 0)))'
declare @glasses geometry = 'GEOMETRYCOLLECTION(LINESTRING(0 20,5 10),POLYGON((5 5,5 15,10 20,20 20,25 15,25 5,20 0,10 0,5 5)),POLYGON((35 5,35 15,40 20,50 20,55 15,55 5,50 0,40 0,35 5)),LINESTRING(55 10,60 20),LINESTRING(25 15,35 15))' 

set @MultiPolygon = @MultiPolygon.MakeValid();
print @MultiPolygon.ToString();

select  @point.STArea() PointArea
       ,@line.STArea() LineArea
       ,@polygon.STArea() PolygonArea
       ,@glasses.STArea() GlassesArea
       ,@MultiPolygon.STArea() MultiPolygonArea
       ,@MultiPolygonGeomCol.STArea() MultiPolygonGeomArea

--Note that as the the MULTIPOLYGON contains two shapes with the same point sets the resultant geometry is empty because when 
--the intersection of the two shapes is the removed there is no shape left and thus the area = 0
go
--###########################################################################################################################
--
-- STNumPoints(), STPointN(), STNumGeometries(), STGeometryN(), STExteriorLine(), 
-- STNumInteriorRing(), STInteriorRingN()
--
--
-- These are the methods that return the information about a shape. 

--Each geometry has a set of points.
declare @square geometry = 'LINESTRING(0 0, 10 0 , 10 10,0 10,0 0)'

select @square.STPointN(id+1).ToString()
from num
where id < @square.STNumPoints()
go

--Use the STGeometry and STNumGeometries if the geometry has more than geometry
declare @square geometry = 'MULTILINESTRING((0 0, 10 0 , 10 10,0 10,0 0),(2 2, 2 6, 6 6,6 2, 2 2), (1 1, 2 1 ,2 2,1 2, 1 1),(3 3, 4 3, 3 4, 3 3))'

select @square.STGeometryN(id+1).ToString()
from num
where id < @square.STNumGeometries()
go
--Use the STExteriorRing and STInteriorRing if the a polygon has more than one ring.
--If you just used the points and plotted them it would be as though you hadn't taken the
--pen off the paper. Each ring is disconnected from the others (Rings cannot overlap)

declare @eight geometry = 'POLYGON((0 0, 10 0 , 10 10,0 10,0 0),(2 2, 2 4, 8 4,8 2, 2 2),(2 6,2 9, 8 9,8 6, 2 6 ))'

select 'Ext',@eight.STExteriorRing().ToString()
union 
select 'Int', @eight.STInteriorRingN(id+1).ToString()
from num
where id < @eight.STNumInteriorRing()
go

