CREATE OR ALTER PROCEDURE [dbo].[sp_nrt_notification_postprocessing] @notification_id_list nvarchar(max)
AS
BEGIN

    BEGIN TRY

        /* Logging */
        declare @rowcount bigint;
        declare @log_id bigint;
        insert into dbo.nrt_batch_log
        (
            procedure_name,
            param_id_list,
            status
        )
        Values
            ('sp_nrt_notification_postprocessing',
             @notification_id_list,
             'START'
            );
        set @log_id = @@IDENTITY;

        /* Temp notification table creation */
        SELECT nrt.notification_uid,
               nrt.notif_status AS NOTIFICATION_STATUS,
               nrt.notif_comments AS NOTIFICATION_COMMENTS,
               nk.d_notification_key AS NOTIFICATION_KEY,
               nrt.notif_local_id AS NOTIFICATION_LOCAL_ID,
               nrt.notif_add_user_id AS NOTIFICATION_SUBMITTED_BY,
               nrt.notif_last_chg_time AS NOTIFICATION_LAST_CHANGE_TIME
        INTO #temp_ntf_table
        FROM dbo.nrt_notifications nrt
        LEFT JOIN dbo.nrt_notification_key nk ON nrt.notification_uid = nk.notification_uid
        WHERE nrt.notification_uid in (SELECT value FROM STRING_SPLIT(@notification_id_list, ','));

        /* Temp notification_event table creation */
        SELECT nrt.notification_uid,
               p.PATIENT_KEY,
               drpt.DATE_KEY AS NOTIFICATION_SENT_DT_KEY,
               dsub.DATE_KEY AS NOTIFICATION_SUBMIT_DT_KEY,
               eve.NOTIFICATION_KEY AS NOTIFICATION_KEY,
               1 AS COUNT,
               inv.INVESTIGATION_KEY,
               cnd.CONDITION_KEY,
               dupd.DATE_KEY AS NOTIFICATION_UPD_DT_KEY
        INTO #temp_ntf_event_table
        FROM dbo.nrt_notifications nrt
        LEFT JOIN dbo.nrt_notification_key nk ON nrt.notification_uid = nk.notification_uid
        LEFT JOIN dbo.NOTIFICATION_EVENT eve ON eve.NOTIFICATION_KEY = nk.d_notification_key
        LEFT JOIN dbo.INVESTIGATION inv ON nrt.public_health_case_uid = inv.CASE_UID
        LEFT JOIN dbo.D_PATIENT p ON nrt.local_patient_uid = p.PATIENT_UID
        LEFT JOIN dbo.RDB_DATE drpt ON CAST(nrt.rpt_sent_time AS DATE) = drpt.DATE_MM_DD_YYYY
        LEFT JOIN dbo.RDB_DATE dsub ON CAST(nrt.notif_add_time AS DATE) = dsub.DATE_MM_DD_YYYY
        LEFT JOIN dbo.RDB_DATE dupd ON CAST(nrt.notif_last_chg_time AS DATE) = dupd.DATE_MM_DD_YYYY
        LEFT JOIN dbo.CONDITION cnd ON nrt.condition_cd = cnd.CONDITION_CD
        WHERE nrt.notification_uid in (SELECT value FROM STRING_SPLIT(@notification_id_list, ','));

        BEGIN TRANSACTION;

        /* Notification Update Operation */
        UPDATE dbo.NOTIFICATION
        SET NOTIFICATION_STATUS = ntf.NOTIFICATION_STATUS
           ,NOTIFICATION_COMMENTS = ntf.NOTIFICATION_COMMENTS
           ,NOTIFICATION_LOCAL_ID = ntf.NOTIFICATION_LOCAL_ID
           ,NOTIFICATION_SUBMITTED_BY = ntf.NOTIFICATION_SUBMITTED_BY
           ,NOTIFICATION_LAST_CHANGE_TIME = ntf.NOTIFICATION_LAST_CHANGE_TIME
        FROM #temp_ntf_table ntf
        INNER JOIN dbo.NOTIFICATION n ON ntf.NOTIFICATION_KEY = n.NOTIFICATION_KEY
            AND ntf.NOTIFICATION_KEY IS NOT NULL

        /* Logging */
        set @rowcount=@@rowcount
        if @rowcount > 0
            update dbo.nrt_batch_log
            set log_detail='Num of Notification keys updated: ' + cast(@rowcount as nvarchar(max))+ '.'
            where batch_id=@log_id;
        else
            update dbo.nrt_batch_log
            set log_detail='No Notification Updates.'
            where batch_id=@log_id;

        /* Notification_Event Update Operation */
        UPDATE dbo.NOTIFICATION_EVENT
        SET PATIENT_KEY = ntfe.PATIENT_KEY
           ,NOTIFICATION_SENT_DT_KEY = ntfe.NOTIFICATION_SENT_DT_KEY
           ,NOTIFICATION_SUBMIT_DT_KEY = ntfe.NOTIFICATION_SUBMIT_DT_KEY
           ,COUNT = ntfe.COUNT
           ,INVESTIGATION_KEY = ntfe.INVESTIGATION_KEY
           ,CONDITION_KEY = ntfe.CONDITION_KEY
           ,NOTIFICATION_UPD_DT_KEY = ntfe.NOTIFICATION_UPD_DT_KEY
        FROM #temp_ntf_event_table ntfe
                 INNER JOIN dbo.NOTIFICATION_EVENT ne ON ntfe.NOTIFICATION_KEY = ne.NOTIFICATION_KEY
            AND ntfe.NOTIFICATION_KEY IS NOT NULL

        /* Logging */
        set @rowcount=@@rowcount
        if @rowcount > 0
            update dbo.nrt_batch_log
            set log_detail='Num of Notification_Event keys updated: ' + cast(@rowcount as nvarchar(max))+ '.'
            where batch_id=@log_id;
        else
            update dbo.nrt_batch_log
            set log_detail='No Notification_Event Updates.'
            where batch_id=@log_id;

        /* Notification Insert Operation */
        -- delete from the key table to generate new keys for the resulting new data to be inserted
        -- delete from dbo.nrt_notification_key;
        insert into dbo.nrt_notification_key(notification_uid)
        select notification_uid from #temp_ntf_table where notification_key is null order by notification_uid;

        INSERT INTO dbo.NOTIFICATION
            (NOTIFICATION_STATUS
            ,NOTIFICATION_COMMENTS
            ,NOTIFICATION_KEY
            ,NOTIFICATION_LOCAL_ID
            ,NOTIFICATION_SUBMITTED_BY
            ,NOTIFICATION_LAST_CHANGE_TIME
            )
            SELECT ntf.NOTIFICATION_STATUS
                  ,ntf.NOTIFICATION_COMMENTS
                  ,k.d_notification_key
                  ,ntf.NOTIFICATION_LOCAL_ID
                  ,ntf.NOTIFICATION_SUBMITTED_BY
                  ,ntf.NOTIFICATION_LAST_CHANGE_TIME
            FROM #temp_ntf_table ntf
            JOIN dbo.nrt_notification_key k ON ntf.notification_uid = k.notification_uid
            WHERE ntf.NOTIFICATION_KEY IS NULL

        /* Logging */
        set @rowcount=@@rowcount
        if @rowcount > 0
            update dbo.nrt_batch_log
            set log_detail='Num of Notification keys inserted: ' + cast(@rowcount as nvarchar(max))+ '.'
            where batch_id=@log_id;
        else
            update dbo.nrt_batch_log
            set log_detail='No Notification Inserts.'
            where batch_id=@log_id;

        INSERT INTO dbo.NOTIFICATION_EVENT
            (PATIENT_KEY
            ,NOTIFICATION_SENT_DT_KEY
            ,NOTIFICATION_SUBMIT_DT_KEY
            ,NOTIFICATION_KEY
            ,COUNT
            ,INVESTIGATION_KEY
            ,CONDITION_KEY
            ,NOTIFICATION_UPD_DT_KEY
            )
            SELECT ntfe.PATIENT_KEY
                  ,ntfe.NOTIFICATION_SENT_DT_KEY
                  ,ntfe.NOTIFICATION_SUBMIT_DT_KEY
                  ,k.d_notification_key
                  ,ntfe.COUNT
                  ,ntfe.INVESTIGATION_KEY
                  ,ntfe.CONDITION_KEY
                  ,ntfe.NOTIFICATION_UPD_DT_KEY
            FROM #temp_ntf_event_table ntfe
            JOIN dbo.nrt_notification_key k ON ntfe.notification_uid = k.notification_uid
            WHERE ntfe.NOTIFICATION_KEY IS NULL

        /* Logging */
        set @rowcount=@@rowcount
        if @rowcount > 0
            update dbo.nrt_batch_log
            set log_detail='Num of Notification_Event keys inserted: ' + cast(@rowcount as nvarchar(max))+ '.'
            where batch_id=@log_id;
        else
            update dbo.nrt_batch_log
            set log_detail='No Notification_Event Inserts.'
            where batch_id=@log_id;

        select 'Success';
        update dbo.nrt_batch_log
        set
            batch_end_time=GETDATE(),
            status='COMPLETE'
        where batch_id=@log_id;

        COMMIT TRANSACTION;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

        /* Logging */
        update dbo.nrt_batch_log
        set batch_end_time=GETDATE(),
            status='ERROR',
            error_log=@ErrorMessage
        where batch_id = @log_id;

        RETURN @ErrorMessage;

    END CATCH
END;
