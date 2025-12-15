-- ==============================================================
-- Program      :   sy08_lkup_tbl.4gl
-- Purpose      :   Lookup Configuration table
-- Module       :   System (sy)
-- Number       :   08
-- Author       :   Bongani Dlamini
-- Version      :   Genero ver 3.20.10
-- Description  :   Provides tables
--                  This configuration drives the dynamic lookup functionality
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL utils_global_lkup

SCHEMA demoappdb

TYPE lkup_config_arr_t DYNAMIC ARRAY OF RECORD LIKE sy08_lkup_config.*
TYPE lkup_config_t RECORD LIKE sy08_lkup_config.*

DEFINE m_lkup_config_rec      lkup_config_t
DEFINE m_lkup_config_arr      lkup_config_arr_t

DEFINE m_idx INTEGER
DEFINE is_edit_mode INTEGER
DEFINE arr_codes DYNAMIC ARRAY OF STRING

--===============================================
-- init module
--===============================================
FUNCTION init_lkup_config()

    -- Initialize the list of records
    CALL load_records()

    MENU "Lookup Config Menu"

        ON ACTION Find
            CALL query_lkup_configs()
            LET is_edit_mode = FALSE

        ON ACTION New
            CALL new_lkup_config()
            LET is_edit_mode = FALSE

        ON ACTION Edit
            IF m_lkup_config_rec.id IS NULL OR m_lkup_config_rec.id <= 0 THEN
                CALL utils_globals.show_info("No lookup configuration selected to edit.")
            ELSE
                LET is_edit_mode = TRUE
                CALL edit_lkup_config()
            END IF

        ON ACTION Delete
            CALL delete_lkup_config()
            LET is_edit_mode = FALSE
            
        ON ACTION Exit
            EXIT MENU
    END MENU

END FUNCTION 

--===============================================
-- load lookup config table
--===============================================
FUNCTION load_records()

-- load cursor
    DECLARE lkup_config_curs CURSOR FOR
    SELECT * FROM sy08_lkup_config
    ORDER BY lookup_code DESC

    -- reset table index
    LET m_idx = 0
    -- load the cursor data to the lkup array variable and increase index 
    FOREACH lkup_config_curs INTO m_lkup_config_arr[m_idx].*
        LET m_idx = m_idx + 1
    END FOREACH

    -- clear cursor
    CLOSE lkup_config_curs
    FREE lkup_config_curs

END FUNCTION

-- ==============================================================
-- Query lookup configs (simple search)
-- ==============================================================
PRIVATE FUNCTION query_lkup_configs()
    DEFINE selected_code STRING

    LET selected_code = utils_global_lkup.display_lookup('lkup_config')

    IF selected_code IS NULL OR selected_code = "" THEN
        RETURN
    END IF

    CALL load_lkup_config(selected_code)

    CALL arr_codes.clear()
    LET arr_codes[1] = selected_code
    LET m_idx = 1
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

    TRY
        PREPARE stmt_select FROM sql_stmt
        DECLARE c_curs CURSOR FOR stmt_select

        FOREACH c_curs INTO lkup_id
            LET idx = idx + 1
            LET arr_codes[idx] = lkup_id
        END FOREACH

        CLOSE c_curs
        FREE c_curs
        FREE stmt_select

    CATCH
        CALL utils_globals.show_sql_error("select_lkup_configs: Error loading lookup configs")
        RETURN FALSE
    END TRY

    IF arr_codes.getLength() == 0 THEN
        CALL utils_globals.msg_no_record()
        RETURN FALSE
    END IF

    LET m_idx = 1
    CALL load_lkup_config(arr_codes[m_idx])
    RETURN TRUE
END FUNCTION

-- ==============================================================
-- Load Single Lookup Config
-- ==============================================================
FUNCTION load_lkup_config(p_id INTEGER)

    TRY
        SELECT * INTO m_lkup_config_rec.* FROM sy08_lkup_config WHERE id = p_id

        IF SQLCA.SQLCODE = 0 THEN
            DISPLAY BY NAME m_lkup_config_rec.*
        ELSE
            INITIALIZE m_lkup_config_rec.* TO NULL
            DISPLAY BY NAME m_lkup_config_rec.*
        END IF

    CATCH
        CALL utils_globals.show_sql_error("load_lkup_config: Error loading lookup config")
        INITIALIZE m_lkup_config_rec.* TO NULL
        DISPLAY BY NAME m_lkup_config_rec.*
    END TRY
