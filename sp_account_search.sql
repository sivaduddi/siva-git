/*
 * ----------------------------------------------------------------------------
 * The procedure sp_account_search all corresponding accounts referring
 * to the given search value.
 *
 * The first line of the result set contains the field labels of the returned
 * column data. These labels are extracted out of the table OBJECT_INFO in
 * dependency of the given language code.
 *
 * The value of p_search_value will be searched within a field identified by
 * p_search_field_flag.
 * ----------------------------------------------------------------------
 */

PROMPT ------------------------------------------------------------------;
PROMPT $Id$
PROMPT ------------------------------------------------------------------;
exec registration.register ( -
    registration.procedure_code, -
    upper ('sp_account_search'), -
    '$Id$');


CREATE OR REPLACE PROCEDURE sp_account_search(
    p_search_attribute   IN            VARCHAR2,
    p_search_value      	IN            VARCHAR2,
    p_like              			IN            VARCHAR2,
    p_user_id          		IN            usertype.USER_ID,
    p_lang_code         	IN            usertype.LANG_CODE,
    p_account_data_sep     OUT NOCOPY VARCHAR2,
    p_account_data         	OUT        usertype.REF_CURSOR)
IS
    v_search_value                 	VARCHAR2(255);
    v_search_attribute             	VARCHAR2(255);
    v_where                        		VARCHAR2(1024);
    v_header                       		VARCHAR2(1024);
    v_sql                         			VARCHAR2(4000);
    var_siva               		VARCHAR2(255);
