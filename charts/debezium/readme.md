## Prerequisite

Database scripts to be run before deploying Debezium Change Data Capture helm chart

### Grant `master` database View Server State to user `nbs_ods`
```tsql
USE MASTER
GO
GRANT VIEW SERVER STATE TO nbs_ods;
```

### Enable Change data capture on Database level.
[Change Data Capture](https://learn.microsoft.com/en-us/sql/relational-databases/track-changes/enable-and-disable-change-data-capture-sql-server?view=sql-server-ver16)

```tsql
USE nbs_odse
GO
EXEC sys.sp_cdc_enable_db
GO
```

### Enable Change data capture on table level. 
Run the below SQL script, copy the contents of the result to query window and execute them all.

```tsql
use nbs_odse;

select concat('exec sys.sp_cdc_enable_table @source_schema = N', '''', TABLE_SCHEMA, ''',@source_name = N', '''',
TABLE_NAME, ''',@role_name = NULL;')
from INFORMATION_SCHEMA.TABLES t
where t.TABLE_catalog = 'nbs_odse'
and t.TABLE_SCHEMA = 'dbo'
and TABLE_TYPE = 'Base Table'
and t.TABLE_NAME in (select distinct TABLE_NAME
from INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
where tc.CONSTRAINT_catalog = 'nbs_odse'
and tc.table_catalog = 'nbs_odse'
and tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
and tc.CONSTRAINT_SCHEMA = 'dbo'
and tc.TABLE_NAME not like '%TEMP%'
and tc.TABLE_SCHEMA = 'dbo')
order by t.table_name;
```

### Verify if Change data capture is enabled

```tsql
select
  name,
  is_cdc_enabled
from sys.databases;
```

### Verify the tables tracked by Sql Server for Change Data Capture
```tsql
select
    name,
    is_tracked_by_cdc
from sys.tables;
```

### If SqlServer edition is lesser than 2016 then Upgrade compatibility level to allow inbuilt functions such as StringSplit

```tsql
ALTER DATABASE nbs_odse SET COMPATIBILITY_LEVEL = 130;
```

### For Azure managed SqlServer Instance only 
Sql Server agent run status is not exposed hence it needs to be mimicked 

```tsql
use nbs_odse;
CREATE or alter FUNCTION dbo.IsSqlAgentRunning()
RETURNS BIT
AS
BEGIN
DECLARE @IsRunning BIT = 1;

    RETURN @IsRunning;

END;
```