-- ==============================================================
-- Program   : st130_trans.4gl
-- Purpose   : Stock Transaction - Movement Tracking (IN/OUT)
-- Module    : Stock Transactions (st)
-- Number    : 130
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Track all stock movements in and out
--              Shows transaction history with filtering options
--              Direction: IN (receipts), OUT (dispatches)
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL utils_db
IMPORT FGL st121_st_lkup
IMPORT FGL utils_status_const

SCHEMA demoappdb

-- ==============================================================
-- Record definitions
-- ==============================================================

-- Transaction array for display
DEFINE arr_st30_trans DYNAMIC ARRAY OF RECORD LIKE st30_trans.*

-- Search/filter criteria
DEFINE filter_rec RECORD
    id LIKE st01_mast.id,
    doc_type VARCHAR(10),
    direction VARCHAR(3),
    date_from DATE,
    date_to DATE,
    batch_id VARCHAR(30)
END RECORD

-- Stock description for display
DEFINE arr_stock_desc DYNAMIC ARRAY OF RECORD
    stock_desc VARCHAR(150)
END RECORD

DEFINE curr_idx INTEGER
DEFINE total_in DECIMAL(15,2)
DEFINE total_out DECIMAL(15,2)
DEFINE net_movement DECIMAL(15,2)

-- ==============================================================
-- MAIN - Entry point when run standalone
-- ==============================================================
--MAIN
--    IF NOT utils_globals.initialize_application() THEN
--        DISPLAY "Initialization failed."
--        EXIT PROGRAM 1
--    END IF
--
--    OPTIONS INPUT WRAP
--    OPEN WINDOW w_st130 WITH FORM "st130_trans" ATTRIBUTES(STYLE = "main")
--    CALL init_trans_module()
--    CLOSE WINDOW w_st130
--END MAIN

-- ==============================================================
-- Initialize Transaction Module - Main entry function
-- ==============================================================
FUNCTION init_trans_module()
    -- Initialize filter
    CALL init_filter()

    -- Load initial data
    CALL load_transactions()

    -- Start dialog
    CALL run_trans_dialog()
END FUNCTION

-- ==============================================================
-- Initialize Filter with defaults
-- ==============================================================
FUNCTION init_filter()
    INITIALIZE filter_rec.* TO NULL

    -- Default to last 30 days
    LET filter_rec.date_from = TODAY - 30
    LET filter_rec.date_to = TODAY

    DISPLAY BY NAME filter_rec.*
END FUNCTION

-- ==============================================================
-- Main Dialog
-- ==============================================================
FUNCTION run_trans_dialog()
    --DEFINE dlg ui.Dialog

    DIALOG ATTRIBUTES(UNBUFFERED)

        -- Filter input section
        INPUT BY NAME filter_rec.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "filter_input")

            BEFORE INPUT
                CALL DIALOG.setActionActive("apply_filter", TRUE)

            AFTER FIELD id
                IF filter_rec.id IS NOT NULL THEN
                    CALL validate_id()
                END IF

            ON ACTION lookup_stock
                ATTRIBUTES(TEXT = "Stock Lookup", IMAGE = "zoom", DEFAULTVIEW = NO)
                CALL lookup_stock_for_filter()

            ON ACTION clear_filter
                ATTRIBUTES(TEXT = "Clear Filter", IMAGE = "clear")
                CALL init_filter()
                CALL load_transactions()

            ON ACTION apply_filter
                ATTRIBUTES(TEXT = "Apply Filter", IMAGE = "search")
                CALL load_transactions()

        END INPUT

        -- Transaction display array
        DISPLAY ARRAY arr_st30_trans TO st30_trans.*
            ATTRIBUTES(COUNT = arr_st30_trans.getLength())

            BEFORE DISPLAY
                CALL display_summary_totals()

            BEFORE ROW
                LET curr_idx = arr_curr()
                IF curr_idx > 0 AND curr_idx <= arr_st30_trans.getLength() THEN
                    CALL load_stock_description(curr_idx)
                END IF

            ON ACTION refresh
                ATTRIBUTES(TEXT = "Refresh", IMAGE = "refresh")
                CALL load_transactions()

            ON ACTION export
                ATTRIBUTES(TEXT = "Export", IMAGE = "save")
                CALL export_transactions()

            ON ACTION view_detail
                ATTRIBUTES(TEXT = "View Stock", IMAGE = "info", DEFAULTVIEW = NO)
                IF curr_idx > 0 THEN
                    CALL view_stock_detail()
                END IF

        END DISPLAY

        ON ACTION quit
            ATTRIBUTES(TEXT = "Quit", IMAGE = "quit")
            EXIT DIALOG

        ON ACTION close
            EXIT DIALOG

    END DIALOG
END FUNCTION

