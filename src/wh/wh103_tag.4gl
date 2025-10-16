-- ==============================================================
-- Program   : wh103_tag.4gl
-- Purpose   : Warehouse Tag Master maintenance (CRUD operations)
-- Module    : Warehouse (wh)
-- Number    : 103
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Master file maintenance for warehouse tags
--              Provides full CRUD operations for tag records
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL MasterCRUD

SCHEMA demoapp_db

-- Warehouse tag record structure
TYPE tag_t RECORD
    tag_code    STRING,           -- Tag code (primary key)
    tag_name    STRING,           -- Tag name
    wh_code     STRING,           -- Associated warehouse code
    description STRING,           -- Tag description
    status      SMALLINT          -- Status (1=Active, 0=Inactive)
END RECORD

DEFINE rec_tag tag_t
DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT
DEFINE master_config utils_globals.master_record

MAIN
    IF NOT utils_globals.connectDatabase() THEN
        EXIT PROGRAM 1
    END IF
    
    CALL initMasterConfig()
    OPEN WINDOW w_wh103 WITH FORM "wh103_tag" ATTRIBUTES(STYLE = "main")
    CALL init_module()
    CLOSE WINDOW w_wh103
END MAIN

-- Initialize master configuration for CRUD operations
FUNCTION initMasterConfig()
    LET master_config.table_name = "wh02_tag"      -- Main table name
    LET master_config.key_field = "tag_code"       -- Primary key field
    LET master_config.name_field = "tag_name"      -- Display field
    LET master_config.phone_field = ""             -- Not used for tags
    LET master_config.email_field = ""             -- Not used for tags
END FUNCTION

-- Main module initialization and dialog handling
FUNCTION init_module()
    -- Setup status dropdown values
    CALL utils_globals.populateStatusCombo("status")
    LET is_edit_mode = FALSE  -- Start in view mode

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_tag.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME="tag")

            BEFORE INPUT
                -- CALL MasterCRUD.setEditMode(DIALOG, FALSE)
                
            ON ACTION new ATTRIBUTES(TEXT="Create", IMAGE="new")
                CALL new_tag()
                
            ON ACTION edit ATTRIBUTES(TEXT="Edit", IMAGE="edit")
                IF utils_globals.is_empty(rec_tag.tag_code) THEN
                    CALL utils_globals.show_info("No record selected to edit.")
                ELSE
                    LET is_edit_mode = TRUE
                    -- CALL MasterCRUD.setEditMode(DIALOG, TRUE)
                END IF
                
            ON ACTION save ATTRIBUTES(TEXT="Update", IMAGE="filesave")
                IF is_edit_mode THEN
                    CALL save_tag()
                    LET is_edit_mode = FALSE
                    -- CALL MasterCRUD.setEditMode(DIALOG, FALSE)
                END IF
                
            ON ACTION DELETE ATTRIBUTES(TEXT="Delete", IMAGE="delete")
                CALL delete_tag()

            ON ACTION FIRST ATTRIBUTES(TEXT="First", IMAGE="first")
                CALL move_record(-2)
            ON ACTION PREVIOUS ATTRIBUTES(TEXT="Previous", IMAGE="prev")
                CALL move_record(-1)
            ON ACTION NEXT ATTRIBUTES(TEXT="Next", IMAGE="next")
                CALL move_record(1)
            ON ACTION LAST ATTRIBUTES(TEXT="Last", IMAGE="last")
                CALL move_record(2)
            ON ACTION QUIT ATTRIBUTES(TEXT="Quit", IMAGE="quit")
                EXIT DIALOG
                
            BEFORE FIELD tag_name, wh_code, description, status
                IF NOT is_edit_mode THEN
                    CALL utils_globals.show_info("Click Edit to modify.")
                    NEXT FIELD tag_code
                END IF
        END INPUT

        BEFORE DIALOG
            LET arr_codes = utils_globals.select_records(master_config.table_name, "1=1")
            IF arr_codes.getLength() > 0 THEN
                LET curr_idx = 1
                CALL load_tag(arr_codes[curr_idx])
            END IF
    END DIALOG