END FUNCTION

-- ==============================================================
-- New Lookup Config
-- ==============================================================
FUNCTION new_lkup_config()
    DEFINE dup_found, new_id INTEGER
    DEFINE i, array_size INTEGER

    INITIALIZE m_lkup_config_rec.* TO NULL
    LET m_lkup_config_rec.created_at = CURRENT

    CALL utils_globals.set_form_label("lbl_form_title", "NEW LOOKUP CONFIG")

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME m_lkup_config_rec.lookup_code,
                      m_lkup_config_rec.table_name,
                      m_lkup_config_rec.key_field,
                      m_lkup_config_rec.desc_field,
                      m_lkup_config_rec.extra_field,
                      m_lkup_config_rec.display_title,
                      m_lkup_config_rec.col1_title,
                      m_lkup_config_rec.col2_title,
                      m_lkup_config_rec.col3_title,
                      m_lkup_config_rec.search_fields
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_lkup_config")

            AFTER FIELD lookup_code
                IF m_lkup_config_rec.lookup_code IS NULL OR m_lkup_config_rec.lookup_code = "" THEN
                    CALL utils_globals.show_error("Lookup Code is required.")
                    NEXT FIELD lookup_code
                END IF
                -- Check if lookup_code already exists
                LET dup_found = check_lookup_code_unique(m_lkup_config_rec.lookup_code)
                IF dup_found != 0 THEN
                    CALL utils_globals.show_error("Lookup Code already exists.")
                    NEXT FIELD lookup_code
                END IF

            AFTER FIELD table_name
                IF m_lkup_config_rec.table_name IS NULL OR m_lkup_config_rec.table_name = "" THEN
                    CALL utils_globals.show_error("Table Name is required.")
                    NEXT FIELD table_name
                END IF

            AFTER FIELD key_field
                IF m_lkup_config_rec.key_field IS NULL OR m_lkup_config_rec.key_field = "" THEN
                    CALL utils_globals.show_error("Key Field is required.")
                    NEXT FIELD key_field
                END IF

            AFTER FIELD desc_field
                IF m_lkup_config_rec.desc_field IS NULL OR m_lkup_config_rec.desc_field = "" THEN
                    CALL utils_globals.show_error("Description Field is required.")
                    NEXT FIELD desc_field
                END IF

            AFTER FIELD display_title
                IF m_lkup_config_rec.display_title IS NULL OR m_lkup_config_rec.display_title = "" THEN
                    CALL utils_globals.show_error("Display Title is required.")
                    NEXT FIELD display_title
                END IF

        END INPUT

        ON ACTION save ATTRIBUTES(TEXT = "Save", IMAGE = "filesave")
            -- Validate before saving
            IF m_lkup_config_rec.lookup_code IS NULL OR m_lkup_config_rec.lookup_code = "" THEN
                CALL utils_globals.show_error("Lookup Code is required.")
                NEXT FIELD lookup_code
            END IF
            IF m_lkup_config_rec.table_name IS NULL OR m_lkup_config_rec.table_name = "" THEN
                CALL utils_globals.show_error("Table Name is required.")
                NEXT FIELD table_name
            END IF
            IF m_lkup_config_rec.key_field IS NULL OR m_lkup_config_rec.key_field = "" THEN
                CALL utils_globals.show_error("Key Field is required.")
                NEXT FIELD key_field
            END IF
            IF m_lkup_config_rec.desc_field IS NULL OR m_lkup_config_rec.desc_field = "" THEN
                CALL utils_globals.show_error("Description Field is required.")
                NEXT FIELD desc_field
            END IF
            IF m_lkup_config_rec.display_title IS NULL OR m_lkup_config_rec.display_title = "" THEN
                CALL utils_globals.show_error("Display Title is required.")
                NEXT FIELD display_title
            END IF
            CALL save_lkup_config()
            LET new_id = m_lkup_config_rec.id
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
        CALL load_lkup_config(new_id)
        LET array_size = arr_codes.getLength()
        IF array_size > 0 THEN
            FOR i = 1 TO array_size
                IF arr_codes[i] = new_id THEN
                    LET m_idx = i
                    EXIT FOR
                END IF
            END FOR
        END IF
        CALL load_lkup_config(new_id)
    ELSE
        LET array_size = arr_codes.getLength()
        IF array_size > 0 AND m_idx >= 1 AND m_idx <= array_size THEN
            CALL load_lkup_config(arr_codes[m_idx])
        ELSE
            LET m_idx = 0
            INITIALIZE m_lkup_config_rec.* TO NULL
            DISPLAY BY NAME m_lkup_config_rec.*
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
        INPUT BY NAME m_lkup_config_rec.lookup_code,
                      m_lkup_config_rec.table_name,
                      m_lkup_config_rec.key_field,
                      m_lkup_config_rec.desc_field,
                      m_lkup_config_rec.extra_field,
                      m_lkup_config_rec.display_title,
                      m_lkup_config_rec.col1_title,
                      m_lkup_config_rec.col2_title,
                      m_lkup_config_rec.col3_title,
                      m_lkup_config_rec.search_fields
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "edit_lkup_config")

            BEFORE FIELD lookup_code
                -- Lookup code should not be editable
                NEXT FIELD table_name

            AFTER FIELD table_name
                IF m_lkup_config_rec.table_name IS NULL OR m_lkup_config_rec.table_name = "" THEN
                    CALL utils_globals.show_error("Table Name is required.")
                    NEXT FIELD table_name
                END IF

            AFTER FIELD key_field
                IF m_lkup_config_rec.key_field IS NULL OR m_lkup_config_rec.key_field = "" THEN
                    CALL utils_globals.show_error("Key Field is required.")
                    NEXT FIELD key_field
                END IF

            AFTER FIELD desc_field
                IF m_lkup_config_rec.desc_field IS NULL OR m_lkup_config_rec.desc_field = "" THEN
                    CALL utils_globals.show_error("Description Field is required.")
                    NEXT FIELD desc_field
                END IF

            AFTER FIELD display_title
                IF m_lkup_config_rec.display_title IS NULL OR m_lkup_config_rec.display_title = "" THEN
                    CALL utils_globals.show_error("Display Title is required.")
                    NEXT FIELD display_title
                END IF

        END INPUT

        ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
            -- Validate before saving
            IF m_lkup_config_rec.table_name IS NULL OR m_lkup_config_rec.table_name = "" THEN
                CALL utils_globals.show_error("Table Name is required.")
                NEXT FIELD table_name
            END IF
            IF m_lkup_config_rec.key_field IS NULL OR m_lkup_config_rec.key_field = "" THEN
                CALL utils_globals.show_error("Key Field is required.")
                NEXT FIELD key_field
            END IF
            IF m_lkup_config_rec.desc_field IS NULL OR m_lkup_config_rec.desc_field = "" THEN
                CALL utils_globals.show_error("Description Field is required.")
                NEXT FIELD desc_field
            END IF
            IF m_lkup_config_rec.display_title IS NULL OR m_lkup_config_rec.display_title = "" THEN
                CALL utils_globals.show_error("Display Title is required.")
                NEXT FIELD display_title
            END IF
            CALL save_lkup_config()
            EXIT DIALOG

        ON ACTION cancel ATTRIBUTES(TEXT = "Cancel", IMAGE = "cancel")
            CALL load_lkup_config(m_lkup_config_rec.id)
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
            WHERE id = m_lkup_config_rec.id

        IF exists = 0 THEN
            -- New record
            LET m_lkup_config_rec.created_at = CURRENT

            INSERT INTO sy08_lkup_config (
                lookup_code,
                table_name,
                key_field,
                desc_field,
                extra_field,
                display_title,
                col1_title,
                col2_title,
                col3_title,
                search_fields,
                created_at
            ) VALUES (
                m_lkup_config_rec.lookup_code,
                m_lkup_config_rec.table_name,
                m_lkup_config_rec.key_field,
                m_lkup_config_rec.desc_field,
                m_lkup_config_rec.extra_field,
                m_lkup_config_rec.display_title,
                m_lkup_config_rec.col1_title,
                m_lkup_config_rec.col2_title,
                m_lkup_config_rec.col3_title,
                m_lkup_config_rec.search_fields,
                m_lkup_config_rec.created_at
            )

            -- Get the generated ID
            LET m_lkup_config_rec.id = SQLCA.SQLERRD[2]

            COMMIT WORK
            CALL utils_globals.msg_saved()
        ELSE
            -- Update existing record
            LET m_lkup_config_rec.updated_at = CURRENT

            UPDATE sy08_lkup_config
                SET table_name = m_lkup_config_rec.table_name,
                    key_field = m_lkup_config_rec.key_field,
                    desc_field = m_lkup_config_rec.desc_field,
                    extra_field = m_lkup_config_rec.extra_field,
                    display_title = m_lkup_config_rec.display_title,
                    col1_title = m_lkup_config_rec.col1_title,
                    col2_title = m_lkup_config_rec.col2_title,
                    col3_title = m_lkup_config_rec.col3_title,
                    search_fields = m_lkup_config_rec.search_fields,
                    updated_at = m_lkup_config_rec.updated_at
                WHERE id = m_lkup_config_rec.id

            COMMIT WORK
            CALL utils_globals.msg_updated()
        END IF

        CALL load_lkup_config(m_lkup_config_rec.id)

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_sql_error("save_lkup_config: Error saving lookup config")
    END TRY
