CREATE OR ALTER PROCEDURE dbo.sp_provider_event @user_id_list nvarchar(max)
AS
BEGIN
    SELECT p.person_uid,
           p.person_parent_uid,
           p.description,
           p.add_time,
           p.first_nm,
           p.middle_nm,
           p.last_nm,
           p.nm_suffix,
           p.cd,
           p.electronic_ind,
           p.last_chg_time,
           p.record_status_cd,
           p.record_status_time,
           p.status_cd,
           p.status_time,
           p.local_id,
           p.version_ctrl_nbr,
           p.edx_ind,
           p.dedup_match_ind,
           p.add_user_id,
           case
               when p.add_user_id > 0 then (select * from dbo.fn_get_user_name(p.add_user_id))
               end          as add_user_name,
           p.last_chg_user_id,
           case
               when p.last_chg_user_id > 0 then (select * from dbo.fn_get_user_name(p.last_chg_user_id))
               end          as last_chg_user_name,
           nested.name      AS 'provider_name',
           nested.address   AS 'provider_address',
           nested.phone     AS 'provider_telephone',
           nested.email     AS 'provider_email',
           nested.entity_id AS 'provider_entity'
    FROM nbs_odse.dbo.Person p WITH (NOLOCK)
             OUTER apply (SELECT *
                          FROM
                              -- address
                              (SELECT (SELECT elp.cd                AS                [addr_elp_cd],
                                              elp.use_cd            AS                [addr_elp_use_cd],
                                              pl.postal_locator_uid as                [addr_pl_uid],
                                              STRING_ESCAPE(pl.street_addr1, 'json')  streetAddr1,
                                              STRING_ESCAPE(pl.street_addr2, 'json')  streetAddr2,
                                              STRING_ESCAPE(pl.city_desc_txt, 'json') city,
                                              pl.zip_cd                               zip,
                                              pl.cnty_cd                              cntyCd,
                                              pl.state_cd                             state,
                                              pl.cntry_cd                             cntryCd,
                                              sc.code_desc_txt                        state_desc,
                                              scc.code_desc_txt                       county,
                                              pl.within_city_limits_ind               within_city_limits_ind,
                                              cc.code_short_desc_txt                  country,
                                              elp.locator_desc_txt                    address_comments
                                       FROM nbs_odse.dbo.Entity_locator_participation elp WITH (NOLOCK)
                                                LEFT OUTER JOIN nbs_odse.dbo.Postal_locator pl WITH (NOLOCK)
                                                                ON elp.locator_uid = pl.postal_locator_uid
                                                LEFT OUTER JOIN nbs_srte.dbo.State_code sc with (NOLOCK) ON sc.state_cd = pl.state_cd
                                                LEFT OUTER JOIN nbs_srte.dbo.State_county_code_value scc with (NOLOCK)
                                                                ON scc.code = pl.cnty_cd
                                                LEFT OUTER JOIN nbs_srte.dbo.Country_code cc with (nolock) ON cc.CODE = pl.cntry_cd
                                       WHERE elp.entity_uid = p.person_uid
                                         AND elp.class_cd = 'PST'
                                         AND elp.status_cd = 'A'
                                       FOR json path, INCLUDE_NULL_VALUES) AS address) AS address,
                              -- person phone
                              (SELECT (SELECT tl.tele_locator_uid AS                               [ph_tl_uid],
                                              elp.cd              AS                               [ph_elp_cd],
                                              elp.use_cd          AS                               [ph_elp_use_cd],
                                              REPLACE(REPLACE(tl.phone_nbr_txt, '-', ''), ' ', '') telephoneNbr,
                                              tl.extension_txt                                     extensionTxt,
                                              elp.locator_desc_txt                                 phone_comments
                                       FROM nbs_odse.dbo.Entity_locator_participation elp WITH (NOLOCK)
                                                JOIN nbs_odse.dbo.Tele_locator tl WITH (NOLOCK)
                                                     ON elp.locator_uid = tl.tele_locator_uid
                                       WHERE elp.entity_uid = p.person_uid
                                         AND elp.class_cd = 'TELE'
                                         AND elp.status_cd = 'A'
                                         AND tl.phone_nbr_txt IS NOT NULL
                                       FOR json path, INCLUDE_NULL_VALUES) AS phone) AS phone,
                              -- person email
                              (SELECT (SELECT tl.tele_locator_uid AS                  [email_tl_uid],
                                              elp.cd              AS                  [email_elp_cd],
                                              elp.use_cd          AS                  [email_elp_use_cd],
                                              STRING_ESCAPE(tl.email_address, 'json') emailAddress
                                       FROM nbs_odse.dbo.Entity_locator_participation elp WITH (NOLOCK)
                                                JOIN nbs_odse.dbo.Tele_locator tl WITH (NOLOCK)
                                                     ON elp.locator_uid = tl.tele_locator_uid
                                       WHERE elp.entity_uid = p.person_uid
                                         AND elp.class_cd = 'TELE'
                                         AND elp.status_cd = 'A'
                                         AND tl.email_address IS NOT NULL
                                       FOR json path, INCLUDE_NULL_VALUES) AS email) AS email,
                              -- person names
                              (SELECT (SELECT pn.person_uid      AS                                [pn_person_uid],
                                              STRING_ESCAPE(REPLACE(pn.last_nm, '-', ' '), 'json') lastNm,
                                              soundex(pn.last_nm)                                  lastNmSndx,
                                              STRING_ESCAPE(pn.middle_nm, 'json')                  middleNm,
                                              STRING_ESCAPE(pn.first_nm, 'json')                   firstNm,
                                              soundex(pn.first_nm)                                 firstNmSndx,
                                              pn.nm_use_cd,
                                              --Target length check
                                              pn.nm_suffix                                         nmSuffix,
                                              case
                                                  when (pn.nm_suffix is not null or pn.nm_suffix != '')
                                                      then (select * from dbo.fn_get_value_by_cd_ques(pn.nm_suffix, 'DEM107'))
                                                  end            as                                name_suffix,
                                              pn.nm_prefix                                         nmPrefix,
                                              case
                                                  when (pn.nm_prefix is not null or pn.nm_prefix != '')
                                                      then (select * from dbo.fn_get_value_by_cd_ques(pn.nm_prefix, 'DEM101'))
                                                  end            as                                name_prefix,
                                              pn.nm_degree                                         nmDegree,
                                              pn.person_name_seq AS                                [pn_person_name_seq],
                                              pn.last_chg_time   AS                                [pn_last_chg_time]
                                       FROM nbs_odse.dbo.person_name pn WITH (NOLOCK)
                                       WHERE person_uid = p.person_uid
                                       FOR json path, INCLUDE_NULL_VALUES) AS name) AS name,
                              -- Entity id
                              (SELECT (SELECT ei.entity_uid,
                                              ei.type_cd          typeCd,
                                              ei.record_status_cd recordStatusCd,
                                              STRING_ESCAPE(
                                                      REPLACE(REPLACE(ei.root_extension_txt, '-', ''), ' ', ''),
                                                      'json')     rootExtensionTxt,
                                              ei.entity_id_seq,
                                              ei.assigning_authority_cd
                                       FROM nbs_odse.dbo.entity_id ei WITH (NOLOCK)
                                       WHERE ei.entity_uid = p.person_uid
                                       FOR json path, INCLUDE_NULL_VALUES) AS entity_id) AS entity_id) AS nested
    WHERE p.person_uid in (SELECT value FROM STRING_SPLIT(@user_id_list, ','))
      AND p.cd = 'PRV';

END;