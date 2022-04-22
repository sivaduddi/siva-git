/*
** ----------------------------------------------------------------------------
** The procedure performs an efficient search on certain customer and account
** attributes. 
**
** The procedure returns a PL/SQL table containing the key of
** all matching records.
*/

PROMPT ------------------------------------------------------------------;
PROMPT $Id$;
PROMPT ------------------------------------------------------------------;

exec registration.register ( -
    registration.procedure_code, -
    upper ('sp_account_search_base'), -
    '$Id$');

/*
 * Create search table to store temporary result.
 */
DROP TABLE ACCOUNT_SEARCH_RID_TMP
/

CREATE GLOBAL TEMPORARY TABLE ACCOUNT_SEARCH_RID_TMP
(
    SESSIONID    VARCHAR2(256) NULL,
    RID          ROWID         NULL,
    ACCOUNT_NO   VARCHAR2(19)  NULL,     -- PK (ACCOUNTS)
    ACCOUNT_TYPE VARCHAR2(1)   NULL,     -- PK (ACCOUNTS)
    CUSTOMER_NO  VARCHAR2(12)  NULL      -- PK (CUSTOMERS)
)
ON COMMIT DELETE ROWS
/
SHOW ERRORS

CREATE OR REPLACE PROCEDURE sp_account_search_base(
    p_search_attribute             VARCHAR2,
    p_search_value                 VARCHAR2,
    p_like                         VARCHAR2)
IS
    v_sql                          VARCHAR2(4000);
    v_where                        VARCHAR2(1024);
    v_from                         VARCHAR2(1024);
    v_search_value                 VARCHAR2( 100);
    v_search_attribute             VARCHAR2( 255);
    v_session_id                   VARCHAR2( 256);
    v_user_id                      usertype.USER_ID;

    /* Concat a 'from-clause' table list. v_from2 is appended to v_from1.
     * v_from2 must not be NULL, v_from1 may be NULL. The result is returned
     * as v_from3.
     */
    PROCEDURE concat_from(v_from1 VARCHAR2, v_from2 VARCHAR2, v_from3 OUT VARCHAR2)
    IS
    BEGIN
        IF (v_from1 IS NULL)
        THEN v_from3 := v_from2 || ' ';
        ELSE v_from3 := v_from1 || ', ' || v_from2 || ' ';
        END IF;
    END concat_from;

BEGIN
    -- $Id$

    v_session_id := SYS_CONTEXT('USERENV', 'SESSIONID');
    v_user_id    := usersession.get_user;

    /* By escaping enclosed quotes ensure that they won't cause any
       trouble.
    */
    v_search_value     := UPPER(RTRIM(REPLACE(p_search_value, '''', '''''')));
    v_search_attribute := UPPER(p_search_attribute);

    v_from := ' CUSTOMERS '
             ||        'LEFT JOIN CONSTELLATION '
             ||        'ON   (CUSTOMERS.CUSTOMER_NO = CONSTELLATION.CUSTOMER_NO) '
             ||        'LEFT JOIN ACCOUNTS '
             ||        'ON   (    CONSTELLATION.ACCOUNT_NO   = ACCOUNTS.ACCOUNT_NO '
             ||        '      AND CONSTELLATION.ACCOUNT_TYPE = ACCOUNTS.ACCOUNT_TYPE) '
             ||        'LEFT JOIN CASH_ACCOUNTS '
             ||        'ON   (    CONSTELLATION.CASH_ACCOUNT_NO = CASH_ACCOUNTS.CASH_ACCOUNT_NO '
             ||        '      AND CONSTELLATION.CACC_CURR       = CASH_ACCOUNTS.CACC_CURR), '
             ||        '(SELECT * FROM TABLE(CAST(sp_permitted_teams_get(''' || RTRIM (v_user_id) || ''') AS T_EXT_TEAM_ACCESS_TABLE))) EXT_TEAM ';

    v_where := ' ' ||
        CASE v_search_attribute
            --WHEN 'ACCOUNT_BRANCH'
            --THEN 'customer_tool.split_account_no(CONSTELLATION.ACCOUNT_NO,' || customer_tool.account_branch || ')'

            WHEN 'ACCOUNT_NO'
            THEN 'CONSTELLATION.ACCOUNT_NO'

            WHEN 'CONSTELLATION_ID'
            THEN 'UPPER(RTRIM(CONSTELLATION.CONSTELLATION_ID))'

            WHEN 'CONSTELLATION_NAME'
            THEN 'UPPER(RTRIM(CONSTELLATION.NAME))'

            WHEN 'CUSTOMER_NO'
            THEN 'UPPER(RTRIM(CUSTOMERS.CUSTOMER_NO))'

            WHEN 'CUSTOMER_NAME'
            THEN 'UPPER(RTRIM(CUSTOMERS.NAME_1))'
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

    --
    -- Check for active records and check team permissions.
    --
    v_where :=    v_where
             ||  ' AND CUSTOMERS.IS_ACTIVE = ''Y'''
             ||  ' AND NVL(CONSTELLATION.IS_ACTIVE, ''Y'') = ''Y'''
             ||  ' AND NVL(ACCOUNTS.IS_ACTIVE, ''Y'') = ''Y'''
             -- Team access cannot be checked by join condition because
             -- there are two levels to be checked:
             -- 1) CONSTELLATION.TEAM_NAME IS NOT NULL -> Must be in EXT_TEAM
             -- 2) CONSTELLATION.TEAM_NAME IS NULL -> CUSTOMERS.TEAM_NAME must match.
             -- [#250209722]
             ||  ' AND (   CONSTELLATION.TEAM_NAME = EXT_TEAM.COLUMN_VALUE '
             ||  '      OR (    CONSTELLATION.TEAM_NAME IS NULL '
             ||  '          AND CUSTOMERS.TEAM_NAME = EXT_TEAM.COLUMN_VALUE))';

    v_sql := 'INSERT INTO ACCOUNT_SEARCH_RID_TMP '
        || 'SELECT DISTINCT '
        ||         v_session_id || ', '
        ||        'ACCOUNTS.ROWID, CONSTELLATION.ACCOUNT_NO, CONSTELLATION.ACCOUNT_TYPE, CONSTELLATION.CUSTOMER_NO '
        || ' FROM ' || v_from
        || 'WHERE ' || v_where
        || 'ORDER BY 1';

    -- error.log_message ('sp_account_search_base', v_sql, error.severity_info);

    /*
    ** Copy result set into in-memory table.
    */
    EXECUTE IMMEDIATE v_sql;
END sp_account_search_base;
/

SHOW ERRORS
EXIT
