/*============================================================================
  File:     Proc Params.sql

  Summary:  This script shows the idea behind block modularization - 
            specifically *needing* to recompile.

  Date:     October 2008

  SQL Server Version: 10.00.1600.22 (RTM)
------------------------------------------------------------------------------
  Written by Kimberly L. Tripp

  This script is intended only as a supplement to demos and lectures
  given by Kimberly L. Tripp.  
  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

USE credit
go

SET STATISTICS IO ON
-- Turn Graphical Showplan ON (Ctrl+K)

-- Add an index to SEEK for LastNames
CREATE INDEX MemberFirstName ON dbo.Member(Firstname)
go

-- Add an index to SEEK for LastNames
CREATE INDEX MemberLastName ON dbo.Member(Lastname)
go

UPDATE dbo.member
	SET firstname = 'Kimberly'
	WHERE member_no = 2345
go

CREATE PROC GetMemberInfoParam
	@Lastname	varchar(30) = NULL,
	@Firstname	varchar(30) = NULL,
	@member_no	int = NULL
AS
SELECT * FROM member
WHERE (lastname LIKE @lastname OR @lastname IS NULL)
	AND (member_no = @member_no OR @member_no IS NULL)
	AND (firstname LIKE @firstname OR @firstname IS NULL)
go

exec GetMemberInfoParam	@Lastname = 'Tripp' with recompile
go

exec GetMemberInfoParam	@Firstname = 'Kimberly' with recompile
go

exec GetMemberInfoParam	@Member_no = 9912 with recompile
go

CREATE PROC GetMemberInfoParam2
	@Lastname	varchar(30) = NULL,
	@Firstname	varchar(30) = NULL,
	@member_no	int = NULL
AS
IF @LastName IS NULL AND @FirstName IS NULL AND @Member_no IS NULL
	RAISERROR ('You must supply at least one parameter.', 16, -1)

DECLARE @ExecStr	varchar(1000),
	@MemberNoStr	varchar(100)
SELECT @ExecStr = 'SELECT * FROM member WHERE ' 

IF @LastName IS NOT NULL
	SELECT @Lastname = 'lastname LIKE ' + QUOTENAME(@lastname, '''')
IF @FirstName IS NOT NULL
	SELECT @Firstname = 'firstname LIKE ' + QUOTENAME(@firstname, '''')
IF @Member_no IS NOT NULL
	SELECT @MemberNoStr = 'member_no = ' + convert(varchar(5), @member_no)

SELECT @ExecStr = @ExecStr + ISNULL(@LastName, ' ') 
	+ 
	CASE
		WHEN @LastName IS NOT NULL AND @FirstName IS NOT NULL
			THEN ' AND '
		ELSE ' '
	END
	+
	ISNULL(@FirstName, ' ') 
	+ 
	CASE
		WHEN (@LastName IS NOT NULL OR @FirstName IS NOT NULL)
					AND @MemberNoStr IS NOT NULL
			THEN ' AND '
		ELSE ' '
	END
	+
	ISNULL(@MemberNoStr, ' ')
--SELECT (@ExecStr)
EXEC(@ExecStr)
go
exec GetMemberInfoParam2	@Lastname = 'test', @FirstName = 'Kimberly' 
go
exec GetMemberInfoParam2	@Firstname = 'Kimberly' 
go
exec GetMemberInfoParam2	@Firstname = 'Kimberly', @Member_no = 842 
go
exec GetMemberInfoParam2	@Member_no = 9912 
go
exec GetMemberInfoParam2	@Lastname = 'Florini', @Member_no = 9912 
go
go

CREATE PROC GetMemberInfoParam3
	@Lastname	varchar(30) = NULL,
	@Firstname	varchar(30) = NULL,
	@member_no	int = NULL
AS
SELECT * FROM member
WHERE lastname =
	CASE WHEN @lastname IS NULL THEN lastname
			ELSE @lastname
	END
	AND 
	firstname =
	CASE WHEN @firstname IS NULL THEN firstname
			ELSE @firstname
	END
	AND
	member_no =
	CASE WHEN @member_no IS NULL THEN member_no
			ELSE @member_no
	END
go

exec GetMemberInfoParam3	@Lastname = 'test', @FirstName = 'Kimberly' 
go
exec GetMemberInfoParam3	@Firstname = 'Kimberly' 
go
exec GetMemberInfoParam3	@Firstname = 'Kimberly', @Member_no = 842 
go
exec GetMemberInfoParam3	@Member_no = 9912 
go
exec GetMemberInfoParam3	@Lastname = 'Florini', @Member_no = 9912 
go
go
