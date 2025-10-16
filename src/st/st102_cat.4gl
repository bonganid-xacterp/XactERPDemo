-- ==============================================================
-- Program   : st02_cat.4gl
-- Purpose   : Category Master maintenance
-- Module    : Stock Category (st)
-- Number    : 02
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL utils_db
IMPORT FGL utils_lookup
IMPORT FGL utils_status_const
IMPORT FGL st122_cat_lkup

SCHEMA demoapp_db

-- ==============================================================
-- Record definition
-- ==============================================================

TYPE t_stock_cat RECORD
    cat_code LIKE st02_cat.cat_code,
    cat_name LIKE st02_cat.cat_name,
    description LIKE st02_cat.description,
    status LIKE st02_cat.status
END RECORD

DEFINE rec_st_cat t_stock_cat
DEFINE is_edit_mode SMALLINT

DEFINE dlg ui.Dialog

-- ==============================================================
-- Main
-- ==============================================================

MAIN
    -- Initialize application (styles, db, etc.)
    IF NOT utils_globals.initialize_application() THEN
        DISPLAY "Initialization failed."
        EXIT PROGRAM 1
    END IF

    -- NOTE: Form file name kept as provided; ensure st102_cat.4fd/xml exists.
    OPEN WINDOW w_st02 WITH FORM "st102_cat" ATTRIBUTES(STYLE = "main")

    CALL init_module()

    CLOSE WINDOW w_st02
END MAIN

-- ==============================================================
-- Init Module
-- ==============================================================

FUNCTION init_module()
    DEFINE ok SMALLINT
    DEFINE cat_code STRING

    DIALOG ATTRIBUTES(UNBUFFERED)

        -- Master INPUT context
        INPUT BY NAME rec_st_cat.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "Stock Categories")

            BEFORE INPUT
                -- Initial UI state
                LET is_edit_mode = FALSE
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", FALSE)

                -- -------------------------
                -- Toolbar / Actions
                -- -------------------------

            ON ACTION find ATTRIBUTES(TEXT = "Search", IMAGE = "zoom")
                LET cat_code = cat_lookup()
                IF cat_code IS NOT NULL AND cat_code <> "" THEN
                    -- Load the selected code into the form
                    LET ok = load_category_by_code(cat_code)
                    -- After loading, user can choose to edit
                    CALL dlg.setActionActive("edit", TRUE)
                    CALL dlg.setActionActive("save", FALSE)
                    LET is_edit_mode = FALSE
                ELSE
                    CALL utils_globals.show_info("No category selected.")
                END IF

            ON ACTION new ATTRIBUTES(TEXT = "Create", IMAGE = "new")
                -- Prepare blank record and enable editing
                CALL new_cat()
                LET is_edit_mode = FALSE
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)

            ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
                IF rec_st_cat.cat_code IS NULL OR rec_st_cat.cat_code = "" THEN
                    CALL utils_globals.show_info(
                        "No category selected to edit.")
                ELSE
                    LET is_edit_mode = TRUE
                    CALL dlg.setActionActive("save", TRUE)
                    CALL dlg.setActionActive("edit", FALSE)
                    MESSAGE "Edit mode enabled. Make changes and click Save."
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Save", IMAGE = "filesave")
                IF is_edit_mode THEN
                    CALL save_category()
                    LET is_edit_mode = FALSE
                    CALL dlg.setActionActive("save", FALSE)
                    CALL dlg.setActionActive("edit", TRUE)
                ELSE
                    CALL utils_globals.show_info("Nothing to save.")
                END IF

            ON ACTION delete ATTRIBUTES(TEXT = "Delete", IMAGE = "delete")
                -- Use non-reserved action name 'delete' (lowercase) for safety
                CALL delete_category()
                -- After delete, we leave edit disabled until a record is loaded
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)
                LET is_edit_mode = FALSE

            ON ACTION first ATTRIBUTES(TEXT = "First Record", IMAGE = "first")
                CALL move_record(-2)
                LET is_edit_mode = FALSE
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)

            ON ACTION previous ATTRIBUTES(TEXT = "Previous", IMAGE = "prev")
                CALL move_record(-1)
                LET is_edit_mode = FALSE
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)

            ON ACTION next ATTRIBUTES(TEXT = "Next", IMAGE = "next")
                CALL move_record(1)
                LET is_edit_mode = FALSE
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)

            ON ACTION last ATTRIBUTES(TEXT = "Last Record", IMAGE = "last")
                CALL move_record(2)
                LET is_edit_mode = FALSE
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)

            ON ACTION quit ATTRIBUTES(TEXT = "Quit", IMAGE = "quit")
                EXIT DIALOG

        END INPUT

        BEFORE DIALOG
            -- Initial load: go to the first available category (if any)
            LET ok = select_stock_cat("1=1")
            LET is_edit_mode = FALSE

    END DIALOG
