-- ==============================================================
-- Program   : sa131_order.4gl
-- Purpose   : Sales Order Program
-- Module    : Sales Order (sa)
-- Number    : 131
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Updated   : Added proper workflow, copy-to-invoice, status management
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL st121_st_lkup
IMPORT FGL utils_doc_totals
IMPORT FGL sa132_invoice
IMPORT FGL dl121_lkup

SCHEMA demoappdb

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE order_hdr_t RECORD LIKE sa31_ord_hdr.*

DEFINE m_ord_rec order_hdr_t

DEFINE m_ord_lines_arr DYNAMIC ARRAY OF RECORD LIKE sa31_ord_det.*
DEFINE m_debt_trans_arr DYNAMIC ARRAY OF RECORD LIKE dl30_trans.*

DEFINE m_debt_rec RECORD LIKE dl01_mast.*

DEFINE m_arr_codes DYNAMIC ARRAY OF STRING
DEFINE m_curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

-- ==============================================================
-- Program init
-- ==============================================================
FUNCTION init_ord_module()

    --DEFINE chosen_row SMALLINT
    DEFINE selected_code INTEGER

    LET is_edit_mode = FALSE
    INITIALIZE m_debt_rec.* TO NULL
    DISPLAY BY NAME m_debt_rec.*

    DISPLAY ARRAY m_debt_trans_arr
        TO m_debt_trans_arr.*
        ATTRIBUTES(UNBUFFERED, DOUBLECLICK = row_select)
        BEFORE DISPLAY
            CALL DIALOG.setActionHidden("accept", TRUE)
            CALL DIALOG.setActionHidden("cancel", TRUE)
            CALL DIALOG.setActionHidden("row_select", TRUE)
        ON ACTION Find
            LET selected_code = dl121_lkup.get_debtors_list()
            CALL load_customer(selected_code)
            LET is_edit_mode = FALSE
        ON ACTION New ATTRIBUTES(TEXT = "New", IMAGE = "new")
            CALL new_order();
            LET is_edit_mode = FALSE
        
        ON ACTION List ATTRIBUTES(TEXT = "Refresh Records", IMAGE = "refresh")
            --CALL load_all_orders();
            LET is_edit_mode = FALSE
        ON ACTION Edit ATTRIBUTES(TEXT = "Edit", IMAGE = "pen")
            IF m_debt_rec.id IS NULL OR m_debt_rec.id = 0 THEN
                CALL utils_globals.show_info("No record selected to edit.")
            ELSE
                LET is_edit_mode = TRUE;
                CALL utils_globals.set_form_label(
                    'lbl_form_title', 'ORDER MAINTENANCE');
                --CALL edit_()
            END IF
        ON ACTION DELETE ATTRIBUTES(TEXT = "Delete", IMAGE = "fa-trash")
            CALL delete_order(m_ord_rec.id);
            LET is_edit_mode = FALSE
        ON ACTION PREVIOUS
            CALL move_record(-1)
        ON ACTION Next
            CALL move_record(1)
        ON ACTION add_invoice ATTRIBUTES(TEXT = "Gen Invoice", IMAGE = "new")
            IF m_debt_rec.id THEN
                --CALL sa132_invoice.new_invoice(m_debt_rec.id)
            ELSE
                CALL utils_globals.show_warning(
                    'Choose a creditor record first.')
            END IF
        ON ACTION EXIT ATTRIBUTES(TEXT = "Exit", IMAGE = "fa-close")
            EXIT DISPLAY
    END DISPLAY
END FUNCTION

-- ==============================================================
-- Function : new_order (NEW - Header first, then lines)
-- ==============================================================
FUNCTION new_order()
    DEFINE l_hdr RECORD LIKE sa31_ord_hdr.*
    DEFINE l_next_doc_no INTEGER
    DEFINE l_new_hdr_id INTEGER

    -- ==========================================================
    -- 1. Generate next document number
    -- ==========================================================
    SELECT COALESCE(MAX(doc_no), 0) + 1 INTO l_next_doc_no FROM sa31_ord_hdr

    -- ==========================================================
    -- 2. Initialize header
    -- ==========================================================
    INITIALIZE l_hdr.* TO NULL
    LET l_hdr.id = l_next_doc_no
    LET l_hdr.trans_date = TODAY
    LET l_hdr.status = "NEW"
    LET l_hdr.created_at = CURRENT
    LET l_hdr.created_by = utils_globals.get_current_user_id()
    LET l_hdr.gross_tot = 0
    LET l_hdr.vat_tot = 0
    LET l_hdr.disc_tot = 0
    LET l_hdr.net_tot = 0

    -- ==========================================================
    -- 3. Input Header Details
    -- ==========================================================
    OPEN WINDOW w_order_hdr WITH FORM "sa131_order" ATTRIBUTES(STYLE = "dialog")

    CALL utils_globals.set_form_label(
        "lbl_form_title", "New Sales Order - Header")

    INPUT BY NAME l_hdr.cust_id,
        l_hdr.trans_date,
        l_hdr.ref_doc_type,
        l_hdr.ref_doc_no
        ATTRIBUTES(WITHOUT DEFAULTS, UNBUFFERED)

        BEFORE INPUT
            DISPLAY BY NAME l_hdr.id, l_hdr.status, l_hdr.trans_date
            MESSAGE SFMT("Enter order header details for Order #%1",
                l_next_doc_no)

        AFTER FIELD acc_code
            IF l_hdr.cust_id IS NOT NULL THEN
                --CALL load_customer_details(
                --    l_hdr.cust_id)
                --    RETURNING l_hdr.cust_id,
                --        l_hdr.cust_name,
                --        l_hdr.cust_phone,
                --        l_hdr.cust_email,
                --        l_hdr.cust_address1,
                --        l_hdr.cust_address2,
                --        l_hdr.cust_address3,
                --        l_hdr.cust_postal_code,
                --        l_hdr.cust_vat_no,
                --        l_hdr.cust_payment_terms

                IF l_hdr.cust_id IS NULL THEN
                    CALL utils_globals.show_error("Customer not found")
                    NEXT FIELD acc_code
                END IF
            END IF

            --ON ACTION lookup_customer ATTRIBUTES(TEXT="Customer Lookup", IMAGE="zoom")
            --    CALL dl121_lkup.load_lookup_form_with_search() RETURNING l_hdr.cust_id
            --    IF l_hdr.cust_id IS NOT NULL THEN
            --        CALL load_customer_details(l_hdr.cust_id)
            --            RETURNING l_hdr.cust_id, l_hdr.cust_name,
            --                      l_hdr.cust_phone, l_hdr.cust_email, l_hdr.cust_address1,
            --                      l_hdr.cust_address2, l_hdr.cust_address3,
            --                      l_hdr.cust_postal_code, l_hdr.cust_vat_no,
            --                      l_hdr.cust_payment_terms
            --        DISPLAY BY NAME l_hdr.cust_id
            --    END IF

        ON ACTION accept ATTRIBUTES(TEXT = "Save Header", IMAGE = "save")
            -- Validate header
            IF l_hdr.cust_id IS NULL THEN
                CALL utils_globals.show_error("Customer is required")
                NEXT FIELD acc_code
            END IF

            IF l_hdr.trans_date IS NULL THEN
                LET l_hdr.trans_date = TODAY
            END IF

            ACCEPT INPUT

        ON ACTION cancel ATTRIBUTES(TEXT = "Cancel", IMAGE = "exit")
            CALL utils_globals.show_info("Order creation cancelled.")
            CLOSE WINDOW w_order_hdr
            RETURN
    END INPUT

    -- Check if cancelled
    IF INT_FLAG THEN
        LET INT_FLAG = FALSE
        CLOSE WINDOW w_order_hdr
        RETURN
    END IF

    -- ==========================================================
    -- 4. Save Header to Database (CRITICAL STEP)
    -- ==========================================================
    BEGIN WORK
    TRY
        INSERT INTO sa31_ord_hdr VALUES(l_hdr.*)

        -- Get the generated header ID
        LET l_new_hdr_id = SQLCA.SQLERRD[2]
        LET l_hdr.id = l_new_hdr_id

        COMMIT WORK

        CALL utils_globals.show_success(
            SFMT("Order header #%1 saved. ID=%2. Now add order lines.",
                l_next_doc_no, l_new_hdr_id))

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to save order header: %1", SQLCA.SQLCODE))
        CLOSE WINDOW w_order_hdr
        RETURN
    END TRY

    CLOSE WINDOW w_order_hdr

    -- ==========================================================
    -- 5. Now add lines (header ID exists)
    -- ==========================================================
    LET m_ord_rec.* = l_hdr.*
    CALL m_ord_lines_arr.clear()
    CALL m_ord_lines_arr.clear()

    CALL input_order_lines(l_new_hdr_id)

    -- ==========================================================
    -- 6. Load the complete order for viewing
    -- ==========================================================
    CALL load_order(l_new_hdr_id)

