USE [xyzmainDW]
GO
/****** Object:  StoredProcedure [ETL].[UpdateControlTable]    Script Date: 07/10/2010 22:54:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [ETL].[UpdateControlTable] 
	@LastExtractDateTime varchar(24) = null 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	--SET NOCOUNT ON

	UPDATE [ETL].[ControlTable]
	   SET LastExtractDateTime = @LastExtractDateTime
END
