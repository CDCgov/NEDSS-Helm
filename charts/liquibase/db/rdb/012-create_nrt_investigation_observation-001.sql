
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation_observation' and xtype = 'U')
CREATE TABLE dbo.nrt_investigation_observation (
    public_health_case_uid bigint                                          NULL,
    observation_id         bigint                                          NULL,
    refresh_datetime       datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime           datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);