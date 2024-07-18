
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation' and xtype = 'U')
CREATE TABLE dbo.nrt_observation
(
    observation_uid            bigint                                          NOT NULL PRIMARY KEY,
    class_cd                   varchar(10)                                     NULL,
    mood_cd                    varchar(10)                                     NULL,
    act_uid                    bigint                                          NULL,
    cd_desc_text               varchar(1000)                                   NULL,
    record_status_cd           varchar(20)                                     NULL,
    jurisdiction_cd            varchar(20)                                     NULL,
    program_jurisdiction_oid   bigint                                          NULL,
    prog_area_cd               varchar(20)                                     NULL,
    pregnant_ind_cd            varchar(20)                                     NULL,
    local_id                   varchar(50)                                     NULL,
    activity_to_time           datetime                                        NULL,
    effective_from_time        datetime                                        NULL,
    rpt_to_state_time          datetime                                        NULL,
    electronic_ind             char(1)                                         NULL,
    version_ctrl_nbr           smallint                                        NOT NULL,
    ordering_person_id         bigint                                          NULL,
    patient_id                 bigint                                          NULL,
    result_observation_uid     bigint                                          NULL,
    author_organization_id     bigint                                          NULL,
    ordering_organization_id   bigint                                          NULL,
    performing_organization_id bigint                                          NULL,
    material_id                bigint                                          NULL,
    add_user_id                bigint                                          NULL,
    add_user_name              varchar(50)                                     NULL,
    add_time                   datetime                                        NULL,
    last_chg_user_id           bigint                                          NULL,
    last_chg_user_name         varchar(50)                                     NULL,
    last_chg_time              datetime                                        NULL,
    refresh_datetime           datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime               datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