END FUNCTION

-- ==============================================================
-- Function : new_ord_from_master (NEW - called from customer master)
-- ==============================================================
FUNCTION new_ord_from_master(p_cust_id INTEGER)
    DEFINE l_hdr RECORD LIKE sa31_ord_hdr.*
    DEFINE l_next_doc_no INTEGER
    DEFINE l_new_hdr_id INTEGER

    LET l_new_hdr_id = p_cust_id
    -- ==========================================================
    -- 1. Generate next document number
    -- ==========================================================
    SELECT COALESCE(MAX(doc_no), 0) + 1 INTO l_next_doc_no FROM sa31_ord_hdr

    -- ==========================================================
    -- 2. Initialize header with customer details
    -- ==========================================================
    INITIALIZE l_hdr.* TO NULL
    LET l_hdr.id = l_next_doc_no
    LET l_hdr.trans_date = TODAY
    LET l_hdr.status = "NEW"
    LET l_hdr.created_at = CURRENT
    LET l_hdr.created_by = utils_globals.get_current_user_id()
    LET l_hdr.gross_tot = 0
    LET l_hdr.vat_tot = 0
    LET l_hdr.disc_tot = 0
    LET l_hdr.net_tot = 0

    -- ==========================================================
    -- 3. Load customer details from dl01_mast
    -- ==========================================================
    --CALL load_customer_details( p_cust_id)
    --    RETURNING l_hdr.cust_id,
    --        l_hdr.cust_name,
    --        l_hdr.cust_phone,
    --        l_hdr.cust_email,
    --        l_hdr.cust_address1,
    --        l_hdr.cust_address2,
    --        l_hdr.cust_address3,
    --        l_hdr.cust_postal_code,
    --        l_hdr.cust_vat_no,
    --        l_hdr.cust_payment_terms

    IF l_hdr.cust_id IS NULL THEN
        CALL utils_globals.show_error("Customer not found")
        RETURN
    END IF

    -- ==========================================================
    -- 4. Input Header Details
    -- ==========================================================
    OPEN WINDOW w_order_hdr WITH FORM "sa131_order" ATTRIBUTES(STYLE = "dialog")

    CALL utils_globals.set_form_label(
        "lbl_form_title", "New Sales Order - Header")

    INPUT BY NAME l_hdr.cust_id,
        l_hdr.trans_date,
        l_hdr.ref_doc_type,
        l_hdr.ref_doc_no
        ATTRIBUTES(WITHOUT DEFAULTS, UNBUFFERED)

        BEFORE INPUT
            DISPLAY BY NAME l_hdr.id,
                l_hdr.status,
                l_hdr.trans_date,
                l_hdr.cust_id,
                l_hdr.cust_name,
                l_hdr.cust_phone,
                l_hdr.cust_email
            MESSAGE SFMT("Enter order header details for Order #%1 - Customer: %2",
                l_next_doc_no, l_hdr.cust_name)

        AFTER FIELD acc_code
            IF l_hdr.cust_id IS NOT NULL THEN
                --CALL load_customer_details(
                --    l_hdr.cust_id)
                --    RETURNING l_hdr.cust_id,
                --        l_hdr.cust_name,
                --        l_hdr.cust_phone,
                --        l_hdr.cust_email,
                --        l_hdr.cust_address1,
                --        l_hdr.cust_address2,
                --        l_hdr.cust_address3,
                --        l_hdr.cust_postal_code,
                --        l_hdr.cust_vat_no,
                --        l_hdr.cust_payment_terms

                IF l_hdr.cust_id IS NULL THEN
                    CALL utils_globals.show_error("Customer not found")
                    NEXT FIELD acc_code
                END IF
            END IF

        ON ACTION lookup_customer
            ATTRIBUTES(TEXT = "Customer Lookup", IMAGE = "zoom")
            CALL dl121_lkup.load_lookup_form_with_search()
                RETURNING l_hdr.cust_id
            IF l_hdr.cust_id IS NOT NULL THEN
                --CALL load_customer_details(
                --    l_hdr.cust_id)
                --    RETURNING l_hdr.cust_id,
                --        l_hdr.cust_name,
                --        l_hdr.cust_phone,
                --        l_hdr.cust_email,
                --        l_hdr.cust_address1,
                --        l_hdr.cust_address2,
                --        l_hdr.cust_address3,
                --        l_hdr.cust_postal_code,
                --        l_hdr.cust_vat_no,
                --        l_hdr.cust_payment_terms
                DISPLAY BY NAME l_hdr.cust_id
            END IF

        ON ACTION accept ATTRIBUTES(TEXT = "Save Header", IMAGE = "save")
            -- Validate header
            IF l_hdr.cust_id IS NULL THEN
                CALL utils_globals.show_error("Customer is required")
                NEXT FIELD acc_code
            END IF

            IF l_hdr.trans_date IS NULL THEN
                LET l_hdr.trans_date = TODAY
            END IF

            ACCEPT INPUT

        ON ACTION cancel ATTRIBUTES(TEXT = "Cancel", IMAGE = "exit")
            CALL utils_globals.show_info("Order creation cancelled.")
            CLOSE WINDOW w_order_hdr
            RETURN
    END INPUT

    -- Check if cancelled
    IF INT_FLAG THEN
        LET INT_FLAG = FALSE
        CLOSE WINDOW w_order_hdr
        RETURN
    END IF

    -- ==========================================================
    -- 5. Save Header to Database (CRITICAL STEP)
    -- ==========================================================
    BEGIN WORK
    TRY
        INSERT INTO sa31_ord_hdr VALUES(l_hdr.*)

        -- Get the generated header ID
        LET l_new_hdr_id = SQLCA.SQLERRD[2]
        LET l_hdr.id = l_new_hdr_id

        COMMIT WORK

        CALL utils_globals.show_success(
            SFMT("Order header #%1 saved for %2. ID=%3. Now add order lines.",
                l_next_doc_no, l_hdr.cust_name, l_new_hdr_id))

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to save order header: %1", SQLCA.SQLCODE))
        CLOSE WINDOW w_order_hdr
        RETURN
    END TRY

    CLOSE WINDOW w_order_hdr

    -- ==========================================================
    -- 6. Now add lines (header ID exists)
    -- ==========================================================
    LET m_ord_rec.* = l_hdr.*
    CALL m_ord_lines_arr.clear()
    CALL m_ord_lines_arr.clear()

    CALL input_order_lines(l_new_hdr_id)

    -- ==========================================================
    -- 7. Load the complete order for viewing
    -- ==========================================================
    CALL load_order(l_new_hdr_id)

