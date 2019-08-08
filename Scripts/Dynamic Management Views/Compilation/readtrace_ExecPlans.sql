print ''
print '###  Plans - Query Plan Worst Reads                                 ###'
print '#######################################################################'
print ''
select 	tUPR.PlanHashID
	, tUPR.RowOrder
,tUPR.Rows
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
--	, tUB.NormText
from ReadTrace.tblUniquePlanRows tUPR
--join dbo.tblUniqueBatches tUB on (tUPR.PlanHashID = tUB.HashID)
--from dbo.tblPlanRows tPR
--join dbo.tblPlans tP on (tP.Seq = tPR.Seq)
--join dbo.tblBatches tB on (tP.BatchSeq = tB.BatchSeq)
--join dbo.tblUniqueBatches tUB on (tB.HashID = tUB.HashID)
--join dbo.tblUniquePlanRows tUPR on (tP.PlanHashID = tUPR.PlanHashID and tPR.RowOrder = tUPR.RowOrder)
where tUPR.PlanHashID in 
	(select tP.PlanHashID from ReadTrace.tblPlans tP where tP.BatchSeq in 
		(select tB.BatchSeq from ReadTrace.tblBatches tB
			 where tB.HashID = '-4428254178964912917'

--			(select top(1) vBU.HashID from ReadTrace.vwBatchUtilization vBU order by vBU.AvgReads desc)
		 --order by tb.BatchSeq desc
		)
	)
order by tUPR.PlanHashID, tUPR.RowOrder	

--PJM


--select * from ReadTrace.vwBatchUtilization vBU
 --order by vBU.AvgReads desc


select top(10) tPR.seq as SequenceNumber
	, tPR.RowOrder as StepNumber
	, ABS((tPR.Rows * tPR.Executes) - (tPR.EstimateRows * tPR.EstimateExecutes)) as Factor
	, tPR.Rows
	, tPR.EstimateRows
	, tPR.Executes
	, tPR.EstimateExecutes
	, tP.SPID
	, tP.DOP
	, tUPR.PhysicalOp
	, tUPR.Argument
	, tP.PlanHashID
	, tUB.NormText
--	, tUB.OrigText
from ReadTrace.tblPlanRows tPR
join ReadTrace.tblPlans tP on (tP.Seq = tPR.Seq)
join ReadTrace.tblBatches tB on (tP.BatchSeq = tB.BatchSeq)
join ReadTrace.tblUniqueBatches tUB on (tB.HashID = tUB.HashID)
join ReadTrace.tblUniquePlanRows tUPR on (tP.PlanHashID = tUPR.PlanHashID and tPR.RowOrder = tUPR.RowOrder)
order by ABS((tPR.Rows * tPR.Executes) - (tPR.EstimateRows * tPR.EstimateExecutes)) desc
	, tPR.seq asc
	, tPR.RowOrder asc

select HashID from ReadTrace.tblUniqueBatches where NormText like 'EXEC USP_GETFPAREQUESTSEARCH%'