END FUNCTION

-- ==============================================================
-- Helpers
-- ==============================================================

-- Initial load (or filtered refresh)
FUNCTION select_stock_cat(p_where STRING) RETURNS SMALLINT
    DEFINE first_code STRING
    DEFINE ok SMALLINT

    SELECT MIN(cat_code) INTO first_code FROM st02_cat
    IF first_code IS NULL THEN
        -- No data; clear the screen
        INITIALIZE rec_st_cat.* TO NULL
        DISPLAY BY NAME rec_st_cat.*
        RETURN FALSE
    END IF

    LET ok = load_category_by_code(first_code)
    RETURN ok
END FUNCTION

-- Lookup popup ? returns selected category code
FUNCTION cat_lookup() RETURNS STRING
    DEFINE s_code STRING
    -- st122_cat_lkup.load_lookup() opens and closes its own popup
    LET s_code = st122_cat_lkup.load_lookup()
    RETURN s_code
END FUNCTION

-- Load category into current record and display
FUNCTION load_category_by_code(p_code STRING) RETURNS SMALLINT
    WHENEVER ERROR CONTINUE

    SELECT cat_code, cat_name, description, status
        INTO rec_st_cat.cat_code,
            rec_st_cat.cat_name,
            rec_st_cat.description,
            rec_st_cat.status
        FROM st02_cat
        WHERE cat_code = p_code

    IF SQLCA.SQLCODE <> 0 THEN
        CALL utils_globals.show_info("Category not found.")
        RETURN FALSE
    END IF

    DISPLAY BY NAME rec_st_cat.*
    RETURN TRUE
END FUNCTION

-- Create new category (inline modal)
FUNCTION new_cat()
    -- Clear current buffer and prompt for a fresh record
    INITIALIZE rec_st_cat.* TO NULL
    DISPLAY BY NAME rec_st_cat.*
    MESSAGE "Enter new category details, then click Save or Cancel."

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_st_cat.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_category")

            AFTER FIELD cat_code
                IF rec_st_cat.cat_code IS NULL OR rec_st_cat.cat_code = "" THEN
                    CALL utils_globals.show_error("Category Code is required.")
                    NEXT FIELD cat_code
                END IF

            AFTER FIELD cat_name
                IF rec_st_cat.cat_name IS NULL OR rec_st_cat.cat_name = "" THEN
                    CALL utils_globals.show_error("Category Name is required.")
                    NEXT FIELD cat_name
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Save")
                -- Save will insert or update (insert expected for new)
                CALL save_category()
                EXIT DIALOG

            ON ACTION cancel
                EXIT DIALOG
        END INPUT
    END DIALOG
END FUNCTION

