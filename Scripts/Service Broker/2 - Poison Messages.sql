USE SBroker;
GO

SELECT * FROM dbo.ApplicationLog;
GO

DELETE FROM dbo.ApplicationLog;
GO

CREATE UNIQUE INDEX UQ_ApplicationLog_UserState
  ON dbo.ApplicationLog (UserState);
GO

-- Test again
EXEC dbo.WriteLogEntry @Details = 'Asynchronous Hello';
GO

SELECT * FROM dbo.ApplicationLog;
GO

-- And again
EXEC dbo.WriteLogEntry @Details = 'Asynchronous Hello';
GO

SELECT * FROM dbo.ApplicationLog;
GO

--> Check the windows application log again

USE master;
GO
