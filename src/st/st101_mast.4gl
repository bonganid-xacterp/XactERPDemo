-- ==============================================================
-- Program   : st101_mast.4gl
-- Purpose   : Stock Master maintenance
-- Module    : Stock Master (st)
-- Number    : 101
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL utils_db
IMPORT FGL st121_st_lkup
IMPORT FGL st122_cat_lkup
IMPORT FGL utils_status_const

SCHEMA demoapp_db

-- ==============================================================
-- Record definitions
-- ==============================================================
TYPE stock_t RECORD
    stock_code LIKE st01_mast.stock_code,
    description LIKE st01_mast.description,
    barcode LIKE st01_mast.barcode,
    batch_control LIKE st01_mast.batch_control,
    category_id LIKE st01_mast.category_id,
    cost LIKE st01_mast.cost,
    selling_price LIKE st01_mast.selling_price,
    stock_on_hand LIKE st01_mast.stock_on_hand,
    total_purch LIKE st01_mast.total_purch,
    total_sales LIKE st01_mast.total_sales,
    status LIKE st01_mast.status
END RECORD

-- Transaction array (for display purposes)
DEFINE arr_st_trans DYNAMIC ARRAY OF RECORD
    trans_date LIKE st30_trans.trans_date,
    trans_type LIKE st30_trans.trans_type,
    direction LIKE st30_trans.direction,
    qty LIKE st30_trans.qty,
    id LIKE st30_trans.id,
    unit_cost LIKE st30_trans.unit_cost,
    expiry_date LIKE st30_trans.expiry_date,
    doc_type LIKE st30_trans.doc_type
END RECORD

DEFINE rec_stock stock_t
DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

-- Mass assignment record (module-level)
DEFINE m_rec_mass RECORD
    apply_category SMALLINT,
    category_id LIKE st01_mast.category_id,
    apply_cost SMALLINT,
    cost_adjustment DECIMAL(15, 2),
    cost_type CHAR(1), -- 'P' = Percentage, 'A' = Amount
    apply_selling SMALLINT,
    selling_adjustment DECIMAL(15, 2),
    selling_type CHAR(1), -- 'P' = Percentage, 'A' = Amount
    apply_status SMALLINT,
    status LIKE st01_mast.status,
    filter_category LIKE st01_mast.category_id,
    filter_status LIKE st01_mast.status
END RECORD

-- ==============================================================
-- MAIN - Entry point when run standalone
-- ==============================================================
MAIN
    IF NOT utils_globals.initialize_application() THEN
        DISPLAY "Initialization failed."
        EXIT PROGRAM 1
    END IF

    OPEN WINDOW w_st101 WITH FORM "st101_mast" ATTRIBUTES(STYLE = "main")
    CALL run_stock_mast()
    CLOSE WINDOW w_st101
END MAIN

-- ==============================================================
-- Run Stock Master - Main initialization function
-- ==============================================================
FUNCTION run_stock_mast()
    CALL run_stock()
END FUNCTION

-- ==============================================================
-- Lookup popup for stock selection
-- ==============================================================
FUNCTION query_stock() RETURNS STRING
    DEFINE selected_code STRING
    LET selected_code = st121_st_lkup.display_stocklist()
    RETURN selected_code
END FUNCTION

-- ==============================================================
-- Set fields editable/readonly
-- ==============================================================
FUNCTION set_fields_editable(editable SMALLINT)
    DEFINE f ui.Form
    DEFINE i INTEGER
    DEFINE field_list DYNAMIC ARRAY OF STRING

    LET f = ui.Window.getCurrent().getForm()

    -- Define all fields that should be editable/readonly
    LET field_list[1] = "description"
    LET field_list[2] = "barcode"
    LET field_list[3] = "batch_control"
    LET field_list[4] = "category_id"
    LET field_list[5] = "cost"
    LET field_list[6] = "selling_price"
    LET field_list[7] = "status"

    FOR i = 1 TO field_list.getLength()
        IF editable THEN
            CALL f.setFieldHidden(field_list[i], FALSE)
        ELSE
            -- In readonly mode, make fields non-editable
            CALL f.setFieldHidden(field_list[i], FALSE)
        END IF
    END FOR

    -- stock_code is always readonly after initial entry
    LET is_edit_mode = editable
END FUNCTION

