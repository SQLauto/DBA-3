/*----------------------------------------------------------------
------------------------------------------------------------------
---  ReadTrace_LeanMeanVersion                                 ---
------------------------------------------------------------------
---  Script to reproduce the output of the original ReadTrace  ---
---  utility to provide greater detail for problem resolution  ---
------------------------------------------------------------------
----------------------------------------------------------------*/

Use Progressive
--Use SQLNexus
Set Nocount On;

print ''
print '###  Interesting Events                                ###'
print '##########################################################'
select convert(nvarchar(30),te.name) as Event
	, count(tIE.EventID) as Occurances
	, tIE.Error
from ReadTrace.tblInterestingEvents tIE
join master.sys.trace_events te on (tIE.EventID = te.trace_event_id)
group by te.name, tIE.Error
order by te.name, count(tIE.EventID) desc


print ''
print '###  Rollup - Top 10 Batches by Attentions             ###'
print '##########################################################'
select top(10) vBU.CompletedEvents as Executions
	, vBU.AttentionEvents
	, convert(nvarchar(20),vBU.AvgDuration) as AvgDuration
	, convert(nvarchar(20),vBU.AvgReads) as AvgReads
	, convert(nvarchar(20),vBU.AvgWrites) as AvgWrites
	, convert(nvarchar(20),vBU.AvgCPU) as AvgCPU
	, vBU.HashID
	, tUB.NormText
from ReadTrace.vwBatchUtilization vBU
join ReadTrace.tblUniqueBatches tUB on (vBU.HashID = tUB.HashID)
order by vBU.AttentionEvents desc, vBU.CompletedEvents desc

----------------------------------------------------------------------------------

print ''
print '###  Average - Top 10 Batches by AvgDuration           ###'
print '##########################################################'
select top(10) vBU.CompletedEvents as Executions
	, vBU.Duration
	, convert(nvarchar(20),vBU.AvgDuration) as AvgDuration
	, vBU.Reads
	, convert(nvarchar(20),vBU.AvgReads) as AvgReads
	, vBU.Writes
	, convert(nvarchar(20),vBU.AvgWrites) as AvgWrites
	, vBU.CPU
	, convert(nvarchar(20),vBU.AvgCPU) as AvgCPU
	, vBU.HashID
	, tUB.NormText
from ReadTrace.vwBatchUtilization vBU
join ReadTrace.tblUniqueBatches tUB on (vBU.HashID = tUB.HashID)
order by vBU.AvgDuration desc

print ''
print '###  Average - Top 10 Batches by AvgReads              ###'
print '##########################################################'
select top(10) vBU.CompletedEvents as Executions
	, vBU.Duration
	, convert(nvarchar(20),vBU.AvgDuration) as AvgDuration
	, vBU.Reads
	, convert(nvarchar(20),vBU.AvgReads) as AvgReads
	, vBU.Writes
	, convert(nvarchar(20),vBU.AvgWrites) as AvgWrites
	, vBU.CPU
	, convert(nvarchar(20),vBU.AvgCPU) as AvgCPU
	, vBU.HashID
	, tUB.NormText
from ReadTrace.vwBatchUtilization vBU
join ReadTrace.tblUniqueBatches tUB on (vBU.HashID = tUB.HashID)
order by vBU.AvgReads desc

print ''
print '###  Average - Top 10 Batches by AvgWrites             ###'
print '##########################################################'
select top(10) vBU.CompletedEvents as Executions
	, vBU.Duration
	, convert(nvarchar(20),vBU.AvgDuration) as AvgDuration
	, vBU.Reads
	, convert(nvarchar(20),vBU.AvgReads) as AvgReads
	, vBU.Writes
	, convert(nvarchar(20),vBU.AvgWrites) as AvgWrites
	, vBU.CPU
	, convert(nvarchar(20),vBU.AvgCPU) as AvgCPU
	, vBU.HashID
	, tUB.NormText
from ReadTrace.vwBatchUtilization vBU
join ReadTrace.tblUniqueBatches tUB on (vBU.HashID = tUB.HashID)
order by vBU.AvgWrites desc

print ''
print '###  Average - Top 10 Batches by AvgCPU                ###'
print '##########################################################'
select top(10) vBU.CompletedEvents as Executions
	, vBU.Duration
	, convert(nvarchar(20),vBU.AvgDuration) as AvgDuration
	, vBU.Reads
	, convert(nvarchar(20),vBU.AvgReads) as AvgReads
	, vBU.Writes
	, convert(nvarchar(20),vBU.AvgWrites) as AvgWrites
	, vBU.CPU
	, convert(nvarchar(20),vBU.AvgCPU) as AvgCPU
	, vBU.HashID
	, tUB.NormText
