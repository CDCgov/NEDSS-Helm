
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_page_case_answer' and xtype = 'U')
CREATE TABLE dbo.nrt_page_case_answer
(
    act_uid                bigint                                          NOT NULL,
    nbs_case_answer_uid    bigint                                          NOT NULL,
    nbs_ui_metadata_uid    bigint                                          NOT NULL,
    nbs_rdb_metadata_uid   bigint                                          NOT NULL,
    nbs_question_uid       bigint                                          NOT NULL,
    rdb_table_nm           varchar(30)                                     NULL,
    rdb_column_nm          varchar(30)                                     NULL,
    answer_txt             varchar(2000)                                   NULL,
    answer_group_seq_nbr   varchar(20)                                     NULL,
    investigation_form_cd  varchar(50)                                     NULL,
    unit_value             varchar(50)                                     NULL,
    question_identifier    varchar(50)                                     NULL,
    data_location          varchar(150)                                    NULL,
    question_label         varchar(300)                                    NULL,
    other_value_ind_cd     char(1)                                         NULL,
    unit_type_cd           varchar(20)                                     NULL,
    mask                   varchar(50)                                     NULL,
    data_type              varchar(20)                                     NULL,
    question_group_seq_nbr int                                             NULL,
    code_set_group_id      bigint                                          NULL,
    block_nm               varchar(30)                                     NULL,
    last_chg_time          datetime                                        NULL,
    record_status_cd       varchar(20)                                     NOT NULL,
    refresh_datetime       datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime           datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);
