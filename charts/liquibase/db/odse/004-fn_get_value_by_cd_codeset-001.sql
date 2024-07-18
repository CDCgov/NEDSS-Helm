CREATE OR ALTER function dbo.fn_get_value_by_cd_codeset(
    @srte_code nvarchar(200),
    @unique_cd nvarchar(200)
)
    returns table
        as return

        select cvg.code_short_desc_txt
        from nbs_srte.dbo.codeset cd with (nolock)
                 join nbs_srte.dbo.totalidm tidm with (nolock) on tidm.SRT_reference = cd.code_set_nm and tidm.unique_cd = (@unique_cd)
                 join nbs_srte.dbo.code_value_general cvg with (nolock) on cvg.code_set_nm = cd.code_set_nm
            and  cvg.code = @srte_code
            and  @srte_code is not null;