from ReadTrace.vwBatchUtilization vBU
join ReadTrace.tblUniqueBatches tUB on (vBU.HashID = tUB.HashID)
order by vBU.AvgCPU desc

----------------------------------------------------------------------------------

print ''
print '###  Rollup - Top 10 Batches by Duration               ###'
print '##########################################################'
select top(10) vBU.CompletedEvents as Executions
	, vBU.Duration
	, convert(nvarchar(20),vBU.AvgDuration) as AvgDuration
	, vBU.Reads
	, convert(nvarchar(20),vBU.AvgReads) as AvgReads
	, vBU.Writes
	, convert(nvarchar(20),vBU.AvgWrites) as AvgWrites
	, vBU.CPU
	, convert(nvarchar(20),vBU.AvgCPU) as AvgCPU
	, vBU.HashID
	, tUB.NormText
from ReadTrace.vwBatchUtilization vBU
join ReadTrace.tblUniqueBatches tUB on (vBU.HashID = tUB.HashID)
order by vBU.Duration desc

print ''
print '###  Rollup - Top 10 Batches by Reads                  ###'
print '##########################################################'
select top(10) vBU.CompletedEvents as Executions
	, vBU.Duration
	, convert(nvarchar(20),vBU.AvgDuration) as AvgDuration
	, vBU.Reads
	, convert(nvarchar(20),vBU.AvgReads) as AvgReads
	, vBU.Writes
	, convert(nvarchar(20),vBU.AvgWrites) as AvgWrites
	, vBU.CPU
	, convert(nvarchar(20),vBU.AvgCPU) as AvgCPU
	, vBU.HashID
	, tUB.NormText
from ReadTrace.vwBatchUtilization vBU
join ReadTrace.tblUniqueBatches tUB on (vBU.HashID = tUB.HashID)
order by vBU.Reads desc

print ''
print '###  Rollup - Top 10 Batches by Writes                 ###'
print '##########################################################'
select top(10) vBU.CompletedEvents as Executions
	, vBU.Duration
	, convert(nvarchar(20),vBU.AvgDuration) as AvgDuration
	, vBU.Reads
	, convert(nvarchar(20),vBU.AvgReads) as AvgReads
	, vBU.Writes
	, convert(nvarchar(20),vBU.AvgWrites) as AvgWrites
	, vBU.CPU
	, convert(nvarchar(20),vBU.AvgCPU) as AvgCPU
	, vBU.HashID
	, tUB.NormText
from ReadTrace.vwBatchUtilization vBU
join ReadTrace.tblUniqueBatches tUB on (vBU.HashID = tUB.HashID)
order by vBU.Writes desc

print ''
print '###  Rollup - Top 10 Batches by CPU                    ###'
print '##########################################################'
select top(10) vBU.CompletedEvents as Executions
	, vBU.Duration
	, convert(nvarchar(20),vBU.AvgDuration) as AvgDuration
	, vBU.Reads
	, convert(nvarchar(20),vBU.AvgReads) as AvgReads
	, vBU.Writes
	, convert(nvarchar(20),vBU.AvgWrites) as AvgWrites
	, vBU.CPU
	, convert(nvarchar(20),vBU.AvgCPU) as AvgCPU
	, vBU.HashID
	, tUB.NormText
from ReadTrace.vwBatchUtilization vBU
join ReadTrace.tblUniqueBatches tUB on (vBU.HashID = tUB.HashID)
order by vBU.CPU desc

----------------------------------------------------------------------------------

print ''
print '###  Individual - Top 10 Unique Batches by Duration    ###'
print '##########################################################'
select top(10) tB.StartTime as StartTime
	, tB.EndTime
	, tB.SPID
	, tB.Duration
	, tB.Reads
	, tB.Writes
	, tB.CPU
	, convert(nvarchar(30),(select top(1) sTF.TraceFileName from ReadTrace.tblTraceFiles sTF where sTF.FirstSeqNumber < tB.StartSeq order by sTF.TraceFileName desc)) as StartingTraceFile --trace file for start of batch
	, convert(nvarchar(30),(select top(1) eTF.TraceFileName from ReadTrace.tblTraceFiles eTF where eTF.FirstSeqNumber < tB.EndSeq order by eTF.TraceFileName desc)) as EndingTraceFile --trace file for end of batch
	, tB.HashID
	, tUB.NormText
