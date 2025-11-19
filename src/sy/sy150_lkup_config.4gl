-- ==============================================================
-- Program   : sy08_lkup_config.4gl
-- Purpose   : Lookup Configuration maintenance (CRUD operations)
-- Module    : System (sy)
-- Number    : 08
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Master file maintenance for lookup configurations
--              Provides full CRUD operations for managing lookup tables
--              This configuration drives the dynamic lookup functionality
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoappdb

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE lkup_config_t RECORD LIKE sy08_lkup_config.*
DEFINE rec_lkup_config lkup_config_t

DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

-- ==============================================================
-- MAIN (Standalone or Child Mode)
-- ==============================================================
--MAIN
--    IF NOT utils_globals.initialize_application() THEN
--        CALL utils_globals.show_error("Initialization failed.")
--        EXIT PROGRAM 1
--    END IF
--
--    IF utils_globals.is_standalone() THEN
--        OPEN WINDOW w_sy08 WITH FORM "sy08_lkup_config"
--    ELSE
--        OPEN WINDOW w_sy08 WITH FORM "sy08_lkup_config" ATTRIBUTES(STYLE = "child")
--    END IF
--
--    CALL init_lkup_config_module()
--
--    IF utils_globals.is_standalone() THEN
--        CLOSE WINDOW w_sy08
--    END IF
--END MAIN

-- ==============================================================
-- Main Controller Menu
-- ==============================================================
FUNCTION init_lkup_config_module()
    LET is_edit_mode = FALSE
    CALL utils_globals.set_form_label("lbl_form_title", "SYSTEM LOOKUP CONFIG")

    -- Initialize the list of records
    CALL load_all_lkup_configs()

    MENU "Lookup Config Menu"

        COMMAND "Find"
            CALL query_lkup_configs()
            LET is_edit_mode = FALSE

        COMMAND "New"
            CALL new_lkup_config()
            LET is_edit_mode = FALSE

        COMMAND "Edit"
            IF rec_lkup_config.id IS NULL OR rec_lkup_config.id <= 0 THEN
                CALL utils_globals.show_info("No lookup configuration selected to edit.")
            ELSE
                LET is_edit_mode = TRUE
                CALL edit_lkup_config()
            END IF

        COMMAND "Delete"
            CALL delete_lkup_config()
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
-- Load all lookup configs into array
-- ==============================================================
PRIVATE FUNCTION load_all_lkup_configs()
    DEFINE ok SMALLINT
    LET ok = select_lkup_configs("1=1")

    IF ok THEN
        MESSAGE SFMT("Loaded %1 lookup configuration(s)", arr_codes.getLength())
    ELSE
        CALL utils_globals.show_info("No lookup configurations found.")
        INITIALIZE rec_lkup_config.* TO NULL
        DISPLAY BY NAME rec_lkup_config.*
    END IF
END FUNCTION

-- ==============================================================
-- Query lookup configs (simple search)
-- ==============================================================
FUNCTION query_lkup_configs()
    DEFINE search_code STRING
    DEFINE ok SMALLINT

    LET search_code = ""

    PROMPT "Enter Lookup Code to search:" FOR search_code

    IF search_code IS NULL OR search_code = "" THEN
        CALL load_all_lkup_configs()
        RETURN
    END IF

    LET ok = select_lkup_configs(SFMT("lookup_code LIKE '%%%1%%'", search_code))

    IF NOT ok THEN
        CALL utils_globals.show_info("No lookup configurations found matching criteria.")
    END IF
END FUNCTION

-- ==============================================================
-- Select lookup configs into array
-- ==============================================================
FUNCTION select_lkup_configs(where_clause STRING) RETURNS SMALLINT
    DEFINE lkup_id INTEGER
    DEFINE idx INTEGER
    DEFINE sql_stmt STRING

    CALL arr_codes.clear()
    LET idx = 0
    LET sql_stmt = "SELECT id FROM sy08_lkup_config"

    IF where_clause IS NOT NULL AND where_clause != "" THEN
        LET sql_stmt = sql_stmt || " WHERE " || where_clause
    END IF

    LET sql_stmt = sql_stmt || " ORDER BY lookup_code"

    PREPARE stmt_select FROM sql_stmt
    DECLARE c_curs CURSOR FOR stmt_select

    FOREACH c_curs INTO lkup_id
        LET idx = idx + 1
        LET arr_codes[idx] = lkup_id
    END FOREACH

    CLOSE c_curs
    FREE c_curs
    FREE stmt_select

    IF arr_codes.getLength() == 0 THEN
        CALL utils_globals.msg_no_record()
        RETURN FALSE
    END IF

    LET curr_idx = 1
    CALL load_lkup_config(arr_codes[curr_idx])
    RETURN TRUE
