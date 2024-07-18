
drop table if exists dbo.nrt_investigation_key;

CREATE TABLE dbo.nrt_investigation_key (
	d_investigation_key bigint IDENTITY(1,1) NOT NULL,
	case_uid bigint NULL
);

declare @max bigint;
select @max=max(INVESTIGATION_KEY)+1 from dbo.INVESTIGATION;
select @max;
if @max IS NULL   --check when max is returned as null
  SET @max = 1
DBCC CHECKIDENT ('dbo.nrt_investigation_key', RESEED, @max);