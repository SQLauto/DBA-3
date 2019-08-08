--Signature="9F742E4AB4DC23D4" 
--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****      Compute recommended MAXDOP and display configured value                                         ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    2008.Sep.18 wardp  First version; CR 225155                                                       ****/
--/****    2009.Feb.12 rajpo  For SQL2K getting the run value from syscurconfigs                             ****/                                                                                                 ****/
--/****    2009.Jul.16 wardp  CR 375891 (SQL Server 2008 support)                                            ****/
--/****    2010.Dec.22 rajpo  CR 467401 Filtered out the Numa node 64 (DAC)                                  ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright (c) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

declare @is64bit               bit
declare @numcpu                           int
declare @sqlcpu                               int
declare @hyperratio      int
declare @numa                                int
declare @affinity             int
declare @affinity64         int
declare @maxdop                           int
declare @configmaxdop int

declare @version nvarchar(12);
set     @version =  convert(nvarchar(12),serverproperty('productversion'));
set nocount on

 if  '10' = (select substring(@version, 1, 2)) -- CR 375891
     begin
     
                                --
                                -- get configured value
                                --
                                
                                select @configmaxdop = CAST(value_in_use AS int)
                                                FROM sys.configurations
                                                WHERE name = 'max degree of parallelism'
                                --
                                -- get logical cpu ratio
                                --

                                -- uncomment appropriate set statement:

                                -- if hyperthreading enabled then
                                --             set @hyperratio = 2
                                -- if hyperthreading disabled then
                                                set @hyperratio = 1

                                --
                                --             DO NOT USE (SELECT hyperthread_ratio FROM sys.dm_os_sys_info) to determine this.  This detects logical cpu per socket!!!!
                                --  SOX04082770002 provides some suggestions on how to test this.
                                --

                                -- check if 64 bit

                                if RIGHT(CAST(SERVERPROPERTY('Edition') AS NVARCHAR(128)),8)=N'(64-bit)'
                                                set @is64bit = 1
                                else
                                                set @is64bit = 0

                                -- get total physical cpu

                                set @numcpu=
                                                (SELECT cpu_count
                                                from sys.dm_os_sys_info)

                                -- check for NUMA

                                select @numa = COUNT(DISTINCT memory_node_id)
                                                FROM sys.dm_os_memory_clerks
                                                where memory_node_id != 64
                                                
                                              

                                -- check for non-default affinity mask

                                select @affinity = CAST(value_in_use AS int)
                                                FROM sys.configurations
                                                WHERE name = 'affinity mask'

                                -- check for non-default affinity64 mask

                                if @is64bit = 1
                                select @affinity64 = CAST(value_in_use AS int)
                                                FROM sys.configurations
                                                WHERE name = 'affinity 64 mask'
                                else
                                set @affinity64 = 0

                                -- check maxdop

                                select @maxdop = @configmaxdop

                                --
                                --  Bit Count Operation for Affinity Masks
                                --
                                if (@affinity <> 0) or (@affinity64 <> 0)
                                begin
                                                set @sqlcpu = 0

                                                while @affinity > 0
                                                begin
                                                                  set @sqlcpu = @sqlcpu + @affinity % 2
                                                                  set @affinity = @affinity/2
                                                end

                                                while @affinity64 > 0
                                                begin
                                                                  set @sqlcpu = @sqlcpu + @affinity64 % 2
                                                                  set @affinity64 = @affinity64/2
                                                end
                                end
                                else
                                                set @sqlcpu = @numcpu

                                --
                                --  End Bit Count
                                --
---Raj assigned values for testing only
                /*set @sqlcpu =8
                set @numa =2
                set @configmaxdop=2 */
