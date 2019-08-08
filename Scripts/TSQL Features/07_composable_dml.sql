USE tempdb
GO


create table t1 (id int, x uniqueidentifier default(newid()))
GO


/*basic output*/

insert t1 (id)
output inserted.*
values (1)
GO


update t1
set x = NEWID()
output inserted.*, deleted.*
go


delete t1
output deleted.*
go


/*composable DML -- nested output*/
/*must be inserted into a table*/
DECLARE @x TABLE (i int, j uniqueidentifier)

INSERT @x (i, j)
SELECT *
FROM
(
	INSERT t1 (id)
	OUTPUT inserted.*
	VALUES (1)
) AS x
WHERE 
	x.x IS NOT NULL;
GO

