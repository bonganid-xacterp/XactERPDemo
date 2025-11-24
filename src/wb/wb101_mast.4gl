-- ==============================================================
-- Program      : wb101_mast.4gl
-- Purpose      : Warehouse Bin Master maintenance (CRUD operations)
-- Module       : Warehouse Bin (wb)
-- Number       : 101
-- Author       : Bongani Dlamini
-- Version      : Genero ver 3.20.10
-- Description  : Master file maintenance for warehouse bins
--                  Provides full CRUD operations for bin records
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL wh121_lkup
IMPORT FGL wb121_lkup
IMPORT FGL utils_global_lkup_form

SCHEMA demoappdb

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE bin_t RECORD LIKE wb01_mast.*
DEFINE wbin_rec bin_t
DEFINE rec_wh_code STRING

DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

-- ==============================================================
-- MAIN (Standalone or Child Mode)
-- ==============================================================
MAIN
    IF NOT utils_globals.initialize_application() THEN
        CALL utils_globals.show_error("Initialization failed.")
        EXIT PROGRAM 1
    END IF

    IF utils_globals.is_standalone() THEN
        OPEN WINDOW w_wb101 WITH FORM "wb101_mast" -- ATTRIBUTES(STYLE = "normal")
    ELSE
        OPEN WINDOW w_wb101 WITH FORM "wb101_mast" ATTRIBUTES(STYLE = "child")
    END IF

    CALL init_wb_module()

    IF utils_globals.is_standalone() THEN
        CLOSE WINDOW w_wb101
    END IF
END MAIN

-- ==============================================================
-- Main Controller Menu
-- ==============================================================
FUNCTION init_wb_module()
    LET is_edit_mode = FALSE
    CALL utils_globals.set_form_label("lbl_title", "WAREHOUSE BIN MAINTENANCE")

    -- Initialize the list of records
    CALL load_all_bins()

    MENU "Bin Menu"

        COMMAND "Find"
            CALL query_bins()
            LET is_edit_mode = FALSE

        COMMAND "New"
            CALL new_bin()
            LET is_edit_mode = FALSE

        COMMAND "Edit"
            IF wbin_rec.wb_code IS NULL OR wbin_rec.wb_code = "" THEN
                CALL utils_globals.show_info("No bin selected to edit.")
            ELSE
                LET is_edit_mode = TRUE
                CALL edit_bin()
            END IF

        COMMAND "Delete"
            CALL delete_bin()
            LET is_edit_mode = FALSE

        COMMAND "Previous"
            CALL move_record(-1)

        COMMAND "Next"
            CALL move_record(1)

        COMMAND "Exit"
            EXIT MENU
    END MENU
END FUNCTION

-- ==============================================================
-- Load all bins into array
-- ==============================================================
PRIVATE FUNCTION load_all_bins()
    DEFINE ok SMALLINT
    LET ok = select_bins("1=1")

    IF ok THEN
        MESSAGE SFMT("Loaded %1 bin(s)", arr_codes.getLength())
    ELSE
        CALL utils_globals.show_info("No bins found.")
        INITIALIZE wbin_rec.* TO NULL
        LET rec_wh_code = NULL
        DISPLAY BY NAME wbin_rec.*
    END IF
END FUNCTION

-- ==============================================================
-- Query bins using lookup
-- ==============================================================
FUNCTION query_bins()
    DEFINE selected_code STRING

    LET selected_code = utils_global_lkup_form.display_lookup('bin')

    IF selected_code IS NULL OR selected_code = "" THEN
        RETURN
    END IF

    CALL load_bin(selected_code)

    CALL arr_codes.clear()
    LET arr_codes[1] = selected_code
    LET curr_idx = 1
END FUNCTION

-- ==============================================================
-- Select bins into array
-- ==============================================================
FUNCTION select_bins(where_clause STRING) RETURNS SMALLINT
    DEFINE code STRING
    DEFINE idx INTEGER
    DEFINE sql_stmt STRING

    -- Input validation for where_clause
    IF where_clause IS NOT NULL AND where_clause != "" THEN
        IF where_clause MATCHES ".*[;'\"].*" THEN
            CALL utils_globals.show_error("Invalid characters in search criteria")
            RETURN FALSE
        END IF
    END IF

    CALL arr_codes.clear()
    LET idx = 0
    LET sql_stmt = "SELECT wb_code FROM wb01_mast"

    IF where_clause IS NOT NULL AND where_clause != "" THEN
        LET sql_stmt = sql_stmt || " WHERE " || where_clause
    END IF

    LET sql_stmt = sql_stmt || " ORDER BY wb_code"

    PREPARE stmt_select FROM sql_stmt
    DECLARE c_curs CURSOR FOR stmt_select

    FOREACH c_curs INTO code
        LET idx = idx + 1
        LET arr_codes[idx] = code
    END FOREACH

    CLOSE c_curs
    FREE c_curs
    FREE stmt_select

    IF arr_codes.getLength() == 0 THEN
        CALL utils_globals.msg_no_record()
        RETURN FALSE
    END IF

    LET curr_idx = 1
    CALL load_bin(arr_codes[curr_idx])
    RETURN TRUE
