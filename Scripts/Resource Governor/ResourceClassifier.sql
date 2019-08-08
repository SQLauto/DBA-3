-- ================================================
-- Template generated from Template Explorer using:
-- Create Scalar Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Pat Martin
-- Create date: July 2010
-- Description:	RG Classifier
-- =============================================
ALTER FUNCTION fnResourceClassifier 
(
)
	RETURNS sysname
	
	AS
	BEGIN
		-- Declare the return variable here
	IF (lower(SUSER_NAME()) != 'xyzreportuser')
		RETURN N'default'
		
	if (lower(APP_NAME()) LIKE '%management studio%') OR (lower(APP_NAME()) LIKE '%query analyzer%')
		RETURN N'groupReporting'

	RETURN N'default'
	
	END
	
GO