END FUNCTION

-- ==============================================================
-- Load Single Lookup Config
-- ==============================================================
FUNCTION load_lkup_config(p_id INTEGER)
    SELECT * INTO rec_lkup_config.* FROM sy08_lkup_config WHERE id = p_id

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_lkup_config.*
    ELSE
        INITIALIZE rec_lkup_config.* TO NULL
        DISPLAY BY NAME rec_lkup_config.*
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
    CALL load_lkup_config(arr_codes[curr_idx])
END FUNCTION

-- ==============================================================
-- New Lookup Config
-- ==============================================================
FUNCTION new_lkup_config()
    DEFINE dup_found, new_id INTEGER
    DEFINE i, array_size INTEGER

    INITIALIZE rec_lkup_config.* TO NULL
    LET rec_lkup_config.created_at = CURRENT

    CALL utils_globals.set_form_label("lbl_form_title", "NEW LOOKUP CONFIG")

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_lkup_config.lookup_code,
                      rec_lkup_config.table_name,
                      rec_lkup_config.key_field,
                      rec_lkup_config.desc_field,
                      rec_lkup_config.display_title,
                      rec_lkup_config.filter_condition
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_lkup_config")

            AFTER FIELD lookup_code
                IF rec_lkup_config.lookup_code IS NULL OR rec_lkup_config.lookup_code = "" THEN
                    CALL utils_globals.show_error("Lookup Code is required.")
                    NEXT FIELD lookup_code
                END IF
                -- Check if lookup_code already exists
                LET dup_found = check_lookup_code_unique(rec_lkup_config.lookup_code)
                IF dup_found != 0 THEN
                    CALL utils_globals.show_error("Lookup Code already exists.")
                    NEXT FIELD lookup_code
                END IF

            AFTER FIELD table_name
                IF rec_lkup_config.table_name IS NULL OR rec_lkup_config.table_name = "" THEN
                    CALL utils_globals.show_error("Table Name is required.")
                    NEXT FIELD table_name
                END IF

            AFTER FIELD key_field
                IF rec_lkup_config.key_field IS NULL OR rec_lkup_config.key_field = "" THEN
                    CALL utils_globals.show_error("Key Field is required.")
                    NEXT FIELD key_field
                END IF

            AFTER FIELD desc_field
                IF rec_lkup_config.desc_field IS NULL OR rec_lkup_config.desc_field = "" THEN
                    CALL utils_globals.show_error("Description Field is required.")
                    NEXT FIELD desc_field
                END IF

            AFTER FIELD display_title
                IF rec_lkup_config.display_title IS NULL OR rec_lkup_config.display_title = "" THEN
                    CALL utils_globals.show_error("Display Title is required.")
                    NEXT FIELD display_title
                END IF

        END INPUT

        ON ACTION save ATTRIBUTES(TEXT = "Save", IMAGE = "filesave")
            -- Validate before saving
            IF rec_lkup_config.lookup_code IS NULL OR rec_lkup_config.lookup_code = "" THEN
                CALL utils_globals.show_error("Lookup Code is required.")
                NEXT FIELD lookup_code
            END IF
            IF rec_lkup_config.table_name IS NULL OR rec_lkup_config.table_name = "" THEN
                CALL utils_globals.show_error("Table Name is required.")
                NEXT FIELD table_name
            END IF
            IF rec_lkup_config.key_field IS NULL OR rec_lkup_config.key_field = "" THEN
                CALL utils_globals.show_error("Key Field is required.")
                NEXT FIELD key_field
            END IF
            IF rec_lkup_config.desc_field IS NULL OR rec_lkup_config.desc_field = "" THEN
                CALL utils_globals.show_error("Description Field is required.")
                NEXT FIELD desc_field
            END IF
            IF rec_lkup_config.display_title IS NULL OR rec_lkup_config.display_title = "" THEN
                CALL utils_globals.show_error("Display Title is required.")
                NEXT FIELD display_title
            END IF
            CALL save_lkup_config()
            LET new_id = rec_lkup_config.id
            IF new_id IS NOT NULL THEN
                CALL utils_globals.show_info("Lookup configuration saved successfully.")
                EXIT DIALOG
            END IF

        ON ACTION cancel ATTRIBUTES(TEXT = "Cancel", IMAGE = "cancel")
            CALL utils_globals.show_info("Creation cancelled.")
            LET new_id = NULL
            EXIT DIALOG

    END DIALOG

    -- Reload the list and position to the new record
    IF new_id IS NOT NULL THEN
        CALL load_all_lkup_configs()
        LET array_size = arr_codes.getLength()
        IF array_size > 0 THEN
            FOR i = 1 TO array_size
                IF arr_codes[i] = new_id THEN
                    LET curr_idx = i
                    EXIT FOR
                END IF
            END FOR
        END IF
        CALL load_lkup_config(new_id)
    ELSE
        LET array_size = arr_codes.getLength()
        IF array_size > 0 AND curr_idx >= 1 AND curr_idx <= array_size THEN
            CALL load_lkup_config(arr_codes[curr_idx])
        ELSE
            LET curr_idx = 0
            INITIALIZE rec_lkup_config.* TO NULL
            DISPLAY BY NAME rec_lkup_config.*
        END IF
    END IF

    CALL utils_globals.set_form_label("lbl_form_title", "SYSTEM LOOKUP CONFIG")
