/*============================================================================
  File:     Spatial Lab - TSQL 1 - CreatingData.sql

  Summary:  Scripts for Excercise 1 Scenario 1 of the Spatial Lab

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

/*###################################################################################
   Create a database for our lab
#####################################################################################*/

if not exists (select 1 from sys.databases where name = 'SpatialLab')
    create database SpatialLab
go
use SpatialLab
go

/*-----------------------------------------------------------------------------------

   Geometry and Geography are very similar, they share many of the same methods and 
   behave in a similar fashion. The difference is that the Geometry type is for use 
   with flat surfaces and the Geography type is for modelling a sperical surface, 
   i.e. the earth. We will generally focus on the geometry type and specify when the 
   geography methods differ
   
   It is possible to use the Geometry to map shapes on the earth if the shapes aren't
   too large otherwise the curve of the earth will have an impact on your calculations.
   For instance many maps are divided into grids providing locations as grid 
   references (x and y) rather than longitude and latitude.
  
   Both Geometry and Geography are for dealing with up to 2 dimensions. Whilst the 
   shapes support holding information about the 2 additional dimensions these are 
   not used in any calculations, they just provide additional information about the 
   spatial instance. 

------------------------------------------------------------------------------------- */

--As with all data types you can instantiate them as variables. 

declare @myGeographyVariable geography

declare @myGeometryVariable geometry

go
---------------------------------------------------------------------------------------------------------------------------
-- Note:
-- You do not have to have the database in SQL 2008 compatibility mode
go
exec sp_dbcmptlevel 'SpatialLab', 80
go
--running this set of statements will work as before
go
declare @myGeographyVariable geography

declare @myGeometryVariable geometry
go
exec sp_dbcmptlevel 'SpatialLab', 100
go
-------------------------------------------------------------------------------------
go
/*###################################################################################
   Creating an instance
  
   Point
*/

declare @p geometry;

set @p = geometry::Point(10,10,0);
print @p.ToString();
set @p = geometry::STGeomFromText('POINT(10 10)',0);
print @p.ToString();
set @p = geometry::STPointFromText('POINT(10 10)',0);
print @p.ToString();
set @p = geometry::STGeomFromWKB(0x010100000000000000000024400000000000002440,0);
print @p.ToString();
set @p = geometry::STPointFromWKB(0x010100000000000000000024400000000000002440,0);
print @p.ToString();
set @p = geometry::GeomFromGml('<Point xmlns="http://www.opengis.net/gml"><pos>10 10</pos></Point>',0);
print @p.ToString();
set @p = geometry::Parse('POINT(10 10)');
print @p.ToString();
set @p = 'POINT(10 10)';
print @p.ToString();

go
--Only the point subtype has its own method that takes simple parameters. All the other subtypes 
--you have to use the STGeom... or STShape... methods.

-- Some of the about methods can be extended to store the additional values of the additional 2 dimensions mentioned above
-- Only the text and GML methods support this extension
--
-- The additional 2 values are specified after the x and y values 
declare @p geometry
set @p = 'POINT(10 10 100 99)';
--print value and visualize
select @p.ToString(), @p


---------------------------------------------------------------------------------------------------------------------------
--Note:
--For a CLR type you can call methods on a type without needing to instantiate an instance of that 
--type. The notation for doing this is <type>::<method> In the above example we are calling the 
--methods of the geometry type directly to create instances of the geometry type.
--
--These methods are not declared in SQL Server directly but are derived by SQL Server on making the call.
--Because SQL is directly accessing the CLR methods they are case sensitive. This is unlike normal CLR 
--functions which are exposed in TSQL by using a TSQL wrapper function. This wrapper removes the case 
--sensitive limitation.

go
/*###################################################################################
  Well Known Binary format WKB
  
  The WKB Format is binary representation of the geometry you are creating. Some 
  bytes are used to identify what type of geometry it is and then others used to
  define the points for the geometry. Where a geometry consists of multiple 
  geometries there are additional bytes used to define how many geometries there 
  are.

  There is also a byte used to define how the binary values are represented, 
  i.e whether 1 is 0x01000000 or 0x00000001

This is the structure of each WKB, you will see they all share the same common mechanism, [byte order][shape type]{[x][y]...}

Point = [Byte order][Type][X value][Y value] 
MultiPoint = [Byte order][Type][PointCount]<Point1><Point2>
Line = [Byte order][Type][PointCount][X Value][YValue][X value][Y value].....
MultiLine = [Byte order][Type][LineCount]<Line1><Line2> .....
Polygon = [Byte order][Type][Polygon Count][PointCount][X Value][YValue][X value][Y value].....
MultiPolygon = [Byte order][Type][Polygon Count]<Polygon1><Polygon2>....
Geometry Collection = [Byte order][Type][Shape Count]<Shape1><Shape2>.....

The types are as follows 
   GeometryCollection = 7,
    LineString = 2,
    MultiLineString = 5,
    MultiPoint = 4,
    MultiPolygon = 6,
    Point = 1,
    Polygon = 3,
    Unknown = 0

For example this will create a 4x4 polygon with a 2x2 hole in it
*/

