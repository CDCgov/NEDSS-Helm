CREATE OR ALTER PROCEDURE [dbo].[sp_investigation_event] @phc_id_list nvarchar(max)
AS 
Begin
	
 BEGIN TRY

/*NBS case answer section
 * TODO: Bring in null rows*/ 
 
SELECT
	* 
 into
	#temp_page_case_answer_table
FROM
	(
	SELECT
		*,
		ROW_NUMBER () OVER (PARTITION BY NBS_QUESTION_UID
	order by
		NBS_QUESTION_UID,
		other_value_ind_cd desc) rowid
	FROM
		(
		SELECT
			distinct nbs_case_answer_uid,
			nuim.nbs_ui_metadata_uid,
			nrdbm.nbs_rdb_metadata_uid,
			nrdbm.rdb_table_nm,
			nrdbm.rdb_column_nm,
			nuim.code_set_group_id,
			cast (replace(answer_txt, char(13)+ char(10), ' ') as varchar(2000)) as answer_txt,
			pa.act_uid,
			pa.record_status_cd,
			nuim.nbs_question_uid,
			nuim.investigation_form_cd,
			nuim.unit_value,
			nuim.question_identifier,
			pa.answer_group_seq_nbr,
			nuim.data_location,
			question_label,
			other_value_ind_cd,
			unit_type_cd,
			mask,
			nuim.block_nm,
			question_group_seq_nbr,
			data_type,
			pa.last_chg_time
		from
			nbs_odse.dbo.nbs_rdb_metadata nrdbm with (nolock)
		inner join nbs_odse.dbo.nbs_ui_metadata nuim with (nolock) on
			nrdbm.nbs_ui_metadata_uid = nuim.nbs_ui_metadata_uid
		left outer join nbs_odse.dbo.nbs_case_answer pa with (nolock) on
			nuim.nbs_question_uid = pa.nbs_question_uid
		inner join nbs_srte.dbo.code_value_general cvg with (nolock) on
			cvg.code = nuim.data_type
		where
			cvg.code_set_nm = 'NBS_DATA_TYPE'
			and 
			act_uid in (
			SELECT
				value
			FROM
				STRING_SPLIT(@phc_id_list,
				','))
	) as answer_table 
) as answer_table
where
	rowid = 1;

