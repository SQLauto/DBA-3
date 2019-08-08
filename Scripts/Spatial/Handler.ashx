<%@ WebHandler Language="VB" Class="Handler" %>

Imports System
Imports System.Web
Imports System.Data.SqlClient
Imports System.Configuration
Imports System.Text

Public Class Handler : Implements IHttpHandler
    
    Public Sub ProcessRequest(ByVal context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "text/xml"
        context.Response.Charset = "iso-8859-1"
        context.Response.CacheControl = "no-cache"
        context.Response.Expires = 0
        
        Dim con As New SqlConnection("server=.;Trusted_Connection=yes;database=Spatial")
        con.Open()
        Dim cmd As New SqlCommand("EXEC dbo.GetTransportHubsAsRSS", con)
        Dim dr As SqlDataReader
        
        dr = cmd.ExecuteReader()
        While dr.Read()
            context.Response.Write(dr("TransportHubs").ToString())
        End While
        dr.Close()
        con.Close()
    End Sub
 
    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