END FUNCTION

-- ==============================================================
-- Function : input_order_lines (NEW)
-- ==============================================================
FUNCTION input_order_lines(p_hdr_id INTEGER)

    OPEN WINDOW w_order_lines
        WITH
        FORM "sa131_order"
        ATTRIBUTES(STYLE = "dialog")

    CALL utils_globals.set_form_label(
        "lbl_form_title", SFMT("Order #%1 - Add Lines", m_ord_rec.id))

    DISPLAY BY NAME m_ord_rec.id,
        m_ord_rec.ref_doc_no,
        m_ord_rec.cust_id,
        m_ord_rec.trans_date,
        m_ord_rec.status,
        m_ord_rec.gross_tot,
        m_ord_rec.disc_tot,
        m_ord_rec.vat_tot,
        m_ord_rec.net_tot

    DIALOG ATTRIBUTES(UNBUFFERED)

        DISPLAY ARRAY m_ord_lines_arr TO arr_sa_ord_lines.*
            BEFORE DISPLAY
                CALL DIALOG.setActionHidden("accept", TRUE)

            ON ACTION add ATTRIBUTES(TEXT = "Add Line", IMAGE = "new")
                CALL edit_or_add_order_line(p_hdr_id, 0, TRUE)
                CALL calculate_order_totals()

            ON ACTION edit ATTRIBUTES(TEXT = "Edit Line", IMAGE = "pen")
                IF arr_curr() > 0 THEN
                    CALL edit_or_add_order_line(p_hdr_id, arr_curr(), FALSE)
                    CALL calculate_order_totals()
                END IF

            ON ACTION delete ATTRIBUTES(TEXT = "Delete Line", IMAGE = "delete")
                IF arr_curr() > 0 THEN
                    CALL delete_order_line(arr_curr())
                    CALL calculate_order_totals()
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Save Lines", IMAGE = "save")
                CALL save_order_lines(p_hdr_id)
                CALL save_order_header_totals()
                CALL utils_globals.show_success(
                    "Order lines saved successfully.")
                EXIT DIALOG

            ON ACTION close ATTRIBUTES(TEXT = "Close", IMAGE = "exit")
                IF m_ord_lines_arr.getLength() > 0 THEN
                    IF utils_globals.show_confirm(
                        "Save lines before closing?", "Confirm") THEN
                        CALL save_order_lines(p_hdr_id)
                        CALL save_order_header_totals()
                    END IF
                END IF
                EXIT DIALOG
        END DISPLAY

    END DIALOG

    CLOSE WINDOW w_order_lines

END FUNCTION

-- ==============================================================
-- Function : edit_or_add_order_line
-- ==============================================================
FUNCTION edit_or_add_order_line(
    p_doc_id INTEGER, p_row INTEGER, p_is_new SMALLINT)
    DEFINE l_line RECORD LIKE sa31_ord_det.*
    DEFINE l_stock_id INTEGER
    DEFINE l_item_desc VARCHAR(150)

    -- Initialize new line
    IF p_is_new THEN
        INITIALIZE l_line.* TO NULL
        LET l_line.hdr_id = p_doc_id
        LET l_line.line_no = m_ord_lines_arr.getLength() + 1
        LET l_line.vat_rate = 15.00
        LET l_line.disc_pct = 0
        LET l_line.status = 1
        LET l_line.created_at = CURRENT
        LET l_line.created_by = utils_globals.get_current_user_id()
    ELSE
        -- Load from existing full array line
        LET l_line.* = m_ord_lines_arr[p_row].*
    END IF

    -- ==============================
    -- Input Dialog for editing/adding
    -- ==============================
    OPEN WINDOW w_line_edit
        WITH
        FORM "sa131_order_line"
        ATTRIBUTES(STYLE = "dialog")

    INPUT BY NAME l_line.stock_id, l_line.qnty, l_line.disc_pct, l_line.vat_rate
        ATTRIBUTES(WITHOUT DEFAULTS, UNBUFFERED)

        BEFORE INPUT
            DISPLAY BY NAME l_line.*

        BEFORE FIELD stock_id
            -- Stock lookup popup
            CALL st121_st_lkup.fetch_list() RETURNING l_stock_id

            IF l_stock_id IS NOT NULL AND l_stock_id > 0 THEN
                LET l_line.stock_id = l_stock_id
                LET l_line.stock_id = l_stock_id

                -- Load stock defaults
                CALL load_stock_defaults(
                    l_stock_id)
                    RETURNING l_line.unit_price, l_line.unit_price, l_item_desc

                LET l_line.unit_price = l_line.unit_price
                LET l_line.item_name = l_item_desc

                DISPLAY BY NAME l_line.stock_id,
                    l_line.unit_price,
                    l_line.unit_price,
                    l_line.item_name

                NEXT FIELD qnty
            END IF

        AFTER FIELD qnty
            IF l_line.qnty IS NOT NULL AND l_line.qnty > 0 THEN
                CALL calculate_line_totals(
                    l_line.qnty,
                    l_line.unit_price,
                    l_line.disc_pct,
                    l_line.vat_rate)
                    RETURNING l_line.gross_amt,
                        l_line.disc_amt,
                        l_line.net_excl_amt,
                        l_line.vat_amt,
                        l_line.line_total

                DISPLAY BY NAME l_line.gross_amt,
                    l_line.disc_amt,
                    l_line.net_excl_amt,
                    l_line.vat_amt,
                    l_line.line_total
            END IF

        AFTER FIELD unit_price, disc_pct, vat_rate
            IF l_line.qnty IS NOT NULL THEN
                CALL calculate_line_totals(
                    l_line.qnty,
                    l_line.unit_price,
                    l_line.disc_pct,
                    l_line.vat_rate)
                    RETURNING l_line.gross_amt,
                        l_line.disc_amt,
                        l_line.net_excl_amt,
                        l_line.vat_amt,
                        l_line.line_total

                DISPLAY BY NAME l_line.gross_amt,
                    l_line.disc_amt,
                    l_line.net_excl_amt,
                    l_line.vat_amt,
                    l_line.line_total
            END IF

        ON ACTION accept ATTRIBUTES(TEXT = "Save Line", IMAGE = "save")
            -- Validate
            IF l_line.stock_id IS NULL OR l_line.stock_id = 0 THEN
                CALL utils_globals.show_error("Stock item is required")
                NEXT FIELD stock_id
            END IF

            IF l_line.qnty IS NULL OR l_line.qnty <= 0 THEN
                CALL utils_globals.show_error("Quantity must be greater than 0")
                NEXT FIELD qnty
            END IF

            -- Save to both arrays
            IF p_is_new THEN
                -- Add to full array
                LET m_ord_lines_arr[m_ord_lines_arr.getLength() + 1].*
                    = l_line.*
                -- Add to display array (only visible fields)
                LET m_ord_lines_arr[m_ord_lines_arr.getLength() + 1].stock_id =
                    l_line.stock_id
                LET m_ord_lines_arr[m_ord_lines_arr.getLength()].qnty =
                    l_line.qnty
                LET m_ord_lines_arr[m_ord_lines_arr.getLength()].unit_price =
                    l_line.unit_price
                LET m_ord_lines_arr[m_ord_lines_arr.getLength()].disc_amt =
                    l_line.disc_amt
                LET m_ord_lines_arr[m_ord_lines_arr.getLength()].vat_amt =
                    l_line.vat_amt
                LET m_ord_lines_arr[m_ord_lines_arr.getLength()].line_total =
                    l_line.line_total
            ELSE
                -- Update full array
                LET m_ord_lines_arr[p_row].* = l_line.*
                -- Update display array (only visible fields)
                LET m_ord_lines_arr[p_row].stock_id = l_line.stock_id
                LET m_ord_lines_arr[p_row].qnty = l_line.qnty
                LET m_ord_lines_arr[p_row].unit_price = l_line.unit_price
                LET m_ord_lines_arr[p_row].disc_amt = l_line.disc_amt
                LET m_ord_lines_arr[p_row].vat_amt = l_line.vat_amt
                LET m_ord_lines_arr[p_row].line_total = l_line.line_total
            END IF

            CALL utils_globals.show_success("Line saved")
            EXIT INPUT

        ON ACTION cancel
            EXIT INPUT
    END INPUT

    CLOSE WINDOW w_line_edit

