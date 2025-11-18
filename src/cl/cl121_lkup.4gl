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

-- display creditor form
FUNCTION fetch_list() RETURNS STRING
    DEFINE selected_code STRING
    DEFINE idx INTEGER
    DEFINE dlg ui.Dialog
    DEFINE sel INTEGER

    DEFINE
        cred_arr DYNAMIC ARRAY OF RECORD
            id LIKE cl01_mast.id,
            supp_name LIKE cl01_mast.supp_name,
            status LIKE cl01_mast.status,
            balance LIKE cl01_mast.balance
        END RECORD,

        cred_rec RECORD
            id LIKE cl01_mast.id,
            supp_name LIKE cl01_mast.supp_name,
            status LIKE cl01_mast.status,
            balance LIKE cl01_mast.balance
        END RECORD

    LET idx = 0
    LET selected_code = NULL
    
    OPEN WINDOW w_cred WITH FORM "cl121_lkup" ATTRIBUTES(STYLE = "dialog")

    -- Load data of all active creditors
    DECLARE creditors_curs CURSOR FOR
        SELECT id,
            supp_name,
            status,
            balance
            FROM cl01_mast
            ORDER BY id ASC

    CALL cred_arr.clear()

    FOREACH creditors_curs INTO cred_rec.*
        LET idx = idx + 1
        LET cred_arr[idx].* = cred_rec.*
    END FOREACH

    -- Show array only if records exist
    IF idx > 0 THEN
        DIALOG ATTRIBUTES(UNBUFFERED)
            DISPLAY ARRAY cred_arr TO r_creditors_list.* ATTRIBUTES(COUNT = idx)

                BEFORE DISPLAY
                    LET dlg = ui.Dialog.getCurrent()
                    IF cred_arr.getLength() > 0 THEN
                        CALL dlg.setCurrentRow("r_creditors_list", 1)
                    END IF

                ON ACTION accept
                    LET sel = dlg.getCurrentRow("r_creditors_list")
                    IF sel > 0 AND sel <= cred_arr.getLength() THEN
                        LET selected_code = cred_arr[sel].id
                    END IF
                    EXIT DIALOG

                ON ACTION cancel
                    LET selected_code = NULL

                    EXIT DIALOG

                ON KEY(RETURN)
                    LET sel = dlg.getCurrentRow("r_creditors_list")
                    IF sel > 0 AND sel <= cred_arr.getLength() THEN
                        LET selected_code = cred_arr[sel].id
                    END IF
                    EXIT DIALOG
                ON KEY(ESCAPE)
                    LET selected_code = NULL
                    EXIT DIALOG
            END DISPLAY
        END DIALOG
    ELSE
        CALL utils_globals.show_info("No creditor records found.")
    END IF

    CLOSE WINDOW w_cred
    RETURN selected_code
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
