select COUNT(SalesID) as SalesCount
, MIN(SalesID) as MinSaleID
, MAX(salesID) as MaxSaleID
, SUM(quantity) as SUMQuantitySold
, SalesDate
from SalesDW.dbo.sales
group by SalesDate
order by SalesDate asc

select COUNT(SalesID) as SalesCount
, MIN(SalesID) as MinSaleID
, MAX(salesID) as MaxSaleID
, SUM(quantity) as SUMQuantitySold
, SalesDate
from SalesDW.dbo.salesreporting
group by SalesDate
order by SalesDate asc


update SalesDW.dbo.sales
set salesdate = '2010-10-01 12:59:44.043'
where SalesDate = '2010-09-01 12:59:44.043'
and SalesID > 6738000

/*

select * from sales
 where SalesDate  >= '2010-01-01' AND SalesDate <= '2010-02-28'
  
select * from salesreporting
 where SalesDate  >= '2010-01-01' AND SalesDate <= '2010-02-28'
 
 */
 
 select COUNT(SalesID) as SalesCount
from dbo.sales

delete from dbo.sales where SalesDate = '2010-08-01 01:56:02.797'

 

 

 