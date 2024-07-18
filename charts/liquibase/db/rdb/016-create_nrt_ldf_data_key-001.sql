
drop table if exists dbo.nrt_ldf_data_key;
	
CREATE TABLE dbo.nrt_ldf_data_key(
    d_ldf_data_key      bigint IDENTITY (1,1) NOT NULL,
    d_ldf_group_key     bigint                NULL,
    business_object_uid bigint                NULL,
    ldf_uid             bigint                null
);
	
declare @max bigint;
select @max=max(ldf_data_key)+1 from dbo.ldf_data;
select @max;
if @max IS NULL   --check when max is returned as null
 SET @max = 1
DBCC CHECKIDENT ('dbo.nrt_ldf_data_key', RESEED, @max);