END FUNCTION

-- ==============================================================
-- Delete Lookup Config
-- ==============================================================
FUNCTION delete_lkup_config()
    DEFINE ok SMALLINT
    DEFINE deleted_id INTEGER
    DEFINE array_size INTEGER

    IF m_lkup_config_rec.id IS NULL OR m_lkup_config_rec.id <= 0 THEN
        CALL utils_globals.show_info("No lookup configuration selected for deletion.")
        RETURN
    END IF

    LET ok =
        utils_globals.show_confirm(
            "Delete lookup configuration: " || m_lkup_config_rec.lookup_code || "?",
            "Confirm Delete")

    IF NOT ok THEN
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    LET deleted_id = m_lkup_config_rec.id

    BEGIN WORK
    TRY
        DELETE FROM sy08_lkup_config WHERE id = deleted_id
        COMMIT WORK
        CALL utils_globals.msg_deleted()
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_sql_error("delete_lkup_config: Error deleting lookup config")
        RETURN
    END TRY

    -- Reload list and navigate to valid record
    CALL load_records()
    LET array_size = arr_codes.getLength()

    IF array_size > 0 THEN
        IF m_idx > array_size THEN
            LET m_idx = array_size
        END IF
        IF m_idx < 1 THEN
            LET m_idx = 1
        END IF
        CALL load_lkup_config(arr_codes[m_idx])
    ELSE
        LET m_idx = 0
        INITIALIZE m_lkup_config_rec.* TO NULL
        DISPLAY BY NAME m_lkup_config_rec.*
    END IF
