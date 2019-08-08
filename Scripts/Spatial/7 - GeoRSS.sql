USE Spatial;
GO

IF EXISTS(SELECT 1 FROM sys.objects WHERE name = 'GetTransportHubsAsRSS')
  DROP PROCEDURE dbo.GetTransportHubsAsRSS;
GO

CREATE PROCEDURE dbo.GetTransportHubsAsRSS
AS
BEGIN
  SET NOCOUNT ON;
  
  DECLARE @GeoRSS xml;

  WITH XMLNAMESPACES ( 'http://www.opengis.net/gml' AS gml,
                       'http://www.georss.org/georss' AS georss
                     )
  SELECT @GeoRSS =
    (SELECT CityName AS title,
            CityName + ' ' + Location.ToString() AS description,
            'http://www.sqldownunder/City/' + CAST(CityId AS varchar(10)) AS link,
            LEFT(DATENAME(dw, GETDATE()),3) + ', '
              + STUFF(CONVERT(nvarchar,GETDATE(),113),21,4,' GMT') AS pubDate,
            Location.AsGml() AS [georss:where]
     FROM dbo.Cities
     WHERE IsMajorTransportHub = 1
     FOR XML PATH('item'), ROOT('channel'));

  SELECT @GeoRSS.query('
  <rss version="2.0"
    xmlns:georss="http://www.georss.org/georss"
    xmlns:gml="http://www.opengis.net/gml">
    <channel>
      <title>Transport Hub GeoRSS Feed</title>
      <description>Transport Hub GeoRSS Feed</description>
      <link>http://www.sqldownunder.com</link>
      {
        for $i in channel/item
        return <item>
                 <title> { $i/title/text() }</title>
                 <description> { $i/description/text() }</description>
                 <link> { $i/link/text() }</link>
                 <pubDate>  { $i/pubDate/text() }</pubDate>
                 <georss:where>
                 {
                   for $shape in $i/georss:where/*
                   return <gml:Point> { $shape/* } </gml:Point>
                 }
                 </georss:where>
               </item>
      }
    </channel>
  </rss>') AS TransportHubs;
END
GO

EXEC dbo.GetTransportHubsAsRSS;
GO