from ReadTrace.tblBatches tB
join ReadTrace.tblUniqueBatches tUB on (tB.HashID = tUB.HashID)
order by tB.Duration desc

print ''
print '###  Individual - Top 10 Batches by Reads              ###'
print '##########################################################'
select top(10) tB.StartTime as StartTime
	, tB.EndTime
	, tB.SPID
	, tB.Duration
	, tB.Reads
	, tB.Writes
	, tB.CPU
	, convert(nvarchar(30),(select top(1) sTF.TraceFileName from ReadTrace.tblTraceFiles sTF where sTF.FirstSeqNumber < tB.StartSeq order by sTF.TraceFileName desc)) as StartingTraceFile --trace file for start of batch
	, convert(nvarchar(30),(select top(1) eTF.TraceFileName from ReadTrace.tblTraceFiles eTF where eTF.FirstSeqNumber < tB.EndSeq order by eTF.TraceFileName desc)) as EndingTraceFile --trace file for end of batch
	, tB.HashID
	, tUB.NormText
from ReadTrace.tblBatches tB
join ReadTrace.tblUniqueBatches tUB on (tB.HashID = tUB.HashID)
order by tB.Reads desc

print ''
print '###  Individual - Top 10 Batches by Writes             ###'
print '##########################################################'
select top(10) tB.StartTime as StartTime
	, tB.EndTime
	, tB.SPID
	, tB.Duration
	, tB.Reads
	, tB.Writes
	, tB.CPU
	, convert(nvarchar(30),(select top(1) sTF.TraceFileName from ReadTrace.tblTraceFiles sTF where sTF.FirstSeqNumber < tB.StartSeq order by sTF.TraceFileName desc)) as StartingTraceFile --trace file for start of batch
	, convert(nvarchar(30),(select top(1) eTF.TraceFileName from ReadTrace.tblTraceFiles eTF where eTF.FirstSeqNumber < tB.EndSeq order by eTF.TraceFileName desc)) as EndingTraceFile --trace file for end of batch
	, tB.HashID
	, tUB.NormText
from ReadTrace.tblBatches tB
join ReadTrace.tblUniqueBatches tUB on (tB.HashID = tUB.HashID)
order by tB.Writes desc

print ''
print '###  Individual - Top 10 Batches by CPU                ###'
print '##########################################################'
select top(10) tB.StartTime as StartTime
	, tB.EndTime
	, tB.SPID
	, tB.Duration
	, tB.Reads
	, tB.Writes
	, tB.CPU
	, convert(nvarchar(30),(select top(1) sTF.TraceFileName from ReadTrace.tblTraceFiles sTF where sTF.FirstSeqNumber < tB.StartSeq order by sTF.TraceFileName desc)) as StartingTraceFile --trace file for start of batch
	, convert(nvarchar(30),(select top(1) eTF.TraceFileName from ReadTrace.tblTraceFiles eTF where eTF.FirstSeqNumber < tB.EndSeq order by eTF.TraceFileName desc)) as EndingTraceFile --trace file for end of batch
	, tB.HashID
	, tUB.NormText
from ReadTrace.tblBatches tB
join ReadTrace.tblUniqueBatches tUB on (tB.HashID = tUB.HashID)
order by tB.CPU desc

-----------------------------------------------------------------------------
print ''
print '###  Plans - Top 10 Discrepancies Between Estimated and Actual      ###'
print '#######################################################################'
print '~~~  Note: StepNumber is the number of the step in the plan and     ~~~'
print '~~~  only relates to other StepNumbers with the same SequenceNumber ~~~'
print '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
print ''
select top(10) tPR.seq as SequenceNumber
	, tPR.RowOrder as StepNumber
	, ABS((tPR.Rows * tPR.Executes) - (tPR.EstimateRows * tPR.EstimateExecutes)) as Factor
	, tPR.Rows
	, tPR.EstimateRows
	, tPR.Executes
	, tPR.EstimateExecutes
	, tP.SPID
	, tP.DOP
	, tP.PlanHashID
	, tUB.NormText
--	, tUB.OrigText
from ReadTrace.tblPlanRows tPR
join ReadTrace.tblPlans tP on (tP.Seq = tPR.Seq)
join ReadTrace.tblBatches tB on (tP.BatchSeq = tB.BatchSeq)
join ReadTrace.tblUniqueBatches tUB on (tB.HashID = tUB.HashID)
order by ABS((tPR.Rows * tPR.Executes) - (tPR.EstimateRows * tPR.EstimateExecutes)) desc
	, tPR.seq asc
	, tPR.RowOrder asc