END FUNCTION

-- ==============================================================
-- Load Single Bin
-- ==============================================================
FUNCTION load_bin(p_code STRING)
    SELECT wb01_mast.*, wh01_mast.wh_code
        INTO wbin_rec.*, rec_wh_code
        FROM wb01_mast LEFT JOIN wh01_mast ON wb01_mast.wh_id = wh01_mast.id
        WHERE wb01_mast.wb_code = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME wbin_rec.*
        DISPLAY rec_wh_code TO wh01_mast.wh_code
    ELSE
        INITIALIZE wbin_rec.* TO NULL
        LET rec_wh_code = NULL
        DISPLAY BY NAME wbin_rec.*
        DISPLAY rec_wh_code TO wh01_mast.wh_code
    END IF
END FUNCTION

-- ==============================================================
-- Navigation
-- ==============================================================
PRIVATE FUNCTION move_record(dir SMALLINT)
    DEFINE new_idx INTEGER

    IF arr_codes.getLength() == 0 THEN
        CALL utils_globals.show_info("No records to navigate.")
        RETURN
    END IF

    LET new_idx = utils_globals.navigate_records(arr_codes, curr_idx, dir)
    LET curr_idx = new_idx
    CALL load_bin(arr_codes[curr_idx])
END FUNCTION

-- ==============================================================
-- New Bin
-- ==============================================================
FUNCTION new_bin()
    DEFINE dup_found SMALLINT
    DEFINE new_id INTEGER  -- Changed from SMALLINT to INTEGER
    DEFINE next_num INTEGER
    DEFINE next_full STRING
    DEFINE i, array_size INTEGER

    INITIALIZE wbin_rec.* TO NULL
    LET rec_wh_code = NULL

    CALL utils_globals.get_next_number("wb01_mast", "WB")
        RETURNING next_num, next_full

    LET wbin_rec.wb_code = next_full
    LET wbin_rec.status = "active"
    LET wbin_rec.created_at = CURRENT
    LET wbin_rec.created_by = utils_globals.get_current_user_id()

    CALL utils_globals.set_form_label("lbl_title", "NEW WAREHOUSE BIN")

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME wbin_rec.* ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_bin")

            AFTER FIELD wb_code
                IF wbin_rec.wb_code IS NULL OR wbin_rec.wb_code = "" THEN
                    CALL utils_globals.show_error("Bin Code is required.")
                    NEXT FIELD wb_code
                END IF

            AFTER FIELD description
                IF wbin_rec.description IS NULL OR wbin_rec.description = "" THEN
                    CALL utils_globals.show_error("Description is required.")
                    NEXT FIELD description
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Save", IMAGE = "filesave")
                LET dup_found = check_bin_unique(wbin_rec.wb_code)
                IF dup_found = 0 THEN
                    CALL save_bin()
                    LET new_id = wbin_rec.id
                    CALL utils_globals.show_info("Bin saved successfully.")
                    EXIT DIALOG
                ELSE
                    CALL utils_globals.show_error("Duplicate bin found.")
                END IF

            ON ACTION cancel
                CALL utils_globals.show_info("Creation cancelled.")
                LET new_id = 0  -- Use 0 instead of NULL for INTEGER
                EXIT DIALOG

        END INPUT

        INPUT rec_wh_code FROM wh01_mast.wh_code
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_bin_wh")

            AFTER FIELD wh_code
                IF rec_wh_code IS NOT NULL AND rec_wh_code != "" THEN
                    CALL validate_warehouse_code(rec_wh_code)
                        RETURNING wbin_rec.wh_id
                    IF wbin_rec.wh_id IS NULL OR wbin_rec.wh_id = 0 THEN
                        CALL utils_globals.show_error("Invalid Warehouse Code.")
                        LET rec_wh_code = NULL
                        NEXT FIELD wh_code
                    END IF
                END IF

            ON ACTION lookup_warehouse ATTRIBUTES(TEXT="Warehouse Lookup", IMAGE="zoom")
                CALL find_wh() RETURNING rec_wh_code
                IF rec_wh_code IS NOT NULL AND rec_wh_code != "" THEN
                    CALL validate_warehouse_code(rec_wh_code)
                        RETURNING wbin_rec.wh_id
                    IF wbin_rec.wh_id IS NOT NULL AND wbin_rec.wh_id > 0 THEN
                        DISPLAY rec_wh_code TO wh01_mast.wh_code
                        MESSAGE SFMT("Warehouse %1 selected", rec_wh_code)
                    ELSE
                        CALL utils_globals.show_error("Invalid Warehouse Code.")
                        LET rec_wh_code = NULL
                    END IF
                END IF
        END INPUT
    END DIALOG

    -- Reload the list and position to the new record
    IF new_id IS NOT NULL AND new_id > 0 THEN
        CALL load_all_bins()
        LET array_size = arr_codes.getLength()
        IF array_size > 0 THEN
            FOR i = 1 TO array_size
                IF arr_codes[i] = wbin_rec.wb_code THEN
                    LET curr_idx = i
                    EXIT FOR
                END IF
            END FOR
        END IF
        CALL load_bin(wbin_rec.wb_code)
    ELSE
        LET array_size = arr_codes.getLength()
        IF array_size > 0 AND curr_idx >= 1 AND curr_idx <= array_size THEN
            CALL load_bin(arr_codes[curr_idx])
        ELSE
            LET curr_idx = 0
            INITIALIZE wbin_rec.* TO NULL
            LET rec_wh_code = NULL
            DISPLAY BY NAME wbin_rec.*
            DISPLAY rec_wh_code TO wh01_mast.wh_code
        END IF
    END IF

    CALL utils_globals.set_form_label("lbl_title", "WAREHOUSE BIN MAINTENANCE")