-- ==============================================================
-- DIALOG Controller - Main interface
-- ==============================================================
FUNCTION run_stock()
    DEFINE ok SMALLINT

    -- Start in read-only mode
    LET is_edit_mode = FALSE

    DIALOG ATTRIBUTES(UNBUFFERED)

        -- -------------------------
        -- Header section INPUT
        -- -------------------------
        INPUT BY NAME rec_stock.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "stock_master")

            BEFORE INPUT
                -- Make fields readonly initially
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION find ATTRIBUTES(TEXT = "Search", IMAGE = "zoom")
                CALL query_stock_lookup()
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION new ATTRIBUTES(TEXT = "Create", IMAGE = "new")
                CALL new_stock()
                -- After successful add, load in readonly mode
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
                IF rec_stock.stock_code IS NULL OR rec_stock.stock_code = "" THEN
                    CALL utils_globals.show_info("No record selected to edit.")
                ELSE
                    LET is_edit_mode = TRUE
                    CALL DIALOG.setActionActive("save", TRUE)
                    CALL DIALOG.setActionActive("edit", FALSE)
                    MESSAGE "Edit mode enabled. Make changes and click Update to save."
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
                IF is_edit_mode THEN
                    CALL save_stock()
                    LET is_edit_mode = FALSE
                    CALL DIALOG.setActionActive("save", FALSE)
                    CALL DIALOG.setActionActive("edit", TRUE)
                END IF

            ON ACTION DELETE ATTRIBUTES(TEXT = "Delete", IMAGE = "delete")
                CALL delete_stock()

            ON ACTION mass_assign ATTRIBUTES(TEXT = "Mass Assign", IMAGE = "properties")
                CALL mass_assign_stock()

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

            -- Field validations for edit mode
            BEFORE FIELD description,
                barcode,
                batch_control,
                category_id,
                cost,
                selling_price,
                status
                IF NOT is_edit_mode THEN
                    CALL utils_globals.show_info(
                        "Click Edit button to modify this record.")
                    NEXT FIELD stock_code
                END IF

            -- Category lookup
            ON ACTION lookup_category
                ATTRIBUTES(TEXT = "Lookup Category", DEFAULTVIEW = NO)
                IF is_edit_mode THEN
                    CALL lookup_category()
                END IF

        END INPUT

        -- -------------------------
        -- Transaction display (readonly)
        -- -------------------------
        DISPLAY ARRAY arr_st_trans TO st30_trans.*
            ATTRIBUTES(COUNT = 0)
            -- Display only, no actions needed
        END DISPLAY

        BEFORE DIALOG
            -- Initial load in read-only mode
            LET ok = select_stock_items("1=1")
            LET is_edit_mode = FALSE

    END DIALOG
END FUNCTION

-- ==============================================================
-- Query using Lookup Window
-- ==============================================================
FUNCTION query_stock_lookup()
    DEFINE selected_code STRING

    LET selected_code = query_stock()

    IF selected_code IS NOT NULL THEN
        CALL load_stock_item(selected_code)
        -- Update the array to contain just this record for navigation
        CALL arr_codes.clear()
        LET arr_codes[1] = selected_code
        LET curr_idx = 1
    ELSE
        CALL utils_globals.show_error("No records found")
    END IF
END FUNCTION

-- ==============================================================
-- SELECT Stock Items into Array
-- ==============================================================
FUNCTION select_stock_items(where_clause) RETURNS SMALLINT
    DEFINE where_clause STRING
    DEFINE code STRING
    DEFINE idx INTEGER

    CALL arr_codes.clear()
    LET idx = 0

    DECLARE c_stock_curs CURSOR FROM "SELECT stock_code FROM st01_mast WHERE "
        || where_clause
        || " ORDER BY stock_code"

    FOREACH c_stock_curs INTO code
        LET idx = idx + 1
        LET arr_codes[idx] = code
    END FOREACH
    FREE c_stock_curs

    IF arr_codes.getLength() == 0 THEN
        CALL utils_globals.msg_no_record()
        RETURN FALSE
    END IF

    LET curr_idx = 1
    CALL load_stock_item(arr_codes[curr_idx])
    RETURN TRUE
END FUNCTION

-- ==============================================================
-- Load Single Stock Item
-- ==============================================================
FUNCTION load_stock_item(p_code STRING)

    SELECT stock_code,
        description,
        barcode,
        batch_control,
        category_id,
        cost,
        selling_price,
        stock_on_hand,
        total_purch,
        total_sales,
        status
        INTO rec_stock.*
        FROM st01_mast
        WHERE stock_code = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_stock.*
        CALL load_stock_transactions(rec_stock.stock_code)
    END IF