END FUNCTION

-- ==============================================================
-- Function : calculate_line_totals (NEW)
-- ==============================================================
PRIVATE FUNCTION calculate_line_totals(
    p_qnty DECIMAL, p_price DECIMAL, p_disc_pct DECIMAL, p_vat_rate DECIMAL)
    RETURNS(DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL)

    DEFINE l_gross, l_disc, l_net, l_vat, l_total DECIMAL(15, 2)

    -- Gross = Quantity × Price
    LET l_gross = p_qnty * p_price

    -- Discount = Gross × (disc_tot% / 100)
    LET l_disc = l_gross * (p_disc_pct / 100)

    -- Net = Gross - Discount
    LET l_net = l_gross - l_disc

    -- vat_tot = Net × (vat_tot% / 100)
    LET l_vat = l_net * (p_vat_rate / 100)

    -- Total = Net + vat_tot
    LET l_total = l_net + l_vat

    RETURN l_gross, l_disc, l_net, l_vat, l_total

END FUNCTION

-- ==============================================================
-- Function : load_stock_defaults (with stock check)
-- ==============================================================
PRIVATE FUNCTION load_stock_defaults(
    p_stock_id INTEGER)
    RETURNS(DECIMAL, DECIMAL, VARCHAR(150))

    DEFINE l_cost DECIMAL(15, 2)
    DEFINE l_price DECIMAL(15, 2)
    DEFINE l_desc VARCHAR(150)
    DEFINE l_stock_on_hand DECIMAL(15, 2)
    DEFINE l_available DECIMAL(15, 2)

    SELECT unit_price, sell_price, description, stock_on_hand
        INTO l_cost, l_price, l_desc, l_stock_on_hand
        FROM st01_mast
        WHERE stock_id = p_stock_id

    IF SQLCA.SQLCODE != 0 THEN
        LET l_cost = 0
        LET l_price = 0
        LET l_desc = "Unknown Item"
    ELSE
        -- Get available stock (on hand - reserved)
        CALL get_available_stock(p_stock_id) RETURNING l_available

        -- Display stock info to user
        MESSAGE SFMT("Stock: %1 | On Hand: %2 | Available: %3",
            l_desc,
            l_stock_on_hand USING "<<<,<<<,<<&.&&",
            l_available USING "<<<,<<<,<<&.&&")
    END IF

    RETURN l_cost, l_price, l_desc

END FUNCTION

-- ==============================================================
-- Function : get_available_stock (NEW)
-- ==============================================================
FUNCTION get_available_stock(p_stock_id INTEGER) RETURNS DECIMAL(15, 2)

    DEFINE l_on_hand DECIMAL(15, 2)
    DEFINE l_reserved DECIMAL(15, 2)
    DEFINE l_available DECIMAL(15, 2)

    -- Get stock on hand
    SELECT stock_on_hand
        INTO l_on_hand
        FROM st01_mast
        WHERE stock_id = p_stock_id

    IF SQLCA.SQLCODE != 0 THEN
        RETURN 0
    END IF

    -- Calculate reserved quantity (sum of all pending order lines)
    SELECT COALESCE(SUM(det.qnty), 0)
        INTO l_reserved
        FROM sa31_ord_det det, sa31_ord_hdr hdr
        WHERE det.hdr_id = hdr.id
            AND det.stock_id = p_stock_id
            AND hdr.status IN ('NEW', 'CONFIRMED', 'PENDING', 'PROCESSING')
            AND hdr.deleted_at IS NULL

    -- Available = On Hand - Reserved
    LET l_available = l_on_hand - l_reserved

    RETURN l_available

END FUNCTION

-- ==============================================================
-- Function : check_stock_availability (NEW - CRITICAL)
-- ==============================================================
FUNCTION check_stock_availability(
    p_stock_id INTEGER, p_required_qty DECIMAL, p_exclude_order_id INTEGER)
    RETURNS(SMALLINT, DECIMAL, DECIMAL, VARCHAR(255))

    DEFINE l_on_hand DECIMAL(15, 2)
    DEFINE l_reserved DECIMAL(15, 2)
    DEFINE l_available DECIMAL(15, 2)
    DEFINE l_stock_desc VARCHAR(150)
    DEFINE l_message VARCHAR(255)
    DEFINE l_ok SMALLINT

    -- Get stock details
    SELECT stock_on_hand, description
        INTO l_on_hand, l_stock_desc
        FROM st01_mast
        WHERE stock_id = p_stock_id

    IF SQLCA.SQLCODE != 0 THEN
        LET l_message = "Stock item not found"
        RETURN FALSE, 0, 0, l_message
    END IF

    -- Calculate reserved (excluding current order if editing)
    IF p_exclude_order_id IS NULL THEN
        SELECT COALESCE(SUM(det.qnty), 0)
            INTO l_reserved
            FROM sa31_ord_det det, sa31_ord_hdr hdr
            WHERE det.hdr_id = hdr.id
                AND det.stock_id = p_stock_id
                AND hdr.status IN ('NEW', 'CONFIRMED', 'PENDING', 'PROCESSING')
                AND hdr.deleted_at IS NULL
    ELSE
        SELECT COALESCE(SUM(det.qnty), 0)
            INTO l_reserved
            FROM sa31_ord_det det, sa31_ord_hdr hdr
            WHERE det.hdr_id = hdr.id
                AND det.stock_id = p_stock_id
                AND hdr.status IN ('NEW', 'CONFIRMED', 'PENDING', 'PROCESSING')
                AND hdr.deleted_at IS NULL
                AND hdr.id != p_exclude_order_id
    END IF

    -- Calculate available
    LET l_available = l_on_hand - l_reserved

    -- Check if enough available
    IF l_available >= p_required_qty THEN
        LET l_ok = TRUE
        LET l_message =
            SFMT("Stock available: %1", l_available USING "<<<,<<<,<<&.&&")
    ELSE
        LET l_ok = FALSE
        LET l_message =
            SFMT("Insufficient stock for %1\nRequired: %2 | Available: %3 | Short: %4",
                l_stock_desc,
                p_required_qty USING "<<<,<<<,<<&.&&",
                l_available USING "<<<,<<<,<<&.&&",
                (p_required_qty - l_available) USING "<<<,<<<,<<&.&&")
    END IF

    RETURN l_ok, l_on_hand, l_available, l_message