END FUNCTION

-- ==============================================================
-- Edit Bin
-- ==============================================================
FUNCTION edit_bin()
    CALL utils_globals.set_form_label("lbl_title", "EDIT WAREHOUSE BIN")

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME wbin_rec.* ATTRIBUTES(WITHOUT DEFAULTS, NAME = "edit_bin")

            BEFORE FIELD wb_code
                -- Bin code should not be editable
                CALL utils_globals.show_info("Bin Code cannot be changed.")
                NEXT FIELD description

            ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
                CALL save_bin()
                EXIT DIALOG

            ON ACTION cancel
                CALL load_bin(wbin_rec.wb_code)
                EXIT DIALOG

            AFTER FIELD description
                IF wbin_rec.description IS NULL OR wbin_rec.description = "" THEN
                    CALL utils_globals.show_error("Description is required.")
                    NEXT FIELD description
                END IF

        END INPUT

        INPUT rec_wh_code FROM wh01_mast.wh_code
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "edit_bin_wh")

            AFTER FIELD wh_code
                IF rec_wh_code IS NOT NULL AND rec_wh_code != "" THEN
                    CALL validate_warehouse_code(rec_wh_code)
                        RETURNING wbin_rec.wh_id
                    IF wbin_rec.wh_id IS NULL OR wbin_rec.wh_id = 0 THEN
                        CALL utils_globals.show_error("Invalid Warehouse Code.")
                        LET rec_wh_code = NULL
                        NEXT FIELD wh_code
                    END IF
                END IF

            ON ACTION lookup_warehouse ATTRIBUTES(TEXT="Warehouse Lookup", IMAGE="zoom")
                CALL find_wh() RETURNING rec_wh_code
                IF rec_wh_code IS NOT NULL AND rec_wh_code != "" THEN
                    CALL validate_warehouse_code(rec_wh_code)
                        RETURNING wbin_rec.wh_id
                    IF wbin_rec.wh_id IS NOT NULL AND wbin_rec.wh_id > 0 THEN
                        DISPLAY rec_wh_code TO wh01_mast.wh_code
                        MESSAGE SFMT("Warehouse %1 selected", rec_wh_code)
                    ELSE
                        CALL utils_globals.show_error("Invalid Warehouse Code.")
                        LET rec_wh_code = NULL
                    END IF
                END IF
        END INPUT
    END DIALOG

    CALL utils_globals.set_form_label("lbl_title", "WAREHOUSE BIN MAINTENANCE")
END FUNCTION

