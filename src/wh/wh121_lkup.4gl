-- ==============================================================
-- Program   : wh121_lkup.4gl
-- Purpose   : Warehouse Lookup (Popup Grid)
-- Module    : Warehouse (wh)
-- Number    : 121
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Lookup dialog for selecting warehouses
--              Provides search/filter capability
-- ==============================================================
IMPORT FGL utils_globals
IMPORT ui

SCHEMA demoappdb

-- ==============================================================
-- Simple lookup - returns selected warehouse code
-- ==============================================================
FUNCTION fetch_list() RETURNS STRING
    DEFINE selected_code STRING
    DEFINE idx INTEGER
    DEFINE dlg ui.Dialog
    DEFINE sel INTEGER

    DEFINE
        wh_arr DYNAMIC ARRAY OF RECORD
            wh_code LIKE wh01_mast.wh_code,
            wh_name LIKE wh01_mast.wh_name,
            location LIKE wh01_mast.location,
            status LIKE wh01_mast.status
        END RECORD,

        wh_rec RECORD
            wh_code LIKE wh01_mast.wh_code,
            wh_name LIKE wh01_mast.wh_name,
            location LIKE wh01_mast.location,
            status LIKE wh01_mast.status
        END RECORD

    LET idx = 0
    LET selected_code = NULL
    OPTIONS INPUT WRAP
    OPEN WINDOW w_wh_lkup WITH FORM "wh121_lkup" ATTRIBUTES(STYLE = "dialog")

    -- Load data of all active warehouses
    DECLARE wh_curs CURSOR FOR
        SELECT wh_code,
               wh_name,
               location,
               status
        FROM wh01_mast
        ORDER BY wh_code

    CALL wh_arr.clear()

    FOREACH wh_curs INTO wh_rec.*
        LET idx = idx + 1
        LET wh_arr[idx].* = wh_rec.*
    END FOREACH

    -- Show array only if records exist
    IF idx > 0 THEN
        DIALOG ATTRIBUTES(UNBUFFERED)
            DISPLAY ARRAY wh_arr TO r_wh_list.* ATTRIBUTES(COUNT = idx)

                BEFORE DISPLAY
                    LET dlg = ui.Dialog.getCurrent()
                    IF wh_arr.getLength() > 0 THEN
                        CALL dlg.setCurrentRow("r_wh_list", 1)
                    END IF

                ON ACTION accept
                    LET sel = dlg.getCurrentRow("r_wh_list")
                    IF sel > 0 AND sel <= wh_arr.getLength() THEN
                        LET selected_code = wh_arr[sel].wh_code
                    END IF
                    EXIT DIALOG

                ON ACTION cancel
                    LET selected_code = NULL
                    EXIT DIALOG

                ON KEY(RETURN)
                    LET sel = dlg.getCurrentRow("r_wh_list")
                    IF sel > 0 AND sel <= wh_arr.getLength() THEN
                        LET selected_code = wh_arr[sel].wh_code
                    END IF
                    EXIT DIALOG

                ON KEY(ESCAPE)
                    LET selected_code = NULL
                    EXIT DIALOG
            END DISPLAY
        END DIALOG
    ELSE
        CALL utils_globals.show_info("No warehouse records found.")
    END IF

    CLOSE WINDOW w_wh_lkup
    RETURN selected_code
END FUNCTION