-----------------------------------------------------------------------------
print ''
print '###  Captured Profiler Events                          ###'
print '##########################################################'
select convert(nvarchar(30),tc.name) as Category, convert(nvarchar(30),te.name) as Event
from master.sys.trace_events te
join master.sys.trace_categories tc on (tc.category_id = te.category_id)
where te.trace_event_id in (select EventID from ReadTrace.tblTracedEvents)
order by tc.name

------------------------------------------------------------------------------------
print ''
print '###  Plans - Query Plan Worst Reads                                 ###'
print '#######################################################################'
print ''
select tUPR.PlanHashID
	, tUPR.RowOrder
	, tUPR.Rows
	, tUPR.Executes
	, tUPR.StmtText
	, tUPR.StmtID
	, tUPR.NodeID
	, tUPR.Parent
	, tUPR.PhysicalOp
	, tUPR.LogicalOp
	, tUPR.Argument
	, tUPR.DefinedValues
	, tUPR.EstimateRows
	, tUPR.EstimateIO
	, tUPR.EstimateCPU
	, tUPR.AvgRowSize
	, tUPR.TotalSubtreeCost
	, tUPR.OutputList
	, tUPR.Warnings
	, tUPR.Type
	, tUPR.Parallel
	, tUPR.EstimateExecutions
from ReadTrace.tblUniquePlanRows tUPR
where tUPR.PlanHashID in 
	(select tP.PlanHashID from ReadTrace.tblPlans tP where tP.BatchSeq in 
		(select tB.BatchSeq from ReadTrace.tblBatches tB where tB.HashID = 
			(select top(1) vBU.HashID from ReadTrace.vwBatchUtilization vBU order by vBU.AvgReads desc)
--		 order by tb.Reads desc
		)
	)
order by tUPR.PlanHashID, tUPR.RowOrder	

print ''
print '###  Plans - Query Plan Worst Duration                              ###'
print '#######################################################################'
print ''
select tUPR.PlanHashID
	, tUPR.RowOrder
	, tUPR.Rows
	, tUPR.Executes
	, tUPR.StmtText
	, tUPR.StmtID
	, tUPR.NodeID
	, tUPR.Parent
	, tUPR.PhysicalOp
	, tUPR.LogicalOp
	, tUPR.Argument
	, tUPR.DefinedValues
	, tUPR.EstimateRows
	, tUPR.EstimateIO
	, tUPR.EstimateCPU
	, tUPR.AvgRowSize
	, tUPR.TotalSubtreeCost
	, tUPR.OutputList
	, tUPR.Warnings
	, tUPR.Type
	, tUPR.Parallel
	, tUPR.EstimateExecutions
from ReadTrace.tblUniquePlanRows tUPR
where tUPR.PlanHashID in 
	(select tP.PlanHashID from ReadTrace.tblPlans tP where tP.BatchSeq in 
		(select tB.BatchSeq from ReadTrace.tblBatches tB where tB.HashID = 
			(select top(1) vBU.HashID from ReadTrace.vwBatchUtilization vBU order by vBU.AvgDuration desc)
--		 order by tb.Duration asc
		)
	)
order by tUPR.PlanHashID, tUPR.RowOrder	


print ''
print '###  Plans - Query Plan Worst CPU                                   ###'
print '#######################################################################'
print ''
select tUPR.PlanHashID
	, tUPR.RowOrder
	, tUPR.Rows
	, tUPR.Executes
	, tUPR.StmtText
	, tUPR.StmtID
	, tUPR.NodeID
	, tUPR.Parent
	, tUPR.PhysicalOp
	, tUPR.LogicalOp
	, tUPR.Argument
	, tUPR.DefinedValues
	, tUPR.EstimateRows
	, tUPR.EstimateIO
	, tUPR.EstimateCPU
	, tUPR.AvgRowSize
	, tUPR.TotalSubtreeCost
	, tUPR.OutputList
	, tUPR.Warnings
	, tUPR.Type
	, tUPR.Parallel
	, tUPR.EstimateExecutions
from ReadTrace.tblUniquePlanRows tUPR
where tUPR.PlanHashID in 
	(select tP.PlanHashID from ReadTrace.tblPlans tP where tP.BatchSeq in 
		(select tB.BatchSeq from ReadTrace.tblBatches tB where tB.HashID = 
			(select top(1) vBU.HashID from ReadTrace.vwBatchUtilization vBU order by vBU.AvgCPU desc)
--		 order by tb.CPU desc
		)
	)
order by tUPR.PlanHashID, tUPR.RowOrder	
