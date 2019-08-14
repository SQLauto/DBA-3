#Since there can be Availability Groups with the same name, we might want to add a groupId to the mix just to keep things unique.
$labServer = "XXX"
$inventoryDB = "XXX"

#Clean the XXX table so that the inventory is built every single time
Invoke-Sqlcmd -Query "TRUNCATE TABLE XXX" -Database $inventoryDB -ServerInstance $labServer

#Fetch all the instances with the respective SQL Server Version
/*
   This is an example of the result set that your query must return
   ############################################################################
   # name                     # version             # instance                #
   ############################################################################
   # server1.domain.net,45000 # SQL Server 2012 RTM # server1\MSSQLSERVER1    #
   # server2.domain.net,45000 # SQL Server 2012 SP2 # server2                 #
   # server3.domain.net,45000 # SQL Server 2012 SP2 # server3                 #
   # server4.domain.net,45000 # SQL Server 2014 SP2 # server4\MSSQLSERVER_2K14#
   # server5.domain.net,45000 # SQL Server 2016 SP2 # server5\SQLSERVER2016   #
   ############################################################################
*/
$instanceLookupQuery = /*Put in here the query that will return the set of instances to evaluate*/

$instances = Invoke-Sqlcmd -ServerInstance $labServer -Database $inventoryDB -Query $instanceLookupQuery

#Create a couple of temporary tables to store all the results fetched from all the instances
$tmpTableReplicasQuery = "
CREATE TABLE ##AlwaysOnReplicasInformation(
    [GroupId] [int] NOT NULL,
    [GroupName] [nvarchar](255) NOT NULL,
    [Replica] [nvarchar](255) NOT NULL,
    [Role] [nvarchar](255) NOT NULL,
    [AvailabilityMode] [nvarchar](255) NOT NULL,
    [FailoverMode] [nvarchar](255) NOT NULL,
    [ConnectionsInPrimaryRole] [nvarchar](255) NOT NULL,
    [ConnectionsInSecondaryRole] [nvarchar](255) NOT NULL,
    [SeedingMode] [nvarchar](255),
    [EndpointURL] [nvarchar](255) NOT NULL,
    [Listener] [nvarchar](255) NOT NULL
)
"
Invoke-Sqlcmd -ServerInstance $labServer -Database 'tempdb' -Query $tmpTableReplicasQuery

#For each instance, grab the AlwaysOn replicas information
    $groupId = 1
    foreach ($instance in $instances){

    #SQL Server 2012/2014 doesn't have a seeding mode description available as it was introduced in 2016
    if($instance.version.Substring(11,4) -ge 2016){
        $AlwaysOnReplicasInformationQuery = "
         SELECT 
            ag.name AS 'GroupName'
           ,cs.replica_server_name AS 'Replica'
           ,rs.role_desc AS 'Role'
           ,REPLACE(ar.availability_mode_desc,'_',' ') AS 'AvailabilityMode'
           ,ar.failover_mode_desc AS 'FailoverMode'
           ,ar.primary_role_allow_connections_desc AS 'ConnectionsInPrimaryRole'
           ,ar.secondary_role_allow_connections_desc AS 'ConnectionsInSecondaryRole'
           ,ar.seeding_mode_desc AS 'SeedingMode'
           ,ar.endpoint_url AS 'EndpointURL'
           ,al.dns_name AS 'Listener'
         FROM sys.availability_groups ag
         JOIN sys.dm_hadr_availability_group_states ags ON ag.group_id = ags.group_id
         JOIN sys.dm_hadr_availability_replica_cluster_states cs ON ags.group_id = cs.group_id 
         JOIN sys.availability_replicas ar ON ar.replica_id = cs.replica_id 
         JOIN sys.dm_hadr_availability_replica_states rs  ON rs.replica_id = cs.replica_id 
         LEFT JOIN sys.availability_group_listeners al ON ar.group_id = al.group_id; 
         "
    } 
    else{
    $AlwaysOnReplicasInformationQuery = "
        SELECT 
            ag.name AS 'GroupName'
           ,cs.replica_server_name AS 'Replica'
           ,rs.role_desc AS 'Role'
           ,REPLACE(ar.availability_mode_desc,'_',' ') AS 'AvailabilityMode'
           ,ar.failover_mode_desc AS 'FailoverMode'
           ,ar.primary_role_allow_connections_desc AS 'ConnectionsInPrimaryRole'
           ,ar.secondary_role_allow_connections_desc AS 'ConnectionsInSecondaryRole'
           ,NULL AS 'Seeding Mode'
           ,ar.endpoint_url AS 'EndpointURL'
           ,al.dns_name AS 'Listener'
        FROM sys.availability_groups ag 
        JOIN sys.dm_hadr_availability_group_states ags ON ag.group_id = ags.group_id
        JOIN sys.dm_hadr_availability_replica_cluster_states cs ON ags.group_id = cs.group_id 
        JOIN sys.availability_replicas ar ON ar.replica_id = cs.replica_id 
        JOIN sys.dm_hadr_availability_replica_states rs  ON rs.replica_id = cs.replica_id 
        LEFT JOIN sys.availability_group_listeners al ON ar.group_id = al.group_id;
        "
    }

    #Go grab the AlwaysOn Availability Groups replicas information for the instance
    Write-Host "Fetching AlwaysOn Replicas information for instance" $instance.instance
    $results = Invoke-Sqlcmd -Query $AlwaysOnReplicasInformationQuery -ServerInstance $instance.name -ErrorAction Stop -querytimeout 30}

    #Build the INSERT statement if it returned at least 1 row
    $isSecondaryReplica = 0

    if($results.Length -ne 0){
      #Build the insert statement 
      $insert = "INSERT INTO ##AlwaysOnReplicasInformation VALUES"
      foreach($result in $results){
        if ($result.Replica -eq $instance.instance -and $result.Role -eq 'SECONDARY'){
            $isSecondaryReplica = 1
        }

        $insert += "
        (
         "+$groupId+",
         '"+$result.GroupName+"',
         '"+$result.Replica+"',
         '"+$result.Role+"',
         '"+$result.AvailabilityMode+"',
         '"+$result.FailoverMode+"',
         '"+$result.ConnectionsInPrimaryRole+"',
         '"+$result.ConnectionsInSecondaryRole+"',
         '"+$result.SeedingMode+"',
         '"+$result.EndpointURL+"',
         '"+$result.Listener+"'
        ),"
       }

   #Store the results from each primary replica into ##AlwaysOnReplicasInformation
       if($isSecondaryReplica -ne 1){
       Invoke-Sqlcmd -Query $insert.Substring(0,$insert.LastIndexOf(',')) -ServerInstance $labServer -Database $inventoryDB
         $groupId++
        }
   }   
}

 #Here you perform the final insert into your central database table
 $finalInsert = "
    INSERT INTO XXX
    SELECT 
       GroupId
      ,GroupName
      ,Replica
      ,Role
      ,AvailabilityMode
      ,FailoverMode
      ,ConnectionsInPrimaryRole
      ,ConnectionsInSecondaryRole
      ,SeedingMode
      ,EndpointURL
      ,Listener
       FROM ##AlwaysOnReplicasInformation
 "
 Invoke-Sqlcmd -Query $finalInsert -ServerInstance $labServer -Database $inventoryDB

Write-Host "Done!"