' Create a new geography point

Dim gb As New SqlGeographyBuilder 
gb.SetSrid(4326)		 'Must set First 
gb.BeginGeography(OpenGisGeographyType.Point)
gb.BeginFigure(-33, 151)
gb.EndFigure()
gb.EndGeography()

Dim geo As New SqlGeography 
geo = gb.ConstructedGeography 
geo.ToString()

' Create a new geography polygon

Dim g As New SqlGeographyBuilder 
g.SetSrid(4326) 	 'Must set First 
g.BeginGeography(OpenGisGeographyType.Polygon)
g.BeginFigure(-33, 151)	‘Note: Lat, Long format
g.AddLine(-31, 152)
g.AddLine(-30, 152)
g.AddLine(-33, 151)	‘Last Point same as First 
g.EndFigure()
g.EndGeography()

Dim geo As New SqlGeography 
geo = g.ConstructedGeography 
geo.ToString()

' Create a new geography multipolygon

Dim b As New SqlGeographyBuilder 
b.SetSrid(4326) 'Must set 1st
b.BeginGeography(OpenGisGeographyType.MultiPolygon)
b.BeginGeography(OpenGisGeographyType.Polygon)
b.BeginFigure(-33, 151)
b.AddLine(-31, 152)
b.AddLine(-30, 152)
b.AddLine(-33, 151)
b.EndFigure()
b.EndGeography()
b.BeginGeography(OpenGisGeographyType.Polygon)
b.BeginFigure(-33, 155)
b.AddLine(-31, 156)
b.AddLine(-30, 156)
b.AddLine(-33, 155)
b.EndFigure()
b.EndGeography()
b.EndGeography()

Dim geo As New SqlGeography 
geo = b.ConstructedGeography 
geo.ToString()

' Create a new geometry collection

Dim b As New SqlGeographyBuilder 
b.SetSrid(4326) 'Must set 1st
b.BeginGeography(OpenGisGeographyType.GeometryCollection)
b.BeginGeography(OpenGisGeographyType.LineString)
b.BeginFigure(-33, 151)
b.AddLine(-31, 152)
b.AddLine(-30, 152)
b.AddLine(-33, 151)
b.EndFigure()
b.EndGeography()
b.BeginGeography(OpenGisGeographyType.Polygon)
b.BeginFigure(-33, 155)
b.AddLine(-31, 156)
b.AddLine(-30, 156)
b.AddLine(-33, 155)
b.EndFigure()
b.EndGeography()
b.BeginGeography(OpenGisGeographyType.Point)
b.BeginFigure(-32, 153)
b.EndFigure()
b.EndGeography()
b.EndGeography()

Dim geo As New SqlGeography 
geo = b.ConstructedGeography 
geo.ToString()

' Create a geography multipoint

Dim b As New SqlGeographyBuilder 
b.SetSrid(4326) 'Must set 1st
b.BeginGeography(OpenGisGeographyType.MultiPoint)
b.BeginGeography(OpenGisGeographyType.Point)
b.BeginFigure(-33, 151)
b.EndFigure()
b.EndGeography()
b.BeginGeography(OpenGisGeographyType.Point)
b.BeginFigure(-33, 155)
b.EndFigure()
b.EndGeography()
b.BeginGeography(OpenGisGeographyType.Point)
b.BeginFigure(-32, 153)
b.EndFigure()
b.EndGeography()
b.EndGeography()

Dim geo As New SqlGeography 
geo = b.ConstructedGeography 
geo.ToString()
