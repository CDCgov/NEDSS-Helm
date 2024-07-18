CREATE OR ALTER PROCEDURE dbo.sp_l_pagebuilder_postprocessing
	@Batch_id bigint, 
	@phc_id bigint,
	@rdb_TABLE_NAME varchar(250),
	@category varchar(250),
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
		VALUES( @Batch_id, @category, 'L_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, 0 );


		COMMIT TRANSACTION;

		BEGIN TRANSACTION;

		SET @Proc_Step_no = 2;
		SET @Proc_Step_Name = 'CREATE TABLE #LOOKUP_TABLE1_'+@category; 
		
		DECLARE @exec_sql nvarchar(2000);
		DECLARE @S_CAT_TABLE_NAME varchar(100) = '';
		DECLARE @L_CAT_TABLE_NAME varchar(100) = '';
		DECLARE @PHC_UID_TABLE_NAME varchar(100) = '';
		DECLARE @LOOKUP_TABLE1_CAT_TABLE_NAME varchar(100) = '';
		
		SET @S_CAT_TABLE_NAME = 'S_'+@category;				
		SET @L_CAT_TABLE_NAME = 'L_'+@category;
		SET @LOOKUP_TABLE1_CAT_TABLE_NAME = '##LOOKUP_TABLE1_'+@category+'_'+CAST(@Batch_id as varchar(50));	
		--SET @PHC_UID_TABLE_NAME = '#PHC_UIDS_'+@category+'_'+CAST(@Batch_id as varchar(50));	

		--CREATE TABLE LOOKUP_TABLE1_INV_{Category} AS
		--*** Keys for New Page case where no Staging Category enteries
	
		EXEC ('IF OBJECT_ID(''tempdb..'+@LOOKUP_TABLE1_CAT_TABLE_NAME+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@LOOKUP_TABLE1_CAT_TABLE_NAME+';
		END;')
		

		CREATE TABLE #PHC_UIDS (page_case_uid BIGINT)	
		
		INSERT INTO #PHC_UIDS
			SELECT inv.public_health_case_uid page_case_uid 
			FROM dbo.nrt_investigation inv
		WHERE inv.public_health_case_uid = @phc_id

		
		SET @exec_sql ='IF OBJECT_ID(''dbo.'+@S_CAT_TABLE_NAME+''', ''U'') IS NULL
		BEGIN
			CREATE TABLE '+QUOTENAME(@S_CAT_TABLE_NAME) +' ( [PAGE_CASE_UID] [numeric](20, 0) NULL
			)ON [PRIMARY];

			CREATE INDEX '+@S_CAT_TABLE_NAME+' 
				ON [dbo].'+@S_CAT_TABLE_NAME+' 
							( PAGE_CASE_UID
							);
		END;'
				
		EXEC sp_executesql @exec_sql;
		if @debug = 'true' SELECT @exec_sql;
	
	
		SET @exec_sql = 'IF OBJECT_ID(''dbo.L_'+@category+''', ''U'') IS NULL
							BEGIN
								CREATE TABLE '+QUOTENAME(@L_CAT_TABLE_NAME)+'
									( 
												 [D_'+@category+'_KEY] [float] NULL, [PAGE_CASE_UID] [float] NULL
									)
									ON [PRIMARY];
								
								CREATE INDEX L_'+@category+'
								ON dbo.'+QUOTENAME(@L_CAT_TABLE_NAME)+'
								( PAGE_CASE_UID
								);
								CREATE NONCLUSTERED INDEX [L_RDB_PERF_04082021_01]
								ON dbo.'+QUOTENAME(@L_CAT_TABLE_NAME)+'
								( [D_'+@category+'_KEY]
								
								) 
								INCLUDE( [PAGE_CASE_UID] );
		
							END;'	
	
		EXEC sp_executesql @exec_sql;
		if @debug = 'true' SELECT @exec_sql;
	


		SET @exec_sql = 'WITH lst
						 AS (SELECT PAGE_CASE_UID
							 FROM #PHC_UIDS
							 EXCEPT
							 (
								 SELECT PAGE_CASE_UID
								 FROM '+QUOTENAME(@S_CAT_TABLE_NAME)+' 
								 UNION
								 SELECT PAGE_CASE_UID
								 FROM '+QUOTENAME(@L_CAT_TABLE_NAME)+'
								
							 ))
						 SELECT *, 1 AS D_NE_KEY
						 INTO '+QUOTENAME(@LOOKUP_TABLE1_CAT_TABLE_NAME)+'
						 FROM lst;'	
	
		EXEC sp_executesql @exec_sql;
		if @debug = 'true' SELECT @exec_sql;
	
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'L_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;
	
		BEGIN TRANSACTION;

		SET @Proc_Step_no = 3;
		SET @Proc_Step_Name = 'ADD TO TABLE '+@LOOKUP_TABLE1_CAT_TABLE_NAME;

		-- Insert into LOOKUP_TABLE1_INV_MOTHER where D_INV Key is not equal to 1 for the given PHC uids
	
		/*
		INSERT INTO #LOOKUP_TABLE1_INV_CAT
	    SELECT pcuid.PAGE_CASE_UID, ladmin.D_INV_CAT_KEY
	    FROM   #PHC_UIDS AS pcuid, ##L_INV_PHC_IDS AS ladmin
	    WHERE  pcuid.PAGE_CASE_UID = ladmin.PAGE_CASE_UID AND 
			   ladmin.D_INV_CAT_KEY != 1;
		*/	  
		
		SET @exec_sql = 'INSERT INTO '+QUOTENAME(@LOOKUP_TABLE1_CAT_TABLE_NAME)+'
	    SELECT pcuid.PAGE_CASE_UID, ladmin.D_'+@category+'_KEY
	    FROM   #PHC_UIDS AS pcuid, '+QUOTENAME(@L_CAT_TABLE_NAME)+' AS ladmin
	    WHERE  pcuid.PAGE_CASE_UID = ladmin.PAGE_CASE_UID AND 
			   ladmin.D_'+@category+'_KEY != 1;'
			 	
		EXEC sp_executesql @exec_sql;
					
					
		SELECT @RowCount_no = @@ROWCOUNT;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, 'INV_'+@category, 'L_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		if @debug = 'true'
			select * from #LOOKUP_TABLE1_INV_CAT
			
		COMMIT TRANSACTION;


		BEGIN TRANSACTION;

		SET @Proc_Step_no = 4;
		DECLARE @LOOKUP_TABLE_D_REMOVE_TABLE_NAME varchar(100) = '';
		SET @LOOKUP_TABLE_D_REMOVE_TABLE_NAME = '##LOOKUP_TABLE_D_REMOVE_'+@category+'_'+CAST(@Batch_id as varchar(50));	
		SET @Proc_Step_Name = 'CREATE TABLE '+@LOOKUP_TABLE_D_REMOVE_TABLE_NAME; 

		--CREATE TABLE LOOKUP_TABLE1_INV_MOTHER AS
		--*** Keys for New Page case where no Stgaing MOTHER enteries
		EXEC ('IF OBJECT_ID(''tempdb.'+@LOOKUP_TABLE_D_REMOVE_TABLE_NAME+''', ''U'') IS NOT NULL
		BEGIN
			DROP TABLE '+@LOOKUP_TABLE_D_REMOVE_TABLE_NAME+';
		END;')


		-- Insert into LOOKUP_TABLE_D_REMOVE_INV_MOTHER where D_INV Key is not equal to 1 for the given PHC uids

		/*
		SELECT pcuid.PAGE_CASE_UID, ladmin.D_INV_CAT_KEY
		INTO #LOOKUP_TABLE_D_REMOVE_INV_CAT
		FROM #PHC_UIDS AS pcuid, ##L_INV_PHC_IDS AS ladmin
		WHERE pcuid.PAGE_CASE_UID = ladmin.PAGE_CASE_UID AND 
			  ladmin.D_INV_CAT_KEY != 1;
		*/
		
		SET @exec_sql = 'SELECT pcuid.PAGE_CASE_UID, ladmin.D_'+@category+'_KEY
		INTO '+@LOOKUP_TABLE_D_REMOVE_TABLE_NAME+'
		FROM #PHC_UIDS AS pcuid, '+QUOTENAME(@L_CAT_TABLE_NAME)+' AS ladmin
		WHERE pcuid.PAGE_CASE_UID = ladmin.PAGE_CASE_UID AND 
			  ladmin.D_'+@category+'_KEY != 1;'
			 	
		EXEC sp_executesql @exec_sql;


		SELECT @RowCount_no = @@ROWCOUNT;
		/*
		CREATE NONCLUSTERED INDEX [L_RDB_PREF_INTERNAL_03]
		ON [dbo].[LOOKUP_TABLE_D_REMOVE_INV_MOTHER]
		( [D_INV_MOTHER_KEY]
		);
		*/

		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'L_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );


		COMMIT TRANSACTION;



		BEGIN TRANSACTION;

		SET @Proc_Step_no = 5;
		SET @Proc_Step_Name = ' INSERT INTO LOOKUP_TABLE_N_'+@CATEGORY; 
		DECLARE @LOOKUP_N_CAT_TABLE_NAME varchar(100) = '';
		SET @LOOKUP_N_CAT_TABLE_NAME = 'LOOKUP_TABLE_N_'+@category;
		 
		EXEC ('DELETE FROM dbo.'+@LOOKUP_N_CAT_TABLE_NAME);

		SET @exec_sql = 'INSERT INTO dbo.'+QUOTENAME(@LOOKUP_N_CAT_TABLE_NAME)+'
			   SELECT PAGE_CASE_UID
			   FROM #PHC_UIDS
			   EXCEPT
			   SELECT PAGE_CASE_UID
			   FROM '+@LOOKUP_TABLE1_CAT_TABLE_NAME+';'
	
		EXEC sp_executesql @exec_sql;
			   

		SELECT @RowCount_no = @@ROWCOUNT;

		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'L_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		if @debug ='true'
			exec ('select * from '+@LOOKUP_N_CAT_TABLE_NAME+';')
			

		COMMIT TRANSACTION;


		BEGIN TRANSACTION;

		SET @Proc_Step_no = 6;
		DECLARE @LOOKUP_TABLE_INC_TABLE_NAME varchar(100) = '';
		SET @LOOKUP_TABLE_INC_TABLE_NAME = 'L_'+@category+'_INC';	
		SET @Proc_Step_Name = 'CREATE TABLE '+@LOOKUP_TABLE_INC_TABLE_NAME; 

		--CREATE TABLE L_INV_MOTHER_INC AS 
	
		EXEC ('IF OBJECT_ID(''dbo.'+@LOOKUP_TABLE_INC_TABLE_NAME+''', ''U'') IS NOT NULL
		BEGIN
		 DROP TABLE dbo.'+@LOOKUP_TABLE_INC_TABLE_NAME+';
		END;')


			
		--Fix: Persist _INC table, full join persisted LOOKUP_TABLE_N_INV_UNDER_CONDITION
		SET @exec_sql = 'SELECT ltn.PAGE_CASE_UID AS PAGE_CASE_UID_N, lt1.PAGE_CASE_UID AS PAGE_CASE_UID_NE, ltn.D_'+@category+'_KEY  AS D_'+@category+'_KEY_N, 
		lt1.D_NE_KEY, CAST(NULL AS bigint) AS PAGE_CASE_UID, CAST(NULL AS bigint) AS D_'+@category+'_KEY 
		INTO '+QUOTENAME(@LOOKUP_TABLE_INC_TABLE_NAME)+'
		FROM '+QUOTENAME(@LOOKUP_TABLE1_CAT_TABLE_NAME)+' AS lt1
			 FULL JOIN
			 '+QUOTENAME(@LOOKUP_N_CAT_TABLE_NAME)+' AS ltn
			 ON lt1.PAGE_CASE_UID = ltn.PAGE_CASE_UID;' 
		EXEC sp_executesql @exec_sql


		SELECT @RowCount_no = @@ROWCOUNT;


		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'L_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;


		BEGIN TRANSACTION;

		SET @Proc_Step_no = 7;
		SET @Proc_Step_Name = 'UPDATE TABLE '+@LOOKUP_TABLE_INC_TABLE_NAME; 
	
		EXEC ('UPDATE '+@LOOKUP_TABLE_INC_TABLE_NAME+'
		  SET PAGE_CASE_UID = COALESCE(PAGE_CASE_UID_N, PAGE_CASE_UID_NE);')

		SET @exec_sql = 'UPDATE '+QUOTENAME(@LOOKUP_TABLE_INC_TABLE_NAME)+'
		  SET D_'+@category+'_KEY = COALESCE(D_'+@category+'_KEY_N, D_NE_KEY);'

		EXEC sp_executesql @exec_sql;

		if @debug ='true'
			PRINT @LOOKUP_TABLE_INC_TABLE_NAME;

		SELECT @RowCount_no = -1;
		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'L_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;

	
		BEGIN TRANSACTION;

		SET @Proc_Step_no = 8;
		SET @Proc_Step_Name = 'Delete from L_'+@category+' where existing default entry';
		
		SET @exec_sql = 'DELETE ladmin FROM '+QUOTENAME(@L_CAT_TABLE_NAME)+' ladmin
			 		JOIN '+QUOTENAME(@LOOKUP_TABLE_INC_TABLE_NAME)+' ladminI
			 	ON ladmin.PAGE_CASE_UID = ladminI.PAGE_CASE_UID
				WHERE ladmin.D_'+@category+'_KEY = 1;'
	
		EXEC sp_executesql @exec_sql;

		SELECT @RowCount_no = @@ROWCOUNT;

		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'L_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );

		COMMIT TRANSACTION;
   

		BEGIN TRANSACTION;

		SET @Proc_Step_no = 9;
		SET @Proc_Step_Name = 'Insert into L_'+@category+' new default key entry';

		SET @exec_sql = 'INSERT INTO '+QUOTENAME(@L_CAT_TABLE_NAME)+'( [PAGE_CASE_UID], [D_'+@category+'_KEY] )
			   		SELECT PAGE_CASE_UID, D_'+@category+'_KEY 
			   		FROM '+QUOTENAME(@LOOKUP_TABLE_INC_TABLE_NAME)+'
			   		WHERE D_'+@category+'_KEY = 1;'
		
		EXEC sp_executesql @exec_sql

		SELECT @RowCount_no = @@ROWCOUNT;

		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'L_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );


		COMMIT TRANSACTION;
   
		BEGIN TRANSACTION;

		SET @Proc_Step_no = 10;
		SET @Proc_Step_Name = 'Insert into L_'+@category+' new key entry';
		
		SET @exec_sql = 'INSERT INTO [dbo].'+QUOTENAME(@L_CAT_TABLE_NAME)+'( [PAGE_CASE_UID], [D_'+@category+'_KEY] )
			   SELECT PAGE_CASE_UID,D_'+@category+'_KEY 
			   FROM '+QUOTENAME(@LOOKUP_N_CAT_TABLE_NAME)+';'
		
		EXEC sp_executesql @exec_sql

		SELECT @RowCount_no = @@ROWCOUNT;

		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'L_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );


		COMMIT TRANSACTION;

	
		BEGIN TRANSACTION;
		SET @Proc_Step_no = 11;
		SET @Proc_Step_Name = 'Delete from D_' + +@category +' where existing default entry';

		DECLARE @D_TABLE_NAME varchar(200);
		DECLARE @D_key_column_name varchar(200);
	
		SET @D_TABLE_NAME = 'D_'+@category;
		SET @D_key_column_name = 'D_'+@category+'_KEY';
		
		SET @exec_sql = 'IF OBJECT_ID(''dbo.'+QUOTENAME(@D_TABLE_NAME)+''', ''U'') IS NULL
			BEGIN
				CREATE TABLE dbo.'+QUOTENAME(@D_TABLE_NAME)+'
				( 
					'+@D_key_column_name+' FLOAT NULL
				)
				ON [PRIMARY];
			END;'
		
		
		EXEC sp_executesql @exec_sql;
		

		SET @exec_sql = ' DELETE dadmin FROM '+ QUOTENAME(@D_TABLE_NAME) +' dadmin '+
			 ' JOIN '+QUOTENAME(@LOOKUP_TABLE_D_REMOVE_TABLE_NAME)+' ladminI
			 	ON dadmin.d_'+@category+'_key = ladminI.D_'+@category+'_KEY; '
			 	
		EXEC sp_executesql @exec_sql;
		
		
		if @debug = 'false'
		 EXEC (' drop table '+@LOOKUP_TABLE_D_REMOVE_TABLE_NAME+';
				 drop table '+@LOOKUP_TABLE1_CAT_TABLE_NAME+';
               ') 	

		SELECT @RowCount_no = @@ROWCOUNT;

		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'L_'+@category, 'START', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );


		COMMIT TRANSACTION;


		BEGIN TRANSACTION;

		SET @Proc_Step_no = 999;
		SET @Proc_Step_Name = 'SP_COMPLETE';


		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'L_'+@category, 'COMPLETE', @Proc_Step_no, @Proc_Step_Name, @RowCount_no );


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


		INSERT INTO [dbo].[job_flow_log]( batch_id, [Dataflow_Name], [package_Name], [Status_Type], [step_number], [step_name], [row_count] )
		VALUES( @Batch_id, @category, 'L_'+@category, 'ERROR', @Proc_Step_no, 'Step -' + CAST(@Proc_Step_no AS varchar(3)) + ' -' + CAST(@ErrorMessage AS varchar(500)), 0 );


		RETURN -1;
	END CATCH;

END;