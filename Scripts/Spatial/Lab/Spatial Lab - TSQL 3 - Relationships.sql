/*============================================================================
  File:     Spatial Lab - TSQL 2 - Properties and Methods.sql

  Summary:  Scripts for Excercise 1 Scenario 3 of the Spatial Lab

  Date:     August 2008

  SQL Server Version 2008 (RTM)
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
/*###################################################################################
  
   In the previous excercise we looked at the properties of geometry variables in
   this excercise we will look at the relaionships between geometries
  
   Many of these methods provide different results depending on the dimension of 
   the geometries involved. Whilst this may appear as though there are methods that 
   do the same thing, it is very useful where you have geometries of different 
   dimensions.

#####################################################################################*/
--
-- STIntersects(),  STOverlaps(), STCrosses(), STTouches 
--  
-- These all provide some information about how two shapes intersect
--
-------------------------------------------------------------------------------------

--STIntersect() will return 1 if any point of either shapes exists on or within the boundaries 
--or the other shape. If any of the other methods return 1 then this will also return 1
--
--This method does not consider a shapes dimension

/* With the geometeries we have      x|
   so line 1 and 2 intersect but nothing intersects with line 3
*/

declare @line1 geometry = 'LINESTRING (2 1, 8 7)'
declare @line2 geometry = 'LINESTRING (9 1, 3 7)'
declare @line3 geometry = 'LINESTRING (10 1, 10 8)'

select @line1.STIntersects (@line2), @line1.STIntersects(@Line3), @Line2.STIntersects(@line3)
select @line2.STIntersects (@line1), @line3.STIntersects(@Line1), @Line3.STIntersects(@line2)

-- visualize
select @line1 union all select @line2 union all select @line3
--This method does not mind which way round the geometeries are. If A interesects B then B will intersect A

--STOverlaps() will return 1 if any the intersection of two shapes has the same dimension as the 
--maximum dimension dimension of the two shapes involved. i.e. when two polygons intersect they
--generally form another polygon, however if the only edges intersect, the intersection is a line
--a line has 1 dimension and so in this case the polygons don't overlap.
--
--Two lines generally intersect at a point however if any segments of the two lines line on top of each 
--other then the intersection is a line. In this case the two lines overlap
--

go
--Two overlapping lines
declare @line1 geometry = 'LINESTRING (1 1, 5 3, 5 6, 2 8)'
declare @line2 geometry = 'LINESTRING (8 1, 5 3, 5 6, 8 8)'

--Two overlapping polygons
declare @poly1 geometry = 'POLYGON((1 2, 1 7, 7 4, 1 2))'
declare @poly2 geometry = 'POLYGON((10 2, 4 4, 10 7, 10 2))'

select @line1.STOverlaps(@line2) LinesOverlap, @poly1.STOverlaps(@poly2) PolysOverlap, @line1.STOverlaps(@poly1) LineOverlapsPoly
select @line1.STIntersects (@line2) LinesIntersect, @poly1.STIntersects (@poly2) PolysIntersect, @line1.STIntersects (@poly1) LineIntersectsPoly

-- visualize
select @line1 union all select @line2 
union all select @poly1 union all select @poly2

--Even though line 1 is on top of poly1 it is not classed as overlapping as the dimensions of 
--the shapes are different
go

declare @s1 geometry = 'POLYGON((0 0, 10 0, 10 10, 0 10,0 0))'
declare @s2 geometry = 'POLYGON((2 2, 2 4, 4 4, 4 2, 2 2))'
declare @s3 geometry = 'POLYGON((5 5, 15 5, 15 15, 5 15,5 5))'

select @s1.STUnion(@s2).ToString(), @s1.STDifference(@s2).ToString(), @s1.STDifference(@s3).ToString(), @s1.STSymDifference(@s3).ToString()

go
declare @polygon geometry = 'GEOMETRYCOLLECTION (POLYGON((0 0, 10 0, 10 10, 0 10,0 0)),POLYGON((5 5, 15 5, 15 15, 5 15,5 5)))'

select @polygon.STIsValid() IsValidPolygon, @polygon.MakeValid().ToString() ValidPolygon, @Polygon.STArea()
go
declare @polygon geometry = 'MULTIPOLYGON (((0 0, 10 0, 10 10, 0 10,0 0)),((5 5, 15 5, 15 15, 5 15,5 5)))'

select @polygon.STIsValid() IsValidPolygon, @polygon.MakeValid().ToString() ValidPolygon, @Polygon.MakeValid().STArea()
go
declare @polygon geometry = 'GEOMETRYCOLLECTION (POLYGON((0 0, 10 0, 10 10, 0 10,0 0)),POLYGON((0 0, 10 0, 10 10, 0 10,0 0)))'

select @polygon.STIsValid() IsValidPolygon, @polygon.MakeValid().ToString() ValidPolygon, @Polygon.STArea(), @polygon.STUnion(@polygon).ToString()
go
