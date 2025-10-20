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

DEFINE rec_st_cat RECORD LIKE st02_cat.*

-- Stock items array for display tab
DEFINE arr_stock DYNAMIC ARRAY OF RECORD
    stock_code LIKE st01_mast.stock_code,
    description LIKE st01_mast.description,
    cost LIKE st01_mast.cost,
    selling_price LIKE st01_mast.selling_price,
    stock_on_hand LIKE st01_mast.stock_on_hand,
    status LIKE st01_mast.status
END RECORD

DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

-- ==============================================================
-- Main
-- ==============================================================

--MAIN
--    -- Initialize application (styles, db, etc.)
--    IF NOT utils_globals.initialize_application() THEN
--        DISPLAY "Initialization failed."
--        EXIT PROGRAM 1
--    END IF
--
--    -- NOTE: Form file name kept as provided; ensure st102_cat.4fd/xml exists.
--    OPEN WINDOW w_st02 WITH FORM "st102_cat" ATTRIBUTES(STYLE = "main")
--
--    CALL init_module()
--
--    CLOSE WINDOW w_st02
--END MAIN

-- ==============================================================
-- Init Module
-- ==============================================================

FUNCTION run_stock_cat()
    DEFINE ok SMALLINT
    DEFINE cat_code STRING

    DIALOG ATTRIBUTES(UNBUFFERED)

        -- Master INPUT context
        INPUT BY NAME rec_st_cat.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "Stock Categories")

            BEFORE INPUT
                -- Initial UI state
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION find ATTRIBUTES(TEXT = "Search", IMAGE = "zoom")
                LET cat_code = cat_lookup()
                IF cat_code IS NOT NULL AND cat_code <> "" THEN
                    -- Load the selected code into the form
                    LET ok = load_category_by_code(cat_code)
                    -- Update array for navigation
                    CALL arr_codes.clear()
                    LET arr_codes[1] = cat_code
                    LET curr_idx = 1
                    LET is_edit_mode = FALSE
                    CALL DIALOG.setActionActive("save", FALSE)
                    CALL DIALOG.setActionActive("edit", TRUE)
                ELSE
                    CALL utils_globals.show_info("No category selected.")
                END IF

            ON ACTION new ATTRIBUTES(TEXT = "Create", IMAGE = "new")
                -- Prepare blank record and enable editing
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

            ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
                IF is_edit_mode THEN
                    CALL save_category()
                    LET is_edit_mode = FALSE
                    CALL DIALOG.setActionActive("save", FALSE)
                    CALL DIALOG.setActionActive("edit", TRUE)
                ELSE
                    CALL utils_globals.show_info("Nothing to save.")
                END IF

            ON ACTION delete ATTRIBUTES(TEXT = "Delete", IMAGE = "delete")
                CALL delete_category()
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION mass_assign ATTRIBUTES(TEXT = "Mass Assign", IMAGE = "properties")
                CALL mass_assign_categories()

            ON ACTION first ATTRIBUTES(TEXT = "First Record", IMAGE = "first")
                CALL move_record(-2)
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION previous ATTRIBUTES(TEXT = "Previous", IMAGE = "prev")
                CALL move_record(-1)
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION next ATTRIBUTES(TEXT = "Next", IMAGE = "next")
                CALL move_record(1)
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION last ATTRIBUTES(TEXT = "Last Record", IMAGE = "last")
                CALL move_record(2)
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION quit ATTRIBUTES(TEXT = "Quit", IMAGE = "quit")
                EXIT DIALOG

            -- Field protection in readonly mode
            BEFORE FIELD cat_name, description, status
                IF NOT is_edit_mode THEN
                    CALL utils_globals.show_info(
                        "Click Edit button to modify this record.")
                    NEXT FIELD cat_code
                END IF

        END INPUT

        -- Display stock items for the category
        DISPLAY ARRAY arr_stock TO demoapp_db1.*
            ATTRIBUTES(COUNT = 0)
            -- Display only, no editing
        END DISPLAY

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
    DEFINE code STRING
    DEFINE idx INTEGER
    DEFINE ok SMALLINT

    CALL arr_codes.clear()
    LET idx = 0

    DECLARE c_cat_curs CURSOR FROM "SELECT cat_code FROM st02_cat WHERE "
        || p_where
        || " ORDER BY cat_code"

    FOREACH c_cat_curs INTO code
        LET idx = idx + 1
        LET arr_codes[idx] = code
    END FOREACH
    FREE c_cat_curs

    IF arr_codes.getLength() == 0 THEN
        INITIALIZE rec_st_cat.* TO NULL
        DISPLAY BY NAME rec_st_cat.*
        CALL utils_globals.msg_no_record()
        RETURN FALSE
    END IF

    LET curr_idx = 1
    LET ok = load_category_by_code(arr_codes[curr_idx])
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

    -- Load stock items for this category
    CALL load_stock_for_category(rec_st_cat.id)

    RETURN TRUE
END FUNCTION

-- Load stock items for a specific category
FUNCTION load_stock_for_category(p_cat_id INTEGER)
    DEFINE idx INTEGER

    CALL arr_stock.clear()
    LET idx = 0

    DECLARE c_stock_curs CURSOR FOR
        SELECT stock_code,
            description,
            cost,
            selling_price,
            stock_on_hand,
            status
        FROM st01_mast
        WHERE category_id = p_cat_id
        ORDER BY stock_code

    FOREACH c_stock_curs INTO arr_stock[idx + 1].*
        LET idx = idx + 1
    END FOREACH

    FREE c_stock_curs
