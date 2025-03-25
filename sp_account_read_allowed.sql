/*
** -----------------------------------------------------------------------
** The procedure sp_account_read_allowed checks the access rights
** for reading to an account
** -----------------------------------------------------------------------
*/

PROMPT ------------------------------------------------------------------;
PROMPT $Id$
PROMPT ------------------------------------------------------------------;


exec registration.register ( -
    registration.function_code, -
    upper ('sp_account_read_allowed'), -
    '$Id$');

CREATE OR REPLACE FUNCTION sp_account_read_allowed
    (p_user_id            		IN       usertype.USER_ID,
     p_account_no         	IN       usertype.ACCOUNT_NO,
     p_account_type       	IN       usertype.ACCOUNT_TYPE)
     p_name                IN       VARCHAR2 DEFAULT NULL)
RETURN BOOLEAN
IS
    v_allowed    NUMBER;
BEGIN
    -- $Id$

    /*
     * No restrictions apply for HVB BEST.
     */
    RETURN TRUE;
END sp_account_read_allowed;
/

SHOW ERRORS
EXIT
