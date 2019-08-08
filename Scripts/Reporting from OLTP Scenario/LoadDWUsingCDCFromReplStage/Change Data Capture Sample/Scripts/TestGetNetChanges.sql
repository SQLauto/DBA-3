
select * from cdc.fn_cdc_get_net_changes_dbo_orders
	(0X000001A30000268E0001, 0X000001A300002A760001, 'all')
	
select * from cdc.[fn_cdc_get_net_changes_dbo_order details]
	(0X000001A30000268E0001, 0X000001A300002A760001, 'all')
	
--select  sys.fn_cdc_get_min_lsn ( 'dbo_order details' )
--select  sys.fn_cdc_get_min_lsn ( 'dbo_orders' )
	
-- These are good values!