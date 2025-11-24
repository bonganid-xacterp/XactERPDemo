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
FUNCTION fetch_list() RETURNS STRING
    DEFINE
        stock_arr DYNAMIC ARRAY OF RECORD
            id LIKE st01_mast.id,
            description LIKE st01_mast.description,
            stock_on_hand LIKE st01_mast.stock_on_hand,
            uom LIKE st01_mast.uom
        END RECORD,
        f_search STRING,
        where_clause STRING,
        ret_code INTEGER,
        curr_idx INTEGER

    -- Open popup lookup form
    OPTIONS INPUT WRAP
    OPEN WINDOW w_lkup
        WITH
        FORM "st121_st_lkup"
        ATTRIBUTES(STYLE = "dialog", TYPE = POPUP)

    LET f_search = ""
    LET where_clause = "1=1" -- Default WHERE clause (all records)
    LET ret_code = NULL

    -- Load initial data
    CALL load_stock_data_construct(stock_arr, where_clause)

    -- Dialog combining search + table
    DIALOG ATTRIBUTES(UNBUFFERED)

        -- ===========================================
        -- Table of Stock Results
        -- ===========================================
        DISPLAY ARRAY stock_arr
            TO tbl_st_list.*
            ATTRIBUTES(DOUBLECLICK = ACCEPT)

            ON KEY(RETURN)
            ON ACTION accept ATTRIBUTES(TEXT = "Select", IMAGE = "check")
                LET curr_idx = arr_curr()
                IF curr_idx > 0 THEN
                    LET ret_code = stock_arr[curr_idx].id
                    EXIT DIALOG
                END IF

            ON ACTION cancel ATTRIBUTES(TEXT = "Close", IMAGE = "exit")
                LET ret_code = NULL
                EXIT DIALOG
        END DISPLAY

        -- ===========================================
        -- Search Field (Enter / Tab / Search Button)
        -- ===========================================
        INPUT BY NAME f_search ATTRIBUTES(WITHOUT DEFAULTS)

            AFTER FIELD f_search
                -- Fires on Enter or Tab leaving the field
                CALL load_stock_data(stock_arr, f_search)
                CALL ui.Interface.refresh()

            ON KEY (RETURN)
            ON ACTION search ATTRIBUTES(TEXT = "Search", IMAGE = "zoom")
                CALL load_stock_data(stock_arr, f_search)
                CALL ui.Interface.refresh()

            ON ACTION clear ATTRIBUTES(TEXT = "Clear", IMAGE = "refresh")
                -- Clear search field and reload all records
                LET f_search = ""
                CALL load_stock_data_construct(stock_arr, "1=1")
                CALL ui.Interface.refresh()
                DISPLAY BY NAME f_search

            ON ACTION close ATTRIBUTES(TEXT = "Close", IMAGE = "exit")
                LET ret_code = NULL
                EXIT DIALOG

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
        stock_on_hand LIKE st01_mast.stock_on_hand,
        uom LIKE st01_mast.uom
    END RECORD,
    p_filter STRING)

    DEFINE
        stock_rec RECORD
            id LIKE st01_mast.id,
            description LIKE st01_mast.description,
            stock_on_hand LIKE st01_mast.stock_on_hand,
            uom LIKE st01_mast.uom
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
    PREPARE stmt
        FROM "SELECT id, description, stock_on_hand, uom
           FROM st01_mast
          WHERE description ILIKE ?
          ORDER BY id
          LIMIT 100"

    DECLARE stock_curs CURSOR FOR stmt
    OPEN stock_curs USING like_pat

    LET i = 0
    FOREACH stock_curs INTO stock_rec.*
        LET i = i + 1
        LET p_arr[i].* = stock_rec.*
    END FOREACH

    CLOSE stock_curs
    FREE stock_curs
    FREE stmt
END FUNCTION

-- ==========================================
-- Helper Function : Load Stock Data with CONSTRUCT
-- ==========================================
FUNCTION load_stock_data_construct(
    p_arr DYNAMIC ARRAY OF RECORD
        id LIKE st01_mast.id,
        description LIKE st01_mast.description,
        stock_on_hand LIKE st01_mast.stock_on_hand,
        uom LIKE st01_mast.uom
    END RECORD,
    p_where_clause STRING)

    DEFINE
        stock_rec RECORD
            id LIKE st01_mast.id,
            description LIKE st01_mast.description,
            stock_on_hand LIKE st01_mast.stock_on_hand,
            uom LIKE st01_mast.uom
        END RECORD,
        sql_query STRING,
        i INTEGER

    CALL p_arr.clear()

    -- Build SQL query with constructed WHERE clause
    LET sql_query =
        "SELECT id, description, stock_on_hand, uom ",
        "FROM st01_mast ",
        "AND (",
        p_where_clause,
        ") ",
        "ORDER BY id ",
        "LIMIT 100"

    -- Prepare and execute query
    PREPARE stmt_construct FROM sql_query
    DECLARE stock_curs_construct CURSOR FOR stmt_construct

    LET i = 0
    FOREACH stock_curs_construct INTO stock_rec.*
        LET i = i + 1
        LET p_arr[i].* = stock_rec.*
    END FOREACH

    CLOSE stock_curs_construct
    FREE stock_curs_construct
    FREE stmt_construct
END FUNCTION
