CREATE OR ALTER PROCEDURE dbo.sp_patient_race_event @user_id_list nvarchar(max)
AS
begin

    SELECT pr.PERSON_UID AS 'PATIENT_UID',
           RACE_CD,
           RACE_CODE.CODE_DESC_TXT,
           RACE_CATEGORY_CD,
           RACE_CODE.PARENT_IS_CD
    into #TMP_S_PERSON_RACE
    from NBS_ODSE.dbo.PERSON_RACE pr with (nolock)
             LEFT OUTER JOIN NBS_SRTE.dbo.RACE_CODE with (nolock) ON pr.RACE_CD = RACE_CODE.CODE
             LEFT OUTER JOIN NBS_SRTE.dbo.RACE_CODE RT with (nolock) ON pr.RACE_CATEGORY_CD = RT.CODE
    where pr.person_uid in (SELECT value FROM STRING_SPLIT(@user_id_list, ','))
    ORDER BY PATIENT_UID, CODE_DESC_TXT;


    SELECT *
    into #TMP_PERSON_ROOT_RACE
    FROM #TMP_S_PERSON_RACE
    WHERE PARENT_IS_CD = 'ROOT'
--ORDER BY PATIENT_UID
    ;


    IF OBJECT_ID('#TMP_S_PERSON_AMER_INDIAN_RACE', 'U') IS NOT NULL
        drop table #TMP_S_PERSON_AMER_INDIAN_RACE ;


    SELECT *
    into #TMP_S_PERSON_AMER_INDIAN_RACE
    FROM #TMP_S_PERSON_RACE
    WHERE RACE_CATEGORY_CD = '1002-5'
      AND RACE_CD <> RACE_CATEGORY_CD
--ORDER BY PATIENT_UID
    ;


    IF OBJECT_ID('#TMP_S_PERSON_BLACK_RACE', 'U') IS NOT NULL
        drop table #TMP_S_PERSON_BLACK_RACE ;


    SELECT *
    into #TMP_S_PERSON_BLACK_RACE
    FROM #TMP_S_PERSON_RACE
    WHERE RACE_CATEGORY_CD = '2054-5'
      AND RACE_CD <> RACE_CATEGORY_CD
--ORDER BY PATIENT_UID
    ;


    IF OBJECT_ID('#TMP_S_PERSON_WHITE_RACE', 'U') IS NOT NULL
        drop table #TMP_S_PERSON_WHITE_RACE ;

    SELECT *
    into #TMP_S_PERSON_WHITE_RACE
    FROM #TMP_S_PERSON_RACE
    WHERE RACE_CATEGORY_CD = '2106-3'
      AND RACE_CD <> RACE_CATEGORY_CD
--ORDER BY PATIENT_UID
    ;


    IF OBJECT_ID('#TMP_S_PERSON_ASIAN_RACE', 'U') IS NOT NULL
        drop table #TMP_S_PERSON_ASIAN_RACE ;

    SELECT *
    into #TMP_S_PERSON_ASIAN_RACE
    FROM #TMP_S_PERSON_RACE
    WHERE RACE_CATEGORY_CD = '2028-9'
      AND RACE_CD <> RACE_CATEGORY_CD
--ORDER BY PATIENT_UID
    ;


    IF OBJECT_ID('#TMP_S_PERSON_HAWAIIAN_RACE', 'U') IS NOT NULL
        drop table #TMP_S_PERSON_HAWAIIAN_RACE ;

    SELECT *
    into #TMP_S_PERSON_HAWAIIAN_RACE
    FROM #TMP_S_PERSON_RACE
    WHERE RACE_CATEGORY_CD = '2076-8'
      AND RACE_CD <> RACE_CATEGORY_CD
--ORDER BY PATIENT_UID
    ;


