
drop table if exists dbo.nrt_notification_key;

CREATE TABLE dbo.nrt_notification_key (
    d_notification_key bigint IDENTITY (1,1) NOT NULL,
    notification_uid   bigint                NULL
);
declare @max bigint;
select @max=max(notification_key)+1 from dbo.NOTIFICATION ;
select @max;
if @max IS NULL   --check when max is returned as null
    SET @max = 1;
DBCC CHECKIDENT ('dbo.nrt_notification_key', RESEED, @max);
