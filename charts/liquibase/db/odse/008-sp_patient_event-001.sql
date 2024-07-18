CREATE OR ALTER PROCEDURE dbo.sp_patient_event @user_id_list nvarchar(max)
AS
BEGIN

    create table #temp_race_table
    (
        race_calculated       varchar(50)   null,
        race_calc_details     varchar(4000) null,
        race_all              varchar(4000) null,
        race_nat_hi_1         varchar(50)   null,
        race_nat_hi_2         varchar(50)   null,
        race_nat_hi_3         varchar(50)   null,
        race_nat_hi_gt3_ind   varchar(50)   null,
        race_nat_hi_all       varchar(2000) null,
        race_asian_1          varchar(50)   null,
        race_asian_2          varchar(50)   null,
        race_asian_3          varchar(50)   null,
        race_asian_gt3_ind    varchar(50)   null,
        race_asian_all        varchar(2000) null,
        race_amer_ind_1       varchar(50)   null,
        race_amer_ind_2       varchar(50)   null,
        race_amer_ind_3       varchar(50)   null,
        race_amer_ind_gt3_ind varchar(50)   null,
        race_amer_ind_all     varchar(2000) null,
        race_black_1          varchar(50)   null,
        race_black_2          varchar(50)   null,
        race_black_3          varchar(50)   null,
        race_black_gt3_ind    varchar(50)   null,
        race_black_all        varchar(2000) null,
        race_white_1          varchar(50)   null,
        race_white_2          varchar(50)   null,
        race_white_3          varchar(50)   null,
        race_white_gt3_ind    varchar(50)   null,
        race_white_all        varchar(2000) null,
        patient_uid_race_out  int           null
    )

    insert into #temp_race_table
    (race_calculated,
     race_calc_details,
     race_all,
     race_nat_hi_1,
     race_nat_hi_2,
     race_nat_hi_3,
     race_nat_hi_gt3_ind,
     race_nat_hi_all,
     race_asian_1,
     race_asian_2,
     race_asian_3,
     race_asian_gt3_ind,
     race_asian_all,
     race_amer_ind_1,
     race_amer_ind_2,
     race_amer_ind_3,
     race_amer_ind_gt3_ind,
     race_amer_ind_all,
     race_black_1,
     race_black_2,
     race_black_3,
     race_black_gt3_ind,
     race_black_all,
     race_white_1,
     race_white_2,
     race_white_3,
     race_white_gt3_ind,
     race_white_all,
     patient_uid_race_out)
        exec nbs_odse.dbo.sp_patient_race_event @user_id_list;


    SELECT p.person_uid,
           p.person_parent_uid,
           p.description,
           p.add_time,
           p.age_reported,
           p.age_reported_unit_cd,
           case
               when (age_reported_unit_cd is not null or age_reported_unit_cd != '') then (select *
                                                                                           from dbo.fn_get_value_by_cd_ques(p.age_reported_unit_cd, 'DEM218'))
               end          as age_reported_unit,
           p.first_nm,
           p.middle_nm,
           p.last_nm,
           p.nm_suffix,
           p.as_of_date_admin,
           p.as_of_date_ethnicity,
           p.as_of_date_general,
           p.as_of_date_morbidity,
           p.as_of_date_sex,
           p.birth_time,
           p.birth_time_calc,
           p.cd,
           p.curr_sex_cd,
           case
               when (p.curr_sex_cd is not null or p.curr_sex_cd != '')
                   then (select * from dbo.fn_get_value_by_cd_ques(p.curr_sex_cd, 'DEM113'))
               end          as current_sex,
           p.deceased_ind_cd,
           case
               when (p.deceased_ind_cd is not null or p.deceased_ind_cd != '') then (select *
                                                                                     from dbo.fn_get_value_by_cd_ques(p.deceased_ind_cd, 'DEM127'))
               end          as deceased_indicator,
           p.electronic_ind,
           p.ethnic_group_ind,
           case
               when (p.ethnic_group_ind is not null or p.ethnic_group_ind != '') then (select *
                                                                                       from dbo.fn_get_value_by_cd_ques(p.ethnic_group_ind, 'DEM155'))
               end          as ethnicity,
           p.birth_gender_cd,
           case
               when (p.birth_gender_cd is not null or p.birth_gender_cd != '') then (select *
                                                                                     from dbo.fn_get_value_by_cd_ques(p.birth_gender_cd, 'DEM114'))
               end          as birth_sex,
           p.deceased_time,
           p.last_chg_time,
           p.marital_status_cd,
           case
               when (p.marital_status_cd is not null or p.marital_status_cd != '') then (select *
                                                                                         from dbo.fn_get_value_by_cd_ques(p.marital_status_cd, 'DEM140'))
               end          as marital_status,
           p.record_status_cd,
           p.record_status_time,
           p.status_cd,
           p.status_time,
           p.local_id,
           p.version_ctrl_nbr,
           p.edx_ind,
           p.dedup_match_ind,
           p.speaks_english_cd,
           case
               when (p.speaks_english_cd is not null or p.speaks_english_cd != '') then (select *
                                                                                         from dbo.fn_get_value_by_cd_ques(p.speaks_english_cd, 'NBS214'))
               end          as speaks_english,
           p.ethnic_unk_reason_cd,
           case
               when (p.ethnic_unk_reason_cd is not null or p.ethnic_unk_reason_cd != '') then (select *
                                                                                               from dbo.fn_get_value_by_cd_ques(p.ethnic_unk_reason_cd, 'NBS273'))
               end          as unk_ethnic_rsn,
           p.sex_unk_reason_cd,
           case
               when (p.sex_unk_reason_cd is not null or p.sex_unk_reason_cd != '') then (select *
                                                                                         from dbo.fn_get_value_by_cd_ques(p.sex_unk_reason_cd, 'NBS272'))
               end          as curr_sex_unk_rsn,
           p.preferred_gender_cd,
           case
               when (p.preferred_gender_cd is not null or p.preferred_gender_cd != '') then (select *
                                                                                             from dbo.fn_get_value_by_cvg(
                                                                                                     p.preferred_gender_cd,
                                                                                                     'NBS_STD_GENDER_PARPT'))
               end          as preferred_gender,
           p.additional_gender_cd,
           p.occupation_cd,
           case
               when (p.occupation_cd is not null or p.occupation_cd != '') then (select *
                                                                                 from dbo.fn_get_value_by_cd_ques(p.occupation_cd, 'DEM139'))
               end          as primary_occupation,
           p.prim_lang_cd,
           case
               when (p.prim_lang_cd is not null or p.prim_lang_cd != '') then (select *
                                                                               from dbo.fn_get_value_by_cd_ques(p.prim_lang_cd, 'DEM142'))
               end          as primary_language,
           p.multiple_birth_ind,
           p.adults_in_house_nbr,
           p.birth_order_nbr,
           p.children_in_house_nbr,
           p.education_level_cd,
           p.add_user_id,
           case
               when p.add_user_id > 0 then (select * from dbo.fn_get_user_name(p.add_user_id))
               end          as add_user_name,
           p.last_chg_user_id,
           case
               when p.last_chg_user_id > 0 then (select * from dbo.fn_get_user_name(p.last_chg_user_id))
               end          as last_chg_user_name,
           nested.name      AS 'patient_name',
           nested.address   AS 'patient_address',
           nested.phone     AS 'patient_telephone',
           nested.email     AS 'patient_email',
           nested.race      AS 'patient_race',
           nested.entity_id AS 'patient_entity'
    FROM nbs_odse.dbo.Person p WITH (NOLOCK)
             OUTER apply (SELECT *
                          FROM
                              -- address
                              (SELECT (SELECT elp.cd                                                                 AS [addr_elp_cd],
                                              elp.use_cd                                                             AS [addr_elp_use_cd],
                                              pl.postal_locator_uid                                                  as [addr_pl_uid],
                                              STRING_ESCAPE(pl.street_addr1, 'json')                                 AS [streetAddr1],
                                              STRING_ESCAPE(pl.street_addr2, 'json')                                 AS [streetAddr2],
                                              STRING_ESCAPE(pl.city_desc_txt, 'json')                                AS [city],
                                              pl.zip_cd                                                              AS [zip],
                                              pl.cnty_cd                                                             AS [cntyCd],
                                              pl.state_cd                                                            AS [state],
                                              pl.cntry_cd                                                            AS [cntryCd],
                                              sc.code_desc_txt                                                       AS [state_desc],
                                              scc.code_desc_txt                                                      AS [county],
                                              pl.within_city_limits_ind,
                                              case
                                                  when elp.use_cd = 'H'
                                                      then coalesce(cc.code_short_desc_txt, pl.cntry_cd)
                                                  else null end                                                      AS [home_country],
                                              case when elp.use_cd = 'BIR' then cc.code_short_desc_txt else null end AS [birth_country]
                                       FROM nbs_odse.dbo.Entity_locator_participation elp WITH (NOLOCK)
                                                LEFT OUTER JOIN nbs_odse.dbo.Postal_locator pl WITH (NOLOCK)
                                                                ON elp.locator_uid = pl.postal_locator_uid
                                                LEFT OUTER JOIN nbs_srte.dbo.State_code sc with (NOLOCK) ON sc.state_cd = pl.state_cd
                                                LEFT OUTER JOIN nbs_srte.dbo.State_county_code_value scc with (NOLOCK)
                                                                ON scc.code = pl.cnty_cd
                                                LEFT OUTER JOIN nbs_srte.dbo.Country_code cc with (nolock) ON cc.code = pl.cntry_cd
                                       WHERE elp.entity_uid = p.person_uid
                                         AND elp.class_cd = 'PST'
                                         AND elp.status_cd = 'A'
                                       FOR json path, INCLUDE_NULL_VALUES) AS address) AS address,
                              -- person phone
                              (SELECT (SELECT tl.tele_locator_uid                                  AS [ph_tl_uid],
                                              elp.cd                                               AS [ph_elp_cd],
                                              elp.use_cd                                           AS [ph_elp_use_cd],
                                              REPLACE(REPLACE(tl.phone_nbr_txt, '-', ''), ' ', '') AS [telephoneNbr],
                                              tl.extension_txt                                     AS [extensionTxt]
                                       FROM nbs_odse.dbo.Entity_locator_participation elp WITH (NOLOCK)
                                                JOIN nbs_odse.dbo.Tele_locator tl WITH (NOLOCK)
                                                     ON elp.locator_uid = tl.tele_locator_uid
                                       WHERE elp.entity_uid = p.person_uid
                                         AND elp.class_cd = 'TELE'
                                         AND elp.status_cd = 'A'
                                         AND tl.phone_nbr_txt IS NOT NULL
                                       FOR json path, INCLUDE_NULL_VALUES) AS phone) AS phone,
                              -- person email
                              (SELECT (SELECT tl.tele_locator_uid                     AS [email_tl_uid],
                                              elp.cd                                  AS [email_elp_cd],
                                              elp.use_cd                              AS [email_elp_use_cd],
                                              STRING_ESCAPE(tl.email_address, 'json') AS [emailAddress]
                                       FROM nbs_odse.dbo.Entity_locator_participation elp WITH (NOLOCK)
                                                JOIN nbs_odse.dbo.Tele_locator tl WITH (NOLOCK)
                                                     ON elp.locator_uid = tl.tele_locator_uid
                                       WHERE elp.entity_uid = p.person_uid
                                         AND elp.cd = 'NET'
                                         AND elp.class_cd = 'TELE'
                                         AND elp.status_cd = 'A'
                                         AND tl.email_address IS NOT NULL
                                       FOR json path, INCLUDE_NULL_VALUES) AS email) AS email,
                              -- person name
                              (SELECT (SELECT pn.person_uid                                        AS [pn_person_uid],
                                              STRING_ESCAPE(REPLACE(pn.last_nm, '-', ' '), 'json') AS [lastNm],
                                              soundex(pn.last_nm)                                  AS [lastNmSndx],
                                              STRING_ESCAPE(pn.middle_nm, 'json')                  AS [middleNm],
                                              STRING_ESCAPE(pn.first_nm, 'json')                   AS [firstNm],
                                              soundex(pn.first_nm)                                 AS [firstNmSndx],
                                              pn.nm_use_cd                                         AS [nm_use_cd],
                                              pn.nm_suffix                                         AS [nmSuffix],
                                              case
                                                  when (pn.nm_suffix is not null or pn.nm_suffix != '')
                                                      then (select * from dbo.fn_get_value_by_cd_ques(pn.nm_suffix, 'DEM107'))
                                                  end                                              as name_suffix,
                                              pn.nm_degree                                         AS [nmDegree],
                                              pn.person_name_seq                                   AS [pn_person_name_seq],
                                              pn.last_chg_time                                     AS [pn_last_chg_time]
                                       FROM nbs_odse.dbo.person_name pn WITH (NOLOCK)
                                       WHERE person_uid = p.person_uid
                                       FOR json path, INCLUDE_NULL_VALUES) AS name) AS name,
                              -- person race
                              (SELECT (SELECT pr.person_uid       AS [pr_person_uid],
                                              pr.race_cd          AS [raceCd],
                                              pr.race_desc_txt    AS [raceDescTxt],
                                              pr.race_category_cd AS [raceCategoryCd],
                                              src.code_desc_txt   AS [srte_code_desc_txt],
                                              src.parent_is_cd    AS [srte_parent_is_cd],
                                              race_calculated,
                                              race_calc_details,
                                              race_amer_ind_1,
                                              race_amer_ind_2,
                                              race_amer_ind_3,
                                              race_amer_ind_gt3_ind,
                                              race_amer_ind_all,
                                              race_asian_1,
                                              race_asian_2,
                                              race_asian_3,
                                              race_asian_gt3_ind,
                                              race_asian_all,
                                              race_black_1,
                                              race_black_2,
                                              race_black_3,
                                              race_black_gt3_ind,
                                              race_black_all,
                                              race_nat_hi_1,
                                              race_nat_hi_2,
                                              race_nat_hi_3,
                                              race_nat_hi_gt3_ind,
                                              race_nat_hi_all,
                                              race_white_1,
                                              race_white_2,
                                              race_white_3,
                                              race_white_gt3_ind,
                                              race_white_all,
                                              race_all
                                       FROM nbs_odse.dbo.person_race pr WITH (NOLOCK)
                                                left outer join nbs_srte.dbo.race_code src ON pr.race_cd = src.code
                                                left outer join #temp_race_table trt on trt.patient_uid_race_out = p.person_uid
                                       WHERE person_uid = p.person_uid
                                       FOR json path, INCLUDE_NULL_VALUES) AS race) AS race,
                              -- Entity id
                              (SELECT (SELECT ei.entity_uid             AS [entity_uid],
                                              ei.type_cd                AS [typeCd],
                                              ei.record_status_cd       AS [recordStatusCd],
                                              STRING_ESCAPE(REPLACE(REPLACE(ei.root_extension_txt, '-', ''), ' ', ''),
                                                            'json')     AS [rootExtensionTxt],
                                              ei.entity_id_seq          AS [entity_id_seq],
                                              ei.assigning_authority_cd AS [assigning_authority_cd]
                                       FROM nbs_odse.dbo.entity_id ei WITH (NOLOCK)
                                       WHERE ei.entity_uid = p.person_uid
                                       FOR json path, INCLUDE_NULL_VALUES) AS entity_id) AS entity_id) AS nested
    WHERE p.person_uid in (SELECT value FROM STRING_SPLIT(@user_id_list, ','))
      AND p.cd = 'PAT'

END;
