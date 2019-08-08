/*============================================================================
  File:     Spatial Lab - TSQL - Num table.sql

  Summary:  Used to generate a number table for use in the scenarios

  Date:     August 2008

  SQL Server Version: 10.0.2531.0 (SQL Server 2008 SP1)
------------------------------------------------------------------------------
  Written By Simon Sabin, SYSolutions, Inc.
  http://www.sqlskills.com/blogs/simon

  All rights reserved.

  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/
go
use SpatialLab
go
set nocount on
go
create table num ( id int not null primary key)
go
declare @i int = 0
while @i < 1000
  begin
  insert into num values (@i)
  set @i += 1
  end
go
