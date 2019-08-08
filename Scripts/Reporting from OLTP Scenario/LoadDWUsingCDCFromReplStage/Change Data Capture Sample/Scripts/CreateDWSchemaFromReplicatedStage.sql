select * into dbo.customers from SalesStage.dbo.Customers 
where 0=1

select * into dbo.employees from SalesStage.dbo.employees 
where 0=1

select * into dbo.products from SalesStage.dbo.products 
where 0=1

select GETDATE() SalesDate, * into dbo.sales from SalesStage.dbo.sales
where 0=1

select * from sales