-- ==============================================================
-- Load Transactions based on filter criteria
-- ==============================================================
FUNCTION load_transactions()
    DEFINE sql_stmt STRING
    DEFINE where_clause STRING
    DEFINE idx INTEGER

    -- Clear existing data
    CALL arr_st30_trans.clear()
    CALL arr_stock_desc.clear()

    -- Build WHERE clause based on filter criteria
    LET where_clause = " WHERE 1=1 "

    IF filter_rec.id IS NOT NULL THEN
        LET where_clause = where_clause || " AND id = " || filter_rec.id
    END IF

    IF filter_rec.doc_type IS NOT NULL AND LENGTH(filter_rec.doc_type) > 0 THEN
        LET where_clause = where_clause || " AND doc_type = '" || filter_rec.doc_type || "'"
    END IF

    IF filter_rec.direction IS NOT NULL AND LENGTH(filter_rec.direction) > 0 THEN
        LET where_clause = where_clause || " AND direction = '" || filter_rec.direction || "'"
    END IF

    IF filter_rec.batch_id IS NOT NULL AND LENGTH(filter_rec.batch_id) > 0 THEN
        LET where_clause = where_clause || " AND batch_id LIKE '%" || filter_rec.batch_id || "%'"
    END IF

    IF filter_rec.date_from IS NOT NULL THEN
        LET where_clause = where_clause || " AND trans_date >= '" || filter_rec.date_from || "'"
    END IF

    IF filter_rec.date_to IS NOT NULL THEN
        LET where_clause = where_clause || " AND trans_date <= '" || filter_rec.date_to || "'"
    END IF

    -- Build complete SQL
    LET sql_stmt = "SELECT * FROM st30_trans" || where_clause || " ORDER BY trans_date DESC, id DESC"

    -- Execute query
    LET idx = 0

    TRY
        DECLARE c_trans CURSOR FROM sql_stmt

        FOREACH c_trans INTO arr_st30_trans[idx + 1].*
            LET idx = idx + 1

            -- Load stock description for each row
            CALL get_stock_description(arr_st30_trans[idx].id)
                RETURNING arr_stock_desc[idx].stock_desc
        END FOREACH

        FREE c_trans

    CATCH
        CALL utils_globals.show_error("Error loading transactions: " || SQLCA.SQLCODE)
        RETURN
    END TRY

    -- Calculate totals
    CALL calculate_totals()

    -- Show message if no records found
    IF idx = 0 THEN
        CALL utils_globals.show_info("No transactions found matching the criteria.")
    ELSE
        MESSAGE SFMT("%1 transaction(s) loaded.", idx)
    END IF

    -- Update display
    CALL display_summary_totals()
END FUNCTION

-- ==============================================================
-- Get Stock Description
-- ==============================================================
FUNCTION get_stock_description(p_id INTEGER)
    RETURNS VARCHAR(150)

    DEFINE v_desc VARCHAR(150)

    SELECT description INTO v_desc
        FROM st01_mast
        WHERE id = p_id

    IF SQLCA.SQLCODE <> 0 THEN
        LET v_desc = "Unknown Stock"
    END IF

    RETURN v_desc
END FUNCTION

-- ==============================================================
-- Load stock description for current row
-- ==============================================================
FUNCTION load_stock_description(p_idx INTEGER)
    IF p_idx > 0 AND p_idx <= arr_stock_desc.getLength() THEN
        -- Description is already loaded in array
        MESSAGE SFMT("Stock: %1", arr_stock_desc[p_idx].stock_desc)
    END IF
END FUNCTION

-- ==============================================================
-- Calculate totals
-- ==============================================================
FUNCTION calculate_totals()
    DEFINE i INTEGER

    LET total_in = 0
    LET total_out = 0

    FOR i = 1 TO arr_st30_trans.getLength()
        IF arr_st30_trans[i].direction = "IN" THEN
            LET total_in = total_in + arr_st30_trans[i].qnty
        ELSE IF arr_st30_trans[i].direction = "OUT" THEN
            LET total_out = total_out + arr_st30_trans[i].qnty
        END IF
        END IF
    END FOR

    LET net_movement = total_in - total_out
END FUNCTION

-- ==============================================================
-- Display summary totals
-- ==============================================================
FUNCTION display_summary_totals()
    DEFINE summary STRING

    LET summary = SFMT("Total IN: %1 | Total OUT: %2 | Net Movement: %3",
        total_in USING "<<<,<<<,<<&.&&",
        total_out USING "<<<,<<<,<<&.&&",
        net_movement USING "<<<,<<<,<<&.&&")

    MESSAGE summary
END FUNCTION

