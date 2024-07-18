CREATE OR ALTER PROCEDURE dbo.sp_ldf_patient_event @ldf_uid_list nvarchar(max), @bus_obj_uid_list nvarchar(max)
AS
Begin
	
 BEGIN TRY
 
 /*select * from dbo.v_ldf_patient ldf                
  WHERE ldf.ldf_uid in (SELECT value FROM STRING_SPLIT(@ldf_uid_list, ',')) 
  and ldf.business_object_uid  in (SELECT value FROM STRING_SPLIT(@bus_obj_uid_list, ',')) 
    Order By ldf.business_object_uid, ldf.display_order_nbr;*/

   select distinct m.ldf_uid,
m.active_ind,
m.add_time ldf_meta_data_add_time,
m.admin_comment,
m.business_object_nm ldf_meta_data_business_object_nm,
m.category_type,
m.cdc_national_id,
m.class_cd,
m.code_set_nm,
m.condition_cd,
m.condition_desc_txt,
m.data_type,
m.deployment_cd,
m.display_order_nbr,
m.field_size,
m.label_txt,
m.ldf_page_id,
m.required_ind,
m.state_cd,
m.validation_txt,
m.validation_jscript_txt,
p.record_status_time,
dbo.fn_get_record_status(p.record_status_cd) as record_status_cd,
m.custom_subform_metadata_uid,
m.html_tag,
m.import_version_nbr,
m.nnd_ind,
m.ldf_oid,
m.version_ctrl_nbr ldf_meta_data_version_ctrl_num,
m.NBS_QUESTION_UID, d.business_object_uid,
d.add_time ldf_data_field_add_time,
d.business_object_nm ldf_field_data_business_object_nm,
d.last_chg_time ldf_data_last_chg_time,
d.ldf_value,
d.version_ctrl_nbr ldf_field_data_version_ctrl_num , cvg.code_desc_txt as LDF_COLUMN_TYPE
 from  nbs_odse.dbo.State_Defined_Field_MetaData m
   join nbs_odse.dbo.State_Defined_Field_Data d on m.ldf_uid = d.ldf_uid  and d.business_object_nm = 'PAT'
   	 	and d.business_object_uid  in (SELECT value FROM STRING_SPLIT(@bus_obj_uid_list, ',')) 
  	 	and d.ldf_uid in (SELECT value FROM STRING_SPLIT(@ldf_uid_list, ',')) 
   join nbs_srte.dbo.code_value_general cvg  on  cvg.code = m.data_type  and cvg.code_set_nm = 'LDF_DATA_TYPE'
   join nbs_odse.dbo.Person p on d.business_object_uid=p.person_uid  and p.person_uid<>p.person_parent_uid   
		and p.cd='PAT' 
  Order By business_object_uid, display_order_nbr 
  
 end try

 BEGIN CATCH
  
     
     IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;
  
    	DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE(); 

      	return @ErrorMessage;

	END CATCH
	
end;