-- ==============================================================
-- Save / Update
-- ==============================================================
FUNCTION save_bin()
    DEFINE exists INTEGER

    BEGIN WORK
    TRY
        SELECT COUNT(*)
            INTO exists
            FROM wb01_mast
            WHERE wb_code = wbin_rec.wb_code

        IF exists = 0 THEN
            INSERT INTO wb01_mast VALUES wbin_rec.*
            COMMIT WORK
            CALL utils_globals.msg_saved()
        ELSE
            LET wbin_rec.updated_at = CURRENT
            UPDATE wb01_mast
                SET wh_id = wbin_rec.wh_id,
                    description = wbin_rec.description,
                    status = wbin_rec.status,
                    updated_at = wbin_rec.updated_at
                WHERE wb_code = wbin_rec.wb_code
            COMMIT WORK
            CALL utils_globals.msg_updated()
        END IF

        CALL load_bin(wbin_rec.wb_code)

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(SFMT("Save failed: Error %1 - %2", 
                                          SQLCA.SQLCODE, SQLCA.SQLERRM))
    END TRY
END FUNCTION

-- ==============================================================
-- Delete Bin
-- ==============================================================
FUNCTION delete_bin()
    DEFINE ok SMALLINT
    DEFINE deleted_code STRING
    DEFINE array_size INTEGER
    DEFINE in_use INTEGER

    IF wbin_rec.wb_code IS NULL OR wbin_rec.wb_code = "" THEN
        CALL utils_globals.show_info("No bin selected for deletion.")
        RETURN
    END IF

    -- Check if bin is being used in other tables (foreign key constraints)
    -- Add your specific foreign key checks here based on your schema
    -- Example:
    -- SELECT COUNT(*) INTO in_use FROM inventory_table WHERE bin_code = wbin_rec.wb_code
    -- IF in_use > 0 THEN
    --     CALL utils_globals.show_error("Cannot delete - bin has inventory records")
    --     RETURN
    -- END IF

    LET ok =
        utils_globals.show_confirm(
            "Delete this bin: " || wbin_rec.description || "?", "Confirm Delete")

    IF NOT ok THEN
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    LET deleted_code = wbin_rec.wb_code

    BEGIN WORK
    TRY
        DELETE FROM wb01_mast WHERE wb_code = deleted_code
        COMMIT WORK
        CALL utils_globals.msg_deleted()
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(SFMT("Delete failed: Error %1 - %2", 
                                          SQLCA.SQLCODE, SQLCA.SQLERRM))
        RETURN
    END TRY

    -- Reload list and navigate to valid record
    CALL load_all_bins()
    LET array_size = arr_codes.getLength()

    IF array_size > 0 THEN
        IF curr_idx > array_size THEN
            LET curr_idx = array_size
        END IF
        IF curr_idx < 1 THEN
            LET curr_idx = 1
        END IF
        CALL load_bin(arr_codes[curr_idx])
    ELSE
        LET curr_idx = 0
        INITIALIZE wbin_rec.* TO NULL
        LET rec_wh_code = NULL
        DISPLAY BY NAME wbin_rec.*
        DISPLAY rec_wh_code TO wh01_mast.wh_code
    END IF
END FUNCTION

-- ==============================================================
-- Check Bin Uniqueness
-- ==============================================================
FUNCTION check_bin_unique(p_wb_code STRING) RETURNS SMALLINT
    DEFINE dup_count INTEGER

    SELECT COUNT(*) INTO dup_count FROM wb01_mast WHERE wb_code = p_wb_code
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Bin code already exists.")
        RETURN 1
    END IF

    RETURN 0
END FUNCTION

-- ==============================================================
-- Validate Warehouse Code and return warehouse ID
-- ==============================================================
FUNCTION validate_warehouse_code(p_wh_code STRING) RETURNS INTEGER
    DEFINE wh_id INTEGER
    
    LET wh_id = 0  -- Initialize to 0 (invalid)

    SELECT id INTO wh_id FROM wh01_mast WHERE wh_code = p_wh_code

    IF SQLCA.SQLCODE != 0 OR wh_id IS NULL THEN
        RETURN 0  -- Return 0 for invalid warehouse code
    END IF

    RETURN wh_id
END FUNCTION

-- ==============================================================
-- Find Warehouse using Lookup
-- ==============================================================
FUNCTION find_wh() RETURNS STRING
    DEFINE selected_wh_code STRING

    LET selected_wh_code = wh121_lkup.fetch_list()

    RETURN selected_wh_code
END FUNCTION