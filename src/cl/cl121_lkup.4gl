-- ==========================================
-- Program : cl121_lkup.4gl
-- Purpose : Creditors Lookup (Popup Grid)
-- Module  : Creditors
-- Number  : 121
-- Version : Genero ver 3.20.10
-- ==========================================
IMPORT FGL utils_globals
IMPORT ui

SCHEMA demoappdb

-- display creditor form with search
FUNCTION fetch_list() RETURNS STRING
    DEFINE selected_code STRING
    DEFINE curr_idx INTEGER
    DEFINE f_search STRING
    DEFINE where_clause STRING

    DEFINE
        cred_arr DYNAMIC ARRAY OF RECORD
            id LIKE cl01_mast.id,
            supp_name LIKE cl01_mast.supp_name,
            status LIKE cl01_mast.status,
            balance LIKE cl01_mast.balance
        END RECORD

    OPTIONS INPUT WRAP
    OPEN WINDOW w_cred WITH FORM "cl121_lkup"
        ATTRIBUTES(STYLE = "dialog", TYPE = POPUP)

    LET f_search = ""
    LET where_clause = "1=1"
    LET selected_code = NULL

    -- Load initial data
    CALL load_creditor_data(cred_arr, f_search)

    DIALOG ATTRIBUTES(UNBUFFERED)

        -- Table of Creditor Results
        DISPLAY ARRAY cred_arr TO r_creditors_list.*
            ATTRIBUTES(DOUBLECLICK = accept)

            ON ACTION accept ATTRIBUTES(TEXT = "Select", IMAGE = "check")
                LET curr_idx = arr_curr()
                IF curr_idx > 0 THEN
                    LET selected_code = cred_arr[curr_idx].id
                    EXIT DIALOG
                END IF

            ON KEY (RETURN)
                LET curr_idx = arr_curr()
                IF curr_idx > 0 THEN
                    LET selected_code = cred_arr[curr_idx].id
                    EXIT DIALOG
                END IF

            ON ACTION cancel ATTRIBUTES(TEXT = "Close", IMAGE = "exit")
                LET selected_code = NULL
                EXIT DIALOG
        END DISPLAY

        -- Search Field
        INPUT BY NAME f_search ATTRIBUTES(WITHOUT DEFAULTS)

            AFTER FIELD f_search
                CALL load_creditor_data(cred_arr, f_search)
                CALL ui.Interface.refresh()

            ON ACTION search ATTRIBUTES(TEXT = "Search", IMAGE = "zoom")
                CALL load_creditor_data(cred_arr, f_search)
                CALL ui.Interface.refresh()

            ON ACTION clear ATTRIBUTES(TEXT = "Clear", IMAGE = "refresh")
                LET f_search = ""
                CALL load_creditor_data(cred_arr, f_search)
                CALL ui.Interface.refresh()
                DISPLAY BY NAME f_search

            ON ACTION cancel ATTRIBUTES(TEXT = "Close", IMAGE = "exit")
                LET selected_code = NULL
                EXIT DIALOG

        END INPUT

    END DIALOG

    CLOSE WINDOW w_cred
    RETURN selected_code
END FUNCTION

-- Helper function to load creditor data with search filter
FUNCTION load_creditor_data(
    p_arr DYNAMIC ARRAY OF RECORD
        id LIKE cl01_mast.id,
        supp_name LIKE cl01_mast.supp_name,
        status LIKE cl01_mast.status,
        balance LIKE cl01_mast.balance
    END RECORD,
    p_filter STRING)

    DEFINE
        cred_rec RECORD
            id LIKE cl01_mast.id,
            supp_name LIKE cl01_mast.supp_name,
            status LIKE cl01_mast.status,
            balance LIKE cl01_mast.balance
        END RECORD,
        like_pat STRING,
        i INTEGER

    CALL p_arr.clear()

    -- Normalize wildcard pattern
    IF p_filter IS NULL OR p_filter = "" THEN
        LET like_pat = "%"
    ELSE
        LET like_pat = "%" || p_filter || "%"
    END IF

    -- Parameterized SQL Query
    PREPARE cred_stmt
        FROM "SELECT id, supp_name, status, balance
           FROM cl01_mast
          WHERE supp_name ILIKE ?
             OR CAST(id AS VARCHAR(20)) ILIKE ?
          ORDER BY id
          LIMIT 100"

    DECLARE cred_curs CURSOR FOR cred_stmt
    OPEN cred_curs USING like_pat, like_pat

    LET i = 0
    FOREACH cred_curs INTO cred_rec.*
        LET i = i + 1
        LET p_arr[i].* = cred_rec.*
    END FOREACH

    CLOSE cred_curs
    FREE cred_curs
    FREE cred_stmt
END FUNCTION