END FUNCTION

-- Create new category (inline modal)
FUNCTION new_cat()
    DEFINE new_cat_code STRING
    DEFINE ok SMALLINT

    -- Open a modal window for new category
    OPEN WINDOW w_new WITH FORM "st102_cat" ATTRIBUTES(STYLE = "main")

    -- Clear current buffer and prompt for a fresh record
    INITIALIZE rec_st_cat.* TO NULL
    LET rec_st_cat.status = "1" -- Default to Active
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
                -- Validate and insert
                LET ok = validate_input(rec_st_cat.cat_code, rec_st_cat.cat_name)
                IF ok = 0 THEN
                    INSERT INTO st02_cat
                        VALUES
                            rec_st_cat.*

                    CALL utils_globals.show_success("Category saved successfully.")
                    LET new_cat_code = rec_st_cat.cat_code
                    EXIT DIALOG
                END IF

            ON ACTION cancel
                LET new_cat_code = NULL
                EXIT DIALOG
        END INPUT
    END DIALOG

    CLOSE WINDOW w_new

    -- Load the newly added record in readonly mode
    IF new_cat_code IS NOT NULL THEN
        LET ok = load_category_by_code(new_cat_code)
        CALL arr_codes.clear()
        LET arr_codes[1] = new_cat_code
        LET curr_idx = 1
    ELSE
        -- Cancelled, reload the list
        LET ok = select_stock_cat("1=1")
    END IF
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
    DEFINE ok SMALLINT

    CASE p_value
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

    IF arr_codes.getLength() == 0 THEN
        INITIALIZE rec_st_cat.* TO NULL
        DISPLAY BY NAME rec_st_cat.*
    ELSE
        LET ok = load_category_by_code(arr_codes[curr_idx])
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

-- ==============================================================
-- Mass Assignment - Update multiple categories
-- ==============================================================
FUNCTION mass_assign_categories()
    DEFINE rec_mass RECORD
        apply_status SMALLINT,
        new_status LIKE st02_cat.status,
        filter_status LIKE st02_cat.status,
        filter_code_pattern STRING
    END RECORD

    DEFINE update_count INTEGER
    DEFINE where_clause STRING
    DEFINE ok SMALLINT
    DEFINE sql_stmt STRING

    -- Initialize mass assignment record
    LET rec_mass.apply_status = 0
    LET rec_mass.new_status = "1"

    -- Simple INPUT for mass assignment (no form, just prompts)
    MENU "Mass Assignment Options"
        ATTRIBUTES(STYLE = "dialog", COMMENT = "Select categories to update")

        BEFORE MENU
            CALL DIALOG.setActionActive("accept", TRUE)

        COMMAND "Status Update"
            -- Prompt for status change
            LET rec_mass.apply_status = 1
            PROMPT "Enter new status (0=Inactive, 1=Active, -1=Archived): "
                FOR rec_mass.new_status

            PROMPT "Filter by status (leave blank for all, 0/1/-1): "
                FOR rec_mass.filter_status

            PROMPT "Filter by code pattern (e.g., 'CAT%', or blank for all): "
                FOR rec_mass.filter_code_pattern

            -- Build where clause
            LET where_clause = "1=1"

            IF rec_mass.filter_status IS NOT NULL
                AND rec_mass.filter_status != "" THEN
                LET where_clause =
                    where_clause
                    || " AND status = '"
                    || rec_mass.filter_status
                    || "'"
            END IF

            IF rec_mass.filter_code_pattern IS NOT NULL
                AND rec_mass.filter_code_pattern != "" THEN
                LET where_clause =
                    where_clause
                    || " AND cat_code LIKE '"
                    || rec_mass.filter_code_pattern
                    || "'"
            END IF

            -- Show preview count
            LET sql_stmt = "SELECT COUNT(*) FROM st02_cat WHERE " || where_clause
            PREPARE cnt_stmt FROM sql_stmt
            EXECUTE cnt_stmt INTO update_count
            FREE cnt_stmt

            -- Confirm the mass update
            LET ok =
                utils_globals.show_confirm(
                    "Apply status update to "
                    || update_count
                    || " categories?",
                    "Confirm Mass Assignment")

            IF ok THEN
                -- Apply the update
                LET sql_stmt =
                    "UPDATE st02_cat SET status = '"
                    || rec_mass.new_status
                    || "' WHERE "
                    || where_clause
                PREPARE upd_stmt FROM sql_stmt
                EXECUTE upd_stmt
                LET update_count = SQLCA.SQLERRD[3]
                FREE upd_stmt

                CALL utils_globals.show_success(
                    update_count || " categories updated successfully.")
                EXIT MENU
            ELSE
                MESSAGE "Mass assignment cancelled."
            END IF

        COMMAND "Cancel"
            EXIT MENU

    END MENU

    -- Reload current record to reflect any changes
    IF rec_st_cat.cat_code IS NOT NULL THEN
        LET ok = load_category_by_code(rec_st_cat.cat_code)
    END IF
END FUNCTION