--                                              AABBBBBBBBCCCCCCCCDDDDDDDDX1X1X1X1X1X1X1X1Y1Y1Y1Y1Y1Y1Y1Y1X2X2X2X2X2X2X2X2Y2Y2Y2Y2Y2Y2Y2Y2X3X3X3X3X3X3X3X3Y3Y3Y3Y3Y3Y3Y3Y3X4X4X4X4X4X4X4X4Y4Y4Y4Y4Y4Y4Y4Y4X5X5X5X5X5X5X5X5Y5Y5Y5Y5Y5Y5Y5Y5DDDDDDDDX1....
declare @p geometry = geometry::STGeomFromWKB(0x000000000300000002000000050000000000000000000000000000000000000000000000004010000000000000401000000000000040100000000000004010000000000000000000000000000000000000000000000000000000000000000000053FF00000000000003FF00000000000003FF000000000000040080000000000004008000000000000400800000000000040080000000000003FF00000000000003FF00000000000003FF0000000000000,0)

--visualize
select @p.ToString(), @p

/*
  A is the byte order
  B is the Shape type, in this case 3 i.e. a polygon
  C is the number of sub shapes, in this case 2, the outer and the inner squares
  D is the number of points in the first shape, in this case 5 (for a polygon the last point has to be the same as the first
  X1 and Y1 and the X and Y for the first point, X2 and Y2 the second etc.
  Once 5 points have been defined you will note that DDDD is repeated indicating the number of points in the second polygon.
*/
go
--Whilst this is totally unreadable, not many people can convert between 8 byte values and floats in their head, the WKB format 
--is easy to create using variables.
--
--If we take our x and y values and create variables we can make the code much more easier to understand

declare @i int = cast(cast(1 as binary(8)) as int)

declare @OuterX1 float = 0, @OuterY1 float = 0
declare @OuterX2 float = 4, @OuterY2 float = 0
declare @OuterX3 float = 4, @OuterY3 float = 4
declare @OuterX4 float = 0, @OuterY4 float = 4
declare @OuterX5 float = 0, @OuterY5 float = 0

declare @InnerX1 float = 1, @InnerY1 float = 1
declare @InnerX2 float = 3, @InnerY2 float = 1
declare @InnerX3 float = 3, @InnerY3 float = 3
declare @InnerX4 float = 1, @InnerY4 float = 3
declare @InnerX5 float = 1, @InnerY5 float = 1

declare @p geometry 

--
set @p = geometry::STGeomFromWKB(  0x000000000300000002
                                 + 0x00000005 
                                 + cast(@OuterX1 as binary(8)) + cast(@OuterY1 as binary(8)) 
                                 + cast(@OuterX2 as binary(8)) + cast(@OuterY2 as binary(8)) 
                                 + cast(@OuterX3 as binary(8)) + cast(@OuterY3 as binary(8)) 
                                 + cast(@OuterX4 as binary(8)) + cast(@OuterY4 as binary(8)) 
                                 + cast(@OuterX5 as binary(8)) + cast(@OuterY5 as binary(8)) 
                                 + 0x00000005 
                                 + cast(@InnerX1 as binary(8)) + cast(@InnerY1 as binary(8)) 
                                 + cast(@InnerX2 as binary(8)) + cast(@InnerY2 as binary(8)) 
                                 + cast(@InnerX3 as binary(8)) + cast(@InnerY3 as binary(8)) 
                                 + cast(@InnerX4 as binary(8)) + cast(@InnerY4 as binary(8)) 
                                 + cast(@InnerX5 as binary(8)) + cast(@InnerY5 as binary(8)),0)
--print value and visualize
select @p.ToString(), @p
go

/*###################################################################################

  The Well Known Text (WKT)
  
  The WKT format is much easier to read but much more difficult to create as you have
  to create strings.
  
  The following are the points to note about the creating geometries in WKT
  
  1. The prefix for a geometry is one of the following, POINT, MULTIPOINT, LINESTRING
     , MULTILINESTRING, POLYGON, MULTIPOLYGON, GEOMETRYCOLLECTION
  2. The prefix is NOT case sensitive
  3. A point (x and y) are represented by two numbers seperated by whitespace
  4. The X and Y value represent the longitude and latitude for geography instances
  5. Z and M can be specified after the x and y values.
  6. Z and M can be NULL but x and y cannot be
  7. Points are seperated by commas
  8. A set or points are wrapped in brackets
  9. When a geometry consists of multi point sets the point sets are wrapped in 
     brackets and seperated by commas this is the case for the Polygon,Multi... and 
     GeometryCollection types
  
  The following methods are using the parse method which results in an SRID of 0 (for 
  geography types the default SRID is 4326).
*/

declare @point geometry = 'POINT(10 1)'
select @point;
go
declare @line geometry = 'LINESTRING( 2 3, 6 4)'
select @line
go
declare @square geometry = 'POLYGON((0 0,10 0,10 10,0 10,0 0))'
select @square
go
declare @donught geometry = 'POLYGON((0 0,10 0,10 10,0 10,0 0),(4 4,4 6,6 6,6 4,4 4))'
select @donught
go


