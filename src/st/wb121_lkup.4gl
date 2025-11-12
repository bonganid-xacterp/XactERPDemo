-- ==========================================
-- Program : st121_wb_lkup.4gl
-- Purpose : Lookup (Popup) with Auto Search
-- Module  : Bin Ledger
-- Number  : 121
-- Author  : Bongani Dlamini
-- Version : Genero ver 3.20.10
-- ==========================================

IMPORT base

SCHEMA demoappdb

-- ==========================================
-- Main Lookup Function
-- ==========================================
FUNCTION display_list() RETURNS STRING
    DEFINE bin_arr DYNAMIC ARRAY OF RECORD
                id LIKE wb01_mast.id,
                description LIKE wb01_mast.description,
                wh_id LIKE wb01_mast.wh_id
            END RECORD,
           f_search STRING,
           ret_code STRING,
           curr SMALLINT

    -- Open popup lookup form
    OPEN WINDOW w_lkup WITH FORM "wb121_lkup"
        ATTRIBUTES(STYLE="dialog", TYPE=POPUP)

    LET f_search = ""
    LET ret_code = NULL

    -- Dialog combining search + table
    DIALOG ATTRIBUTES(UNBUFFERED)

        -- ===========================================
        -- Table Results
        -- ===========================================
        DISPLAY ARRAY bin_arr TO tbl_list.*
            ATTRIBUTES(DOUBLECLICK=accept)

            BEFORE DISPLAY
                CALL load_table_data(bin_arr, f_search)

            ON ACTION accept ATTRIBUTES(TEXT="Select", IMAGE="check")
                LET curr = arr_curr()
                IF curr > 0 THEN
                    LET ret_code = bin_arr[curr].id
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
                CALL load_table_data(bin_arr, f_search)
                NEXT FIELD f_search

            AFTER FIELD f_search
                -- Fires on Enter or Tab leaving the field
                CALL load_table_data(bin_arr, f_search)

            ON ACTION search ATTRIBUTES(TEXT="Search", IMAGE="zoom")
                CALL load_table_data(bin_arr, f_search)

        END INPUT

    END DIALOG

    CLOSE WINDOW w_lkup
    RETURN ret_code
END FUNCTION


-- ==========================================
-- Helper Function : Load Data
-- ==========================================
FUNCTION load_table_data(
    p_arr DYNAMIC ARRAY OF RECORD
        id LIKE wb01_mast.id,
        description LIKE wb01_mast.description,
        wh_id LIKE wb01_mast.wh_id
    END RECORD,
    p_filter STRING)

    DEFINE bin_rec RECORD
                id LIKE wb01_mast.id,
                description LIKE wb01_mast.description,
                wh_id LIKE wb01_mast.wh_id
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

    PREPARE stmt FROM
    "SELECT b.id, b.wb_code, b.description, b.wh_id
       FROM wb01_mast b
      WHERE (CAST(b.id AS VARCHAR(20)) ILIKE ?
             OR b.wb_code ILIKE ?
             OR b.description ILIKE ?
             OR CAST(b.wh_id AS VARCHAR(20)) ILIKE ?)
      ORDER BY b.id
      LIMIT 100";

    DECLARE bin_curs CURSOR FOR stmt
    OPEN bin_curs USING like_pat, like_pat, like_pat

    LET i = 0
    FOREACH bin_curs INTO bin_rec.*
        LET i = i + 1
        LET p_arr[i].* = bin_rec.*
    END FOREACH

    CLOSE bin_curs
    FREE bin_curs
    FREE stmt
END FUNCTION
