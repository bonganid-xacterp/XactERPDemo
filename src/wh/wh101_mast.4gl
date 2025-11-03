-- ==============================================================
-- Program   : wh101_mast.4gl
-- Purpose   : Warehouse Master maintenance (CRUD operations)
-- Module    : Warehouse (wh)
-- Number    : 101
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Master file maintenance for warehouses
--              Provides full CRUD operations for warehouse records
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL wh121_lkup
IMPORT FGL utils_status_const

SCHEMA demoapp_db -- Use correct schema name

-- Warehouse master record structure
TYPE warehouse_t RECORD LIKE wh01_mast.*

DEFINE rec_wh warehouse_t
DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER

-- ==============================================================
-- Main
-- ==============================================================
MAIN
    IF NOT utils_globals.initialize_application() THEN
        DISPLAY "Initialization failed."
        EXIT PROGRAM 1
    END IF
    OPTIONS INPUT WRAP
    OPEN WINDOW w_wh101 WITH FORM "wh101_mast" ATTRIBUTES(STYLE = "main")
    CALL init_wh_module()
    CLOSE WINDOW w_wh101
END MAIN

-- ==============================================================
-- Menu Controller
-- ==============================================================
FUNCTION init_wh_module()
    DEFINE is_edit_mode SMALLINT
    DEFINE selected_code STRING

    -- ===========================================
    -- MAIN MENU (top-level)
    -- ===========================================
    MENU "warehouses Menu"

        COMMAND "Find"
            --LET selected_code = query_warehouse()
            LET is_edit_mode = FALSE

        COMMAND "New"
            CALL new_warehouse()
            LET is_edit_mode = FALSE

        COMMAND "Edit"
            IF rec_wh.wh_code IS NULL OR rec_wh.wh_code = "" THEN
                CALL utils_globals.show_info("No record selected to edit.")
            ELSE
                LET is_edit_mode = TRUE
                CALL edit_warehouse() -- call subdialog function
            END IF

        COMMAND "Delete"
            CALL delete_warehouse()
            LET is_edit_mode = FALSE

        COMMAND "First"
            CALL move_record(-2)
        COMMAND "Previous"
            CALL move_record(-1)
        COMMAND "Next"
            CALL move_record(1)
        COMMAND "Last"
            CALL move_record(2)

        COMMAND "Exit"
            EXIT MENU

    END MENU
END FUNCTION

-- ==============================================================
-- Lookup popup
-- ==============================================================
FUNCTION query_warehouse() RETURNS STRING
    DEFINE selected_code STRING
    LET selected_code = wh121_lkup.fetch_wh_list(NULL)
    RETURN selected_code
END FUNCTION

-- ==============================================================
-- Build navigation list (codes) from a WHERE clause
-- ==============================================================
FUNCTION select_warehouses(p_where STRING) RETURNS SMALLINT
    DEFINE code STRING
    DEFINE idx INTEGER
    DEFINE s_stmt STRING

    CALL arr_codes.clear()
    LET idx = 0

    -- Use prepared statement for dynamic SQL (3.20-compliant)
    LET s_stmt =
        "SELECT wh_code FROM wh01_mast WHERE " || p_where || " ORDER BY wh_code"
    PREPARE p_sel FROM s_stmt
    DECLARE c_curs CURSOR FOR p_sel

    FOREACH c_curs INTO code
        LET idx = idx + 1
        LET arr_codes[idx] = code
    END FOREACH

    CLOSE c_curs
    FREE p_sel

    IF arr_codes.getLength() = 0 THEN
        CALL utils_globals.show_info("No records found.")
        RETURN FALSE
    END IF

    LET curr_idx = 1
    CALL load_warehouse(arr_codes[curr_idx])
    RETURN TRUE
END FUNCTION

-- ==============================================================
-- Load Single Warehouse
-- ==============================================================
FUNCTION load_warehouse(p_code STRING)
    -- Select fields in the SAME order/count as rec_wh.*
    SELECT * INTO rec_wh.* FROM wh01_mast WHERE wh_code = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_wh.*
    ELSE
        -- If missing, clear the screen
        INITIALIZE rec_wh.* TO NULL
        DISPLAY BY NAME rec_wh.*
    END IF
END FUNCTION

