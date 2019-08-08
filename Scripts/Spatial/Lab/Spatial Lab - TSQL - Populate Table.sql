
use SpatialLab
go

truncate table Geo
go

declare @p geometry 
declare @div float 
set @div = 1000.0;

with geoms(x1,xdiff, y1, ydiff)
as( select abs(cast (cast(newid() as varbinary(MAX)) as int)) %10000000/@div x1 
         , abs(cast (cast(newid() as varbinary(MAX)) as int)) %10000/@div xDiff
         , abs(cast (cast(newid() as varbinary(MAX)) as int)) %10000000/@div y1
         , abs(cast (cast(newid() as varbinary(MAX)) as int)) %10000/@div YDiff2
from num 
where id < 10000)
insert into Geo
select newid(),geometry::STGeomFromWKB(  0x000000000300000001
                                 + 0x00000005 
                                 + cast(X1 as binary(8)) + cast(Y1 as binary(8)) 
                                 + cast(X1 as binary(8)) + cast(Y1+YDiff as binary(8)) 
                                 + cast(X1+XDiff as binary(8)) + cast(Y1+YDiff as binary(8)) 
                                 + cast(X1+XDiff as binary(8)) + cast(Y1 as binary(8)) 
                                 + cast(X1 as binary(8)) + cast(Y1 as binary(8)),0).ToString()
from geoms
where x1 <> y1 and xDiff > 0 and yDiff >0

