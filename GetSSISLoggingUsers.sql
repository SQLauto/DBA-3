/****** Script for SelectTopNRows command from SSMS  ******/
SELECT count (package_name) Entries
		, [package_name]
      ,[message]
  FROM [SSISDB].[internal].[operation_messages] A inner join [SSISDB].[internal].[event_messages] B
  on A.operation_id = b.operation_id
  Group By [package_name], [message]

  SELECT Count(package_name) Entries
	  ,package_name
      ,[event_name]
	    FROM [SSISDB].[internal].[event_messages]
	  Group By [package_name], [event_name]