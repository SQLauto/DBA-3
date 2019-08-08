use TVShop

select 'Index Name' = i.[name],
       'Stats Date' = stats_date(i.[object_id], i.index_id), i.index_id
 from sys.objects o
  inner join sys.indexes i
   on o.[object_id] = i.[object_id]
   where i.name is not null and is_ms_shipped =0
   order by [Stats Date] asc;

