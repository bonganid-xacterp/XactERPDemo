-- ==========================================
-- Program : st121_lkup.4gl
-- Purpose : Stock Lookup (Popup)
-- Module  : Stock Ledger
-- Number  : 121
-- Author  : Bongani Dlamini
-- Version : Genero ver 3.20.10
-- ==========================================

SCHEMA xactdemo_db

FUNCTION display_stocklist() RETURNS STRING
    DEFINE stock_arr DYNAMIC ARRAY OF RECORD
               stock_code     LIKE st01_mast.stock_code,
               description    LIKE st01_mast.description
           END RECORD,
           stock_rec RECORD
               stock_code     LIKE st01_mast.stock_code,
               description    LIKE st01_mast.description
           END RECORD,
           ret_code STRING,
           curr_pa, idx SMALLINT

    OPEN WINDOW w_st121_lkup WITH FORM "st121_lkup" ATTRIBUTES(TYPE = POPUP, STYLE = "lookup")

    DECLARE stock_curs CURSOR FOR
        SELECT stock_code, description
          FROM st01_mast
         WHERE status = 1
         ORDER BY stock_code

    LET idx = 0
    CALL stock_arr.clear()
    FOREACH stock_curs INTO stock_rec.*
        LET idx = idx + 1
        LET stock_arr[idx].* = stock_rec.*
    END FOREACH

    LET ret_code = NULL
    IF idx > 0 THEN
        DISPLAY ARRAY stock_arr TO sa_stock.* ATTRIBUTES(COUNT = idx)
        LET curr_pa = arr_curr()
        LET ret_code = stock_arr[curr_pa].stock_code
    END IF

    CLOSE WINDOW w_st121_lkup
    RETURN ret_code
END FUNCTION
