-- ==========================================
-- Program : st122_lkup.4gl
-- Purpose : Stock Lookup (Popup)
-- Module  : Stock Ledger
-- Number  : 121
-- Author  : Bongani Dlamini
-- Version : Genero ver 3.20.10
-- ==========================================
IMPORT FGL utils_globals

SCHEMA demoapp_db

FUNCTION load_lookup() RETURNS STRING
    DEFINE
        arr_st_cat DYNAMIC ARRAY OF RECORD
            cat_code LIKE st02_cat.cat_code,
            description LIKE st02_cat.description,
            status LIKE st02_cat.status
        END RECORD,
        rec_st_cat RECORD
            cat_code LIKE st02_cat.cat_code,
            description LIKE st02_cat.description,
            status LIKE st02_cat.status
        END RECORD,
        ret_code STRING,
        curr_pa, idx SMALLINT

    OPEN WINDOW w_st122_cat_lkup
        WITH
        FORM "st122_cat_lkup"
        ATTRIBUTES(TYPE = POPUP, STYLE = "lookup")

    DECLARE st_cat_curs CURSOR FOR
        SELECT cat_code, description
            FROM st02_cat
            WHERE status = 1
            ORDER BY cat_code

    LET idx = 0
    CALL arr_st_cat.clear()
    FOREACH st_cat_curs INTO rec_st_cat.*
        LET idx = idx + 1
        LET arr_st_cat[idx].* = rec_st_cat.*
    END FOREACH

    LET ret_code = NULL
    IF idx > 0 THEN
        DISPLAY ARRAY arr_st_cat TO rec_st_cat.* ATTRIBUTES(COUNT = idx)
        LET curr_pa = arr_curr()
        LET ret_code = arr_st_cat[curr_pa].cat_code
    END IF

    CLOSE WINDOW w_st122_cat_lkup
    RETURN ret_code
END FUNCTION
