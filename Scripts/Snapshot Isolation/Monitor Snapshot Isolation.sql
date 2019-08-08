--
-- Script to monitor Snapshot Isolation
--
-- 1- Top 10 Oldest Snapshot Transactions
SELECT TOP 10 atxs.transaction_begin_time, 
              atx.transaction_id, 
              atxs.[name]
FROM sys.dm_tran_active_snapshot_database_transactions AS atx 
INNER JOIN sys.dm_tran_active_transactions as atxs
  ON atx.transaction_id = atxs.transaction_id
WHERE atx.is_snapshot = 1
ORDER BY atxs.transaction_begin_time ASC
GO
--
-- 2- Top 10 Most Expensive Snapshot Transactions
SELECT TOP 10 atxs.transaction_begin_time, atx.* 
FROM sys.dm_tran_active_snapshot_database_transactions AS atx
INNER JOIN sys.dm_tran_active_transactions as atxs
  ON atx.transaction_id = atxs.transaction_id
WHERE atx.is_snapshot = 1
ORDER BY atx.max_version_chain_traversed DESC