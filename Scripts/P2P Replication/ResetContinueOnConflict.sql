USE [XYZMain]
EXEC sp_changepublication 
  @publication = 'Customers', 
  @property = N'p2p_continue_onconflict', 
  @value = true
GO

--To verify the option has been changed, run the following command.
-- You should see the value 1 in the p2p_continue_onconflict column.

USE [XYZMain]
EXEC sp_helppublication @publication = 'Customers'


USE [XYZMainAppRepl]
EXEC sp_changepublication 
  @publication = 'Customers', 
  @property = N'p2p_continue_onconflict', 
  @value = true
GO

--To verify the option has been changed, run the following command.
-- You should see the value 1 in the p2p_continue_onconflict column.

USE [XYZMainAppRepl]
EXEC sp_helppublication @publication = 'Customers'
