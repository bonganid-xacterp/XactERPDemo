-- ==============================================================
-- Program   : wh101_mast.4gl
-- Purpose   : Warehouse Master Maintenance (CRUD)
-- Module    : Warehouse (wh)
-- Number    : 101
-- Author    : Bongani Dlamini
-- Version   : Genero BDL 3.20.10
-- Description:
--   Master maintenance for warehouses.
--   Provides full CRUD operations, lookup, and navigation.
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL wh121_lkup

SCHEMA demoapp_db

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE warehouse_t RECORD LIKE wh01_mast.*
DEFINE rec_wh warehouse_t

-- Array for warehouse bins (read-only list in the form)
DEFINE arr_wh_bins DYNAMIC ARRAY OF RECORD
    wb_code     LIKE wb01_mast.wb_code,
    description LIKE wb01_mast.description,
    status      LIKE wb01_mast.status
END RECORD

-- Navigation helpers
DEFINE arr_codes  DYNAMIC ARRAY OF STRING
DEFINE curr_idx   INTEGER
DEFINE is_edit_mode SMALLINT

-- ==============================================================
-- MAIN
-- ==============================================================
MAIN
    IF NOT utils_globals.initialize_application() THEN
        CALL utils_globals.show_error("Initialization failed.")
        EXIT PROGRAM 1
    END IF

    -- Open as dialog when standalone, child otherwise
    IF utils_globals.is_standalone() THEN
        OPEN WINDOW w_wh101 WITH FORM "wh101_mast" ATTRIBUTES(STYLE="normal")
    ELSE
        OPEN WINDOW w_wh101 WITH FORM "wh101_mast" ATTRIBUTES(STYLE="child")
    END IF

    CALL init_wh_module()

    IF utils_globals.is_standalone() THEN
        CLOSE WINDOW w_wh101
    END IF
END MAIN

-- ==============================================================
-- Module Controller
-- ==============================================================
FUNCTION init_wh_module()
    LET is_edit_mode = FALSE
    CALL utils_globals.set_form_label("lbl_title", "WAREHOUSE MAINTENANCE")
    INITIALIZE rec_wh.* TO NULL
    DISPLAY BY NAME rec_wh.*
    MENU "Warehouse Menu"
        COMMAND "Find"       CALL query_warehouses(); LET is_edit_mode = FALSE
        COMMAND "New"        CALL new_warehouse();    LET is_edit_mode = FALSE
        COMMAND "Edit"       
                IF rec_wh.wh_code IS NULL OR rec_wh.wh_code = "" 
                THEN 
                CALL utils_globals.show_info("No warehouse selected to edit.") 
                ELSE LET is_edit_mode = TRUE; 
                CALL edit_warehouse() END IF
        COMMAND "Delete"     CALL delete_warehouse(); LET is_edit_mode = FALSE
        COMMAND "Previous"   CALL move_record(-1)
        COMMAND "Next"       CALL move_record(1)
        COMMAND "Exit"       EXIT MENU
    END MENU
END FUNCTION

-- ==============================================================
-- Load all warehouses into navigation array; load first
-- ==============================================================
PRIVATE FUNCTION load_all_records()
    DEFINE ok SMALLINT
    LET ok = load_first_record("1=1")

    IF ok THEN
        MESSAGE SFMT("Loaded %1 warehouse(s)", arr_codes.getLength())
    ELSE
        CALL utils_globals.show_info("No warehouses found.")
        INITIALIZE rec_wh.* TO NULL
        DISPLAY BY NAME rec_wh.*
        CALL arr_wh_bins.clear()
    END IF
END FUNCTION