---Raj assigned values for testing only -END

                                --
                                --  Recommend MAXDOP Setting
                                --
                                if ((@hyperratio = 1) and (@numa = 1))
            set @maxdop = @sqlcpu
                                else
                                begin

                                                set @maxdop = ((@sqlcpu/@hyperratio)/@numa)
                                                /*if sqrt(@maxdop) >= 2
                                                                set @maxdop = 4
                                                else
                                                                if sqrt(@maxdop) >= 1
                                                                                set @maxdop = 2
                                                                else
                                                                                set @maxdop = 1
                                end        */
                                end
                                if @maxdop >8
                                                set @maxdop = 8
              
   end 
 else -- CR 375891
  if  9 = (select substring(@version, 1, 1))
     begin
     
                                --
                                -- get configured value
                                --
                                
                                select @configmaxdop = CAST(value_in_use AS int)
                                                FROM sys.configurations
                                                WHERE name = 'max degree of parallelism'
                                --
                                -- get logical cpu ratio
                                --

                                -- uncomment appropriate set statement:

                                -- if hyperthreading enabled then
                                --             set @hyperratio = 2
                                -- if hyperthreading disabled then
                                                set @hyperratio = 1

                                --
                                --             DO NOT USE (SELECT hyperthread_ratio FROM sys.dm_os_sys_info) to determine this.  This detects logical cpu per socket!!!!
                                --  SOX04082770002 provides some suggestions on how to test this.
                                --

                                -- check if 64 bit

                                if RIGHT(CAST(SERVERPROPERTY('Edition') AS NVARCHAR(128)),8)=N'(64-bit)'
                                                set @is64bit = 1
                                else
                                                set @is64bit = 0

                                -- get total physical cpu

                                set @numcpu=
                                                (SELECT cpu_count
                                                from sys.dm_os_sys_info)

                                -- check for NUMA

                                select @numa = COUNT(DISTINCT memory_node_id)
                                                FROM sys.dm_os_memory_clerks
                                                where memory_node_id != 64

                                -- check for non-default affinity mask

                                select @affinity = CAST(value_in_use AS int)
                                                FROM sys.configurations
                                                WHERE name = 'affinity mask'

                                -- check for non-default affinity64 mask

                                if @is64bit = 1
                                select @affinity64 = CAST(value_in_use AS int)
                                                FROM sys.configurations
                                                WHERE name = 'affinity 64 mask'
                                else
                                set @affinity64 = 0

                                -- check maxdop

                                select @maxdop = @configmaxdop

                                --
                                --  Bit Count Operation for Affinity Masks
                                --
                                if (@affinity <> 0) or (@affinity64 <> 0)
                                begin
                                                set @sqlcpu = 0

                                                while @affinity > 0
                                                begin
                                                                  set @sqlcpu = @sqlcpu + @affinity % 2
                                                                  set @affinity = @affinity/2
                                                end

                                                while @affinity64 > 0
                                                begin
                                                                  set @sqlcpu = @sqlcpu + @affinity64 % 2
                                                                  set @affinity64 = @affinity64/2
                                                end
                                end
                                else
                                                set @sqlcpu = @numcpu

                                --
                                --  End Bit Count
                                --
---Raj assigned values for testing only
                /*set @sqlcpu =8
                set @numa =2
                set @configmaxdop=2 */
---Raj assigned values for testing only -END

                                --
                                --  Recommend MAXDOP Setting
                                --
                                if ((@hyperratio = 1) and (@numa = 1))
            set @maxdop = @sqlcpu
                                else
                                begin

                                                set @maxdop = ((@sqlcpu/@hyperratio)/@numa)
                                                /*if sqrt(@maxdop) >= 2
                                                                set @maxdop = 4
                                                else
                                                                if sqrt(@maxdop) >= 1
                                                                                set @maxdop = 2
                                                                else
                                                                                set @maxdop = 1
                                end        */
                                end
                                if @maxdop >8
                                                set @maxdop = 8
              
   end 
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin

                                
				select @configmaxdop = CAST (value as int)
                                                from master.dbo.syscurconfigs
                                                where comment = N'maximum degree of parallelism'
				
                                                ---Find the number of CPUs

                                if object_id ('tempdb.dbo.#processorCount') is not null
                                                drop table #processorCount
                                create table #processorCount (xp_index int, xp_name varchar (50),internal_value int, character_value int)
                                insert into #processorCount exec xp_msver N'ProcessorCount'
                                select @sqlcpu=internal_value from #processorCount
                                ---Now loop through the affinity mask setting
                                

                                select @affinity = CAST(value AS int)
                                                FROM sysconfigures
                                                WHERE comment = 'affinity mask'
                                ---If it is 64-bit
                                if RIGHT(CAST(SERVERPROPERTY('Edition') AS NVARCHAR(128)),8)=N'(64-bit)'
                                                set @is64bit = 1
                                else
                                                set @is64bit = 0
                                
                                if @is64bit = 1
                                select @affinity64 = CAST(value AS int)
                                                FROM sysconfigures
                                                WHERE comment = 'affinity 64 mask'
                                else
                                set @affinity64 = 0
                
                                ---Now loop through the affnhity mask
                                
                                if (@affinity <> 0) or (@affinity64 <> 0)
                                begin
                                                set @sqlcpu = 0

                                                while @affinity > 0
                                                begin
                                                                  set @sqlcpu = @sqlcpu + @affinity % 2
                                                                  set @affinity = @affinity/2
                                                end

                                                while @affinity64 > 0
                                                begin
                                                                  set @sqlcpu = @sqlcpu + @affinity64 % 2
                                                                  set @affinity64 = @affinity64/2
                                                end
                                end
                                
                                set @maxdop =@sqlcpu
                                if @maxdop >8
                                                set @maxdop = 8

         end

if (@maxdop=@sqlcpu)
                set @maxdop=0

if (@configmaxdop !=@maxdop) --and (@configmaxdop != @sqlcpu)


 select  serverproperty('machinename') as 'Server Name',                                           
         isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
         @configmaxdop as 'MAXDOP Configured Value',                                                            
         @maxdop as 'MAXDOP Optimal Value'