END FUNCTION

-- ==============================================================
-- Function : validate_order_stock_levels (NEW)
-- ==============================================================
FUNCTION validate_order_stock_levels(
    p_order_id INTEGER)
    RETURNS(SMALLINT, VARCHAR(1000))

    DEFINE i INTEGER
    DEFINE l_ok SMALLINT
    DEFINE l_on_hand DECIMAL(15, 2)
    DEFINE l_available DECIMAL(15, 2)
    DEFINE l_message VARCHAR(255)
    DEFINE l_error_msg VARCHAR(1000)
    DEFINE l_has_errors SMALLINT

    LET l_has_errors = FALSE
    LET l_error_msg = "Stock availability issues:\n\n"

    -- Check each line
    FOR i = 1 TO m_ord_lines_arr.getLength()
        IF m_ord_lines_arr[i].stock_id IS NOT NULL
            AND m_ord_lines_arr[i].qnty > 0 THEN

            CALL check_stock_availability(
                m_ord_lines_arr[i].stock_id,
                m_ord_lines_arr[i].qnty,
                p_order_id)
                RETURNING l_ok, l_on_hand, l_available, l_message

            IF NOT l_ok THEN
                LET l_has_errors = TRUE
                LET l_error_msg =
                    l_error_msg || SFMT("Line %1: %2\n", i, l_message)
            END IF
        END IF
    END FOR

    IF l_has_errors THEN
        RETURN FALSE, l_error_msg
    ELSE
        RETURN TRUE, "All stock levels OK"
    END IF

END FUNCTION

-- ==============================================================
-- Function : update_stock_on_hand (NEW)
-- ==============================================================
FUNCTION update_stock_on_hand(
    p_stock_id INTEGER, p_quantity DECIMAL, p_direction VARCHAR(3))
    RETURNS SMALLINT

    DEFINE l_current_stock DECIMAL(15, 2)
    DEFINE l_user SMALLINT

    LET l_user = utils_globals.get_current_user_id()

    BEGIN WORK

    TRY
        -- Lock the stock record
        SELECT stock_on_hand
            INTO l_current_stock
            FROM st01_mast
            WHERE stock_id = p_stock_id
            FOR UPDATE

        -- Update based on direction
        IF p_direction = "OUT" THEN
            -- Sales - decrease stock
            UPDATE st01_mast
                SET stock_on_hand = stock_on_hand - p_quantity,
                    total_sales = total_sales + p_quantity,
                    updated_at = CURRENT
                WHERE stock_id = p_stock_id

        ELSE
            IF p_direction = "IN" THEN
                -- Purchase/Return - increase stock
                UPDATE st01_mast
                    SET stock_on_hand = stock_on_hand + p_quantity,
                        total_purch = total_purch + p_quantity,
                        updated_at = CURRENT
                    WHERE stock_id = p_stock_id
            END IF
        END IF

        -- Record stock transaction
        INSERT INTO st30_trans(
            stock_id,
            trans_date,
            doc_type,
            direction,
            qnty,
            created_at,
            created_by)
            VALUES(p_stock_id,
                TODAY,
                'INVOICE',
                p_direction,
                p_quantity,
                CURRENT,
                l_user)

        COMMIT WORK
        RETURN TRUE

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to update stock: %1", SQLCA.SQLCODE))
        RETURN FALSE
    END TRY

END FUNCTION

-- ==============================================================
-- Function : delete_order_line
-- ==============================================================
FUNCTION delete_order_line(p_row INTEGER)
    IF p_row > 0 THEN
        IF utils_globals.show_confirm(
            SFMT("Delete line %1?", p_row), "Confirm Delete") THEN
            -- Delete from both arrays
            CALL m_ord_lines_arr.deleteElement(p_row)
            CALL m_ord_lines_arr.deleteElement(p_row)
            CALL utils_globals.show_success("Line deleted")
        END IF
    END IF
END FUNCTION

-- ==============================================================
-- Function : save_order_lines (with stock validation)
-- ==============================================================
FUNCTION save_order_lines(p_doc_id INTEGER)
    DEFINE i INTEGER
    DEFINE l_stock_ok SMALLINT
    DEFINE l_stock_msg VARCHAR(1000)

    -- CRITICAL: Validate stock levels before saving
    CALL validate_order_stock_levels(p_doc_id) RETURNING l_stock_ok, l_stock_msg

    IF NOT l_stock_ok THEN
        CALL utils_globals.show_error(l_stock_msg)
        RETURN
    END IF

    BEGIN WORK
    TRY
        DELETE FROM sa31_ord_det WHERE hdr_id = p_doc_id

        FOR i = 1 TO m_ord_lines_arr.getLength()
            -- Ensure hdr_id is set
            LET m_ord_lines_arr[i].hdr_id = p_doc_id
            INSERT INTO sa31_ord_det VALUES m_ord_lines_arr[i].*
        END FOR

        COMMIT WORK

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to save lines: %1", SQLCA.SQLCODE))
    END TRY

END FUNCTION

-- ==============================================================
-- Function : calculate_order_totals (NEW)
-- ==============================================================
FUNCTION calculate_order_totals()
    DEFINE i INTEGER
    DEFINE l_gross, l_disc_tot, l_vat_tot, l_net DECIMAL(15, 2)

    LET l_gross = 0
    LET l_disc_tot = 0
    LET l_vat_tot = 0

    FOR i = 1 TO m_ord_lines_arr.getLength()
        LET l_gross = l_gross + NVL(m_ord_lines_arr[i].gross_amt, 0)
        LET l_disc_tot = l_disc_tot + NVL(m_ord_lines_arr[i].disc_amt, 0)
        LET l_vat_tot = l_vat_tot + NVL(m_ord_lines_arr[i].vat_amt, 0)
    END FOR

    LET l_net = l_gross - l_disc_tot + l_vat_tot

    LET m_ord_rec.gross_tot = l_gross
    LET m_ord_rec.disc_tot = l_disc_tot
    LET m_ord_rec.vat_tot = l_vat_tot
    LET m_ord_rec.net_tot = l_net

    DISPLAY BY NAME m_ord_rec.gross_tot,
        m_ord_rec.disc_tot,
        m_ord_rec.vat_tot,
        m_ord_rec.net_tot

    MESSAGE SFMT("Totals: Gross=%1, disc_tot=%2, vat_tot=%3, Net=%4",
        l_gross USING "<<<,<<<,<<&.&&",
        l_disc_tot USING "<<<,<<<,<<&.&&",
        l_vat_tot USING "<<<,<<<,<<&.&&",
        l_net USING "<<<,<<<,<<&.&&")

END FUNCTION

-- ==============================================================
-- Function : save_order_header_totals (NEW)
-- ==============================================================
FUNCTION save_order_header_totals()

    BEGIN WORK
    TRY
        UPDATE sa31_ord_hdr
            SET gross_tot = m_ord_rec.gross_tot,
                disc_tot = m_ord_rec.disc_tot,
                vat_tot = m_ord_rec.vat_tot,
                net_tot = m_ord_rec.net_tot,
                updated_at = CURRENT
            WHERE id = m_ord_rec.id

        COMMIT WORK

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to update totals: %1", SQLCA.SQLCODE))
    END TRY

END FUNCTION

