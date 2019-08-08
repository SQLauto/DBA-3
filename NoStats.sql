use adventureworks;

select c.name from sys.columns c
 left outer join sys.stats_columns sc
 on sc.[object_id] = c.[object_id]
 and sc.column_id = c.column_id
   where c.[object_id] = object_id('HumanResources.Employee')
 and sc.column_id is null
 order by c.column_id