END FUNCTION

-- ==============================================================
-- Check Lookup Code Uniqueness
-- ==============================================================
FUNCTION check_lookup_code_unique(p_lookup_code STRING) RETURNS SMALLINT
    DEFINE dup_count INTEGER

    TRY
        SELECT COUNT(*) INTO dup_count FROM sy08_lkup_config WHERE lookup_code = p_lookup_code
        IF dup_count > 0 THEN
            RETURN 1
        END IF

        RETURN 0

    CATCH
        CALL utils_globals.show_sql_error("check_lookup_code_unique: Error checking uniqueness")
        RETURN 0
    END TRY
END FUNCTION

-- ==============================================================
-- Utility function to get lookup config by code
-- ==============================================================
FUNCTION get_lkup_config_by_code(p_lookup_code STRING) RETURNS lkup_config_t
    DEFINE lkup_rec lkup_config_t

    TRY
        SELECT * INTO lkup_rec.*
            FROM sy08_lkup_config
            WHERE lookup_code = p_lookup_code

        RETURN lkup_rec.*

    CATCH
        CALL utils_globals.show_sql_error("get_lkup_config_by_code: Error getting lookup config")
        INITIALIZE lkup_rec.* TO NULL
        RETURN lkup_rec.*
    END TRY
END FUNCTION
