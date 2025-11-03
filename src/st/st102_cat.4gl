-- ==============================================================
-- Program   : st102_cat.4gl
-- Purpose   : Stock Category Master maintenance
-- Module    : Stock Category (st)
-- Number    : 102
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL st122_cat_lkup

SCHEMA demoapp_db

-- ==============================================================
-- Record definitions
-- ==============================================================
TYPE category_t RECORD LIKE st02_cat.*

DEFINE rec_cat category_t
DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

-- ==============================================================
-- MAIN (Standalone Mode)
-- ==============================================================
--MAIN
--
--    -- Initialize application (sets g_standalone_mode automatically)
--    IF NOT utils_globals.initialize_application() THEN
--        DISPLAY "Initialization failed."
--        EXIT PROGRAM 1
--    END IF
--
--    -- If standalone mode, open window
--    IF utils_globals.is_standalone() THEN
--      OPTIONS INPUT WRAP
--        OPEN WINDOW w_st_cat WITH FORM "st102_cat" ATTRIBUTES(STYLE = "main")
--    END IF
--
--    -- Run the module (works in both standalone and MDI modes)
--    CALL init_cat_module()
--
--    -- If standalone mode, close window on exit
--    IF utils_globals.is_standalone() THEN
--        CLOSE WINDOW w_st_cat
--    END IF
--
--END MAIN

-- ==============================================================
-- Lookup popup
-- ==============================================================
FUNCTION query_category() RETURNS STRING
    DEFINE selected_code STRING
    LET selected_code = st122_cat_lkup.load_lookup()
    RETURN selected_code
END FUNCTION

-- ==============================================================
-- MENU Controller
-- ==============================================================
FUNCTION init_cat_module()

    -- Start in read-only mode
    LET is_edit_mode = FALSE

    -- ===========================================
    -- MAIN MENU (top-level)
    -- ===========================================
    MENU "Stock Categories Menu"

        COMMAND "Find"
            CALL query_categories()
            LET is_edit_mode = FALSE

        COMMAND "New"
            CALL new_category()
            LET is_edit_mode = FALSE

        COMMAND "Edit"
            IF rec_cat.cat_code IS NULL OR rec_cat.cat_code = "" THEN
                CALL utils_globals.show_info("No record selected to edit.")
            ELSE
                LET is_edit_mode = TRUE
                CALL edit_category()
            END IF

        COMMAND "Delete"
            CALL delete_category()
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
-- Edit Category (Sub-dialog)
-- ==============================================================
FUNCTION edit_category()

    DIALOG ATTRIBUTES(UNBUFFERED)

        INPUT BY NAME rec_cat.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "category")

            BEFORE INPUT
                MESSAGE "Edit mode enabled. Make changes and click Save or Cancel."

            ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
                CALL save_category()
                EXIT DIALOG

            ON ACTION cancel
                CALL load_category(rec_cat.cat_code) -- Reload to discard changes
                EXIT DIALOG

            AFTER FIELD cat_code
                IF rec_cat.cat_code IS NULL OR rec_cat.cat_code = "" THEN
                    CALL utils_globals.show_error("Category Code is required.")
                    NEXT FIELD cat_code
                END IF

            AFTER FIELD cat_name
                IF rec_cat.cat_name IS NULL OR rec_cat.cat_name = "" THEN
                    CALL utils_globals.show_error("Category Name is required.")
                    NEXT FIELD cat_name
                END IF

        END INPUT

    END DIALOG

END FUNCTION

-- ==============================================================
-- Query using Lookup Window
-- ==============================================================
FUNCTION query_categories()
    DEFINE selected_code STRING

    LET selected_code = query_category()

    IF selected_code IS NOT NULL THEN
        CALL load_category(selected_code)
        -- Update the array to contain just this record for navigation
        CALL arr_codes.clear()
        LET arr_codes[1] = selected_code
        LET curr_idx = 1
    END IF
END FUNCTION

-- ==============================================================
-- SELECT Categories into Array
-- ==============================================================
FUNCTION select_categories(where_clause) RETURNS SMALLINT
    DEFINE where_clause STRING
    DEFINE code STRING
    DEFINE idx INTEGER

    CALL arr_codes.clear()
    LET idx = 0

    DECLARE c_cat_curs CURSOR FROM "SELECT cat_code FROM st02_cat WHERE "
        || where_clause
        || " ORDER BY cat_code"

    FOREACH c_cat_curs INTO code
        LET idx = idx + 1
        LET arr_codes[idx] = code
    END FOREACH

    FREE c_cat_curs

    IF arr_codes.getLength() == 0 THEN
        CALL utils_globals.msg_no_record()
        RETURN FALSE
    END IF

    LET curr_idx = 1
    CALL load_category(arr_codes[curr_idx])
    RETURN TRUE

END FUNCTION

-- ==============================================================
-- Load Single Category
-- ==============================================================
FUNCTION load_category(p_code STRING)

    SELECT * INTO rec_cat.* FROM st02_cat WHERE cat_code = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_cat.*
    END IF