-- ==============================================================
-- Query via Lookup (popup)
-- ==============================================================
FUNCTION query_warehouses()

    DEFINE selected_code STRING
    DEFINE found_idx, i INTEGER

    LET selected_code = wh121_lkup.fetch_list()

    IF selected_code IS NULL OR selected_code = "" THEN
        RETURN
    END IF

    LET found_idx = 0
    FOR i = 1 TO arr_codes.getLength()
        IF arr_codes[i] = selected_code THEN
            LET found_idx = i
            EXIT FOR
        END IF
    END FOR

    IF found_idx > 0 THEN
        LET curr_idx = found_idx
        CALL load_single_record(selected_code)
    ELSE
        CALL load_all_records()
        FOR i = 1 TO arr_codes.getLength()
            IF arr_codes[i] = selected_code THEN
                LET curr_idx = i
                EXIT FOR
            END IF
        END FOR
        CALL load_single_record(selected_code)
    END IF

END FUNCTION

-- ==============================================================
-- Fill arr_codes according to where clause and load first
-- ==============================================================
FUNCTION load_first_record(where_clause STRING) RETURNS SMALLINT
    DEFINE code STRING
    DEFINE idx  INTEGER
    DEFINE sql_stmt STRING

    CALL arr_codes.clear()
    LET idx = 0
    LET sql_stmt = "SELECT wh_code FROM wh01_mast"

    IF where_clause IS NOT NULL AND where_clause <> "" THEN
        LET sql_stmt = sql_stmt || " WHERE " || where_clause
    END IF

    LET sql_stmt = sql_stmt || " ORDER BY wh_code"

    PREPARE stmt_select FROM sql_stmt
    DECLARE c_curs CURSOR FOR stmt_select

    FOREACH c_curs INTO code
        LET idx = idx + 1
        LET arr_codes[idx] = code
    END FOREACH

    CLOSE c_curs
    FREE c_curs
    FREE stmt_select

    IF arr_codes.getLength() = 0 THEN
        CALL utils_globals.msg_no_record()
        RETURN FALSE
    END IF

    LET curr_idx = 1
    CALL load_single_record(arr_codes[curr_idx])
    RETURN TRUE
END FUNCTION

-- ==============================================================
-- Load a single warehouse and its bins
-- ==============================================================
FUNCTION load_single_record(p_code STRING)
    DEFINE l_sqlcode INTEGER

    SELECT id, wh_code, wh_name, location, status, created_at, created_by, updated_at
      INTO rec_wh.id, rec_wh.wh_code, rec_wh.wh_name, rec_wh.location,
           rec_wh.status, rec_wh.created_at, rec_wh.created_by, rec_wh.updated_at
      FROM wh01_mast
     WHERE wh_code = p_code

    LET l_sqlcode = SQLCA.SQLCODE

    IF l_sqlcode = 0 THEN
        DISPLAY BY NAME rec_wh.*
        MESSAGE SFMT("Loaded warehouse: %1 (%2)", rec_wh.wh_code, rec_wh.wh_name)
        CALL load_warehouse_bins(rec_wh.id)
    ELSE
        MESSAGE SFMT("Warehouse not found (%1)", SQLCA.SQLCODE)
        INITIALIZE rec_wh.* TO NULL
        DISPLAY BY NAME rec_wh.*
        CALL arr_wh_bins.clear()
    END IF
END FUNCTION

-- ==============================================================
-- Load bins for a warehouse (read-only detail grid)
-- ==============================================================
FUNCTION load_warehouse_bins(p_wh_id INTEGER)
    DEFINE idx INTEGER

    CALL arr_wh_bins.clear()

    DECLARE c_bins CURSOR FOR
        SELECT wb_code, description, status
          FROM wb01_mast
         WHERE wh_id = p_wh_id
         ORDER BY wb_code

    LET idx = 1
    FOREACH c_bins INTO arr_wh_bins[idx].wb_code,
                        arr_wh_bins[idx].description,
                        arr_wh_bins[idx].status
        LET idx = idx + 1
    END FOREACH

    CLOSE c_bins
    FREE c_bins

    IF arr_wh_bins.getLength() > 0 THEN
        MESSAGE SFMT("Warehouse has %1 bin(s)", arr_wh_bins.getLength())
    ELSE
        MESSAGE "No bins found in this warehouse"
    END IF
END FUNCTION

