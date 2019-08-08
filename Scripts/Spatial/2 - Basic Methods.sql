USE Spatial;
GO

DECLARE @Brisbane GEOGRAPHY = GEOGRAPHY::STGeomFromText('POINT (153.02 -27.25)',4326);
DECLARE @Perth GEOGRAPHY = GEOGRAPHY::STGeomFromText('POINT (115.52 -31.57)',4326);
SELECT @Brisbane.STDistance(@Perth);
GO

-- Creating a GEOGRAPHY Point from WKT
DECLARE @Paris GEOGRAPHY ;
SET @Paris = GEOGRAPHY::STPointFromText('POINT(48.87 2.33)', 4326);
select @Paris 
GO

-- Creating a GEOMETRY Point from WKT
DECLARE @Point GEOMETRY;
SET @Point = GEOMETRY::STPointFromText('POINT(32577 234232)', 0);
GO

-- Creating a LineString from WKT
DECLARE @PanamaCanal GEOGRAPHY;
SET @PanamaCanal 
  = GEOGRAPHY::STLineFromText('LINESTRING( -79.909 9.339, -79.536 8.942 )',4326);
GO

-- Creating a Polygon from WKT
DECLARE @Pentagon GEOGRAPHY;
SET @Pentagon = GEOGRAPHY::STPolyFromText(
  'POLYGON(( -47.0532219483429 19.870863029297695,
             -47.05468297004701 19.87304314667469,
             -47.05788016319276 19.872800914712734,
             -47.05849170684814 19.870219840133124,
             -47.05556273460198 19.8690670969195,
             -47.0532219483429 19.870863029297695),
           ( -47.05582022666931 19.8702866652523,
             -47.0569360256195 19.870734733163644,
             -47.05673214773439 19.87170668418343,
             -47.0554769039154 19.871848684516294,
             -47.05491900444031 19.87097997215688,
             -47.05582022666931 19.8702866652523))',
           4326);
SELECT @Pentagon;
GO

-- Creating a GEOMETRYCollection from WKT
DECLARE @ShapeCollection GEOMETRY;
SET @ShapeCollection = GEOMETRY::STGeomCollFromText(
   'GEOMETRYCOLLECTION( POLYGON((15 15, 10 15, 10 10, 15 15)),
                        POINT(10 10))',0);
SELECT @ShapeCollection;
GO

-- CLRTypes implement the Parse() and ToString() methods
DECLARE @SomePoint GEOGRAPHY;
SET @SomePoint = GEOGRAPHY::Parse('POINT(12 5)');
SELECT @SomePoint.ToString();
GO

-- STAsText() returns WKT by default
DECLARE @Point GEOMETRY;
SET @Point = GEOMETRY::STPointFromText('POINT(10 20 15 5)', 0);
SELECT @Point.STAsText();
GO

-- ToString() returns more info
DECLARE @Point GEOMETRY;
SET @Point = GEOMETRY::STPointFromText('POINT(10 20 15 5)', 0);
SELECT @Point.ToString()
GO

-- AsTextZM() can be used with collections
DECLARE @GeometryCollection GEOMETRY;
SET @GeometryCollection = GEOMETRY::STGeomCollFromText(
  'GEOMETRYCOLLECTION(LINESTRING(15 15 2 0, 12 5 2 4),
                      POINT(20 20 4 6))',0);
SELECT @GEOMETRYCollection.AsTextZM();
GO

-- Creating a Point from WKB
DECLARE @ByteOrder bit = 0;
DECLARE @GeometryType int = 1;
DECLARE @Longitude float = 33.20;
DECLARE @Latitude float = 41.92;
DECLARE @BinaryValue varbinary(max);
DECLARE @NewPoint GEOGRAPHY;

SET @BinaryValue = CAST(@ByteOrder AS binary(1))
                 + CAST(@GeometryType AS binary(4))
                 + CAST(@Longitude AS binary(8))
                 + CAST(@Latitude AS binary(8));
SET @NewPoint = GEOGRAPHY::STPointFromWKB(@BinaryValue, 4326);
GO

-- Converting between formats
DECLARE @WKT varchar(100) = 'POINT(92 7)';
DECLARE @WKB varbinary(max);
DECLARE @InitialPoint GEOMETRY = GEOMETRY::STGeomFromText(@WKT,0);
DECLARE @RecreatedPoint GEOMETRY;

SET @WKB = @InitialPoint.STAsBinary();
SET @RecreatedPoint = GEOMETRY::STGeomFromWKB(@WKB,0);

SELECT @InitialPoint.STAsText(), @RecreatedPoint.STAsText();
GO

-- GML as an exchange format
DECLARE @Point GEOGRAPHY;
SET @Point = GEOGRAPHY::GeomFromGml('
  <Point xmlns="http://www.opengis.net/gml">
      <pos>12 50</pos>
  </Point>',4326);
GO

-- GML Linestring
DECLARE @LineString GEOMETRY;
SET @LineString = GEOMETRY::GeomFromGml('
  <LineString xmlns="http://www.opengis.net/gml">
    <posList>12 4 9 14</posList>
  </LineString>',0);
SELECT @LineString;
GO

-- Polygon
DECLARE @Polygon GEOMETRY;
SET @polygon = GEOMETRY::GeomFromGml('
  <Polygon xmlns="http://www.opengis.net/gml">
    <exterior>
      <LinearRing>
        <posList>0 0 200 0 200 200 0 200 0 0</posList>
      </LinearRing>
    </exterior>
    <interior>
      <LinearRing>
        <posList>5 5 20 10 140 140 10 20 5 5</posList>
      </LinearRing>
    </interior>
  </Polygon>', 0);
SELECT @Polygon;
GO  

-- GeometryCollection (note the odd capitalization)
DECLARE @GeometryCollection GEOMETRY
SET @GeometryCollection = GEOMETRY::GeomFromGml('
  <MultiGeometry xmlns="http://www.opengis.net/gml">
    <geometryMembers>
      <Point>
        <pos>25 9</pos>
      </Point>
      <LineString>
        <posList>6 12 2 4</posList>
      </LineString>
    </geometryMembers>
  </MultiGeometry>', 0);
SELECT @GeometryCollection;
GO

-- Outputting GML
DECLARE @PanamaCanal GEOGRAPHY;
SET @PanamaCanal 
  = GEOGRAPHY::STLineFromText('LINESTRING( -79.909 9.339, -79.536 8.942 )',4326);
SELECT @PanamaCanal.AsGml();
GO

