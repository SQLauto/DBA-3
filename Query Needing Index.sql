--- Query needing index.sql
---
--- The query plan for this query indicates an index could be helpful
---	FOR THIS QUERY only !

--- This stored procedure is provided "AS IS" with no warranties, and confers no rights. 
--- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
---
--- 
dbcc freeproccache
go
use adventureworks2000
go
select 
	CustomerID, 
	CASE ContactType
		WHEN 1 THEN 'Call'
		WHEN 2 THEN 'Meeting'
		WHEN 3 THEN 'E-Mail'
	END ContactType,
	convert(nvarchar(100), ContactDate, 1) Date,
	notes
from customer_contacts
where ContactDate between '1/1/04' and '2/1/04'
and SalesPersonID = 13

 