/*Complete Investigation section*/  
SELECT 
  results.public_health_case_uid,
  results.program_jurisdiction_oid as program_jurisdiction_oid,      
  jc.code as jurisdiction_code,
  jc.code_desc_txt as jurisdiction_nm,
  act.mood_cd,act.class_cd ,  
  results.case_type_cd,
  results.case_class_cd,
  results.inv_case_status,
  results.outbreak_name,
  results.cd,
  results.cd_desc_txt,
  results.prog_area_cd,
  results.jurisdiction_cd,
  results.pregnant_ind_cd,
  results.pregnant_ind,
  results.local_id local_id,
  results.rpt_form_cmplt_time,
  results.activity_to_time,
  results.activity_from_time,
  results.add_user_id,
  case when results.add_user_id > 0 then (select * from dbo.fn_get_user_name(results.add_user_id)) 
  end as add_user_name,
  results.add_time,
  results.last_chg_user_id,
  case when results.last_chg_user_id > 0 then  (select * from dbo.fn_get_user_name(results.last_chg_user_id))
  end as last_chg_user_name,
  results.last_chg_time,
  results.curr_process_state_cd,
  results.curr_process_state,
  results.investigation_status_cd,
  results.investigation_status,
  case when (results.record_status_cd is not null or results.record_status_cd != '') then dbo.fn_get_record_status(results.record_status_cd)
  end as record_status_cd,
  results.shared_ind,
  results.txt,
  results.effective_from_time,
  results.effective_to_time,
  results.rpt_source_cd,
  results.rpt_src_cd_desc,
  results.rpt_to_county_time,
  results.rpt_to_state_time,
  results.mmwr_week,
  results.mmwr_year,
  results.disease_imported_cd,
  results.disease_imported_ind,
  results.imported_country_cd,
  results.imported_state_cd,
  results.imported_county_cd,
  results.imported_from_country,
  sc.state_nm imported_from_state,
  sccv.code_desc_txt imported_from_county,
  results.imported_city_desc_txt,
  results.diagnosis_time,
  results.hospitalized_admin_time,
  results.hospitalized_discharge_time,
  results.hospitalized_duration_amt,
  results.outbreak_ind,
  results.outbreak_ind_val,
  results.hospitalized_ind_cd,
  results.hospitalized_ind,
  results.transmission_mode_cd,
  results.transmission_mode,
  results.outcome_cd,
  results.die_frm_this_illness_ind,
  results.day_care_ind_cd,
  results.day_care_ind,
  results.food_handler_ind_cd,
  results.food_handler_ind,
  results.deceased_time,
  results.pat_age_at_onset,
  results.pat_age_at_onset_unit_cd,
  results.pat_age_at_onset_unit,
  results.detection_method_cd,
  results.priority_cd,
  results.contact_inv_status_cd,
  cvg.code_desc_txt detection_method_desc_txt,
  cvg1.code_short_desc_txt contact_inv_priority,
  cvg2.code_short_desc_txt contact_inv_status,
  results.investigator_assigned_time,
  results.effective_duration_amt,
  results.effective_duration_unit_cd,
  results.illness_duration_unit,
  results.infectious_from_date,
  results.infectious_to_date,
  results.referral_basis_cd,
  results.referral_basis,
  results.inv_priority_cd,
  results.coinfection_id, 
  results.contact_inv_txt,
  pac.prog_area_desc_txt program_area_description, 
  notification.local_id notification_local_id,
  notification.add_time notification_add_time,
  notification.record_status_cd notification_record_status_cd,
  notification.last_chg_time notification_last_chg_time
  ,cm.case_management_uid
  ,investigation_act_entity.nac_page_case_uid
  ,investigation_act_entity.nac_last_chg_time
  ,investigation_act_entity.nac_add_time
  ,investigation_act_entity.person_as_reporter_uid
  ,investigation_act_entity.hospital_uid
  ,investigation_act_entity.ordering_facilty_uid
  ,results.act_ids
  ,results.observation_notification_ids
  ,results.person_participations
  ,results.organization_participations
  ,results.investigation_confirmation_method
  ,results.investigation_case_answer
  ,results.investigation_notifications
  --con.investigation_form_cd,  
  -- ,results.investigation_act_entity
  -- ,results.ldf_public_health_case
  -- into dbo.Investigation_Dim_Event