-- ==============================================================
-- Find current index by code (for navigation after lookups)
-- ==============================================================
FUNCTION set_curr_idx_by_code(p_code STRING)
    DEFINE i INTEGER
    FOR i = 1 TO arr_codes.getLength()
        IF arr_codes[i] = p_code THEN
            LET curr_idx = i
            EXIT FOR
        END IF
    END FOR
END FUNCTION

-- ==============================================================
-- Navigation
-- ==============================================================
FUNCTION move_record(dir SMALLINT)
    CASE dir
        WHEN -2
            LET curr_idx = 1
        WHEN -1
            IF curr_idx > 1 THEN
                LET curr_idx = curr_idx - 1
            ELSE
                CALL utils_globals.show_info("Start of list.")
                RETURN
            END IF
        WHEN 1
            IF curr_idx < arr_codes.getLength() THEN
                LET curr_idx = curr_idx + 1
            ELSE
                CALL utils_globals.show_info("End of list.")
                RETURN
            END IF
        WHEN 2
            LET curr_idx = arr_codes.getLength()
    END CASE

    CALL load_warehouse(arr_codes[curr_idx])
END FUNCTION

-- ==============================================================
-- New Warehouse
-- ==============================================================
FUNCTION new_warehouse()
    -- Prepare blank record with sensible defaults
    INITIALIZE rec_wh.* TO NULL
    LET rec_wh.status = 'active'
    DISPLAY BY NAME rec_wh.*
    MESSAGE "Enter new warehouse details, then click Save."
END FUNCTION

-- ==============================================================
-- Save / Update
-- ==============================================================
FUNCTION save_warehouse()
    DEFINE r_exists INTEGER
    DEFINE ok SMALLINT

    IF rec_wh.wh_code IS NULL OR rec_wh.wh_code = "" THEN
        CALL utils_globals.show_info("Warehouse code is required.")
        RETURN
    END IF

    SELECT COUNT(*) INTO r_exists FROM wh01_mast WHERE wh_code = rec_wh.wh_code

    IF r_exists = 0 THEN
        INSERT INTO wh01_mast VALUES rec_wh.*
        CALL utils_globals.show_info("Record saved.")
        -- refresh navigation list and index to the newly saved code
        LET ok = select_warehouses("1=1")
        CALL set_curr_idx_by_code(rec_wh.wh_code)
    ELSE
        UPDATE wh01_mast
            SET wh01_mast.* = rec_wh.*
            WHERE wh_code = rec_wh.wh_code
        CALL utils_globals.show_info("Record updated.")
        -- keep current index; reload to reflect changes
        CALL load_warehouse(rec_wh.wh_code)
    END IF
END FUNCTION

-- ===========================================
-- Separate function for data dialog
-- ===========================================
FUNCTION edit_warehouse()
    --DEFINE ok SMALLINT

    DIALOG ATTRIBUTES(UNBUFFERED)

        INPUT BY NAME rec_wh.* ATTRIBUTES(WITHOUT DEFAULTS, NAME = "creditors")

            BEFORE INPUT

            ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
                CALL save_warehouse()
                EXIT DIALOG

            ON ACTION cancel
                EXIT DIALOG

            AFTER FIELD supp_name
                IF rec_wh.wh_name IS NULL OR rec_wh.wh_name = "" THEN
                    CALL utils_globals.show_error("Supplier Name is required.")
                    NEXT FIELD supp_name
                END IF

        END INPUT

    END DIALOG
END FUNCTION

-- ==============================================================
-- Delete Warehouse
-- ==============================================================
FUNCTION delete_warehouse()
    DEFINE ok SMALLINT

    IF rec_wh.wh_code IS NULL OR rec_wh.wh_code = "" THEN
        CALL utils_globals.show_info("No warehouse selected for deletion.")
        RETURN
    END IF

    LET ok =
        utils_globals.show_confirm(
            "Delete warehouse: "
                || rec_wh.wh_name
                || " ("
                || rec_wh.wh_code
                || ")?",
            "Confirm Delete")

    IF NOT ok THEN
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    DELETE FROM wh01_mast WHERE wh_code = rec_wh.wh_code
    IF SQLCA.SQLCODE = 0 THEN
        CALL utils_globals.show_info("Record deleted.")
    ELSE
        CALL utils_globals.show_info("Delete failed.")
        RETURN
    END IF

    IF NOT select_warehouses("1=1") THEN
        -- Nothing left; clear the form
        INITIALIZE rec_wh.* TO NULL
        DISPLAY BY NAME rec_wh.*
        LET curr_idx = 0
    END IF
END FUNCTION
