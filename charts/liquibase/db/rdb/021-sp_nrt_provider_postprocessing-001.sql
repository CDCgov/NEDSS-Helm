CREATE OR ALTER PROCEDURE dbo.sp_nrt_provider_postprocessing @id_list nvarchar(max)
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
		('sp_nrt_provider_postprocessing',
		@id_list,
		'START'
		);
	set @log_id = @@IDENTITY;

	/* Temp Provider Table*/
	select 
		PROVIDER_KEY,
		nrt.provider_uid as PROVIDER_UID,
		local_id as PROVIDER_LOCAL_ID,
		record_status as PROVIDER_RECORD_STATUS,
		name_prefix as PROVIDER_NAME_PREFIX,
		first_name as PROVIDER_FIRST_NAME,
		middle_name as PROVIDER_MIDDLE_NAME,
		last_name as PROVIDER_LAST_NAME,
		name_suffix as PROVIDER_NAME_SUFFIX,
		name_degree as PROVIDER_NAME_DEGREE,
		general_comments as PROVIDER_GENERAL_COMMENTS,
		quick_code as PROVIDER_QUICK_CODE,
		nrt.provider_registration_num as PROVIDER_REGISTRATION_NUM,
		provider_registration_num_auth as PROVIDER_REGISRATION_NUM_AUTH,
		street_address_1 as PROVIDER_STREET_ADDRESS_1,
		street_address_2 as PROVIDER_STREET_ADDRESS_2,
		city as PROVIDER_CITY,
		state as PROVIDER_STATE,
		state_code as PROVIDER_STATE_CODE,
		zip as PROVIDER_ZIP,
		county as PROVIDER_COUNTY,
		county_code as PROVIDER_COUNTY_CODE,
		country as PROVIDER_COUNTRY,
		address_comments as PROVIDER_ADDRESS_COMMENTS,
		phone_work as PROVIDER_PHONE_WORK,
		phone_ext_work as PROVIDER_PHONE_EXT_WORK,
		email_work as PROVIDER_EMAIL_WORK,
		phone_comments as PROVIDER_PHONE_COMMENTS,
		phone_cell as PROVIDER_PHONE_CELL,
		entry_method as PROVIDER_ENTRY_METHOD,
		add_user_name as PROVIDER_ADDED_BY,
		add_time as PROVIDER_ADD_TIME,
		last_chg_user_name as PROVIDER_LAST_UPDATED_BY,
		last_chg_time as PROVIDER_LAST_CHANGE_TIME
	into #temp_prv_table
	from dbo.nrt_provider nrt
	left join dbo.d_provider p on p.provider_uid = nrt.provider_uid
	where nrt.provider_uid in (SELECT value FROM STRING_SPLIT(@id_list, ','))
	

	/* D_Provider Update Operation */
	BEGIN TRANSACTION;
	update dbo.d_provider
		set [PROVIDER_UID]	=	 prv.[PROVIDER_UID]	,
		 [PROVIDER_KEY]	=	prv.[PROVIDER_KEY]	,
		 [PROVIDER_LOCAL_ID]	=	prv.[PROVIDER_LOCAL_ID]	,
		 [PROVIDER_RECORD_STATUS]	=	prv.[PROVIDER_RECORD_STATUS]	,
		 [PROVIDER_NAME_PREFIX]	=	prv.[PROVIDER_NAME_PREFIX]	,
		 [PROVIDER_FIRST_NAME]	=	prv.[PROVIDER_FIRST_NAME]	,
		 [PROVIDER_MIDDLE_NAME]	=	prv.[PROVIDER_MIDDLE_NAME]	,
		 [PROVIDER_LAST_NAME]	=	prv.[PROVIDER_LAST_NAME]	,
		 [PROVIDER_NAME_SUFFIX]	=	prv.[PROVIDER_NAME_SUFFIX]	,
		 [PROVIDER_NAME_DEGREE]	=	prv.[PROVIDER_NAME_DEGREE]	,
		 [PROVIDER_GENERAL_COMMENTS]	=	prv.[PROVIDER_GENERAL_COMMENTS]	,
		 [PROVIDER_QUICK_CODE]	=	substring(prv.[PROVIDER_QUICK_CODE] ,1,50)	,
		 [PROVIDER_REGISTRATION_NUM]	=	substring(prv.[PROVIDER_REGISTRATION_NUM] ,1,50)	,
		 [PROVIDER_REGISRATION_NUM_AUTH]	=	substring(prv.[PROVIDER_REGISRATION_NUM_AUTH] ,1,50)	,
		 [PROVIDER_STREET_ADDRESS_1]	=	substring(prv.[PROVIDER_STREET_ADDRESS_1],1,50),
		 [PROVIDER_STREET_ADDRESS_2]	=	substring(prv.[PROVIDER_STREET_ADDRESS_2],1,50),
		 [PROVIDER_CITY]	=	substring(prv.[PROVIDER_CITY] ,1,50)	,
		 [PROVIDER_STATE]	=	prv.[PROVIDER_STATE]	,
		 [PROVIDER_STATE_CODE]	=	prv.[PROVIDER_STATE_CODE]	,
		 [PROVIDER_ZIP]	=	prv.[PROVIDER_ZIP]	,
		 [PROVIDER_COUNTY]	=	prv.[PROVIDER_COUNTY]	,
		 [PROVIDER_COUNTY_CODE]	=	prv.[PROVIDER_COUNTY_CODE]	,
		 [PROVIDER_COUNTRY]	=	prv.[PROVIDER_COUNTRY]	,
		 [PROVIDER_ADDRESS_COMMENTS]	=	prv.[PROVIDER_ADDRESS_COMMENTS]	,
		 [PROVIDER_PHONE_WORK]	=	prv.[PROVIDER_PHONE_WORK]	,
		 [PROVIDER_PHONE_EXT_WORK]	=	 prv.[PROVIDER_PHONE_EXT_WORK]	,
		 [PROVIDER_EMAIL_WORK]	=	substring(prv.[PROVIDER_EMAIL_WORK] ,1,50)	,
		 [PROVIDER_PHONE_COMMENTS]	=	prv.[PROVIDER_PHONE_COMMENTS]	,
		 [PROVIDER_PHONE_CELL]	=	prv.[PROVIDER_PHONE_CELL]	,
		 [PROVIDER_ENTRY_METHOD]	=	prv.[PROVIDER_ENTRY_METHOD]	,
		 [PROVIDER_LAST_CHANGE_TIME]	=	prv.[PROVIDER_LAST_CHANGE_TIME]	,
		 [PROVIDER_ADD_TIME]	=	prv.[PROVIDER_ADD_TIME]	,
		 [PROVIDER_ADDED_BY]	=	prv.[PROVIDER_ADDED_BY]	,
		 [PROVIDER_LAST_UPDATED_BY]	=	prv.[PROVIDER_LAST_UPDATED_BY]	
	from #temp_prv_table prv
	inner join dbo.d_provider p on prv.provider_uid = p.provider_uid
	    and prv.provider_key = p.provider_key
	    and p.provider_key is not null;

	/* Logging */
	set @rowcount=@@rowcount 
	if @rowcount > 0
		update dbo.nrt_batch_log
		set log_detail='Num of Provider keys updated: '+ cast(@rowcount as nvarchar(max))+ '.'
		where batch_id=@log_id; 
	else 
		update dbo.nrt_batch_log
		set log_detail='No Provider Updates.'
		where batch_id=@log_id; 
	
	/* D_Provider Insert Operation */
		
	-- delete from the key table to generate new keys for the resulting new data to be inserted
	delete from dbo.nrt_provider_key ;
	insert into dbo.nrt_provider_key(provider_uid) 
	select provider_uid from #temp_prv_table where provider_key is null order by provider_uid;

	insert into dbo.d_provider
			([PROVIDER_UID]
           ,[PROVIDER_KEY]
           ,[PROVIDER_LOCAL_ID]
           ,[PROVIDER_RECORD_STATUS]
           ,[PROVIDER_NAME_PREFIX]
           ,[PROVIDER_FIRST_NAME]
           ,[PROVIDER_MIDDLE_NAME]
           ,[PROVIDER_LAST_NAME]
           ,[PROVIDER_NAME_SUFFIX]
           ,[PROVIDER_NAME_DEGREE]
           ,[PROVIDER_GENERAL_COMMENTS]
           ,[PROVIDER_QUICK_CODE]
           ,[PROVIDER_REGISTRATION_NUM]
           ,[PROVIDER_REGISRATION_NUM_AUTH]
           ,[PROVIDER_STREET_ADDRESS_1]
           ,[PROVIDER_STREET_ADDRESS_2]
           ,[PROVIDER_CITY]
           ,[PROVIDER_STATE]
           ,[PROVIDER_ZIP]
           ,[PROVIDER_COUNTY]
           ,[PROVIDER_COUNTRY]
           ,[PROVIDER_ADDRESS_COMMENTS]
           ,[PROVIDER_PHONE_WORK]
           ,[PROVIDER_PHONE_EXT_WORK]
           ,[PROVIDER_EMAIL_WORK]
           ,[PROVIDER_PHONE_COMMENTS]
           ,[PROVIDER_PHONE_CELL]
           ,[PROVIDER_ENTRY_METHOD]
           ,[PROVIDER_LAST_CHANGE_TIME]
           ,[PROVIDER_ADD_TIME]
           ,[PROVIDER_ADDED_BY]
           ,[PROVIDER_LAST_UPDATED_BY]
           ,[PROVIDER_STATE_CODE]
           ,[PROVIDER_COUNTY_CODE])
			SELECT  prv.[PROVIDER_UID] 
			  ,k.[d_PROVIDER_KEY] as PROVIDER_KEY  
			  ,prv.[PROVIDER_LOCAL_ID]
			  ,prv.[PROVIDER_RECORD_STATUS]
			  ,prv.[PROVIDER_NAME_PREFIX]
			  ,prv.[PROVIDER_FIRST_NAME]
			  ,prv.[PROVIDER_MIDDLE_NAME]
			  ,prv.[PROVIDER_LAST_NAME]
			  ,prv.[PROVIDER_NAME_SUFFIX]
			  ,prv.[PROVIDER_NAME_DEGREE]
			  ,prv.[PROVIDER_GENERAL_COMMENTS]
			  ,case when cast ( prv.PROVIDER_QUICK_CODE as varchar(50))= '' then null else cast ( prv.PROVIDER_QUICK_CODE as varchar(50)) end
			  ,case when cast ( prv.[PROVIDER_REGISTRATION_NUM] as varchar(50))= '' then null else cast ( prv.[PROVIDER_REGISTRATION_NUM] as varchar(50)) end
			  ,case when cast ( prv.[PROVIDER_REGISRATION_NUM_AUTH] as varchar(50))= '' then null else cast ( prv.[PROVIDER_REGISRATION_NUM_AUTH] as varchar(50)) end
			  ,case when cast ( prv.[PROVIDER_STREET_ADDRESS_1] as varchar(50))= '' then null else cast ( prv.[PROVIDER_STREET_ADDRESS_1] as varchar(50)) end
			  ,case when cast ( prv.[PROVIDER_STREET_ADDRESS_2] as varchar(50))= '' then null else cast ( prv.[PROVIDER_STREET_ADDRESS_2] as varchar(50)) end
			  ,case when cast ( prv.[PROVIDER_CITY] as varchar(50))= '' then null else cast ( prv.[PROVIDER_CITY] as varchar(50)) end
			  ,prv.[PROVIDER_STATE]
			  ,prv.[PROVIDER_ZIP]
			  ,prv.[PROVIDER_COUNTY]
			  ,prv.[PROVIDER_COUNTRY]
			  ,case when prv.[PROVIDER_ADDRESS_COMMENTS]= '' then null else prv.[PROVIDER_ADDRESS_COMMENTS] end
			  ,case when prv.[PROVIDER_PHONE_WORK]= '' then null else prv.[PROVIDER_PHONE_WORK] end
			  ,case when prv.[PROVIDER_PHONE_EXT_WORK] = '' then null else prv.[PROVIDER_PHONE_EXT_WORK] end
			  ,case when cast ( prv.[PROVIDER_EMAIL_WORK] as varchar(50))= '' then null else cast ( prv.[PROVIDER_EMAIL_WORK] as varchar(50)) end
			  ,case when prv.[PROVIDER_PHONE_COMMENTS]= '' then null else prv.[PROVIDER_PHONE_COMMENTS] end
			  ,prv.[PROVIDER_PHONE_CELL]
			  ,prv.[PROVIDER_ENTRY_METHOD]
			  ,prv.[PROVIDER_LAST_CHANGE_TIME]
			  ,prv.[PROVIDER_ADD_TIME]
			  ,prv.[PROVIDER_ADDED_BY]
			  ,prv.[PROVIDER_LAST_UPDATED_BY]
			  ,prv.[PROVIDER_STATE_CODE]
			  ,case when prv.[PROVIDER_COUNTY_CODE]= '' then null else prv.[PROVIDER_COUNTY_CODE] end
			FROM #temp_prv_table prv
			join dbo.nrt_provider_key k on prv.provider_uid = k.provider_uid
			where prv.provider_key is null
			  
		/* Logging */
		set @rowcount=@@rowcount 	  
		if @rowcount > 0
			update dbo.nrt_batch_log
			set log_detail=log_detail+' Num of Provider keys inserted: ' + cast(@rowcount as nvarchar(max))+ '.'
		where batch_id=@log_id; 
		else 
			update dbo.nrt_batch_log
			set log_detail=log_detail+' No Provider Inserts.'
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
		set 
			batch_end_time=GETDATE(),
			status='ERROR',
				error_log=@ErrorMessage
			where batch_id = @log_id; 
  
    	/*
    	declare @errorstr varchar(max)
		set @errorstr = coalesce(@ErrorMessage+', ID List:' , @id_list) 
		return @errorstr;
		*/
      	return @ErrorMessage;

	END CATCH
	
END;