CREATE or ALTER FUNCTION dbo.fn_get_user_name(@user_id as bigint)
    RETURNS Table
        AS RETURN
        SELECT CAST((RTRIM(LTRIM(au.user_last_nm)) + ', ' +
                     RTRIM(LTRIM(au.user_first_nm))) as varchar(150)) as user_full_name
        FROM NBS_ODSE.dbo.Auth_user au WITH (NOLOCK)
        WHERE au.NEDSS_ENTRY_ID = @user_id;