-- ==============================================================
-- Function : load_customer_details (NEW)
-- ==============================================================
FUNCTION load_customer(p_id INTEGER)

    SELECT * INTO m_debt_rec.* FROM dl01_mast WHERE id = p_id

    IF SQLCA.SQLCODE = 0 THEN
        MESSAGE SFMT("Customer: %1", m_debt_rec.cust_name)
        RETURN m_debt_rec.*
    ELSE
        CALL utils_globals.msg_no_record()
    END IF
    RETURN
END FUNCTION

-- ==============================================================
-- Function : load_order (with status checks)
-- ==============================================================
FUNCTION load_order(p_doc_id INTEGER)
    DEFINE idx INTEGER
    DEFINE user_choice SMALLINT
    DEFINE l_can_edit SMALLINT

    OPTIONS INPUT WRAP

    -- Open window and attach the form
    OPEN WINDOW w_ord WITH FORM "sa131_order" ATTRIBUTES(STYLE = "dialog")

    -- Initialize variables
    INITIALIZE m_ord_rec.* TO NULL
    CALL m_ord_lines_arr.clear()
    CALL m_ord_lines_arr.clear()

    -- ==========================================================
    -- Load header record with customer and user information
    -- ==========================================================
    SELECT * INTO m_ord_rec.* FROM sa31_ord_hdr WHERE id = p_doc_id

    IF SQLCA.SQLCODE = 0 THEN
        -- ===========================================
        -- Check if order can be edited
        -- ===========================================
        LET l_can_edit = can_edit_order(m_ord_rec.id, m_ord_rec.status)

        -- ======================================================
        -- Load order line items (display fields)
        -- ======================================================
        LET idx = 0

        DECLARE ord_lines_cur CURSOR FOR
            SELECT stock_id,
                batch_id,
                qnty,
                unit_price,
                sell_price,
                disc_amt,
                vat_amt,
                line_total
                FROM sa31_ord_det
                WHERE hdr_id = p_doc_id
                ORDER BY line_no

        FOREACH ord_lines_cur INTO m_ord_lines_arr[idx + 1].*
            LET idx = idx + 1
        END FOREACH

        CLOSE ord_lines_cur
        FREE ord_lines_cur

        -- ======================================================
        -- Load full order line items (for database operations)
        -- ======================================================
        LET idx = 0

        DECLARE ord_full_lines_cur CURSOR FOR
            SELECT * FROM sa31_ord_det WHERE hdr_id = p_doc_id ORDER BY line_no

        FOREACH ord_full_lines_cur INTO m_ord_lines_arr[idx + 1].*
            LET idx = idx + 1
        END FOREACH

        CLOSE ord_full_lines_cur
        FREE ord_full_lines_cur

        -- ======================================================
        -- Display header and lines
        -- ======================================================
        CALL utils_globals.set_form_label(
            "lbl_form_title",
            SFMT("Sales Order #%1 - Status: %2",
                m_ord_rec.id, m_ord_rec.status))

        DISPLAY BY NAME m_ord_rec.id,
            m_ord_rec.ref_doc_no,
            m_ord_rec.cust_id,
            m_ord_rec.trans_date,
            m_ord_rec.status,
            m_ord_rec.gross_tot,
            m_ord_rec.disc_tot,
            m_ord_rec.vat_tot,
            m_ord_rec.net_tot

        DISPLAY ARRAY m_ord_lines_arr TO arr_sa_ord_lines.*

            BEFORE DISPLAY
                -- Hide the implicit accept action for view-only
                CALL DIALOG.setActionHidden("accept", TRUE)

                -- Disable edit if invoiced
                IF NOT l_can_edit THEN
                    CALL DIALOG.setActionActive("edit", FALSE)
                    MESSAGE "Order invoiced/completed - cannot edit"
                END IF

                -- --------------------------------------------------
                -- Allow editing via prompt menu
                -- --------------------------------------------------
            ON ACTION edit ATTRIBUTES(TEXT = "Edit Order", IMAGE = "pen")
                IF NOT l_can_edit THEN
                    CALL utils_globals.show_error(
                        "Cannot edit order with status: " || m_ord_rec.status)
                    CONTINUE DISPLAY
                END IF

                LET user_choice = prompt_edit_choice()

                CASE user_choice
                    WHEN 1
                        CALL edit_order_header(p_doc_id)
                        -- Refresh header display
                        DISPLAY BY NAME m_ord_rec.id,
                            m_ord_rec.ref_doc_no,
                            m_ord_rec.cust_id,
                            m_ord_rec.trans_date,
                            m_ord_rec.status,
                            m_ord_rec.gross_tot,
                            m_ord_rec.disc_tot,
                            m_ord_rec.vat_tot,
                            m_ord_rec.net_tot
                    WHEN 2
                        CALL edit_order_lines(p_doc_id)
                    OTHERWISE
                        CALL utils_globals.show_info("Edit cancelled.")
                END CASE

            ON ACTION copy_to_invoice
                ATTRIBUTES(TEXT = "Copy to Invoice", IMAGE = "forward")
                CALL copy_order_to_invoice(p_doc_id)
                -- Reload to show updated status
                EXIT DISPLAY

            ON ACTION view_invoice
                ATTRIBUTES(TEXT = "View Invoice", IMAGE = "info")
                CALL view_linked_invoice(m_ord_rec.id)

            ON ACTION delete ATTRIBUTES(TEXT = "Delete", IMAGE = "delete")
                CALL delete_order(p_doc_id)
                EXIT DISPLAY

                -- --------------------------------------------------
                -- Close action
                -- --------------------------------------------------
            ON ACTION close ATTRIBUTES(TEXT = "Close", IMAGE = "exit")
                EXIT DISPLAY
        END DISPLAY

    ELSE
        CALL utils_globals.show_error("Order not found.")
    END IF

    CLOSE WINDOW w_ord
END FUNCTION

-- ==============================================================
-- Function : can_edit_order (NEW)
-- ==============================================================
FUNCTION can_edit_order(
    p_order_id INTEGER, p_status VARCHAR(10))
    RETURNS SMALLINT

    DEFINE l_invoice_count INTEGER

    -- Check status
    IF p_status = "INVOICED"
        OR p_status = "COMPLETED"
        OR p_status = "CANCELLED" THEN
        RETURN FALSE
    END IF

    -- Check for linked invoices
    SELECT COUNT(*)
        INTO l_invoice_count
        FROM sa32_inv_hdr
        WHERE ref_doc_type = "ORDER"
            AND ref_doc_no
                =
                (SELECT doc_no FROM sa31_ord_hdr WHERE id = p_order_id)

    IF l_invoice_count > 0 THEN
        RETURN FALSE
    END IF

    RETURN TRUE

END FUNCTION