-- ==============================================================
-- Validate Stock Code
-- ==============================================================
FUNCTION validate_id()
    DEFINE v_exists INTEGER
    DEFINE v_desc VARCHAR(150)

    SELECT COUNT(*), MAX(description)
        INTO v_exists, v_desc
        FROM st01_mast
        WHERE id = filter_rec.id

    IF v_exists = 0 THEN
        CALL utils_globals.show_error("Stock code not found.")
        LET filter_rec.id = NULL
    ELSE
        MESSAGE SFMT("Stock: %1", v_desc)
    END IF
END FUNCTION

-- ==============================================================
-- Lookup Stock for Filter
-- ==============================================================
FUNCTION lookup_stock_for_filter()
    DEFINE selected_code INTEGER

    CALL st121_st_lkup.display_stocklist() RETURNING selected_code

    IF selected_code IS NOT NULL AND selected_code > 0 THEN
        LET filter_rec.id = selected_code
        DISPLAY BY NAME filter_rec.id
        CALL validate_id()
    END IF
END FUNCTION

-- ==============================================================
-- View Stock Detail
-- ==============================================================
PRIVATE FUNCTION view_stock_detail()
    DEFINE v_id INTEGER
    DEFINE v_desc VARCHAR(150)
    DEFINE v_barcode VARCHAR(50)
    DEFINE v_cost DECIMAL(15,2)
    DEFINE v_price DECIMAL(15,2)
    DEFINE v_on_hand DECIMAL(15,2)
    DEFINE v_status VARCHAR(10)
    DEFINE msg STRING

    IF curr_idx <= 0 OR curr_idx > arr_st30_trans.getLength() THEN
        RETURN
    END IF

    LET v_id = arr_st30_trans[curr_idx].id

    SELECT description, barcode, unit_cost, sell_price, stock_on_hand, status
        INTO v_desc, v_barcode, v_cost, v_price, v_on_hand, v_status
        FROM st01_mast
        WHERE id = v_id

    IF SQLCA.SQLCODE = 0 THEN
        LET msg = SFMT("Stock Code: %1\nDescription: %2\nBarcode: %3\nCost: %4\nPrice: %5\nOn Hand: %6\nStatus: %7",
            v_id,
            v_desc,
            v_barcode,
            v_cost USING "<<<,<<<,<<&.&&",
            v_price USING "<<<,<<<,<<&.&&",
            v_on_hand USING "<<<,<<<,<<&.&&",
            v_status)

        CALL utils_globals.show_info(msg)
    ELSE
        CALL utils_globals.show_error("Error loading stock details.")
    END IF
END FUNCTION

-- ==============================================================
-- Export Transactions (placeholder)
-- ==============================================================
FUNCTION export_transactions()
    -- Placeholder for export functionality
    -- Could export to CSV, Excel, etc.
    CALL utils_globals.show_info("Export functionality not yet implemented.")
END FUNCTION

-- ==============================================================
-- Function : update_stock_on_hand
-- Purpose  : Adjust stock quantity (IN / OUT)
-- ==============================================================

PUBLIC FUNCTION update_stock_on_hand(p_stock_id INTEGER, p_qty DECIMAL,
                                     p_direction VARCHAR(3), p_doc_type STRING)
    RETURNS SMALLINT

    DEFINE l_current_stock DECIMAL(15,2)
    DEFINE l_user_id INTEGER

    LET l_user_id = utils_globals.get_current_user_id()

    BEGIN WORK
    TRY
        SELECT stock_on_hand INTO l_current_stock
          FROM st01_mast
         WHERE stock_id = p_stock_id
           FOR UPDATE

        IF p_direction = "OUT" THEN
            IF l_current_stock < p_qty THEN
                CALL utils_globals.show_error(SFMT(
                    "Insufficient stock: Available %1, Required %2",
                    l_current_stock, p_qty))
                ROLLBACK WORK
                RETURN FALSE
            END IF

            UPDATE st01_mast
               SET stock_on_hand = stock_on_hand - p_qty,
                   total_sales = total_sales + p_qty,
                   updated_at = CURRENT
             WHERE stock_id = p_stock_id

        ELSE IF p_direction = "IN" THEN
            UPDATE st01_mast
               SET stock_on_hand = stock_on_hand + p_qty,
                   total_purch = total_purch + p_qty,
                   updated_at = CURRENT
             WHERE stock_id = p_stock_id
        END IF
        END IF

        INSERT INTO st30_trans (
            stock_id, trans_date, doc_type, direction, qnty,
            created_at, created_by)
        VALUES (
            p_stock_id, TODAY, p_doc_type, p_direction, p_qty,
            CURRENT, l_user_id)

        COMMIT WORK
        RETURN TRUE

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(SFMT(
            "Stock update failed for ID %1: %2", p_stock_id, SQLCA.SQLERRM))
        RETURN FALSE
    END TRY
END FUNCTION

