-- ==============================================================
-- Program   : st102_cat.4gl
-- Purpose   : Stock Category Master Maintenance
-- Module    : Stock Category (st)
-- Number    : 102
-- Author    : Bongani Dlamini
-- Version   : Genero 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL utils_lkup   -- ? Global lookup utility (replaces st122_cat_lkup)
IMPORT FGL st122_cat_lkup

SCHEMA demoappdb

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE category_t RECORD LIKE st02_cat.*
DEFINE rec_cat category_t

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
--        OPEN WINDOW w_st_cat WITH FORM "st102_cat" ATTRIBUTES(STYLE="dialog")
--    ELSE
--        OPEN WINDOW w_st_cat WITH FORM "st102_cat" ATTRIBUTES(STYLE="child")
--    END IF
--
--    CALL init_category_module()
--
--    IF utils_globals.is_standalone() THEN
--        CLOSE WINDOW w_st_cat
--    END IF
--END MAIN


-- ==============================================================
-- Lookup Popup using utils_lookup
-- ==============================================================
FUNCTION query_category() RETURNS STRING
    DEFINE selected_code STRING

    -- ? Use generic lookup function from utils_lookup
    LET selected_code = st122_cat_lkup.load_lookup()

    RETURN selected_code
END FUNCTION


-- ==============================================================
-- Main Controller Menu
-- ==============================================================
FUNCTION init_category_module()
    LET is_edit_mode = FALSE
    CALL utils_globals.set_form_label("lbl_form_title", "STOCK CATEGORY MAINTENANCE")

     -- initialize the list of records
    CALL load_all_categories()

    MENU "Category Menu"

        COMMAND "Find"
            CALL query_categories()
            LET is_edit_mode = FALSE

        COMMAND "New"
            CALL new_category()
            LET is_edit_mode = FALSE

        COMMAND "Edit"
            IF rec_cat.cat_code IS NULL OR rec_cat.cat_code = "" THEN
                CALL utils_globals.show_info("No category selected to edit.")
            ELSE
                LET is_edit_mode = TRUE
                CALL edit_category()
            END IF

        COMMAND "Delete"
            CALL delete_category()
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
-- Query using Lookup
-- ==============================================================
FUNCTION query_categories()
    DEFINE selected_code STRING
    LET selected_code = query_category()

    IF selected_code IS NULL OR selected_code = "" THEN
        RETURN
    END IF

    CALL load_category(selected_code)

    CALL arr_codes.clear()
    LET arr_codes[1] = selected_code
    LET curr_idx = 1
END FUNCTION

-- ==============================================================
-- Load all categories into array
-- ==============================================================
FUNCTION load_all_categories()
    DEFINE ok SMALLINT
    LET ok = select_categories("1=1")

    IF ok THEN
        MESSAGE SFMT("Loaded %1 category(ies)", arr_codes.getLength())
    ELSE
        CALL utils_globals.show_info("No categories found.")
        INITIALIZE rec_cat.* TO NULL
        DISPLAY BY NAME rec_cat.*
    END IF
END FUNCTION

-- ==============================================================
-- Select categories into array
-- ==============================================================
FUNCTION select_categories(where_clause STRING) RETURNS SMALLINT
    DEFINE code STRING
    DEFINE idx INTEGER
    DEFINE sql_stmt STRING

    CALL arr_codes.clear()
    LET idx = 0
    LET sql_stmt = "SELECT cat_code FROM st02_cat"

    IF where_clause IS NOT NULL AND where_clause != "" THEN
        LET sql_stmt = sql_stmt || " WHERE " || where_clause
    END IF

    LET sql_stmt = sql_stmt || " ORDER BY cat_code"

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
    CALL load_category(arr_codes[curr_idx])
    RETURN TRUE
END FUNCTION

-- ==============================================================
-- Load Single Category
-- ==============================================================
FUNCTION load_category(p_code STRING)

    DISPLAY p_code
    SELECT * INTO rec_cat.* FROM st02_cat WHERE cat_code = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_cat.*
    ELSE
        INITIALIZE rec_cat.* TO NULL
        DISPLAY BY NAME rec_cat.*
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
    CALL load_category(arr_codes[curr_idx])
END FUNCTION

