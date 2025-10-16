-- ==============================================================
-- Program   : wb101_mast.4gl
-- Purpose   : Warehouse Bin Master maintenance (CRUD operations)
-- Module    : Warehouse Bin (wb)
-- Number    : 101
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Master file maintenance for warehouse bins
--              Provides full CRUD operations for bin records
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoapp_db

TYPE bin_t RECORD
    wb_code LIKE wb01_mast.wb_code,
    wh_id LIKE wb01_mast.wh_id,
    description LIKE wb01_mast.description,
    status LIKE wb01_mast.status
END RECORD

DEFINE rec_bin bin_t
DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT
DEFINE master_config utils_globals.master_record

--MAIN
--    IF NOT utils_globals.initialize_application() THEN
--        EXIT PROGRAM 1
--    END IF
--
--    CALL initMasterConfig()
--    OPEN WINDOW w_wb101 WITH FORM "wb101_mast" ATTRIBUTES(STYLE = "main")
--    CALL init_module()
--    CLOSE WINDOW w_wb101
--END MAIN

-- Initialize master configuration for CRUD operations
FUNCTION initMasterConfig()
    LET master_config.table_name = "wb01_mast" -- Main table name
    LET master_config.key_field = "wb_code" -- Primary key field
    LET master_config.name_field = "description" -- Display field
    LET master_config.phone_field = "" -- Not used for bins
    LET master_config.email_field = "" -- Not used for bins
END FUNCTION

-- Main module initialization and dialog handling
FUNCTION init_module()
    -- Setup status dropdown values
    CALL utils_globals.populate_status_combo("status")
    LET is_edit_mode = FALSE -- Start in view mode

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_bin.* ATTRIBUTES(WITHOUT DEFAULTS, NAME = "bin")

            BEFORE INPUT
                -- CALL MasterCRUD.setEditMode(DIALOG, FALSE)

            ON ACTION new ATTRIBUTES(TEXT = "Create", IMAGE = "new")
                CALL new_bin()

            ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
                IF utils_globals.is_empty(rec_bin.wb_code) THEN
                    CALL utils_globals.show_info("No record selected to edit.")
                ELSE
                    LET is_edit_mode = TRUE
                    -- CALL MasterCRUD.setEditMode(DIALOG, TRUE)
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
                IF is_edit_mode THEN
                    CALL save_bin()
                    LET is_edit_mode = FALSE
                    -- CALL MasterCRUD.setEditMode(DIALOG, FALSE)
                END IF

            ON ACTION DELETE ATTRIBUTES(TEXT = "Delete", IMAGE = "delete")
                CALL delete_bin()

            ON ACTION FIRST ATTRIBUTES(TEXT = "First", IMAGE = "first")
                CALL move_record(-2)
            ON ACTION PREVIOUS ATTRIBUTES(TEXT = "Previous", IMAGE = "prev")
                CALL move_record(-1)
            ON ACTION NEXT ATTRIBUTES(TEXT = "Next", IMAGE = "next")
                CALL move_record(1)
            ON ACTION LAST ATTRIBUTES(TEXT = "Last", IMAGE = "last")
                CALL move_record(2)
            ON ACTION QUIT ATTRIBUTES(TEXT = "Quit", IMAGE = "quit")
                EXIT DIALOG

            BEFORE FIELD wh_id, description, status
                IF NOT is_edit_mode THEN
                    CALL utils_globals.show_info("Click Edit to modify.")
                    NEXT FIELD wb_code
                END IF
        END INPUT

        BEFORE DIALOG
            --LET arr_codes = utils_globals.select_records(master_config.table_name, "1=1")
            --IF arr_codes.getLength() > 0 THEN
            --    LET curr_idx = 1
            --    CALL load_bin(arr_codes[curr_idx])
            --END IF
    END DIALOG
END FUNCTION

-- Load bin record by code and display on form
FUNCTION load_bin(p_code STRING)
    SELECT wb_code, wh_id, description, status
        INTO rec_bin.*
        FROM wb01_mast
        WHERE wb_code = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_bin.* -- Update form fields
    END IF