-- Insert or Update category
FUNCTION save_category()
    DEFINE cnt INTEGER
    DEFINE ok SMALLINT

    -- Basic validations
    IF rec_st_cat.cat_code IS NULL OR rec_st_cat.cat_code = "" THEN
        CALL utils_globals.show_error(
            "Nothing to save: Category Code is empty.")
        RETURN
    END IF

    IF rec_st_cat.cat_name IS NULL OR rec_st_cat.cat_name = "" THEN
        CALL utils_globals.show_error("Category Name is required.")
        RETURN
    END IF

    -- Does the key exist?
    SELECT COUNT(*) INTO cnt FROM st02_cat WHERE cat_code = rec_st_cat.cat_code

    IF cnt = 0 THEN
        -- New record: enforce duplicate checks on both code and name
        LET ok = validate_input(rec_st_cat.cat_code, rec_st_cat.cat_name)
        IF ok = 1 THEN
            -- Duplicate detected; do not proceed
            RETURN
        END IF

        INSERT INTO st02_cat(
            cat_code, cat_name, description, status)
            VALUES(rec_st_cat.cat_code,
                rec_st_cat.cat_name,
                rec_st_cat.description,
                rec_st_cat.status)

        CALL utils_globals.msg_saved()
    ELSE
        -- Update existing
        UPDATE st02_cat
            SET cat_name = rec_st_cat.cat_name,
                description = rec_st_cat.description,
                status = rec_st_cat.status
            WHERE cat_code = rec_st_cat.cat_code

        CALL utils_globals.msg_updated()
    END IF

    -- Refresh screen to a stable state (first record)
    LET ok = select_stock_cat("1=1")
    LET is_edit_mode = FALSE
END FUNCTION

-- Delete current category
FUNCTION delete_category()
    DEFINE ans CHAR(1)

    IF rec_st_cat.cat_code IS NULL OR rec_st_cat.cat_code = "" THEN
        CALL utils_globals.show_info("No category selected to delete.")
        RETURN
    END IF

    LET ans =
        utils_globals.show_confirm(
            "Do you want to delete this record ?", "Deleting Record")

    IF ans = "Y" THEN
        DELETE FROM st02_cat WHERE cat_code = rec_st_cat.cat_code
        CALL utils_globals.msg_deleted()
        -- Move to the next logical record after delete
        CALL move_record(1)
    END IF
END FUNCTION

-- Navigation: -2=FIRST, -1=PREV, 1=NEXT, 2=LAST
FUNCTION move_record(p_value SMALLINT)
    DEFINE code STRING
    DEFINE ok SMALLINT

    CASE p_value
        WHEN -2
            SELECT MIN(cat_code) INTO code FROM st02_cat
        WHEN 2
            SELECT MAX(cat_code) INTO code FROM st02_cat
        WHEN -1
            IF rec_st_cat.cat_code IS NULL OR rec_st_cat.cat_code = "" THEN
                SELECT MAX(cat_code) INTO code FROM st02_cat
            ELSE
                SELECT MAX(cat_code)
                    INTO code
                    FROM st02_cat
                    WHERE cat_code < rec_st_cat.cat_code
                IF code IS NULL THEN
                    SELECT MIN(cat_code) INTO code FROM st02_cat
                END IF
            END IF
        WHEN 1
            IF rec_st_cat.cat_code IS NULL OR rec_st_cat.cat_code = "" THEN
                SELECT MIN(cat_code) INTO code FROM st02_cat
            ELSE
                SELECT MIN(cat_code)
                    INTO code
                    FROM st02_cat
                    WHERE cat_code > rec_st_cat.cat_code
                IF code IS NULL THEN
                    SELECT MAX(cat_code) INTO code FROM st02_cat
                END IF
            END IF
        OTHERWISE
            LET code = rec_st_cat.cat_code
    END CASE

    IF code IS NULL THEN
        INITIALIZE rec_st_cat.* TO NULL
        DISPLAY BY NAME rec_st_cat.*
    ELSE
        LET ok = load_category_by_code(code)
    END IF
END FUNCTION

-- Duplicate checks (returns 1 if duplicate exists, else 0)
FUNCTION validate_input(p_cat_code STRING, p_cat_name STRING) RETURNS SMALLINT
    DEFINE dup_count INTEGER

    -- Check code duplicate
    SELECT COUNT(*) INTO dup_count FROM st02_cat WHERE cat_code = p_cat_code
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Duplicate category code already exists.")
        RETURN 1
    END IF

    -- Check name duplicate
    SELECT COUNT(*) INTO dup_count FROM st02_cat WHERE cat_name = p_cat_name
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Duplicate category name already exists.")
        RETURN 1
    END IF

    RETURN 0
END FUNCTION
