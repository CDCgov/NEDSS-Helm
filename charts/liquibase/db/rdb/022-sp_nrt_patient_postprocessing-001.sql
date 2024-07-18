CREATE OR ALTER PROCEDURE dbo.sp_nrt_patient_postprocessing @id_list nvarchar(max)
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
		('sp_nrt_patient_postprocessing',
		@id_list,
		'START'
		);
	set @log_id = @@IDENTITY;

	/* Temp patient table creation*/
	select 
		PATIENT_KEY,
		nrt.patient_uid AS PATIENT_UID,
		nrt.patient_mpr_uid AS PATIENT_MPR_UID,
		record_status AS PATIENT_RECORD_STATUS,
		local_id AS PATIENT_LOCAL_ID,
		case when rtrim(ltrim(general_comments)) = '' then null
		else general_comments end AS PATIENT_GENERAL_COMMENTS,
		first_name AS PATIENT_FIRST_NAME,
		case when rtrim(ltrim(middle_name)) = '' then null
		else middle_name end AS PATIENT_MIDDLE_NAME,
		last_name AS PATIENT_LAST_NAME,
		name_suffix AS PATIENT_NAME_SUFFIX,
		alias_nickname AS PATIENT_ALIAS_NICKNAME,
		case when rtrim(ltrim(street_address_1)) = '' then null
		else street_address_1 end AS PATIENT_STREET_ADDRESS_1,
		case when rtrim(ltrim(street_address_2)) = '' then null
		else street_address_2 end AS PATIENT_STREET_ADDRESS_2,
		case when rtrim(ltrim(city)) = '' then null
		else city end AS PATIENT_CITY,
		state AS PATIENT_STATE,
		case when rtrim(ltrim(state_code)) = '' then null
		else state_code end AS PATIENT_STATE_CODE,
		case when rtrim(ltrim(zip)) = '' then null
		else zip end AS PATIENT_ZIP,
		case when rtrim(ltrim(county_code)) = '' then null
		else county_code end AS PATIENT_COUNTY_CODE,
		county AS PATIENT_COUNTY,
		case when rtrim(ltrim(country)) = '' then null
		else country end AS PATIENT_COUNTRY,
		case when rtrim(ltrim(within_city_limits)) = '' then null
		else within_city_limits end AS PATIENT_WITHIN_CITY_LIMITS,
		case when rtrim(ltrim(phone_home)) = '' then null
		else phone_home end AS PATIENT_PHONE_HOME,
		case when rtrim(ltrim(phone_ext_home)) = '' then null
		else phone_ext_home end AS PATIENT_PHONE_EXT_HOME,
		case when rtrim(ltrim(phone_work)) = '' then null
		else phone_work end AS PATIENT_PHONE_WORK,
		case when rtrim(ltrim(phone_ext_work)) = '' then null
		else phone_ext_work end AS PATIENT_PHONE_EXT_WORK,
		phone_cell AS PATIENT_PHONE_CELL,
		email AS PATIENT_EMAIL,
		dob AS PATIENT_DOB,
		age_reported AS PATIENT_AGE_REPORTED,
		age_reported_unit AS PATIENT_AGE_REPORTED_UNIT,
		birth_sex AS PATIENT_BIRTH_SEX,
		current_sex AS PATIENT_CURRENT_SEX,
		deceased_indicator AS PATIENT_DECEASED_INDICATOR,
		deceased_date AS PATIENT_DECEASED_DATE,
		marital_status AS PATIENT_MARITAL_STATUS,
		case when rtrim(ltrim(ssn)) = '' then null
		else ssn end AS PATIENT_SSN,
		ethnicity AS PATIENT_ETHNICITY,
		race_calculated AS PATIENT_RACE_CALCULATED,
		race_calc_details AS PATIENT_RACE_CALC_DETAILS,
		race_amer_ind_1 AS PATIENT_RACE_AMER_IND_1,
		race_amer_ind_2 AS PATIENT_RACE_AMER_IND_2,
		race_amer_ind_3 AS PATIENT_RACE_AMER_IND_3,
		race_amer_ind_gt3_ind AS PATIENT_RACE_AMER_IND_GT3_IND,
		race_amer_ind_all AS PATIENT_RACE_AMER_IND_ALL,
		race_asian_1 AS PATIENT_RACE_ASIAN_1,
		race_asian_2 AS PATIENT_RACE_ASIAN_2,
		race_asian_3 AS PATIENT_RACE_ASIAN_3,
		race_asian_gt3_ind AS PATIENT_RACE_ASIAN_GT3_IND,
		race_asian_all AS PATIENT_RACE_ASIAN_ALL,
		race_black_1 AS PATIENT_RACE_BLACK_1,
		race_black_2 AS PATIENT_RACE_BLACK_2,
		race_black_3 AS PATIENT_RACE_BLACK_3,
		race_black_gt3_ind AS PATIENT_RACE_BLACK_GT3_IND,
		race_black_all AS PATIENT_RACE_BLACK_ALL,
		race_nat_hi_1 AS PATIENT_RACE_NAT_HI_1,
		race_nat_hi_2 AS PATIENT_RACE_NAT_HI_2,
		race_nat_hi_3 AS PATIENT_RACE_NAT_HI_3,
		race_nat_hi_gt3_ind AS PATIENT_RACE_NAT_HI_GT3_IND,
		race_nat_hi_all AS PATIENT_RACE_NAT_HI_ALL,
		race_white_1 AS PATIENT_RACE_WHITE_1,
		race_white_2 AS PATIENT_RACE_WHITE_2,
		race_white_3 AS PATIENT_RACE_WHITE_3,
		race_white_gt3_ind AS PATIENT_RACE_WHITE_GT3_IND,
		race_white_all AS PATIENT_RACE_WHITE_ALL,
		nrt.patient_number AS PATIENT_NUMBER,
		nrt.patient_number_auth AS PATIENT_NUMBER_AUTH,
		entry_method AS PATIENT_ENTRY_METHOD,
		speaks_english AS PATIENT_SPEAKS_ENGLISH,
		unk_ethnic_rsn AS PATIENT_UNK_ETHNIC_RSN,
		curr_sex_unk_rsn AS PATIENT_CURR_SEX_UNK_RSN,
		preferred_gender AS PATIENT_PREFERRED_GENDER,
		addl_gender_info AS PATIENT_ADDL_GENDER_INFO,
		census_tract AS PATIENT_CENSUS_TRACT,
		race_all AS PATIENT_RACE_ALL,
		birth_country AS PATIENT_BIRTH_COUNTRY,
		primary_occupation AS PATIENT_PRIMARY_OCCUPATION,
		primary_language AS PATIENT_PRIMARY_LANGUAGE,
		add_user_name AS PATIENT_ADDED_BY,
		add_time AS PATIENT_ADD_TIME,
		last_chg_user_name AS PATIENT_LAST_UPDATED_BY,
		last_chg_time AS PATIENT_LAST_CHANGE_TIME
	into #temp_patient_table
	from dbo.nrt_patient nrt
	left join dbo.d_patient p on p.patient_uid = nrt.patient_uid
	where    
	nrt.patient_uid in (SELECT value FROM STRING_SPLIT(@id_list, ','));

	/* D_Patient Update Operation */
	BEGIN TRANSACTION;
	update dbo.d_patient
		set	[PATIENT_KEY]	=	tpt.[PATIENT_KEY]	,
			[PATIENT_MPR_UID]	=	tpt.[PATIENT_MPR_UID]	,
			[PATIENT_RECORD_STATUS]	=	tpt.[PATIENT_RECORD_STATUS]	,
			[PATIENT_LOCAL_ID]	=	tpt.[PATIENT_LOCAL_ID]	,
			[PATIENT_GENERAL_COMMENTS]	=	 substring(tpt.[PATIENT_GENERAL_COMMENTS] ,1,2000)	,
			[PATIENT_FIRST_NAME]	=	tpt.[PATIENT_FIRST_NAME]	,
			[PATIENT_MIDDLE_NAME]	=	tpt.[PATIENT_MIDDLE_NAME]	,
			[PATIENT_LAST_NAME]	=	tpt.[PATIENT_LAST_NAME]	,
			[PATIENT_NAME_SUFFIX]	=	tpt.[PATIENT_NAME_SUFFIX]	,
			[PATIENT_ALIAS_NICKNAME]	=	tpt.[PATIENT_ALIAS_NICKNAME]	,
			[PATIENT_STREET_ADDRESS_1]	=	substring(tpt.[PATIENT_STREET_ADDRESS_1],1,50)	,
			[PATIENT_STREET_ADDRESS_2]	=	substring(tpt.[PATIENT_STREET_ADDRESS_2],1,50)	,
			[PATIENT_CITY]	=	 substring(tpt.[PATIENT_CITY] ,1,50)	,
			[PATIENT_STATE]	=	tpt.[PATIENT_STATE]	,
			[PATIENT_STATE_CODE]	=	tpt.[PATIENT_STATE_CODE]	,
			[PATIENT_ZIP]	=	tpt.[PATIENT_ZIP]	,
			[PATIENT_COUNTY]	=		substring(tpt.[PATIENT_COUNTY] ,1,50),
			[PATIENT_COUNTY_CODE]	=	tpt.[PATIENT_COUNTY_CODE]	,
			[PATIENT_COUNTRY]	=	tpt.[PATIENT_COUNTRY]	,
			[PATIENT_WITHIN_CITY_LIMITS]	=	tpt.[PATIENT_WITHIN_CITY_LIMITS]	,
			[PATIENT_PHONE_HOME]	=	tpt.[PATIENT_PHONE_HOME]	,
			[PATIENT_PHONE_EXT_HOME]	=	tpt.[PATIENT_PHONE_EXT_HOME]	,
			[PATIENT_PHONE_WORK]	=	tpt.[PATIENT_PHONE_WORK]	,
			[PATIENT_PHONE_EXT_WORK]	=	tpt.[PATIENT_PHONE_EXT_WORK]	,
			[PATIENT_PHONE_CELL]	=	tpt.[PATIENT_PHONE_CELL]	,
			[PATIENT_EMAIL]	=	tpt.[PATIENT_EMAIL]	,
			[PATIENT_DOB]	=	tpt.[PATIENT_DOB]	,
			[PATIENT_AGE_REPORTED]	=		tpt.[PATIENT_AGE_REPORTED],
			[PATIENT_AGE_REPORTED_UNIT]	=	 substring(tpt.[PATIENT_AGE_REPORTED_UNIT] ,1,20)	,
			[PATIENT_BIRTH_SEX]	=	 substring(tpt.[PATIENT_BIRTH_SEX] ,1,50)	,
			[PATIENT_CURRENT_SEX]	=		substring(tpt.[PATIENT_CURRENT_SEX] ,1,50),
			[PATIENT_DECEASED_INDICATOR]	=		substring(tpt.[PATIENT_DECEASED_INDICATOR] ,1,50),
			[PATIENT_DECEASED_DATE]	=	tpt.[PATIENT_DECEASED_DATE]	,
			[PATIENT_MARITAL_STATUS]	=		substring(tpt.[PATIENT_MARITAL_STATUS] ,1,50),
			[PATIENT_SSN]	=	substring(tpt.[PATIENT_SSN] ,1,50)	,
			[PATIENT_ETHNICITY]	=		substring(tpt.[PATIENT_ETHNICITY] ,1,50),
			[PATIENT_RACE_CALCULATED]	=		substring(tpt.[PATIENT_RACE_CALCULATED] ,1,50),
			[PATIENT_RACE_CALC_DETAILS]	=	tpt.[PATIENT_RACE_CALC_DETAILS]	,
			[PATIENT_RACE_AMER_IND_1]	=	tpt.[PATIENT_RACE_AMER_IND_1]	,
			[PATIENT_RACE_AMER_IND_2]	=	tpt.[PATIENT_RACE_AMER_IND_2]	,
			[PATIENT_RACE_AMER_IND_3]	=	tpt.[PATIENT_RACE_AMER_IND_3]	,
			[PATIENT_RACE_AMER_IND_GT3_IND]	=	tpt.[PATIENT_RACE_AMER_IND_GT3_IND]	,
			[PATIENT_RACE_AMER_IND_ALL]	=	tpt.[PATIENT_RACE_AMER_IND_ALL]	,
			[PATIENT_RACE_ASIAN_1]	=	tpt.[PATIENT_RACE_ASIAN_1]	,
			[PATIENT_RACE_ASIAN_2]	=	tpt.[PATIENT_RACE_ASIAN_2]	,
			[PATIENT_RACE_ASIAN_3]	=	tpt.[PATIENT_RACE_ASIAN_3]	,
			[PATIENT_RACE_ASIAN_GT3_IND]	=	tpt.[PATIENT_RACE_ASIAN_GT3_IND]	,
			[PATIENT_RACE_ASIAN_ALL]	=	tpt.[PATIENT_RACE_ASIAN_ALL]	,
			[PATIENT_RACE_BLACK_1]	=	tpt.[PATIENT_RACE_BLACK_1]	,
			[PATIENT_RACE_BLACK_2]	=	tpt.[PATIENT_RACE_BLACK_2]	,
			[PATIENT_RACE_BLACK_3]	=	tpt.[PATIENT_RACE_BLACK_3]	,
			[PATIENT_RACE_BLACK_GT3_IND]	=	tpt.[PATIENT_RACE_BLACK_GT3_IND]	,
			[PATIENT_RACE_BLACK_ALL]	=	tpt.[PATIENT_RACE_BLACK_ALL]	,
			[PATIENT_RACE_NAT_HI_1]	=	tpt.[PATIENT_RACE_NAT_HI_1]	,
			[PATIENT_RACE_NAT_HI_2]	=	tpt.[PATIENT_RACE_NAT_HI_2]	,
			[PATIENT_RACE_NAT_HI_3]	=	tpt.[PATIENT_RACE_NAT_HI_3]	,
			[PATIENT_RACE_NAT_HI_GT3_IND]	=	tpt.[PATIENT_RACE_NAT_HI_GT3_IND]	,
			[PATIENT_RACE_NAT_HI_ALL]	=	tpt.[PATIENT_RACE_NAT_HI_ALL]	,
			[PATIENT_RACE_WHITE_1]	=	tpt.[PATIENT_RACE_WHITE_1]	,
			[PATIENT_RACE_WHITE_2]	=	tpt.[PATIENT_RACE_WHITE_2]	,
			[PATIENT_RACE_WHITE_3]	=	tpt.[PATIENT_RACE_WHITE_3]	,
			[PATIENT_RACE_WHITE_GT3_IND]	=	tpt.[PATIENT_RACE_WHITE_GT3_IND]	,
			[PATIENT_RACE_WHITE_ALL]	=	tpt.[PATIENT_RACE_WHITE_ALL]	,
			[PATIENT_NUMBER]	=		substring(tpt.[PATIENT_NUMBER] ,1,50),
			[PATIENT_NUMBER_AUTH]	=	tpt.[PATIENT_NUMBER_AUTH]	,
			[PATIENT_ENTRY_METHOD]	=	tpt.[PATIENT_ENTRY_METHOD]	,
			[PATIENT_LAST_CHANGE_TIME]	=	tpt.[PATIENT_LAST_CHANGE_TIME]	,
			[PATIENT_ADD_TIME]	=	tpt.[PATIENT_ADD_TIME]	,
			[PATIENT_ADDED_BY]	=	tpt.[PATIENT_ADDED_BY]	,
			[PATIENT_LAST_UPDATED_BY]	=	tpt.[PATIENT_LAST_UPDATED_BY]	,
			[PATIENT_SPEAKS_ENGLISH]	=	tpt.[PATIENT_SPEAKS_ENGLISH]	,
			[PATIENT_UNK_ETHNIC_RSN]	=	tpt.[PATIENT_UNK_ETHNIC_RSN]	,
			[PATIENT_CURR_SEX_UNK_RSN]	=	tpt.[PATIENT_CURR_SEX_UNK_RSN]	,
			[PATIENT_PREFERRED_GENDER]	=	tpt.[PATIENT_PREFERRED_GENDER]	,
			[PATIENT_ADDL_GENDER_INFO]	=	tpt.[PATIENT_ADDL_GENDER_INFO]	,
			[PATIENT_CENSUS_TRACT]	=	tpt.[PATIENT_CENSUS_TRACT]	,
			[PATIENT_RACE_ALL]	=	tpt.[PATIENT_RACE_ALL]	,
			[PATIENT_BIRTH_COUNTRY]	=	 substring(tpt.[PATIENT_BIRTH_COUNTRY] ,1,50)	,
			[PATIENT_PRIMARY_OCCUPATION]	=		substring(tpt.[PATIENT_PRIMARY_OCCUPATION] ,1,50),
			[PATIENT_PRIMARY_LANGUAGE]	=		substring(tpt.[PATIENT_PRIMARY_LANGUAGE] ,1,50)
		from #temp_patient_table tpt
		inner join dbo.d_patient p on tpt.patient_uid = p.patient_uid 
		and tpt.patient_key = p.patient_key
		and p.patient_key is not null;
	
	/* Logging */
	set @rowcount=@@rowcount 
	if @rowcount > 0
		update dbo.nrt_batch_log
		set log_detail='Num of Patient keys updated: '+ cast(@rowcount as nvarchar(max))+ '.'
		where batch_id=@log_id; 
	else 
		update dbo.nrt_batch_log
		set log_detail='No Patient Updates.'
		where batch_id=@log_id; 
		

	/* D_Patient Insert Operation */
	-- declare @max_key bigint;
	-- select  @max_key = max(patient_key) from dbo.d_patient;
	
	-- delete from the key table to generate new keys for the resulting new data to be inserted
	delete from dbo.nrt_patient_key ;
	insert into dbo.nrt_patient_key(patient_uid) 
	select patient_uid from #temp_patient_table where patient_key is null order by patient_uid;

	insert into dbo.d_patient
			([PATIENT_KEY]
				  ,[PATIENT_MPR_UID]
				  ,[PATIENT_RECORD_STATUS]
				  ,[PATIENT_LOCAL_ID]
				  ,[PATIENT_GENERAL_COMMENTS]
				  ,[PATIENT_FIRST_NAME]
				  ,[PATIENT_MIDDLE_NAME]
				  ,[PATIENT_LAST_NAME]
				  ,[PATIENT_NAME_SUFFIX]
				  ,[PATIENT_ALIAS_NICKNAME]
				  ,[PATIENT_STREET_ADDRESS_1]
				  ,[PATIENT_STREET_ADDRESS_2]
				  ,[PATIENT_CITY]
				  ,[PATIENT_STATE]
				  ,[PATIENT_STATE_CODE]
				  ,[PATIENT_ZIP]
				  ,[PATIENT_COUNTY]
				  ,[PATIENT_COUNTY_CODE]
				  ,[PATIENT_COUNTRY]
				  ,[PATIENT_WITHIN_CITY_LIMITS]
				  ,[PATIENT_PHONE_HOME]
				  ,[PATIENT_PHONE_EXT_HOME]
				  ,[PATIENT_PHONE_WORK]
				  ,[PATIENT_PHONE_EXT_WORK]
				  ,[PATIENT_PHONE_CELL]
				  ,[PATIENT_EMAIL]
				  ,[PATIENT_DOB]
				  ,[PATIENT_AGE_REPORTED] 
				  ,[PATIENT_AGE_REPORTED_UNIT] 
				  ,[PATIENT_BIRTH_SEX] 
				  ,[PATIENT_CURRENT_SEX] 
				  ,[PATIENT_DECEASED_INDICATOR] 
				  ,[PATIENT_DECEASED_DATE]
				  ,[PATIENT_MARITAL_STATUS] 
				  ,[PATIENT_SSN] 
				  ,[PATIENT_ETHNICITY] 
				  ,[PATIENT_RACE_CALCULATED] 
				  ,[PATIENT_RACE_CALC_DETAILS]
				  ,[PATIENT_RACE_AMER_IND_1]
				  ,[PATIENT_RACE_AMER_IND_2]
				  ,[PATIENT_RACE_AMER_IND_3]
				  ,[PATIENT_RACE_AMER_IND_GT3_IND]
				  ,[PATIENT_RACE_AMER_IND_ALL]
				  ,[PATIENT_RACE_ASIAN_1]
				  ,[PATIENT_RACE_ASIAN_2]
				  ,[PATIENT_RACE_ASIAN_3]
				  ,[PATIENT_RACE_ASIAN_GT3_IND]
				  ,[PATIENT_RACE_ASIAN_ALL]
				  ,[PATIENT_RACE_BLACK_1]
				  ,[PATIENT_RACE_BLACK_2]
				  ,[PATIENT_RACE_BLACK_3]
				  ,[PATIENT_RACE_BLACK_GT3_IND]
				  ,[PATIENT_RACE_BLACK_ALL]
				  ,[PATIENT_RACE_NAT_HI_1]
				  ,[PATIENT_RACE_NAT_HI_2]
				  ,[PATIENT_RACE_NAT_HI_3]
				  ,[PATIENT_RACE_NAT_HI_GT3_IND]
				  ,[PATIENT_RACE_NAT_HI_ALL]
				  ,[PATIENT_RACE_WHITE_1]
				  ,[PATIENT_RACE_WHITE_2]
				  ,[PATIENT_RACE_WHITE_3]
				  ,[PATIENT_RACE_WHITE_GT3_IND]
				  ,[PATIENT_RACE_WHITE_ALL]
				  ,[PATIENT_NUMBER] 
				  ,[PATIENT_NUMBER_AUTH]
				  ,[PATIENT_ENTRY_METHOD]
				  ,[PATIENT_LAST_CHANGE_TIME]
				  ,[PATIENT_UID]
				  ,[PATIENT_ADD_TIME]
				  ,[PATIENT_ADDED_BY]
				  ,[PATIENT_LAST_UPDATED_BY]
				  ,[PATIENT_SPEAKS_ENGLISH]
				  ,[PATIENT_UNK_ETHNIC_RSN]
				  ,[PATIENT_CURR_SEX_UNK_RSN]
				  ,[PATIENT_PREFERRED_GENDER]
				  ,[PATIENT_ADDL_GENDER_INFO]
				  ,[PATIENT_CENSUS_TRACT]
				  ,[PATIENT_RACE_ALL]
				  ,[PATIENT_BIRTH_COUNTRY] 
				  ,[PATIENT_PRIMARY_OCCUPATION] 
				  ,[PATIENT_PRIMARY_LANGUAGE] )
			SELECT  distinct k.[d_PATIENT_KEY] as PATIENT_KEY  
				  ,tpt.[PATIENT_MPR_UID]
				  ,tpt.[PATIENT_RECORD_STATUS]
				  ,tpt.[PATIENT_LOCAL_ID]
				  ,substring(tpt.[PATIENT_GENERAL_COMMENTS] ,1,2000)
				  ,tpt.[PATIENT_FIRST_NAME]
				  ,tpt.[PATIENT_MIDDLE_NAME]
				  ,tpt.[PATIENT_LAST_NAME]
				  ,tpt.[PATIENT_NAME_SUFFIX]
				  ,tpt.[PATIENT_ALIAS_NICKNAME]
				  ,substring(tpt.[PATIENT_STREET_ADDRESS_1],1,50)
				  ,substring(tpt.[PATIENT_STREET_ADDRESS_2],1,50)
				  ,substring(tpt.[PATIENT_CITY],1,50)
				  ,tpt.[PATIENT_STATE]
				  ,tpt.[PATIENT_STATE_CODE]
				  ,tpt.[PATIENT_ZIP]
				  ,substring(tpt.[PATIENT_COUNTY],1,50)
				  ,tpt.[PATIENT_COUNTY_CODE]
				  ,tpt.[PATIENT_COUNTRY]
				  ,tpt.[PATIENT_WITHIN_CITY_LIMITS]
				  ,tpt.[PATIENT_PHONE_HOME]
				  ,tpt.[PATIENT_PHONE_EXT_HOME]
				  ,tpt.[PATIENT_PHONE_WORK]
				  ,tpt.[PATIENT_PHONE_EXT_WORK]
				  ,tpt.[PATIENT_PHONE_CELL]
				  ,tpt.[PATIENT_EMAIL]
				  ,tpt.[PATIENT_DOB]
				  ,tpt.[PATIENT_AGE_REPORTED]
				  ,substring(tpt.[PATIENT_AGE_REPORTED_UNIT] ,1,20)
				  ,substring(tpt.[PATIENT_BIRTH_SEX] ,1,50)
				  ,substring(tpt.[PATIENT_CURRENT_SEX] ,1,50)
				  ,substring(tpt.[PATIENT_DECEASED_INDICATOR] ,1,50)
				  ,tpt.[PATIENT_DECEASED_DATE]
				  ,substring(tpt.[PATIENT_MARITAL_STATUS] ,1,50)
				  ,substring(tpt.[PATIENT_SSN] ,1,50)
				  ,substring(tpt.[PATIENT_ETHNICITY] ,1,50)
				  ,substring(tpt.[PATIENT_RACE_CALCULATED] ,1,50)
				  ,tpt.[PATIENT_RACE_CALC_DETAILS]
				  ,tpt.[PATIENT_RACE_AMER_IND_1]
				  ,tpt.[PATIENT_RACE_AMER_IND_2]
				  ,tpt.[PATIENT_RACE_AMER_IND_3]
				  ,tpt.[PATIENT_RACE_AMER_IND_GT3_IND]
				  ,tpt.[PATIENT_RACE_AMER_IND_ALL]
				  ,tpt.[PATIENT_RACE_ASIAN_1]
				  ,tpt.[PATIENT_RACE_ASIAN_2]
				  ,tpt.[PATIENT_RACE_ASIAN_3]
				  ,tpt.[PATIENT_RACE_ASIAN_GT3_IND]
				  ,tpt.[PATIENT_RACE_ASIAN_ALL]
				  ,tpt.[PATIENT_RACE_BLACK_1]
				  ,tpt.[PATIENT_RACE_BLACK_2]
				  ,tpt.[PATIENT_RACE_BLACK_3]
				  ,tpt.[PATIENT_RACE_BLACK_GT3_IND]
				  ,tpt.[PATIENT_RACE_BLACK_ALL]
				  ,tpt.[PATIENT_RACE_NAT_HI_1]
				  ,tpt.[PATIENT_RACE_NAT_HI_2]
				  ,tpt.[PATIENT_RACE_NAT_HI_3]
				  ,tpt.[PATIENT_RACE_NAT_HI_GT3_IND]
				  ,tpt.[PATIENT_RACE_NAT_HI_ALL]
				  ,tpt.[PATIENT_RACE_WHITE_1]
				  ,tpt.[PATIENT_RACE_WHITE_2]
				  ,tpt.[PATIENT_RACE_WHITE_3]
				  ,tpt.[PATIENT_RACE_WHITE_GT3_IND]
				  ,tpt.[PATIENT_RACE_WHITE_ALL]
				  ,substring(tpt.[PATIENT_NUMBER] ,1,50)
				  ,tpt.[PATIENT_NUMBER_AUTH]
				  ,tpt.[PATIENT_ENTRY_METHOD]
				  ,tpt.[PATIENT_LAST_CHANGE_TIME]
				  ,tpt.[PATIENT_UID]
				  ,tpt.[PATIENT_ADD_TIME]
				  ,tpt.[PATIENT_ADDED_BY]
				  ,tpt.[PATIENT_LAST_UPDATED_BY]
				  ,tpt.[PATIENT_SPEAKS_ENGLISH]
				  ,tpt.[PATIENT_UNK_ETHNIC_RSN]
				  ,tpt.[PATIENT_CURR_SEX_UNK_RSN]
				  ,tpt.[PATIENT_PREFERRED_GENDER]
				  ,tpt.[PATIENT_ADDL_GENDER_INFO]
				  ,tpt.[PATIENT_CENSUS_TRACT]
				  ,tpt.[PATIENT_RACE_ALL]
				  ,substring(tpt.[PATIENT_BIRTH_COUNTRY] ,1,50)
				  ,substring(tpt.[PATIENT_PRIMARY_OCCUPATION] ,1,50)
				  ,substring(tpt.[PATIENT_PRIMARY_LANGUAGE] ,1,50)
			  FROM #temp_patient_table tpt
			  join dbo.nrt_patient_key k on tpt.patient_uid = k.patient_uid
			  where tpt.patient_key is null;
			 			  
		/* Logging */
		set @rowcount=@@rowcount 	  
		if @rowcount > 0
			update dbo.nrt_batch_log
			set log_detail=log_detail+' Num of Patient keys inserted: ' + cast(@rowcount as nvarchar(max))+ '.'
		where batch_id=@log_id; 
		else 
			update dbo.nrt_batch_log
			set log_detail=log_detail+' No Patient Inserts.'
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
  
      	return @ErrorMessage;

	END CATCH
	
END