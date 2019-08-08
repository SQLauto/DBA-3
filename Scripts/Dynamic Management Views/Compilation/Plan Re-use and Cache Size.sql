-- Plan Re-use & Cache Size
--	Compare single use plans to re-used plans
--

-- This script is provided "AS IS" with no warranties, and confers no rights. 
-- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
--

declare @single int, @reused int, @total int

select @single=
	sum(case(usecounts)
		when 1 then 1
		else 0
	end),
	@reused=
	sum(case(usecounts)
		when 1 then 0
		else 1
	end),
	@total=count(usecounts)
from sys.dm_exec_cached_plans

select 
'Single use plans (usecounts=1)'= @single,
'Re-used plans (usecounts>1)'= @reused,
're-use %'=cast(100.0*@reused / @total as dec(5,2)),
'total usecounts'=@total


select 'single use plan size'=sum(cast(size_in_bytes as bigint))
from sys.dm_exec_cached_plans
where usecounts = 1