-- Note: that with a polygon can have a number of sets of points. The first set defines the outer ring of the polygon. 
-- Subsequent shapes remove from or add to the inside of the polygon. This susequent shapes must reside inside the first polygon
-- In the shape above a 2x2 square is removed from the inside of a 10x10 square.

declare @vs geometry = 'MULTILINESTRING((0 10,5 0,10 10),(20 10,25 0,30 10))'
select @vs 
go
declare @rockets geometry = 'MULTIPOLYGON(((0 0,5 10, 5 30, 15 40, 25 30, 25 10, 30 0, 20 0, 15 5, 10 0, 0 0)),((40 0,45 10, 45 30, 55 40, 65 30, 65 10, 70 0, 60 0, 55 5, 50 0, 40 0)))'
select @rockets
go
declare @glasses geometry = 'GEOMETRYCOLLECTION(LINESTRING(0 20,5 10),POLYGON((5 5,5 15,10 20,20 20,25 15,25 5,20 0,10 0,5 5)),POLYGON((35 5,35 15,40 20,50 20,55 15,55 5,50 0,40 0,35 5)),LINESTRING(55 10,60 20),LINESTRING(25 15,35 15))' 
select @glasses
go

-- Display multiple geometries
declare @vs geometry = 'MULTILINESTRING((0 10,5 0,10 10),(20 10,25 0,30 10))'
declare @rockets geometry = 'MULTIPOLYGON(((0 0,5 10, 5 30, 15 40, 25 30, 25 10, 30 0, 20 0, 15 5, 10 0, 0 0)),((40 0,45 10, 45 30, 55 40, 65 30, 65 10, 70 0, 60 0, 55 5, 50 0, 40 0)))'
declare @glasses geometry = 'GEOMETRYCOLLECTION(LINESTRING(0 20,5 10),POLYGON((5 5,5 15,10 20,20 20,25 15,25 5,20 0,10 0,5 5)),POLYGON((35 5,35 15,40 20,50 20,55 15,55 5,50 0,40 0,35 5)),LINESTRING(55 10,60 20),LINESTRING(25 15,35 15))' 

select @vs union all select @rockets union all select @glasses
go

/*###################################################################################

  We will stick with the WKT format as this is easily readable and can be used for 
  all geometry shapes.

#####################################################################################*/

go
/*###################################################################################

   Valid Instances
  
   It is possible to specifiy a set of points that to visual inspection look like 
   a valid shape. However there are a set of rules that are imposed that define how
   points should be ordered, and shapes combined in order for a shape to be valid.
  
   Thankfully most if not all shapes that look correct visually but are not valid 
   according to the rules can be converted into a geometry that is valid. This is 
   achieved using the MakeValid() method.
  
   It is important to understand this, especially when dealing with user input as 
   often user input of complex shapes can result in invalid shapes.
  
   Most of the useful methods on the shape do not work if the shape is not valid.
  
   You may also encounter invalid shapes if you have your points in the wrong order
  
######################################################################################*/

/*
  It is easy to create an invalid shape. If we create a polygon that represents an 
  hour glass (if not very round). The key aspect is that the exterior line of the 
  polygon crosses itself which is invalid. This is easily created by flipping the 
  points of a square

  so instead of -- we get --
                ||        \/
                ||        /\
                --        --
*/

declare @polygon geometry = 'POLYGON ((0 0, 10 0, 0 10, 10 10,0 0))'

select @polygon.STIsValid() IsValidPolygon, @polygon.MakeValid().ToString() ValidPolygon
select @polygon.MakeValid()

--You will see that this is converted into two triangles one inverted on top of the other. 
go
--The other common issue is overlapping polygons
--If a multi polygon contains shapes that overlap then it may be invalid.
--
--This multi polygon is invalid and is converted to a polygon containing two rings like a donught.
declare @polygon geometry = 'MULTIPOLYGON (((0 0, 10 0, 10 10, 0 10,0 0)),((2 2, 2 4, 4 4, 4 2, 2 2)))'

select @polygon.STIsValid() IsValidPolygon, @polygon.MakeValid().ToString() ValidPolygon, @Polygon.MakeValid().STArea()
select @polygon.MakeValid()
go
--Unlike the MULTIPOLYGON above the GEOMETRYCOLLECTION with the same point sets is valid
declare @polygon geometry = 'GEOMETRYCOLLECTION (POLYGON((0 0, 10 0, 10 10, 0 10,0 0)),POLYGON((2 2, 2 4, 4 4, 4 2, 2 2)))'

select @polygon.STIsValid() IsValidPolygon, @polygon.MakeValid().ToString() ValidPolygon, @Polygon.STArea()
select @polygon.MakeValid()
go
--The impact of whether you choose MULTIPOLYGON and GEOMETRYCOLLECTION can be seen with the result from .STArea().
--The MULTIPLOYGON gets converted into a shape as a result of a STSymDifference whereas the GEOMETRYCOLLECTION provides 
--answers based on a UNION. A geometry collection can contain overlapping shapes.

go
