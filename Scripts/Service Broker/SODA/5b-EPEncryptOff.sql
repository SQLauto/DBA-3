

:CONNECT localhost\SQLDEV01

ALTER ENDPOINT BrokerEndpoint_SQLDEV01
	FOR SERVICE_BROKER
    ( ENCRYPTION = DISABLED )
--    ( ENCRYPTION = REQUIRED )
GO

:CONNECT localhost\SQLDEV02

ALTER ENDPOINT BrokerEndpoint_SQLDEV02
	FOR SERVICE_BROKER
    ( ENCRYPTION = DISABLED )
--    ( ENCRYPTION = REQUIRED )
GO