-- ==========================================
-- Program : st122_lkup.4gl
-- Purpose : Stock Lookup (Popup)
-- Module  : Stock Ledger
-- Number  : 121
-- Author  : Bongani Dlamini
-- Version : Genero ver 3.20.10
-- ==========================================
IMPORT FGL utils_globals

SCHEMA demoappdb

FUNCTION load_lookup() RETURNS STRING
    DEFINE arr_st_cat DYNAMIC ARRAY OF RECORD
            id     LIKE st02_cat.id,
            description  LIKE st02_cat.description,
            status       LIKE st02_cat.status
        END RECORD,
        rec_list RECORD
            id     LIKE st02_cat.id,
            description  LIKE st02_cat.description,
            status       LIKE st02_cat.status
        END RECORD,
        ret_code STRING,
        curr_row, idx SMALLINT

    LET idx = 0
    LET ret_code = NULL
    OPTIONS INPUT WRAP

    OPEN WINDOW w_lkup WITH FORM "st122_cat_lkup"
        ATTRIBUTES(TYPE = POPUP, STYLE = "lookup")

    DECLARE st_cat_curs CURSOR FOR
        SELECT id, description, status
          FROM st02_cat
         ORDER BY id

    CALL arr_st_cat.clear()

    FOREACH st_cat_curs INTO rec_list.*
        LET idx = idx + 1
        LET arr_st_cat[idx].* = rec_list.*
    END FOREACH

    IF idx > 0 THEN
        DISPLAY ARRAY arr_st_cat TO rec_list.*
            ATTRIBUTES(COUNT = idx, UNBUFFERED)
        LET curr_row = arr_curr()
        LET ret_code = arr_st_cat[curr_row].id
    ELSE
        CALL utils_globals.msg_no_record()
    END IF

    CLOSE WINDOW w_lkup
    RETURN ret_code
END FUNCTION