END FUNCTION

-- ==============================================================
-- Load Stock Transactions (for display)
-- ==============================================================
FUNCTION load_stock_transactions(p_stock_code STRING)
    DEFINE idx INTEGER

    CALL arr_st_trans.clear()
    LET idx = 0

    DECLARE c_trans_curs CURSOR FOR
        SELECT trans_date,
            trans_type,
            direction,
            qty,
            id,
            unit_cost,
            expiry_date,
            doc_type
        FROM st30_trans
        WHERE stock_code = p_stock_code
        ORDER BY trans_date DESC

    FOREACH c_trans_curs INTO arr_st_trans[idx + 1].*
        LET idx = idx + 1
    END FOREACH

    FREE c_trans_curs
END FUNCTION

-- ==============================================================
-- Navigation
-- ==============================================================
FUNCTION move_record(dir SMALLINT)
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

    CALL load_stock_item(arr_codes[curr_idx])
END FUNCTION

-- ==============================================================
-- New Stock Item
-- ==============================================================
FUNCTION new_stock()
    DEFINE dup_found SMALLINT
    DEFINE ok SMALLINT
    DEFINE new_stock_code STRING

    -- open a modal popup window just for the new stock item
    OPEN WINDOW w_new WITH FORM "st101_mast" ATTRIBUTES(STYLE = "main")

    -- Clear all fields and set defaults
    INITIALIZE rec_stock.* TO NULL
    LET rec_stock.status = "1"
    LET rec_stock.batch_control = 0
    LET rec_stock.cost = 0.00
    LET rec_stock.selling_price = 0.00
    LET rec_stock.stock_on_hand = 0.00
    LET rec_stock.total_purch = 0.00
    LET rec_stock.total_sales = 0.00

    DISPLAY BY NAME rec_stock.*

    MESSAGE "Enter new stock item details, then click Save or Cancel."

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_stock.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_stock")

            -- validations
            AFTER FIELD stock_code
                IF rec_stock.stock_code IS NULL OR rec_stock.stock_code = "" THEN
                    CALL utils_globals.show_error("Stock Code is required.")
                    NEXT FIELD stock_code
                END IF

            AFTER FIELD description
                IF rec_stock.description IS NULL
                    OR rec_stock.description = "" THEN
                    CALL utils_globals.show_error("Description is required.")
                    NEXT FIELD description
                END IF

            AFTER FIELD cost
                IF rec_stock.cost IS NULL THEN
                    LET rec_stock.cost = 0.00
                END IF

            AFTER FIELD selling_price
                IF rec_stock.selling_price IS NULL THEN
                    LET rec_stock.selling_price = 0.00
                END IF

            -- Category lookup
            ON ACTION lookup_category
                ATTRIBUTES(TEXT = "Lookup Category", DEFAULTVIEW = NO)
                CALL lookup_category()

                -- main actions
            ON ACTION save ATTRIBUTES(TEXT = "Save")
                LET dup_found = check_stock_unique(rec_stock.stock_code)

                IF dup_found = 0 THEN
                    INSERT INTO st01_mast(
                        stock_code,
                        description,
                        barcode,
                        batch_control,
                        category_id,
                        cost,
                        selling_price,
                        stock_on_hand,
                        total_purch,
                        total_sales,
                        status)
                        VALUES(
                            rec_stock.stock_code,
                            rec_stock.description,
                            rec_stock.barcode,
                            rec_stock.batch_control,
                            rec_stock.category_id,
                            rec_stock.cost,
                            rec_stock.selling_price,
                            rec_stock.stock_on_hand,
                            rec_stock.total_purch,
                            rec_stock.total_sales,
                            rec_stock.status)

                    CALL utils_globals.show_success("Stock item saved successfully.")
                    LET new_stock_code = rec_stock.stock_code
                    EXIT DIALOG
                END IF

            ON ACTION cancel
                LET new_stock_code = NULL
                EXIT DIALOG
        END INPUT
    END DIALOG

    CLOSE WINDOW w_new

    -- Load the newly added record in readonly mode
    IF new_stock_code IS NOT NULL THEN
        CALL load_stock_item(new_stock_code)
        CALL arr_codes.clear()
        LET arr_codes[1] = new_stock_code
        LET curr_idx = 1
    ELSE
        -- Cancelled, reload the list
        LET ok = select_stock_items("1=1")
    END IF