/*Calculate Person Race*/

    IF OBJECT_ID('#TMP_S_PERSON_ROOT_RACE', 'U') IS NOT NULL
        drop table #TMP_S_PERSON_ROOT_RACE;

    select *
    into #TMP_S_PERSON_ROOT_RACE
    from #TMP_PERSON_ROOT_RACE;

    ALTER TABLE #TMP_S_PERSON_ROOT_RACE
        ADD PATIENT_RACE_CALCULATED VARCHAR(2000),
            PATIENT_RACE_CALC_DETAILS varchar(4000),
            PATIENT_RACE_ALL varchar(4000);

    with cte as (select patient_uid,
                        (STUFF((SELECT ' | ' + CAST(sppr2.CODE_DESC_TXT AS varchar(2000))
                                FROM #TMP_S_PERSON_ROOT_RACE sppr2
                                WHERE sppr2.patient_uid = sppr.patient_uid
                                FOR XML PATH('')), 2, 1, '')) AS CODE_DESC_TXT_List
                 from #TMP_S_PERSON_ROOT_RACE sppr
                 where CODE_DESC_TXT is not null
                 --and RACE_CATEGORY_CD not in ('PHC1175' ,'NASK','U')
                 group by patient_uid
        --having count(*) > 1

    )
    update sppr
    set sppr.PATIENT_RACE_ALL = rtrim(ltrim(cte1.CODE_DESC_TXT_List))
    from #TMP_S_PERSON_ROOT_RACE sppr,
         cte cte1
    where sppr.PATIENT_UID = cte1.PATIENT_UID
--and cte1.rn = 1
    ;


    with cte as (select patient_uid,
                        (STUFF((SELECT ' | ' + CAST(sppr2.CODE_DESC_TXT AS varchar(2000))
                                FROM #TMP_S_PERSON_ROOT_RACE sppr2
                                WHERE sppr2.patient_uid = sppr.patient_uid
                                  and RACE_CATEGORY_CD not in ('PHC1175', 'NASK', 'U')
                                FOR XML PATH('')), 2, 1, '')) AS CODE_DESC_TXT_List
                 from #TMP_S_PERSON_ROOT_RACE sppr
                 where CODE_DESC_TXT is not null
                 --and RACE_CATEGORY_CD not in ('PHC1175' ,'NASK','U')
                 group by patient_uid
        --having count(*) > 1

    )
    update sppr
    set sppr.PATIENT_RACE_CALC_DETAILS = rtrim(ltrim(cte1.CODE_DESC_TXT_List))
    from #TMP_S_PERSON_ROOT_RACE sppr,
         cte cte1
    where sppr.PATIENT_UID = cte1.PATIENT_UID
--and cte1.rn = 1
    ;


    update #TMP_S_PERSON_ROOT_RACE
    set PATIENT_RACE_CALCULATED =
            case
                when len(PATIENT_RACE_CALC_DETAILS) < 1 OR PATIENT_RACE_CALC_DETAILS is null then 'Unknown'
                when CHARINDEX('|', PATIENT_RACE_CALC_DETAILS) > 0 then 'Multi-Race'
                when CHARINDEX('|', PATIENT_RACE_CALC_DETAILS) = 0 then PATIENT_RACE_CALC_DETAILS
                end;