BEGIN
    -- $Id$

    usersession.set_user (p_user_id, p_lang_code);

    /* By escaping enclosed quotes ensure that they won't cause any trouble.
     */
    v_search_value     := UPPER(LTRIM(RTRIM(p_search_value)));
    v_search_attribute := UPPER(p_search_attribute);

    /*
     * For prefix search we can use function based indexes. These
     * are always up to date and do not need maintenance by
     * ctxsrv.
     */
    v_where :=
        CASE v_search_attribute
            WHEN 'ACCOUNT_BRANCH'
            THEN ' customer_tool.split_account_no(CONSTELLATION.ACCOUNT_NO,' || customer_tool.account_branch || ')'

            WHEN 'ACCOUNT_NO'
            THEN ' customer_tool.split_account_no(CONSTELLATION.ACCOUNT_NO,' || customer_tool.account_no || ')'

            WHEN 'ACCOUNT_TYPE'
            THEN ' CONSTELLATION.ACCOUNT_TYPE'

            WHEN 'CUSTOMER_NO'
            THEN ' UPPER(RTRIM(CUSTOMERS.CUSTOMER_NO))'

            WHEN 'CUSTOMER_NAME'
            THEN ' UPPER(RTRIM(CUSTOMERS.NAME_1))'

            WHEN 'CONSTELLATION_NAME'
            THEN ' UPPER(RTRIM(CONSTELLATION.NAME))'
        END;

    /*
     * Check the Search-Method (right, all, left)
     */
    v_where := v_where ||
        CASE p_like
            WHEN 'B' THEN ' LIKE '''  || v_search_value || '%'''
            WHEN 'C' THEN ' LIKE ''%' || v_search_value || '%'''
            WHEN 'E' THEN ' LIKE ''%' || v_search_value || ''''
        END;

    /*
     * now, for all different cases build the sql statement
     */
    v_sql :=    'SELECT RTRIM(CUSTOMERS.CUSTOMER_NO)||''-''||RTRIM(CONSTELLATION.CONSTELLATION_ID),CUSTOMERS.NAME_1,'
             ||        'CONSTELLATION.NAME,'
             ||        'customer_tool.split_account_no(ACCOUNTS.ACCOUNT_NO,' || customer_tool.account_branch || ') AS VNDL,'
             ||        'customer_tool.split_account_no(ACCOUNTS.ACCOUNT_NO,' || customer_tool.account_no || ') AS ACCOUNT_NO,'
             ||        'ACCOUNTS.ACCOUNT_TYPE,'
             ||        'customer_tool.split_account_no(CASH_ACCOUNTS.CASH_ACCOUNT_NO,' || customer_tool.account_branch || '),'
             ||        'customer_tool.split_account_no(CASH_ACCOUNTS.CASH_ACCOUNT_NO,' || customer_tool.account_no || '),'
             ||        'CASH_ACCOUNTS.CACC_CURR,order_tool.get_trading_place_description(CONSTELLATION.TRADING_PLACE),CONSTELLATION.IS_DEFAULT,'
             ||        'CUSTOMERS.CUSTOMER_NO AS CUSTOMER_NO2,CONSTELLATION.CONSTELLATION_ID AS CONSTELLATION_ID2,'
             ||        'customer_tool.split_account_no(ACCOUNTS.ACCOUNT_NO,' || customer_tool.account_branch || ') AS VNDL2,'
             ||        'customer_tool.split_account_no(ACCOUNTS.ACCOUNT_NO,' || customer_tool.account_no || ')  AS ACCOUNT_NO2 '
             || 'FROM             CUSTOMERS '
             ||        'JOIN      CONSTELLATION '
             ||        'ON   (CUSTOMERS.CUSTOMER_NO = CONSTELLATION.CUSTOMER_NO) '
             ||        'LEFT JOIN ACCOUNTS '
             ||        'ON   (    CONSTELLATION.ACCOUNT_NO   = ACCOUNTS.ACCOUNT_NO '
             ||        '      AND CONSTELLATION.ACCOUNT_TYPE = ACCOUNTS.ACCOUNT_TYPE) '
             ||        'LEFT JOIN CASH_ACCOUNTS '
             ||        'ON   (    CONSTELLATION.CASH_ACCOUNT_NO = CASH_ACCOUNTS.CASH_ACCOUNT_NO '
             ||        '      AND CONSTELLATION.CACC_CURR       = CASH_ACCOUNTS.CACC_CURR), '
             ||        '(SELECT * FROM TABLE(CAST(sp_permitted_teams_get(:user_id) AS T_EXT_TEAM_ACCESS_TABLE))) EXT_TEAM ';

    --
    -- Check for active records and check team permissions.
    --
    v_sql :=    v_sql
             || 'WHERE ' || v_where 
             ||  ' AND CUSTOMERS.IS_ACTIVE = ''Y'''
             ||  ' AND CONSTELLATION.IS_ACTIVE = ''Y'''
             ||  ' AND NVL(ACCOUNTS.IS_ACTIVE, ''Y'') = ''Y'''
             -- Team access cannot be checked by join condition because
             -- there are two levels to be checked:
             -- 1) CONSTELLATION.TEAM_NAME IS NOT NULL -> Must be in EXT_TEAM
             -- 2) CONSTELLATION.TEAM_NAME IS NULL -> CUSTOMERS.TEAM_NAME must match.
             -- [#250209722]
             ||  ' AND (   CONSTELLATION.TEAM_NAME = EXT_TEAM.COLUMN_VALUE '
             ||  '      OR (    CONSTELLATION.TEAM_NAME IS NULL '
             ||  '          AND CUSTOMERS.TEAM_NAME = EXT_TEAM.COLUMN_VALUE))';

    /* header for client output
     */
    v_header := 'SELECT '|| '''' || userobject.get_description(userobject.column_code,'CUSTOMER_NO')    || ''' ,'
                         || '''' || userobject.get_description(userobject.column_code,'NAME_1')         || ''' ,'
                         || '''' || userobject.get_description(userobject.column_code,'CONSTELLATION')  || ''' ,'
                         || '''' || userobject.get_description(userobject.column_code,'VNDL')           || ''' ,'
                         || '''' || userobject.get_description(userobject.column_code,'ACCOUNT_NO')     || ''' ,'
                         || '''' || userobject.get_description(userobject.column_code,'ACCOUNT_TYPE')   || ''' ,'
                         || '''' || userobject.get_description(userobject.column_code,'VNDL')           || ''' ,'
                         || '''' || userobject.get_description(userobject.column_code,'CASH_ACCOUNT_NO')|| ''' ,'
                         || '''' || userobject.get_description(userobject.column_code,'CACC_CURR')      || ''' ,'
                         || '''' || userobject.get_description(userobject.column_code,'TRADING_PLACE')  || ''' ,'
                         || '''' || userobject.get_description(userobject.column_code,'IS_DEFAULT')     || ''' ,'
                         || ' NULL AS CUSTOMER_NO2, NULL AS CONSTELLATION_ID2, NULL AS VNDL2, NULL AS ACCOUNT_NO2 FROM DUAL';

    v_sql := v_header || ' UNION ALL SELECT * FROM (' || v_sql;
    v_sql := v_sql || ' ORDER BY 1)';

    /*
     * Return result
     */
    p_account_data_sep := '## ACCOUNTS ##';
    OPEN  p_account_data
    FOR   v_sql
    USING
        p_user_id;

EXCEPTION
    WHEN OTHERS
    THEN
        error.log_message('sp_account_search', v_sql || ': ' || SQLERRM, error.severity_error);

        RAISE_APPLICATION_ERROR (
            error.application_error_no,
            error.format (
                 error.search_error,
                 userobject.get_description (userobject.table_code, 'ACCOUNTS'),
                 v_search_value));
END sp_account_search;
/

SHOW ERRORS
EXIT