-- ==============================================================
-- Alternative version with search capability using f_search field
-- ==============================================================
FUNCTION load_lookup_form_with_search() RETURNS STRING

    DEFINE selected_code STRING
    
    DEFINE cred_arr DYNAMIC ARRAY OF RECORD
        id LIKE cl01_mast.id,
        supp_name LIKE cl01_mast.supp_name,
        status LIKE cl01_mast.status
    END RECORD

    DEFINE f_search STRING
    DEFINE sel SMALLINT
    DEFINE row_count INTEGER

    LET selected_code = NULL
    LET f_search = NULL

    IF row_count = 0 THEN
        CALL utils_globals.show_info("No creditor records found.")
        RETURN NULL
    END IF
    OPTIONS INPUT WRAP
    OPEN WINDOW w_lkup WITH FORM "cl121_lkup" ATTRIBUTES(STYLE = "dialog")

    DIALOG ATTRIBUTES(UNBUFFERED)

        INPUT BY NAME f_search
            AFTER FIELD f_search
                CALL load_creditors_for_lookup(f_search)
                    RETURNING cred_arr, row_count
                CALL DIALOG.setArrayLength("r_creditors_list", cred_arr.getLength())
                -- keep table on row 1 but return focus to filter
                CALL DIALOG.setCurrentRow(
                    "r_creditors_list", IIF(row_count > 0, 1, 0))
                NEXT FIELD f_search
        END INPUT

        DISPLAY ARRAY cred_arr TO r_creditors_list.*

            BEFORE DISPLAY
                CALL DIALOG.setCurrentRow("r_creditors_list", 1)

            ON ACTION ACCEPT
            
                LET sel = DIALOG.getCurrentRow("r_creditors_list")
                IF sel > 0 AND sel <= cred_arr.getLength() THEN
                    LET selected_code = cred_arr[sel].id
                    EXIT DIALOG
                END IF

            ON ACTION cancel
                LET selected_code = NULL
                EXIT DIALOG

            ON ACTION doubleclick
                LET sel = DIALOG.getCurrentRow("r_creditors_list")
                IF sel > 0 AND sel <= cred_arr.getLength() THEN
                    LET selected_code = cred_arr[sel].id
                    EXIT DIALOG
                END IF

            ON KEY(RETURN)
                LET sel = DIALOG.getCurrentRow("r_creditors_list")
                IF sel > 0 AND sel <= cred_arr.getLength() THEN
                    LET selected_code = cred_arr[sel].id
                    EXIT DIALOG
                END IF

        END DISPLAY

    END DIALOG

    CLOSE WINDOW w_lkup

    RETURN selected_code

END FUNCTION

-- Helper function to load creditors with optional search filter
FUNCTION load_creditors_for_lookup(search_filter STRING)
    RETURNS(
        DYNAMIC ARRAY OF RECORD
            id LIKE cl01_mast.id,
            l_name LIKE cl01_mast.supp_name,
            status LIKE cl01_mast.status
        END RECORD,
        INTEGER)

    DEFINE rec RECORD
        id LIKE cl01_mast.id,
        l_name LIKE cl01_mast.supp_name,
        status LIKE cl01_mast.status
    END RECORD

    DEFINE cred_arr DYNAMIC ARRAY OF RECORD
        id LIKE cl01_mast.id,
        l_name LIKE cl01_mast.supp_name,
        status LIKE cl01_mast.status
    END RECORD
    
    DEFINE sql_stmt STRING
    DEFINE row_count INTEGER
    DEFINE search_pat STRING

    CALL cred_arr.clear()
    LET row_count = 0

    LET search_pat = "%" || NVL(search_filter, "") || "%"

    -- Build SQL with search filter
    LET sql_stmt = "SELECT id, supp_name, status FROM cl01_mast"

    IF search_filter IS NOT NULL AND search_filter.getLength() > 0 THEN
        LET sql_stmt =
            sql_stmt
                || " WHERE id LIKE '%"
                || search_filter
                || "%'"
                || " OR supp_name LIKE '%"
                || search_filter
                || "%'"
    END IF

    LET sql_stmt = sql_stmt || " ORDER BY id"

    WHENEVER ERROR CONTINUE
    
    PREPARE cred_prep
        FROM "SELECT id, supp_name, status"
            || "FROM cl01_mast "
            || "WHERE id ILIKE ? OR supp_name ILIKE ? "
            || "ORDER BY id";
            
    DECLARE cred_csr2 CURSOR FOR cred_prep

    OPEN cred_csr2 USING search_pat, search_pat

    IF SQLCA.SQLCODE = 0 THEN
        FETCH cred_csr2 INTO rec.*
        WHILE SQLCA.SQLCODE = 0
            LET row_count = row_count + 1
            LET cred_arr[row_count].* = rec.*
            FETCH cred_csr2 INTO rec.*
        END WHILE
    END IF

    CLOSE cred_csr2
    FREE cred_prep
    
    WHENEVER ERROR STOP

    RETURN cred_arr, row_count

END FUNCTION
