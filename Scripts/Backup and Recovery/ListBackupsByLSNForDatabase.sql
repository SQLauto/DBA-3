:SETVAR ActiveServer (local)\SQLDEV02
:SETVAR ActiveDatabase AdventureWorksLT

:ON ERROR EXIT
go

:CONNECT $(ActiveServer)

SELECT Backup_Start_Date,
	(CASE [type]
		WHEN 'D' THEN 'Full'
		WHEN 'I' THEN 'Diff'
		WHEN 'L' THEN 'Log'
		ELSE 'Unknown'
	END) AS 'Type',
	[Position],
	[Name],
	[Description],
	First_LSN, 
	Last_LSN, 
	Backup_Finish_Date, 
	* -- OR Just *
FROM msdb.dbo.backupset AS s
    JOIN msdb.dbo.backupmediafamily AS m
        ON s.media_set_id = m.media_set_id
WHERE database_name = '$(ActiveDatabase)'
ORDER BY 1 ASC