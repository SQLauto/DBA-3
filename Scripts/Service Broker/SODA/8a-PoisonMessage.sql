
-- Example of catching the poison message event
-- 

:CONNECT localhost\SQLDEV02

USE Master
GO

USE TestDB
GO

CREATE QUEUE PoisonQueue
GO

CREATE SERVICE PoisonService
  ON QUEUE PoisonQueue
  ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification])
GO

-- ON DATABASE and ON SERVER do not work for this
CREATE EVENT NOTIFICATION DeactivateEvent
  ON QUEUE TestTargetQueue
  FOR BROKER_QUEUE_DISABLED
  TO SERVICE 'PoisonService', 'current database'
GO


