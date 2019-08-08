-- Had to restart service and then run this code (twice)

exec master.dbo.sp_serveroption @server=N'SQL2008Admin\sqldev02',
@optname=N'dist', @optvalue=N'false'

exec sp_dropdistributor @no_checks=1,@ignore_distributor=1

--exec sp_dropdistributiondb 'distribution'
--exec sp_dropdistributor



