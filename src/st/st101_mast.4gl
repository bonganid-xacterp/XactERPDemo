-- ==============================================================
-- Program   : st101_mast.4gl
-- Purpose   : Stock Master maintenance
-- Module    : Stock Master (st)
-- Number    : 101
-- Author    : Bongani Dlamini
-- Version   : Genero 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL utils_db
IMPORT FGL st122_cat_lkup
IMPORT FGL utils_status_const
IMPORT FGL st121_st_lkup
IMPORT FGL pu131_grn

SCHEMA demoappdb

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE stock_t RECORD LIKE st01_mast.*

DEFINE rec_stock stock_t
DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT
DEFINE
    m_cat_name STRING,
    m_username STRING

-- UOM ComboBox arrays
DEFINE arr_uom_codes DYNAMIC ARRAY OF STRING
DEFINE arr_uom_names DYNAMIC ARRAY OF STRING

-- Transactions array for display
DEFINE arr_st_trans DYNAMIC ARRAY OF RECORD
    trans_date LIKE st30_trans.trans_date,
    doc_type LIKE st30_trans.doc_type,
    direction LIKE st30_trans.direction,
    qnty LIKE st30_trans.qnty,
    unit_cost LIKE st30_trans.unit_cost,
    sell_price LIKE st30_trans.sell_price,
    expiry_date LIKE st30_trans.expiry_date
END RECORD

-- ==============================================================
-- MAIN
-- ==============================================================
MAIN
    IF NOT utils_globals.initialize_application() THEN
        DISPLAY "Initialization failed."
        EXIT PROGRAM 1
    END IF

    IF utils_globals.is_standalone() THEN
        OPTIONS INPUT WRAP
        OPEN WINDOW w_st101 WITH FORM "st101_mast" -- ATTRIBUTES(STYLE = "normal")
    END IF

    CALL init_st_module()

    IF utils_globals.is_standalone() THEN
        CLOSE WINDOW w_st101
    END IF
END MAIN

-- ==============================================================
-- Menu Controller
-- ==============================================================
FUNCTION init_st_module()
    DEFINE ok SMALLINT
    LET is_edit_mode = FALSE

    --LET ok = select_stock_items("1=1")

    -- Load UOMs into ComboBox after form is opened
    CALL load_uoms()

    MENU "Stock Master Menu"

        COMMAND "Find"
            CALL query_stock_lookup()
            LET is_edit_mode = FALSE

        COMMAND "New"
            CALL new_stock()

        COMMAND "Edit"
            IF rec_stock.id IS NULL OR rec_stock.id = 0 THEN
                CALL utils_globals.show_info("No record selected.")
            ELSE
                CALL edit_stock()
            END IF

        COMMAND "Delete"
            CALL delete_stock()

        COMMAND "Previous"
            CALL move_record(-1)

        COMMAND "Next"
            CALL move_record(1)

        COMMAND "Capture GRN"
            CALL capture_grn()

        COMMAND "Exit"
            EXIT MENU
    END MENU
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
-- Load Stock Record
-- ==============================================================
FUNCTION load_stock_item(p_id INTEGER)
    SELECT * INTO rec_stock.* FROM st01_mast WHERE id = p_id

    IF SQLCA.SQLCODE = 0 THEN
        CALL refresh_display_fields()
        DISPLAY BY NAME rec_stock.*, m_cat_name, m_username
        CALL load_stock_transactions(rec_stock.id)
    END IF
END FUNCTION

-- ==============================================================
-- Lookup popup for Stock selection
-- ==============================================================
FUNCTION query_stock() RETURNS STRING
    DEFINE selected_code STRING

    LET selected_code = st121_st_lkup.display_stocklist()
    RETURN selected_code
END FUNCTION

-- ==============================================================
-- Refresh Linked Fields
-- ==============================================================
FUNCTION refresh_display_fields()
    LET m_cat_name = get_linked_category(rec_stock.category_id)
    LET m_username = utils_globals.get_username(rec_stock.created_by)
    DISPLAY BY NAME m_cat_name, m_username
END FUNCTION

-- ==============================================================
-- Load Transactions
-- ==============================================================
FUNCTION get_linked_category(p_id INTEGER)
    DEFINE l_cat_name STRING
    SELECT cat_name INTO l_cat_name FROM st02_cat WHERE id = p_id
    RETURN l_cat_name
END FUNCTION

