
drop table if exists dbo.nrt_organization_key;

CREATE TABLE dbo.nrt_organization_key (
    d_organization_key bigint IDENTITY (1,1) NOT NULL,
    organization_uid   bigint                NULL
);

declare @max bigint;
select @max=max(organization_key)+1 from dbo.D_ORGANIZATION ;
select @max;
if @max IS NULL   --check when max is returned as null
  SET @max = 1
DBCC CHECKIDENT ('dbo.nrt_organization_key', RESEED, @max);