/*Person Race Breakdown*/
    ALTER TABLE #TMP_S_PERSON_AMER_INDIAN_RACE
        ADD
            PATIENT_RACE_AMER_IND_ALL varchar(2000),
            PATIENT_RACE_AMER_IND_1 varchar(50),
            PATIENT_RACE_AMER_IND_2 varchar(50),
            PATIENT_RACE_AMER_IND_3 varchar(50),
            PATIENT_RACE_AMER_IND_4 varchar(50),
            PATIENT_RACE_AMER_IND_GT3_IND varchar(10);
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_AMER_INDIAN_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_AMER_IND_1] = cte1.code_desc_txt
    from #TMP_S_PERSON_AMER_INDIAN_RACE prs,
         cte cte1
    where cte1.rn = 1
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_AMER_INDIAN_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_AMER_IND_2] = cte1.code_desc_txt
    from #TMP_S_PERSON_AMER_INDIAN_RACE prs,
         cte cte1
    where cte1.rn = 2
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_AMER_INDIAN_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_AMER_IND_3] = cte1.code_desc_txt
    from #TMP_S_PERSON_AMER_INDIAN_RACE prs,
         cte cte1
    where cte1.rn = 3
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_AMER_INDIAN_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_AMER_IND_4] = cte1.code_desc_txt
    from #TMP_S_PERSON_AMER_INDIAN_RACE prs,
         cte cte1
    where cte1.rn = 4
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;

    update #TMP_S_PERSON_AMER_INDIAN_RACE
    set [PATIENT_RACE_AMER_IND_GT3_IND] =
            case
                when [PATIENT_RACE_AMER_IND_4] is not null then 'TRUE'
                when [PATIENT_RACE_AMER_IND_4] is null then 'FALSE'
                end;


    IF OBJECT_ID('#TEMP_AMER_IND_RACE_ALL', 'U') IS NOT NULL
        drop table #TEMP_AMER_IND_RACE_ALL ;


    SELECT distinct patient_uid,
                    STUFF((SELECT distinct ' | ' + code_desc_txt
                           FROM #TMP_S_PERSON_AMER_INDIAN_RACE t1
                           where t1.patient_uid = t2.patient_uid
                           FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '') as PATIENT_RACE_AMER_IND_ALL
    into #TEMP_AMER_IND_RACE_ALL
    from #TMP_S_PERSON_AMER_INDIAN_RACE t2;

    update p
    SET p.PATIENT_RACE_AMER_IND_ALL = SUBSTRING(ps.PATIENT_RACE_AMER_IND_ALL, 2, LEN(ps.PATIENT_RACE_AMER_IND_ALL))
    from #TMP_S_PERSON_AMER_INDIAN_RACE p
             INNER JOIN #TEMP_AMER_IND_RACE_ALL ps
                        on p.PATIENT_UID = ps.PATIENT_UID
--and prs.RACE_CD = cte1.race_cd
    ;


    ALTER TABLE #TMP_S_PERSON_BLACK_RACE
        ADD
            PATIENT_RACE_BLACK_ALL varchar(2000),
            PATIENT_RACE_BLACK_1 varchar(50),
            PATIENT_RACE_BLACK_2 varchar(50),
            PATIENT_RACE_BLACK_3 varchar(50),
            PATIENT_RACE_BLACK_4 varchar(50),
            PATIENT_RACE_BLACK_GT3_IND varchar(10);
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_BLACK_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_BLACK_1] = cte1.code_desc_txt
    from #TMP_S_PERSON_BLACK_RACE prs,
         cte cte1
    where cte1.rn = 1
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_BLACK_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_BLACK_2] = cte1.code_desc_txt
    from #TMP_S_PERSON_BLACK_RACE prs,
         cte cte1
    where cte1.rn = 2
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_BLACK_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_BLACK_3] = cte1.code_desc_txt
    from #TMP_S_PERSON_BLACK_RACE prs,
         cte cte1
    where cte1.rn = 3
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_BLACK_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_BLACK_4] = cte1.code_desc_txt
    from #TMP_S_PERSON_BLACK_RACE prs,
         cte cte1
    where cte1.rn = 4
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;


    update #TMP_S_PERSON_BLACK_RACE
    set [PATIENT_RACE_BLACK_GT3_IND] =
            case
                when [PATIENT_RACE_BLACK_4] is not null then 'TRUE'
                when [PATIENT_RACE_BLACK_4] is null then 'FALSE'
                end;


    IF OBJECT_ID('#TEMP_BLACK_RACE_ALL', 'U') IS NOT NULL
        drop table #TEMP_BLACK_RACE_ALL ;


    SELECT distinct patient_uid,
                    STUFF((SELECT distinct ' | ' + code_desc_txt
                           FROM #TMP_S_PERSON_BLACK_RACE t1
                           where t1.patient_uid = t2.patient_uid
                           FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '') as PATIENT_RACE_BLACK_ALL
    into #TEMP_BLACK_RACE_ALL
    from #TMP_S_PERSON_BLACK_RACE t2

    update p
    SET p.PATIENT_RACE_BLACK_ALL = SUBSTRING(ps.PATIENT_RACE_BLACK_ALL, 2, LEN(ps.PATIENT_RACE_BLACK_ALL))
    from #TMP_S_PERSON_BLACK_RACE p
             INNER JOIN #TEMP_BLACK_RACE_ALL ps
                        on p.PATIENT_UID = ps.PATIENT_UID
--and prs.RACE_CD = cte1.race_cd
    ;


    ALTER TABLE #TMP_S_PERSON_WHITE_RACE
        ADD
            PATIENT_RACE_WHITE_ALL varchar(2000),
            PATIENT_RACE_WHITE_1 varchar(50),
            PATIENT_RACE_WHITE_2 varchar(50),
            PATIENT_RACE_WHITE_3 varchar(50),
            PATIENT_RACE_WHITE_4 varchar(50),
            PATIENT_RACE_WHITE_GT3_IND varchar(10);
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_WHITE_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_WHITE_1] = cte1.code_desc_txt
    from #TMP_S_PERSON_WHITE_RACE prs,
         cte cte1
    where cte1.rn = 1
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_WHITE_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_WHITE_2] = cte1.code_desc_txt
    from #TMP_S_PERSON_WHITE_RACE prs,
         cte cte1
    where cte1.rn = 2
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_WHITE_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_WHITE_3] = cte1.code_desc_txt
    from #TMP_S_PERSON_WHITE_RACE prs,
         cte cte1
    where cte1.rn = 3
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_WHITE_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_WHITE_4] = cte1.code_desc_txt
    from #TMP_S_PERSON_WHITE_RACE prs,
         cte cte1
    where cte1.rn = 4
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;


    update #TMP_S_PERSON_WHITE_RACE
    set [PATIENT_RACE_WHITE_GT3_IND] =
            case
                when [PATIENT_RACE_WHITE_4] is not null then 'TRUE'
                when [PATIENT_RACE_WHITE_4] is null then 'FALSE'
                end;


    IF OBJECT_ID('#TEMP_WHITE_RACE_ALL', 'U') IS NOT NULL
        drop table #TEMP_WHITE_RACE_ALL ;


    SELECT distinct patient_uid,
                    STUFF((SELECT distinct ' | ' + code_desc_txt
                           FROM #TMP_S_PERSON_WHITE_RACE t1
                           where t1.patient_uid = t2.patient_uid
                           FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '') as PATIENT_RACE_WHITE_ALL
    into #TEMP_WHITE_RACE_ALL
    from #TMP_S_PERSON_WHITE_RACE t2;

    update p
    SET p.PATIENT_RACE_WHITE_ALL = SUBSTRING(ps.PATIENT_RACE_WHITE_ALL, 2, LEN(ps.PATIENT_RACE_WHITE_ALL))
    from #TMP_S_PERSON_WHITE_RACE p
             INNER JOIN #TEMP_WHITE_RACE_ALL ps
                        on p.PATIENT_UID = ps.PATIENT_UID
--and prs.RACE_CD = cte1.race_cd
    ;


    ALTER TABLE #TMP_S_PERSON_ASIAN_RACE
        ADD
            PATIENT_RACE_ASIAN_ALL varchar(2000),
            PATIENT_RACE_ASIAN_1 varchar(50),
            PATIENT_RACE_ASIAN_2 varchar(50),
            PATIENT_RACE_ASIAN_3 varchar(50),
            PATIENT_RACE_ASIAN_4 varchar(50),
            PATIENT_RACE_ASIAN_GT3_IND varchar(10);
    ;
    with cte as (select pr.person_uid
                      , prs.race_cd
                      , prs.race_category_cd
                      , prs.[code_desc_txt]
                      , row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_ASIAN_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_ASIAN_1] = cte1.code_desc_txt
    from #TMP_S_PERSON_ASIAN_RACE prs,
         cte cte1
    where cte1.rn = 1
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_ASIAN_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_ASIAN_2] = cte1.code_desc_txt
    from #TMP_S_PERSON_ASIAN_RACE prs,
         cte cte1
    where cte1.rn = 2
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_ASIAN_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_ASIAN_3] = cte1.code_desc_txt
    from #TMP_S_PERSON_ASIAN_RACE prs,
         cte cte1
    where cte1.rn = 3
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_ASIAN_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_ASIAN_4] = cte1.code_desc_txt
    from #TMP_S_PERSON_ASIAN_RACE prs,
         cte cte1
    where cte1.rn = 4
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;


    update #TMP_S_PERSON_ASIAN_RACE
    set [PATIENT_RACE_ASIAN_GT3_IND] =
            case
                when [PATIENT_RACE_ASIAN_4] is not null then 'TRUE'
                when [PATIENT_RACE_ASIAN_4] is null then 'FALSE'
                end;


    IF OBJECT_ID('#TEMP_ASIAN_RACE_ALL', 'U') IS NOT NULL
        drop table #TEMP_ASIAN_RACE_ALL ;


    SELECT distinct patient_uid,
                    STUFF((SELECT distinct ' | ' + code_desc_txt
                           FROM #TMP_S_PERSON_ASIAN_RACE t1
                           where t1.patient_uid = t2.patient_uid
                           FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '') as PATIENT_RACE_ASIAN_ALL
    into #TEMP_ASIAN_RACE_ALL
    from #TMP_S_PERSON_ASIAN_RACE t2

    update p
    SET p.PATIENT_RACE_ASIAN_ALL = SUBSTRING(ps.PATIENT_RACE_ASIAN_ALL, 2, LEN(ps.PATIENT_RACE_ASIAN_ALL))
    from #TMP_S_PERSON_ASIAN_RACE p
             INNER JOIN #TEMP_ASIAN_RACE_ALL ps
                        on p.PATIENT_UID = ps.PATIENT_UID
--and prs.RACE_CD = cte1.race_cd
    ;


    ALTER TABLE #TMP_S_PERSON_HAWAIIAN_RACE
        ADD
            PATIENT_RACE_NAT_HI_ALL varchar(2000),
            PATIENT_RACE_NAT_HI_1 varchar(50),
            PATIENT_RACE_NAT_HI_2 varchar(50),
            PATIENT_RACE_NAT_HI_3 varchar(50),
            PATIENT_RACE_NAT_HI_4 varchar(50),
            PATIENT_RACE_NAT_HI_GT3_IND varchar(10);
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_HAWAIIAN_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_NAT_HI_1] = cte1.code_desc_txt
    from #TMP_S_PERSON_HAWAIIAN_RACE prs,
         cte cte1
    where cte1.rn = 1
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_HAWAIIAN_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_NAT_HI_2] = cte1.code_desc_txt
    from #TMP_S_PERSON_HAWAIIAN_RACE prs,
         cte cte1
    where cte1.rn = 2
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_HAWAIIAN_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_NAT_HI_3] = cte1.code_desc_txt
    from #TMP_S_PERSON_HAWAIIAN_RACE prs,
         cte cte1
    where cte1.rn = 3
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;
    ;
    with cte as (select pr.person_uid,
                        prs.race_cd,
                        prs.race_category_cd,
                        prs.[code_desc_txt],
                        row_number() OVER (PARTITION BY pr.person_uid ORDER BY pr.person_uid) AS rn
                 from #TMP_S_PERSON_HAWAIIAN_RACE prs,
                      NBS_ODSE.dbo.person_race pr with (nolock),
                      [NBS_SRTE].[dbo].[Race_code] rc with (nolock)
                 where prs.PATIENT_UID = PR.person_uid
                   and pr.race_cd = pr.race_category_cd
                   and rc.code = pr.race_category_cd
                 group by pr.person_uid, prs.race_cd, prs.race_category_cd, prs.[code_desc_txt])
    update prs
    set prs.[PATIENT_RACE_NAT_HI_4] = cte1.code_desc_txt
    from #TMP_S_PERSON_HAWAIIAN_RACE prs,
         cte cte1
    where cte1.rn = 4
      and prs.PATIENT_UID = cte1.person_uid
