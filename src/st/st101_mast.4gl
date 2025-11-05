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
TYPE stock_t RECORD LIKE st01_mast.*

-- Transaction array (for display purposes)
DEFINE arr_st_trans DYNAMIC ARRAY OF RECORD LIKE st30_trans.*

DEFINE rec_stock stock_t
DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

DEFINE m_cat_name STRING
DEFINE m_username STRING

-- ==============================================================
-- MAIN (Standalone Mode)
-- ==============================================================
MAIN

    -- Initialize application (sets g_standalone_mode automatically)
    IF NOT utils_globals.initialize_application() THEN
        DISPLAY "Initialization failed."
        EXIT PROGRAM 1
    END IF

    -- If standalone mode, open window
    IF utils_globals.is_standalone() THEN
    OPTIONS INPUT WRAP
        OPEN WINDOW w_st101 WITH FORM "st101_mast" ATTRIBUTES(STYLE = "main")
    END IF

    -- Run the module (works in both standalone and MDI modes)
    CALL init_st_module()

    -- If standalone mode, close window on exit
    IF utils_globals.is_standalone() THEN
        CLOSE WINDOW w_st101
    END IF

END MAIN

-- ==============================================================
-- Lookup popup for stock selection
-- ==============================================================
FUNCTION query_stock() RETURNS STRING
    DEFINE selected_code STRING
    LET selected_code = st121_st_lkup.display_stocklist()

    RETURN selected_code
END FUNCTION

-- ==============================================================
-- MENU Controller - Main interface
-- ==============================================================
FUNCTION init_st_module()
    DEFINE ok SMALLINT

    -- Start in read-only mode
    LET is_edit_mode = FALSE

    -- Initial load
    LET ok = select_stock_items("1=1")

    -- ===========================================
    -- MAIN MENU (top-level)
    -- ===========================================
    MENU "Stock Master Menu"

        COMMAND "Find"
            CALL query_stock_lookup()
            LET is_edit_mode = FALSE

        COMMAND "New"
            CALL new_stock()
            LET is_edit_mode = FALSE

        COMMAND "Edit"
            IF rec_stock.stock_code IS NULL OR rec_stock.stock_code = "" THEN
                CALL utils_globals.show_info("No record selected to edit.")
            ELSE
                LET is_edit_mode = TRUE
                CALL edit_stock()
            END IF

        COMMAND "Delete"
            CALL delete_stock()
            LET is_edit_mode = FALSE

        COMMAND "Previous"
            CALL move_record(-1)
            LET is_edit_mode = FALSE

        COMMAND "Next"
            CALL move_record(1)
            LET is_edit_mode = FALSE

        COMMAND "Exit"
            EXIT MENU

    END MENU
END FUNCTION

-- ==============================================================
-- Edit Stock Item (Sub-dialog)
-- ==============================================================
FUNCTION edit_stock()
    DIALOG ATTRIBUTES(UNBUFFERED)

        INPUT BY NAME rec_stock.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "stock_master")

            BEFORE INPUT
                MESSAGE "Edit mode enabled. Make changes and click Save or Cancel."

            ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
                CALL save_stock()
                EXIT DIALOG

            ON ACTION cancel
                CALL load_stock_item(
                    rec_stock.stock_code) -- Reload to discard changes
                EXIT DIALOG

            AFTER FIELD stock_code
                IF rec_stock.stock_code IS NULL
                    OR rec_stock.stock_code = "" THEN
                    CALL utils_globals.show_error("Stock Code is required.")
                    NEXT FIELD stock_code
                END IF

            AFTER FIELD description
                IF rec_stock.description IS NULL
                    OR rec_stock.description = "" THEN
                    CALL utils_globals.show_error("Description is required.")
                    NEXT FIELD description
                END IF

                -- Category lookup
            ON ACTION lookup_category
                ATTRIBUTES(TEXT = "Lookup Category", DEFAULTVIEW = NO)
                CALL lookup_category()

        END INPUT

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
FUNCTION load_stock_item(p_code integer)

    SELECT * INTO rec_stock.* FROM st01_mast WHERE stock_code = p_code

    IF SQLCA.SQLCODE = 0 THEN

        -- get username and category

        CALL refresh_display_fields()
        DISPLAY BY NAME rec_stock.*
        --CALL load_stock_transactions(rec_stock.stock_code)
    END IF

END FUNCTION