-- ==============================================================
-- Function : copy_order_to_invoice (NEW - CRITICAL FEATURE)
-- ==============================================================
FUNCTION copy_order_to_invoice(p_order_id INTEGER)
    DEFINE l_order_hdr RECORD LIKE sa31_ord_hdr.*
    DEFINE l_invoice_hdr RECORD LIKE sa32_inv_hdr.*
    DEFINE l_new_invoice_id INTEGER
    DEFINE l_new_invoice_doc_no VARCHAR(20)
    DEFINE l_invoice_count INTEGER
    DEFINE l_stock_id INTEGER
    DEFINE l_quantity DECIMAL(15, 2)

    -- ===========================================
    -- 1. Validate order can be converted
    -- ===========================================

    -- Check if already converted
    SELECT COUNT(*)
        INTO l_invoice_count
        FROM sa32_inv_hdr
        WHERE ref_doc_type = "ORDER"
            AND ref_doc_no
                =
                (SELECT doc_no FROM sa31_ord_hdr WHERE id = p_order_id)

    IF l_invoice_count > 0 THEN
        CALL utils_globals.show_error(
            "Order has already been converted to an invoice")
        RETURN
    END IF

    -- Load order
    SELECT * INTO l_order_hdr.* FROM sa31_ord_hdr WHERE id = p_order_id

    IF SQLCA.SQLCODE != 0 THEN
        CALL utils_globals.show_error("Order not found")
        RETURN
    END IF

    -- Check status
    IF l_order_hdr.status = "INVOICED" THEN
        CALL utils_globals.show_error("Order already invoiced")
        RETURN
    END IF

    -- Confirm with user
    IF NOT utils_globals.show_confirm(
        SFMT("Convert Order #%1 to Sales Invoice?", l_order_hdr.id),
        "Confirm Conversion") THEN
        RETURN
    END IF

    -- ===========================================
    -- 2. Create invoice header
    -- ===========================================
    BEGIN WORK
    TRY
        -- Get next invoice number
        SELECT COALESCE(MAX(id), '0') + 1
            INTO l_new_invoice_doc_no
            FROM sa32_inv_hdr

        -- Copy order to invoice
        INITIALIZE l_invoice_hdr.* TO NULL
        LET l_invoice_hdr.id = l_new_invoice_doc_no
        LET l_invoice_hdr.ref_doc_type = "ORDER"
        LET l_invoice_hdr.ref_doc_no = l_order_hdr.id
        LET l_invoice_hdr.cust_id = l_order_hdr.cust_id
        LET l_invoice_hdr.trans_date = TODAY
        LET l_invoice_hdr.trans_date = TODAY
        LET l_invoice_hdr.gross_tot = l_order_hdr.gross_tot
        LET l_invoice_hdr.disc_tot = l_order_hdr.disc_tot
        LET l_invoice_hdr.vat_tot = l_order_hdr.vat_tot
        LET l_invoice_hdr.net_tot = l_order_hdr.net_tot
        LET l_invoice_hdr.status = "NEW"
        LET l_invoice_hdr.created_at = CURRENT
        LET l_invoice_hdr.created_by = utils_globals.get_current_user_id()

        -- Copy customer details
        LET l_invoice_hdr.cust_id = l_order_hdr.cust_id
        LET l_invoice_hdr.cust_name = l_order_hdr.cust_name
        LET l_invoice_hdr.cust_phone = l_order_hdr.cust_phone
        LET l_invoice_hdr.cust_email = l_order_hdr.cust_email
        LET l_invoice_hdr.cust_address1 = l_order_hdr.cust_address1
        LET l_invoice_hdr.cust_address2 = l_order_hdr.cust_address2
        LET l_invoice_hdr.cust_address3 = l_order_hdr.cust_address3
        LET l_invoice_hdr.cust_postal_code = l_order_hdr.cust_postal_code
        LET l_invoice_hdr.cust_vat_no = l_order_hdr.cust_vat_no
        LET l_invoice_hdr.cust_payment_terms = l_order_hdr.cust_payment_terms

        INSERT INTO sa32_inv_hdr VALUES(l_invoice_hdr.*)
        LET l_new_invoice_id = SQLCA.SQLERRD[2]

        -- ===========================================
        -- 3. Copy order lines to invoice
        -- ===========================================
        INSERT INTO sa32_inv_det(
            hdr_id,
            line_no,
            stock_id,
            batch_id,
            qnty,
            unit_price,
            sell_price,
            vat_tot,
            line_tot,
            disc_tot,
            stock_id,
            item_name,
            uom,
            unit_price,
            disc_pct,
            disc_amt,
            gross_amt,
            net_amt,
            vat_rate,
            vat_amt,
            line_total,
            status,
            created_at,
            created_by)
            SELECT l_new_invoice_id,
                line_no,
                stock_id,
                batch_id,
                qnty,
                unit_price,
                sell_price,
                vat_tot,
                line_tot,
                disc_tot,
                stock_id,
                item_name,
                uom,
                unit_price,
                disc_pct,
                disc_amt,
                gross_amt,
                net_amt,
                vat_rate,
                vat_amt,
                line_total,
                status,
                CURRENT,
                m_user
                FROM sa31_ord_det
                WHERE hdr_id = p_order_id

        -- ===========================================
        -- 4. Deduct stock for each line (CRITICAL)
        -- ===========================================
        DECLARE inv_lines_cur CURSOR FOR
            SELECT stock_id, qnty FROM sa31_ord_det WHERE hdr_id = p_order_id

        FOREACH inv_lines_cur INTO l_stock_id, l_quantity
            -- Deduct physical stock
            IF NOT update_stock_on_hand(l_stock_id, l_quantity, "OUT") THEN
                ROLLBACK WORK
                CALL utils_globals.show_error("Failed to update stock levels")
                RETURN
            END IF
        END FOREACH

        CLOSE inv_lines_cur
        FREE inv_lines_cur

        -- ===========================================
        -- 5. Update order status to INVOICED
        -- ===========================================
        UPDATE sa31_ord_hdr
            SET status = "INVOICED", updated_at = CURRENT
            WHERE id = p_order_id

        COMMIT WORK

        CALL utils_globals.show_success(
            SFMT("Order #%1 converted to Invoice #%2 - Stock updated",
                l_order_hdr.id, l_new_invoice_doc_no))

        -- Update module record
        LET m_ord_rec.status = "INVOICED"
        DISPLAY BY NAME m_ord_rec.id,
            m_ord_rec.ref_doc_no,
            m_ord_rec.cust_id,
            m_ord_rec.trans_date,
            m_ord_rec.status,
            m_ord_rec.gross_tot,
            m_ord_rec.disc_tot,
            m_ord_rec.vat_tot,
            m_ord_rec.net_tot

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to convert order: %1", SQLCA.SQLCODE))
    END TRY

END FUNCTION

-- ==============================================================
-- Function : view_linked_invoice (NEW)
-- ==============================================================
FUNCTION view_linked_invoice(p_order_doc_no INTEGER)
    DEFINE l_invoice_id INTEGER
    DEFINE l_invoice_doc_no VARCHAR(20)

    SELECT id, doc_no
        INTO l_invoice_id, l_invoice_doc_no
        FROM sa32_inv_hdr
        WHERE ref_doc_type = "ORDER" AND ref_doc_no = p_order_doc_no

    IF SQLCA.SQLCODE = 0 THEN
        CALL utils_globals.show_info(
            SFMT("This order was converted to Invoice #%1", l_invoice_doc_no))
        -- TODO: Call invoice view function if available
        -- CALL sa132_invoice.load_invoice(l_invoice_id)
    ELSE
        CALL utils_globals.show_info("No linked invoice found")
    END IF

END FUNCTION

-- ==============================================================
-- Function : prompt_edit_choice
-- ==============================================================
PRIVATE FUNCTION prompt_edit_choice() RETURNS SMALLINT
    DEFINE choice SMALLINT

    MENU "Edit Order" ATTRIBUTES(STYLE = "modal")
        COMMAND "Header"
            RETURN 1
        COMMAND "Lines"
            RETURN 2
        COMMAND "Cancel"
            RETURN 0
    END MENU

    RETURN choice

END FUNCTION