END FUNCTION

-- ==============================================================
-- Edit Lookup Config
-- ==============================================================
FUNCTION edit_lkup_config()
    CALL utils_globals.set_form_label("lbl_form_title", "EDIT LOOKUP CONFIG")

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_lkup_config.lookup_code,
                      rec_lkup_config.table_name,
                      rec_lkup_config.key_field,
                      rec_lkup_config.desc_field,
                      rec_lkup_config.display_title,
                      rec_lkup_config.filter_condition
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "edit_lkup_config")

            BEFORE FIELD lookup_code
                -- Lookup code should not be editable
                NEXT FIELD table_name

            AFTER FIELD table_name
                IF rec_lkup_config.table_name IS NULL OR rec_lkup_config.table_name = "" THEN
                    CALL utils_globals.show_error("Table Name is required.")
                    NEXT FIELD table_name
                END IF

            AFTER FIELD key_field
                IF rec_lkup_config.key_field IS NULL OR rec_lkup_config.key_field = "" THEN
                    CALL utils_globals.show_error("Key Field is required.")
                    NEXT FIELD key_field
                END IF

            AFTER FIELD desc_field
                IF rec_lkup_config.desc_field IS NULL OR rec_lkup_config.desc_field = "" THEN
                    CALL utils_globals.show_error("Description Field is required.")
                    NEXT FIELD desc_field
                END IF

            AFTER FIELD display_title
                IF rec_lkup_config.display_title IS NULL OR rec_lkup_config.display_title = "" THEN
                    CALL utils_globals.show_error("Display Title is required.")
                    NEXT FIELD display_title
                END IF

        END INPUT

        ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
            -- Validate before saving
            IF rec_lkup_config.table_name IS NULL OR rec_lkup_config.table_name = "" THEN
                CALL utils_globals.show_error("Table Name is required.")
                NEXT FIELD table_name
            END IF
            IF rec_lkup_config.key_field IS NULL OR rec_lkup_config.key_field = "" THEN
                CALL utils_globals.show_error("Key Field is required.")
                NEXT FIELD key_field
            END IF
            IF rec_lkup_config.desc_field IS NULL OR rec_lkup_config.desc_field = "" THEN
                CALL utils_globals.show_error("Description Field is required.")
                NEXT FIELD desc_field
            END IF
            IF rec_lkup_config.display_title IS NULL OR rec_lkup_config.display_title = "" THEN
                CALL utils_globals.show_error("Display Title is required.")
                NEXT FIELD display_title
            END IF
            CALL save_lkup_config()
            EXIT DIALOG

        ON ACTION cancel ATTRIBUTES(TEXT = "Cancel", IMAGE = "cancel")
            CALL load_lkup_config(rec_lkup_config.id)
            EXIT DIALOG

    END DIALOG

    CALL utils_globals.set_form_label("lbl_form_title", "SYSTEM LOOKUP CONFIG")
END FUNCTION