-- ==============================================================
-- New Category
-- ==============================================================
FUNCTION new_category()
    DEFINE dup_found, new_id SMALLINT
    DEFINE next_num INTEGER
    DEFINE next_full STRING
    DEFINE i, array_size INTEGER

    INITIALIZE rec_cat.* TO NULL

    CALL utils_globals.get_next_number("st02_cat", "CAT")
        RETURNING next_num, next_full

    LET rec_cat.cat_code = next_full
    LET rec_cat.status = "active"
    LET rec_cat.created_at = CURRENT
    LET rec_cat.created_by = utils_globals.get_current_user_id()

    CALL utils_globals.set_form_label("lbl_form_title", "NEW CATEGORY")

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_cat.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME="new_category")

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

            ON ACTION save ATTRIBUTES(TEXT="Save", IMAGE="filesave")
                LET dup_found = check_category_unique(rec_cat.cat_code, rec_cat.cat_name)
                IF dup_found = 0 THEN
                    CALL save_category()
                    LET new_id = rec_cat.id
                    CALL utils_globals.show_info("Category saved successfully.")
                    EXIT DIALOG
                ELSE
                    CALL utils_globals.show_error("Duplicate category found.")
                END IF

            ON ACTION cancel
                CALL utils_globals.show_info("Creation cancelled.")
                LET new_id = NULL
                EXIT DIALOG
        END INPUT
    END DIALOG

    -- Reload the list and position to the new record
    IF new_id IS NOT NULL THEN
        CALL load_all_categories()
        LET array_size = arr_codes.getLength()
        IF array_size > 0 THEN
            FOR i = 1 TO array_size
                IF arr_codes[i] = rec_cat.cat_code THEN
                    LET curr_idx = i
                    EXIT FOR
                END IF
            END FOR
        END IF
        CALL load_category(rec_cat.cat_code)
    ELSE
        LET array_size = arr_codes.getLength()
        IF array_size > 0 AND curr_idx >= 1 AND curr_idx <= array_size THEN
            CALL load_category(arr_codes[curr_idx])
        ELSE
            LET curr_idx = 0
            INITIALIZE rec_cat.* TO NULL
            DISPLAY BY NAME rec_cat.*
        END IF
    END IF
END FUNCTION

-- ==============================================================
-- Edit Category
-- ==============================================================
FUNCTION edit_category()
    CALL utils_globals.set_form_label("lbl_form_title", "EDIT CATEGORY")

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_cat.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME="edit_category")

            ON ACTION save ATTRIBUTES(TEXT="Update", IMAGE="filesave")
                CALL save_category()
                EXIT DIALOG

            ON ACTION cancel
                CALL load_category(rec_cat.cat_code)
                EXIT DIALOG

            AFTER FIELD cat_name
                IF rec_cat.cat_name IS NULL OR rec_cat.cat_name = "" THEN
                    CALL utils_globals.show_error("Category Name is required.")
                    NEXT FIELD cat_name
                END IF
        END INPUT
    END DIALOG
END FUNCTION

-- ==============================================================
-- Save / Update
-- ==============================================================
FUNCTION save_category()
    DEFINE exists INTEGER
    DEFINE l_user INTEGER

    LET l_user = utils_globals.get_current_user_id()

    BEGIN WORK
    TRY
        SELECT COUNT(*) INTO exists FROM st02_cat WHERE cat_code = rec_cat.cat_code

        IF exists = 0 THEN
            INSERT INTO st02_cat VALUES rec_cat.*
            COMMIT WORK
            CALL utils_globals.msg_saved()
        ELSE
            UPDATE st02_cat SET
                cat_name = rec_cat.cat_name,
                description = rec_cat.description,
                status = rec_cat.status,
                updated_at = CURRENT
            WHERE cat_code = rec_cat.cat_code
            COMMIT WORK
            CALL utils_globals.msg_updated()
        END IF

        CALL load_category(rec_cat.cat_code)

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Save failed: %1", SQLCA.SQLCODE))
    END TRY
END FUNCTION

-- ==============================================================
-- Delete Category
-- ==============================================================
FUNCTION delete_category()
    DEFINE ok SMALLINT
    DEFINE deleted_code STRING
    DEFINE array_size INTEGER

    IF rec_cat.cat_code IS NULL OR rec_cat.cat_code = "" THEN
        CALL utils_globals.show_info("No category selected for deletion.")
        RETURN
    END IF

    LET ok = utils_globals.show_confirm(
        "Delete this category: " || rec_cat.cat_name || "?",
        "Confirm Delete"
    )

    IF NOT ok THEN
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    LET deleted_code = rec_cat.cat_code
    DELETE FROM st02_cat WHERE cat_code = deleted_code
    CALL utils_globals.msg_deleted()

    -- Reload list and navigate to valid record
    CALL load_all_categories()
    LET array_size = arr_codes.getLength()

    IF array_size > 0 THEN
        IF curr_idx > array_size THEN
            LET curr_idx = array_size
        END IF
        IF curr_idx < 1 THEN
            LET curr_idx = 1
        END IF
        CALL load_category(arr_codes[curr_idx])
    ELSE
        LET curr_idx = 0
        INITIALIZE rec_cat.* TO NULL
        DISPLAY BY NAME rec_cat.*
    END IF
END FUNCTION


-- ==============================================================
-- Check Category Uniqueness
-- ==============================================================
FUNCTION check_category_unique(p_cat_code STRING, p_cat_name STRING) RETURNS SMALLINT
    DEFINE dup_count INTEGER

    SELECT COUNT(*) INTO dup_count FROM st02_cat WHERE cat_code = p_cat_code
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Category code already exists.")
        RETURN 1
    END IF

    SELECT COUNT(*) INTO dup_count FROM st02_cat WHERE cat_name = p_cat_name
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Category name already exists.")
        RETURN 1
    END IF

    RETURN 0
END FUNCTION
