
drop table if exists dbo.nrt_ldf_group_key;

CREATE TABLE dbo.nrt_ldf_group_key (
	d_ldf_group_key bigint IDENTITY(1,1) NOT NULL,
	business_object_uid bigint NULL
);

declare @max bigint;
select @max=max(ldf_group_key)+1 from dbo.ldf_group;
select @max;
if @max IS NULL   --check when max is returned as null
  SET @max = 1
DBCC CHECKIDENT ('dbo.nrt_ldf_group_key', RESEED, @max);