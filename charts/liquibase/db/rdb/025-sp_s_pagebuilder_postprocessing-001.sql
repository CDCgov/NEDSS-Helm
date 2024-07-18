CREATE OR ALTER PROCEDURE dbo.sp_s_pagebuilder_postprocessing
		@Batch_id bigint,
		@phc_id bigint,
		@rdb_table_name varchar(250) = 'D_INV_ADMINISTRATIVE',
	 	@category varchar(250) = 'INV_ADMINISTRATIVE',
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
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, 0 );

		COMMIT TRANSACTION;

		SELECT @batch_start_time = batch_start_dttm, @batch_end_time = batch_end_dttm
		FROM [dbo].[job_batch_log]
		WHERE status_type = 'start' AND 
			  type_code = 'MasterETL';
			 
		---******************************************************************
		---** START PROCESSING TEXT BASED QUESTIONS AND ANSWERS *************
		
		
		BEGIN TRANSACTION;
		SET @Proc_Step_no = 3;
		SET @Proc_Step_Name = ' Generating text_data_'+@category; 

		IF OBJECT_ID('#text_data_INV', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #text_data_INV;
		END;
		

		SELECT DISTINCT 
			   NBS_CASE_ANSWER_UID, nrt_page.CODE_SET_GROUP_ID, nrt_page.RDB_COLUMN_NM, CAST(REPLACE(ANSWER_TXT, CHAR(13) + CHAR(10), ' ') AS varchar(2000)) AS ANSWER_TXT, COALESCE(ACT_UID, 1) AS PAGE_CASE_UID_TEXT, nrt_page.RECORD_STATUS_CD, nrt_page.NBS_QUESTION_UID
		INTO #text_data_INV
		FROM dbo.nrt_page_case_answer AS nrt_page WITH(NOLOCK) --2
			INNER JOIN
			NBS_SRTE.dbo.CODE_VALUE_GENERAL AS CVG WITH(NOLOCK)
			ON UPPER(CVG.CODE) = UPPER(nrt_page.DATA_TYPE)
		WHERE 
			nrt_page.act_uid = @phc_id
			AND nrt_page.ANSWER_GROUP_SEQ_NBR IS NULL
			AND (nrt_page.RDB_TABLE_NM = @rdb_table_name AND nrt_page.QUESTION_GROUP_SEQ_NBR IS NULL AND UPPER(nrt_page.DATA_TYPE) = 'TEXT')
				OR (nrt_page.RDB_TABLE_NM = @rdb_table_name AND nrt_page.QUESTION_GROUP_SEQ_NBR IS NULL AND nrt_page.RDB_COLUMN_NM LIKE '%_CD')
			AND CVG.CODE_SET_NM = 'NBS_DATA_TYPE' 
			AND CODE IN( 'CODED', 'TEXT' )
		ORDER BY NBS_CASE_ANSWER_UID, nrt_page.CODE_SET_GROUP_ID, nrt_page.RDB_COLUMN_NM, CAST(REPLACE(ANSWER_TXT, CHAR(13) + CHAR(10), ' ') AS varchar(2000)), COALESCE(ACT_UID, 1), nrt_page.RECORD_STATUS_CD, nrt_page.NBS_QUESTION_UID;
		
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		if @debug = 'true'
			select * from #text_data_INV;
	
		COMMIT TRANSACTION;

		BEGIN TRANSACTION;
		DECLARE @text_output_table_name varchar(500) = ''
		SET @Proc_Step_no = 4;
		SET @text_output_table_name = '##text_data_INV_out_'+@category+'_'+CAST(@Batch_id as varchar(50));	
	
		SET @Proc_Step_Name = ' Generating '+@text_output_table_name;
		
		EXEC ('IF OBJECT_ID(''tempdb..'+@text_output_table_name+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@text_output_table_name+';
		END;')
		
		DECLARE @columns nvarchar(max);
		DECLARE @sql nvarchar(max);
		SET @columns = N'';
		SELECT @columns+=N', p.' + QUOTENAME(LTRIM(RTRIM([RDB_COLUMN_NM])))
		FROM
		(
			SELECT [RDB_COLUMN_NM]
			FROM #text_data_INV AS p
			GROUP BY [RDB_COLUMN_NM]
		) AS x;
		SET @sql = N'
		SELECT [PAGE_CASE_UID_text] as PAGE_CASE_UID_text, ' + STUFF(@columns, 1, 2, '') + ' into '+@text_output_table_name +' FROM (
		SELECT [PAGE_CASE_UID_text], [answer_txt] , [RDB_COLUMN_NM] 
		 FROM #text_data_INV
			group by [PAGE_CASE_UID_text], [answer_txt] , [RDB_COLUMN_NM] 
		) AS j PIVOT (max(answer_txt) FOR [RDB_COLUMN_NM] in 
	   (' + STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '') + ')) AS p;';
		
	  	if @debug = 'true'
	  		PRINT @sql;
		
	  	EXEC sp_executesql @sql;
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		--- If the #text_data_inv table does not have any records create the table with default column 	
		EXEC ('IF OBJECT_ID(''tempdb..'+@text_output_table_name+''', ''U'') IS NULL
		BEGIN
			CREATE TABLE '+@text_output_table_name+'
			( 
						 [PAGE_CASE_UID_text] [bigint] NULL,
			)
			
		END;') 

		if @debug = 'true'
	  		EXEC ('select * from '+@text_output_table_name)				
	
		COMMIT TRANSACTION;
	
		---*************************************************************
		---** START PROCESSING CODED QUESTIONS AND ANSWERS *************
	

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 5;
		SET @Proc_Step_Name = ' Generating CODED rdb_ui_metadata_'+@category; 
		-- CREATE TABLE CODED_TABLE AS
		IF OBJECT_ID('#CASE_ANSWER_PHC_UIDS', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CASE_ANSWER_PHC_UIDS;
		END;

		SELECT DISTINCT 
			   NBS_CASE_ANSWER_UID, nrt_page.RECORD_STATUS_CD, nrt_page.ACT_UID AS 'PAGE_CASE_UID', nrt_page.INVESTIGATION_FORM_CD, ANSWER_TXT, nrt_page.nbs_question_uid,
			   nrt_page.RDB_COLUMN_NM, nrt_page.CODE_SET_GROUP_ID, nrt_page.unit_value, CODE_SET_GROUP_ID AS CODE_SET_GROUP_ID1, QUESTION_GROUP_SEQ_NBR, DATA_TYPE, OTHER_VALUE_IND_CD
		INTO #CASE_ANSWER_PHC_UIDS
		FROM dbo.nrt_page_case_answer as nrt_page WITH(NOLOCK) --2
		WHERE nrt_page.act_uid=@phc_id 
			AND nrt_page.ANSWER_GROUP_SEQ_NBR IS NULL
			 AND UPPER(nrt_page.data_type) = 'CODED' 
			 AND ANSWER_GROUP_SEQ_NBR IS NULL  
			 AND nrt_page.rdb_table_nm = @rdb_table_name
			 AND QUESTION_GROUP_SEQ_NBR IS NULL AND 
			  ( UPPER(DATA_TYPE) = 'CODED' OR 
				UPPER(UNIT_TYPE_CD) = 'CODED' OR 
				mask = 'NUM_TEMP'
			  ) AND 
			  RDB_COLUMN_NM NOT LIKE '%_CD'
		  ORDER BY nrt_page.NBS_QUESTION_UID, nrt_page.RDB_COLUMN_NM, nrt_page.CODE_SET_GROUP_ID, nrt_page.unit_value DESC;
			  

		CREATE NONCLUSTERED INDEX [idx_CASE_ANSWER_PHC_UIDS]
          ON #CASE_ANSWER_PHC_UIDS ([INVESTIGATION_FORM_CD],[nbs_question_uid])
          INCLUDE ([NBS_CASE_ANSWER_UID],[RECORD_STATUS_CD],[PAGE_CASE_UID],[ANSWER_TXT])
		;


		IF OBJECT_ID('#CODED_TABLE_INV', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CODED_TABLE_INV;
		END;
		SELECT DISTINCT 
			   NBS_CASE_ANSWER_UID, PA.CODE_SET_GROUP_ID, PA.RDB_COLUMN_NM, CAST(ANSWER_TXT AS varchar(2000)) AS ANSWER_TXT, 
			   PAGE_CASE_UID, PA.RECORD_STATUS_CD, PA.NBS_QUESTION_UID, OTHER_VALUE_IND_CD, CAST(NULL AS [varchar](256)) AS ANSWER_OTH, 
			   CAST(NULL AS [varchar](256)) AS ANSWER_TXT1, PA.INVESTIGATION_FORM_CD
		INTO #CODED_TABLE_INV
		FROM #CASE_ANSWER_PHC_UIDS AS PA WITH(NOLOCK)
										   INNER JOIN
										   NBS_SRTE.dbo.CODE_VALUE_GENERAL AS CVG WITH(NOLOCK)
										   ON UPPER(CVG.CODE) = UPPER(PA.DATA_TYPE)
		WHERE CVG.CODE_SET_NM = 'NBS_DATA_TYPE' 
		AND UPPER(data_type) = 'CODED'
		ORDER BY PAGE_CASE_UID, NBS_CASE_ANSWER_UID, PA.CODE_SET_GROUP_ID;

		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );
		COMMIT TRANSACTION;


		BEGIN TRANSACTION;
		SET @Proc_Step_no = 7;
		SET @Proc_Step_Name = ' Update CODED rdb_ui_metadata_'+@category;
		UPDATE #coded_table_INV
		  SET ANSWER_OTH = SUBSTRING(ANSWER_TXT, CHARINDEX('^', ANSWER_TXT) + 1, LEN(RTRIM(LTRIM(ANSWER_TXT))))
		WHERE CHARINDEX('^', ANSWER_TXT) > 0;
		UPDATE #coded_table_INV
		  SET ANSWER_TXT = SUBSTRING(ANSWER_TXT, 1, ( CHARINDEX('^', ANSWER_TXT) - 1 ))
		WHERE CHARINDEX('^', ANSWER_TXT) > 0;
		UPDATE #coded_table_INV
		  SET ANSWER_TXT = 'OTH'
		WHERE UPPER(ANSWER_TXT) LIKE 'OTH^%';
		SELECT @RowCount_no = -1;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 8;
		SET @Proc_Step_Name = ' Create table CODED_TABLE_OTHER_EMPTY_'+@category; 
		--CREATE TABLE 	CODED_TABLE_OTHER_EMPTY 
		IF OBJECT_ID('#CODED_TABLE_OTHER_EMPTY_INV', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CODED_TABLE_OTHER_EMPTY_INV;
		END;

		SELECT DISTINCT 
			   CODED.CODE_SET_GROUP_ID, PAGE_CASE_UID, NBS_QUESTION_UID, RDB_COLUMN_NM, NBS_CASE_ANSWER_UID, '' AS ANSWER_TXT, ANSWER_OTH AS ANSWER_DESC11, OTHER_VALUE_IND_CD
		INTO #CODED_TABLE_OTHER_EMPTY_INV
		FROM #CODED_TABLE_INV AS CODED
		WHERE OTHER_VALUE_IND_CD = 'T' AND 
			  ( COALESCE(ANSWER_TXT, '') <> 'OTH' OR 
				LEN(COALESCE(answer_txt, '')) = 0
			  );
		--ORDER BY NBS_CASE_ANSWER_UID, RDB_COLUMN_NM
		SELECT @RowCount_no = @@ROWCOUNT;
		CREATE NONCLUSTERED INDEX [RDB_PERF_INTERNAL_03]
		ON #CODED_TABLE_OTHER_EMPTY_INV
		( [PAGE_CASE_UID] ASC, [RDB_COLUMN_NM] ASC
		);

		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 9;
		SET @Proc_Step_Name = ' create table CODED_TABLE_OTHER_NONEMPTY_'+@category; 
		-- CREATE TABLE CODED_TABLE_OTHER_NONEMPTY 
		IF OBJECT_ID('#CODED_TABLE_OTHER_NONEMPTY_INV', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CODED_TABLE_OTHER_NONEMPTY_INV;
		END;

		SELECT DISTINCT 
			   CODED.CODE_SET_GROUP_ID, PAGE_CASE_UID, NBS_QUESTION_UID, RDB_COLUMN_NM, NBS_CASE_ANSWER_UID, ANSWER_TXT, ANSWER_OTH AS ANSWER_DESC11, OTHER_VALUE_IND_CD
		INTO #CODED_TABLE_OTHER_NONEMPTY_INV
		FROM #CODED_TABLE_INV AS CODED
		WHERE OTHER_VALUE_IND_CD = 'T' AND 
			  ( ANSWER_OTH IS NOT NULL OR 
				ANSWER_TXT LIKE 'OTH^%'
			  )
		ORDER BY NBS_CASE_ANSWER_UID, RDB_COLUMN_NM;
		SELECT @RowCount_no = @@ROWCOUNT;
		CREATE NONCLUSTERED INDEX [RDB_PERF_INTERNAL_03]
		ON #CODED_TABLE_OTHER_NONEMPTY_INV
		( [PAGE_CASE_UID] ASC, [RDB_COLUMN_NM] ASC
		);

		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;
		if @debug = 'true'
			select * from #CODED_TABLE_OTHER_NONEMPTY_INV
	
	

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 10;
		SET @Proc_Step_Name = ' delete from CODED_TABLE_OTHER_NONEMPTY_'+@category;
		DELETE #CODED_TABLE_OTHER_EMPTY_INV
		FROM #CODED_TABLE_OTHER_EMPTY_INV A
			 INNER JOIN
			 #CODED_TABLE_OTHER_NONEMPTY_INV B
			 ON A.PAGE_CASE_UID = B.PAGE_CASE_UID AND 
				A.RDB_COLUMN_NM = B.RDB_COLUMN_NM;
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 11;
		SET @Proc_Step_Name = ' create table CODED_TABLE_OTHER_'+@category;
		IF OBJECT_ID('#CODED_TABLE_OTHER_INV', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CODED_TABLE_OTHER_INV;
		END;

		SELECT COALESCE(cne.[NBS_QUESTION_UID], ce.[NBS_QUESTION_UID]) AS [NBS_QUESTION_UID], COALESCE(cne.[RDB_COLUMN_NM], ce.[RDB_COLUMN_NM]) AS [RDB_COLUMN_NM], COALESCE(cne.[CODE_SET_GROUP_ID], ce.[CODE_SET_GROUP_ID]) AS [CODE_SET_GROUP_ID], COALESCE(cne.[PAGE_CASE_UID], ce.[PAGE_CASE_UID]) AS [PAGE_CASE_UID], COALESCE(cne.[NBS_CASE_ANSWER_UID], ce.[NBS_CASE_ANSWER_UID]) AS [NBS_CASE_ANSWER_UID], COALESCE(cne.[ANSWER_TXT], ce.[ANSWER_TXT]) AS [ANSWER_TXT], COALESCE(cne.[ANSWER_DESC11], ce.[ANSWER_DESC11]) AS [ANSWER_DESC11], COALESCE(cne.[OTHER_VALUE_IND_CD], ce.[OTHER_VALUE_IND_CD]) AS [OTHER_VALUE_IND_CD], CAST(NULL AS [varchar](30)) AS RDB_COLUMN_NM2
		INTO #CODED_TABLE_OTHER_INV
		FROM #CODED_TABLE_OTHER_NONEMPTY_INV AS cne
			 FULL OUTER JOIN
			 #CODED_TABLE_OTHER_EMPTY_INV AS ce
			 ON cne.NBS_CASE_ANSWER_UID = ce.NBS_CASE_ANSWER_UID AND 
				cne.[RDB_COLUMN_NM] = ce.[RDB_COLUMN_NM];
		SELECT @RowCount_no = @@ROWCOUNT;
		CREATE NONCLUSTERED INDEX [RDB_PERF_INTERNAL_01]
		ON #CODED_TABLE_OTHER_INV
		( [OTHER_VALUE_IND_CD]
		) 
		INCLUDE( [RDB_COLUMN_NM] );

		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );
		
		COMMIT TRANSACTION;

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 12;
		SET @Proc_Step_Name = ' update table CODED_TABLE_OTHER_'+@category;
		UPDATE #CODED_TABLE_OTHER_INV
		  SET RDB_COLUMN_NM = REPLACE(SUBSTRING(RDB_COLUMN_NM, 1, 26), ' ', '') + '_OTH'
		WHERE OTHER_VALUE_IND_CD = 'T';
		UPDATE #CODED_TABLE_OTHER_INV
		  SET ANSWER_TXT = ''
		WHERE( OTHER_VALUE_IND_CD = 'T' AND 
			   ANSWER_TXT <> 'OTH'
			 );
		SELECT @RowCount_no = -1;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 12;
		SET @Proc_Step_Name = ' create table CODED_TABLE_STD_'+@category; 
		--CREATE TABLE 	CODED_TABLE_STD 
		IF OBJECT_ID('#CODED_TABLE_STD_INV', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CODED_TABLE_STD_INV;
		END;
		SELECT DISTINCT 
			   CODED.CODE_SET_GROUP_ID, PAGE_CASE_UID, coded.NBS_QUESTION_UID, NBS_CASE_ANSWER_UID, ANSWER_TXT, METADATA.CODE_SET_NM, RDB_COLUMN_NM, ANSWER_OTH, METADATA.CODE, CODE_SHORT_DESC_TXT AS ANSWER_TXT1
		INTO #CODED_TABLE_STD_INV
		FROM #coded_table_INV AS CODED WITH(NOLOCK) LEFT
			 OUTER JOIN
			 REF_FORMCODE_TRANSLATION AS METADATA WITH(NOLOCK)
			 ON METADATA.INVESTIGATION_FORM_CD = CODED.INVESTIGATION_FORM_CD AND 
				METADATA.CODE_SET_GROUP_ID = CODED.CODE_SET_GROUP_ID AND 
				METADATA.CODE = CODED.ANSWER_TXT and METADATA.NBS_QUESTION_UID=coded.NBS_QUESTION_UID

		UNION
		SELECT DISTINCT 
			   CODED.CODE_SET_GROUP_ID, PAGE_CASE_UID, NBS_QUESTION_UID, NBS_CASE_ANSWER_UID, ANSWER_TXT, 'COUNTY_CCD' AS CODE_SET_NM, RDB_COLUMN_NM, ANSWER_OTH, CODED.ANSWER_TXT, '' AS ANSWER_TXT1
		FROM #coded_table_INV AS CODED WITH(NOLOCK)
		WHERE CODED.CODE_SET_GROUP_ID IN
		(
			SELECT code_set_group_id
			FROM nbs_srte..codeset
			WHERE CLASS_CD = 'V_State_county_code_value'
		)
		ORDER BY NBS_CASE_ANSWER_UID, RDB_COLUMN_NM;

		DELETE FROM #CODED_TABLE_STD_INV
		WHERE ANSWER_TXT IS NOT NULL AND 
			  ANSWER_TXT1 IS NULL AND 
			  CODE_SET_NM IS NULL;

		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;

	
		BEGIN TRANSACTION;
		SET @Proc_Step_no = 15;
		SET @Proc_Step_Name = ' Create table CODED_TABLE_SNTEMP_'+@category; 
		-- CREATE TABLE CODED_TABLE_SNTEMP AS
		IF OBJECT_ID('#CODED_TABLE_SNTEMP_INV', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CODED_TABLE_SNTEMP_INV;
		END;

		SELECT NBS_CASE_ANSWER_UID, 
		case when (RTRIM(CODE_SET_GROUP_ID) IS NULL AND (UNIT_TYPE_CD = 'CODED')) then nrt_page.unit_value 
		else CODE_SET_GROUP_ID end as CODE_SET_GROUP_ID, 
		nrt_page.RDB_COLUMN_NM, CAST(ANSWER_TXT AS varchar(2000)) AS ANSWER_TXT, ACT_UID AS 'PAGE_CASE_UID', nrt_page.RECORD_STATUS_CD, nrt_page.NBS_QUESTION_UID, nrt_page.MASK, CAST(NULL AS [varchar](2000)) AS ANSWER_TXT_CODE, CAST(NULL AS [varchar](2000)) AS ANSWER_VALUE, nrt_page.INVESTIGATION_FORM_CD,
		nrt_page.UNIT_VALUE, CODE_SET_GROUP_ID AS CODE_SET_GROUP_ID1, QUESTION_GROUP_SEQ_NBR, DATA_TYPE, UNIT_VALUE AS UNIT_VALUE1, UNIT_TYPE_CD
		INTO #CODED_TABLE_SNTEMP_INV
		FROM dbo.nrt_page_case_answer AS nrt_page WITH(NOLOCK) --3
			INNER JOIN
			NBS_SRTE.dbo.CODE_VALUE_GENERAL AS CVG WITH(NOLOCK)
			ON UPPER(CVG.CODE) = UPPER(nrt_page.DATA_TYPE)
		WHERE nrt_page.act_uid = @phc_id  
			  AND nrt_page.ANSWER_GROUP_SEQ_NBR IS NULL 
			  AND CVG.CODE_SET_NM = 'NBS_DATA_TYPE' 
			  AND UPPER(nrt_page.data_type) = 'NUMERIC'  
			  AND nrt_page.RDB_TABLE_NM = @rdb_table_name AND 
			  QUESTION_GROUP_SEQ_NBR IS NULL AND 
			  ( ( UPPER(DATA_TYPE) = 'NUMERIC' AND 
				  UNIT_VALUE IS NOT NULL AND 
				  unit_type_cd != 'LITERAL'
				) OR 
				( UPPER(DATA_TYPE) = 'NUMERIC' AND 
				  UPPER(mask) = 'NUM' AND 
				  unit_type_cd = 'LITERAL'
				)
			  ) AND 
			  RDB_COLUMN_NM NOT LIKE '%_CD'
		ORDER BY ACT_UID, NBS_CASE_ANSWER_UID, nrt_page.CODE_SET_GROUP_ID;
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;
	
		

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 17;
		SET @Proc_Step_Name = ' Ceate TABLE   CODED_TABLE_SNTEMP_'+@category;
		UPDATE #CODED_TABLE_SNTEMP_INV
		  SET ANSWER_TXT_CODE = SUBSTRING(ANSWER_TXT, CHARINDEX('^', ANSWER_TXT) + 1, LEN(RTRIM(ANSWER_TXT))), ANSWER_VALUE = REPLACE(SUBSTRING(ANSWER_TXT, 1, ( CHARINDEX('^', ANSWER_TXT) - 1 )), ',', '')
		WHERE CHARINDEX('^', ANSWER_TXT) > 0;
		UPDATE #CODED_TABLE_SNTEMP_INV
		  SET ANSWER_VALUE = answer_txt
		WHERE ISNUMERIC(answer_txt) = 1;

		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;
		
		BEGIN TRANSACTION;
		SET @Proc_Step_no = 18;
		SET @Proc_Step_Name = ' LOG Invalid Numeric data INTO ETL_DQ_LOG';
	
		INSERT INTO dbo.ETL_DQ_LOG( EVENT_TYPE, EVENT_LOCAL_ID, EVENT_UID, DQ_ISSUE_CD, DQ_ISSUE_DESC_TXT, DQ_ISSUE_QUESTION_IDENTIFIER, DQ_ISSUE_ANSWER_TXT, DQ_ISSUE_RDB_LOCATION, JOB_BATCH_LOG_UID, DQ_ETL_PROCESS_TABLE, DQ_ETL_PROCESS_COLUMN, DQ_STATUS_TIME, DQ_ISSUE_SOURCE_LOCATION, DQ_ISSUE_SOURCE_QUESTION_LABEL )
		(
		SELECT DISTINCT 'INVESTIGATION', inv.LOCAL_ID, inv.PUBLIC_HEALTH_CASE_UID, 
		'INVALID_NUMERIC_VALUE', 'BAD NUMERIC VALUE: A non-numeric value exists in a field expecting a numeric value and requires update. Please correct the bad numeric value so that it can be properly written to the reporting database during the next ETL run', 
		nrt_page.QUESTION_IDENTIFIER, ANSWER_VALUE, nrt_page.DATA_LOCATION, @Batch_id, nrt_page.rdb_table_nm, nrt_page.RDB_COLUMN_NM, 
		GETDATE(), nrt_page.DATA_LOCATION, QUESTION_LABEL
					FROM #CODED_TABLE_SNTEMP_INV
			 INNER JOIN
			 	dbo.nrt_investigation inv
			 	on #CODED_TABLE_SNTEMP_INV.page_case_uid = inv.public_health_case_uid
				 INNER JOIN
				 NBS_SRTE.DBO.CONDITION_CODE
				 ON CONDITION_CODE.CONDITION_CD = inv.CD
				 INNER JOIN 
				 dbo.nrt_page_case_answer nrt_page
				 ON nrt_page.act_uid = inv.public_health_case_uid
			WHERE nrt_page.act_uid = @phc_id
				AND (isNumeric(ANSWER_VALUE) != 1) 
				AND ANSWER_VALUE IS NOT NULL);
		
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );
	
		COMMIT TRANSACTION;
	
		BEGIN TRANSACTION;
		SET @Proc_Step_no = 19;
		SET @Proc_Step_Name = ' Update  CODED_TABLE_SNTEMP_TRANS_A_'+@category; 
		--CREATE TABLE CODED_TABLE_SNTEMP_TRANS_A
		IF OBJECT_ID('#CODED_TABLE_SNTEMP_TRANS_A_INV', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CODED_TABLE_SNTEMP_TRANS_A_INV;
		END;

		SELECT 
		--CODED.CODE_SET_GROUP_ID, 
		  PAGE_CASE_UID, ANSWER_TXT_CODE, ANSWER_VALUE, NBS_CASE_ANSWER_UID, METADATA.CODE_SET_NM, RDB_COLUMN_NM, METADATA.CODE, CODE_SHORT_DESC_TXT AS 'ANSWER_TXT2', MASK, coded.NBS_QUESTION_UID, CAST(NULL AS varchar(2000)) AS ANSWER_TXT, METADATA.INVESTIGATION_FORM_CD
		INTO #CODED_TABLE_SNTEMP_TRANS_A_INV
		FROM #CODED_TABLE_SNTEMP_INV AS CODED WITH(NOLOCK) LEFT
			 JOIN
			 REF_FORMCODE_TRANSLATION AS METADATA WITH(NOLOCK)
			 ON METADATA.INVESTIGATION_FORM_CD = CODED.INVESTIGATION_FORM_CD AND 
				METADATA.CODE_SET_GROUP_ID = CODED.CODE_SET_GROUP_ID AND 
				METADATA.CODE = CODED.ANSWER_TXT_CODE
			 ORDER BY NBS_CASE_ANSWER_UID, RDB_COLUMN_NM;
		SELECT @RowCount_no = @@ROWCOUNT;
		UPDATE #CODED_TABLE_SNTEMP_TRANS_A_INV SET ANSWER_VALUE=NULL WHERE  ISNUMERIC(ANSWER_VALUE)!=1;
		UPDATE #CODED_TABLE_SNTEMP_TRANS_A_INV
		  SET CODE_SET_NM = a.CODE_SET_NM, ANSWER_TXT_CODE = '', ANSWER_TXT2 = '', code = ''
		FROM
		(
			SELECT TOP 1 CODE_SET_NM, NBS_QUESTION_UID
			FROM #CODED_TABLE_SNTEMP_TRANS_A_INV
			WHERE CODE_SET_NM IS NOT NULL
		) AS a
		WHERE #CODED_TABLE_SNTEMP_TRANS_A_INV.NBS_QUESTION_UID = a.NBS_QUESTION_UID AND 
			  #CODED_TABLE_SNTEMP_TRANS_A_INV.code_set_nm IS NULL;

		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );


		COMMIT TRANSACTION;


		BEGIN TRANSACTION;
		SET @Proc_Step_no = 20;
		SET @Proc_Step_Name = ' UPDATE TABLE  CODED_TABLE_SNTEMP_TRANS_A_'+@category;

		UPDATE #CODED_TABLE_SNTEMP_TRANS_A_INV
		  SET ANSWER_TXT = REPLACE(ANSWER_VALUE, ' ', '')
		WHERE LEN(mask) > 0;
		UPDATE #CODED_TABLE_SNTEMP_TRANS_A_INV
		  SET ANSWER_TXT = REPLACE(ANSWER_VALUE, ' ', '') + ' ' + REPLACE(ANSWER_TXT2, ' ', '')
		WHERE LEN(mask) = 0;
		SELECT @RowCount_no = -1;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 21;
		SET @Proc_Step_Name = ' UPDATE TABLE  CODED_TABLE_SNTEMP_TRANS_CODE_'+@category;
		IF OBJECT_ID('#CODED_TABLE_SNTEMP_TRANS_CODE_INV', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CODED_TABLE_SNTEMP_TRANS_CODE_INV;
		END;

		SELECT *
		INTO #CODED_TABLE_SNTEMP_TRANS_CODE_INV
		FROM #CODED_TABLE_SNTEMP_TRANS_A_INV;
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 22;
		SET @Proc_Step_Name = ' UPDATE TABLE  CODED_TABLE_SNTEMP_TRANS_CODE_'+@category;
		UPDATE #CODED_TABLE_SNTEMP_TRANS_CODE_INV
		  SET RDB_COLUMN_NM = REPLACE(SUBSTRING(RDB_COLUMN_NM, 1, 25) + '_UNIT', ' ', ''), ANSWER_TXT = REPLACE(ANSWER_TXT2, '  ', ' ')
		WHERE LEN(mask) > 0;
		--alter table  dbo.CODED_TABLE_SNTEMP_TRANS_CODE_INV_HIV     drop column CODE_SET_GROUP_ID	;
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 23;
		SET @Proc_Step_Name = ' CREATE TABLE  CODED_TABLE_'+@category;
		IF OBJECT_ID('#CODED_TABLE_TEMP_INV', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CODED_TABLE_TEMP_INV;
		END;
	
		IF OBJECT_ID('#CODED_TABLE_CAT_INV', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CODED_TABLE_CAT_INV;
		END;

		SELECT COALESCE(csnta.NBS_CASE_ANSWER_UID, csntc.NBS_CASE_ANSWER_UID) AS NBS_CASE_ANSWER_UID, COALESCE(csnta.RDB_COLUMN_NM, csntc.RDB_COLUMN_NM) AS RDB_COLUMN_NM, COALESCE(csnta.PAGE_CASE_UID, csntc.PAGE_CASE_UID) AS PAGE_CASE_UID, COALESCE(csnta.ANSWER_TXT_CODE, csntc.ANSWER_TXT_CODE) AS ANSWER_TXT_CODE, COALESCE(csnta.ANSWER_VALUE, csntc.ANSWER_VALUE) AS ANSWER_VALUE, COALESCE(csnta.CODE_SET_NM, csntc.CODE_SET_NM) AS CODE_SET_NM, COALESCE(csnta.CODE, csntc.CODE) AS CODE, COALESCE(csnta.ANSWER_TXT2, csntc.ANSWER_TXT2) AS ANSWER_TXT2, COALESCE(csnta.MASK, csntc.MASK) AS MASK, COALESCE(csnta.ANSWER_TXT, csntc.ANSWER_TXT) AS ANSWER_TXT, COALESCE(csnta.nbs_question_uid, csntc.nbs_question_uid) AS nbs_question_uid
		INTO #CODED_TABLE_TEMP_INV
		FROM #CODED_TABLE_SNTEMP_TRANS_A_INV AS csnta
			 FULL OUTER JOIN
			 #CODED_TABLE_SNTEMP_TRANS_CODE_INV AS csntc
			 ON csnta.NBS_CASE_ANSWER_UID = csntc.NBS_CASE_ANSWER_UID AND 
				csnta.[RDB_COLUMN_NM] = csntc.[RDB_COLUMN_NM];
		SELECT CODE_SET_GROUP_ID, COALESCE(csnta.PAGE_CASE_UID, csntt.[PAGE_CASE_UID]) AS [PAGE_CASE_UID], COALESCE(csnta.NBS_QUESTION_UID, csntt.NBS_QUESTION_UID) AS [NBS_QUESTION_UID], COALESCE(csnta.NBS_QUESTION_UID, csntt.[NBS_CASE_ANSWER_UID]) AS [NBS_CASE_ANSWER_UID], COALESCE(csnta.ANSWER_TXT, csntt.[ANSWER_TXT]) AS [ANSWER_TXT], COALESCE(csnta.CODE_SET_NM, csntt.[CODE_SET_NM]) AS [CODE_SET_NM], COALESCE(csnta.RDB_COLUMN_NM, csntt.[RDB_COLUMN_NM]) AS [RDB_COLUMN_NM], ANSWER_OTH, COALESCE(csnta.CODE, csntt.[CODE]) AS [CODE], csnta.ANSWER_TXT1, csntt.[ANSWER_TXT_CODE], csntt.[ANSWER_VALUE], csntt.[ANSWER_TXT2], csntt.[MASK]
		INTO #CODED_TABLE_CAT_INV
		FROM #CODED_TABLE_STD_INV AS csnta
			 FULL OUTER JOIN
			 #CODED_TABLE_TEMP_INV AS csntt
			 ON csnta.NBS_CASE_ANSWER_UID = csntt.NBS_CASE_ANSWER_UID AND 
				csnta.[RDB_COLUMN_NM] = csntt.[RDB_COLUMN_NM];
		SELECT @RowCount_no = @@ROWCOUNT;
		
		CREATE NONCLUSTERED INDEX [RDB_PERF_INTERNAL_02]
		ON #CODED_TABLE_CAT_INV
		( [CODE_SET_GROUP_ID]
		) 
		INCLUDE( [PAGE_CASE_UID], [NBS_QUESTION_UID], [NBS_CASE_ANSWER_UID], [ANSWER_TXT], [RDB_COLUMN_NM], [ANSWER_OTH] );

		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 24;
		SET @Proc_Step_Name = ' UPDATE TABLE  CODED_TABLE_'+@category;
		UPDATE #CODED_TABLE_CAT_INV
		  SET ANSWER_TXT1 = ANSWER_TXT
		WHERE RTRIM(ANSWER_TXT1) = '';
		
		if @debug = 'true'
			select * from #CODED_TABLE_CAT_INV
	
		IF OBJECT_ID('#CODED_TABLE_DESC_INV_TEMP', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CODED_TABLE_DESC_INV_TEMP;
		END;

		SELECT p1.PAGE_CASE_UID, p1.NBS_QUESTION_UID, STUFF(
		(
			SELECT TOP 10 ' | ' + ANSWER_TXT1
			FROM #CODED_TABLE_CAT_INV AS p2
			WHERE p2.PAGE_CASE_UID = p1.PAGE_CASE_UID AND 
				  p2.nbs_question_uid = p1.NBS_QUESTION_UID
			ORDER BY PAGE_CASE_UID, NBS_QUESTION_UID, NBS_CASE_ANSWER_UID FOR XML PATH(''), TYPE
		).value( '.', 'varchar(2000)' ), 1, 3, '') AS ANSWER_DESC11
		INTO #CODED_TABLE_DESC_INV_TEMP
		FROM #CODED_TABLE_CAT_INV AS p1
		--where  nbs_question_uid is not null
		GROUP BY PAGE_CASE_UID, RDB_COLUMN_NM, NBS_QUESTION_UID;
		
		if @debug = 'true'
			select * from #CODED_TABLE_DESC_INV_TEMP
	
		IF OBJECT_ID('#CODED_TABLE_DESC_INV', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CODED_TABLE_DESC_INV;
		END;

		SELECT ct.*, COALESCE(ctt.answer_desc11, ct.answer_txt1) AS answer_desc11
		INTO #CODED_TABLE_DESC_INV
		FROM #CODED_TABLE_CAT_INV AS ct LEFT
			 OUTER JOIN
			 #CODED_TABLE_DESC_INV_TEMP AS ctt
			 ON ct.PAGE_CASE_UID = ctt.PAGE_CASE_UID AND 
				ct.NBS_QUESTION_UID = ctt.NBS_QUESTION_UID;
		SELECT @RowCount_no = @@ROWCOUNT;

	    INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;
	
		if @debug = 'true'
			select * from #CODED_TABLE_DESC_INV
	
		BEGIN TRANSACTION;
		SET @Proc_Step_no = 26;
		SET @Proc_Step_Name = 'CREATE TABLE  CODED_COUNTY_TABLE_'+@category; 
		--CREATE TABLE 	CODED_COUNTY_TABLE 
		IF OBJECT_ID('#CODED_COUNTY_TABLE_INV', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CODED_COUNTY_TABLE_INV;
		END;

		SELECT CODED.CODE_SET_GROUP_ID, PAGE_CASE_UID, NBS_QUESTION_UID, NBS_CASE_ANSWER_UID, ANSWER_TXT, CVG.CODE_SET_NM, RDB_COLUMN_NM, ANSWER_OTH, CVG.CODE, CODE_SHORT_DESC_TXT AS 'ANSWER_TXT1'
		INTO #CODED_COUNTY_TABLE_INV
		FROM #CODED_TABLE_INV AS CODED WITH(NOLOCK) LEFT
			 JOIN
			 NBS_SRTE.dbo.CODESET_GROUP_METADATA AS METADATA WITH(NOLOCK)
			 ON METADATA.CODE_SET_GROUP_ID = CODED.CODE_SET_GROUP_ID LEFT
															   JOIN
															   NBS_SRTE.dbo.V_STATE_COUNTY_CODE_VALUE AS CVG WITH(NOLOCK)
															   ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM AND 
																  CVG.CODE = CODED.ANSWER_TXT
		WHERE METADATA.CODE_SET_NM = 'COUNTY_CCD';
		
		IF OBJECT_ID('#CODED_COUNTY_TABLE_DESC_INV_TEMP', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CODED_COUNTY_TABLE_DESC_INV_TEMP;
		END;

		SELECT p1.PAGE_CASE_UID, p1.NBS_QUESTION_UID, STUFF(
		(
			SELECT TOP 10 ' |' + ANSWER_TXT1
			FROM #CODED_COUNTY_TABLE_INV AS p2
			WHERE p2.PAGE_CASE_UID = p1.PAGE_CASE_UID AND 
				  p2.nbs_question_uid = p1.NBS_QUESTION_UID
			ORDER BY PAGE_CASE_UID, NBS_QUESTION_UID, NBS_CASE_ANSWER_UID FOR XML PATH(''), TYPE
		).value( '.', 'varchar(2000)' ), 1, 2, '') AS ANSWER_DESC11
		INTO #CODED_COUNTY_TABLE_DESC_INV_TEMP
		FROM #CODED_COUNTY_TABLE_INV AS p1
		GROUP BY PAGE_CASE_UID, NBS_QUESTION_UID;
	
		IF OBJECT_ID('#CODED_COUNTY_TABLE_DESC_INV', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CODED_COUNTY_TABLE_DESC_INV;
		END;

		SELECT cct.*, cctt.answer_desc11
		INTO #CODED_COUNTY_TABLE_DESC_INV
		FROM #CODED_COUNTY_TABLE_INV AS cct LEFT
			 OUTER JOIN
			 #CODED_COUNTY_TABLE_DESC_INV_TEMP AS cctt
			 ON cct.PAGE_CASE_UID = cctt.PAGE_CASE_UID AND 
				cct.NBS_QUESTION_UID = cctt.NBS_QUESTION_UID;
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 27;
		SET @Proc_Step_Name = 'CREATE TABLE CODED_TABLE_MERGED_'+@category;
		IF OBJECT_ID('#CODED_TABLE_MERGED_TEMP_INV', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CODED_TABLE_MERGED_TEMP_INV;
		END;
		IF OBJECT_ID('#CODED_TABLE_MERGED_INV', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CODED_TABLE_MERGED_INV;
		END;

		SELECT temp_tbl.*
		INTO #CODED_TABLE_MERGED_INV
		FROM
		(
			SELECT [CODE_SET_GROUP_ID], [PAGE_CASE_UID], [NBS_QUESTION_UID], [NBS_CASE_ANSWER_UID], [ANSWER_TXT], [CODE_SET_NM], [RDB_COLUMN_NM], [ANSWER_OTH], [CODE], [ANSWER_TXT1], [answer_desc11], [ANSWER_TXT_CODE], [ANSWER_VALUE], [ANSWER_TXT2], [MASK], NULL AS OTHER_VALUE_IND_CD, NULL AS RDB_COLUMN_NM2
			FROM #CODED_TABLE_DESC_INV
			UNION ALL
			SELECT [CODE_SET_GROUP_ID], [PAGE_CASE_UID], [NBS_QUESTION_UID], [NBS_CASE_ANSWER_UID], [ANSWER_TXT], [CODE_SET_NM], [RDB_COLUMN_NM], [ANSWER_OTH], [CODE], [ANSWER_TXT1], [answer_desc11], NULL, NULL, NULL, NULL, NULL, NULL
			FROM #CODED_COUNTY_TABLE_DESC_INV
			UNION ALL
			SELECT [CODE_SET_GROUP_ID], [PAGE_CASE_UID], [NBS_CASE_ANSWER_UID], [NBS_QUESTION_UID], [ANSWER_TXT], NULL, [RDB_COLUMN_NM], NULL, NULL, NULL, [ANSWER_DESC11], NULL, NULL, NULL, NULL, [OTHER_VALUE_IND_CD], [RDB_COLUMN_NM2]
			FROM #CODED_TABLE_OTHER_INV
		) AS temp_tbl;
	
		CREATE NONCLUSTERED INDEX [RDB_PERF_INTERNAL_04]
		ON #CODED_TABLE_MERGED_INV
		( [RDB_COLUMN_NM]
		);

		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );
	
		COMMIT TRANSACTION;

		if @debug = 'true'
			select * from #CODED_TABLE_MERGED_INV;
		

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 31;
		SET @Proc_Step_Name = ' CREATE TABLE DATE_DATA_'+@category; 
		-- CREATE TABLE DATE_DATA AS
		IF OBJECT_ID('#DATE_DATA_INV', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #DATE_DATA_INV;
		END;

		SELECT NBS_CASE_ANSWER_UID, nrt_page.CODE_SET_GROUP_ID, nrt_page.RDB_COLUMN_NM, 
			(CASE
			  WHEN ISDATE(ANSWER_TXT) = 1 THEN ANSWER_TXT
			  ELSE NULL
			  END ) AS ANSWER_TXT1, ACT_UID AS PAGE_CASE_UID, nrt_page.RECORD_STATUS_CD, 
			  nrt_page.NBS_QUESTION_UID, ( CASE
											 WHEN ISDATE(ANSWER_TXT) = 1 THEN ANSWER_TXT
											 ELSE NULL
											 END ) AS ANSWER_TXT,
			nrt_page.INVESTIGATION_FORM_CD, CODE_SET_GROUP_ID AS CODE_SET_GROUP_ID1, QUESTION_GROUP_SEQ_NBR, DATA_TYPE
		INTO #DATE_DATA_INV
		FROM dbo.nrt_page_case_answer AS nrt_page WITH(NOLOCK) --4
				LEFT OUTER JOIN
					NBS_SRTE.dbo.CODE_VALUE_GENERAL AS CVG WITH(NOLOCK)
					ON UPPER(CVG.CODE) = UPPER(nrt_page.DATA_TYPE)
		WHERE nrt_page.act_uid = @phc_id 
			AND nrt_page.ANSWER_GROUP_SEQ_NBR IS NULL 
			AND CVG.CODE_SET_NM = 'NBS_DATA_TYPE' 
			AND CODE IN( 'DATETIME', 'DATE' ) 
			AND nrt_page.RDB_TABLE_NM = @rdb_table_name AND 
			  QUESTION_GROUP_SEQ_NBR IS NULL AND 
			  DATA_TYPE IN( 'Date/Time', 'Date', 'DATETIME', 'DATE' )
		ORDER BY ACT_UID, NBS_CASE_ANSWER_UID, nrt_page.CODE_SET_GROUP_ID;

		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		INSERT INTO dbo.ETL_DQ_LOG( EVENT_TYPE, EVENT_LOCAL_ID, EVENT_UID, DQ_ISSUE_CD, DQ_ISSUE_DESC_TXT, DQ_ISSUE_QUESTION_IDENTIFIER, DQ_ISSUE_ANSWER_TXT, DQ_ISSUE_RDB_LOCATION, JOB_BATCH_LOG_UID, DQ_ETL_PROCESS_TABLE, DQ_ETL_PROCESS_COLUMN, DQ_STATUS_TIME, DQ_ISSUE_SOURCE_LOCATION, DQ_ISSUE_SOURCE_QUESTION_LABEL )
		(
			SELECT 'INVESTIGATION', inv.LOCAL_ID, inv.PUBLIC_HEALTH_CASE_UID, 'INVALID_DATE', 'BAD DATE: A poorly formatted date exists and requires update. Please correct the bad date so that it can be properly written to the reporting database during the next ETL run.', nrt_page.QUESTION_IDENTIFIER, ANSWER_TXT, nrt_page.DATA_LOCATION, @Batch_id, nrt_page.rdb_table_nm, nrt_page.RDB_COLUMN_NM, GETDATE(), nrt_page.DATA_LOCATION, nrt_page.QUESTION_LABEL
			FROM dbo.nrt_page_case_answer nrt_page
				 INNER JOIN
				 dbo.nrt_investigation inv
				 ON nrt_page.ACT_UID = inv.PUBLIC_HEALTH_CASE_UID
				 INNER JOIN
				 NBS_SRTE.DBO.CONDITION_CODE
				 ON CONDITION_CODE.CONDITION_CD = inv.CD
			WHERE nrt_page.act_uid = @phc_id
				  AND DATA_TYPE IN ( 'Date/Time', 'Date', 'DATETIME', 'DATE' ) AND 
				  (ISDATE(ANSWER_TXT) != 1) AND 
				  UPPER(nrt_page.DATA_LOCATION) = 'NBS_CASE_ANSWER.ANSWER_TXT' AND 
				 ANSWER_TXT IS NOT NULL AND 
				  nrt_page.rdb_table_nm = @rdb_table_name
				  AND CONDITION_CODE.INVESTIGATION_FORM_CD = nrt_page.INVESTIGATION_FORM_CD
		);
	

		COMMIT TRANSACTION;
	
		BEGIN TRANSACTION;
		SET @Proc_Step_no = 32;
		SET @Proc_Step_Name = ' UPDATE TABLE date_data_INV';
		UPDATE #DATE_DATA_INV
		  SET ANSWER_TXT1 = FORMAT(CAST([ANSWER_TXT] AS date), 'MM/dd/yy') + ' 00:00:00';
		--SET ANSWER_TXT=dhms(input(ANSWER_TXT1,MMDDYY10.),0,0,0); 
		--DROP ANSWER_TXT;
		--RENAME ANSWER_TXT=ANSWER_TXT1;   
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;


		BEGIN TRANSACTION;
		SET @Proc_Step_no = 36;
		SET @Proc_Step_Name = ' CREATE TABLE PAGE_DATE_TABLE_'+@category;
		IF OBJECT_ID('#PAGE_DATE_TABLE_INV', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #PAGE_DATE_TABLE_INV;
		END;

		CREATE TABLE #PAGE_DATE_TABLE_INV
		( 
				NBS_CASE_ANSWER_UID bigint, CODE_SET_GROUP_ID bigint, RDB_COLUMN_NM char(40), ANSWER_TXT1 date, PAGE_CASE_UID bigint, LAST_CHG_TIME date, RECORD_STATUS_CD char(40)
		);
 
		--IF PAGE_CASE_UID=. THEN PAGE_CASE_UID= 1;
		UPDATE #DATE_DATA_INV
		  SET PAGE_CASE_UID = 1
		WHERE PAGE_CASE_UID IS NULL;
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 37;
		SET @Proc_Step_Name = ' UPDATE TABLE  PAGE_DATE_TABLE_'+@category; 
		--%DBLOAD (PAGE_DATE_TABLE, DATE_DATA); 
		INSERT INTO #PAGE_DATE_TABLE_INV( NBS_CASE_ANSWER_UID, CODE_SET_GROUP_ID, RDB_COLUMN_NM, ANSWER_TXT1, PAGE_CASE_UID, RECORD_STATUS_CD )
			   SELECT NBS_CASE_ANSWER_UID, CODE_SET_GROUP_ID, RDB_COLUMN_NM, CAST(ANSWER_TXT1 AS datetime), PAGE_CASE_UID, 
			   --	LAST_CHG_TIME , 
			   RECORD_STATUS_CD
			   FROM #DATE_DATA_INV;
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;

		BEGIN TRANSACTION;

		DECLARE @date_output_table_name varchar(500) = ''
		SET @Proc_Step_no = 39;
		SET @date_output_table_name = '##date_data_INV_out_'+@category+'_'+CAST(@Batch_id as varchar(50));	
	
		SET @Proc_Step_Name = ' Generating FINAL TABLE FOR '+@date_output_table_name;
		
		EXEC ('IF OBJECT_ID(''tempdb..'+@date_output_table_name+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@date_output_table_name+';
		END;')
			
		SET @columns = N'';
		SELECT @columns+=N', p.' + QUOTENAME(LTRIM(RTRIM([RDB_COLUMN_NM])))
		FROM
		(
			SELECT [RDB_COLUMN_NM]
			FROM #PAGE_DATE_TABLE_INV AS p
			GROUP BY [RDB_COLUMN_NM]
		) AS x;
		
		SET @sql = N'
		SELECT [PAGE_CASE_UID] as PAGE_CASE_UID_date, ' + STUFF(@columns, 1, 2, '') + ' into '+@date_output_table_name + ' FROM (
		SELECT [PAGE_CASE_UID], [answer_txt1] , [RDB_COLUMN_NM] 
		FROM #PAGE_DATE_TABLE_INV
		group by [PAGE_CASE_UID], [answer_txt1] , [RDB_COLUMN_NM] 
		) AS j PIVOT (max(answer_txt1) FOR [RDB_COLUMN_NM] in 
	   (' + STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '') + ')) AS p;';

		if @debug = 'true'
			PRINT @sql;	
	  
		EXEC sp_executesql @sql;
		
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		--- If the #PAGE_date_table_inv table does not have any records create the table with default column 	
		EXEC ('IF OBJECT_ID(''tempdb..'+@date_output_table_name+''', ''U'') IS NULL
		BEGIN
			CREATE TABLE '+@date_output_table_name+'
			( 
						 [PAGE_CASE_UID_date] [bigint] NULL,
			)
			
		END;') 

		if @debug = 'true'
	  		EXEC ('select * from '+@date_output_table_name)		
	
		COMMIT TRANSACTION;

		---*************************************************************
		---** START PROCESSING NUMERIC QUESTIONS AND ANSWERS *************	
	
		BEGIN TRANSACTION;
		SET @Proc_Step_no = 41;
		SET @Proc_Step_Name = ' CREATE TABLE  NUMERIC_BASE_DATA_INV_CAT';
		IF OBJECT_ID('#NUMERIC_BASE_DATA_INV_CAT', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #NUMERIC_BASE_DATA_INV_CAT;
		END;

		SELECT NBS_CASE_ANSWER_UID, nrt_page.CODE_SET_GROUP_ID, nrt_page.RDB_COLUMN_NM, CAST(ANSWER_TXT AS varchar(2000)) AS ANSWER_TXT, ACT_UID AS PAGE_CASE_UID, nrt_page.RECORD_STATUS_CD, nrt_page.NBS_QUESTION_UID, LEN(RTRIM(ANSWER_TXT)) AS TXT_LEN, CAST(NULL AS [varchar](2000)) AS ANSWER_UNIT, CAST(NULL AS int) AS LENCODED, 
		CAST(NULL AS [varchar](2000)) AS ANSWER_CODED, CAST(NULL AS [varchar](2000)) AS UNIT_VALUE1, CAST(NULL AS [varchar](30)) AS RDB_COLUMN_NM2,
		CODE_SET_GROUP_ID AS CODE_SET_GROUP_ID1, QUESTION_GROUP_SEQ_NBR, DATA_TYPE
		INTO #NUMERIC_BASE_DATA_INV_CAT
		FROM dbo.nrt_page_case_answer AS nrt_page WITH(NOLOCK) --5
			INNER JOIN
			NBS_SRTE.dbo.CODE_VALUE_GENERAL AS CVG WITH(NOLOCK)
			ON UPPER(CVG.CODE) = UPPER(nrt_page.DATA_TYPE)
		WHERE nrt_page.act_uid=@phc_id 
			AND nrt_page.ANSWER_GROUP_SEQ_NBR IS NULL 
			AND CVG.CODE_SET_NM = 'NBS_DATA_TYPE' 
			AND CODE IN( 'Numeric', 'NUMERIC' )
			AND nrt_page.RDB_TABLE_NM = @rdb_table_name AND 
			  nrt_page.QUESTION_GROUP_SEQ_NBR IS NULL AND 
			  nrt_page.DATA_TYPE IN( 'Numeric', 'NUMERIC' ) AND 
			  nrt_page.nbs_question_uid NOT IN
				(
					SELECT nbs_question_uid
					FROM #CODED_TABLE_SNTEMP_TRANS_A_INV
				)
		ORDER BY ACT_UID, NBS_CASE_ANSWER_UID, nrt_page.CODE_SET_GROUP_ID;
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 43;
		SET @Proc_Step_Name = ' UPDATE TABLE  #NUMERIC_BASE_DATA_INV_CAT'; 

		UPDATE #NUMERIC_BASE_DATA_INV_CAT
		  SET ANSWER_UNIT = SUBSTRING(ANSWER_TXT, 1, ( CHARINDEX('^', ANSWER_TXT) - 1 ))
		WHERE CHARINDEX('^', ANSWER_TXT) > 0;
		UPDATE #NUMERIC_BASE_DATA_INV_CAT
		  SET LENCODED = LEN(RTRIM(ANSWER_UNIT))
		WHERE CHARINDEX('^', ANSWER_TXT) > 0;
		UPDATE #NUMERIC_BASE_DATA_INV_CAT
		  SET ANSWER_CODED = SUBSTRING(ANSWER_TXT, ( LENCODED + 2 ), TXT_LEN)
		WHERE CHARINDEX('^', ANSWER_TXT) > 0;
		UPDATE #NUMERIC_BASE_DATA_INV_CAT
		  SET UNIT_VALUE1 = REPLACE(ANSWER_UNIT, ',', '')
		WHERE CHARINDEX('^', ANSWER_TXT) > 0;
		UPDATE #NUMERIC_BASE_DATA_INV_CAT
		  SET RDB_COLUMN_NM2 = SUBSTRING(RTRIM(RDB_COLUMN_NM), 1, 25) + ' UNIT'
		WHERE LEN(RTRIM(ANSWER_CODED)) > 0;
		IF OBJECT_ID('#NUMERIC_DATA_2_INV_CAT', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #NUMERIC_DATA_2_INV_CAT;
		END;

		SELECT *
		INTO #NUMERIC_DATA_2_INV_CAT
		FROM #NUMERIC_BASE_DATA_INV_CAT;
		UPDATE #NUMERIC_DATA_2_INV_CAT
		  SET RDB_COLUMN_NM = RDB_COLUMN_NM2
		WHERE LEN(RTRIM(RDB_COLUMN_NM2)) > 0;
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;

	
		BEGIN TRANSACTION;
		SET @Proc_Step_no = 44;
		SET @Proc_Step_Name = ' CREATE TABLE  NUMERIC_DATA_MERGED_INV_CAT';
		IF OBJECT_ID('#NUMERIC_DATA_MERGED_INV_CAT', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #NUMERIC_DATA_MERGED_INV_CAT;
		END;

		SELECT COALESCE(nbd.NBS_CASE_ANSWER_UID, nd2.NBS_CASE_ANSWER_UID) AS NBS_CASE_ANSWER_UID, COALESCE(nbd.[RDB_COLUMN_NM2], nd2.[RDB_COLUMN_NM2]) AS [RDB_COLUMN_NM2], COALESCE(nbd.[CODE_SET_GROUP_ID], nd2.[CODE_SET_GROUP_ID]) AS [CODE_SET_GROUP_ID], COALESCE(nbd.[RDB_COLUMN_NM], nd2.[RDB_COLUMN_NM]) AS [RDB_COLUMN_NM], COALESCE(nbd.[ANSWER_TXT], nd2.[ANSWER_TXT]) AS [ANSWER_TXT], COALESCE(nbd.[PAGE_CASE_UID], nd2.[PAGE_CASE_UID]) AS [PAGE_CASE_UID], COALESCE(nbd.[RECORD_STATUS_CD], nd2.[RECORD_STATUS_CD]) AS [RECORD_STATUS_CD], COALESCE(nbd.[NBS_QUESTION_UID], nd2.[NBS_QUESTION_UID]) AS [NBS_QUESTION_UID], COALESCE(nbd.[TXT_LEN], nd2.[TXT_LEN]) AS [TXT_LEN], COALESCE(nbd.[ANSWER_UNIT], nd2.[ANSWER_UNIT]) AS [ANSWER_UNIT], COALESCE(nbd.[LENCODED], nd2.[LENCODED]) AS [LENCODED], COALESCE(nbd.[ANSWER_CODED], nd2.[ANSWER_CODED]) AS [ANSWER_CODED], COALESCE(nbd.[UNIT_VALUE1], nd2.[UNIT_VALUE1]) AS [UNIT_VALUE1]
		INTO #NUMERIC_DATA_MERGED_INV_CAT
		FROM #NUMERIC_BASE_DATA_INV_CAT AS nbd
			 FULL OUTER JOIN
			 #NUMERIC_DATA_2_INV_CAT AS nd2
			 ON nbd.NBS_CASE_ANSWER_UID = nd2.NBS_CASE_ANSWER_UID AND 
				nbd.[RDB_COLUMN_NM] = nd2.[RDB_COLUMN_NM];
		SELECT @RowCount_no = @@ROWCOUNT;

		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 45;
		SET @Proc_Step_Name = ' CREATE TABLE  NUMERIC_DATA_TRANS_INV_CAT'; 
		--CREATE TABLE 	NUMERIC_DATA_TRANS  AS 
		IF OBJECT_ID('#NUMERIC_DATA_TRANS_INV_CAT', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #NUMERIC_DATA_TRANS_INV_CAT;
		END;

		SELECT PAGE_CASE_UID, NBS_QUESTION_UID, NBS_CASE_ANSWER_UID, ANSWER_UNIT, ANSWER_CODED, CVG.CODE_SET_NM, RDB_COLUMN_NM, ANSWER_TXT, CODE, CODE_SHORT_DESC_TXT AS UNIT, CAST(NULL AS [varchar](2000)) AS ANSWER_TXT_F
		INTO #NUMERIC_DATA_TRANS_INV_CAT
		FROM #NUMERIC_DATA_MERGED_INV_CAT AS CODED WITH(NOLOCK) LEFT
			 JOIN
			 NBS_SRTE.dbo.CODESET_GROUP_METADATA AS METADATA WITH(NOLOCK)
			 ON METADATA.CODE_SET_GROUP_ID = CODED.CODE_SET_GROUP_ID LEFT
																	   JOIN
																	   NBS_SRTE.dbo.CODE_VALUE_GENERAL AS CVG WITH(NOLOCK)
																	   ON CVG.CODE_SET_NM = METADATA.CODE_SET_NM
		WHERE CVG.CODE = CODED.ANSWER_CODED OR 
			  ANSWER_CODED IS NULL
		ORDER BY PAGE_CASE_UID;
		UPDATE #NUMERIC_DATA_TRANS_INV_CAT
		  SET PAGE_CASE_UID = COALESCE(PAGE_CASE_UID, 1), ANSWER_TXT_F = CASE
																		 WHEN COALESCE(RTRIM(UNIT), '') = '' THEN ANSWER_TXT
																		 WHEN CHARINDEX(' UNIT', RDB_COLUMN_NM) > 0 THEN UNIT
																		 ELSE ANSWER_UNIT
																		 END;

		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		
		COMMIT TRANSACTION;

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 48;
		SET @Proc_Step_Name = ' UPDATE TABLE  CODED_TABLE_SNTEMP_TRANS_A_INV_CAT'; 

		IF OBJECT_ID('#NUMERIC_DATA_TRANS1_INV_CAT', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #NUMERIC_DATA_TRANS1_INV_CAT;
		END;
	/**
		IF OBJECT_ID('#CODED_TABLE_MERGED_INV', 'U') IS NULL
		BEGIN
			CREATE TABLE #CODED_TABLE_MERGED_INV
			( 
				[RDB_COLUMN_NM] [varchar](30) NULL, [ANSWER_TXT] [varchar](2000) NULL
			)
			ON [PRIMARY];
		END;
		**/

		SELECT DISTINCT 
			   ndtis.PAGE_CASE_UID, ndtis.RDB_COLUMN_NM, ANSWER_UNIT, ANSWER_TXT_F AS ANSWER_TXT
		INTO #NUMERIC_DATA_TRANS1_INV_CAT
		FROM #NUMERIC_DATA_TRANS_INV_CAT AS ndtis LEFT
			 OUTER JOIN
			 #CODED_TABLE_MERGED_INV AS ctmis
			 ON ndtis.RDB_COLUMN_NM = ctmis.RDB_COLUMN_NM AND 
				ctmis.answer_txt IS NOT NULL AND 
				ctmis.RDB_COLUMN_NM IS NULL;
			

		COMMIT TRANSACTION;
		
		if @debug = 'true'
			select * from #NUMERIC_DATA_TRANS1_INV_CAT;

		BEGIN TRANSACTION;
		WITH lst
			 AS (SELECT ndtis.rdb_column_nm,
							  CASE
							  WHEN ndtis.answer_txt IS NOT NULL THEN 1
							  ELSE 0
							  END AS Ans_null
				 FROM #NUMERIC_DATA_TRANS1_INV_CAT AS ndtis LEFT
					  OUTER JOIN
					  #CODED_TABLE_MERGED_INV AS ctmis
					  ON ndtis.RDB_COLUMN_NM = ctmis.RDB_COLUMN_NM AND 
						 ctmis.answer_txt IS NOT NULL AND 
						 ctmis.RDB_COLUMN_NM IS NULL)
			 DELETE FROM #CODED_TABLE_MERGED_INV
			 WHERE RDB_COLUMN_NM IN
			 (
				 SELECT rdb_column_nm
				 FROM lst
				 WHERE ans_null != 0
			 );

		COMMIT TRANSACTION;

		BEGIN TRANSACTION;
		WITH lst
			 AS (SELECT rdb_column_nm,
						CASE
						WHEN answer_txt IS NOT NULL THEN 1
						ELSE 0
						END AS Ans_null
				 FROM #NUMERIC_DATA_TRANS1_INV_CAT
				 WHERE RDB_COLUMN_NM IN
				 (
					 SELECT RDB_COLUMN_NM
					 FROM #CODED_TABLE_MERGED_INV
					 GROUP BY rdb_column_nm
				 )
				 GROUP BY rdb_column_nm,
						  CASE
						  WHEN answer_txt IS NOT NULL THEN 1
						  ELSE 0
						  END)
			 DELETE FROM #NUMERIC_DATA_TRANS1_INV_CAT
			 WHERE rdb_column_nm IN
			 (
				 SELECT rdb_column_nm
				 FROM lst
				 WHERE ans_null = 0
				 EXCEPT
				 SELECT rdb_column_nm
				 FROM lst
				 WHERE ans_null = 1
			 );
		COMMIT TRANSACTION;
	
		BEGIN TRANSACTION;
		DECLARE @coded_output_table_name varchar(500) = ''
		
		SET @Proc_Step_no = 49;
	
		SET @coded_output_table_name = '##CODED_DATA_INV_CAT_out_'+@category+'_'+CAST(@Batch_id as varchar(50));	
	
		SET @Proc_Step_Name = ' Generating '+@coded_output_table_name;
		
		EXEC ('IF OBJECT_ID(''tempdb..'+@coded_output_table_name+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@coded_output_table_name+';
		END;')
	
		IF OBJECT_ID('#CODED_TABLE_MERGED_INV', 'U') IS NOT NULL
		BEGIN
			UPDATE #CODED_TABLE_MERGED_INV
			  SET answer_desc11 = NULL
			WHERE answer_desc11 = '';
		END;

		IF OBJECT_ID('#CODED_TABLE_MERGED_INV', 'U') IS NOT NULL
		BEGIN
			UPDATE #CODED_TABLE_MERGED_INV
			  SET answer_desc11 = ANSWER_VALUE
			WHERE ANSWER_OTH IS NOT NULL AND 
				  ANSWER_VALUE IS NOT NULL AND 
				  answer_desc11 IS NULL AND 
				  answer_oth IS NOT NULL;
		END;

		IF OBJECT_ID('#CODED_TABLE_MERGED_INV', 'U') IS NOT NULL
		BEGIN
			UPDATE #CODED_TABLE_MERGED_INV
			  SET answer_desc11 = ANSWER_TXT
			WHERE ANSWER_OTH IS NULL AND 
				  ANSWER_TXT2 IS NOT NULL AND 
				  ( answer_desc11 IS NULL
				  ) AND 
				  answer_oth IS NULL AND 
				  LEN(ANSWER_TXT2) > 0;
		END;

		IF OBJECT_ID('#CODED_TABLE_MERGED_INV', 'U') IS NOT NULL
		BEGIN
			UPDATE #CODED_TABLE_MERGED_INV
			  SET answer_desc11 = ANSWER_TXT
			WHERE ANSWER_OTH IS NULL AND 
				  ANSWER_TXT2 IS NOT NULL AND 
				  ( answer_desc11 IS NULL
				  ) AND 
				  answer_oth IS NULL AND 
				  LEN(ANSWER_TXT) > 0;
		END;



		IF OBJECT_ID('#CODED_TABLE_MERGED_INV', 'U') IS NOT NULL
		BEGIN
			UPDATE #CODED_TABLE_MERGED_INV
			  SET answer_desc11 = ANSWER_VALUE
			WHERE ANSWER_OTH IS NULL AND 
				  ANSWER_VALUE IS NOT NULL AND 
				  answer_desc11 IS NULL AND 
				  answer_txt IS NOT NULL AND 
				  code = '';
		END;

		IF OBJECT_ID('#CODED_TABLE_MERGED_INV', 'U') IS NOT NULL
		BEGIN
			UPDATE #CODED_TABLE_MERGED_INV
			  SET answer_desc11 = ANSWER_TXT
			WHERE answer_desc11 IS NULL AND 
				  ANSWER_OTH IS NULL AND 
				  ANSWER_TXT2 IS NULL AND 
				  answer_oth IS NULL AND 
				  ANSWER_TXT IS NOT NULL AND 
				  ANSWER_TXT <> ''
		END;

		SET @columns = N'';
		SELECT @columns+=N', p.' + QUOTENAME(LTRIM(RTRIM([RDB_COLUMN_NM])))
		FROM
		(
			SELECT [RDB_COLUMN_NM]
			FROM #CODED_TABLE_MERGED_INV AS p
			GROUP BY [RDB_COLUMN_NM]
		) AS x;
		SET @sql = N'
		SELECT [PAGE_CASE_UID] as PAGE_CASE_UID_coded, ' + STUFF(@columns, 1, 2, '') + ' into '+@coded_output_table_name+'  FROM (
		SELECT [PAGE_CASE_UID], [ANSWER_DESC11] , [RDB_COLUMN_NM] 
		 FROM #CODED_TABLE_MERGED_INV
			group by [PAGE_CASE_UID], [ANSWER_DESC11] , [RDB_COLUMN_NM] 
		) AS j PIVOT (max(ANSWER_DESC11) FOR [RDB_COLUMN_NM] in 
	   (' + STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '') + ')) AS p;';
		
	  	if @debug = 'true'
	  		PRINT @sql;
	  	
		EXEC sp_executesql @sql;
		
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		--- If the #text_data_inv table does not have any records create the table with default column 	
		EXEC ('IF OBJECT_ID(''tempdb..'+@coded_output_table_name+''', ''U'') IS NULL
		BEGIN
			CREATE TABLE '+@coded_output_table_name+'
			( 
				[PAGE_CASE_UID_coded] [bigint] NULL,
			)
			
		END;') 

		if @debug = 'true'
	  		EXEC ('select * from '+@coded_output_table_name)			
	
	
	
		COMMIT TRANSACTION;

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 49;
		SET @Proc_Step_Name = ' LOG Invalid Numeric data INTO ETL_DQ_LOG';
	
		INSERT INTO dbo.ETL_DQ_LOG( EVENT_TYPE, EVENT_LOCAL_ID, EVENT_UID, DQ_ISSUE_CD, DQ_ISSUE_DESC_TXT, DQ_ISSUE_QUESTION_IDENTIFIER, DQ_ISSUE_ANSWER_TXT, DQ_ISSUE_RDB_LOCATION, JOB_BATCH_LOG_UID, DQ_ETL_PROCESS_TABLE, DQ_ETL_PROCESS_COLUMN, DQ_STATUS_TIME, DQ_ISSUE_SOURCE_LOCATION, DQ_ISSUE_SOURCE_QUESTION_LABEL )
		(
			SELECT DISTINCT 'INVESTIGATION', inv.LOCAL_ID, inv.PUBLIC_HEALTH_CASE_UID, 
			'INVALID_NUMERIC_VALUE', 'BAD NUMERIC VALUE: A non-numeric value exists in a field expecting a numeric value and requires update. Please correct the bad numeric value so that it can be properly written to the reporting database during the next ETL run', 
			nrt_page.QUESTION_IDENTIFIER, numeric_inv.ANSWER_TXT, nrt_page.DATA_LOCATION, @Batch_id, nrt_page.rdb_table_nm, nrt_page.RDB_COLUMN_NM, 
			GETDATE(), nrt_page.DATA_LOCATION, QUESTION_LABEL
			FROM #NUMERIC_DATA_TRANS1_INV_CAT numeric_inv
			    INNER JOIN
			 	dbo.nrt_investigation inv 
			 	ON numeric_inv.page_case_uid = inv.PUBLIC_HEALTH_CASE_UID
				 INNER JOIN
				 NBS_SRTE.DBO.CONDITION_CODE
				 ON CONDITION_CODE.CONDITION_CD = inv.CD
				 INNER JOIN
				  dbo.nrt_page_case_answer nrt_page
			 	 ON nrt_page.act_uid = inv.public_health_case_uid
			WHERE nrt_page.act_uid = @phc_id
				AND (isNumeric(numeric_inv.ANSWER_TXT) != 1) AND 
				  numeric_inv.ANSWER_TXT IS NOT NULL AND 
				 CONDITION_CODE.INVESTIGATION_FORM_CD = nrt_page.INVESTIGATION_FORM_CD);
		
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );
		COMMIT TRANSACTION;
	
		BEGIN TRANSACTION;
	
		DECLARE @numeric_output_table_name varchar(500) = ''
		SET @Proc_Step_no = 50;
		SET @numeric_output_table_name = '##NUMERIC_DATA_PIVOT_INV_CAT_'+@category+'_'+CAST(@Batch_id as varchar(50));	
	
		SET @Proc_Step_Name = ' Generating FINAL TABLE FOR NUmeric '+@numeric_output_table_name;
		
		EXEC ('IF OBJECT_ID(''tempdb..'+@numeric_output_table_name+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@numeric_output_table_name+';
		END;')
		
		
		SET @columns = N'';
		SELECT @columns+=N', p.' + QUOTENAME(LTRIM(RTRIM([RDB_COLUMN_NM])))
		FROM
		(
			SELECT [RDB_COLUMN_NM]
			FROM #NUMERIC_DATA_TRANS1_INV_CAT AS p
			GROUP BY [RDB_COLUMN_NM]
		) AS x;
	
		SET @sql = N'
		SELECT [PAGE_CASE_UID] as PAGE_CASE_UID_NUMERIC, ' + STUFF(@columns, 1, 2, '') + ' into '+@numeric_output_table_name+' FROM (
		SELECT [PAGE_CASE_UID], [answer_txt] , [RDB_COLUMN_NM] 
		 FROM #NUMERIC_DATA_TRANS1_INV_CAT
		  WHERE (isNumeric(ANSWER_TXT) = 1) AND  ANSWER_TXT IS NOT NULL 
			group by [PAGE_CASE_UID], [answer_txt] , [RDB_COLUMN_NM] 
		) AS j PIVOT (max(answer_txt) FOR [RDB_COLUMN_NM] in 
	   (' + STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '') + ')) AS p;';
		
	  	if @debug = 'true'
	  		PRINT @sql;
	  	
		EXEC sp_executesql @sql;
		
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );			
	
		--- If the #text_data_inv table does not have any records create the table with default column 	
		EXEC ('IF OBJECT_ID(''tempdb..'+@numeric_output_table_name+''', ''U'') IS NULL
		BEGIN
			CREATE TABLE '+@numeric_output_table_name+'
			( 
				[PAGE_CASE_UID_numeric] [bigint] NULL,
			)
			
		END;') 

		if @debug = 'true'
	  		EXEC ('select * from '+@numeric_output_table_name)			
		
	
		COMMIT TRANSACTION;
		

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 53;
		SET @Proc_Step_Name = ' Generating STAGING_KEY_INV_CAT'; 
		--create table STAGING_KEY AS 
		IF OBJECT_ID('#STAGING_KEY_INV_CAT', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #STAGING_KEY_INV_CAT;
		END;

		SELECT ACT_UID AS PAGE_CASE_UID, NBS_CASE_ANSWER_UID, nrt_page.LAST_CHG_TIME
		INTO #STAGING_KEY_INV_CAT
		FROM dbo.nrt_page_case_answer AS nrt_page WITH(NOLOCK) --6
		WHERE 
		nrt_page.act_uid=@phc_id 
		AND ANSWER_GROUP_SEQ_NBR IS NULL 
		AND nrt_page.RDB_TABLE_NM = @rdb_table_name AND 
			  QUESTION_GROUP_SEQ_NBR IS NULL
		GROUP BY ACT_UID, NBS_CASE_ANSWER_UID, nrt_page.LAST_CHG_TIME;
	
		IF OBJECT_ID('#STAGING_KEY_INV_CAT_FINAL', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #STAGING_KEY_INV_CAT_FINAL;
		END;

		SELECT *
		INTO #STAGING_KEY_INV_CAT_FINAL
		FROM
		(
			SELECT *, ROW_NUMBER() OVER(PARTITION BY [page_case_uid]
			ORDER BY [page_case_uid], NBS_CASE_ANSWER_UID) AS rowid
			FROM #STAGING_KEY_INV_CAT
		) AS Der
		WHERE rowid = 1;
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );
		
	
		COMMIT TRANSACTION;
	
		if @debug = 'true'
		 	select * from #STAGING_KEY_INV_CAT_FINAL;
			EXEC ('select * from '+@numeric_output_table_name);
			EXEC ('select * from '+@date_output_table_name);
			EXEC ('select * from '+@coded_output_table_name);
			EXEC ('select * from '+@text_output_table_name);
		

		
		BEGIN TRANSACTION;
		SET @Proc_Step_no = 54;
		SET @Proc_Step_Name = ' Creating Table S_'+@category; 
    
		
		declare @final_table_name varchar(250);
		declare @drop_sql nvarchar(1000);
		declare @final_insert nvarchar(2500);
		declare @drop_columns nvarchar(2000);
	
		set @final_table_name = 'dbo.S_'+@category		
		
		set @drop_sql = '		
			IF OBJECT_ID('''+@final_table_name+''', ''U'') IS NOT NULL
			BEGIN
				DROP TABLE '+@final_table_name+';
			END;'

		if @debug = 'true'
		 	print @drop_sql
		 	
		exec sp_executesql @drop_sql
	
		
		set @final_insert = 
			'SELECT sk.*, ndo.*, ddo.*, cdo.*, tdo.*
			 INTO '+@final_table_name+'
			 FROM #STAGING_KEY_INV_CAT_FINAL AS sk 
				 LEFT OUTER JOIN (select * from '+@numeric_output_table_name+' where PAGE_CASE_UID_numeric > 0)  AS ndo
				 ON ndo.PAGE_CASE_UID_NUMERIC = sk.PAGE_CASE_UID 
				 LEFT OUTER JOIN '+@date_output_table_name+' AS ddo
				 ON ddo.PAGE_CASE_UID_date = sk.PAGE_CASE_UID 
				 LEFT OUTER JOIN '+@coded_output_table_name+' AS cdo
				 ON cdo.PAGE_CASE_UID_coded = sk.PAGE_CASE_UID 
				 LEFT OUTER JOIN '+@text_output_table_name+' AS tdo
				 ON tdo.PAGE_CASE_UID_text = sk.PAGE_CASE_UID; '	
				 
	
		if @debug = 'true'
			print @final_insert
			
		 exec sp_executesql @final_insert
		 
		
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );


		COMMIT TRANSACTION;
		
		if @debug = 'true'
		 	EXEC ('select * from '+@final_table_name)	
			
		
		set @drop_columns = 'ALTER TABLE '+@final_table_name+' DROP COLUMN rowid,PAGE_CASE_UID_numeric,PAGE_CASE_UID_date,PAGE_CASE_UID_coded,PAGE_CASE_UID_text '
	
		if @debug = 'true'
		 	print @drop_columns
		
		exec sp_executesql @drop_columns


		if @debug = 'false'
		 EXEC (' drop table '+@numeric_output_table_name+';
				 drop table '+@date_output_table_name+';
				 drop table '+@text_output_table_name+';
				 drop table '+@coded_output_table_name+';  
               ') 	
		
		

		BEGIN TRANSACTION;
		SET @Proc_Step_no = 999;
		SET @Proc_Step_Name = 'SP_COMPLETE';
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'S_'+@category, 'COMPLETE', @Proc_Step_no, @Proc_Step_name, @RowCount_no );

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
		VALUES( @Batch_id, @category, @final_table_name, 'ERROR', @Proc_Step_no, 'ERROR - ' + @Proc_Step_name, 'Step -' + CAST(@Proc_Step_no AS varchar(3)) + ' -' + CAST(@ErrorMessage AS varchar(500)), 0 );
		RETURN -1;
	END CATCH;

END;
