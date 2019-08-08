
sp_who2

/*

There are two different approaches to implementing Resource Governor. The first
approach can be used when you have identified different workloads but are unsure of the
resource utilization of each workload. The second approach assumes that you have
identified the resource utilization for each workload.
The following steps describe how to implement Resource Governor when resource
utilization is known. For example, you want to prevent the administrators from running
queries which take more than 10 percent of the server memory, and limit queries
submitted by marketing from using more than 50 percent of the CPU.
1. Create additional and/or alter existing resource pools with the appropriate settings.

*/

/*
CREATE RESOURCE POOL poolAdmin
WITH (
MAX_MEMORY_PERCENT = 10
)
;
*/

CREATE RESOURCE POOL PoolReporting
WITH (MAX_CPU_PERCENT = 15);

/*

2. Create additional and/or alter existing workload group(s) with the appropriate
settings, and assign each workload group to a specific resource pool.

*/

create workload group groupReporting
using PoolReporting
go

/*

Implementing Resource Governor when workload
utilization is unknown
Use these steps when you know what resource utilization you
want to set for the workloads.

1. Setup the resource pools
2. Create the workloads and assign them to pools.
3. Create the classifier function
4. Register the classifier function with the Resource Governor
5. Enable Resource Governor

*/

SELECT * FROM sys.dm_resource_governor_resource_pools;
SELECT * FROM sys.dm_resource_governor_workload_groups;
SELECT * FROM sys.dm_resource_governor_configuration;


/*
Alter RESOURCE POOL PoolAdmin
WITH (MAX_CPU_PERCENT = 90);
*/

/*
Alter workload group groupAdmin
using PoolAdmin
go
*/

/*
Alter RESOURCE POOL PoolReporting
WITH (MAX_CPU_PERCENT = 10);
*/

/*
create workload group groupReporting
using PoolReporting
go
*/

/*

3. Create or alter a UDF to perform the classification (for example, a function returning
the name of the workload group that each session will be assigned to, based on some
connection information, such as login name or application name). Note that the UDF
is also referred as the classifier function when configuring the Resource Governor.

*/

use master
go

Drop Function rgclassifier_v1
go


CREATE FUNCTION rgclassifier_v1() RETURNS SYSNAME
WITH SCHEMABINDING
AS
	BEGIN
		-- Declare the return variable here
	IF (lower(SUSER_NAME()) != 'xyzreportuser')
		RETURN N'default'
		
	if (lower(APP_NAME()) LIKE '%management studio%') OR (lower(APP_NAME()) LIKE '%query analyzer%')
		RETURN N'groupReporting'

	RETURN N'default'
	
	END
go


/*

4. Register the classifiier function with Resource Governor as follows:

*/

ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION= dbo.rgclassifier_v1)
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

/*
5. Start the Resource Governor and apply all of the changes by running the following
command:

*/

ALTER RESOURCE GOVERNOR RECONFIGURE
--To clear the Resource Governor statistics, use the following command:
ALTER RESOURCE GOVERNOR Reset Statistics
--To unregister the classifier function, either use:
ALTER RESOURCE GOVERNOR DISABLE
--Or use:
ALTER RESOURCE GOVERNOR WITH (Classifier_Function = NULL);
ALTER RESOURCE GOVERNOR RECONFIGURE

/*

When you are unsure of the resource utilization of the workloads, the steps to implement
Resource Governor are:

1. Create workload groups.
2. Create a function to classify requests into a workload group.
3. Register the classifier function in the previous step with Resource Governor.
4. Enable Resource Governor.
5. Monitor the resource consumption for each workload group by using the
SQLServer:Workload Group Stats object in Perfmon. This object helps you
monitor the amount of CPU and memory that each workload consumes.
6. Use the Performance Monitor logs to establish pools. Based on the statistics collected
in the previous step, you can define minimums and maximums for resource
utilization.
7. Assign the workload group to the pools.
