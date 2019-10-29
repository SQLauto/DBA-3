
select a.dns_name, a.port, a.ip_configuration_string_from_cluster,
       b.ip_address, b.state_desc
	from sys.availability_group_listeners a inner join sys.availability_group_listener_ip_addresses b
	on a.listener_id = b.listener_id


