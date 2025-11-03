-- ==========================================
-- Program : st121_st_lkup.4gl
-- Purpose : Stock Lookup (Popup) with Auto Search
-- Module  : Stock Ledger
-- Number  : 121
-- Author  : Bongani Dlamini
-- Version : Genero ver 3.20.10
-- ==========================================
IMPORT base

SCHEMA demoapp_db

-- ==========================================
-- Main Lookup Function
-- ==========================================

FUNCTION display_stocklist() RETURNS STRING
    DEFINE
        stock_arr DYNAMIC ARRAY OF RECORD
            stock_code LIKE st01_mast.stock_code,
            description LIKE st01_mast.description
        END RECORD,
        f_search STRING,
        ret_code STRING,
        curr SMALLINT

    OPEN WINDOW w_lkup
        WITH
        FORM "st121_st_lkup"
        ATTRIBUTES(TYPE = POPUP, STYLE = "lookup")

    LET f_search = "*"
    LET ret_code = NULL

    DIALOG

    -- display the list of records
    DISPLAY ARRAY stock_arr TO f_st_list.*
        ATTRIBUTES(DOUBLECLICK = ACCEPT)

        BEFORE DISPLAY 
            CALL load_stock_data(stock_arr, f_search)

        ON ACTION accept
            LET curr = arr_curr()
            IF curr > 0 THEN
                LET ret_code = stock_arr[curr].stock_code
                EXIT DIALOG
            END IF

        ON ACTION CANCEL ATTRIBUTE (TEXT ="Exit")
            LET ret_code = NULL
            EXIT DIALOG
    END DISPLAY

    -- search input
    INPUT BY NAME f_search ATTRIBUTES(WITHOUT DEFAULTS)
        BEFORE INPUT
            CALL load_stock_data(stock_arr, f_search)
            NEXT FIELD f_st_search.f_search

            ON ACTION accept
            -- Trigger search immediately when Enter pressed
            CALL load_stock_data(stock_arr, f_search)
            CLEAR f_search
            
        AFTER FIELD f_st_search.f_search
            CALL load_stock_data(stock_arr, f_search)
    END INPUT

END DIALOG


    CLOSE WINDOW w_lkup
    RETURN ret_code
END FUNCTION

-- Build and execute parameterized query with wildcard handling
FUNCTION load_stock_data(
    p_arr DYNAMIC ARRAY OF RECORD
        stock_code LIKE st01_mast.stock_code,
        description LIKE st01_mast.description
    END RECORD,
    p_filter STRING)

    DEFINE
        rec RECORD
            stock_code LIKE st01_mast.stock_code,
            description LIKE st01_mast.description
        END RECORD,
        i INTEGER,
        like_pat STRING

    DEFINE buf base.StringBuffer
    LET buf = base.StringBuffer.create()

    CALL p_arr.clear()

    -- Normalize wildcard pattern:
    --  * -> % ; if no * present, do prefix search by appending %
    IF p_filter IS NULL OR p_filter = "" THEN
        LET like_pat = "%"
    ELSE
        LET like_pat = p_filter
        IF like_pat NOT MATCHES "*\\**" THEN
            -- no asterisk: treat as prefix search (foo -> foo%)
            LET like_pat = like_pat || "*"
        END IF
        -- Replace all '*' with '%' for SQL
        CALL buf.append(like_pat)
        CALL buf.replace("*", "%", 0)
        LET like_pat = buf.toString()
    END IF

    -- Parameterized SQL (no concatenation)
    PREPARE stmt
        FROM "SELECT stock_code, description
           FROM st01_mast
          WHERE status = 'active'
            AND (stock_code ILIKE ? OR description ILIKE ?)
          ORDER BY stock_code"

    DECLARE stock_c CURSOR FOR stmt
    OPEN stock_c USING like_pat, like_pat

    LET i = 0
    FOREACH stock_c INTO rec.*
        LET i = i + 1
        LET p_arr[i].* = rec.*
    END FOREACH

    CLOSE stock_c
    FREE stock_c
    FREE stmt
    
END FUNCTION
