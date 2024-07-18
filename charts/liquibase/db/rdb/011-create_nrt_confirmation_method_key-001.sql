
drop table if exists dbo.nrt_confirmation_method_key;

CREATE TABLE dbo.nrt_confirmation_method_key (
	d_confirmation_method_key bigint IDENTITY(1,1) NOT NULL,
	confirmation_method_cd varchar(50) NULL
);

declare @max bigint;
select @max=max(confirmation_method_key)+1 from dbo.confirmation_method;
select @max;
if @max IS NULL   --check when max is returned as null
  SET @max = 1
DBCC CHECKIDENT ('dbo.nrt_confirmation_method_key', RESEED, @max);
