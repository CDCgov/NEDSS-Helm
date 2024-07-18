CREATE OR ALTER PROCEDURE dbo.sp_sld_investigation_repeat_postprocessing
    @Batch_id bigint,
    @phc_id bigint,
    @debug bit = 'false'
AS
BEGIN
    DECLARE @RowCount_no int;
    DECLARE @Proc_Step_no float= 0;
    DECLARE @Proc_Step_Name varchar(200)= '';
    DECLARE @batch_start_time datetime2(7)= NULL;
    DECLARE @batch_end_time datetime2(7)= NULL;

    BEGIN TRY

        SET @Proc_Step_no = 1;
        SET @Proc_Step_Name = 'SP_Start';


        BEGIN TRANSACTION;

        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
        VALUES( @batch_id, 'INVESTIGATION_REPEAT', 'SLD_INVESTIGATION_REPEAT', 'START', @Proc_Step_no, @Proc_Step_Name, 0 );



        COMMIT TRANSACTION;

        SELECT @batch_start_time = batch_start_dttm, @batch_end_time = batch_end_dttm
        FROM [dbo].[job_batch_log]
        WHERE type_code = 'MasterETL' AND
            status_type = 'start';

        BEGIN TRANSACTION;

        /* BEGIN - Check to see if there is an entry in job_batch_rebuild_log table to rebuild PB Repeating Questions dimension*/

        IF OBJECT_ID('job_batch_rebuild_log') IS NOT NULL
            BEGIN
                DECLARE @count int;
                SET @count =
                        (
                            SELECT COUNT(*)
                            FROM job_batch_rebuild_log
                            WHERE Status_Type = 'start' AND
                                type_code = 'PB_RPT_DIMENSION'
                        );
                IF(@count > 0)
                    BEGIN
                        SET @batch_start_time =
                                (
                                    SELECT MAX(batch_start_dttm)
                                    FROM job_batch_rebuild_log
                                    WHERE type_code = 'PB_RPT_DIMENSION' AND
                                        status_type = 'start'
                                );
                    END;
                UPDATE job_batch_rebuild_log
                SET batch_end_dttm = @batch_end_time, status_type = 'complete'
                WHERE type_code = 'PB_RPT_DIMENSION' AND
                    status_type = 'start';
            END;

        /* END - Check to see if there is an entry in job_batch_rebuild_log table to rebuild PB Repeating Questions dimension*/

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = 2;
        SET @Proc_Step_Name = ' Generating phc_uids_REPT';

        IF OBJECT_ID('#phc_uids_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #phc_uids_REPT;
            END;

        /*NRT integration: Removing batch time condition*/
        SELECT inv.PUBLIC_HEALTH_CASE_UID AS 'PAGE_CASE_UID', INVESTIGATION_FORM_CD, CD, LAST_CHG_TIME
        INTO #phc_uids_REPT
        FROM dbo.nrt_investigation as inv WITH(NOLOCK), NBS_SRTE.dbo.CONDITION_CODE WITH(NOLOCK)
        WHERE inv.public_health_case_uid = @phc_id
          AND CONDITION_CODE.CONDITION_CD = inv.CD
          AND INVESTIGATION_FORM_CD NOT IN( 'INV_FORM_BMDGAS', 'INV_FORM_BMDGBS', 'INV_FORM_BMDGEN', 'INV_FORM_BMDNM', 'INV_FORM_BMDSP', 'INV_FORM_GEN', 'INV_FORM_HEPA', 'INV_FORM_HEPBV', 'INV_FORM_HEPCV', 'INV_FORM_HEPGEN', 'INV_FORM_MEA', 'INV_FORM_PER', 'INV_FORM_RUB', 'INV_FORM_RVCT', 'INV_FORM_VAR' )

        if @debug = 'true'
            select * from #phc_uids_REPT;

        SELECT @RowCount_no = @@ROWCOUNT;

        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
        VALUES( @batch_id, 'INVESTIGATION_REPEAT', 'SLD_INVESTIGATION_REPEAT', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );



        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = 3;
        SET @Proc_Step_Name = ' Generating TEXT_METADATA_REPT';


        IF OBJECT_ID('#NBS_CASE_ANSWER_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #NBS_CASE_ANSWER_REPT;
            END;

        -- CREATE TABLE  NBS_CASE_ANSWER AS
        SELECT nrt_page.*
        INTO #NBS_CASE_ANSWER_REPT
        FROM dbo.nrt_page_case_answer AS nrt_page WITH(NOLOCK)
                 INNER JOIN
             #phc_uids_REPT AS inv
             ON inv.PAGE_CASE_UID = nrt_page.ACT_UID AND
                nrt_page.ANSWER_GROUP_SEQ_NBR IS NOT NULL
        WHERE nrt_page.ACT_UID = @phc_id
        --AND inv.INVESTIGATION_FORM_CD = nrt_page.INVESTIGATION_FORM_CD;


        if @debug = 'true'
            select * from #NBS_CASE_ANSWER_REPT;


        SELECT DISTINCT
            NBS_CASE_ANSWER_UID, nrt_page.ANSWER_GROUP_SEQ_NBR, CAST(REPLACE(ANSWER_TXT, CHAR(13) + CHAR(10), ' ') AS varchar(2000)) AS ANSWER_TXT, COALESCE(ACT_UID, 0) AS PAGE_CASE_UID_TEXT, nrt_page.RECORD_STATUS_CD,
            nrt_page.QUESTION_GROUP_SEQ_NBR, nrt_page.NBS_QUESTION_UID, nrt_page.CODE_SET_GROUP_ID, LTRIM(RTRIM(RDB_COLUMN_NM)) AS RDB_COLUMN_NM, nrt_page.INVESTIGATION_FORM_CD, nrt_page.BLOCK_NM, nrt_page.QUESTION_GROUP_SEQ_NBR AS QUESTION_GROUP_SEQ_NBR1
        INTO #TEXT_DATA_REPT
        FROM #NBS_CASE_ANSWER_REPT as nrt_page
                 INNER JOIN
             NBS_SRTE.dbo.CODE_VALUE_GENERAL AS CVG WITH(NOLOCK)
             ON UPPER(CVG.CODE) = UPPER(nrt_page.DATA_TYPE)
        WHERE nrt_page.ANSWER_GROUP_SEQ_NBR IS NOT NULL
          AND CVG.CODE_SET_NM = 'NBS_DATA_TYPE' AND
            CODE = 'TEXT' AND
            QUESTION_GROUP_SEQ_NBR IS NOT NULL
        ORDER BY NBS_QUESTION_UID;



        DECLARE @text_output_table_name varchar(500) = ''
        SET @text_output_table_name = '##TEXT_DATA_REPT_out_'+CAST(@Batch_id as varchar(50));

        EXEC ('IF OBJECT_ID(''tempdb..'+@text_output_table_name+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@text_output_table_name+';
		END;')


        DECLARE @columns nvarchar(max);
        DECLARE @sql nvarchar(max);

        SET @columns = N'';

        SELECT @columns+=N', p.' + QUOTENAME([RDB_COLUMN_NM])
        FROM
            (
                SELECT [RDB_COLUMN_NM]
                FROM #text_data_REPT AS p
                GROUP BY [RDB_COLUMN_NM]
            ) AS x;
        SET @sql = N'
				SELECT [PAGE_CASE_UID_text] as PAGE_CASE_UID_text,
				BLOCK_NM as BLOCK_NM_text, ANSWER_GROUP_SEQ_NBR as ANSWER_GROUP_SEQ_NBR_text, ' + STUFF(@columns, 1, 2, '') + ' into  '+@text_output_table_name +'  FROM (
				SELECT [PAGE_CASE_UID_text], BLOCK_NM, ANSWER_GROUP_SEQ_NBR, [answer_txt] , [RDB_COLUMN_NM]
					FROM #text_data_REPT
					where PAGE_CASE_UID_text > 0
					group by [PAGE_CASE_UID_text], BLOCK_NM, ANSWER_GROUP_SEQ_NBR, [answer_txt] , [RDB_COLUMN_NM]
						) AS j PIVOT (max(answer_txt) FOR [RDB_COLUMN_NM] in
						(' + STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '') + ')) AS p;';

        if @debug = 'true'
            PRINT @sql;

        EXEC sp_executesql @sql;
        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
        VALUES( @batch_id, 'INVESTIGATION_REPEAT', 'SLD_INVESTIGATION_REPEAT', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @Proc_Step_no = 4;
        SET @Proc_Step_Name = ' Generating CODED_TABLE_TEMP_REPT';


        IF OBJECT_ID('#CODED_TABLE_TEMP_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #CODED_TABLE_TEMP_REPT;
            END;


        SELECT DISTINCT
            NBS_CASE_ANSWER_UID, nrt_page.ANSWER_GROUP_SEQ_NBR, CAST(ANSWER_TXT AS varchar(2000)) AS ANSWER_TXT, ACT_UID AS 'PAGE_CASE_UID', nrt_page.RECORD_STATUS_CD, nrt_page.QUESTION_GROUP_SEQ_NBR, nrt_page.NBS_QUESTION_UID, nrt_page.CODE_SET_GROUP_ID, UPPER(LTRIM(RTRIM(nrt_page.RDB_COLUMN_NM))) AS RDB_COLUMN_NM, nrt_page.QUESTION_GROUP_SEQ_NBR AS QUESTION_GROUP_SEQ_NBR1, nrt_page.INVESTIGATION_FORM_CD, nrt_page.BLOCK_NM, nrt_page.OTHER_VALUE_IND_CD,
            CAST(NULL AS [varchar](30)) AS RDB_COLUMN_NM2, CAST(NULL AS [varchar](256)) AS ANSWER_OTH
        INTO #CODED_TABLE_TEMP_REPT
        FROM #NBS_CASE_ANSWER_REPT AS nrt_page
                 INNER JOIN
             NBS_SRTE.dbo.CODE_VALUE_GENERAL AS CVG WITH(NOLOCK)
             ON UPPER(CVG.CODE) = UPPER(nrt_page.DATA_TYPE)
        WHERE nrt_page.ANSWER_GROUP_SEQ_NBR IS NOT NULL AND
            CVG.CODE_SET_NM = 'NBS_DATA_TYPE' AND
            CODE = 'CODED' AND
            QUESTION_GROUP_SEQ_NBR IS NOT NULL
        ORDER BY ACT_UID;

        if @debug = 'true'
            select * from #CODED_TABLE_TEMP_REPT;


        UPDATE #coded_table_TEMP_REPT
        SET ANSWER_OTH = SUBSTRING(ANSWER_TXT, CHARINDEX('^', ANSWER_TXT) + 1, LEN(RTRIM(LTRIM(ANSWER_TXT))))
        WHERE CHARINDEX('^', ANSWER_TXT) > 0;

        UPDATE #coded_table_TEMP_REPT
        SET ANSWER_TXT = SUBSTRING(ANSWER_TXT, 1, ( CHARINDEX('^', ANSWER_TXT) - 1 ))
        WHERE CHARINDEX('^', ANSWER_TXT) > 0;

        UPDATE #coded_table_TEMP_REPT
        SET RDB_COLUMN_NM2 = SUBSTRING(RDB_COLUMN_NM, 1, 22)
        WHERE OTHER_VALUE_IND_CD = 'T';

        UPDATE #coded_table_TEMP_REPT
        SET ANSWER_TXT = 'OTH'
        WHERE UPPER(ANSWER_TXT) LIKE 'OTH^%';

        IF OBJECT_ID('#CODED_TABLE_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #CODED_TABLE_REPT;
            END;

        -- CREATE TABLE 	CODED_TABLE AS
        SELECT DISTINCT
            ANSWER_GROUP_SEQ_NBR, CODED.CODE_SET_GROUP_ID, PAGE_CASE_UID, NBS_QUESTION_UID, NBS_CASE_ANSWER_UID, CAST(ANSWER_TXT AS varchar(2000)) AS ANSWER_TXT, CVG.CODE_SET_NM, RDB_COLUMN_NM, ANSWER_OTH, RDB_COLUMN_NM2, CODE, CODE_SHORT_DESC_TXT AS 'ANSWER_TXT1', INVESTIGATION_FORM_CD, BLOCK_NM, OTHER_VALUE_IND_CD
        INTO #CODED_TABLE_REPT
        FROM #CODED_TABLE_TEMP_REPT AS CODED LEFT
                                                 JOIN
             NBS_SRTE.dbo.CODESET_GROUP_METADATA AS METADATA
             ON METADATA.CODE_SET_GROUP_ID = CODED.CODE_SET_GROUP_ID LEFT
                                                 JOIN
             NBS_SRTE.dbo.CODE_VALUE_GENERAL AS CVG
             ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM AND
                CVG.CODE = CODED.ANSWER_TXT;
        /*
        CREATE NONCLUSTERED INDEX [RDB_PERF_INTERNAL_01]
ON #CODED_TABLE_REPT
        ( [CODE_SET_GROUP_ID]
        )
               INCLUDE( [ANSWER_GROUP_SEQ_NBR], [PAGE_CASE_UID], [NBS_QUESTION_UID], [NBS_CASE_ANSWER_UID], [ANSWER_TXT], [RDB_COLUMN_NM], [ANSWER_OTH], [RDB_COLUMN_NM2], [INVESTIGATION_FORM_CD], [BLOCK_NM] );

        */
        IF OBJECT_ID('#CODED_TABLE_DESC_REPT_TEMP', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #CODED_TABLE_DESC_REPT_TEMP;
            END;


        SELECT p1.PAGE_CASE_UID, p1.ANSWER_GROUP_SEQ_NBR, p1.NBS_QUESTION_UID, STUFF(
                (
                    SELECT TOP 10 ' | ' + ANSWER_TXT1
                    FROM #CODED_TABLE_REPT AS p2
                    WHERE p2.PAGE_CASE_UID = p1.PAGE_CASE_UID AND
                        p2.nbs_question_uid = p1.NBS_QUESTION_UID AND
                        p2.ANSWER_GROUP_SEQ_NBR = p1.ANSWER_GROUP_SEQ_NBR AND
                        p2.ANSWER_GROUP_SEQ_NBR = p1.ANSWER_GROUP_SEQ_NBR
                    ORDER BY PAGE_CASE_UID, ANSWER_GROUP_SEQ_NBR, NBS_QUESTION_UID, NBS_CASE_ANSWER_UID DESC FOR XML PATH(''), TYPE
                ).value( '.', 'varchar(2000)' ), 1, 3, '') AS ANSWER_DESC11
        INTO #CODED_TABLE_DESC_REPT_TEMP
        FROM #CODED_TABLE_REPT AS p1
        --where  nbs_question_uid is not null
        GROUP BY PAGE_CASE_UID, RDB_COLUMN_NM, NBS_QUESTION_UID, ANSWER_GROUP_SEQ_NBR;

        IF OBJECT_ID('#CODED_TABLE_DESC_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #CODED_TABLE_DESC_REPT;
            END;

        SELECT ct.*, COALESCE(ctt.answer_desc11, ct.answer_txt1) AS answer_desc11
        INTO #CODED_TABLE_DESC_REPT
        FROM #CODED_TABLE_REPT AS ct LEFT
                                         OUTER JOIN
             #CODED_TABLE_DESC_REPT_TEMP AS ctt
             ON ct.PAGE_CASE_UID = ctt.PAGE_CASE_UID AND
                ct.NBS_QUESTION_UID = ctt.NBS_QUESTION_UID AND
                ct.ANSWER_GROUP_SEQ_NBR = ctt.ANSWER_GROUP_SEQ_NBR;

        if @debug = 'true'
            select * from #CODED_TABLE_DESC_REPT;

        IF OBJECT_ID('#CODED_COUNTY_TABLE_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #CODED_COUNTY_TABLE_REPT;
            END;

        SELECT ANSWER_GROUP_SEQ_NBR, CODED.CODE_SET_GROUP_ID, PAGE_CASE_UID, NBS_QUESTION_UID, NBS_CASE_ANSWER_UID, CAST(ANSWER_TXT AS varchar(2000)) AS ANSWER_TXT, CVG.CODE_SET_NM, RDB_COLUMN_NM, ANSWER_OTH, RDB_COLUMN_NM2, CVG.CODE, CODE_SHORT_DESC_TXT AS 'ANSWER_TXT1', INVESTIGATION_FORM_CD, BLOCK_NM
        INTO #CODED_COUNTY_TABLE_REPT
        FROM #CODED_TABLE_REPT AS CODED WITH(NOLOCK) LEFT
                                                         JOIN
             NBS_SRTE.dbo.CODESET_GROUP_METADATA AS METADATA WITH(NOLOCK)
             ON METADATA.CODE_SET_GROUP_ID = CODED.CODE_SET_GROUP_ID LEFT
                                                         JOIN
             NBS_SRTE.dbo.V_STATE_COUNTY_CODE_VALUE AS CVG WITH(NOLOCK)
             ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM AND
                CVG.CODE = CODED.ANSWER_TXT
        WHERE METADATA.CODE_SET_NM = 'COUNTY_CCD';

        IF OBJECT_ID('#CODED_COUNTY_TABLE_DESC_REPT_TEMP', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #CODED_COUNTY_TABLE_DESC_REPT_TEMP;
            END;

        SELECT p1.PAGE_CASE_UID, p1.ANSWER_GROUP_SEQ_NBR, p1.NBS_QUESTION_UID, STUFF(
                (
                    SELECT TOP 10 ' |' + ANSWER_TXT1
                    FROM #CODED_COUNTY_TABLE_REPT AS p2
                    WHERE p2.PAGE_CASE_UID = p1.PAGE_CASE_UID AND
                        p2.nbs_question_uid = p1.NBS_QUESTION_UID AND
                        p2.ANSWER_GROUP_SEQ_NBR = p1.ANSWER_GROUP_SEQ_NBR
                    ORDER BY PAGE_CASE_UID, ANSWER_GROUP_SEQ_NBR, NBS_QUESTION_UID, NBS_CASE_ANSWER_UID DESC FOR XML PATH(''), TYPE
                ).value( '.', 'varchar(2000)' ), 1, 2, '') AS ANSWER_DESC11
        INTO #CODED_COUNTY_TABLE_DESC_REPT_TEMP
        FROM #CODED_COUNTY_TABLE_REPT AS p1
        GROUP BY PAGE_CASE_UID, ANSWER_GROUP_SEQ_NBR, NBS_QUESTION_UID;

        IF OBJECT_ID('#CODED_COUNTY_TABLE_DESC_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #CODED_COUNTY_TABLE_DESC_REPT;
            END;

        SELECT cct.*, CAST(NULL AS char(1)) AS OTHER_VALUE_IND_CD, cctt.answer_desc11
        INTO #CODED_COUNTY_TABLE_DESC_REPT
        FROM #CODED_COUNTY_TABLE_REPT AS cct LEFT
                                                 OUTER JOIN
             #CODED_COUNTY_TABLE_DESC_REPT_TEMP AS cctt
             ON cct.PAGE_CASE_UID = cctt.PAGE_CASE_UID AND
                cct.ANSWER_GROUP_SEQ_NBR = cctt.ANSWER_GROUP_SEQ_NBR AND
                cct.NBS_QUESTION_UID = cctt.NBS_QUESTION_UID;

        IF OBJECT_ID('#CODED_TABLE_OTH_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #CODED_TABLE_OTH_REPT;
            END;

        -- CREATE TABLE  CODED_TABLE_OTH_REPT AS
        SELECT *, CAST(NULL AS [varchar](2000)) AS ANSWER_DESC11
        INTO #CODED_TABLE_OTH_REPT
        FROM #CODED_TABLE_REPT
        WHERE OTHER_VALUE_IND_CD = 'T';

        UPDATE #CODED_TABLE_OTH_REPT
        SET ANSWER_TXT = '', PAGE_CASE_UID = '', NBS_CASE_ANSWER_UID = ''
        WHERE ANSWER_TXT NOT LIKE 'OTH%';

        --DATA CODED_TABLE_OTH;
        UPDATE #CODED_TABLE_OTH_REPT
        SET RDB_COLUMN_NM = RTRIM(LTRIM(RDB_COLUMN_NM2)) + '_OTH';

        UPDATE #CODED_TABLE_OTH_REPT
        SET ANSWER_TXT = 'OTH'
        WHERE UPPER(ANSWER_TXT) LIKE 'OTH%';

        UPDATE #CODED_TABLE_OTH_REPT
        SET ANSWER_DESC11 = ANSWER_OTH
        WHERE(LEN(LTRIM(RTRIM(RDB_COLUMN_NM2))) > 0);

        --- ************************************************



        IF OBJECT_ID('#CODED_TABLE_SNTEMP_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #CODED_TABLE_SNTEMP_REPT;
            END;

        --CREATE TABLE  CODED_TABLE_SNTEMP AS
        SELECT NBS_CASE_ANSWER_UID, ANSWER_GROUP_SEQ_NBR, nrt_page.CODE_SET_GROUP_ID, RDB_COLUMN_NM, CAST(ANSWER_TXT AS varchar(2000)) AS ANSWER_TXT, ACT_UID AS 'PAGE_CASE_UID', nrt_page.RECORD_STATUS_CD, nrt_page.NBS_QUESTION_UID, nrt_page.INVESTIGATION_FORM_CD, nrt_page.BLOCK_NM, UNIT_TYPE_CD, CAST(NULL AS [varchar](100)) AS ANSWER_TXT_CODE, CAST(NULL AS [varchar](256)) AS ANSWER_VALUE
        INTO #CODED_TABLE_SNTEMP_REPT
        FROM #NBS_CASE_ANSWER_REPT AS nrt_page
                 INNER JOIN
             NBS_SRTE.dbo.CODE_VALUE_GENERAL AS CVG WITH(NOLOCK)
             ON UPPER(CVG.CODE) = UPPER(nrt_page.DATA_TYPE)
                 INNER JOIN #phc_uids_REPT phc
                            ON phc.PAGE_CASE_UID = nrt_page.act_uid
        WHERE QUESTION_GROUP_SEQ_NBR IS NOT NULL AND
            ( UPPER(DATA_TYPE) = 'NUMERIC' AND
              UPPER(unit_type_cd) = 'CODED'
                )
          AND CVG.CODE_SET_NM = 'NBS_DATA_TYPE'
          AND (nrt_page.investigation_form_cd IS NULL
            )
          AND QUESTION_GROUP_SEQ_NBR IS NOT NULL
          AND --revisit
            ( phc.LAST_CHG_TIME <= nrt_page.last_chg_time OR
              nrt_page.act_uid IS NULL
                );

        UPDATE #CODED_TABLE_SNTEMP_REPT
        SET ANSWER_TXT_CODE = SUBSTRING(ANSWER_TXT, CHARINDEX('^', ANSWER_TXT) + 1, LEN(RTRIM(ANSWER_TXT))), ANSWER_VALUE = REPLACE(SUBSTRING(ANSWER_TXT, 1, ( CHARINDEX('^', ANSWER_TXT) - 1 )), ',', '')
        WHERE CHARINDEX('^', ANSWER_TXT) > 0;

        UPDATE #CODED_TABLE_SNTEMP_REPT
        SET ANSWER_VALUE = ANSWER_TXT
        WHERE CHARINDEX('^', ANSWER_TXT) = 0;

        if @debug = 'true'
            select * from #CODED_TABLE_SNTEMP_REPT;

        IF OBJECT_ID('#CODED_TABLE_SNTEMP_TRANS_A_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #CODED_TABLE_SNTEMP_TRANS_A_REPT;
            END;

        --CREATE TABLE 	CODED_TABLE_SNTEMP_TRANS_A AS
        SELECT CODED.CODE_SET_GROUP_ID, PAGE_CASE_UID, ANSWER_TXT_CODE, ANSWER_VALUE, NBS_CASE_ANSWER_UID, CVG.CODE_SET_NM, RDB_COLUMN_NM, CVG.CODE, CODE_SHORT_DESC_TXT AS ANSWER_TXT2, INVESTIGATION_FORM_CD, BLOCK_NM, ANSWER_GROUP_SEQ_NBR, UNIT_TYPE_CD, CAST(NULL AS varchar(100)) AS ANSWER_DESC11
        INTO #CODED_TABLE_SNTEMP_TRANS_A_REPT
        FROM #CODED_TABLE_SNTEMP_REPT AS CODED LEFT
                                                   JOIN
             NBS_SRTE.dbo.CODESET_GROUP_METADATA AS METADATA
             ON METADATA.CODE_SET_GROUP_ID = CODED.CODE_SET_GROUP_ID LEFT
                                                   JOIN
             NBS_SRTE.dbo.CODE_VALUE_GENERAL AS CVG
             ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM AND
                CVG.CODE = CODED.ANSWER_TXT_CODE
        ORDER BY NBS_CASE_ANSWER_UID, RDB_COLUMN_NM;


        UPDATE #CODED_TABLE_SNTEMP_TRANS_A_REPT
        SET ANSWER_DESC11 = LTRIM(RTRIM(ANSWER_VALUE))
        WHERE LEN(UNIT_TYPE_CD) > 0 AND
            UPPER(UNIT_TYPE_CD) = 'CODED' AND
            isNumeric(ANSWER_VALUE) = 1
        ;


        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
        VALUES( @batch_id, 'INVESTIGATION_REPEAT', 'SLD_INVESTIGATION_REPEAT', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;
        BEGIN

            SET @Proc_Step_no = 5;
            SET @Proc_Step_Name = ' LOG Invalid Numeric data INTO ETL_DQ_LOG';

            INSERT INTO dbo.ETL_DQ_LOG( EVENT_TYPE, EVENT_LOCAL_ID, EVENT_UID, DQ_ISSUE_CD, DQ_ISSUE_DESC_TXT, DQ_ISSUE_QUESTION_IDENTIFIER, DQ_ISSUE_ANSWER_TXT, DQ_ISSUE_RDB_LOCATION, JOB_BATCH_LOG_UID, DQ_ETL_PROCESS_TABLE, DQ_ETL_PROCESS_COLUMN, DQ_STATUS_TIME, DQ_ISSUE_SOURCE_LOCATION, DQ_ISSUE_SOURCE_QUESTION_LABEL )
                (
                    SELECT distinct 'INVESTIGATION', inv.LOCAL_ID, inv.public_health_case_uid,
                                    'INVALID_NUMERIC_VALUE', 'BAD NUMERIC VALUE: A non-numeric value exists in a field expecting a numeric value and requires update. Please correct the bad numeric value so that it can be properly written to the reporting database during the next ETL run',
                                    nrt_page.QUESTION_IDENTIFIER, ANSWER_VALUE, nrt_page.DATA_LOCATION,
                                    @Batch_id, nrt_page.rdb_table_nm, nrt_page.RDB_COLUMN_NM,
                                    GETDATE(), nrt_page.DATA_LOCATION, nrt_page.QUESTION_LABEL
                    FROM #CODED_TABLE_SNTEMP_REPT as rept WITH(NOLOCK)
                             INNER JOIN dbo.nrt_investigation as inv WITH(NOLOCK)
                                        ON inv.public_health_case_uid = rept.page_case_uid
                             INNER JOIN dbo.nrt_page_case_answer as nrt_page WITH(NOLOCK)
                                        ON nrt_page.act_uid = inv.public_health_case_uid
                    WHERE nrt_page.act_uid = @phc_id
                      AND (isNumeric(ANSWER_VALUE) != 1)
                      AND ltrim(rtrim(ANSWER_VALUE))<>''
                      AND nrt_page.QUESTION_GROUP_SEQ_NBR IS NOT NULL
                );


            SELECT @RowCount_no = @@ROWCOUNT;
            INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
            VALUES( @Batch_id, 'INVESTIGATION_REPEAT', 'SLD_INVESTIGATION_REPEAT', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

        END

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;

        DECLARE @coded_output_table_name varchar(500) = ''
        SET @Proc_Step_no = 6;
        SET @coded_output_table_name = '##CODED_DATA_INV_CAT_out_'+CAST(@Batch_id as varchar(50));
        SET @Proc_Step_Name = ' Generating '+@coded_output_table_name;


        IF OBJECT_ID('#CODED_TABLE_SNTEMP_TRANS_CODE_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #CODED_TABLE_SNTEMP_TRANS_CODE_REPT;
            END;

        SELECT *
        INTO #CODED_TABLE_SNTEMP_TRANS_CODE_REPT
        FROM #CODED_TABLE_SNTEMP_TRANS_A_REPT where (isNumeric(ANSWER_VALUE) = 1) OR ANSWER_VALUE is null;

        UPDATE #CODED_TABLE_SNTEMP_TRANS_CODE_REPT
        SET RDB_COLUMN_NM = REPLACE(SUBSTRING(RDB_COLUMN_NM, 1, 21) + '_UNIT', ' ', ''), ANSWER_DESC11 = LTRIM(RTRIM(ANSWER_TXT2))
        WHERE LEN(UNIT_TYPE_CD) > 0 AND
            UPPER(UNIT_TYPE_CD) = 'CODED';

        IF OBJECT_ID('#CODED_TABLE_SNTEMP_TRANS_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #CODED_TABLE_SNTEMP_TRANS_REPT;
            END;
        SELECT *
        INTO #CODED_TABLE_SNTEMP_TRANS_REPT
        FROM #CODED_TABLE_SNTEMP_TRANS_A_REPT
        UNION
        SELECT *
        FROM #CODED_TABLE_SNTEMP_TRANS_CODE_REPT;

        ALTER TABLE #CODED_TABLE_SNTEMP_TRANS_REPT
            ADD [NBS_QUESTION_UID] [bigint] NULL, [ANSWER_TXT] [varchar](100) NULL, [ANSWER_OTH] [varchar](256) NULL, [RDB_COLUMN_NM2] [varchar](30) NULL, [ANSWER_TXT1] [varchar](100) NULL, [OTHER_VALUE_IND_CD] [char](1) NULL;

        IF OBJECT_ID('#CODED_TABLE_MERGED_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #CODED_TABLE_MERGED_REPT;
            END;
        SELECT *
        INTO #CODED_TABLE_MERGED_REPT
        FROM #CODED_TABLE_DESC_REPT
        UNION
        SELECT *
        FROM #CODED_TABLE_OTH_REPT
        UNION
        SELECT *
        FROM #CODED_COUNTY_TABLE_DESC_REPT
        UNION
        SELECT [ANSWER_GROUP_SEQ_NBR], [CODE_SET_GROUP_ID], [PAGE_CASE_UID], [NBS_QUESTION_UID], [NBS_CASE_ANSWER_UID], [ANSWER_TXT], [CODE_SET_NM], [RDB_COLUMN_NM], [ANSWER_OTH], [RDB_COLUMN_NM2], [CODE], [ANSWER_TXT1], [INVESTIGATION_FORM_CD], [BLOCK_NM], [OTHER_VALUE_IND_CD], [ANSWER_DESC11]
        FROM #CODED_TABLE_SNTEMP_TRANS_REPT;

        if @debug = 'true'
            select * from #CODED_TABLE_MERGED_REPT;

        IF OBJECT_ID('#CODED_DATA_REPT_OUT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #CODED_DATA_REPT_OUT;
            END;

        SET @columns = N'';

        SELECT @columns+=N', p.' + QUOTENAME(RTRIM([RDB_COLUMN_NM]))
        FROM
            (
                SELECT [RDB_COLUMN_NM]
                FROM #CODED_TABLE_MERGED_REPT AS p
                GROUP BY [RDB_COLUMN_NM]
            ) AS x;
        SET @sql = N'
							SELECT [PAGE_CASE_UID] as PAGE_CASE_UID_coded,
							BLOCK_NM as BLOCK_NM_coded, ANSWER_GROUP_SEQ_NBR as ANSWER_GROUP_SEQ_NBR_coded,' + STUFF(@columns, 1, 2, '') + ' into '+ @coded_output_table_name +' FROM (
							SELECT [PAGE_CASE_UID], BLOCK_NM, ANSWER_GROUP_SEQ_NBR, [ANSWER_DESC11] , [RDB_COLUMN_NM]
								FROM #CODED_TABLE_MERGED_REPT
								where PAGE_CASE_UID > 0
								group by
								PAGE_CASE_UID, BLOCK_NM, ANSWER_GROUP_SEQ_NBR, [ANSWER_DESC11] , [RDB_COLUMN_NM]
									) AS j PIVOT (max(ANSWER_DESC11) FOR [RDB_COLUMN_NM] in
									(' + STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '') + ')) AS p;';


        EXEC sp_executesql @sql;

        if @debug = 'true'
            PRINT  @coded_output_table_name;

        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
        VALUES( @batch_id, 'INVESTIGATION_REPEAT', 'SLD_INVESTIGATION_REPEAT', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        DECLARE @date_output_table_name varchar(500) = ''
        SET @Proc_Step_no = 7;
        SET @date_output_table_name = '##date_data_INV_out_'+CAST(@Batch_id as varchar(50));
        SET @Proc_Step_Name = ' Generating '+@date_output_table_name;


        --CREATE TABLE  	DATE_DATA AS
        /*
        IF OBJECT_ID('#DATE_DATA_REPT', 'U') IS NOT NULL
        BEGIN
            DROP TABLE #DATE_DATA_REPT;
        END;
        */

        SELECT DISTINCT
            NBS_CASE_ANSWER_UID, nrt_page.ANSWER_GROUP_SEQ_NBR, ( CASE
                                                                      WHEN ISDATE(ANSWER_TXT) = 1 THEN( FORMAT(CAST([ANSWER_TXT] AS date), 'MM/dd/yy') + ' 00:00:00' )
                                                                      ELSE NULL
            END ) AS ANSWER_TXT1, ACT_UID AS 'PAGE_CASE_UID', nrt_page.RECORD_STATUS_CD,
            nrt_page.QUESTION_GROUP_SEQ_NBR, nrt_page.NBS_QUESTION_UID, nrt_page.CODE_SET_GROUP_ID, UPPER(RTRIM(LTRIM(nrt_page.RDB_COLUMN_NM))) AS RDB_COLUMN_NM, nrt_page.INVESTIGATION_FORM_CD, nrt_page.BLOCK_NM, nrt_page.QUESTION_GROUP_SEQ_NBR AS QUESTION_GROUP_SEQ_NBR1
        INTO #DATE_DATA_REPT
        FROM #NBS_CASE_ANSWER_REPT as nrt_page
                 INNER JOIN
             NBS_SRTE.dbo.CODE_VALUE_GENERAL AS CVG WITH(NOLOCK)
             ON UPPER(CVG.CODE) = UPPER(nrt_page.DATA_TYPE)
        WHERE
            CVG.CODE_SET_NM = 'NBS_DATA_TYPE' AND
            CODE IN( 'DATETIME', 'DATE' ) AND
            QUESTION_GROUP_SEQ_NBR IS NOT NULL
        ORDER BY ACT_UID;

        if @debug = 'true'
            select * from #DATE_DATA_REPT;



        INSERT INTO dbo.ETL_DQ_LOG( EVENT_TYPE, EVENT_LOCAL_ID, EVENT_UID, DQ_ISSUE_CD, DQ_ISSUE_DESC_TXT, DQ_ISSUE_QUESTION_IDENTIFIER, DQ_ISSUE_ANSWER_TXT, DQ_ISSUE_RDB_LOCATION, JOB_BATCH_LOG_UID, DQ_ETL_PROCESS_TABLE, DQ_ETL_PROCESS_COLUMN, DQ_STATUS_TIME, DQ_ISSUE_SOURCE_LOCATION, DQ_ISSUE_SOURCE_QUESTION_LABEL )
            (
                SELECT 'INVESTIGATION', inv.LOCAL_ID, PUBLIC_HEALTH_CASE_UID, 'INVALID_DATE', 'BAD DATE: A poorly formatted date exists and requires update. Please correct the bad date so that it can be properly written to the reporting database during the next ETL run.',
                       nrt_page.QUESTION_IDENTIFIER, ANSWER_TXT, nrt_page.DATA_LOCATION, @Batch_id, nrt_page.rdb_table_nm, nrt_page.RDB_COLUMN_NM, GETDATE(), nrt_page.DATA_LOCATION, QUESTION_LABEL
                FROM dbo.nrt_page_case_answer as nrt_page
                         INNER JOIN
                     dbo.nrt_investigation as inv
                     ON nrt_page.ACT_UID = inv.PUBLIC_HEALTH_CASE_UID
                         INNER JOIN
                     NBS_SRTE.DBO.CONDITION_CODE
                     ON CONDITION_CODE.CONDITION_CD = inv.CD
                WHERE
                    nrt_page.act_uid = @phc_id
                  AND DATA_TYPE IN( 'Date/Time', 'Date', 'DATETIME', 'DATE' ) AND
                    (ISDATE(ANSWER_TXT) != 1) AND
                    UPPER(nrt_page.DATA_LOCATION) = 'NBS_CASE_ANSWER.ANSWER_TXT' AND
                    ANSWER_TXT IS NOT NULL AND
                    nrt_page.rdb_table_nm = 'D_INVESTIGATION_REPEAT'
            );



        IF OBJECT_ID('#PAGE_DATE_TABLE_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #PAGE_DATE_TABLE_REPT;
            END;

        CREATE TABLE #PAGE_DATE_TABLE_REPT
        (
            NBS_CASE_ANSWER_UID bigint, CODE_SET_GROUP_ID bigint, RDB_COLUMN_NM char(40), INVESTIGATION_FORM_CD char(250), BLOCK_NM char(30), ANSWER_TXT1 date, PAGE_CASE_UID bigint, LAST_CHG_TIME date, RECORD_STATUS_CD char(40), ANSWER_GROUP_SEQ_NBR bigint, NBS_QUESTION_UID bigint
        );


        INSERT INTO #PAGE_DATE_TABLE_REPT( NBS_CASE_ANSWER_UID, CODE_SET_GROUP_ID, RDB_COLUMN_NM, INVESTIGATION_FORM_CD, BLOCK_NM, ANSWER_TXT1, PAGE_CASE_UID,
            --	LAST_CHG_TIME ,
                                           RECORD_STATUS_CD, ANSWER_GROUP_SEQ_NBR, NBS_QUESTION_UID )
        SELECT NBS_CASE_ANSWER_UID, CODE_SET_GROUP_ID, RDB_COLUMN_NM, INVESTIGATION_FORM_CD, BLOCK_NM, ANSWER_TXT1, PAGE_CASE_UID,
               --	LAST_CHG_TIME ,
               RECORD_STATUS_CD, ANSWER_GROUP_SEQ_NBR, NBS_QUESTION_UID
        FROM #DATE_DATA_REPT;



        CREATE NONCLUSTERED INDEX [RDB_PERF_INTERNAL_03]
            ON #PAGE_DATE_TABLE_REPT
                ( [PAGE_CASE_UID]
                    )
            INCLUDE( [RDB_COLUMN_NM], [BLOCK_NM], [ANSWER_TXT1], [ANSWER_GROUP_SEQ_NBR] );


        EXEC ('IF OBJECT_ID(''tempdb..'+@date_output_table_name+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@date_output_table_name+';
		END;')


        SET @columns = N'';

        SELECT @columns+=N', p.' + QUOTENAME(RTRIM([RDB_COLUMN_NM]))
        FROM
            (
                SELECT [RDB_COLUMN_NM]
                FROM #PAGE_DATE_TABLE_REPT AS p
                GROUP BY [RDB_COLUMN_NM]
            ) AS x;
        SET @sql = N'
									SELECT [PAGE_CASE_UID] as PAGE_CASE_UID_date,
									BLOCK_NM as BLOCK_NM_date, ANSWER_GROUP_SEQ_NBR as ANSWER_GROUP_SEQ_NBR_date,' + STUFF(@columns, 1, 2, '') + ' into '+@date_output_table_name + ' FROM (
									SELECT [PAGE_CASE_UID], BLOCK_NM, ANSWER_GROUP_SEQ_NBR, [answer_txt1] , [RDB_COLUMN_NM]
										FROM #PAGE_DATE_TABLE_REPT
										where PAGE_CASE_UID > 0
										group by  PAGE_CASE_UID, BLOCK_NM, ANSWER_GROUP_SEQ_NBR, [answer_txt1] , [RDB_COLUMN_NM]
											) AS j PIVOT (max(answer_txt1) FOR [RDB_COLUMN_NM] in
											(' + STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '') + ')) AS p;';

        EXEC sp_executesql @sql;

        if @debug = 'true'
            PRINT @sql;

        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
        VALUES( @batch_id, 'INVESTIGATION_REPEAT', 'SLD_INVESTIGATION_REPEAT', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @Proc_Step_no = 8;
        SET @Proc_Step_Name = 'Begin Numeric Section';


        /*** NUMERIC SECTION******/


        --CREATE TABLE NUMERIC_BASE_DATA AS

        IF OBJECT_ID('#NUMERIC_BASE_DATA_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #NUMERIC_BASE_DATA_REPT;
            END;


        SELECT DISTINCT
            NBS_CASE_ANSWER_UID, nrt_page.ANSWER_GROUP_SEQ_NBR, ANSWER_TXT, ACT_UID AS 'PAGE_CASE_UID', nrt_page.RECORD_STATUS_CD,
            nrt_page.QUESTION_GROUP_SEQ_NBR, nrt_page.NBS_QUESTION_UID, nrt_page.UNIT_VALUE AS 'CODE_SET_GROUP_ID', UPPER(LTRIM(RTRIM(nrt_page.RDB_COLUMN_NM))) AS RDB_COLUMN_NM, nrt_page.INVESTIGATION_FORM_CD, nrt_page.BLOCK_NM, nrt_page.QUESTION_GROUP_SEQ_NBR AS QUESTION_GROUP_SEQ_NBR1,
            LEN(RTRIM(ANSWER_TXT)) AS TXT_LEN, CAST(NULL AS [varchar](100)) AS ANSWER_UNIT, CAST(NULL AS int) AS LENCODED, CAST(NULL AS [varchar](100)) AS ANSWER_CODED, CAST(NULL AS [varchar](100)) AS UNIT_VALUE1, CAST(NULL AS [varchar](30)) AS RDB_COLUMN_NM2
        INTO #NUMERIC_BASE_DATA_REPT
        FROM #NBS_CASE_ANSWER_REPT as nrt_page
                 INNER JOIN
             NBS_SRTE.dbo.CODE_VALUE_GENERAL AS CVG WITH(NOLOCK)
             ON UPPER(CVG.CODE) = UPPER(nrt_page.DATA_TYPE)
        WHERE ANSWER_GROUP_SEQ_NBR IS NOT NULL
          AND CVG.CODE_SET_NM = 'NBS_DATA_TYPE'
          AND CODE = 'NUMERIC' AND
            ( UNIT_TYPE_CD IS NULL OR
              UNIT_TYPE_CD = 'LITERAL'
                ) AND
            QUESTION_GROUP_SEQ_NBR IS NOT NULL;


        IF OBJECT_ID('#NUMERIC_DATA1_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #NUMERIC_DATA1_REPT;
            END;

        SELECT *
        INTO #NUMERIC_DATA1_REPT
        FROM #NUMERIC_BASE_DATA_REPT;

        UPDATE #NUMERIC_DATA1_REPT
        SET ANSWER_UNIT = SUBSTRING(ANSWER_TXT, 1, ( CHARINDEX('^', ANSWER_TXT) - 1 ))
        WHERE CHARINDEX('^', ANSWER_TXT) > 0;

        UPDATE #NUMERIC_DATA1_REPT
        SET LENCODED = LEN(RTRIM(ANSWER_UNIT))
        WHERE CHARINDEX('^', ANSWER_TXT) > 0;

        UPDATE #NUMERIC_DATA1_REPT
        SET ANSWER_CODED = SUBSTRING(ANSWER_TXT, ( LENCODED + 2 ), TXT_LEN)
        WHERE CHARINDEX('^', ANSWER_TXT) > 0;


        UPDATE #NUMERIC_DATA1_REPT
        SET UNIT_VALUE1 = REPLACE(ANSWER_UNIT, ',', '')
        WHERE CHARINDEX('^', ANSWER_TXT) > 0;

        UPDATE #NUMERIC_DATA1_REPT
        SET ANSWER_UNIT = ANSWER_TXT
        WHERE CHARINDEX('^', ANSWER_TXT) = 0;

        UPDATE #NUMERIC_DATA1_REPT
        SET RDB_COLUMN_NM2 = RTRIM(RDB_COLUMN_NM) + ' UNIT'
        WHERE LEN(RTRIM(ANSWER_CODED)) > 0;

        IF OBJECT_ID('#NUMERIC_DATA2_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #NUMERIC_DATA2_REPT;
            END;

        SELECT *
        INTO #NUMERIC_DATA2_REPT
        FROM #NUMERIC_DATA1_REPT;

        UPDATE #NUMERIC_DATA2_REPT
        SET RDB_COLUMN_NM2 = SUBSTRING(RDB_COLUMN_NM2, 1, 22)
        WHERE LEN(RTRIM(RDB_COLUMN_NM2)) > 0;

        IF OBJECT_ID('#NUMERIC_DATA_MERGED_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #NUMERIC_DATA_MERGED_REPT;
            END;
        SELECT *
        INTO #NUMERIC_DATA_MERGED_REPT
        FROM #NUMERIC_DATA1_REPT
        UNION
        SELECT *
        FROM #NUMERIC_DATA2_REPT;

        IF OBJECT_ID('#NUMERIC_DATA_TRANS_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #NUMERIC_DATA_TRANS_REPT;
            END;

        -- CREATE TABLE NUMERIC_DATA_TRANS  AS
        SELECT PAGE_CASE_UID, NBS_QUESTION_UID, ANSWER_GROUP_SEQ_NBR, NBS_CASE_ANSWER_UID, ANSWER_UNIT, ANSWER_CODED, CVG.CODE_SET_NM, RDB_COLUMN_NM, ANSWER_TXT, CODE, CODE_SHORT_DESC_TXT AS 'UNIT', ANSWER_UNIT AS ANSWER_UNIT1, INVESTIGATION_FORM_CD, BLOCK_NM
        INTO #NUMERIC_DATA_TRANS_REPT
        FROM #NUMERIC_DATA_MERGED_REPT AS CODED LEFT
                                                    JOIN
             NBS_SRTE.dbo.CODESET_GROUP_METADATA AS METADATA
             ON METADATA.CODE_SET_GROUP_ID = CODED.UNIT_VALUE1 LEFT
                                                    JOIN
             NBS_SRTE.dbo.CODE_VALUE_GENERAL AS CVG
             ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM AND
                ANSWER_GROUP_SEQ_NBR IS NOT NULL;

        UPDATE #NUMERIC_DATA_TRANS_REPT
        SET ANSWER_TXT = CASE
                             WHEN COALESCE(RTRIM(UNIT), '') = '' THEN ANSWER_TXT
                             WHEN CHARINDEX(' UNIT', RDB_COLUMN_NM) > 0 THEN UNIT
                             ELSE ANSWER_UNIT
            END;

        IF OBJECT_ID('#NUMERIC_DATA_TRANS1_REPT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE #NUMERIC_DATA_TRANS1_REPT;
            END;



        --				CREATE TABLE  NUMERIC_DATA_TRANS1 AS
        BEGIN
            SELECT DISTINCT
                PAGE_CASE_UID, RDB_COLUMN_NM, ANSWER_UNIT, ANSWER_TXT, ANSWER_GROUP_SEQ_NBR, NBS_CASE_ANSWER_UID, INVESTIGATION_FORM_CD, BLOCK_NM, NBS_QUESTION_UID
            INTO #NUMERIC_DATA_TRANS1_REPT
            FROM #NUMERIC_DATA_TRANS_REPT;
            SELECT @RowCount_no = @@ROWCOUNT;
            INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
            VALUES( @Batch_id, 'INVESTIGATION_REPEAT', 'SLD_INVESTIGATION_REPEAT', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

        END;

        COMMIT TRANSACTION;
        BEGIN TRANSACTION;
        BEGIN

            SET @Proc_Step_no = 9;
            SET @Proc_Step_Name = ' LOG Invalid Numeric data INTO ETL_DQ_LOG';

            INSERT INTO dbo.ETL_DQ_LOG( EVENT_TYPE, EVENT_LOCAL_ID, EVENT_UID, DQ_ISSUE_CD, DQ_ISSUE_DESC_TXT, DQ_ISSUE_QUESTION_IDENTIFIER, DQ_ISSUE_ANSWER_TXT, DQ_ISSUE_RDB_LOCATION, JOB_BATCH_LOG_UID, DQ_ETL_PROCESS_TABLE, DQ_ETL_PROCESS_COLUMN, DQ_STATUS_TIME, DQ_ISSUE_SOURCE_LOCATION, DQ_ISSUE_SOURCE_QUESTION_LABEL )
                (
                    SELECT 'INVESTIGATION', inv.LOCAL_ID, inv.PUBLIC_HEALTH_CASE_UID,
                           'INVALID_NUMERIC_VALUE', 'BAD NUMERIC VALUE: A non-numeric value exists in a field expecting a numeric value and requires update. Please correct the bad numeric value so that it can be properly written to the reporting database during the next ETL run',
                           nrt_page.QUESTION_IDENTIFIER, nrt_page.ANSWER_TXT, nrt_page.DATA_LOCATION, @Batch_id, nrt_page.rdb_table_nm, nrt_page.RDB_COLUMN_NM,
                           GETDATE(), nrt_page.DATA_LOCATION, nrt_page.QUESTION_LABEL
                    FROM #NUMERIC_DATA_TRANS1_REPT as rept
                             INNER JOIN
                         dbo.nrt_investigation as inv
                         ON rept.page_case_uid= inv.PUBLIC_HEALTH_CASE_UID
                             INNER JOIN
                         NBS_SRTE.DBO.CONDITION_CODE
                         ON CONDITION_CODE.CONDITION_CD = inv.CD
                             INNER JOIN
                         dbo.nrt_page_case_answer as nrt_page
                         ON nrt_page.act_uid = inv.PUBLIC_HEALTH_CASE_UID
                    WHERE nrt_page.act_uid = @phc_id
                      AND (isNumeric(nrt_page.ANSWER_TXT) != 1)
                      AND nrt_page.ANSWER_TXT IS NOT NULL);


            SELECT @RowCount_no = @@ROWCOUNT;
            INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
            VALUES( @Batch_id, 'INVESTIGATION_REPEAT', 'SLD_INVESTIGATION_REPEAT', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

        END

        COMMIT TRANSACTION;
        BEGIN TRANSACTION;
        DECLARE @numeric_output_table_name varchar(500) = ''
        SET @Proc_Step_no = 10;
        SET @numeric_output_table_name = '##numeric_DATA_REPT_out_'+CAST(@Batch_id as varchar(50));
        SET @Proc_Step_Name = 'Generating FINAL TABLE FOR Numeric '+@numeric_output_table_name;


        EXEC ('IF OBJECT_ID(''tempdb..'+@numeric_output_table_name+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@numeric_output_table_name+';
		END;')
        -- DECLARE @columns NVARCHAR(MAX), @sql NVARCHAR(MAX);

        SET @columns = N'';

        SELECT @columns+=N', p.' + QUOTENAME([RDB_COLUMN_NM])
        FROM
            (
                SELECT [RDB_COLUMN_NM]
                FROM #NUMERIC_DATA_TRANS1_REPT AS p
                GROUP BY [RDB_COLUMN_NM]
            ) AS x;
        SET @sql = N'
				SELECT [PAGE_CASE_UID] as PAGE_CASE_UID_numeric,
				BLOCK_NM as BLOCK_NM_numeric, ANSWER_GROUP_SEQ_NBR as ANSWER_GROUP_SEQ_NBR_numeric, ' + STUFF(@columns, 1, 2, '') + ' into '+@numeric_output_table_name+' FROM (
				SELECT [PAGE_CASE_UID], BLOCK_NM, ANSWER_GROUP_SEQ_NBR, [answer_txt] , [RDB_COLUMN_NM]
					FROM #NUMERIC_DATA_TRANS1_REPT
					where PAGE_CASE_UID > 0
					and (isNumeric(ANSWER_TXT) = 1) AND  ANSWER_TXT IS NOT NULL
					group by [PAGE_CASE_UID], BLOCK_NM, ANSWER_GROUP_SEQ_NBR, [answer_txt] , [RDB_COLUMN_NM]
						) AS j PIVOT (max(answer_txt) FOR [RDB_COLUMN_NM] in
						(' + STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '') + ')) AS p;';

        EXEC sp_executesql @sql;
        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
        VALUES( @Batch_id, 'INVESTIGATION_REPEAT', 'SLD_INVESTIGATION_REPEAT', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );
        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @Proc_Step_no = 11;
        DECLARE @staging_table_name varchar(500) = ''
        SET @staging_table_name = '##STAGING_KEY_REPT_'+CAST(@Batch_id as varchar(50));
        SET @Proc_Step_Name = 'Generating Final Staging table '+@staging_table_name;

        -- CREATE TABLE  STAGING_KEY AS
        EXEC ('IF OBJECT_ID(''tempdb..'+@staging_table_name+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@staging_table_name+';
		END;')

        EXEC ('IF OBJECT_ID(''tempdb..'+@numeric_output_table_name+''', ''U'') IS NULL
		BEGIN
			CREATE TABLE '+@numeric_output_table_name+'
			(
				[PAGE_CASE_UID_numeric] [bigint] NULL, [INVESTIGATION_FORM_CD_numeric] [varchar](50) NULL, [BLOCK_NM_numeric] [varchar](30) NULL, [ANSWER_GROUP_SEQ_NBR_numeric] [int] NULL
			)
			ON [PRIMARY];

		END;')

        EXEC ('IF OBJECT_ID(''tempdb..'+@date_output_table_name+''', ''U'') IS NULL
		BEGIN
			CREATE TABLE '+@date_output_table_name+'
			(
					[PAGE_CASE_UID_date] [bigint] NULL, [INVESTIGATION_FORM_CD_date] [varchar](50) NULL, [BLOCK_NM_date] [varchar](30) NULL, [ANSWER_GROUP_SEQ_NBR_date] [int] NULL
			)
			ON [PRIMARY];

		END;')

        EXEC ('IF OBJECT_ID(''tempdb..'+@coded_output_table_name+''', ''U'') IS NULL
		BEGIN
			CREATE TABLE '+@coded_output_table_name+'
			(
					 [PAGE_CASE_UID_coded] [bigint] NULL, [INVESTIGATION_FORM_CD_coded] [varchar](50) NULL, [BLOCK_NM_coded] [varchar](30) NULL, [ANSWER_GROUP_SEQ_NBR_coded] [int] NULL
			)
			ON [PRIMARY];

		END;')


        EXEC ('IF OBJECT_ID(''tempdb..'+@text_output_table_name+''', ''U'') IS NULL
		BEGIN
			CREATE TABLE '+@text_output_table_name+'
			(
						[PAGE_CASE_UID_text] [bigint] NULL, [INVESTIGATION_FORM_CD] [varchar](50) NULL, [BLOCK_NM_text] [varchar](30) NULL, [ANSWER_GROUP_SEQ_NBR_text] [int] NULL
			)ON [PRIMARY];

		END;')



        declare @staging_step nvarchar(2500);

        set @staging_step=
                '	SELECT PAGE_CASE_UID_date AS PAGE_CASE_UID, BLOCK_NM_date AS BLOCK_NM, ANSWER_GROUP_SEQ_NBR_date AS ANSWER_GROUP_SEQ_NBR
                    INTO '+@staging_table_name+'
			FROM '+@date_output_table_name+'
			UNION
			SELECT PAGE_CASE_UID_text, BLOCK_NM_text, ANSWER_GROUP_SEQ_NBR_text
			FROM '+@text_output_table_name+'
			UNION
			SELECT PAGE_CASE_UID_numeric, BLOCK_NM_numeric, ANSWER_GROUP_SEQ_NBR_numeric
			FROM '+@numeric_output_table_name+'
			UNION
			SELECT PAGE_CASE_UID_coded, BLOCK_NM_coded, ANSWER_GROUP_SEQ_NBR_coded
			FROM '+@coded_output_table_name+';'

        if @debug = 'true'
            print @staging_step;

        exec sp_executesql @staging_step;
        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
        VALUES( @Batch_id, 'INVESTIGATION_REPEAT', 'SLD_INVESTIGATION_REPEAT', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

        COMMIT TRANSACTION;


        BEGIN TRANSACTION;
        SET @Proc_Step_no = 12;
        SET @Proc_Step_Name = 'S_INVESTIGATION_REPEAT Update';



        IF OBJECT_ID('dbo.S_INVESTIGATION_REPEAT', 'U') IS NOT NULL
            BEGIN
                DROP TABLE dbo.S_INVESTIGATION_REPEAT;
            END;


        DECLARE @mergeSQL varchar(max)= 'SELECT sk.* ,ddo.*,tdo.*, ' +
                                        (
                                            SELECT STUFF(
                                                           (
                                                               SELECT ',' + +col
                                                               FROM
                                                                   (
                                                                       SELECT CASE
                                                                                  WHEN i1.t IS NOT NULL AND
                                                                                       i2.t IS NOT NULL THEN 'COALESCE(' + i1.t + '.' + i1.COLUMN_NAME + ', ' + i2.t + '.' + i2.COLUMN_NAME + ') AS ' + i1.COLUMN_NAME
                                                                                  ELSE COALESCE(i1.COLUMN_NAME, i2.COLUMN_NAME)
                                                                                  END AS col, COALESCE(i1.COLUMN_NAME, i2.COLUMN_NAME) AS cname
                                                                       FROM
                                                                           (
                                                                               SELECT 't1' AS t, COLUMN_NAME
                                                                               FROM tempdb.INFORMATION_SCHEMA.COLUMNS
                                                                               WHERE TABLE_NAME = @coded_output_table_name
                                                                           ) AS i1
                                                                               FULL OUTER JOIN
                                                                           (
                                                                               SELECT 't2' AS t, COLUMN_NAME
                                                                               FROM tempdb.INFORMATION_SCHEMA.COLUMNS
                                                                               WHERE TABLE_NAME = @numeric_output_table_name
                                                                           ) AS i2
                                                                           ON i1.COLUMN_NAME = i2.COLUMN_NAME
                                                                   ) AS cols
                                                               ORDER BY cname FOR XML PATH(''), TYPE
                                                           ).value( '.', 'NVARCHAR(MAX)' ), 1, 1, '')
                                        ) + ' INTO S_INVESTIGATION_REPEAT
									from '+@staging_table_name+' sk
									LEFT OUTER  JOIN '+@date_output_table_name+' ddo   ON
									ddo.PAGE_CASE_UID_date=sk.PAGE_CASE_UID    and
									/*ddo.INVESTIGATION_FORM_CD_date = sk.INVESTIGATION_FORM_CD and */
									ddo.BLOCK_NM_date = sk.BLOCK_NM and
									ddo.ANSWER_GROUP_SEQ_NBR_date = sk.ANSWER_GROUP_SEQ_NBR
									LEFT OUTER  JOIN '+@text_output_table_name+' tdo   ON  tdo.PAGE_CASE_UID_text=sk.PAGE_CASE_UID
									/*and tdo.INVESTIGATION_FORM_CD_text = sk.INVESTIGATION_FORM_CD */
									and tdo.BLOCK_NM_text = sk.BLOCK_NM and  tdo.ANSWER_GROUP_SEQ_NBR_text = sk.ANSWER_GROUP_SEQ_NBR
									LEFT OUTER  JOIN '+@numeric_output_table_name+' t2 ON t2.PAGE_CASE_UID_NUMERIC=sk.PAGE_CASE_UID
									/*and t2.INVESTIGATION_FORM_CD_numeric = sk.INVESTIGATION_FORM_CD */
									and t2.BLOCK_NM_numeric = sk.BLOCK_NM and  t2.ANSWER_GROUP_SEQ_NBR_numeric = sk.ANSWER_GROUP_SEQ_NBR
									LEFT OUTER  JOIN '+@coded_output_table_name+' t1  ON  t1.PAGE_CASE_UID_coded=sk.PAGE_CASE_UID
									/*and t1.INVESTIGATION_FORM_CD_coded = sk.INVESTIGATION_FORM_CD*/
									and t1.BLOCK_NM_coded = sk.BLOCK_NM and  t1.ANSWER_GROUP_SEQ_NBR_coded = sk.ANSWER_GROUP_SEQ_NBR';





        EXECUTE (@mergeSQL);

        if @debug = 'true'
            print @mergeSQL;

        if @debug = 'false'
            EXEC (' drop table '+@staging_table_name+';
				 drop table '+@numeric_output_table_name+';
				 drop table '+@date_output_table_name+';
				 drop table '+@text_output_table_name+';
				 drop table '+@coded_output_table_name+';
               ')

        ALTER TABLE dbo.S_INVESTIGATION_REPEAT DROP COLUMN PAGE_CASE_UID_numeric;
        ALTER TABLE dbo.S_INVESTIGATION_REPEAT DROP COLUMN PAGE_CASE_UID_date;
        ALTER TABLE dbo.S_INVESTIGATION_REPEAT DROP COLUMN PAGE_CASE_UID_coded;
        ALTER TABLE dbo.S_INVESTIGATION_REPEAT DROP COLUMN PAGE_CASE_UID_text;

        ALTER TABLE dbo.S_INVESTIGATION_REPEAT DROP COLUMN BLOCK_NM_numeric;
        ALTER TABLE dbo.S_INVESTIGATION_REPEAT DROP COLUMN BLOCK_NM_date;
        ALTER TABLE dbo.S_INVESTIGATION_REPEAT DROP COLUMN BLOCK_NM_coded;
        ALTER TABLE dbo.S_INVESTIGATION_REPEAT DROP COLUMN BLOCK_NM_text;

        ALTER TABLE dbo.S_INVESTIGATION_REPEAT DROP COLUMN ANSWER_GROUP_SEQ_NBR_numeric;
        ALTER TABLE dbo.S_INVESTIGATION_REPEAT DROP COLUMN ANSWER_GROUP_SEQ_NBR_date;
        ALTER TABLE dbo.S_INVESTIGATION_REPEAT DROP COLUMN ANSWER_GROUP_SEQ_NBR_coded;
        ALTER TABLE dbo.S_INVESTIGATION_REPEAT DROP COLUMN ANSWER_GROUP_SEQ_NBR_text;

        if @debug = 'true'
            select * from dbo.S_INVESTIGATION_REPEAT;


        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
        VALUES( @Batch_id, 'INVESTIGATION_REPEAT', 'SLD_INVESTIGATION_REPEAT', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = 13;
        SET @Proc_Step_Name = 'Insert into L_INVESTIGATION_REPEAT';


        IF OBJECT_ID('dbo.L_INVESTIGATION_REPEAT', 'U') IS NULL
            BEGIN
                CREATE TABLE [dbo].[L_INVESTIGATION_REPEAT]
                (
                    [D_INVESTIGATION_REPEAT_KEY] [float] NULL, [PAGE_CASE_UID] [float] NULL
                )
                    ON [PRIMARY];
            END;

        DELETE FROM dbo.LOOKUP_TABLE_N_REPT;

        INSERT INTO dbo.LOOKUP_TABLE_N_REPT
        SELECT PAGE_CASE_UID
        FROM dbo.S_INVESTIGATION_REPEAT
        WHERE PAGE_CASE_UID > 1
        EXCEPT
        SELECT DISTINCT
            PAGE_CASE_UID
        FROM dbo.L_INVESTIGATION_REPEAT;


        IF OBJECT_ID('dbo.L_INVESTIGATION_REPEAT_INC', 'U') IS NOT NULL
            BEGIN
                DROP TABLE dbo.L_INVESTIGATION_REPEAT_INC;
            END;

        SELECT pcuid.PAGE_CASE_UID, ladmin.[D_INVESTIGATION_REPEAT_KEY]
        INTO [dbo].[L_INVESTIGATION_REPEAT_INC]
        FROM #phc_uids_REPT AS pcuid, dbo.[L_INVESTIGATION_REPEAT] AS ladmin
        WHERE pcuid.PAGE_CASE_UID = ladmin.PAGE_CASE_UID AND
            ladmin.[D_INVESTIGATION_REPEAT_KEY] != 1;

        INSERT INTO [dbo].[L_INVESTIGATION_REPEAT_INC]( [PAGE_CASE_UID], [D_INVESTIGATION_REPEAT_KEY] )
        SELECT PAGE_CASE_UID, D_REPT_KEY
        FROM dbo.LOOKUP_TABLE_N_REPT;

        INSERT INTO [dbo].[L_INVESTIGATION_REPEAT]( [PAGE_CASE_UID], [D_INVESTIGATION_REPEAT_KEY] )
        SELECT PAGE_CASE_UID, D_REPT_KEY
        FROM dbo.LOOKUP_TABLE_N_REPT;

        CREATE INDEX idx_PAGE_CASE_UID_L
            ON dbo.L_INVESTIGATION_REPEAT_INC
                ( PAGE_CASE_UID
                    );

        CREATE INDEX idx_PAGE_CASE_UID_S
            ON dbo.S_INVESTIGATION_REPEAT
                ( page_case_uid
                    );

        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
        VALUES( @Batch_id, 'INVESTIGATION_REPEAT', 'SLD_INVESTIGATION_REPEAT', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;
        SET @Proc_Step_no = 14;
        SET @Proc_Step_Name = 'Insert into D_INVESTIGATION_REPEAT_INC';

        IF OBJECT_ID('dbo.D_INVESTIGATION_REPEAT', 'U') IS NULL
            BEGIN
                CREATE TABLE [dbo].[D_INVESTIGATION_REPEAT]
                (
                    [D_INVESTIGATION_REPEAT_KEY] [float] NULL, [PAGE_CASE_UID] [float] NULL
                )
                    ON [PRIMARY];
            END;


        IF OBJECT_ID('dbo.D_INVESTIGATION_REPEAT_INC', 'U') IS NOT NULL
            BEGIN
                DROP TABLE dbo.D_INVESTIGATION_REPEAT_INC;
            END;

        --CREATE TABLE NBS_D_INVESTIGATION_REPEAT(DROP=NBS_CASE_ANSWER_UID INVESTIGATION_FORM_CD) AS
        SELECT SREPT.*, LREPT.D_INVESTIGATION_REPEAT_KEY
        INTO dbo.D_INVESTIGATION_REPEAT_INC
        FROM dbo.L_INVESTIGATION_REPEAT_INC AS LREPT LEFT
                                                         OUTER JOIN
             dbo.S_INVESTIGATION_REPEAT AS SREPT
             ON SREPT.PAGE_CASE_UID = LREPT.PAGE_CASE_UID;
        CREATE NONCLUSTERED INDEX [RDB_PERF_INTERNAL_07]
            ON [dbo].[D_INVESTIGATION_REPEAT_INC]
                ( [D_INVESTIGATION_REPEAT_KEY]
                    );

        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = 15;
        SET @Proc_Step_Name = ' Add new columns to D_INVESTIGATION_REPEAT';

        -- create table rdb_ui_metadata_INVESTIGATION_REPEAT as

        DECLARE @Temp_Query_Table TABLE
                                  (
                                      ID int IDENTITY(1, 1), QUERY_stmt varchar(5000)
                                  );
        DECLARE @column_query varchar(5000);
        DECLARE @Max_Query_No int;
        DECLARE @Curr_Query_No int;
        DECLARE @ColumnList varchar(5000);

        INSERT INTO @Temp_Query_Table
        SELECT 'ALTER TABLE dbo.D_INVESTIGATION_REPEAT ADD [' + COLUMN_NAME + '] ' + DATA_TYPE + CASE
                                                                                                     WHEN DATA_TYPE IN('char', 'varchar', 'nchar', 'nvarchar') THEN ' (' + COALESCE(CAST(NULLIF(CHARACTER_MAXIMUM_LENGTH, -1) AS varchar(10)), CAST(CHARACTER_MAXIMUM_LENGTH AS varchar(10))) + ')'
                                                                                                     ELSE ''
            END + CASE
                      WHEN IS_NULLABLE = 'NO' THEN ' NOT NULL'
                      ELSE ' NULL'
                   END
        FROM INFORMATION_SCHEMA.COLUMNS AS c
        WHERE TABLE_NAME = 'D_INVESTIGATION_REPEAT_INC' AND
            NOT EXISTS
                (
                    SELECT 1
                    FROM INFORMATION_SCHEMA.COLUMNS
                    WHERE TABLE_NAME = 'D_INVESTIGATION_REPEAT' AND
                        COLUMN_NAME = c.COLUMN_NAME
                ) AND
            LOWER(COLUMN_NAME) NOT IN( LOWER('PAGE_CASE_UID'), 'last_chg_time' );


        SET @Max_Query_No =
                (
                    SELECT MAX(ID)
                    FROM @Temp_Query_Table AS t
                );

        SET @Curr_Query_No = 0;

        WHILE @Max_Query_No > @Curr_Query_No

            BEGIN
                SET @Curr_Query_No = @Curr_Query_No + 1;

                SET @column_query =
                        (
                            SELECT QUERY_stmt
                            FROM @Temp_Query_Table AS t
                            WHERE ID = @Curr_Query_No
                        );

                --SELECT @column_query;

                EXEC (@column_query);

            END;

        SELECT @RowCount_no = @@ROWCOUNT;


        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
        VALUES( @Batch_id, 'INVESTIGATION_REPEAT', 'SLD_INVESTIGATION_REPEAT', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );


        COMMIT TRANSACTION;

        BEGIN TRANSACTION;

        SET @Proc_Step_no = 14;
        SET @Proc_Step_Name = ' Inserting data into D_INVESTIGATION_REPEAT';

        IF NOT EXISTS
            (
                SELECT *
                FROM sys.indexes
                WHERE name = 'RDB_PERF_04092021_06' AND
                    object_id = OBJECT_ID('D_INVESTIGATION_REPEAT')
            )
            BEGIN

                CREATE NONCLUSTERED INDEX [RDB_PERF_04092021_06]
                    ON [dbo].[D_INVESTIGATION_REPEAT]
                        ( [D_INVESTIGATION_REPEAT_KEY]
                            );
            END;

        INSERT INTO [dbo].[D_INVESTIGATION_REPEAT]( [D_INVESTIGATION_REPEAT_KEY] )
        SELECT 1
        WHERE NOT EXISTS
            (
                SELECT TOP 1 d_INVESTIGATION_REPEAT_key
                FROM [RDB].[dbo].[D_INVESTIGATION_REPEAT_INC]
                WHERE d_INVESTIGATION_REPEAT_key = 1
            ) AND
            NOT EXISTS
                (
                    SELECT TOP 1 D_INVESTIGATION_REPEAT_KEY
                    FROM [RDB].[DBO].[D_INVESTIGATION_REPEAT]
                    WHERE D_INVESTIGATION_REPEAT_KEY = 1
                );

        DECLARE @insert_query nvarchar(max);

        SET @insert_query =
                (
                    SELECT 'INSERT INTO  [dbo].[D_INVESTIGATION_REPEAT]( [D_INVESTIGATION_REPEAT_KEY] ,' + STUFF(
                            (
                                SELECT ', [' + name + ']'
                                FROM syscolumns
                                WHERE id = OBJECT_ID('S_INVESTIGATION_REPEAT') AND
                                    LOWER(NAME) NOT IN( 'last_chg_time' ) FOR XML PATH('')
                            ), 1, 1, '') + ' ) select [D_INVESTIGATION_REPEAT_KEY] , ' + STUFF(
                                   (
                                       SELECT ', SINV.[' + name + ']'
                                       FROM syscolumns
                                       WHERE id = OBJECT_ID('S_INVESTIGATION_REPEAT') AND
                                           LOWER(NAME) NOT IN( 'last_chg_time' ) FOR XML PATH('')
                                   ), 1, 1, '') + '
	   FROM  dbo.L_INVESTIGATION_REPEAT_INC LINV
	   INNER JOIN dbo.S_INVESTIGATION_REPEAT SINV ON SINV.PAGE_CASE_UID=LINV.PAGE_CASE_UID
	    where linv.D_INVESTIGATION_REPEAT_KEY != 1'
                );


        PRINT @insert_query;

        DELETE dnr
        FROM dbo.D_INVESTIGATION_REPEAT DNR
                 INNER JOIN
             dbo.S_INVESTIGATION_REPEAT SINV
             ON SINV.PAGE_CASE_UID = DNR.PAGE_CASE_UID;

        --SELECT @insert_query;

        EXEC sp_executesql @insert_query;

        SELECT @RowCount_no = @@ROWCOUNT;
        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
        VALUES( @Batch_id, 'INVESTIGATION_REPEAT', 'SLD_INVESTIGATION_REPEAT', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

        COMMIT TRANSACTION;



        BEGIN TRANSACTION;

        SET @Proc_Step_no = 999;
        SET @Proc_Step_Name = 'SP_COMPLETE';

        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
        VALUES( @Batch_id, 'INVESTIGATION_REPEAT', 'D_INVESTIGATION_REPEAT', 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );
        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRANSACTION;
            END;


        DECLARE @ErrorNumber int= ERROR_NUMBER();
        DECLARE @ErrorLine int= ERROR_LINE();
        DECLARE @ErrorMessage nvarchar(4000)= ERROR_MESSAGE();
        DECLARE @ErrorSeverity int= ERROR_SEVERITY();
        DECLARE @ErrorState int= ERROR_STATE();

        INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [Error_Description], [row_count] )
        VALUES( @Batch_id, 'INVESTIGATION_REPEAT', 'D_INVESTIGATION_REPEAT', 'ERROR', @Proc_Step_no, 'ERROR - ' + @Proc_Step_name, 'Step -' + CAST(@Proc_Step_no AS varchar(3)) + ' -' + CAST(@ErrorMessage AS varchar(500)), 0 );

        RETURN -1;
    END CATCH;

END;