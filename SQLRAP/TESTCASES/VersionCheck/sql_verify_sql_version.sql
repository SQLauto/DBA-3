--Signature="20F0A4A3E77A432E" 

--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    Master check against the latest version of SQL Server 2005                                        ****/
--/****                                                                                                      ****/
--/****    Master check against the latest version of SQL Server 2000                                        ****/
--/****                                                                                                      ****/
--/****    8/11/08 - Tim Wolff - changed logic to account for MS08-040                                       ****/
--/****    11/25/08 - Ward Pond - CR 256767                                                                  ****/
--/****    2/16/09 - Ward Pond - CR 306836; bug 306838                                                       ****/
--/****    7/06/09 - Ward Pond - CR 371291                                                                   ****/
--/****    11/02/09 - djaiswal - CR 379851                                                                   ****/
--/****    11/03/09 - Ward Pond - CR 379851                                                                  ****/
--/****    12/02/09 - Ward Pond - bug 419864                                                                 ****/
--/****    03/02/2010 -Rajpo	-CR 439212                                                                   ****/
--/****    05/18/10 - Ward Pond - CR 457667                                                                  ****/
--/****    05/31/10 - Ward Pond - CR 457667 (again)                                                          ****/
--/****    06/01/10 - Ward Pond - bug 459907                                                                 ****/
--/****    06/04/10 - Ward Pond - bug 459907 (again)                                                         ****/
--/****    06/16/10 - Ward Pond - bug 464802                                                                 ****/
--/****    06/30/10 - Ward Pond - bug 459907 (again)                                                         ****/
--/****    08/09/10 - Ward Pond - CR 467355                                                                  ****/
--/****    10/08/10 - Ward Pond - CR 467355 (again)                                                          ****/
--/****    01/19/11 - Rajpo     - CR 472558 changed the latest builds                                        ****/
--/****	   06/06/11 - Rajpo     - CR 473245 Changed the default builds for QFE 2008 and R2                   ****/
--/****	   10/17/11 - Rajpo		- CR 480849 Changed the GDR and QFE builds to latest                         ****/	
--/****    Copyright (c) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

-- re: bug 457667:
-- note and beware of the inconsistency in the minor level between major <= 9 (two-digit minor) and major >= 10 (one-digit minor).
-- SQL PG does this to keep the build digits in the same relative position of the string across all versions.
declare @2008R2defaultGDR char(12);
set     @2008R2defaultGDR = '10.50.2500.00'; --changed --SP1

declare @2008R2defaultQFE char(12);
set     @2008R2defaultQFE =  '10.50.2772.00'; ---changed

declare @2008defaultGDR char(12);
set     @2008defaultGDR = '10.0.5500.0'; --changed --SP3

declare @2008defaultQFE char(12);
set     @2008defaultQFE = '10.0.5500.0' ; --changed 

declare @2005defaultGDR char(12);
set     @2005defaultGDR = '9.00.5000' ---SP4

declare @2005defaultQFE char(12);
set     @2005defaultQFE = '9.00.5292' --changed

declare @2000defaultGDR char(12);
set     @2000defaultGDR = '8.00.2050.00' ;

declare @2000defaultQFE char(12);
set     @2000defaultQFE = '8.00.2283.00';   

declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));

declare @build   char(4);
if  '10.50' = (select substring(@version, 1, 5))
	set     @build = convert(int, substring(@version, 7, 4))
else
	set     @build = convert(int, substring(@version, 6, 4))


if  '10.5' = (select substring(@version, 1, 4))
     begin 
	  if  @build BETWEEN 0000 AND (convert(int, substring(@2008R2defaultGDR, 7, 4)) - 1)
     
              begin 
                    --print @build
                   select serverproperty('machinename')                                        as 'Server Name',                                            
                          isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
                          @2008R2defaultGDR                                                      as 'Recommended Build',  
                          convert(char(12),serverproperty('productversion'))                   as 'Current Build'
              end
		ELSE
              if  @build BETWEEN (convert(int, substring(@2008R2defaultGDR, 7, 4)) + 1) AND (convert(int, substring(@2008R2defaultQFE, 7, 4)) - 1)
              begin 
                   select serverproperty('machinename')                                        as 'Server Name',                                            
                          isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
                          @2008R2defaultQFE                                                      as 'Recommended Build',  
                          convert(char(12),serverproperty('productversion'))                   as 'Current Build'
              end
     end
 else 
 if  '10' = (select substring(@version, 1, 2))
     begin
	  if  @build BETWEEN 0000 AND (convert(int, substring(@2008defaultGDR, 6, 4)) - 1)  -- Change to accomodate 2008, this will never happen
     
              begin 
                    --print @build
                   select serverproperty('machinename')                                        as 'Server Name',                                            
                          isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
                          @2008defaultGDR                                                      as 'Recommended Build',  
                          convert(char(12),serverproperty('productversion'))                   as 'Current Build'
              end
		ELSE
              if  @build BETWEEN (convert(int, substring(@2008defaultGDR, 6, 4)) + 1) AND (convert(int, substring(@2008defaultQFE, 6, 4)) - 1)  -- Change to accomodate 2008  
              begin 
                   select serverproperty('machinename')                                        as 'Server Name',                                            
                          isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
                          @2008defaultQFE                                                      as 'Recommended Build',  
                          convert(char(12),serverproperty('productversion'))                   as 'Current Build'
              end
     end
 else 
 if  9 = (select substring(@version, 1, 1))
     begin

	if  @build BETWEEN 0000 AND (convert(int, substring(@2005defaultGDR, 6, 4)) - 1)  -- bug 306838
              begin 
                   select serverproperty('machinename')                                        as 'Server Name',                                            
                          isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
                          @2005defaultGDR                                                      as 'Recommended Build',  
                          convert(char(12),serverproperty('productversion'))                   as 'Current Build'
              end
		ELSE
			if  @build BETWEEN (convert(int, substring(@2005defaultGDR, 6, 4)) + 1) AND (convert(int, substring(@2005defaultQFE, 6, 4)) - 1)  -- bug 306838
              begin 
                   select serverproperty('machinename')                                        as 'Server Name',                                            
                          isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
                          @2005defaultQFE                                                      as 'Recommended Build',  
                          convert(char(12),serverproperty('productversion'))                   as 'Current Build'
              end
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin
	        if  @build BETWEEN 0000 AND (convert(int, substring(@2000defaultGDR, 6, 4)) - 1)  -- bug 306838
              begin 
                   select serverproperty('machinename')                                        as 'Server Name',                                            
                          isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
                          @2000defaultGDR                                                      as 'Recommended Build',  
                          convert(char(12),serverproperty('productversion'))                   as 'Current Build'
              end
		ELSE
			if  @build  BETWEEN (convert(int, substring(@2000defaultGDR, 6, 4)) + 1) AND (convert(int, substring(@2000defaultQFE, 6, 4)) - 1)  -- bug 306838
              begin 
                   select serverproperty('machinename')                                        as 'Server Name',                                            
                          isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
                          @2000defaultQFE                                                      as 'Recommended Build',  
                          convert(char(12),serverproperty('productversion'))                   as 'Current Build'
              end
     end
