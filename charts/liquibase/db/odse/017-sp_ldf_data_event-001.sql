CREATE OR ALTER PROCEDURE dbo.sp_ldf_data_event @bus_obj_nm varchar(20), @ldf_uid nvarchar(max),  @bus_obj_uid_list nvarchar(max)
AS 
begin
	 begin try
			if @bus_obj_nm = 'PAT'  exec dbo.sp_ldf_patient_event @ldf_uid, @bus_obj_uid_list 
			else if @bus_obj_nm = 'PRV'  exec dbo.sp_ldf_provider_event @ldf_uid , @bus_obj_uid_list 
			else if  @bus_obj_nm = 'ORG'  exec dbo.sp_ldf_organization_event @ldf_uid, @bus_obj_uid_list 
			else if  @bus_obj_nm = 'LAB'  exec dbo.sp_ldf_observation_event @ldf_uid, @bus_obj_uid_list 
			else if  @bus_obj_nm = 'PHC'  exec dbo.sp_ldf_phc_event @ldf_uid, @bus_obj_uid_list 
			else if  @bus_obj_nm = 'VAC'  exec dbo.sp_ldf_intervention_event @ldf_uid, @bus_obj_uid_list 
	end try

	BEGIN CATCH

     IF @@TRANCOUNT > 0   ROLLBACK TRANSACTION;
  
    	DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE(); 

      	return 'ERROR : ' + @ErrorMessage;

	END CATCH 
end
