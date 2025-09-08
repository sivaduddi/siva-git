/**
 * View to retrieve data for Order list service.
 *
 * $Id$
 */

CREATE OR REPLACE FORCE EDITIONABLE VIEW FTNG_ORDER (
    "ACCT",
    "ORDNO",
    "CNTRK",
    "CNTR",
    "STAT",
    "BSIND",
    "OCIND",
    "QTY",
    "LMTT",
    "LMT",
    "CURR",
    "STPL",
    "QTYD",
    "AVGP",
    "EXP",
    "EXPD",
    "COVIND",
    "ORDTYP",
    "OAO",
    "RSTR",
    "LSTC"
)
AS
SELECT
    RTRIM(o.CUSTOMER_DEPOT_NO) AS ACCT,
    o.ORDER_NO AS ORDNO,
    o.CONTRACT_KEY AS CNTRK,
    contract_tool.format_contract_id(TREAT(value(fcd) AS T_CONTRACT)) AS CNTR,
    order_tool.decode_order_status(o.ORDER_STATUS, o.PENDING, o.QUANTITY, o.ORIG_QUANTITY, o.QUANTITY_DONE, wo.IS_LIVE) AS STAT,
    o.DEAL_TYPE AS BSIND,
    eco.OPEN_CLOSE_INDICATOR AS OCIND,
    o.QUANTITY AS QTY,
    eco.LIMIT_ATTR_CODE AS LMTT,
    eco.LIMIT1 AS LMT,
    eco.LIMIT1_CURR AS CURR,
    eco.STOP_LIMIT AS STPL,
    o.QUANTITY_DONE AS QTYD,
    o.AVERAGE_PRICE AS AVGP,
    eco.TRADING_RESTR_CODE AS "EXP",
    TO_CHAR(o.EXPIRY,'YYYY-MM-DD') AS EXPD,
    eco.COVERED_INDICATOR AS COVIND,
    RTRIM(o.ORDER_TYPE) AS ORDTYP,
    RTRIM(wo.COLLECTIVE_ORDER_TYPE) AS OAO,
    eco.EXECUTION_INSTR_CODE AS RSTR,
    o.LAST_CHANGE AS LSTC
FROM      ORDR o
     JOIN WORKING_ORDER wo ON o.BRANCH_ID  = wo.BRANCH_ID
                          AND o.ORDER_NO   = wo.ORDER_NO
                          AND o.VERSION_NO = wo.VERSION_NO
     JOIN EXCHANGE_CUSTOMER_ORDER eco
                           ON o.BRANCH_ID  = eco.BRANCH_ID
                          AND o.ORDER_NO   = eco.ORDER_NO
                          AND o.VERSION_NO = eco.VERSION_NO
     JOIN FO_CONTRACT_DATA fcd ON o.CONTRACT_KEY = fcd.CONTRACT_KEY
WHERE COALESCE(wo.IN_ORDER_OV,'Y') = 'Y'
;
/
SHOW ERRORS
EXIT
