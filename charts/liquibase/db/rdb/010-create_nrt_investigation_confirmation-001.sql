
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation_confirmation' and xtype = 'U')
CREATE TABLE dbo.nrt_investigation_confirmation
(
    public_health_case_uid       bigint                                          NULL,
    confirmation_method_cd       varchar(50)                                     NULL,
    confirmation_method_desc_txt varchar(150)                                    NULL,
    confirmation_method_time     datetime                                        NULL,
    refresh_datetime             datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime                 datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);