END FUNCTION

-- Load tag record by code and display on form
FUNCTION load_tag(p_code STRING)
    SELECT tag_code, tag_name, wh_code, description, status
      INTO rec_tag.*
      FROM wh02_tag
     WHERE tag_code = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_tag.*  -- Update form fields
    END IF
END FUNCTION

-- Navigate between records (First/Prev/Next/Last)
FUNCTION move_record(dir SMALLINT)
    LET curr_idx = utils_globals.navigate_records(arr_codes, curr_idx, dir)
    CALL load_tag(arr_codes[curr_idx])  -- Load selected record
    -- CALL MasterCRUD.setEditMode(DIALOG, FALSE)  -- Reset to view mode
    LET is_edit_mode = FALSE
END FUNCTION

-- Initialize new tag record for creation
FUNCTION new_tag()
    INITIALIZE rec_tag.* TO NULL  -- Clear all fields
    LET rec_tag.status = 1        -- Default to active status
    DISPLAY BY NAME rec_tag.*     -- Update form display
    LET is_edit_mode = TRUE       -- Enable editing
    -- CALL MasterCRUD.setEditMode(DIALOG, TRUE)
    MESSAGE "Enter new tag details, then click Update to save."
END FUNCTION

-- Save tag record (INSERT for new, UPDATE for existing)
FUNCTION save_tag()
    DEFINE exists INTEGER
    
    -- Validate required fields before saving
    IF NOT validateFields() THEN
        RETURN
    END IF
    
    -- Check if record already exists
    SELECT COUNT(*) INTO exists FROM wh02_tag WHERE tag_code = rec_tag.tag_code

    IF exists = 0 THEN
        -- Insert new record
        INSERT INTO wh02_tag (tag_code, tag_name, wh_code, description, status)
        VALUES (rec_tag.tag_code, rec_tag.tag_name, rec_tag.wh_code, rec_tag.description, rec_tag.status)
        CALL utils_globals.msg_saved()
        -- Refresh record list and position to new record
        LET arr_codes = utils_globals.select_records(master_config.table_name, "1=1")
        CALL utils_globals.set_current_index(arr_codes, rec_tag.tag_code)
    ELSE
        -- Update existing record
        UPDATE wh02_tag SET tag_name = rec_tag.tag_name, wh_code = rec_tag.wh_code,
               description = rec_tag.description, status = rec_tag.status
        WHERE tag_code = rec_tag.tag_code
        CALL utils_globals.msg_updated()
    END IF
    CALL load_tag(rec_tag.tag_code)  -- Reload to confirm changes
END FUNCTION

-- Delete current tag record with confirmation
FUNCTION delete_tag()
    IF utils_globals.is_empty(rec_tag.tag_code) THEN
        CALL utils_globals.show_info("No tag selected for deletion.")
        RETURN
    END IF

    -- Confirm deletion with user
    IF utils_globals.confirm_delete("tag", rec_tag.tag_name) THEN
        DELETE FROM wh02_tag WHERE tag_code = rec_tag.tag_code
        CALL utils_globals.msg_deleted()
        -- Refresh record list after deletion
        LET arr_codes = utils_globals.select_records(master_config.table_name, "1=1")
        IF arr_codes.getLength() > 0 THEN
            LET curr_idx = 1
            CALL load_tag(arr_codes[curr_idx])  -- Load first remaining record
        ELSE
            -- No records left, clear form
            INITIALIZE rec_tag.* TO NULL
            DISPLAY BY NAME rec_tag.*
        END IF
    END IF
END FUNCTION

-- Validate required fields before saving
FUNCTION validateFields() RETURNS BOOLEAN
    -- Check tag code is provided
    IF utils_globals.is_empty(rec_tag.tag_code) THEN
        CALL utils_globals.show_error("Tag Code is required.")
        RETURN FALSE
    END IF
    -- Check tag name is provided
    IF utils_globals.is_empty(rec_tag.tag_name) THEN
        CALL utils_globals.show_error("Tag Name is required.")
        RETURN FALSE
    END IF
    RETURN TRUE  -- All validations passed
END FUNCTION