-- ==============================================================
-- Lookup with search capability using f_search field
-- ==============================================================
FUNCTION load_lookup_form_with_search() RETURNS STRING

    DEFINE selected_code STRING

    DEFINE wh_arr DYNAMIC ARRAY OF RECORD
        wh_code LIKE wh01_mast.wh_code,
        wh_name LIKE wh01_mast.wh_name,
        location LIKE wh01_mast.location,
        status LIKE wh01_mast.status
    END RECORD

    DEFINE f_search STRING
    DEFINE sel SMALLINT
    DEFINE row_count INTEGER

    LET selected_code = NULL
    LET f_search = NULL

    -- Initial load with all warehouses
    CALL load_warehouses_for_lookup(f_search)
        RETURNING wh_arr, row_count

    IF row_count = 0 THEN
        CALL utils_globals.show_info("No warehouse records found.")
        RETURN NULL
    END IF

    OPTIONS INPUT WRAP
    OPEN WINDOW w_wh_lkup WITH FORM "wh121_lkup" ATTRIBUTES(STYLE = "dialog")

    DIALOG ATTRIBUTES(UNBUFFERED)

        INPUT BY NAME f_search
            AFTER FIELD f_search
                CALL load_warehouses_for_lookup(f_search)
                    RETURNING wh_arr, row_count
                CALL DIALOG.setArrayLength("r_wh_list", wh_arr.getLength())
                -- Keep table on row 1 but return focus to filter
                CALL DIALOG.setCurrentRow(
                    "r_wh_list", IIF(row_count > 0, 1, 0))
                NEXT FIELD f_search
        END INPUT

        DISPLAY ARRAY wh_arr TO r_wh_list.*

            BEFORE DISPLAY
                CALL DIALOG.setCurrentRow("r_wh_list", 1)

            ON ACTION ACCEPT
                LET sel = DIALOG.getCurrentRow("r_wh_list")
                IF sel > 0 AND sel <= wh_arr.getLength() THEN
                    LET selected_code = wh_arr[sel].wh_code
                    EXIT DIALOG
                END IF

            ON ACTION cancel
                LET selected_code = NULL
                EXIT DIALOG

            ON ACTION doubleclick
                LET sel = DIALOG.getCurrentRow("r_wh_list")
                IF sel > 0 AND sel <= wh_arr.getLength() THEN
                    LET selected_code = wh_arr[sel].wh_code
                    EXIT DIALOG
                END IF

            ON KEY(RETURN)
                LET sel = DIALOG.getCurrentRow("r_wh_list")
                IF sel > 0 AND sel <= wh_arr.getLength() THEN
                    LET selected_code = wh_arr[sel].wh_code
                    EXIT DIALOG
                END IF

            ON KEY(ESCAPE)
                LET selected_code = NULL
                EXIT DIALOG

        END DISPLAY

    END DIALOG

    CLOSE WINDOW w_wh_lkup

    RETURN selected_code

END FUNCTION

-- ==============================================================
-- Helper function to load warehouses with optional search filter
-- ==============================================================
FUNCTION load_warehouses_for_lookup(search_filter STRING)
    RETURNS(
        DYNAMIC ARRAY OF RECORD
            wh_code LIKE wh01_mast.wh_code,
            wh_name LIKE wh01_mast.wh_name,
            location LIKE wh01_mast.location,
            status LIKE wh01_mast.status
        END RECORD,
        INTEGER)

    DEFINE rec RECORD
        wh_code LIKE wh01_mast.wh_code,
        wh_name LIKE wh01_mast.wh_name,
        location LIKE wh01_mast.location,
        status LIKE wh01_mast.status
    END RECORD

    DEFINE wh_arr DYNAMIC ARRAY OF RECORD
        wh_code LIKE wh01_mast.wh_code,
        wh_name LIKE wh01_mast.wh_name,
        location LIKE wh01_mast.location,
        status LIKE wh01_mast.status
    END RECORD

    DEFINE row_count INTEGER
    DEFINE search_pat STRING

    CALL wh_arr.clear()
    LET row_count = 0

    LET search_pat = "%" || NVL(search_filter, "") || "%"

    WHENEVER ERROR CONTINUE

    -- Prepare query with search filter
    PREPARE wh_prep FROM
        "SELECT wh_code, wh_name, location, status " ||
        "FROM wh01_mast " ||
        "WHERE (wh_code LIKE ? OR wh_name LIKE ? OR location LIKE ?) " ||
        "ORDER BY wh_code"

    DECLARE wh_csr CURSOR FOR wh_prep

    OPEN wh_csr USING search_pat, search_pat, search_pat

    IF SQLCA.SQLCODE = 0 THEN
        FETCH wh_csr INTO rec.*
        WHILE SQLCA.SQLCODE = 0
            LET row_count = row_count + 1
            LET wh_arr[row_count].* = rec.*
            FETCH wh_csr INTO rec.*
        END WHILE
    END IF

    CLOSE wh_csr
    FREE wh_prep

    WHENEVER ERROR STOP

    RETURN wh_arr, row_count

END FUNCTION

-- ==============================================================
-- Get warehouse name by code
-- ==============================================================
PUBLIC FUNCTION get_warehouse_name(p_wh_code STRING) RETURNS STRING
    DEFINE l_wh_name STRING

    SELECT wh_name INTO l_wh_name
    FROM wh01_mast
    WHERE wh_code = p_wh_code

    IF SQLCA.SQLCODE != 0 THEN
        RETURN NULL
    END IF

    RETURN l_wh_name
END FUNCTION

-- ==============================================================
-- Validate warehouse code exists
-- ==============================================================
PUBLIC FUNCTION validate_warehouse_code(p_wh_code STRING) RETURNS SMALLINT
    DEFINE l_count INTEGER

    SELECT COUNT(*) INTO l_count
    FROM wh01_mast
    WHERE wh_code = p_wh_code

    IF l_count > 0 THEN
        RETURN TRUE
    END IF

    RETURN FALSE
END FUNCTION
