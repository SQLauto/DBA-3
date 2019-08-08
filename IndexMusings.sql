use adventureworks
go

create table sp_table_pages
(
	 PageFID			tinyint
	,PagePID			int
	,IAMFID				tinyint
	,IAMPID				int
	,ObjectID			int
	,IndexID			tinyint
	,PartitionNumber	tinyint
	,PartitionID		bigint
	,iam_chain_type		varchar(30)
	,PageType			tinyint
	,IndexLevel			tinyint
	,NextPageFID		tinyint
	,NextPagePID		int
	,PrevPageFID		tinyint
	,PrevPagePID		int
	,Primary Key		(PageFID,PagePID)
);

drop table bigrows
go

create table bigrows
(
	a int primary key,
	b varchar(1600)
);

go

insert into bigrows values(5,  replicate('a', 1600));
insert into bigrows values(10, replicate('b', 1600));
insert into bigrows values(15, replicate('c', 1600));
insert into bigrows values(20, replicate('d', 1600));
insert into bigrows values(25, replicate('e', 1600));

go

select * from bigrows;

sp_helpindex N'bigrows';

truncate table sp_table_pages;
insert into sp_table_pages exec ('dbcc ind (AdventureWorks, bigrows, -1)' );

select PageFID, PagePID, PageType from sp_table_pages where pagetype = 1;

dbcc traceon(3604);
go

dbcc page(AdventureWorks, 1, 21013, 1);

-- Insert a new row out of order, to see what happens...

insert into bigrows values(22, replicate('x', 1600));
go

dbcc page(AdventureWorks, 1, 21034, 1);
go