-- ==============================================================
-- Save / Update Lookup Config
-- ==============================================================
FUNCTION save_lkup_config()
    DEFINE exists INTEGER

    BEGIN WORK
    TRY
        SELECT COUNT(*)
            INTO exists
            FROM sy08_lkup_config
            WHERE id = rec_lkup_config.id

        IF exists = 0 THEN
            -- New record
            LET rec_lkup_config.created_at = CURRENT

            INSERT INTO sy08_lkup_config (
                lookup_code,
                table_name,
                key_field,
                desc_field,
                display_title,
                filter_condition,
                created_at
            ) VALUES (
                rec_lkup_config.lookup_code,
                rec_lkup_config.table_name,
                rec_lkup_config.key_field,
                rec_lkup_config.desc_field,
                rec_lkup_config.display_title,
                rec_lkup_config.filter_condition,
                rec_lkup_config.created_at
            )

            -- Get the generated ID
            LET rec_lkup_config.id = SQLCA.SQLERRD[2]

            COMMIT WORK
            CALL utils_globals.msg_saved()
        ELSE
            -- Update existing record
            LET rec_lkup_config.updated_at = CURRENT

            UPDATE sy08_lkup_config
                SET table_name = rec_lkup_config.table_name,
                    key_field = rec_lkup_config.key_field,
                    desc_field = rec_lkup_config.desc_field,
                    display_title = rec_lkup_config.display_title,
                    filter_condition = rec_lkup_config.filter_condition,
                    updated_at = rec_lkup_config.updated_at
                WHERE id = rec_lkup_config.id

            COMMIT WORK
            CALL utils_globals.msg_updated()
        END IF

        CALL load_lkup_config(rec_lkup_config.id)

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(SFMT("Save failed: %1", SQLCA.SQLCODE))
    END TRY
END FUNCTION

-- ==============================================================
-- Delete Lookup Config
-- ==============================================================
FUNCTION delete_lkup_config()
    DEFINE ok SMALLINT
    DEFINE deleted_id INTEGER
    DEFINE array_size INTEGER

    IF rec_lkup_config.id IS NULL OR rec_lkup_config.id <= 0 THEN
        CALL utils_globals.show_info("No lookup configuration selected for deletion.")
        RETURN
    END IF

    LET ok =
        utils_globals.show_confirm(
            "Delete lookup configuration: " || rec_lkup_config.lookup_code || "?",
            "Confirm Delete")

    IF NOT ok THEN
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    LET deleted_id = rec_lkup_config.id

    BEGIN WORK
    TRY
        DELETE FROM sy08_lkup_config WHERE id = deleted_id
        COMMIT WORK
        CALL utils_globals.msg_deleted()
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(SFMT("Delete failed: %1", SQLCA.SQLCODE))
        RETURN
    END TRY

    -- Reload list and navigate to valid record
    CALL load_all_lkup_configs()
    LET array_size = arr_codes.getLength()

    IF array_size > 0 THEN
        IF curr_idx > array_size THEN
            LET curr_idx = array_size
        END IF
        IF curr_idx < 1 THEN
            LET curr_idx = 1
        END IF
        CALL load_lkup_config(arr_codes[curr_idx])
    ELSE
        LET curr_idx = 0
        INITIALIZE rec_lkup_config.* TO NULL
        DISPLAY BY NAME rec_lkup_config.*
    END IF
END FUNCTION

-- ==============================================================
-- Check Lookup Code Uniqueness
-- ==============================================================
FUNCTION check_lookup_code_unique(p_lookup_code STRING) RETURNS SMALLINT
    DEFINE dup_count INTEGER

    SELECT COUNT(*) INTO dup_count FROM sy08_lkup_config WHERE lookup_code = p_lookup_code
    IF dup_count > 0 THEN
        RETURN 1
    END IF

    RETURN 0
END FUNCTION

-- ==============================================================
-- Public functions for external calls
-- ==============================================================
FUNCTION list_lkup_configs()
    CALL init_lkup_config_module()
END FUNCTION

FUNCTION add_lkup_config()
    CALL new_lkup_config()
END FUNCTION

-- ==============================================================
-- Utility function to get lookup config by code
-- ==============================================================
FUNCTION get_lkup_config_by_code(p_lookup_code STRING) RETURNS lkup_config_t
    DEFINE lkup_rec lkup_config_t

    SELECT * INTO lkup_rec.*
        FROM sy08_lkup_config
        WHERE lookup_code = p_lookup_code

    RETURN lkup_rec.*
END FUNCTION