-- ==============================================================
-- Function : edit_order_header (UPDATE syntax)
-- ==============================================================
FUNCTION edit_order_header(p_doc_id INTEGER)
    DEFINE new_hdr RECORD LIKE sa31_ord_hdr.*

    LET new_hdr.* = m_ord_rec.*

    DIALOG
        INPUT BY NAME new_hdr.cust_id,
            new_hdr.trans_date,
            new_hdr.ref_doc_type,
            new_hdr.ref_doc_no
            ATTRIBUTES(WITHOUT DEFAULTS)

            AFTER FIELD acc_code
                IF new_hdr.cust_id IS NOT NULL THEN
                    --CALL load_customer_details(
                    --    new_hdr.cust_id)
                    --    RETURNING new_hdr.cust_id,
                    --        new_hdr.cust_name,
                    --        new_hdr.cust_phone,
                    --        new_hdr.cust_email,
                    --        new_hdr.cust_address1,
                    --        new_hdr.cust_address2,
                    --        new_hdr.cust_address3,
                    --        new_hdr.cust_postal_code,
                    --        new_hdr.cust_vat_no,
                    --        new_hdr.cust_payment_terms
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Save", IMAGE = "save")

                BEGIN WORK
                TRY
                    UPDATE sa31_ord_hdr
                        SET trans_date = new_hdr.trans_date,
                            ref_doc_type = new_hdr.ref_doc_type,
                            ref_doc_no = new_hdr.ref_doc_no,
                            cust_id = new_hdr.cust_id,
                            cust_name = new_hdr.cust_name,
                            cust_phone = new_hdr.cust_phone,
                            cust_email = new_hdr.cust_email,
                            cust_address1 = new_hdr.cust_address1,
                            cust_address2 = new_hdr.cust_address2,
                            cust_address3 = new_hdr.cust_address3,
                            cust_postal_code = new_hdr.cust_postal_code,
                            cust_vat_no = new_hdr.cust_vat_no,
                            cust_payment_terms = new_hdr.cust_payment_terms,
                            updated_at = CURRENT
                        WHERE id = p_doc_id

                    LET m_ord_rec.* = new_hdr.*

                    COMMIT WORK
                    CALL utils_globals.show_success("Header updated")
                    EXIT DIALOG

                CATCH
                    ROLLBACK WORK
                    CALL utils_globals.show_error(
                        SFMT("Update failed: %1", SQLCA.SQLCODE))
                END TRY

            ON ACTION cancel
                EXIT DIALOG
        END INPUT

    END DIALOG
END FUNCTION

-- ==============================================================
-- Function : edit_order_lines
-- ==============================================================
FUNCTION edit_order_lines(p_doc_id INTEGER)
    DIALOG
        DISPLAY ARRAY m_ord_lines_arr TO arr_sa_ord_lines.*
            BEFORE DISPLAY
                CALL DIALOG.setActionHidden("accept", TRUE)

            ON ACTION add ATTRIBUTES(TEXT = "Add Line", IMAGE = "new")
                CALL edit_or_add_order_line(p_doc_id, 0, TRUE)
                CALL calculate_order_totals()

            ON ACTION edit ATTRIBUTES(TEXT = "Edit Line", IMAGE = "pen")
                IF arr_curr() > 0 THEN
                    CALL edit_or_add_order_line(p_doc_id, arr_curr(), FALSE)
                    CALL calculate_order_totals()
                END IF

            ON ACTION delete ATTRIBUTES(TEXT = "Delete", IMAGE = "delete")
                IF arr_curr() > 0 THEN
                    CALL delete_order_line(arr_curr())
                    CALL calculate_order_totals()
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Save", IMAGE = "save")
                CALL save_order_lines(p_doc_id)
                CALL save_order_header_totals()
                CALL utils_globals.show_success("Changes saved")
                EXIT DIALOG

            ON ACTION cancel
                EXIT DIALOG
        END DISPLAY
    END DIALOG
END FUNCTION

-- ==============================================================
-- Function : save_order
-- ==============================================================
FUNCTION save_order()
    DEFINE exists INTEGER

    BEGIN WORK
    TRY
        SELECT COUNT(*) INTO exists FROM sa31_ord_hdr WHERE id = m_ord_rec.id

        IF exists = 0 THEN
            INSERT INTO sa31_ord_hdr VALUES m_ord_rec.*
            CALL utils_globals.show_success("Order saved")
        ELSE
            UPDATE sa31_ord_hdr
                SET doc_no = m_ord_rec.id,
                    acc_code = m_ord_rec.cust_id,
                    trans_date = m_ord_rec.trans_date,
                    gross_tot = m_ord_rec.gross_tot,
                    disc_tot = m_ord_rec.disc_tot,
                    vat_tot = m_ord_rec.vat_tot,
                    net_tot = m_ord_rec.net_tot,
                    status = m_ord_rec.status,
                    updated_at = CURRENT
                WHERE id = m_ord_rec.id
            CALL utils_globals.show_success("Order updated")
        END IF

        -- Save lines
        CALL save_order_lines(m_ord_rec.id)

        COMMIT WORK

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(SFMT("Save failed: %1", SQLCA.SQLCODE))
    END TRY

END FUNCTION

-- ==============================================================
-- Function : delete_order
-- ==============================================================
FUNCTION delete_order(p_doc_id INTEGER)
    DEFINE ok SMALLINT
    DEFINE l_status VARCHAR(10)
    DEFINE l_doc_no INTEGER
    DEFINE l_invoice_count INTEGER

    IF p_doc_id IS NULL THEN
        CALL utils_globals.show_info("No order selected for deletion.")
        RETURN
    END IF

    -- ===========================================
    -- Check if order can be deleted
    -- ===========================================

    -- Get order details
    SELECT status, doc_no
        INTO l_status, l_doc_no
        FROM sa31_ord_hdr
        WHERE id = p_doc_id

    -- Check status
    IF l_status = "INVOICED" OR l_status = "COMPLETED" THEN
        CALL utils_globals.show_error(
            "Cannot delete invoiced/completed orders. Status: " || l_status)
        RETURN
    END IF

    -- Check for linked invoices
    SELECT COUNT(*)
        INTO l_invoice_count
        FROM sa32_inv_hdr
        WHERE ref_doc_type = "ORDER" AND ref_doc_no = l_doc_no

    IF l_invoice_count > 0 THEN
        CALL utils_globals.show_error(
            SFMT("Cannot delete order - it has %1 linked invoice(s)",
                l_invoice_count))
        RETURN
    END IF

    -- Confirm deletion
    LET ok =
        utils_globals.show_confirm(
            SFMT("Delete Order #%1?", l_doc_no), "Confirm Delete")

    IF NOT ok THEN
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    -- Delete order
    BEGIN WORK
    TRY
        DELETE FROM sa31_ord_det WHERE hdr_id = p_doc_id
        DELETE FROM sa31_ord_hdr WHERE id = p_doc_id

        COMMIT WORK
        CALL utils_globals.show_success("Order deleted")

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(SFMT("Delete failed: %1", SQLCA.SQLCODE))
    END TRY

END FUNCTION

-- ==============================================================
-- Function : move_record
-- ==============================================================
PRIVATE FUNCTION move_record(dir SMALLINT)
    DEFINE new_idx INTEGER

    IF m_arr_codes.getLength() == 0 THEN
        CALL utils_globals.show_info("No records to navigate.")
        RETURN
    END IF

    LET new_idx = utils_globals.navigate_records(m_arr_codes, m_curr_idx, dir)
    LET m_curr_idx = new_idx
    CALL load_order(m_arr_codes[m_curr_idx])
END FUNCTION
