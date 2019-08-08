USE Spatial;
GO

-- Note the locations of the cities
SELECT * FROM dbo.Cities;
GO

-- Enforce that all cities use the same SRID
IF EXISTS(SELECT 1 FROM sys.objects WHERE name = 'CHK_Cities_Location_SRID')
  ALTER TABLE dbo.Cities DROP CONSTRAINT CHK_Cities_Location_SRID;
GO

ALTER TABLE dbo.Cities 
ADD CONSTRAINT CHK_Cities_Location_SRID 
CHECK (Location.STSrid = 4326)
GO

-- Simple distance calculation (note the parentheses)
SELECT f.Location.STDistance((SELECT t.Location 
                              FROM dbo.Cities AS t 
                              WHERE CityName = 'Perth'))
  FROM dbo.Cities AS f WHERE f.CityName = 'Brisbane';
GO

-- Nearest major transport hub
DECLARE @TestLocation GEOGRAPHY 
  = (SELECT Location FROM dbo.Cities WHERE CityName = 'Aberdeen');

SELECT c.CityName, 
       c.Location.STDistance(@TestLocation),
       c.Location.ToString()
FROM dbo.Cities AS c
WHERE c.IsMajorTransportHub = 1
  AND c.Location.STDistance(@TestLocation) 
      = (SELECT MIN(h.Location.STDistance(@TestLocation))
         FROM dbo.Cities AS h
         WHERE h.IsMajorTransportHub = 1);
GO                                           

-- alternately using TOP (note the difference in query plan)
DECLARE @TestLocation GEOGRAPHY 
  = (SELECT Location FROM dbo.Cities WHERE CityName = 'Aberdeen');

SELECT TOP(1) c.CityName, 
              c.Location.STDistance(@TestLocation),
              c.Location.ToString()
FROM dbo.Cities AS c
WHERE c.IsMajorTransportHub = 1
ORDER BY c.Location.STDistance(@TestLocation);
GO

-- Countries (note the spatial pane, and projections for geography)
SELECT * FROM dbo.Countries;
GO  
  
  
-- STEnvelope returns a bounding box
-- Note: we'll use the geometry version of the border
SELECT BorderAsGeometry.STEnvelope()
  FROM dbo.Countries 
  WHERE CountryName = 'Australia'
UNION ALL
SELECT BorderAsGeometry
  FROM dbo.Countries 
  WHERE CountryName = 'Australia';
GO

-- STConvexHull returns a tight bounding area
SELECT BorderAsGeometry.STConvexHull()
  FROM dbo.Countries 
  WHERE CountryName = 'Australia'
UNION ALL
SELECT BorderAsGeometry
  FROM dbo.Countries 
  WHERE CountryName = 'Australia';
GO

-- Reduce (try values 1 to 10)
SELECT BorderAsGeometry.Reduce(1)
  FROM dbo.Countries 
  WHERE CountryName = 'Australia';
GO
