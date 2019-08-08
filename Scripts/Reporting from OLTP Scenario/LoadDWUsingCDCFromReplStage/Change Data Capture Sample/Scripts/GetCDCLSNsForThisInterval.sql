
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Pat Martin
-- Create date: July 2010
-- Description:	Manage CDC Changes
-- =============================================
CREATE PROCEDURE ETL.GetCDCLSNsForThisInterval 
	-- Add the parameters for the stored procedure here
	@StartTime nvarchar(24) = null 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

/*============================================
  This file is part of a Microsoft SQL Server Shared Source Application.
  Copyright (C) Microsoft Corporation.  All rights reserved.
 
THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
PARTICULAR PURPOSE.
========================================== */

	declare 
	
	@lastLSN binary(10),
	@lastLSN_str nvarchar(42),	
	@startLSN binary(10),
	@startLSN_str nvarchar(42),	
	@endLSN binary(10),
	@endLSN_str nvarchar(42),

	@lastlsn_time datetime,
	@lastlsn_time_str nvarchar(24)
	
	
	IF (@StartTime is null)
	BEGIN
	-- Give me all transactions past the snapshot
		exec sys.sp_cdc_dbsnapshotLSN 'SalesStage_ETLSnapshot', @lastLSN output, @lastLSN_str output
		select @startLSN = sys.fn_cdc_increment_lsn(@lastLSN)
		select @endLSN = sys.fn_cdc_get_max_lsn();
		while (@startLSN >= @endLSN) -- NEEDED!!!
		begin
			waitfor delay '00:00:10'
			select @endLSN = sys.fn_cdc_get_max_lsn();
		end		
	END	
	ELSE
	BEGIN
	-- Give me all transactions past the requested start date
	-- TODO - Add timeout logic to cover window where CDC catchup is not possible - PJM
		SET @startLSN = sys.fn_cdc_map_time_to_lsn('smallest greater than', @StartTime);
		SET @endLSN = sys.fn_cdc_get_max_lsn();
		while (@startLSN >= @endLSN OR @startLSN is null) -- NEEDED!!!
		begin
			waitfor delay '00:00:10'
			select @endLSN = sys.fn_cdc_get_max_lsn();
		end
	END
	
	
	-- Map the time interval to a change data capture query range.
	SET @lastlsn_time = sys.fn_cdc_map_lsn_to_time(@endLSN);

	select @startLSN_str = upper(sys.fn_varbintohexstr(@startLSN))
	select @endLSN_str = upper(sys.fn_varbintohexstr(@endLSN))
	select @lastlsn_time_str = CONVERT ( nvarchar(24) , @lastlsn_time , 121 )

	select	@startLSN_str as ExtractStartLSN,
			@endLSN_str as ExtractEndLSN,
			@lastlsn_time_str as ExtractEndTime
			--@lastlsn_time as ExtractEndTime
END

