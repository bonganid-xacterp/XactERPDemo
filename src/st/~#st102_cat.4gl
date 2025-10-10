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

SCHEMA xactdemo_db

-- ==============================================================
-- Record definition
-- ==============================================================

TYPE t_stock_cat RECORD
    cat_code     LIKE st02_cat.cat_code,
    cat_name     LIKE st02_cat.cat_name,
    description  LIKE st02_cat.description,
    status       LIKE st02_cat.status
END RECORD

DEFINE rec_st_cat      t_stock_cat
DEFINE is_edit_mode    SMALLINT

-- ==============================================================
-- Main
-- ==============================================================

MAIN
    IF NOT utils_globals.initialize_application() THEN
        DISPLAY "Initialization failed."
        EXIT PROGRAM 1
    END IF

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

        INPUT BY NAME rec_st_cat.* ATTRIBUTES(WITHOUT DEFAULTS, NAME = "Stock Categories")

            BEFORE INPUT
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", FALSE)

            ON ACTION find ATTRIBUTES(TEXT = "Search", IMAGE = "zoom")
                LET cat_code = cat_lookup()

            ON ACTION new  ATTRIBUTES(TEXT = "Create", IMAGE = "new")
                CALL new_cat()
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
                IF rec_st_cat.cat_code IS NULL OR rec_st_cat.cat_code = "" THEN
                    CALL utils_globals.show_info("No category selected to edit.")
                ELSE
                    LET is_edit_mode = TRUE
                    CALL DIALOG.setActionActive("save", TRUE)
                    CALL DIALOG.setActionActive("edit", FALSE)
                    MESSAGE "Edit mode enabled. Make changes and click Save."
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Save", IMAGE = "filesave")
                IF is_edit_mode THEN
                    CALL save_category()
                    LET is_edit_mode = FALSE
                    CALL DIALOG.setActionActive("save", FALSE)
                    CALL DIALOG.setActionActive("edit", TRUE)
                END IF

            ON ACTION DELETE ATTRIBUTES(TEXT = "Delete", IMAGE = "delete")
                CALL delete_category()

            ON ACTION FIRST ATTRIBUTES(TEXT = "First Record", IMAGE = "first")
                CALL move_record(-2)
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION PREVIOUS ATTRIBUTES(TEXT = "Previous", IMAGE = "prev")
                CALL move_record(-1)
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION NEXT ATTRIBUTES(TEXT = "Next", IMAGE = "next")
                CALL move_record(1)
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION LAST ATTRIBUTES(TEXT = "Last Record", IMAGE = "last")
                CALL move_record(2)
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION QUIT ATTRIBUTES(TEXT = "Quit", IMAGE = "quit")
                EXIT DIALOG

        END INPUT

        BEFORE DIALOG
            -- initial load
            LET ok = select_stock_cat("1=1")
            LET is_edit_mode = FALSE

    END DIALOG
END FUNCTION

-- ==============================================================
-- Helpers
-- ==============================================================

-- Initial load (or filtered refresh)
FUNCTION select_stock_cat(p_where STRING) RETURNS SMALLINT
    DEFINE code STRING
    SELECT MIN(cat_code) INTO code FROM st02_cat
    IF code IS NULL THEN
        INITIALIZE rec_st_cat.* TO NULL
        DISPLAY BY NAME rec_st_cat.*
        RETURN FALSE
    END IF
    LET code = load_category_by_code(code)
    RETURN TRUE
END FUNCTION


-- Lookup popup ? loads selected category
FUNCTION cat_lookup() RETURNS STRING
    DEFINE s_code STRING
    -- st122_cat_lkup.load_lookup() should open/close its own popup
    LET s_code = st122_cat_lkup.load_lookup()
    RETURN s_code
END FUNCTION


-- Load category into current record and display
FUNCTION load_category_by_code(p_code STRING) RETURNS SMALLINT
    WHENEVER ERROR CONTINUE
    SELECT cat_code, cat_name, description, status
      INTO rec_st_cat.cat_code, rec_st_cat.cat_name, rec_st_cat.description, rec_st_cat.status
      FROM st02_cat
     WHERE cat_code = p_code

    IF SQLCA.SQLCODE <> 0 THEN
        CALL utils_globals.show_info("Category not found.")
        RETURN FALSE
    END IF

    DISPLAY BY NAME rec_st_cat.*
    RETURN TRUE
END FUNCTION

