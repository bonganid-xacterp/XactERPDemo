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
IMPORT FGL pu130_order
IMPORT FGL pu131_grn
IMPORT FGL pu132_inv

SCHEMA demoappdb

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE stock_t RECORD LIKE st01_mast.*

DEFINE m_stock_rec stock_t
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
DEFINE m_st_trans_arr DYNAMIC ARRAY OF RECORD LIKE st30_trans.*

-- ==============================================================
-- Init Program
-- ==============================================================
FUNCTION init_st_module()
    DEFINE chosen_row SMALLINT

    LET is_edit_mode = FALSE

    INITIALIZE m_stock_rec.* TO NULL

    DISPLAY BY NAME m_stock_rec.*

    DISPLAY ARRAY m_st_trans_arr TO m_st_trans_arr.*
    
        ATTRIBUTES(UNBUFFERED, DOUBLECLICK = row_select)

        BEFORE DISPLAY
            CALL DIALOG.setActionHidden("accept", TRUE)
            CALL DIALOG.setActionHidden("cancel", TRUE)
            CALL DIALOG.setActionHidden("row_select", TRUE)

        ON ACTION Find
            CALL query_stock_lookup();
            LET is_edit_mode = FALSE

        ON ACTION New ATTRIBUTES(TEXT = "New", IMAGE = "new")
            CALL new_stock();
            LET is_edit_mode = FALSE

        ON ACTION row_select

            TRY
                LET chosen_row = DIALOG.getCurrentRow("m_st_trans_arr");
                IF chosen_row > 0 THEN
                    CALL open_transaction_window(
                        m_st_trans_arr[chosen_row].doc_no,
                        m_st_trans_arr[chosen_row].doc_type)
                END IF
            CATCH
                CALL utils_globals.show_error('Error fetching doc')
            END TRY

        ON ACTION List ATTRIBUTES(TEXT = "Refresh Records", IMAGE = "refresh")
            CALL load_all_stock();
            LET is_edit_mode = FALSE

        ON ACTION Edit ATTRIBUTES(TEXT = "Edit", IMAGE = "pen")
            IF m_stock_rec.id IS NULL OR m_stock_rec.id = 0 THEN
                CALL utils_globals.show_info("No record selected to edit.")
            ELSE
                LET is_edit_mode = TRUE;
                CALL utils_globals.set_form_label(
                    'lbl_form_title', 'CREDITORS MAINTENANCE');
                CALL edit_stock()
            END IF

        ON ACTION DELETE ATTRIBUTES(TEXT = "Delete", IMAGE = "fa-trash")
            CALL delete_stock();
            LET is_edit_mode = FALSE

        ON ACTION PREVIOUS
            CALL move_record(-1)

        ON ACTION NEXT
            CALL move_record(1)

        ON ACTION add_order ATTRIBUTES(TEXT = "Add P/Order", IMAGE = "new")
            IF m_stock_rec.id THEN
                CALL pu130_order.new_po_from_master(m_stock_rec.id)
            ELSE
                CALL utils_globals.show_warning(
                    'Choose a creditor record first.')
            END IF

        ON ACTION EXIT ATTRIBUTES(TEXT = "Exit", IMAGE = "fa-close")
            EXIT DISPLAY

    END DISPLAY
END FUNCTION

-- ==============================================================
-- Load All Records
-- ==============================================================
FUNCTION load_all_stock()
    DEFINE ok SMALLINT
    LET ok = select_stock_items("1=1")

    IF ok THEN
        MESSAGE SFMT("Loaded %1 stock item(s)", arr_codes.getLength())
        IF arr_codes.getLength() > 0 THEN
            CALL load_stock_item(arr_codes[1])
        END IF
    ELSE
        CALL utils_globals.show_info("No stock items found.")
        INITIALIZE m_stock_rec.* TO NULL
        DISPLAY BY NAME m_stock_rec.*
        CALL m_st_trans_arr.clear()
    END IF
END FUNCTION

-- ==============================================================
-- Query using Lookup Window
-- ==============================================================
FUNCTION query_stock_lookup()
    DEFINE selected_code STRING
    DEFINE found_idx, i INTEGER

    LET selected_code = st121_st_lkup.fetch_list()

    IF selected_code IS NULL OR selected_code = "" THEN
        RETURN
    END IF

    LET found_idx = 0
    FOR i = 1 TO arr_codes.getLength()
        IF arr_codes[i] = selected_code THEN
            LET found_idx = i
            EXIT FOR
        END IF
    END FOR

    IF found_idx > 0 THEN
        LET curr_idx = found_idx
        CALL load_stock_item(selected_code)
    ELSE
        CALL load_all_stock()
        FOR i = 1 TO arr_codes.getLength()
            IF arr_codes[i] = selected_code THEN
                LET curr_idx = i
                EXIT FOR
            END IF
        END FOR
        CALL load_stock_item(selected_code)
    END IF
END FUNCTION

