CREATE OR ALTER FUNCTION dbo.fn_get_record_status (@record_status_cd nvarchar(100))
RETURNS nvarchar(200)
AS 
begin
	-- get the record status by code 
	-- Other than LOG_DEL rest of them are all ACTIVE
	select  @record_status_cd = 
 		case 
			when @record_status_cd = 'LOG_DEL' then  'INACTIVE'
			else 'ACTIVE'
		end
	RETURN @record_status_cd
end