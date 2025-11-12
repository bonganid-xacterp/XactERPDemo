-- ==========================================
-- Program : st121_st_lkup.4gl
-- Purpose : Stock Lookup (Popup) with Auto Search
-- Module  : Stock Ledger
-- Number  : 121
-- Author  : Bongani Dlamini
-- Version : Genero ver 3.20.10
-- ==========================================

IMPORT base

SCHEMA demoappdb

-- ==========================================
-- Main Lookup Function
-- ==========================================
FUNCTION display_stocklist() RETURNS STRING
    DEFINE stock_arr DYNAMIC ARRAY OF RECORD
                id LIKE st01_mast.id,
                description LIKE st01_mast.description,
                stock_on_hand LIKE st01_mast.stock_on_hand
            END RECORD,
           f_search STRING,
           ret_code STRING,
           curr SMALLINT

    -- Open popup lookup form
    OPEN WINDOW w_lkup WITH FORM "st121_st_lkup"
        ATTRIBUTES(STYLE="dialog", TYPE=POPUP)

    LET f_search = ""
    LET ret_code = NULL

    -- Dialog combining search + table
    DIALOG ATTRIBUTES(UNBUFFERED)

        -- ===========================================
        -- Table of Stock Results
        -- ===========================================
        DISPLAY ARRAY stock_arr TO tbl_st_list.*
            ATTRIBUTES(DOUBLECLICK=accept)

            BEFORE DISPLAY
                CALL load_stock_data(stock_arr, f_search)

            ON ACTION accept ATTRIBUTES(TEXT="Select", IMAGE="check")
                LET curr = arr_curr()
                IF curr > 0 THEN
                    LET ret_code = stock_arr[curr].id
                    EXIT DIALOG
                END IF

            ON ACTION cancel ATTRIBUTES(TEXT="Close", IMAGE="exit")
                LET ret_code = NULL
                EXIT DIALOG
        END DISPLAY

        -- ===========================================
        -- Search Field (Enter / Tab / Search Button)
        -- ===========================================
        INPUT BY NAME f_search ATTRIBUTES(WITHOUT DEFAULTS)

            BEFORE FIELD f_search
                -- If Enter pressed, reload but stay on same field
                CALL load_stock_data(stock_arr, f_search)
                NEXT FIELD f_search

            AFTER FIELD f_search
                -- Fires on Enter or Tab leaving the field
                CALL load_stock_data(stock_arr, f_search)

            ON ACTION search ATTRIBUTES(TEXT="Search", IMAGE="zoom")
                CALL load_stock_data(stock_arr, f_search)

        END INPUT

    END DIALOG

    CLOSE WINDOW w_lkup
    RETURN ret_code
END FUNCTION


-- ==========================================
-- Helper Function : Load Stock Data
-- ==========================================
FUNCTION load_stock_data(
    p_arr DYNAMIC ARRAY OF RECORD
        id LIKE st01_mast.id,
        description LIKE st01_mast.description,
        stock_on_hand LIKE st01_mast.stock_on_hand
    END RECORD,
    p_filter STRING)

    DEFINE stock_rec RECORD
                id LIKE st01_mast.id,
                description LIKE st01_mast.description,
                stock_on_hand LIKE st01_mast.stock_on_hand
            END RECORD,
           like_pat STRING,
           i INTEGER

    DEFINE buf base.StringBuffer
    LET buf = base.StringBuffer.create()

    CALL p_arr.clear()

    -- Normalize wildcard pattern
    IF p_filter IS NULL OR p_filter = "" THEN
        LET like_pat = "%"
    ELSE
        LET like_pat = p_filter
        IF like_pat NOT MATCHES ".*\\*.*" THEN
            -- No '*' entered, assume prefix search
            LET like_pat = like_pat || "*"
        END IF
        CALL buf.append(like_pat)
        CALL buf.replace("*", "%", 0)
        LET like_pat = buf.toString()
    END IF

    -- ===========================================
    -- Parameterized SQL Query
    -- ===========================================
    PREPARE stmt FROM
        "SELECT id, description, stock_on_hand
           FROM st01_mast
          WHERE status = 'active'
            AND (CAST(id AS VARCHAR(20)) ILIKE ?
                 OR description ILIKE ?
                 OR CAST(stock_on_hand AS VARCHAR(20)) ILIKE ?)
          ORDER BY id
          LIMIT 100"

    DECLARE stock_curs CURSOR FOR stmt
    OPEN stock_curs USING like_pat, like_pat, like_pat

    LET i = 0
    FOREACH stock_curs INTO stock_rec.*
        LET i = i + 1
        LET p_arr[i].* = stock_rec.*
    END FOREACH

    CLOSE stock_curs
    FREE stock_curs
    FREE stmt
END FUNCTION
