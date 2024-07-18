CREATE OR ALTER PROCEDURE dbo.sp_organization_event @org_id_list nvarchar(max)
AS
BEGIN
    SELECT o.organization_uid,
           o.description,
           o.cd,
           o.electronic_ind,
           o.record_status_cd,
           o.record_status_time,
           o.status_cd,
           o.status_time,
           o.local_id,
           o.version_ctrl_nbr,
           o.edx_ind,
           naics.code_short_desc_txt as 'stand_ind_class',
           o.add_user_id,
           case
               when o.add_user_id > 0 then (select * from dbo.fn_get_user_name(o.add_user_id))
               end                   as add_user_name,
           o.last_chg_user_id,
           case
               when o.last_chg_user_id > 0 then (select * from dbo.fn_get_user_name(o.last_chg_user_id))
               end                   as last_chg_user_name,
           o.add_time,
           o.last_chg_time,
           nested.name               AS 'organization_name',
           nested.address            AS 'organization_address',
           nested.phone              AS 'organization_telephone',
           nested.fax                AS 'organization_fax',
           nested.entity_id          AS 'organization_entity_id'
    FROM NBS_ODSE.dbo.Organization o WITH (NOLOCK)
             OUTER apply (SELECT *
                          FROM
                              -- address
                              (SELECT (SELECT elp.cd                 AS               [addr_elp_cd],
                                              elp.use_cd             AS               [addr_elp_use_cd],
                                              pl.postal_locator_uid  AS               [addr_pl_uid],
                                              STRING_ESCAPE(pl.street_addr1, 'json')  street_addr1,
                                              STRING_ESCAPE(pl.street_addr2, 'json')  street_addr2,
                                              STRING_ESCAPE(pl.city_desc_txt, 'json') city,
                                              pl.zip_cd                               zip,
                                              pl.cnty_cd                              cnty_cd,
                                              pl.state_cd                             state,
                                              pl.cntry_cd                             cntry_cd,
                                              sc.code_desc_txt                        state_desc,
                                              scc.code_desc_txt                       county,
                                              pl.within_city_limits_ind               within_city_limits_ind,
                                              cc.code_short_desc_txt AS               [country],
                                              elp.locator_desc_txt   AS               [address_comments],
                                              ccv.code_desc_txt      as               [county_desc]
                                       FROM entity_locator_participation elp with (nolock)
                                                left outer join postal_locator pl with (nolock)
                                                                on elp.locator_uid = pl.postal_locator_uid
                                                left outer join nbs_srte.dbo.state_code sc with (nolock) on sc.state_cd = pl.state_cd
                                                left outer join nbs_srte.dbo.state_county_code_value scc with (nolock)
                                                                on scc.code = pl.cnty_cd
                                                left outer join nbs_srte.dbo.country_code cc with (nolock) on cc.code = pl.cntry_cd
                                                left outer join nbs_srte.dbo.state_county_code_value ccv with (nolock)
                                                                on ccv.code = pl.cnty_cd
                                       WHERE elp.entity_uid = o.organization_uid
                                         AND elp.class_cd = 'PST'
                                         AND elp.use_cd = 'WP'
                                         AND elp.cd = 'O'
                                       FOR json path, INCLUDE_NULL_VALUES) AS address) AS address,
                              -- org name
                              (SELECT (SELECT on2.organization_uid                       AS [on_org_uid],
                                              LTRIM(RTRIM(SUBSTRING(on2.nm_txt, 1, 50))) AS [organization_name]
                                       FROM NBS_ODSE.dbo.Organization_name on2
                                       WHERE o.organization_uid = on2.organization_uid
                                       FOR json path, INCLUDE_NULL_VALUES) AS name) AS name,
                              -- org phone
                              (SELECT (SELECT tl.tele_locator_uid  AS                              [ph_tl_uid],
                                              elp.cd               AS                              [ph_elp_cd],
                                              elp.use_cd           AS                              [ph_elp_use_cd],
                                              REPLACE(REPLACE(tl.phone_nbr_txt, '-', ''), ' ', '') telephone_nbr,
                                              tl.extension_txt                                     extension_txt,
                                              STRING_ESCAPE(tl.email_address, 'json')              email_address,
                                              elp.locator_desc_txt as                              [phone_comments]
                                       FROM Entity_locator_participation elp WITH (NOLOCK)
                                                JOIN Tele_locator tl WITH (NOLOCK) ON elp.locator_uid = tl.tele_locator_uid
                                       WHERE elp.entity_uid = o.organization_uid
                                         AND elp.class_cd = 'TELE'
                                         AND elp.use_cd = 'WP'
                                         AND elp.cd = 'PH'
                                       FOR json path, INCLUDE_NULL_VALUES) AS phone) AS phone,
                              -- org fax
                              (SELECT (SELECT tl.tele_locator_uid                              AS [fax_tl_uid],
                                              elp.cd                                           AS [fax_elp_cd],
                                              elp.use_cd                                       AS [fax_elp_use_cd],
                                              LTRIM(RTRIM(SUBSTRING(tl.phone_nbr_txt, 1, 20))) as [org_fax]
                                       FROM Entity_locator_participation elp WITH (NOLOCK)
                                                JOIN Tele_locator tl WITH (NOLOCK) ON elp.locator_uid = tl.tele_locator_uid
                                       WHERE elp.entity_uid = o.organization_uid
                                         AND elp.class_cd = 'TELE'
                                         AND elp.use_cd = 'WP'
                                         AND elp.cd = 'FAX'
                                       FOR json path, INCLUDE_NULL_VALUES) AS fax) AS fax,
                              -- Entity id
                              (SELECT (SELECT ei.entity_uid,
                                              ei.type_cd          AS [type_cd],
                                              ei.record_status_cd AS [record_status_cd],
                                              STRING_ESCAPE(
                                                      REPLACE(REPLACE(ei.root_extension_txt, '-', ''), ' ', ''),
                                                      'json')     AS [root_extension_txt],
                                              ei.entity_id_seq,
                                              ei.assigning_authority_cd,
                                              case
                                                  when (ei.type_cd = 'FI' and ei.assigning_authority_cd is not null)
                                                      then (select *
                                                            from dbo.fn_get_value_by_cvg(ei.assigning_authority_cd, 'EI_AUTH_ORG'))
                                                  end             as facility_id_auth
                                       FROM entity_id ei WITH (NOLOCK)
                                       WHERE ei.entity_uid = o.organization_uid
                                       FOR json path, INCLUDE_NULL_VALUES) AS entity_id) AS entity_id) AS nested
             LEFT JOIN nbs_srte.dbo.NAICS_INDUSTRY_CODE naics ON (NAICS.CODE = o.STANDARD_INDUSTRY_CLASS_CD)
    WHERE o.organization_uid in (SELECT value FROM STRING_SPLIT(@org_id_list, ','))
END;