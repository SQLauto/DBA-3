Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'T-Log VLF Check Condition', @description=N'', @facet=N'Database', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>LE</OpType>
  <Count>2</Count>
  <Function>
    <TypeClass>Numeric</TypeClass>
    <FunctionType>ExecuteSql</FunctionType>
    <ReturnType>Numeric</ReturnType>
    <Count>2</Count>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>Numeric</Value>
    </Constant>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>&lt;?char 13?&gt;
create table #tmp (FileID varchar(3), FileSize numeric(20,0),&lt;?char 13?&gt;
StartOffset bigint, FSeqNo bigint, Status char(1),&lt;?char 13?&gt;
Parity varchar(4), CreateLSN numeric(25,0))&lt;?char 13?&gt;
insert into #tmp&lt;?char 13?&gt;
EXEC (''''dbcc loginfo'''')&lt;?char 13?&gt;
select count(*) from #tmp&lt;?char 13?&gt;
drop table #tmp&lt;?char 13?&gt;
</Value>
    </Constant>
  </Function>
  <Constant>
    <TypeClass>Numeric</TypeClass>
    <ObjType>System.Double</ObjType>
    <Value>50</Value>
  </Constant>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id

GO