-- ==============================================================
-- Load Stock Record
-- ==============================================================
FUNCTION load_stock_item(p_id INTEGER)
    TRY
        SELECT * INTO m_stock_rec.* FROM st01_mast WHERE id = p_id

        IF SQLCA.SQLCODE = 0 THEN
            CALL refresh_display_fields()
            DISPLAY BY NAME m_stock_rec.*, m_cat_name, m_username
            CALL load_stock_transactions(m_stock_rec.id)
        END IF
    CATCH
        CALL utils_globals.show_sql_error(
            "load_stock_item: Error loading stock item")
    END TRY
END FUNCTION

-- ==============================================================
-- Lookup popup for Stock selection
-- ==============================================================
FUNCTION query_stock() RETURNS STRING
    DEFINE selected_code STRING

    LET selected_code = st121_st_lkup.fetch_list()
    RETURN selected_code
END FUNCTION

-- ==============================================================
-- Refresh Linked Fields
-- ==============================================================
FUNCTION refresh_display_fields()
    LET m_cat_name = get_linked_category(m_stock_rec.category_id)
    LET m_username = utils_globals.get_username(m_stock_rec.created_by)
    DISPLAY BY NAME m_cat_name, m_username
END FUNCTION

-- ==============================================================
-- Load Transactions
-- ==============================================================
FUNCTION get_linked_category(p_id INTEGER)
    DEFINE l_cat_name STRING
    TRY
        SELECT cat_name INTO l_cat_name FROM st02_cat WHERE id = p_id
    CATCH
        CALL utils_globals.show_sql_error(
            "get_linked_category: Error loading category")
        LET l_cat_name = NULL
    END TRY
    RETURN l_cat_name
END FUNCTION

-- ==============================================================
-- Load Transactions
-- ==============================================================
FUNCTION load_stock_transactions(p_stock_id INTEGER)
    DEFINE idx INTEGER

    CALL m_st_trans_arr.clear()

    TRY
        DECLARE stock_trans_curs CURSOR FOR
            SELECT *
                FROM st30_trans
                WHERE stock_id = p_stock_id
                ORDER BY trans_date DESC

        LET idx = 1
        FOREACH stock_trans_curs INTO m_st_trans_arr[idx].*
            LET idx = idx + 1
        END FOREACH

        CLOSE stock_trans_curs
        FREE stock_trans_curs

    CATCH
        CALL utils_globals.show_sql_error(
            "load_stock_transactions: Error loading transactions")
    END TRY

END FUNCTION

-- ==============================================================
-- New Stock
-- ==============================================================
FUNCTION new_stock()
    DEFINE random_id INTEGER
    DEFINE frm ui.Form

    INITIALIZE m_stock_rec.* TO NULL

    LET m_stock_rec.status = "active"
    LET m_stock_rec.unit_cost = 0
    LET m_stock_rec.sell_price = 0
    LET m_stock_rec.stock_on_hand = 0
    LET m_stock_rec.total_sales = 0
    LET m_stock_rec.total_purch = 0
    LET m_stock_rec.reserved_qnty = 0
    LET random_id = utils_globals.get_random_user()

    IF m_stock_rec.stock_code IS NULL THEN
        LET m_stock_rec.stock_code =
            utils_globals.get_next_code("st01_mast", "id")
    END IF

    LET m_stock_rec.created_by = random_id
    LET m_stock_rec.created_at = CURRENT

    -- refresh to get the username after updating the user id
    CALL refresh_display_fields()

    LET frm = ui.Window.getCurrent().getForm()
    CALL frm.setFieldHidden("id", TRUE) -- make id read-only for new

    DIALOG ATTRIBUTES(UNBUFFERED)

        INPUT BY NAME m_stock_rec.* ATTRIBUTES(WITHOUT DEFAULTS)
            ON ACTION lookup_category
                CALL open_category_lkup()

            ON ACTION save
                TRY
                    IF check_stock_unique(m_stock_rec.id) = 0 THEN
                        CALL save_stock()
                    END IF
                CATCH
                    CALL utils_globals.msg_error_duplicates()
                END TRY

        END INPUT

        ON ACTION cancel
            EXIT DIALOG

    END DIALOG

    IF m_stock_rec.id IS NOT NULL THEN
        CALL load_stock_item(m_stock_rec.id)

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
        INPUT BY NAME m_stock_rec.* ATTRIBUTES(WITHOUT DEFAULTS)

            ON ACTION save ATTRIBUTES(TEXT = "Update")
                CALL save_stock()
                EXIT DIALOG
            ON ACTION cancel ATTRIBUTES(TEXT = "Exit")
                CALL load_stock_item(m_stock_rec.id)
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

    TRY
        SELECT COUNT(*) INTO r_exists FROM st01_mast WHERE id = m_stock_rec.id

        IF r_exists = 0 THEN
            INSERT INTO st01_mast VALUES m_stock_rec.*
            CALL utils_globals.msg_saved()
        ELSE
            UPDATE st01_mast
                SET st01_mast.* = m_stock_rec.*
                WHERE id = m_stock_rec.id
            CALL utils_globals.msg_updated()
        END IF
    CATCH
        CALL utils_globals.show_sql_error("save_stock: Error saving stock item")
    END TRY

    CALL load_stock_item(m_stock_rec.id)
