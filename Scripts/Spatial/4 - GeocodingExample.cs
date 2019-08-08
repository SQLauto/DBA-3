using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.Net;
using Geocoder.MapPoint;

namespace Geocoder
{
	public partial class GeocodingFunctions
	{
		[SqlFunction()]
		public static SqlString Geocode( SqlString AddressLine,
			                             SqlString PrimaryCity,
			                             SqlString Subdivision,
			                             SqlString PostalCode,
			                             SqlString CountryRegion,
			                             SqlString UserName,
			                             SqlString Password)
		{
			FindServiceSoap findService = new FindServiceSoap();
			findService.Credentials 
			  = new NetworkCredential(UserName.ToString(), Password.ToString());

			FindAddressSpecification addressToGeocode 
			  = new FindAddressSpecification();
	          
			Address address = new Address();
			address.AddressLine = AddressLine.ToString();
			address.PrimaryCity = PrimaryCity.ToString();
			address.Subdivision = Subdivision.ToString();
			address.PostalCode = PostalCode.ToString();
			address.CountryRegion = CountryRegion.ToString();
	        
			addressToGeocode.InputAddress = address;
			// NOTE: need to use the appropriate MapPoint location (NA for North America)
			addressToGeocode.DataSourceName = "MapPoint.AP";

			FindOptions findOptions = new FindOptions();
			// we only want latitude and longitude
			findOptions.ResultMask = FindResultMask.LatLongFlag;
	        
			FindRange findRange = new FindRange();
			findRange.StartIndex = 0;
			findRange.Count = 1;
	        
			findOptions.Range = findRange;

			addressToGeocode.Options = findOptions;

			FindResults findResults;
			findResults = findService.FindAddress(addressToGeocode);

			SqlString locatedAddress = new SqlString();
			if (findResults.Results.Length > 0)
			{
				locatedAddress 
				  = "POINT("
				  + findResults.Results[0].FoundLocation.LatLong.Longitude 
				  + " " 
				  + findResults.Results[0].FoundLocation.LatLong.Latitude 
				  + ")";
			}
			else
			{
				locatedAddress = "POINT EMPTY";
			}

			return locatedAddress;
		}
	}
}