-- ==============================================================
-- Navigation (uses global navigate helper)
-- dir: -1 prev, +1 next; supports -2 first, +2 last if your util does
-- ==============================================================
PRIVATE FUNCTION move_record(dir SMALLINT)
    DEFINE new_idx INTEGER

    IF arr_codes.getLength() = 0 THEN
        CALL utils_globals.show_info("No records to navigate.")
        RETURN
    END IF

    LET new_idx = utils_globals.navigate_records(arr_codes, curr_idx, dir)
    LET curr_idx = new_idx
    CALL load_single_record(arr_codes[curr_idx])
END FUNCTION

-- ==============================================================
-- New Warehouse (Dialog with Save/Cancel)
-- ==============================================================
FUNCTION new_warehouse()
    DEFINE dup_found SMALLINT
    DEFINE new_id    INTEGER
    DEFINE next_num  INTEGER
    DEFINE next_full STRING
    DEFINE i, array_size INTEGER

    -- Start fresh record defaults
    INITIALIZE rec_wh.* TO NULL

    -- Generate code using your global helper (prefix WH)
    CALL utils_globals.get_next_number("wh01_mast", "WH")
        RETURNING next_num, next_full

    LET rec_wh.wh_code    = next_full
    LET rec_wh.status     = "active"
    LET rec_wh.created_at = CURRENT
    LET rec_wh.created_by = utils_globals.get_current_user_id()

    CALL utils_globals.set_form_label("lbl_title", "NEW WAREHOUSE")

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_wh.* ATTRIBUTES(WITHOUT DEFAULTS, NAME="new_warehouse")

            -- Save button shows in the dialog button bar
            ON ACTION save ATTRIBUTES(TEXT="Save", IMAGE="filesave")
                LET dup_found = check_warehouse_unique(rec_wh.wh_code)
                IF dup_found = 0 THEN
                    CALL insert_warehouse()   -- explicit INSERT + RETURNING
                    LET new_id = rec_wh.id
                    EXIT DIALOG
                ELSE
                    CALL utils_globals.show_error("Duplicate warehouse found.")
                END IF

            ON ACTION cancel ATTRIBUTES(TEXT="Cancel", IMAGE="cancel")
                CALL utils_globals.show_info("Creation cancelled.")
                LET new_id = NULL
                EXIT DIALOG

        END INPUT
    END DIALOG

    -- Reload list and reposition on newly created code, else restore selection
    IF new_id IS NOT NULL THEN
        CALL load_all_records()
        LET array_size = arr_codes.getLength()
        IF array_size > 0 THEN
            FOR i = 1 TO array_size
                IF arr_codes[i] = rec_wh.wh_code THEN
                    LET curr_idx = i
                    EXIT FOR
                END IF
            END FOR
        END IF
        CALL load_single_record(rec_wh.wh_code)
    ELSE
        LET array_size = arr_codes.getLength()
        IF array_size > 0 AND curr_idx >= 1 AND curr_idx <= array_size THEN
            CALL load_single_record(arr_codes[curr_idx])
        ELSE
            LET curr_idx = 0
            INITIALIZE rec_wh.* TO NULL
            DISPLAY BY NAME rec_wh.*
        END IF
    END IF

    CALL utils_globals.set_form_label("lbl_title", "WAREHOUSE MAINTENANCE")
END FUNCTION

-- ==============================================================
-- Edit Warehouse (Dialog with Update/Cancel)
-- ==============================================================
FUNCTION edit_warehouse()
    CALL utils_globals.set_form_label("lbl_title", "EDIT WAREHOUSE")

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_wh.* ATTRIBUTES(WITHOUT DEFAULTS, NAME="edit_warehouse")

            BEFORE FIELD wh_code
                NEXT FIELD wh_name

            AFTER FIELD wh_name
                IF rec_wh.wh_name IS NULL OR rec_wh.wh_name = "" THEN
                    CALL utils_globals.show_error("Warehouse Name is required.")
                    NEXT FIELD wh_name
                END IF

            ON ACTION save ATTRIBUTES(TEXT="Update", IMAGE="filesave")
                CALL update_warehouse()
                EXIT DIALOG

            ON ACTION cancel ATTRIBUTES(TEXT="Cancel", IMAGE="cancel")
                CALL load_single_record(rec_wh.wh_code)
                EXIT DIALOG

        END INPUT
    END DIALOG

    CALL utils_globals.set_form_label("lbl_title", "WAREHOUSE MAINTENANCE")
