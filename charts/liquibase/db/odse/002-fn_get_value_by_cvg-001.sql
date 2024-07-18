CREATE OR ALTER FUNCTION dbo.fn_get_value_by_cvg(
    @srte_code nvarchar(200),
    @cvg_str nvarchar(200)
)
    returns table
        as return
        select cvg.code_short_desc_txt
        from nbs_srte.dbo.code_value_general cvg with (nolock)
        where cvg.code_set_nm = @cvg_str
          and @srte_code = cvg.code
          and @srte_code is not null;