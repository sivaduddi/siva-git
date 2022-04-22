
** -----------------------------------------------------------------------
*/
-- ----------------------------------------------------------------------
-- $Log$
-- Revision 1.3  2002/02/13 16:19:01  mu
-- - replaced userobject.register by registration.register
--
-- Revision 1.2  2000/08/28 13:29:02  mu
-- 	added call of registration.register
--
-- Revision 1.1  2000/03/01 07:51:59  fjh
--     Initial version
--
-- ----------------------------------------------------------------------

PROMPT ------------------------------------------------------------------;
PROMPT $Id$
PROMPT ------------------------------------------------------------------;


exec registration.register ( -
    registration.function_code, -
    upper ('sp_account_exists'), -
    '$Id$');

CREATE OR REPLACE FUNCTION sp_account_exists
    (p_account_no         IN       usertype.ACCOUNT_NO,
     p_account_type       IN       usertype.ACCOUNT_TYPE,
     p_check_active       IN       usertype.YESNO := 'N')
RETURN BOOLEAN
IS
    v_exists    NUMBER;
BEGIN
    IF p_check_active = 'Y' THEN
    BEGIN
        SELECT 1
        INTO v_exists
        FROM ACCOUNTS a
        WHERE a.ACCOUNT_NO   = p_account_no
          AND a.ACCOUNT_TYPE = NVL(p_account_type, a.ACCOUNT_TYPE)
          AND a.IS_ACTIVE    = p_check_active;

        RETURN TRUE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
    END;
    ELSE
    BEGIN
        SELECT 1
        INTO v_exists
        FROM ACCOUNTS a
        WHERE a.ACCOUNT_NO   = p_account_no
          AND a.ACCOUNT_TYPE = NVL(p_account_type, a.ACCOUNT_TYPE);

        RETURN TRUE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
    END;
    END IF;

END sp_account_exists;
/

SHOW ERRORS

EXIT