END FUNCTION

-- ==============================================================
-- Insert (explicit column list, safe; PostgreSQL RETURNING)
-- ==============================================================
FUNCTION insert_warehouse()
    BEGIN WORK
    TRY
        INSERT INTO wh01_mast
        VALUES
            rec_wh.*

        COMMIT WORK
        CALL utils_globals.msg_saved()
        CALL load_single_record(rec_wh.wh_code)
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(SFMT("Insert failed: %1", SQLCA.SQLCODE))
    END TRY
END FUNCTION

-- ==============================================================
-- Update (explicit list; keep updated_at current)
-- ==============================================================
FUNCTION update_warehouse()
    BEGIN WORK
    TRY
        LET rec_wh.updated_at = CURRENT

        UPDATE wh01_mast
           SET wh_name   = rec_wh.wh_name,
               location   = rec_wh.location,
               status     = rec_wh.status,
               updated_at = rec_wh.updated_at
         WHERE wh_code   = rec_wh.wh_code

        COMMIT WORK
        CALL utils_globals.msg_updated()
        CALL load_single_record(rec_wh.wh_code)
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(SFMT("Update failed: %1", SQLCA.SQLCODE))
    END TRY
END FUNCTION

-- ==============================================================
-- Delete Warehouse (with bin dependency check)
-- ==============================================================
FUNCTION delete_warehouse()
    DEFINE ok SMALLINT
    DEFINE deleted_code STRING
    DEFINE array_size   INTEGER
    DEFINE bin_count    INTEGER

    IF rec_wh.wh_code IS NULL OR rec_wh.wh_code = "" THEN
        CALL utils_globals.show_info("No warehouse selected for deletion.")
        RETURN
    END IF

    -- Prevent delete if bins exist
    SELECT COUNT(*) INTO bin_count FROM wb01_mast WHERE wh_id = rec_wh.id
    IF bin_count > 0 THEN
        CALL utils_globals.show_error(
            SFMT("Cannot delete warehouse. It has %1 bin(s).", bin_count))
        RETURN
    END IF

    LET ok = utils_globals.show_confirm(
        "Delete this warehouse: " || rec_wh.wh_name || "?", "Confirm Delete")

    IF NOT ok THEN
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    LET deleted_code = rec_wh.wh_code

    BEGIN WORK
    TRY
        DELETE FROM wh01_mast WHERE wh_code = deleted_code
        COMMIT WORK
        CALL utils_globals.msg_deleted()
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(SFMT("Delete failed: %1", SQLCA.SQLCODE))
        RETURN
    END TRY

    CALL load_all_records()
    LET array_size = arr_codes.getLength()

    IF array_size > 0 THEN
        IF curr_idx > array_size THEN LET curr_idx = array_size END IF
        IF curr_idx < 1 THEN LET curr_idx = 1 END IF
        CALL load_single_record(arr_codes[curr_idx])
    ELSE
        LET curr_idx = 0
        INITIALIZE rec_wh.* TO NULL
        DISPLAY BY NAME rec_wh.*
        CALL arr_wh_bins.clear()
    END IF
END FUNCTION

-- ==============================================================
-- Check uniqueness by wh_code (returns 1 if duplicate)
-- ==============================================================
FUNCTION check_warehouse_unique(p_wh_code STRING) RETURNS SMALLINT
    DEFINE dup_count INTEGER
    SELECT COUNT(*) INTO dup_count FROM wh01_mast WHERE wh_code = p_wh_code
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Warehouse code already exists.")
        RETURN 1
    END IF
    RETURN 0
END FUNCTION