END FUNCTION

-- ==============================================================
-- Save / Update Stock Item
-- ==============================================================
FUNCTION save_stock()
    DEFINE exists INTEGER

    SELECT COUNT(*)
        INTO exists
        FROM st01_mast
        WHERE stock_code = rec_stock.stock_code

    IF exists = 0 THEN
        -- save data into the db
        INSERT INTO st01_mast(
            stock_code,
            description,
            barcode,
            batch_control,
            category_id,
            cost,
            selling_price,
            stock_on_hand,
            total_purch,
            total_sales,
            status)
            VALUES(
                rec_stock.stock_code,
                rec_stock.description,
                rec_stock.barcode,
                rec_stock.batch_control,
                rec_stock.category_id,
                rec_stock.cost,
                rec_stock.selling_price,
                rec_stock.stock_on_hand,
                rec_stock.total_purch,
                rec_stock.total_sales,
                rec_stock.status)
        CALL utils_globals.msg_saved()
    ELSE
        -- update record
        UPDATE st01_mast
            SET description = rec_stock.description,
                barcode = rec_stock.barcode,
                batch_control = rec_stock.batch_control,
                category_id = rec_stock.category_id,
                cost = rec_stock.cost,
                selling_price = rec_stock.selling_price,
                status = rec_stock.status
            WHERE stock_code = rec_stock.stock_code
        CALL utils_globals.msg_updated()
    END IF

    CALL load_stock_item(rec_stock.stock_code)
END FUNCTION

-- ==============================================================
-- Delete Stock Item
-- ==============================================================
FUNCTION delete_stock()
    DEFINE ok SMALLINT
    DEFINE trans_count INTEGER

    -- If no record is loaded, skip
    IF rec_stock.stock_code IS NULL OR rec_stock.stock_code = "" THEN
        CALL utils_globals.show_info('No stock item selected for deletion.')
        RETURN
    END IF

    -- Check if there are transactions
    SELECT COUNT(*)
        INTO trans_count
        FROM st30_trans
        WHERE stock_code = rec_stock.stock_code

    IF trans_count > 0 THEN
        CALL utils_globals.show_error(
            "Cannot delete stock item with existing transactions.")
        RETURN
    END IF

    -- Confirm delete
    LET ok =
        utils_globals.show_confirm(
            "Delete this stock item: " || rec_stock.description || "?",
            "Confirm Delete")

    IF NOT ok THEN
        MESSAGE "Delete cancelled."
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    DELETE FROM st01_mast WHERE stock_code = rec_stock.stock_code
    CALL utils_globals.msg_deleted()
    LET ok = select_stock_items("1=1")
END FUNCTION

-- ==============================================================
-- Check Stock uniqueness
-- ==============================================================
FUNCTION check_stock_unique(p_stock_code STRING) RETURNS SMALLINT
    DEFINE dup_count INTEGER
    DEFINE exists SMALLINT

    LET exists = 0

    -- check for duplicate stock code
    SELECT COUNT(*) INTO dup_count FROM st01_mast WHERE stock_code = p_stock_code

    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Duplicate stock code already exists.")
        LET exists = 1
        RETURN exists
    END IF

    RETURN exists
END FUNCTION

-- ==============================================================
-- Lookup Category
-- ==============================================================
FUNCTION lookup_category()
    DEFINE selected_cat_id INTEGER

    -- Call category lookup function
    LET selected_cat_id = st122_cat_lkup.load_lookup()

    IF selected_cat_id IS NOT NULL THEN
        LET rec_stock.category_id = selected_cat_id
        DISPLAY BY NAME rec_stock.category_id
    END IF
END FUNCTION