END FUNCTION

-- Navigate between records (First/Prev/Next/Last)
FUNCTION move_record(dir SMALLINT)
    LET curr_idx = utils_globals.navigate_records(arr_codes, curr_idx, dir)
    CALL load_bin(arr_codes[curr_idx]) -- Load selected record
    -- CALL MasterCRUD.setEditMode(DIALOG, FALSE)  -- Reset to view mode
    LET is_edit_mode = FALSE
END FUNCTION

-- Initialize new bin record for creation
FUNCTION new_bin()
    INITIALIZE rec_bin.* TO NULL -- Clear all fields
    LET rec_bin.status = 1 -- Default to active status
    DISPLAY BY NAME rec_bin.* -- Update form display
    LET is_edit_mode = TRUE -- Enable editing
    -- CALL MasterCRUD.setEditMode(DIALOG, TRUE)
    MESSAGE "Enter new bin details, then click Update to save."
END FUNCTION

-- Save bin record (INSERT for new, UPDATE for existing)
FUNCTION save_bin()
    DEFINE exists INTEGER

    -- Validate required fields before saving
    IF NOT validateFields() THEN
        RETURN
    END IF

    -- Check if record already exists
    SELECT COUNT(*) INTO exists FROM wb01_mast WHERE wb_code = rec_bin.wb_code

    IF exists = 0 THEN
        -- Insert new record
        INSERT INTO wb01_mast(
            wb_code, wh_id, description, status)
            VALUES(rec_bin.wb_code,
                rec_bin.wh_id,
                rec_bin.description,
                rec_bin.status)
        CALL utils_globals.msg_saved()
        -- Refresh record list and position to new record
        -- LET arr_codes = utils_globals.select_records(master_config.table_name, "1=1")

        -- CALL utils_globals.set_current_index(arr_codes, rec_bin.wb_code)
    ELSE
        -- Update existing record
        UPDATE wb01_mast
            SET wh_id = rec_bin.wh_id,
                description = rec_bin.description,
                status = rec_bin.status
            WHERE wb_code = rec_bin.wb_code
        CALL utils_globals.msg_updated()
    END IF
    CALL load_bin(rec_bin.wb_code) -- Reload to confirm changes
END FUNCTION

-- Delete current bin record with confirmation
FUNCTION delete_bin()
    IF utils_globals.is_empty(rec_bin.wb_code) THEN
        CALL utils_globals.show_info("No bin selected for deletion.")
        RETURN
    END IF

    -- Confirm deletion with user
    IF utils_globals.confirm_delete("bin", rec_bin.description) THEN
        DELETE FROM wb01_mast WHERE wb_code = rec_bin.wb_code
        CALL utils_globals.msg_deleted()
        -- Refresh record list after deletion
        --LET arr_codes = utils_globals.select_records(master_config.table_name, "1=1")
        --IF arr_codes.getLength() > 0 THEN
        --    LET curr_idx = 1
        --    CALL load_bin(arr_codes[curr_idx])  -- Load first remaining record
        --ELSE
        --    -- No records left, clear form
        --    INITIALIZE rec_bin.* TO NULL
        --    DISPLAY BY NAME rec_bin.*
        --END IF
    END IF
END FUNCTION

-- Validate required fields before saving
FUNCTION validateFields() RETURNS BOOLEAN
    -- Check bin code is provided
    IF utils_globals.is_empty(rec_bin.wb_code) THEN
        CALL utils_globals.show_error("Bin Code is required.")
        RETURN FALSE
    END IF
    -- Check warehouse ID is provided
    IF utils_globals.is_empty(rec_bin.wh_id) THEN
        CALL utils_globals.show_error("Warehouse ID is required.")
        RETURN FALSE
    END IF
    RETURN TRUE -- All validations passed
END FUNCTION

-- Entry point function for external calls
FUNCTION open_wbbin_form()
    CALL init_module() -- Start the main dialog
END FUNCTION