END FUNCTION

-- ==============================================================
-- Lookup Category
-- ==============================================================
FUNCTION open_category_lkup()
    DEFINE selected_cat_id INTEGER
    LET selected_cat_id = st122_cat_lkup.load_lookup()

    IF selected_cat_id IS NOT NULL THEN
        LET m_stock_rec.category_id = selected_cat_id
        DISPLAY BY NAME m_stock_rec.category_id
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

    TRY
        -- Open and fetch all matching records
        DECLARE stock_curs CURSOR FROM l_sql

        FOREACH stock_curs INTO l_code
            LET l_idx = l_idx + 1
            LET arr_codes[l_idx] = l_code
        END FOREACH

        CLOSE stock_curs
        FREE stock_curs
    CATCH
        CALL utils_globals.show_sql_error(
            "select_stock_items: Error selecting stock items")
        RETURN FALSE
    END TRY

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
    TRY
        SELECT COUNT(*) INTO dup_count FROM st01_mast WHERE id = p_id
        IF dup_count > 0 THEN
            CALL utils_globals.show_error("Duplicate stock code exists.")
            RETURN 1
        END IF
    CATCH
        CALL utils_globals.show_sql_error(
            "check_stock_unique: Error checking stock uniqueness")
        RETURN 1
    END TRY
    RETURN 0
END FUNCTION

-- ==============================================================
-- Delete stock
-- ==============================================================
FUNCTION delete_stock()
    DEFINE
        trans_count INTEGER,
        ok SMALLINT

    IF m_stock_rec.id IS NULL OR m_stock_rec.id = 0 THEN
        CALL utils_globals.show_info("No stock item selected.")
        RETURN
    END IF

    TRY
        SELECT COUNT(*)
            INTO trans_count
            FROM st30_trans
            WHERE stock_id = m_stock_rec.id
        IF trans_count > 0 THEN
            CALL utils_globals.show_error(
                "Cannot delete item with transactions.")
            RETURN
        END IF

        LET ok = utils_globals.show_confirm("Delete this item?", "Confirm")
        IF ok THEN
            DELETE FROM st01_mast WHERE id = m_stock_rec.id
            CALL utils_globals.msg_deleted()
            LET ok = select_stock_items("1=1")
        END IF
    CATCH
        CALL utils_globals.show_sql_error(
            "delete_stock: Error deleting stock item")
    END TRY
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
            SELECT uom_code, uom_name FROM st03_uom_master ORDER BY uom_code

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
-- Capture New PO from Stock
-- ==============================================================
FUNCTION capture_new_po(p_id INTEGER)
    -- capture new po
    CALL pu130_order.new_po_from_stock(p_id)
END FUNCTION

-- ==============================================================
-- Open Transaction Document (double-click handler)
-- ==============================================================
FUNCTION open_transaction_window(p_doc_id INTEGER, l_type STRING)

    DISPLAY "Loaded the doc no for doc : " || p_doc_id

    CASE l_type
        WHEN "PO"
            CALL pu130_order.load_po(p_doc_id)
        WHEN "INV"
            CALL pu132_inv.load_pu_inv(p_doc_id)
        WHEN "GRN"
            CALL pu131_grn.load_pu_grn(p_doc_id)
        OTHERWISE
            CALL utils_globals.show_info("Unknown document type: " || l_type)
    END CASE

END FUNCTION

-- ==============================================================
-- Extract Document ID from Notes
-- ==============================================================
FUNCTION extract_doc_id_from_notes(
    p_notes STRING, p_doc_type STRING)
    RETURNS INTEGER
    DEFINE l_pattern STRING
    DEFINE l_pos INTEGER
    DEFINE l_end_pos INTEGER
    DEFINE l_doc_id_str STRING
    DEFINE l_doc_id INTEGER

    IF p_notes IS NULL THEN
        RETURN NULL
    END IF

    -- Pattern: "PO#123" or "GRN#123" or "INV#123"
    LET l_pattern = p_doc_type || "#"
    LET l_pos = p_notes.getIndexOf(l_pattern, 1)

    IF l_pos = 0 THEN
        RETURN NULL
    END IF

    -- Move past the pattern to get the number
    LET l_pos = l_pos + l_pattern.getLength()

    -- Find the end of the number (space or end of string)
    LET l_end_pos = l_pos
    WHILE l_end_pos <= p_notes.getLength()
        IF p_notes.getCharAt(l_end_pos) >= "0"
            AND p_notes.getCharAt(l_end_pos) <= "9" THEN
            LET l_end_pos = l_end_pos + 1
        ELSE
            EXIT WHILE
        END IF
    END WHILE

    IF l_end_pos = l_pos THEN
        RETURN NULL
    END IF

    LET l_doc_id_str = p_notes.subString(l_pos, l_end_pos - 1)
    LET l_doc_id = l_doc_id_str

    RETURN l_doc_id
END FUNCTION