FROM
  (
    SELECT
      phc.public_health_case_uid,
      phc.program_jurisdiction_oid program_jurisdiction_oid,
      phc.case_type_cd,
      phc.case_class_cd,
      case when (phc.case_class_cd is not null or phc.case_class_cd != '') then (select * from dbo.fn_get_value_by_cd_codeset(phc.case_class_cd, 'INV163'))
  		end as inv_case_status,
      phc.outbreak_name,
      phc.cd,
      phc.cd_desc_txt cd_desc_txt,
      phc.prog_area_cd prog_area_cd,
      phc.jurisdiction_cd jurisdiction_cd,
      phc.pregnant_ind_cd pregnant_ind_cd,
      case when (phc.pregnant_ind_cd is not null or phc.pregnant_ind_cd != '') then (select * from dbo.fn_get_value_by_cd_codeset(phc.pregnant_ind_cd, 'INV178'))
  		end as pregnant_ind,
      phc.local_id local_id,
      phc.rpt_form_cmplt_time rpt_form_cmplt_time,
      phc.activity_to_time activity_to_time,
      phc.add_time add_time,
      phc.activity_from_time activity_from_time,
      phc.last_chg_time,
      phc.add_user_id add_user_id,
      phc.last_chg_user_id last_chg_user_id,
      phc.curr_process_state_cd curr_process_state_cd,
      case when (phc.curr_process_state_cd is not null or phc.curr_process_state_cd != '') then (select * from dbo.fn_get_value_by_cvg(phc.curr_process_state_cd, 'CM_PROCESS_STAGE'))
  		end as curr_process_state,
      phc.investigation_status_cd,
      case when (phc.investigation_status_cd is not null or phc.investigation_status_cd != '') then (select * from dbo.fn_get_value_by_cd_codeset(phc.investigation_status_cd, 'INV109'))
  		end as investigation_status,
      phc.record_status_cd,
      phc.shared_ind,
	  phc.txt,
	  phc.effective_from_time,
	  phc.effective_to_time,
	  phc.rpt_source_cd,
	  case when (phc.rpt_source_cd is not null or phc.rpt_source_cd != '') then (select * from dbo.fn_get_value_by_cd_codeset(phc.rpt_source_cd, 'INV112'))
  		end as rpt_src_cd_desc,
	  phc.rpt_to_county_time,
	  phc.rpt_to_state_time,
	  phc.mmwr_week,
	  phc.mmwr_year,
	  phc.disease_imported_cd,
	  case when (phc.disease_imported_cd is not null or phc.disease_imported_cd != '') then (select * from dbo.fn_get_value_by_cd_codeset(phc.disease_imported_cd, 'INV152'))
  		end as disease_imported_ind,
	  phc.imported_city_desc_txt,
	  phc.imported_country_cd,
	  case when (phc.imported_country_cd is not null or phc.imported_country_cd != '') then (select * from dbo.fn_get_value_by_cd_codeset(phc.imported_country_cd, 'INV153'))
  		end as imported_from_country,
	  phc.imported_state_cd,
	  phc.imported_county_cd,
	  phc.diagnosis_time,
	  phc.hospitalized_admin_time,
	  phc.hospitalized_discharge_time,
	  phc.hospitalized_duration_amt,
	  phc.outbreak_ind,
	  case when (phc.outbreak_ind is not null or phc.outbreak_ind != '') then (select * from dbo.fn_get_value_by_cd_codeset(phc.outbreak_ind, 'INV150'))
  		end as outbreak_ind_val,
	  phc.hospitalized_ind_cd,
	  case when (phc.hospitalized_ind_cd is not null or phc.hospitalized_ind_cd != '') then (select * from dbo.fn_get_value_by_cd_codeset(phc.hospitalized_ind_cd, 'INV128'))
  		end as hospitalized_ind,
	  phc.transmission_mode_cd,
	  case when (phc.transmission_mode_cd is not null or phc.transmission_mode_cd != '') then (select * from dbo.fn_get_value_by_cd_codeset(phc.transmission_mode_cd, 'INV157'))
  		end as transmission_mode,
	  phc.outcome_cd,
	  case when (phc.outcome_cd != '') then (select * from dbo.fn_get_value_by_cd_codeset(phc.outcome_cd, 'INV145'))
  		end as die_frm_this_illness_ind,
	  phc.day_care_ind_cd,
	  case when (phc.day_care_ind_cd is not null or phc.day_care_ind_cd != '') then (select * from dbo.fn_get_value_by_cd_codeset(phc.day_care_ind_cd, 'INV148'))
  		end as day_care_ind,
	  phc.food_handler_ind_cd,
	  case when (phc.food_handler_ind_cd is not null or phc.food_handler_ind_cd != '') then (select * from dbo.fn_get_value_by_cd_codeset(phc.food_handler_ind_cd, 'INV149'))
  		end as food_handler_ind,
	  phc.deceased_time,
	  phc.pat_age_at_onset,
	  phc.pat_age_at_onset_unit_cd,
	  case when (phc.pat_age_at_onset_unit_cd is not null or phc.pat_age_at_onset_unit_cd != '') then (select * from dbo.fn_get_value_by_cd_codeset(phc.pat_age_at_onset_unit_cd, 'INV144'))
  		end as pat_age_at_onset_unit,
  	  phc.detection_method_cd,
  	  phc.priority_cd,
	  phc.investigator_assigned_time,
	  phc.effective_duration_amt,
	  phc.effective_duration_unit_cd,
	  case when (phc.effective_duration_unit_cd is not null or phc.effective_duration_unit_cd != '') then (select * from dbo.fn_get_value_by_cd_codeset(phc.effective_duration_unit_cd, 'INV144'))
  		end as illness_duration_unit,
	  phc.infectious_from_date,
	  phc.infectious_to_date,
	  phc.referral_basis_cd,
	  case when (phc.referral_basis_cd is not null or phc.referral_basis_cd != '') then (select * from dbo.fn_get_value_by_cvg(phc.referral_basis_cd, 'REFERRAL_BASIS'))
  		end as referral_basis,
	  phc.inv_priority_cd,
	  phc.contact_inv_status_cd,
	  phc.coinfection_id,
	  phc.contact_inv_txt,
      nesteddata.act_ids,
      nesteddata.observation_notification_ids,
      nesteddata.person_participations,
      nesteddata.organization_participations,
      nesteddata.investigation_confirmation_method,
      nesteddata.investigation_case_answer
      ,nesteddata.investigation_notifications
      --,nesteddata.ldf_public_health_case
    FROM
      --public health case
      public_health_case phc
      WITH (NOLOCK)
       OUTER apply (
        SELECT
          *
        FROM
          (
            -- persons associated with public_health_case
            SELECT
              (
                SELECT
                  p.act_uid AS [act_uid],
                  p.type_cd AS [type_cd],
                  p.subject_entity_uid AS [entity_id],
                  p.subject_class_cd AS [subject_class_cd],
                  p.record_status_cd AS [participation_record_status],
                  p.last_chg_time AS [participation_last_change_time],
                  STRING_ESCAPE(person.first_nm, 'json') AS [first_name],
                  STRING_ESCAPE(person.last_nm, 'json') AS [last_name],
                  person.local_id AS [local_id],
                  person.birth_time AS [birth_time],
                  person.curr_sex_cd AS [curr_sex_cd],
                  person.cd AS [person_cd],
                  person.person_parent_uid AS [person_parent_uid],
                  person.record_status_cd AS [person_record_status],
                  person.last_chg_time AS [person_last_chg_time]
              FROM
  participation p
                  WITH (NOLOCK)
                  JOIN person ON person.person_uid = (
      select
                      person.person_parent_uid
     from
                      person
                    where
                      person.person_uid = p.subject_entity_uid
                  )
                WHERE
      p.act_uid = phc.public_health_case_uid FOR json path,INCLUDE_NULL_VALUES
              ) AS person_participations
          ) AS person_participations,
          (
      SELECT
            (
                SELECT
                  p.act_uid AS [act_uid],
                  p.type_cd AS [type_cd],
                  p.subject_entity_uid AS [entity_id],
                  p.subject_class_cd AS [subject_class_cd],
                  p.record_status_cd AS [record_status],
                  p.last_chg_time AS [participation_last_change_time],
                  STRING_ESCAPE(org.display_nm, 'json') AS [name],
                  org.last_chg_time AS [org_last_change_time]
                FROM
                  participation p
                  WITH (NOLOCK)
                  JOIN organization org ON org.organization_uid = p.subject_entity_uid
                WHERE
                  p.act_uid = phc.public_health_case_uid FOR json path,INCLUDE_NULL_VALUES
              ) AS organization_participations
          ) AS organization_participations
          -- act_ids associated with public health case
          ,(
            SELECT
              (
                SELECT                 
                act.source_act_uid ,
                act.target_Act_uid as public_health_case_uid,
                act.source_class_cd,
                act.target_class_cd,
                act.type_cd as act_type_cd,
                act.status_cd,
				act.add_time act_add_time,
                act.add_user_id act_add_user_id,
                case when act.add_user_id > 0 then (select * from dbo.fn_get_user_name(act.add_user_id)) 
  				end as add_user_name,
                act.last_chg_user_id act_last_chg_user_id,
                case when act.last_chg_user_id > 0 then (select * from dbo.fn_get_user_name(act.last_chg_user_id)) 
  				end as last_chg_user_name,
                act.last_chg_time as act_last_chg_time
                FROM
                  act_id WITH (NOLOCK) 
                  join act_relationship act WITH (NOLOCK) on act_id.act_uid = act.target_act_uid 
                WHERE
                  act.target_act_uid = phc.public_health_case_uid FOR json path,INCLUDE_NULL_VALUES
              ) AS observation_notification_ids
	    ) AS observation_notification_ids
	   -- act_ids associated with public health case
	          ,(
	            SELECT
	              (
	                SELECT
	                  act_id.act_uid AS [id],
	                  act_id_seq AS [act_id_seq],
	                  act_id.record_status_cd AS [record_status],
	                  act_id.root_extension_txt AS [root_extension_txt],
	                  act_id.type_cd AS [type_cd],
	                  act_id.type_desc_txt AS [type_desc_txt],
	                  act_id.add_time act_id_add_time,
	                  act_id.add_user_id act_id_add_user_id,
	                  act_id.last_chg_user_id act_id_last_chg_user_id,
	                  act_id.last_chg_time AS [act_id_last_change_time]             
	                FROM
	                  act_id WITH (NOLOCK) 
	                WHERE
	                  act_uid = phc.public_health_case_uid FOR json path,INCLUDE_NULL_VALUES
	      ) AS act_ids
	          ) AS act_ids,
          -- get assocaited confirmation method
          (
            SELECT
              (
               select cm.public_health_case_uid,
               	cm.confirmation_method_cd,
               	cvg.CODE_SHORT_DESC_TXT as confirmation_method_desc_txt,
               	cm.confirmation_method_time,
               	phc1.last_chg_time as phc_last_chg_time
				from dbo.Confirmation_method cm 
					join nbs_srte.dbo.Code_value_general cvg on cvg.code = cm.confirmation_method_cd and cvg.code_set_nm='PHC_CONF_M'
					join dbo.Public_health_case phc1 on cm.public_health_case_uid = phc1.public_health_case_uid 
                WHERE
                  cm.public_health_case_uid = phc.public_health_case_uid  FOR json path,INCLUDE_NULL_VALUES
              ) AS investigation_confirmation_method
          ) AS investigation_confirmation_method,
          -- NBS case answer associated with phc
	      (
	        SELECT
	          (
	           select 
	            nbs_case_answer_uid,
				nca.nbs_ui_metadata_uid,
				nca.nbs_rdb_metadata_uid,
				nca.rdb_table_nm,
				nca.rdb_column_nm,
				nca.code_set_group_id,
				nca.answer_txt,
				nca.act_uid,
				nca.record_status_cd,
				nca.nbs_question_uid,
				nca.investigation_form_cd,
				nca.unit_value,
				nca.question_identifier,
				nca.data_location,
				nca.answer_group_seq_nbr,
				nca.question_label,
				nca.other_value_ind_cd,
				nca.unit_type_cd,
				nca.mask,
				nca.block_nm,
				nca.question_group_seq_nbr,
				nca.data_type,
				nca.last_chg_time
				from #temp_page_case_answer_table nca WITH (NOLOCK)
	            WHERE
	              nca.act_uid = phc.public_health_case_uid  
	              --AND nca.last_chg_time = phc.last_chg_time  
	              FOR json path,INCLUDE_NULL_VALUES
	          ) AS investigation_case_answer
	      ) AS investigation_case_answer
	
	      -- investigation notification columns
	      ,(
	        SELECT
	          (
	           SELECT                 
                act.source_act_uid ,
                act.target_act_uid as public_health_case_uid,
                act.source_class_cd,
                act.target_class_cd,
                act.type_cd as act_type_cd,
                act.status_cd,
                notif.notification_uid,
                notif.prog_area_cd, 		
				notif.program_jurisdiction_oid, 
				notif.jurisdiction_cd,
				notif.record_status_time, 		
				notif.status_time,
                notif.rpt_sent_time,
                notif.record_status_cd as 'notif_status',
                notif.local_id as 'notif_local_id',
                notif.txt as 'notif_comments',
                notif.add_time as 'notif_add_time',
                notif.add_user_id as 'notif_add_user_id',
                case when notif.add_user_id > 0 then (select * from dbo.fn_get_user_name(notif.add_user_id)) 
  				end as 'notif_add_user_name',
                notif.last_chg_user_id as 'notif_last_chg_user_id',
                case when notif.last_chg_user_id > 0 then (select * from dbo.fn_get_user_name(notif.last_chg_user_id)) 
  				end as 'notif_last_chg_user_name',
                notif.last_chg_time as 'notif_last_chg_time',
                per.local_id as 'local_patient_id',
                per.person_uid as 'local_patient_uid',
                phc.cd as 'condition_cd',
                phc.cd_desc_txt as 'condition_desc'
                FROM
                  act_relationship act WITH (NOLOCK)
                  join notification notif WITH (NOLOCK) on  act.source_act_uid = notif.notification_uid
                  join nbs_odse.dbo.participation part with (nolock) ON part.type_cd='SubjOfPHC' AND part.act_uid=act.target_act_uid
				  join nbs_odse.dbo.person per with (nolock) ON per.cd='PAT' AND per.person_uid = part.subject_entity_uid
                WHERE
                  act.target_act_uid = phc.public_health_case_uid 
                  AND notif.cd not in ('EXP_NOTF', 'SHARE_NOTF', 'EXP_NOTF_PHDC','SHARE_NOTF_PHDC')
                  AND act.source_class_cd = 'NOTF'
              	  AND act.target_class_cd = 'CASE' FOR json path,INCLUDE_NULL_VALUES
	          ) AS investigation_notifications
	      ) AS investigation_notifications
	      
	      /*
           -- ldf_phc associated with phc
          ,(
            SELECT
              (
               select * from nbs_odse..v_ldf_phc ldf
                 WHERE ldf.public_health_case_uid = phc.public_health_case_uid
               Order By ldf.public_health_case_uid, ldf.display_order_nbr
 						FOR json path,INCLUDE_NULL_VALUES
              ) AS ldf_public_health_case
          ) AS ldf_public_health_case 
          */
          
      ) as nestedData
 WHERE
      phc.public_health_case_uid in (SELECT value FROM STRING_SPLIT(@phc_id_list, ','))
  ) AS results
  LEFT JOIN notification ON results.public_health_case_uid = notification.notification_uid
  LEFT JOIN nbs_srte.dbo.jurisdiction_code jc ON results.jurisdiction_cd = jc.code
  LEFT JOIN act ON act.act_uid = results.public_health_case_uid
  LEFT JOIN nbs_srte.dbo.program_area_code pac on results.prog_area_cd = pac.prog_area_cd
  LEFT JOIN nbs_srte.dbo.state_code sc ON results.imported_state_cd = sc.state_cd
  LEFT JOIN nbs_srte.dbo.state_county_code_value sccv ON results.imported_county_cd = sccv.code
  LEFT JOIN nbs_srte.dbo.code_value_general cvg ON results.detection_method_cd = cvg.code and cvg.code_set_nm='PHC_DET_MT'
  LEFT JOIN nbs_srte.dbo.code_value_general cvg1 on results.priority_cd = cvg1.code and cvg1.code_set_nm='NBS_PRIORITY'
  LEFT JOIN nbs_srte.dbo.code_value_general cvg2 on results.contact_inv_status_cd = cvg2.code and cvg2.code_set_nm='PHC_IN_STS'
  LEFT OUTER JOIN nbs_odse.dbo.case_management cm on results.public_health_case_uid= cm.public_health_case_uid
  LEFT JOIN 
	(  	
       SELECT DISTINCT act_uid AS nac_page_case_uid,
       last_chg_time AS nac_last_chg_time,
       add_time as nac_add_time, 
	   MAX(CASE WHEN type_cd = 'PerAsReporterOfPHC' THEN entity_uid END) person_as_reporter_uid,
	   MAX(CASE WHEN type_cd = 'HospOfADT' THEN entity_uid END) hospital_uid,
	   MAX(CASE WHEN type_cd = 'OrgAsClinicOfPHC' THEN entity_uid END) ordering_facilty_uid
        FROM
          nbs_act_entity nac WITH (NOLOCK)
        GROUP BY act_uid, last_chg_time, add_time
	     ) AS investigation_act_entity
	     ON investigation_act_entity.nac_page_case_uid = results.public_health_case_uid 
  --LEFT JOIN nbs_srte.dbo.condition_code con on results.cd = con.condition_cd
  ;
 
-- select * from dbo.Investigation_Dim_Event;
  end try

 BEGIN CATCH
  
     
     IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;
  
    	DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE(); 

  	return @ErrorMessage;

	END CATCH
	
end;
