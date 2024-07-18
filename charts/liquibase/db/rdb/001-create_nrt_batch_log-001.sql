
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_batch_log' and xtype = 'U')
CREATE TABLE dbo.nrt_batch_log(
    batch_id          bigint IDENTITY(1,1) NOT NULL PRIMARY KEY,
    batch_start_time  datetime DEFAULT (getdate()) NULL,
    batch_end_time    datetime NULL,
    procedure_name    varchar(500) NULL,
    param_id_list     nvarchar(max) NULL,
    status            varchar(50) NULL,
    log_detail        nvarchar(max) NULL,
    error_log         nvarchar(max) NULL
);