END FUNCTION

-- ==============================================================
-- Navigation
-- ==============================================================
PRIVATE FUNCTION move_record(dir SMALLINT)

    CASE dir
        WHEN -2
            LET curr_idx = 1
        WHEN -1
            IF curr_idx > 1 THEN
                LET curr_idx = curr_idx - 1
            ELSE
                CALL utils_globals.msg_start_of_list()
                RETURN
            END IF
        WHEN 1
            IF curr_idx < arr_codes.getLength() THEN
                LET curr_idx = curr_idx + 1
            ELSE
                CALL utils_globals.msg_end_of_list()
                RETURN
            END IF
        WHEN 2
            LET curr_idx = arr_codes.getLength()
    END CASE

    IF arr_codes.getLength() > 0 THEN
        CALL load_category(arr_codes[curr_idx])
    END IF

END FUNCTION

-- ==============================================================
-- New Category
-- ==============================================================
FUNCTION new_category()
    DEFINE dup_found SMALLINT
    DEFINE ok SMALLINT
    DEFINE new_cat_code STRING

    -- Clear all fields and set defaults
    INITIALIZE rec_cat.* TO NULL
    LET rec_cat.status = "1"

    MESSAGE "Enter new category details, then click Save or Cancel."

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_cat.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_category")

            -- validations
            AFTER FIELD cat_code
                IF rec_cat.cat_code IS NULL OR rec_cat.cat_code = "" THEN
                    CALL utils_globals.show_error("Category Code is required.")
                    NEXT FIELD cat_code
                END IF

            AFTER FIELD cat_name
                IF rec_cat.cat_name IS NULL OR rec_cat.cat_name = "" THEN
                    CALL utils_globals.show_error("Category Name is required.")
                    NEXT FIELD cat_name
                END IF

            -- main actions
            ON ACTION save ATTRIBUTES(TEXT = "Save")
                LET dup_found = check_category_unique(rec_cat.cat_code, rec_cat.cat_name)

                IF dup_found = 0 THEN
                    CALL save_category()
                    EXIT DIALOG
                END IF

            ON ACTION cancel
                LET new_cat_code = NULL
                EXIT DIALOG
        END INPUT
    END DIALOG

    -- Load the newly added record in readonly mode
    IF new_cat_code IS NOT NULL THEN
        CALL load_category(new_cat_code)
        CALL arr_codes.clear()
        LET arr_codes[1] = new_cat_code
        LET curr_idx = 1
    ELSE
        -- Cancelled, reload the list
        LET ok = select_categories("1=1")
    END IF
END FUNCTION

-- ==============================================================
-- Save / Update
-- ==============================================================
FUNCTION save_category()
    DEFINE exists INTEGER

    SELECT COUNT(*)
        INTO exists
        FROM st02_cat
        WHERE cat_code = rec_cat.cat_code

    IF exists = 0 THEN
        -- save data into the db
        INSERT INTO st02_cat VALUES rec_cat.*
        CALL utils_globals.msg_saved()
    ELSE
        -- update record
        UPDATE st02_cat
            SET st02_cat.* = rec_cat.*
            WHERE cat_code = rec_cat.cat_code
        CALL utils_globals.msg_updated()
    END IF

    CALL load_category(rec_cat.cat_code)
END FUNCTION

-- ==============================================================
-- Delete Category
-- ==============================================================
FUNCTION delete_category()
    DEFINE ok SMALLINT

    -- If no record is loaded, skip
    IF rec_cat.cat_code IS NULL OR rec_cat.cat_code = "" THEN
        CALL utils_globals.show_info("No category selected for deletion.")
        RETURN
    END IF

    -- Confirm delete
    LET ok =
        utils_globals.show_confirm(
            "Delete this category: " || rec_cat.cat_name || "?",
            "Confirm Delete")

    IF NOT ok THEN
        MESSAGE "Delete cancelled."
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    DELETE FROM st02_cat WHERE cat_code = rec_cat.cat_code
    CALL utils_globals.msg_deleted()
    LET ok = select_categories("1=1")
END FUNCTION

-- ==============================================================
-- Check category uniqueness
-- ==============================================================
FUNCTION check_category_unique(p_cat_code STRING, p_cat_name STRING)
    RETURNS SMALLINT
    DEFINE dup_count INTEGER
    DEFINE exists SMALLINT

    LET exists = 0

    -- check for duplicate category code
    SELECT COUNT(*) INTO dup_count FROM st02_cat WHERE cat_code = p_cat_code
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Duplicate category code already exists.")
        LET exists = 1
        RETURN exists
    END IF

    -- check for duplicate name
    SELECT COUNT(*) INTO dup_count FROM st02_cat WHERE cat_name = p_cat_name
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Category name already exists.")
        LET exists = 1
        RETURN exists
    END IF

    RETURN exists
END FUNCTION