-- ==============================================================
-- Get Linked records
-- ==============================================================
FUNCTION refresh_display_fields()
    LET m_cat_name = get_linked_category(rec_stock.category_id)
    LET m_username = utils_globals.get_username(rec_stock.created_by)
    DISPLAY BY NAME m_cat_name, m_username
END FUNCTION

-- ==============================================================
-- Get Linked category
-- ==============================================================
FUNCTION get_linked_category(p_id INTEGER)
    DEFINE int_flag INT
    DEFINE l_cat_name STRING

    IF NOT int_flag THEN
        SELECT cat_name INTO l_cat_name FROM st02_cat WHERE id = p_id
    END IF

    RETURN l_cat_name

END FUNCTION

-- ==============================================================
-- Load Stock Transactions (for display)
-- ==============================================================
FUNCTION load_stock_transactions(p_stock_code STRING)
    DEFINE idx INTEGER

    CALL arr_st_trans.clear()
    LET idx = 1

    DECLARE c_trans_curs CURSOR FOR
        SELECT *
            FROM st30_trans
            WHERE stock_code = p_stock_code
            ORDER BY trans_date DESC

    FOREACH c_trans_curs
        INTO arr_st_trans[idx].trans_date,
            arr_st_trans[idx].doc_type,
            arr_st_trans[idx].direction,
            arr_st_trans[idx].qnty,
            arr_st_trans[idx].unit_cost,
            arr_st_trans[idx].sell_price,
            arr_st_trans[idx].expiry_date
        LET idx = idx + 1
    END FOREACH

    CLOSE c_trans_curs
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
    DEFINE new_stock_code STRING 
    DEFINE rec_new stock_t
    DEFINE random_id INTEGER
    
    -- Initialize with defaults
    INITIALIZE rec_new.* TO NULL
    
    LET rec_new.status = "active"
    LET rec_new.batch_control = 0
    LET rec_new.unit_cost = 0.00
    LET rec_new.sell_price = 0.00
    LET rec_new.stock_on_hand = 0.00
    LET rec_new.total_purch = 0.00
    LET rec_new.total_sales = 0.00
    

    LET random_id = utils_globals.get_random_user() RETURN random_id 
    LET new_stock_code = utils_globals.get_next_code("st01_mast", "stock_code")

    LET rec_new.created_by =  random_id
    LET rec_new.stock_code = new_stock_code
    
    -- Use the record for input
    INPUT BY NAME rec_new.*
        ATTRIBUTES(UNBUFFERED)
        
        BEFORE INPUT
            MESSAGE "Enter new stock details"
            
        AFTER FIELD stock_code, description
            IF (rec_new.stock_code IS NULL OR rec_new.stock_code = "") OR
               (rec_new.description IS NULL OR rec_new.description = "") THEN
                NEXT FIELD stock_code
                
            END IF
            
        ON ACTION save
            IF check_stock_unique(rec_new.stock_code) = 0 THEN
                INSERT INTO st01_mast VALUES rec_new.*
                LET new_stock_code = rec_new.stock_code
                EXIT INPUT
            END IF
            
        ON ACTION cancel
            LET new_stock_code = NULL
            EXIT INPUT
    END INPUT
    
    -- Load the newly added record in readonly mode
    IF new_stock_code IS NOT NULL THEN
        CALL load_stock_item(new_stock_code)
        CALL arr_codes.clear()
        LET arr_codes[1] = new_stock_code
        LET curr_idx = 1
    END IF
END FUNCTION

-- ==============================================================
-- Save / Update Stock Item
-- ==============================================================
FUNCTION save_stock()
    DEFINE r_exists INTEGER

    SELECT COUNT(*)
        INTO r_exists
        FROM st01_mast
        WHERE stock_code = rec_stock.stock_code

    IF r_exists = 0 THEN
        -- save data into the db
        INSERT INTO st01_mast VALUES rec_stock.*

        CALL utils_globals.msg_saved()

    ELSE
        -- update record
        UPDATE st01_mast
            SET st01_mast.* = rec_stock.*
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
    SELECT COUNT(*)
        INTO dup_count
        FROM st01_mast
        WHERE stock_code = p_stock_code

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
    DEFINE f_cat_name STRING

    -- Call category lookup function
    LET selected_cat_id = st122_cat_lkup.load_lookup()

    IF selected_cat_id IS NOT NULL THEN
        LET rec_stock.category_id = selected_cat_id
        DISPLAY BY NAME f_cat_name
    END IF
END FUNCTION