--and prs.RACE_CD = cte1.race_cd
    ;


    update #TMP_S_PERSON_HAWAIIAN_RACE
    set [PATIENT_RACE_NAT_HI_GT3_IND] =
            case
                when [PATIENT_RACE_NAT_HI_4] is not null then 'TRUE'
                when [PATIENT_RACE_NAT_HI_4] is null then 'FALSE'
                end;


    IF OBJECT_ID('#TEMP_HAWAIIAN_RACE_ALL', 'U') IS NOT NULL
        drop table #TEMP_HAWAIIAN_RACE_ALL ;


    SELECT distinct patient_uid,
                    STUFF((SELECT distinct ' | ' + code_desc_txt
                           FROM #TMP_S_PERSON_HAWAIIAN_RACE t1
                           where t1.patient_uid = t2.patient_uid
                           FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '') as PATIENT_RACE_NAT_HI_ALL
    into #TEMP_HAWAIIAN_RACE_ALL
    from #TMP_S_PERSON_HAWAIIAN_RACE t2

    update p
    SET p.PATIENT_RACE_NAT_HI_ALL = SUBSTRING(ps.PATIENT_RACE_NAT_HI_ALL, 2, LEN(ps.PATIENT_RACE_NAT_HI_ALL))
    from #TMP_S_PERSON_HAWAIIAN_RACE p
             INNER JOIN #TEMP_HAWAIIAN_RACE_ALL ps
                        on p.PATIENT_UID = ps.PATIENT_UID
--and prs.RACE_CD = cte1.race_cd
    ;


/*Person Race Out*/
    IF OBJECT_ID('#TMP_S_PERSON_RACE_OUT', 'U') IS NOT NULL
        DROP TABLE #TMP_S_PERSON_RACE_OUT ;


    select distinct patient_race_calculated     as race_calculated
                  , patient_race_calc_details   as race_calc_details
                  , patient_race_all            as race_all
                  , cast(null as varchar(50))   as race_nat_hi_1
                  , cast(null as varchar(50))   as race_nat_hi_2
                  , cast(null as varchar(50))   as race_nat_hi_3
                  , cast(null as varchar(10))   as race_nat_hi_gt3_ind
                  , cast(null as varchar(2000)) as race_nat_hi_all
                  , cast(null as varchar(50))   as race_asian_1
                  , cast(null as varchar(50))   as race_asian_2
                  , cast(null as varchar(2000)) as race_asian_all
                  , cast(null as varchar(50))   as race_asian_3
                  , cast(null as varchar(10))   as race_asian_gt3_ind
                  , cast(null as varchar(50))   as race_amer_ind_1
                  , cast(null as varchar(50))   as race_amer_ind_2
                  , cast(null as varchar(50))   as race_amer_ind_3
                  , cast(null as varchar(10))   as race_amer_ind_gt3_ind
                  , cast(null as varchar(2000)) as race_amer_ind_all
                  , cast(null as varchar(50))   as race_black_1
                  , cast(null as varchar(50))   as race_black_2
                  , cast(null as varchar(50))   as race_black_3
                  , cast(null as varchar(10))   as race_black_gt3_ind
                  , cast(null as varchar(2000)) as race_black_all
                  , cast(null as varchar(50))   as race_white_1
                  , cast(null as varchar(50))   as race_white_2
                  , cast(null as varchar(50))   as race_white_3
                  , cast(null as varchar(10))   as race_white_gt3_ind
                  , cast(null as varchar(2000)) as race_white_all
                  , spr.patient_uid             as patient_uid_race_out
    into #tmp_s_person_race_out
    from #tmp_s_person_root_race spr;


    update spr
    set spr.race_amer_ind_1       = sai.patient_race_amer_ind_1,
        spr.race_amer_ind_2       = sai.patient_race_amer_ind_2,
        spr.race_amer_ind_3       = sai.patient_race_amer_ind_3,
        spr.race_amer_ind_gt3_ind = sai.patient_race_amer_ind_gt3_ind,
        spr.race_amer_ind_all     = rtrim(ltrim(sai.patient_race_amer_ind_all))
    from #tmp_s_person_race_out spr
             join #tmp_s_person_amer_indian_race sai on spr.patient_uid_race_out = sai.patient_uid;


    update spr
    set spr.race_nat_hi_1       = sai.patient_race_nat_hi_1,
        spr.race_nat_hi_2       = sai.patient_race_nat_hi_2,
        spr.race_nat_hi_3       = sai.patient_race_nat_hi_3,
        spr.race_nat_hi_gt3_ind = sai.patient_race_nat_hi_gt3_ind,
        spr.race_nat_hi_all     = rtrim(ltrim(sai.patient_race_nat_hi_all))
    from #tmp_s_person_race_out spr
             join #tmp_s_person_hawaiian_race sai on spr.patient_uid_race_out = sai.patient_uid;


    update spr
    set spr.race_black_1       = sai.patient_race_black_1,
        spr.race_black_2       = sai.patient_race_black_2,
        spr.race_black_3       = sai.patient_race_black_3,
        spr.race_black_gt3_ind = sai.patient_race_black_gt3_ind,
        spr.race_black_all     = rtrim(ltrim(sai.patient_race_black_all))
    from #tmp_s_person_race_out spr
             join #tmp_s_person_black_race sai on spr.patient_uid_race_out = sai.patient_uid;


    update spr
    set spr.race_white_1       = sai.patient_race_white_1,
        spr.race_white_2       = sai.patient_race_white_2,
        spr.race_white_3       = sai.patient_race_white_3,
        spr.race_white_gt3_ind = sai.patient_race_white_gt3_ind,
        spr.race_white_all     = rtrim(ltrim(sai.patient_race_white_all))
    from #tmp_s_person_race_out spr
             join #tmp_s_person_white_race sai on spr.patient_uid_race_out = sai.patient_uid;


    update spr
    set spr.race_asian_1       = sai.patient_race_asian_1,
        spr.race_asian_2       = sai.patient_race_asian_2,
        spr.race_asian_3       = sai.patient_race_asian_3,
        spr.race_asian_gt3_ind = sai.patient_race_asian_gt3_ind,
        spr.race_asian_all     = rtrim(ltrim(sai.patient_race_asian_all))
    from #tmp_s_person_race_out spr
             join #tmp_s_person_asian_race sai on spr.patient_uid_race_out = sai.patient_uid;


    select * from #tmp_s_person_race_out;

END;