-- ==============================================================
-- Mass Assignment - Update multiple stock items
-- ==============================================================
FUNCTION mass_assign_stock()
    DEFINE update_count INTEGER
    DEFINE where_clause STRING
    DEFINE ok SMALLINT

    -- Initialize mass assignment record
    LET m_rec_mass.apply_category = 0
    LET m_rec_mass.apply_cost = 0
    LET m_rec_mass.cost_type = 'P'
    LET m_rec_mass.apply_selling = 0
    LET m_rec_mass.selling_type = 'P'
    LET m_rec_mass.apply_status = 0

    -- Open mass assignment window
    OPEN WINDOW w_mass WITH FORM "st101_mass"
        ATTRIBUTES(STYLE = "dialog", TEXT = "Mass Assignment")

    INPUT BY NAME m_rec_mass.*
        ATTRIBUTES(WITHOUT DEFAULTS, UNBUFFERED)

        ON ACTION apply ATTRIBUTES(TEXT = "Apply")
            -- Build where clause based on filters
            LET where_clause = "1=1"

            IF m_rec_mass.filter_category IS NOT NULL THEN
                LET where_clause =
                    where_clause
                    || " AND category_id = "
                    || m_rec_mass.filter_category
            END IF

            IF m_rec_mass.filter_status IS NOT NULL
                AND m_rec_mass.filter_status != "" THEN
                LET where_clause =
                    where_clause
                    || " AND status = '"
                    || m_rec_mass.filter_status
                    || "'"
            END IF

            -- Confirm the mass update
            LET ok =
                utils_globals.show_confirm(
                    "Apply mass assignment to filtered stock items?",
                    "Confirm Mass Assignment")

            IF ok THEN
                CALL apply_mass_assignment(where_clause) RETURNING update_count

                CALL utils_globals.show_success(
                    update_count
                    || " stock items updated successfully.")
                EXIT INPUT
            END IF

        ON ACTION cancel
            EXIT INPUT

    END INPUT

    CLOSE WINDOW w_mass

    -- Reload current record
    IF rec_stock.stock_code IS NOT NULL THEN
        CALL load_stock_item(rec_stock.stock_code)
    END IF
END FUNCTION

-- ==============================================================
-- Apply Mass Assignment Updates
-- ==============================================================
FUNCTION apply_mass_assignment(where_clause)
    DEFINE where_clause STRING
    DEFINE update_count INTEGER
    DEFINE sql_stmt STRING

    LET update_count = 0

    -- Update category
    IF m_rec_mass.apply_category = 1 AND m_rec_mass.category_id IS NOT NULL THEN
        LET sql_stmt =
            "UPDATE st01_mast SET category_id = "
            || m_rec_mass.category_id
            || " WHERE "
            || where_clause
        PREPARE upd_cat FROM sql_stmt
        EXECUTE upd_cat
        LET update_count = SQLCA.SQLERRD[3]
        FREE upd_cat
    END IF

    -- Update cost price
    IF m_rec_mass.apply_cost = 1 THEN
        IF m_rec_mass.cost_type = 'P' THEN
            -- Percentage adjustment
            LET sql_stmt =
                "UPDATE st01_mast SET cost = cost * (1 + "
                || m_rec_mass.cost_adjustment
                || " / 100) WHERE "
                || where_clause
        ELSE
            -- Amount adjustment
            LET sql_stmt =
                "UPDATE st01_mast SET cost = cost + "
                || m_rec_mass.cost_adjustment
                || " WHERE "
                || where_clause
        END IF
        PREPARE upd_cost FROM sql_stmt
        EXECUTE upd_cost
        LET update_count = SQLCA.SQLERRD[3]
        FREE upd_cost
    END IF

    -- Update selling price
    IF m_rec_mass.apply_selling = 1 THEN
        IF m_rec_mass.selling_type = 'P' THEN
            -- Percentage adjustment
            LET sql_stmt =
                "UPDATE st01_mast SET selling_price = selling_price * (1 + "
                || m_rec_mass.selling_adjustment
                || " / 100) WHERE "
                || where_clause
        ELSE
            -- Amount adjustment
            LET sql_stmt =
                "UPDATE st01_mast SET selling_price = selling_price + "
                || m_rec_mass.selling_adjustment
                || " WHERE "
                || where_clause
        END IF
        PREPARE upd_sell FROM sql_stmt
        EXECUTE upd_sell
        LET update_count = SQLCA.SQLERRD[3]
        FREE upd_sell
    END IF

    -- Update status
    IF m_rec_mass.apply_status = 1 AND m_rec_mass.status IS NOT NULL THEN
        LET sql_stmt =
            "UPDATE st01_mast SET status = '"
            || m_rec_mass.status
            || "' WHERE "
            || where_clause
        PREPARE upd_status FROM sql_stmt
        EXECUTE upd_status
        LET update_count = SQLCA.SQLERRD[3]
        FREE upd_status
    END IF

    RETURN update_count
END FUNCTION 