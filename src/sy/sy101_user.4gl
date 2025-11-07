-- ==============================================================
-- Program   : sy101_user.4gl
-- Purpose   : User Master maintenance (CRUD operations)
-- Module    : System (sy)
-- Number    : 101
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Master file maintenance for system users
--              Provides full CRUD operations for user records
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoapp_db

-- User master record structure
TYPE user_t RECORD
    user_id STRING, -- User ID (primary key)
    user_name STRING, -- Full user name
    email STRING, -- Email address
    phone STRING, -- Phone number
    role STRING, -- User role (ADMIN/USER/VIEWER)
    department STRING, -- Department
    status SMALLINT -- Status (1=Active, 0=Inactive)
END RECORD

DEFINE rec_user user_t
DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT
DEFINE master_config utils_globals.master_record

MAIN
    IF NOT utils_globals.initialize_application() THEN
        EXIT PROGRAM 1
    END IF

    CALL initMasterConfig()
      OPTIONS INPUT WRAP
    OPEN WINDOW w_sy101 WITH FORM "sy101_user" ATTRIBUTES(STYLE = "main")
    CALL init_module()
    CLOSE WINDOW w_sy101
END MAIN

-- Initialize master configuration for CRUD operations
FUNCTION initMasterConfig()
    LET master_config.table_name = "sy01_user" -- Main table name
    LET master_config.key_field = "user_id" -- Primary key field
    LET master_config.name_field = "user_name" -- Display field
    LET master_config.phone_field = "phone" -- Phone field
    LET master_config.email_field = "email" -- Email field
END FUNCTION

-- Main module initialization and dialog handling
FUNCTION init_module()
    -- Setup status dropdown values
    CALL utils_globals.populate_status_combo("status")
    LET is_edit_mode = FALSE -- Start in view mode

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_user.* ATTRIBUTES(WITHOUT DEFAULTS, NAME = "user")

            BEFORE INPUT
                -- CALL MasterCRUD.setEditMode(DIALOG, FALSE)

            ON ACTION new ATTRIBUTES(TEXT = "Create", IMAGE = "new")
                CALL new_user()

            ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
                IF utils_globals.is_empty(rec_user.user_id) THEN
                    CALL utils_globals.show_info("No record selected to edit.")
                ELSE
                    LET is_edit_mode = TRUE
                    -- CALL MasterCRUD.setEditMode(DIALOG, TRUE)
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
                IF is_edit_mode THEN
                    CALL save_user()
                    LET is_edit_mode = FALSE
                    -- CALL MasterCRUD.setEditMode(DIALOG, FALSE)
                END IF

            ON ACTION DELETE ATTRIBUTES(TEXT = "Delete", IMAGE = "delete")
                CALL delete_user()

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

            BEFORE FIELD user_name, email, phone, role, department, status
                IF NOT is_edit_mode THEN
                    CALL utils_globals.show_info("Click Edit to modify.")
                    NEXT FIELD user_id
                END IF
        END INPUT

        BEFORE DIALOG
            --LET arr_codes = utils_globals.select_records("1=1")
            --IF arr_codes.getLength() > 0 THEN
            --    LET curr_idx = 1
            --    CALL load_user(arr_codes[curr_idx])
            --END IF
    END DIALOG
END FUNCTION

-- Load user record by ID and display on form
FUNCTION load_user(p_id STRING)
    SELECT user_id, user_name, email, phone, role, department, status
        INTO rec_user.*
        FROM sy01_user
        WHERE user_id = p_id

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_user.* -- Update form fields
    END IF
END FUNCTION

-- Navigate between records (First/Prev/Next/Last)
FUNCTION move_record(dir SMALLINT)
    LET curr_idx = utils_globals.navigate_records(arr_codes, curr_idx, dir)
    CALL load_user(arr_codes[curr_idx]) -- Load selected record
    -- CALL MasterCRUD.setEditMode(DIALOG, FALSE)  -- Reset to view mode
    LET is_edit_mode = FALSE
END FUNCTION

