    SELECT SUBSTRING(sc.name, 1,30) 'column_name',

             SUBSTRING(OBJECT_NAME(sc.id), 1,30) 'table_name',

             SUBSTRING(type_name(sc.xusertype),1, 10) 'datatype',

             sc.length 'len',

             sc.isnullable 'null'

          FROM syscolumns sc 

         INNER JOIN sysobjects so

           ON sc.id = so.id AND so.type = 'U'

         WHERE sc.name = -- 'systemid' (specify your column name)

         ORDER BY sc.name
