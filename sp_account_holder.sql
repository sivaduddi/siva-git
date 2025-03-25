/*
 * The procedure returns the account holder for a given customer no., constellation id
 * and account number.
 * What sounds easy for a standard OROM is much more complicated for some systems.
 * Thus, the function first checks if feature HOOK_ACCOUNT_HOLDER is defined.
 * If so work is delegated to this feature. Otherwise account holder is returned
 * as
 *    Prio 1) Constellation Name of matching constellation
 *    Prio 2) Of no such constellation exists Customer name is returned as
 *            customer_tool."concat"(c.NAME_1, c.NAME_2)
 */

PROMPT ------------------------------------------------------------------;
PROMPT $Id$
PROMPT ------------------------------------------------------------------;

exec registration.register ( -
    registration.function_code, -
    'sp_account_holder', -
    '$Id$');


CREATE OR REPLACE FUNCTION sp_account_holder(
    p_customer_no      	 IN     ORDR.CUSTOMER_NO%TYPE,
    p_constellation_id	 IN     ORDR.CONSTELLATION_ID%TYPE,
    p_account_no      	 IN     ORDR.CUSTOMER_DEPOT_NO%TYPE,
    p_account_type     	 IN     ORDR.CUSTOMER_DEPOT_NO%TYPE 
    p_location_id        IN     ORDR.LOCATION_ID%TYPE DEFAULT NULL
)
RETURN VARCHAR2 RESULT_CACHE DETERMINISTIC
IS
    c                usertype.REF_CURSOR;
    v_account_holder VARCHAR2(255);
BEGIN
    -- $Id$

    IF feature_tool.has_feature('HOOK_ACCOUNT_HOLDER')
    THEN
        DECLARE
            v_feature_data T_FEATURE_DATA := NEW T_FEATURE_DATA(0);
            i              INTEGER;
        BEGIN
            v_feature_data.vc2_table := T_VARCHAR2_TABLE(
                                            p_customer_no,
                                            p_constellation_id,
                                            p_account_no,
                                            p_account_type
                                         );

            i := feature_tool.execute_feature('HOOK_ACCOUNT_HOLDER', v_feature_data);
            v_account_holder := v_feature_data."S";
        END;

    ELSE
        v_account_holder := customer_tool.get_account_holder(
                                p_customer_no      => p_customer_no,
                                p_constellation_id => p_constellation_id,
                                p_account_no       => p_account_no,
                                p_account_type     => p_account_type);
    END IF;

    RETURN v_account_holder;
END sp_account_holder;
/

SHOW ERRORS
EXIT
