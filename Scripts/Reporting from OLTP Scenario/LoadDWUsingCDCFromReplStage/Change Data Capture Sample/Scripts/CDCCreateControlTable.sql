USE [SalesStage]
GO

/****** Object:  Table [dbo].[ETL.ControlTable]    Script Date: 07/31/2010 02:32:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE ETL.ControlTable(
	[LastExtractDateTime] [varchar](24) NOT NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

INSERT INTO ETL.ControlTable values('');


