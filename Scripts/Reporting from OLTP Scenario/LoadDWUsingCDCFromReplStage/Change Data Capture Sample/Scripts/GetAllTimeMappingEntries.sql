/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 15000 [start_lsn]
      ,[tran_begin_time]
      ,[tran_end_time]
      ,[tran_id]
      ,[tran_begin_lsn]
  FROM [xyzmain].[cdc].[lsn_time_mapping]