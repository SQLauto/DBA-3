cd "C:\Program Files\Microsoft SQL Server\100\COM"
c:
tablediff -sourceserver .\sqldev02 -sourcedatabase xyzmain -sourceschema dbo -sourcetable customers -destinationserver .\sqldev03 -destinationdatabase xyzmainapprepl -destinationschema dbo -destinationtable customers -f "fixcustomers.sql"
tablediff -sourceserver .\sqldev02 -sourcedatabase xyzmain -sourceschema dbo -sourcetable orders -destinationserver .\sqldev03 -destinationdatabase xyzmainapprepl -destinationschema dbo -destinationtable orders -f "fixorders.sql"
tablediff -sourceserver .\sqldev02 -sourcedatabase xyzmain -sourceschema dbo -sourcetable [order details] -destinationserver .\sqldev03 -destinationdatabase xyzmainapprepl -destinationschema dbo -destinationtable [order details] -f "fixorderdetails.sql"
tablediff -sourceserver .\sqldev02 -sourcedatabase xyzmain -sourceschema dbo -sourcetable categories -destinationserver .\sqldev03 -destinationdatabase xyzmainapprepl -destinationschema dbo -destinationtable categories -f "fixcategories.sql"
tablediff -sourceserver .\sqldev02 -sourcedatabase xyzmain -sourceschema dbo -sourcetable products -destinationserver .\sqldev03 -destinationdatabase xyzmainapprepl -destinationschema dbo -destinationtable products -f "fixproducts.sql"

pause
