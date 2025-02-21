/*
** -----------------------------------------------------------------------
** The procedure sp_account_insert stores an account into the table ACCOUNTS.
** -----------------------------------------------------------------------
*/

PROMPT ------------------------------------------------------------------;
PROMPT $Id$
PROMPT ------------------------------------------------------------------;


exec registration.register ( -
    registration.procedure_code, -
    upper ('sp_account_insert'), -
    '$Id$');

CREATE OR REPLACE PROCEDURE sp_account_insert
    (p_account            IN OUT  ACCOUNTS%ROWTYPE)
IS
BEGIN
   -- $Id$
    p_account.LAST_CHANGE := 0;

    /*
     * Provide default values.
     */
    p_account.IS_ACTIVE        				:= NVL(p_account.IS_ACTIVE,        'Y');
    p_account.ACCOUNT_DIVISION 		:= NVL(p_account.ACCOUNT_DIVISION, '');
    p_account.DELETE_FLAG     			:= NVL(p_account.DELETE_FLAG,      'N');
    p_account.ATLAS_FLAG      				:= NVL(p_account.ATLAS_FLAG,       'N');

    INSERT INTO ACCOUNTS VALUES p_account;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR (
          error.application_error_no,
          error.format (
            error.insert_failed,
            userobject.get_description (userobject.table_code, 'ACCOUNTS'),
            error.format (
              error.already_exists,
              customer_tool.account_compound_key_get (p_account) )));

END sp_account_insert;
/

SHOW ERRORS

EXIT

