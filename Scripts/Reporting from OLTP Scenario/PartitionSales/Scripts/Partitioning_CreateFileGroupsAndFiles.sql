
:SETVAR TargetServer (local)\SQLDEV02
:SETVAR TargetDB SalesDW
:SETVAR FILEGROUPCOUNT 6
:SETVAR SQLDATADIRECTORY c:\sqlskills\test

go

:ON ERROR EXIT
go

:CONNECT $(TargetServer)

!!REM mkdir C:\SQLskills\Test
go

-- Might need to watch transaction log,  ....

USE $(TargetDB)
GO

declare @i int 
declare @ExecStr nvarchar(max)
declare @CountStr nvarchar(2)

-------------------------------------------------------
-- Add FILEGROUPS to the target database
-------------------------------------------------------

SET @i = 1

WHILE @i <= $(FILEGROUPCOUNT)
BEGIN

  SET @CountStr = rtrim(convert(nchar(2),@i));
  
  SELECT @ExecStr = N'ALTER DATABASE $(TARGETDB) ADD FILEGROUP FG' + @CountStr
  
  --SELECT @Execstr
  exec (@ExecStr)
  
  SET @i+=1
  
END

-------------------------------------------------------
-- Add Files to each Filegroup - ONE FILE PER GROUP.
-------------------------------------------------------

SET @i = 1

WHILE @i <= $(FILEGROUPCOUNT)
BEGIN

  SET @CountStr = rtrim(convert(nchar(2),@i));
  
  SELECT @ExecStr = N'ALTER DATABASE $(TARGETDB) ADD FILE ' +
         N'(NAME = N''Partitioned' + '$(TARGETDB)' + N'FG' + @CountStr + '''' +
         N', FileName = N''$(SQLDATADIRECTORY)\Partitioned' + '$(TARGETDB)' + N'FG' + @CountStr + 'File' + '1.ndf''' +
         N', SIZE = 10MB, MAXSIZE = 100MB, FILEGROWTH = 10MB)' +
         N' TO FILEGROUP [FG' + @CountStr + ']'
                    
  --SELECT @Execstr
  exec (@ExecStr)
  
  SET @i+=1
  
END


-------------------------------------------------------
-- Verify all files and filegroups
-------------------------------------------------------
USE $(TARGETDB)
go

sp_helpfilegroup
exec sp_helpfile
go