-- Create new category (modal)
FUNCTION new_cat()
    DEFINE dup_found SMALLINT

    OPEN WINDOW w_new WITH FORM "st102_cat" ATTRIBUTES(STYLE = "main")

    INITIALIZE rec_st_cat.* TO NULL
    DISPLAY BY NAME rec_st_cat.*
    MESSAGE "Enter new category details, then click Save or Cancel."

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_st_cat.* ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_category")

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

            AFTER FIELD description
                IF rec_st_cat.description IS NULL OR rec_st_cat.description = "" THEN
                    CALL utils_globals.show_error("Description is required.")
                    NEXT FIELD description
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Save")
                LET dup_found = validate_input(
                    rec_st_cat.cat_code,
                    rec_st_cat.cat_name,
                    rec_st_cat.description)

                IF dup_found = 0 THEN
                    CALL save_category()
                    EXIT DIALOG
                END IF

            ON ACTION cancel
                EXIT DIALOG
        END INPUT
    END DIALOG

    CLOSE WINDOW w_new
END FUNCTION

-- Insert or Update category
FUNCTION save_category()
    DEFINE cnt INTEGER
    DEFINE cat_code STRING 

    IF rec_st_cat.cat_code IS NULL THEN
        CALL utils_globals.show_error("Nothing to save: Category Code is empty.")
        RETURN
    END IF

    SELECT COUNT(*) INTO cnt FROM st02_cat WHERE cat_code = rec_st_cat.cat_code

    IF cnt = 0 THEN
        INSERT INTO st02_cat (
        cat_code, 
        cat_name, 
        description, 
        status)
        VALUES (
        rec_st_cat.cat_code, 
        rec_st_cat.cat_name, 
        rec_st_cat.description, 
        rec_st_cat.status)
        CALL utils_globals.get_msg_saved()
    ELSE
        UPDATE st02_cat
           SET cat_name    = rec_st_cat.cat_name,
               description = rec_st_cat.description,
               status      = rec_st_cat.status
         WHERE cat_code    = rec_st_cat.cat_code
        CALL utils_globals.get_msg_updated()
    END IF

    -- Refresh the display from DB (trusted source)
    LET cat_code =  load_category_by_code(rec_st_cat.cat_code)
END FUNCTION

-- Delete current category
FUNCTION delete_category()
    DEFINE ans CHAR(1)

    IF rec_st_cat.cat_code IS NULL OR rec_st_cat.cat_code = "" THEN
        CALL utils_globals.show_info("No category selected to delete.")
        RETURN
    END IF

    LET ans = utils_globals.show_confirm('Do you want to delete this record ?', 'Deleting Record')

    IF ans = "Y" THEN
        DELETE FROM st02_cat WHERE cat_code = rec_st_cat.cat_code
        CALL utils_globals.get_msg_deleted()
        -- move to next logical record after delete
        CALL move_record(1)
    END IF
END FUNCTION


-- Navigation: -2=FIRST, -1=PREV, 1=NEXT, 2=LAST
FUNCTION move_record(p_value SMALLINT)
    DEFINE code STRING

    CASE p_value
        WHEN -2
            SELECT MIN(cat_code) INTO code FROM st02_cat
        WHEN 2
            SELECT MAX(cat_code) INTO code FROM st02_cat
        WHEN -1
            IF rec_st_cat.cat_code IS NULL OR rec_st_cat.cat_code = "" THEN
                SELECT MAX(cat_code) INTO code FROM st02_cat
            ELSE
                SELECT MAX(cat_code) INTO code FROM st02_cat WHERE cat_code < rec_st_cat.cat_code
                IF code IS NULL THEN
                    SELECT MIN(cat_code) INTO code FROM st02_cat
                END IF
            END IF
        WHEN 1
            IF rec_st_cat.cat_code IS NULL OR rec_st_cat.cat_code = "" THEN
                SELECT MIN(cat_code) INTO code FROM st02_cat
            ELSE
                SELECT MIN(cat_code) INTO code FROM st02_cat WHERE cat_code > rec_st_cat.cat_code
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
        LET code = load_category_by_code(code)
    END IF
END FUNCTION

-- Duplicate checks
FUNCTION validate_input(p_cat_code STRING, p_cat_name STRING, p_description STRING) RETURNS SMALLINT
    DEFINE dup_count INTEGER
    DEFINE exists SMALLINT

    LET exists = 0

    SELECT COUNT(*) INTO dup_count FROM st02_cat WHERE cat_code = p_cat_code
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Duplicate category code already exists.")
        LET exists = 1
        RETURN exists
    END IF

    SELECT COUNT(*) INTO dup_count FROM st02_cat WHERE cat_name = p_cat_name
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Duplicate category name already exists.")
        LET exists = 1
        RETURN exists
    END IF

    SELECT COUNT(*) INTO dup_count FROM st02_cat WHERE description = p_description
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Duplicate description already exists.")
        LET exists = 1
        RETURN exists
    END IF

    RETURN exists
END FUNCTION