-- Initialize new user record for creation
FUNCTION new_user()
    INITIALIZE rec_user.* TO NULL -- Clear all fields
    LET rec_user.status = 1 -- Default to active status
    LET rec_user.role = "USER" -- Default role
    DISPLAY BY NAME rec_user.* -- Update form display
    LET is_edit_mode = TRUE -- Enable editing
    -- CALL MasterCRUD.setEditMode(DIALOG, TRUE)
    MESSAGE "Enter new user details, then click Update to save."
END FUNCTION

-- Save user record (INSERT for new, UPDATE for existing)
FUNCTION save_user()
    DEFINE exists INTEGER

    -- Validate required fields before saving
    IF NOT validateFields() THEN
        RETURN
    END IF

    -- Check if record already exists
    SELECT COUNT(*) INTO exists FROM sy01_user WHERE user_id = rec_user.user_id

--    IF exists = 0 THEN
--        -- Insert new record
--        INSERT INTO sy01_user (user_id, user_name, email, phone, role, department, status)
--        VALUES (rec_user.user_id, rec_user.user_name, rec_user.email, rec_user.phone,
--                rec_user.role, rec_user.department, rec_user.status)
--        CALL utils_globals.msg_saved()
--        -- Refresh record list and position to new record
--        LET arr_codes = utils_globals.select_records(master_config.table_name, "1=1")
--
--        CALL utils_globals.set_current_index(arr_codes, rec_user.user_id)
--    ELSE
--        -- Update existing record
--        UPDATE sy01_user SET user_name = rec_user.user_name, email = rec_user.email,
--               phone = rec_user.phone, role = rec_user.role, department = rec_user.department,
--               status = rec_user.status
--        WHERE user_id = rec_user.user_id
--        CALL utils_globals.msg_updated()
--    END IF
    CALL load_user(rec_user.user_id) -- Reload to confirm changes
END FUNCTION

-- Delete current user record with confirmation
FUNCTION delete_user()
    IF utils_globals.is_empty(rec_user.user_id) THEN
        CALL utils_globals.show_info("No user selected for deletion.")
        RETURN
    END IF

    -- Confirm deletion with user
    --IF utils_globals.confirm_delete("user", rec_user.user_name) THEN
    --    DELETE FROM sy01_user WHERE user_id = rec_user.user_id
    --    CALL utils_globals.msg_deleted()
    --    -- Refresh record list after deletion
    --    LET arr_codes = utils_globals.select_records(master_config.table_name, "1=1")
    --    IF arr_codes.getLength() > 0 THEN
    --        LET curr_idx = 1
    --        CALL load_user(arr_codes[curr_idx])  -- Load first remaining record
    --    ELSE
    --        -- No records left, clear form
    --        INITIALIZE rec_user.* TO NULL
    --        DISPLAY BY NAME rec_user.*
    --    END IF
    --END IF
END FUNCTION

-- Validate required fields before saving
FUNCTION validateFields() RETURNS BOOLEAN
    -- Check user ID is provided
    IF utils_globals.is_empty(rec_user.user_id) THEN
        CALL utils_globals.show_error("User ID is required.")
        RETURN FALSE
    END IF
    -- Check user name is provided
    IF utils_globals.is_empty(rec_user.user_name) THEN
        CALL utils_globals.show_error("User Name is required.")
        RETURN FALSE
    END IF
    -- Check email format if provided
    IF NOT utils_globals.is_empty(rec_user.email) THEN
        IF NOT utils_globals.is_valid_email(rec_user.email) THEN
            CALL utils_globals.show_error("Invalid email format.")
            RETURN FALSE
        END IF
    END IF
    -- Check role is valid
    IF NOT utils_globals.is_empty(rec_user.role) THEN
        IF rec_user.role NOT MATCHES "ADMIN|USER|VIEWER" THEN
            CALL utils_globals.show_error(
                "Role must be ADMIN, USER, or VIEWER.")
            RETURN FALSE
        END IF
    END IF
    RETURN TRUE -- All validations passed
END FUNCTION

-- List users (for external calls)
FUNCTION list_users()
    CALL init_module() -- Start the main dialog
END FUNCTION

-- Search user profile (for external calls)
FUNCTION search_user()
    -- This would open a search dialog
    CALL utils_globals.show_info("User search functionality")
END FUNCTION

-- Add user (for external calls)
FUNCTION add_user()
    CALL new_user() -- Start new user creation
END FUNCTION
