CREATE OR ALTER FUNCTION dbo.fn_get_value_by_cd_ques(
    @srte_code nvarchar(200),
    @ques_identifier nvarchar(200)
)
    returns table
        as return
        select cvg.code_short_desc_txt
        from nbs_odse.dbo.nbs_question nq with (nolock)
                 join nbs_srte.dbo.codeset cd with (nolock) on cd.code_set_group_id = nq.code_set_group_id
                 join nbs_srte.dbo.code_value_general cvg with (nolock) on cvg.code_set_nm = cd.code_set_nm
            and nq.question_identifier = (@ques_identifier)
            and @srte_code = cvg.code
            and @srte_code is not null;