-- ==============================================================
-- Load Transactions
-- ==============================================================
FUNCTION load_stock_transactions(p_stock_id INTEGER)
    DEFINE idx INTEGER
    CALL arr_st_trans.clear()
    LET idx = 1

    DECLARE c_trans CURSOR FOR
        SELECT *
            FROM st30_trans
            WHERE stock_id = p_stock_id
            ORDER BY trans_date DESC

    FOREACH c_trans INTO arr_st_trans[idx].*
        LET idx = idx + 1
    END FOREACH

    CLOSE c_trans
    FREE c_trans
--    DISPLAY ARRAY arr_st_trans TO tbl_st_trans.*
END FUNCTION

-- ==============================================================
-- New Stock
-- ==============================================================
FUNCTION new_stock()
    DEFINE random_id INTEGER
    DEFINE frm ui.Form

    INITIALIZE rec_stock.* TO NULL

    LET rec_stock.status = "active"
    LET rec_stock.unit_cost = 0
    LET rec_stock.sell_price = 0
    LET rec_stock.stock_on_hand = 0
    LET rec_stock.total_sales = 0
    LET rec_stock.total_purch = 0
    LET rec_stock.reserved_qnty = 0
    LET random_id = utils_globals.get_random_user()
    LET rec_stock.stock_code = utils_globals.get_next_code("st01_mast", "id")
    LET rec_stock.created_by = random_id
    LET rec_stock.created_at = TODAY 
    
    -- refresh to get the username after updating the user id
    CALL refresh_display_fields()

    LET frm = ui.Window.getCurrent().getForm()
    CALL frm.setFieldHidden("id", TRUE) -- make id read-only for new

    INPUT BY NAME rec_stock.* ATTRIBUTES(WITHOUT DEFAULTS)
        ON ACTION lookup_category
            CALL open_category_lkup()

        ON ACTION save
            IF check_stock_unique(rec_stock.id) = 0 THEN
                INSERT INTO st01_mast VALUES rec_stock.*
                CALL utils_globals.msg_saved()
                EXIT INPUT
            END IF

        ON ACTION cancel
            EXIT INPUT
    END INPUT

    IF rec_stock.id IS NOT NULL THEN
        CALL load_stock_item(rec_stock.id)
    END IF
END FUNCTION

-- ==============================================================
-- Edit Stock
-- ==============================================================
FUNCTION edit_stock()
    DEFINE frm ui.Form
    LET frm = ui.Window.getCurrent().getForm()
    CALL frm.setFieldHidden("id", TRUE) -- id is read-only during edit

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_stock.* ATTRIBUTES(WITHOUT DEFAULTS)
        
            ON ACTION save ATTRIBUTES(TEXT="Update")
                CALL save_stock()
                EXIT DIALOG
            ON ACTION cancel ATTRIBUTES(TEXT="Exit")
                CALL load_stock_item(rec_stock.id)
                EXIT DIALOG
            ON ACTION lookup_category
                CALL open_category_lkup()
        END INPUT
    END DIALOG
END FUNCTION

-- ==============================================================
-- Save / Update
-- ==============================================================
FUNCTION save_stock()
    DEFINE r_exists INTEGER

    SELECT COUNT(*) INTO r_exists FROM st01_mast WHERE id = rec_stock.id
    IF r_exists = 0 THEN
        INSERT INTO st01_mast VALUES rec_stock.*
        CALL utils_globals.msg_saved()
    ELSE
        UPDATE st01_mast SET st01_mast.* = rec_stock.* WHERE id = rec_stock.id
        CALL utils_globals.msg_updated()
    END IF

    CALL load_stock_item(rec_stock.id)
END FUNCTION

-- ==============================================================
-- Lookup Category
-- ==============================================================
FUNCTION open_category_lkup()
    DEFINE selected_cat_id INTEGER
    LET selected_cat_id = st122_cat_lkup.load_lookup()

    IF selected_cat_id IS NOT NULL THEN
        LET rec_stock.category_id = selected_cat_id
        DISPLAY BY NAME rec_stock.category_id
        CALL refresh_display_fields()
    END IF
END FUNCTION

