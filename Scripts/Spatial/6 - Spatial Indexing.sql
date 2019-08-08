USE tempdb;
GO

DROP TABLE Shapes;
GO

CREATE TABLE Shapes( id int IDENTITY(1,1) PRIMARY KEY ,Shape GEOMETRY);
GO
CREATE SPATIAL INDEX IX_Shapes_Shape on Shapes(Shape) 
  WITH (BOUNDING_BOX=(0,0,512,512), GRIDS =(LOW,LOW,LOW,LOW));
GO
DELETE FROM Shapes;
INSERT INTO Shapes(Shape) VALUES (GEOMETRY::Parse('POINT(10 10)'));
INSERT INTO Shapes(Shape) VALUES (GEOMETRY::Parse('POLYGON((10 10,490 10,490 490,10 490,10 10))'));
INSERT INTO Shapes(Shape) VALUES (GEOMETRY::Parse('POLYGON((0 0,2 0,2 2,0 2,0 0))'));
INSERT INTO Shapes(Shape) VALUES (GEOMETRY::Parse('POLYGON((2 0,2 2,4 2,4 0,2 0))'));
INSERT INTO Shapes(Shape) VALUES (GEOMETRY::Parse('POLYGON((0 2,2 2,2 4,0 4,0 2))'));
INSERT INTO Shapes(Shape) VALUES (GEOMETRY::Parse('POLYGON((0.5 0.5,1.5 0.5,1.5 1.5,0.5 1.5,0.5 0.5))'));
INSERT INTO Shapes(Shape) VALUES (GEOMETRY::Parse('POLYGON((0.6 0.6,1.6 0.6,1.6 1.6,0.6 1.6,0.6 0.6))'));
INSERT INTO Shapes(Shape) VALUES (GEOMETRY::Parse('POLYGON((2.5 2.5,3.5 2.5,3.5 3.5,2.5 3.5,2.5 2.5))'));
INSERT INTO Shapes(Shape) VALUES (GEOMETRY::Parse('POLYGON((2 2.5,3.5 2.5,3.5 3.5,2 3.5,2 2.5))'));
INSERT INTO Shapes(Shape) VALUES (GEOMETRY::Parse('LINESTRING(2 2.5,2 3.5)'));
INSERT INTO Shapes(Shape) VALUES (GEOMETRY::Parse('LINESTRING(2 2.5,2 35)'));
INSERT INTO Shapes(Shape) VALUES (GEOMETRY::Parse('LINESTRING(2 2.5,2 65)'));
GO

SELECT * FROM sys.spatial_index_tessellations;
SELECT * FROM sys.spatial_indexes;
SELECT * FROM sys.internal_tables;
GO

EXEC sp_help 'sys.spatial_index_tessellations';
GO
EXEC sp_help 'sys.extended_index_389576426_384000';
GO

--Populate the table with a random set of POINTs.
SET NOCOUNT ON;
DECLARE @Counter int = 0;
WHILE @Counter < 10000
BEGIN
  INSERT INTO Shapes 
  SELECT GEOMETRY::Point(CAST(CAST(NEWID() AS varbinary(4))AS int)%100,
                         CAST(CAST(NEWID() as varbinary(4))AS int)%100,0);
  SET @Counter += 1;
END;
GO

-- precise
SELECT * 
FROM Shapes
WHERE Shape.STIntersects('POLYGON((10 10,300 10, 300 300, 10 300, 10 10))')= 1;
GO

-- quicker but less precise
SELECT * 
FROM Shapes
WHERE Shape.Filter('POLYGON((10 10,300 10, 300 300, 10 300, 10 10))')= 1;
GO

DROP TABLE Shapes;
GO
