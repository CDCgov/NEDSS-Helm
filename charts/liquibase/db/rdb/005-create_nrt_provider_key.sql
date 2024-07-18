
drop table if exists dbo.nrt_provider_key;

CREATE TABLE dbo.nrt_provider_key (
    d_provider_key bigint IDENTITY (1,1) NOT NULL,
    provider_uid   bigint                NULL
);

declare @max bigint;
select @max=max(provider_key)+1 from dbo.d_provider;
select @max;
if @max IS NULL   --check when max is returned as null
  SET @max = 1
DBCC CHECKIDENT ('dbo.nrt_provider_key', RESEED, @max);