-- ==============================================================
-- Navigation and Utilities
-- ==============================================================
FUNCTION select_stock_items(p_where STRING) RETURNS SMALLINT
    DEFINE
        l_sql STRING,
        l_code INTEGER,
        l_idx INTEGER

    -- Reset navigation array
    CALL arr_codes.clear()
    LET l_idx = 0

    -- Build SQL dynamically and safely
    LET l_sql = SFMT("SELECT id FROM st01_mast WHERE %1 ORDER BY id", p_where)

    -- Open and fetch all matching records
    DECLARE stock_curs CURSOR FROM l_sql

    FOREACH stock_curs INTO l_code
        LET l_idx = l_idx + 1
        LET arr_codes[l_idx] = l_code
    END FOREACH

    CLOSE stock_curs
    FREE stock_curs

    -- Handle no records found
    IF arr_codes.getLength() = 0 THEN
        CALL utils_globals.msg_no_record()
        RETURN FALSE
    END IF

    -- Load the first record by default
    LET curr_idx = 1
    CALL load_stock_item(arr_codes[curr_idx])

    RETURN TRUE
END FUNCTION

-- ==============================================================
-- Navigation
-- ==============================================================
FUNCTION move_record(dir SMALLINT)
    DEFINE new_idx INTEGER

    IF arr_codes.getLength() == 0 THEN
        CALL utils_globals.show_info("No records to navigate.")
        RETURN
    END IF

    LET new_idx = utils_globals.navigate_records(arr_codes, curr_idx, dir)
    LET curr_idx = new_idx
CALL load_stock_item(arr_codes[curr_idx])
END FUNCTION

-- ==============================================================
-- Check stock uniqueness
-- ==============================================================
FUNCTION check_stock_unique(p_id INTEGER) RETURNS SMALLINT
    DEFINE dup_count INTEGER
    SELECT COUNT(*) INTO dup_count FROM st01_mast WHERE id = p_id
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Duplicate stock code exists.")
        RETURN 1
    END IF
    RETURN 0
END FUNCTION

-- ==============================================================
-- Delete stock
-- ==============================================================
FUNCTION delete_stock()
    DEFINE
        trans_count INTEGER,
        ok SMALLINT

    IF rec_stock.id IS NULL OR rec_stock.id = 0 THEN
        CALL utils_globals.show_info("No stock item selected.")
        RETURN
    END IF

    SELECT COUNT(*)
        INTO trans_count
        FROM st30_trans
        WHERE stock_id = rec_stock.id
    IF trans_count > 0 THEN
        CALL utils_globals.show_error("Cannot delete item with transactions.")
        RETURN
    END IF

    LET ok = utils_globals.show_confirm("Delete this item?", "Confirm")
    IF ok THEN
        DELETE FROM st01_mast WHERE id = rec_stock.id
        CALL utils_globals.msg_deleted()
        LET ok = select_stock_items("1=1")
    END IF
END FUNCTION

-- ==============================================================
-- Load UOMs into ComboBox
-- ==============================================================
FUNCTION load_uoms()
    DEFINE idx INTEGER
    DEFINE cb ui.ComboBox
    DEFINE frm ui.Form
    DEFINE win ui.Window

    -- Clear arrays
    CALL arr_uom_codes.clear()
    CALL arr_uom_names.clear()

    LET idx = 1

    TRY
        -- Load active UOMs from database
        DECLARE uom_curs CURSOR FOR
            SELECT uom_code, uom_name
              FROM st03_uom_master
             ORDER BY uom_code

        FOREACH uom_curs INTO arr_uom_codes[idx], arr_uom_names[idx]
            LET idx = idx + 1
        END FOREACH

        CLOSE uom_curs
        FREE uom_curs

        -- Only populate ComboBox if we have a valid form loaded
        LET win = ui.Window.getCurrent()
        IF win IS NOT NULL THEN
            LET frm = win.getForm()
            IF frm IS NOT NULL THEN
                LET cb = ui.ComboBox.forName("st01_mast.uom")
                IF cb IS NOT NULL THEN
                    -- Clear existing items
                    CALL cb.clear()

                    -- Add UOMs to ComboBox
                    FOR idx = 1 TO arr_uom_codes.getLength()
                        CALL cb.addItem(arr_uom_codes[idx], arr_uom_names[idx])
                    END FOR
                ELSE
                    -- ComboBox not found - form may not be loaded yet
                    -- This is OK, arrays are populated for later use
                    DISPLAY "Note: UOM ComboBox will be populated when form is available"
                END IF
            END IF
        END IF

    CATCH
        -- Silent fail for database errors during UOM loading
        -- Don't break the module if UOMs can't be loaded
        DISPLAY "Warning: Could not load UOMs - ", SQLCA.SQLERRM
    END TRY
END FUNCTION

-- ==============================================================
-- Load UOMs into ComboBox
-- ==============================================================
FUNCTION capture_grn()
    -- capture new grn
    CALL pu131_grn.new_pu_grn()
END FUNCTION