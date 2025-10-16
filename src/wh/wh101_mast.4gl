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
TYPE warehouse_t RECORD
    wh_code LIKE wh01_mast.wh_code, -- Warehouse code (primary key)
    wh_name LIKE wh01_mast.wh_name, -- Warehouse name
    location LIKE wh01_mast.location, -- Physical location
    status LIKE wh01_mast.status -- Status (1=Active, 0=Inactive)
END RECORD

DEFINE rec_wh warehouse_t
DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE can_save SMALLINT -- TRUE when creating or editing (enables Save)

DEFINE dlg ui.Dialog

-- ==============================================================
-- Main
-- ==============================================================
MAIN
    IF NOT utils_globals.initialize_application() THEN
        DISPLAY "Initialization failed."
        EXIT PROGRAM 1
    END IF

    OPEN WINDOW w_wh101 WITH FORM "wh101_mast" ATTRIBUTES(STYLE = "main")
    CALL init_module()
    CLOSE WINDOW w_wh101
END MAIN

-- ==============================================================
-- DIALOG Controller
-- ==============================================================
FUNCTION init_module()
    DEFINE ok SMALLINT
    DEFINE code STRING

    CALL utils_status_const.populate_status_combobox()
    LET can_save = FALSE

    DIALOG ATTRIBUTES(UNBUFFERED)

        -- Bind the record to the form
        INPUT BY NAME rec_wh.* ATTRIBUTES(WITHOUT DEFAULTS, NAME = "warehouse")

            -- -----------------------
            -- Entering input phase
            -- -----------------------
            BEFORE INPUT
                LET can_save = FALSE
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)

                -- -----------------------
                -- Lookup / Find
                -- -----------------------
            ON ACTION find ATTRIBUTES(TEXT = "Search", IMAGE = "zoom")
                LET code = query_warehouse()
                IF code IS NOT NULL AND code <> "" THEN
                    CALL load_warehouse(code)
                    CALL set_curr_idx_by_code(code)
                ELSE
                    CALL utils_globals.show_info("No record selected.")
                END IF
                LET can_save = FALSE
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)

                -- -----------------------
                -- Create new record
                -- -----------------------
            ON ACTION new ATTRIBUTES(TEXT = "Create", IMAGE = "new")
                CALL new_warehouse()
                -- For NEW we allow editing immediately and enable Save
                LET can_save = TRUE
                CALL dlg.setActionActive("save", TRUE)
                CALL dlg.setActionActive("edit", FALSE)

                -- -----------------------
                -- Enter Edit mode
                -- -----------------------
            ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
                IF rec_wh.wh_code IS NULL OR rec_wh.wh_code = "" THEN
                    CALL utils_globals.show_info("No record selected to edit.")
                ELSE
                    LET can_save = TRUE
                    CALL dlg.setActionActive("save", TRUE)
                    CALL dlg.setActionActive("edit", FALSE)
                    MESSAGE "Edit mode enabled. Make changes and click Update to save."
                END IF

                -- -----------------------
                -- Save (Insert or Update)
                -- -----------------------
            ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
                IF can_save THEN
                    CALL save_warehouse()
                    LET can_save = FALSE
                    CALL dlg.setActionActive("save", FALSE)
                    CALL dlg.setActionActive("edit", TRUE)
                END IF

                -- -----------------------
                -- Delete current record
                -- -----------------------
            ON ACTION DELETE ATTRIBUTES(TEXT = "Delete", IMAGE = "delete")
                CALL delete_warehouse()
                LET can_save = FALSE
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)

                -- -----------------------
                -- Navigation
                -- -----------------------
            ON ACTION FIRST ATTRIBUTES(TEXT = "First Record", IMAGE = "first")
                CALL move_record(-2)
                LET can_save = FALSE
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)

            ON ACTION PREVIOUS ATTRIBUTES(TEXT = "Previous", IMAGE = "prev")
                CALL move_record(-1)
                LET can_save = FALSE
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)

            ON ACTION NEXT ATTRIBUTES(TEXT = "Next", IMAGE = "next")
                CALL move_record(1)
                LET can_save = FALSE
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)

            ON ACTION LAST ATTRIBUTES(TEXT = "Last Record", IMAGE = "last")
                CALL move_record(2)
                LET can_save = FALSE
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)

                -- -----------------------
                -- Exit dialog
                -- -----------------------
            ON ACTION QUIT ATTRIBUTES(TEXT = "Quit", IMAGE = "quit")
                EXIT DIALOG

                -- -----------------------
                -- Guard fields when not in edit/new mode
                -- -----------------------
            BEFORE FIELD wh_name, location, status
                IF NOT can_save THEN
                    CALL utils_globals.show_info(
                        "Click New or Edit to modify this record.")
                    NEXT FIELD wh_code
                END IF

        END INPUT

        -- Load list on dialog start
        BEFORE DIALOG
            LET ok = select_warehouses("1=1")
            LET can_save = FALSE

    END DIALOG
END FUNCTION

-- ==============================================================
-- Lookup popup
-- ==============================================================
FUNCTION query_warehouse() RETURNS STRING
    DEFINE selected_code STRING
    LET selected_code = wh121_lkup.fetch_wh_list()
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
    SELECT wh_code, wh_name, location, status
        INTO rec_wh.*
        FROM wh01_mast
        WHERE wh_code = p_code

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
    LET rec_wh.status = 1
    DISPLAY BY NAME rec_wh.*
    MESSAGE "Enter new warehouse details, then click Save."
END FUNCTION

-- ==============================================================
-- Save / Update
-- ==============================================================
FUNCTION save_warehouse()
    DEFINE v_exists INTEGER
    DEFINE ok SMALLINT

    IF rec_wh.wh_code IS NULL OR rec_wh.wh_code = "" THEN
        CALL utils_globals.show_info("Warehouse code is required.")
        RETURN
    END IF

    SELECT COUNT(*) INTO v_exists FROM wh01_mast WHERE wh_code = rec_wh.wh_code

    IF v_exists = 0 THEN
        INSERT INTO wh01_mast(
            wh_code, wh_name, location, status)
            VALUES(rec_wh.wh_code,
                rec_wh.wh_name,
                rec_wh.location,
                rec_wh.status)
        CALL utils_globals.show_info("Record saved.")
        -- refresh navigation list and index to the newly saved code
        LET ok = select_warehouses("1=1")
        CALL set_curr_idx_by_code(rec_wh.wh_code)
    ELSE
        UPDATE wh01_mast
            SET wh_name = rec_wh.wh_name,
                location = rec_wh.location,
                status = rec_wh.status
            WHERE wh_code = rec_wh.wh_code
        CALL utils_globals.show_info("Record updated.")
        -- keep current index; reload to reflect changes
        CALL load_warehouse(rec_wh.wh_code)
    END IF
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
