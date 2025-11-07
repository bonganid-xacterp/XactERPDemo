-- ==============================================================
-- Program   : sa132_invoice.4gl
-- Purpose   : Sales Invoice Program (COMPLETE & CORRECTED)
-- Module    : Sales Invoice (sa)
-- Number    : 132
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Updated   : Added proper workflow, stock deduction, status management
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL st121_st_lkup
IMPORT FGL utils_doc_totals
IMPORT FGL dl121_lkup

SCHEMA demoapp_db

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE invoice_hdr_t RECORD LIKE sa32_inv_hdr.*
TYPE cust_t RECORD LIKE dl01_mast.*

DEFINE m_rec_inv invoice_hdr_t
DEFINE m_cust_rec cust_t

-- display only lines
DEFINE arr_sa_inv_lines DYNAMIC ARRAY OF RECORD
    sa32_inv_det RECORD
        hdr_id     LIKE sa32_inv_det.hdr_id,
        stock_id   LIKE sa32_inv_det.stock_id,
        item_name  LIKE sa32_inv_det.item_name,
        qnty       LIKE sa32_inv_det.qnty,
        unit_cost  LIKE sa32_inv_det.unit_cost,
        sell_price LIKE sa32_inv_det.sell_price,
        disc       LIKE sa32_inv_det.disc,
        line_tot   LIKE sa32_inv_det.line_tot
    END RECORD
END RECORD

-- Full detail records for database operations
DEFINE m_arr_inv_lines DYNAMIC ARRAY OF RECORD LIKE sa32_inv_det.*

DEFINE m_arr_codes DYNAMIC ARRAY OF STRING
DEFINE m_curr_idx INTEGER
DEFINE m_is_edit SMALLINT

-- ==============================================================
-- Function : new_invoice (NEW - Header first, then lines)
-- Purpose  : Create new invoice with proper workflow
-- ==============================================================
FUNCTION new_invoice()
    DEFINE l_hdr RECORD LIKE sa32_inv_hdr.*
    DEFINE l_next_doc_no VARCHAR(20)
    DEFINE l_new_hdr_id INTEGER

    -- ==========================================================
    -- 1. Generate next document number
    -- ==========================================================
    SELECT COALESCE(MAX(doc_no), '0') + 1 INTO l_next_doc_no FROM sa32_inv_hdr

    -- ==========================================================
    -- 2. Initialize header
    -- ==========================================================
    INITIALIZE l_hdr.* TO NULL
    LET l_hdr.doc_no = l_next_doc_no
    LET l_hdr.trans_date = TODAY
    LET l_hdr.due_date = TODAY + 30  -- 30 days default
    LET l_hdr.status = "DRAFT"
    LET l_hdr.created_at = CURRENT
    LET l_hdr.created_by = utils_globals.get_current_user_id()
    LET l_hdr.gross_tot = 0
    LET l_hdr.vat = 0
    LET l_hdr.disc = 0
    LET l_hdr.net_tot = 0

    -- ==========================================================
    -- 3. Input Header Details
    -- ==========================================================
    OPEN WINDOW w_invoice_hdr WITH FORM "sa132_invoice" ATTRIBUTES(STYLE="dialog")

    CALL utils_globals.set_form_label("lbl_form_title", "New Sales Invoice - Header")

    INPUT BY NAME l_hdr.cust_id, l_hdr.trans_date, 
                  l_hdr.due_date, l_hdr.ref_doc_type, l_hdr.ref_doc_no
        ATTRIBUTES(WITHOUT DEFAULTS, UNBUFFERED)

        BEFORE INPUT
            DISPLAY BY NAME l_hdr.doc_no, l_hdr.status, l_hdr.trans_date,
                            l_hdr.due_date
            MESSAGE SFMT("Enter invoice header details for Invoice #%1", l_next_doc_no)

        AFTER FIELD cust_id
            IF l_hdr.cust_id IS NOT NULL THEN
                CALL load_customer_details(l_hdr.cust_id)
                    RETURNING l_hdr.cust_id, l_hdr.cust_name,
                              l_hdr.cust_phone, l_hdr.cust_email, l_hdr.cust_address1,
                              l_hdr.cust_address2, l_hdr.cust_address3,
                              l_hdr.cust_postal_code, l_hdr.cust_vat_no,
                              l_hdr.cust_payment_terms

                IF l_hdr.cust_id IS NULL THEN
                    CALL utils_globals.show_error("Customer not found")
                    NEXT FIELD cust_id
                END IF
            END IF

        ON ACTION lookup_customer ATTRIBUTES(TEXT="Customer Lookup", IMAGE="zoom")
            CALL dl121_lkup.load_lookup_form_with_search() RETURNING l_hdr.cust_id
            IF l_hdr.cust_id IS NOT NULL THEN
                CALL load_customer_details(l_hdr.cust_id)
                    RETURNING l_hdr.cust_id, l_hdr.cust_name,
                              l_hdr.cust_phone, l_hdr.cust_email, l_hdr.cust_address1,
                              l_hdr.cust_address2, l_hdr.cust_address3,
                              l_hdr.cust_postal_code, l_hdr.cust_vat_no,
                              l_hdr.cust_payment_terms
                DISPLAY BY NAME l_hdr.cust_id
            END IF

        ON ACTION accept ATTRIBUTES(TEXT="Save Header", IMAGE="save")
            -- Validate header
            IF l_hdr.cust_id IS NULL THEN
                CALL utils_globals.show_error("Customer is required")
                NEXT FIELD cust_id
            END IF

            IF l_hdr.trans_date IS NULL THEN
                LET l_hdr.trans_date = TODAY
            END IF

            ACCEPT INPUT

        ON ACTION cancel ATTRIBUTES(TEXT="Cancel", IMAGE="exit")
            CALL utils_globals.show_info("Invoice creation cancelled.")
            CLOSE WINDOW w_invoice_hdr
            RETURN
    END INPUT

    -- Check if cancelled
    IF INT_FLAG THEN
        LET INT_FLAG = FALSE
        CLOSE WINDOW w_invoice_hdr
        RETURN
    END IF

    -- ==========================================================
    -- 4. Save Header to Database (CRITICAL STEP)
    -- ==========================================================
    BEGIN WORK
    TRY
        INSERT INTO sa32_inv_hdr VALUES(l_hdr.*)

        -- Get the generated header ID
        LET l_new_hdr_id = SQLCA.SQLERRD[2]
        LET l_hdr.id = l_new_hdr_id

        COMMIT WORK

        CALL utils_globals.show_success(
            SFMT("Invoice header #%1 saved. ID=%2. Now add invoice lines.",
                 l_next_doc_no, l_new_hdr_id))

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to save invoice header: %1", SQLCA.SQLCODE))
        CLOSE WINDOW w_invoice_hdr
        RETURN
    END TRY

    CLOSE WINDOW w_invoice_hdr

    -- ==========================================================
    -- 5. Now add lines (header ID exists)
    -- ==========================================================
    LET m_rec_inv.* = l_hdr.*
    CALL m_arr_inv_lines.clear()

    CALL input_invoice_lines(l_new_hdr_id)

    -- ==========================================================
    -- 6. Load the complete invoice for viewing
    -- ==========================================================
    CALL load_invoice(l_new_hdr_id)

END FUNCTION

-- ==============================================================
-- Function : input_invoice_lines (NEW)
-- Purpose  : Add/edit lines for a saved invoice
-- ==============================================================
FUNCTION input_invoice_lines(p_hdr_id INTEGER)

    OPEN WINDOW w_invoice_lines WITH FORM "sa132_invoice" ATTRIBUTES(STYLE="dialog")

    CALL utils_globals.set_form_label("lbl_form_title",
        SFMT("Invoice #%1 - Add Lines", m_rec_inv.doc_no))

    DISPLAY BY NAME m_rec_inv.*

    DIALOG ATTRIBUTES(UNBUFFERED)

        DISPLAY ARRAY m_arr_inv_lines TO arr_sa_inv_lines.*
            BEFORE DISPLAY
                CALL DIALOG.setActionHidden("accept", TRUE)

            ON ACTION add ATTRIBUTES(TEXT="Add Line", IMAGE="new")
                CALL edit_or_add_invoice_line(p_hdr_id, 0, TRUE)
                CALL calculate_invoice_totals()

            ON ACTION edit ATTRIBUTES(TEXT="Edit Line", IMAGE="pen")
                IF arr_curr() > 0 THEN
                    CALL edit_or_add_invoice_line(p_hdr_id, arr_curr(), FALSE)
                    CALL calculate_invoice_totals()
                END IF

            ON ACTION delete ATTRIBUTES(TEXT="Delete Line", IMAGE="delete")
                IF arr_curr() > 0 THEN
                    CALL delete_invoice_line(p_hdr_id, arr_curr())
                    CALL calculate_invoice_totals()
                END IF

            ON ACTION save ATTRIBUTES(TEXT="Save Lines", IMAGE="save")
                CALL save_invoice_lines(p_hdr_id)
                CALL save_invoice_header_totals()
                CALL utils_globals.show_success("Invoice lines saved successfully.")
                EXIT DIALOG

            ON ACTION close ATTRIBUTES(TEXT="Close", IMAGE="exit")
                IF m_arr_inv_lines.getLength() > 0 THEN
                    IF utils_globals.show_confirm(
                        "Save lines before closing?", "Confirm") THEN
                        CALL save_invoice_lines(p_hdr_id)
                        CALL save_invoice_header_totals()
                    END IF
                END IF
                EXIT DIALOG
        END DISPLAY

    END DIALOG

    CLOSE WINDOW w_invoice_lines

END FUNCTION

-- ==============================================================
-- Function : edit_or_add_invoice_line (NEW)
-- ==============================================================
FUNCTION edit_or_add_invoice_line(p_doc_id INTEGER, p_row INTEGER, p_is_new SMALLINT)
    DEFINE l_line RECORD LIKE sa32_inv_det.*
    DEFINE l_stock_id INTEGER
    DEFINE l_item_desc VARCHAR(150)

    -- Initialize new line
    IF p_is_new THEN
        INITIALIZE l_line.* TO NULL
        LET l_line.hdr_id = p_doc_id
        LET l_line.line_no = m_arr_inv_lines.getLength() + 1
        LET l_line.vat_rate = 15.00
        LET l_line.disc_pct = 0
        LET l_line.status = 1
        LET l_line.created_at = CURRENT
        LET l_line.created_by = utils_globals.get_current_user_id()
    ELSE
        -- Load from existing array line
        -- TODO : fix this to add the new line array
        -- LET l_line.* = m_arr_inv_lines[p_row].*
    END IF

    -- ==============================
    -- Input Dialog for editing/adding
    -- ==============================
    OPEN WINDOW w_line_edit WITH FORM "sa132_invoice_line" ATTRIBUTES(STYLE="dialog")

    INPUT BY NAME l_line.stock_id, l_line.qnty, l_line.unit_price,
                  l_line.disc_pct, l_line.vat_rate
        ATTRIBUTES(WITHOUT DEFAULTS, UNBUFFERED)

        BEFORE INPUT
            DISPLAY BY NAME l_line.*

        BEFORE FIELD stock_id
            -- Stock lookup popup
            CALL st121_st_lkup.display_stocklist() RETURNING l_stock_id

            IF l_stock_id IS NOT NULL AND l_stock_id > 0 THEN
                LET l_line.stock_id = l_stock_id
                LET l_line.stock_id = l_stock_id

                -- Load stock defaults
                CALL load_stock_defaults(l_stock_id)
                    RETURNING l_line.unit_cost, l_line.unit_price, l_item_desc

                LET l_line.sell_price = l_line.unit_price
                LET l_line.item_name = l_item_desc

                DISPLAY BY NAME l_line.stock_id, l_line.unit_cost,
                                l_line.unit_price, l_line.item_name

                NEXT FIELD qnty
            END IF

        AFTER FIELD qnty
            IF l_line.qnty IS NOT NULL AND l_line.qnty > 0 THEN
                CALL calculate_line_totals(l_line.qnty, l_line.unit_price,
                                          l_line.disc_pct, l_line.vat_rate)
                    RETURNING l_line.gross_amt, l_line.disc_amt,
                              l_line.net_amt, l_line.vat_amt, l_line.line_total

                DISPLAY BY NAME l_line.gross_amt, l_line.disc_amt,
                                l_line.net_amt, l_line.vat_amt, l_line.line_total
            END IF

        AFTER FIELD unit_price, disc_pct, vat_rate
            IF l_line.qnty IS NOT NULL THEN
                CALL calculate_line_totals(l_line.qnty, l_line.unit_price,
                                          l_line.disc_pct, l_line.vat_rate)
                    RETURNING l_line.gross_amt, l_line.disc_amt,
                              l_line.net_amt, l_line.vat_amt, l_line.line_total

                DISPLAY BY NAME l_line.gross_amt, l_line.disc_amt,
                                l_line.net_amt, l_line.vat_amt, l_line.line_total
            END IF

        ON ACTION accept ATTRIBUTES(TEXT="Save Line", IMAGE="save")
            -- Validate
            IF l_line.stock_id IS NULL OR l_line.stock_id = 0 THEN
                CALL utils_globals.show_error("Stock item is required")
                NEXT FIELD stock_id
            END IF

            IF l_line.qnty IS NULL OR l_line.qnty <= 0 THEN
                CALL utils_globals.show_error("Quantity must be greater than 0")
                NEXT FIELD qnty
            END IF

            -- Save to array
            IF p_is_new THEN
                LET m_arr_inv_lines[m_arr_inv_lines.getLength() + 1].* = l_line.*
            ELSE
                LET m_arr_inv_lines[p_row].* = l_line.*
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
PRIVATE FUNCTION calculate_line_totals(p_qnty DECIMAL, p_price DECIMAL,
                               p_disc_pct DECIMAL, p_vat_rate DECIMAL)
    RETURNS (DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL)

    DEFINE l_gross, l_disc, l_net, l_vat, l_total DECIMAL(15,2)

    -- Gross = Quantity × Price
    LET l_gross = p_qnty * p_price

    -- Discount = Gross × (Disc% / 100)
    LET l_disc = l_gross * (p_disc_pct / 100)

    -- Net = Gross - Discount
    LET l_net = l_gross - l_disc

    -- VAT = Net × (VAT% / 100)
    LET l_vat = l_net * (p_vat_rate / 100)

    -- Total = Net + VAT
    LET l_total = l_net + l_vat

    RETURN l_gross, l_disc, l_net, l_vat, l_total

END FUNCTION

-- ==============================================================
-- Function : load_stock_defaults
-- ==============================================================
PRIVATE FUNCTION load_stock_defaults(p_stock_id INTEGER)
    RETURNS (DECIMAL, DECIMAL, VARCHAR(150))

    DEFINE l_cost DECIMAL(15,2)
    DEFINE l_price DECIMAL(15,2)
    DEFINE l_desc VARCHAR(150)
    DEFINE l_stock_on_hand DECIMAL(15,2)

    SELECT unit_cost, sell_price, description, stock_on_hand
        INTO l_cost, l_price, l_desc, l_stock_on_hand
        FROM st01_mast
        WHERE stock_id = p_stock_id

    IF SQLCA.SQLCODE != 0 THEN
        LET l_cost = 0
        LET l_price = 0
        LET l_desc = "Unknown Item"
    ELSE
        -- Display stock info to user
        MESSAGE SFMT("Stock: %1 | On Hand: %2",
                     l_desc,
                     l_stock_on_hand USING "<<<,<<<,<<&.&&")
    END IF

    RETURN l_cost, l_price, l_desc

END FUNCTION

-- ==============================================================
-- Function : delete_invoice_line (CORRECTED)
-- ==============================================================
FUNCTION delete_invoice_line(p_doc_id INTEGER, p_row INTEGER)
    IF p_row > 0 THEN
        IF utils_globals.show_confirm(
            SFMT("Delete line %1?", p_row), "Confirm Delete") THEN
            CALL m_arr_inv_lines.deleteElement(p_row)
            CALL utils_globals.show_success("Line deleted")
        END IF
    END IF
END FUNCTION

-- ==============================================================
-- Function : save_invoice_lines (CORRECTED)
-- ==============================================================
FUNCTION save_invoice_lines(p_doc_id INTEGER)
    DEFINE i INTEGER

    BEGIN WORK
    TRY
        DELETE FROM sa32_inv_det WHERE hdr_id = p_doc_id

        FOR i = 1 TO m_arr_inv_lines.getLength()
            -- Ensure hdr_id is set
            LET m_arr_inv_lines[i].hdr_id = p_doc_id
            INSERT INTO sa32_inv_det VALUES m_arr_inv_lines[i].*
        END FOR

        COMMIT WORK

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to save lines: %1", SQLCA.SQLCODE))
    END TRY

END FUNCTION

-- ==============================================================
-- Function : calculate_invoice_totals (NEW)
-- ==============================================================
FUNCTION calculate_invoice_totals()
    DEFINE i INTEGER
    DEFINE l_gross, l_disc_tot, l_vat_tot, l_net DECIMAL(15,2)

    LET l_gross = 0
    LET l_disc_tot = 0
    LET l_vat_tot = 0

    FOR i = 1 TO m_arr_inv_lines.getLength()
        LET l_gross = l_gross + NVL(m_arr_inv_lines[i].gross_amt, 0)
        LET l_disc_tot = l_disc_tot + NVL(m_arr_inv_lines[i].disc_amt, 0)
        LET l_vat_tot = l_vat_tot + NVL(m_arr_inv_lines[i].vat_amt, 0)
    END FOR

    LET l_net = l_gross - l_disc_tot + l_vat_tot

    LET m_rec_inv.gross_tot = l_gross
    LET m_rec_inv.disc = l_disc_tot
    LET m_rec_inv.vat = l_vat_tot
    LET m_rec_inv.net_tot = l_net

    DISPLAY BY NAME m_rec_inv.gross_tot, m_rec_inv.disc,
                     m_rec_inv.vat, m_rec_inv.net_tot

    MESSAGE SFMT("Totals: Gross=%1, Disc=%2, VAT=%3, Net=%4",
                 l_gross USING "<<<,<<<,<<&.&&",
                 l_disc_tot USING "<<<,<<<,<<&.&&",
                 l_vat_tot USING "<<<,<<<,<<&.&&",
                 l_net USING "<<<,<<<,<<&.&&")

END FUNCTION

-- ==============================================================
-- Function : save_invoice_header_totals (NEW)
-- ==============================================================
FUNCTION save_invoice_header_totals()

    BEGIN WORK
    TRY
        UPDATE sa32_inv_hdr
            SET gross_tot = m_rec_inv.gross_tot,
                disc = m_rec_inv.disc,
                vat = m_rec_inv.vat,
                net_tot = m_rec_inv.net_tot,
                updated_at = CURRENT
            WHERE id = m_rec_inv.id

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
PRIVATE FUNCTION load_customer_details(p_cust_id INTEGER)
    RETURNS (INTEGER, VARCHAR(100), VARCHAR(20), VARCHAR(100),
             VARCHAR(100), VARCHAR(100), VARCHAR(100), VARCHAR(10),
             VARCHAR(20), VARCHAR(50))

    DEFINE l_cust_id INTEGER
    DEFINE l_cust_name VARCHAR(100)
    DEFINE l_phone VARCHAR(20)
    DEFINE l_email VARCHAR(100)
    DEFINE l_addr1 VARCHAR(100)
    DEFINE l_addr2 VARCHAR(100)
    DEFINE l_addr3 VARCHAR(100)
    DEFINE l_postal VARCHAR(10)
    DEFINE l_vat VARCHAR(20)
    DEFINE l_terms VARCHAR(50)

    SELECT id, cust_name, cust_id, phone, email,
           address1, address2, address3, postal_code,
           vat_no, payment_terms
        INTO l_cust_id, l_cust_name,l_phone, l_email,
             l_addr1, l_addr2, l_addr3, l_postal, l_vat, l_terms
        FROM dl01_mast
        WHERE cust_id = p_cust_id

    IF SQLCA.SQLCODE = 0 THEN
        MESSAGE SFMT("Customer: %1", l_cust_name)
        RETURN l_cust_id, l_cust_name, l_phone, l_email,
               l_addr1, l_addr2, l_addr3, l_postal, l_vat, l_terms
    ELSE
        RETURN NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
    END IF

END FUNCTION

-- ==============================================================
-- Function : load_invoice (CORRECTED with status checks)
-- ==============================================================
FUNCTION load_invoice(p_doc_id INTEGER)
    DEFINE idx INTEGER
    DEFINE user_choice SMALLINT
    DEFINE l_can_edit SMALLINT

    OPTIONS INPUT WRAP

    -- Open window and attach the form
    OPEN WINDOW w_inv WITH FORM "sa132_invoice" ATTRIBUTES(STYLE = "dialog")

    -- Initialize variables
    INITIALIZE m_rec_inv.* TO NULL
    CALL m_arr_inv_lines.clear()

    -- ==========================================================
    -- Load header record
    -- ==========================================================
    SELECT * INTO m_rec_inv.*
      FROM sa32_inv_hdr
     WHERE id = p_doc_id

    IF SQLCA.SQLCODE = 0 THEN
        -- ===========================================
        -- Check if invoice can be edited
        -- ===========================================
        LET l_can_edit = can_edit_invoice(m_rec_inv.id, m_rec_inv.status)

        -- ======================================================
        -- Load invoice line items (CORRECTED)
        -- ======================================================
        LET idx = 0

        DECLARE inv_lines_cur CURSOR FOR
            SELECT *
              FROM sa32_inv_det
             WHERE hdr_id = p_doc_id
             ORDER BY line_no

        FOREACH inv_lines_cur INTO m_arr_inv_lines[idx + 1].*
            LET idx = idx + 1
        END FOREACH

        CLOSE inv_lines_cur
        FREE inv_lines_cur

        -- ======================================================
        -- Display header and lines
        -- ======================================================
        CALL utils_globals.set_form_label("lbl_form_title",
            SFMT("Sales Invoice #%1 - Status: %2", m_rec_inv.doc_no, m_rec_inv.status))

        DISPLAY BY NAME m_rec_inv.*

        -- DISPLAY ARRAY m_arr_inv_lines TO arr_sa_inv_lines.*
        DISPLAY ARRAY m_arr_inv_lines TO arr_sa_inv_lines.*

            BEFORE DISPLAY
                CALL DIALOG.setActionHidden("accept", TRUE)

                -- Disable edit if posted
                IF NOT l_can_edit THEN
                    CALL DIALOG.setActionActive("edit", FALSE)
                    MESSAGE "Invoice posted - cannot edit"
                END IF

            ON ACTION edit ATTRIBUTES(TEXT = "Edit Invoice", IMAGE = "pen")
                IF NOT l_can_edit THEN
                    CALL utils_globals.show_error(
                        "Cannot edit invoice with status: " || m_rec_inv.status)
                    CONTINUE DISPLAY
                END IF

                LET user_choice = prompt_edit_choice()

                CASE user_choice
                    WHEN 1
                        CALL edit_invoice_header(p_doc_id)
                        DISPLAY BY NAME m_rec_inv.* -- Refresh header
                    WHEN 2
                        CALL edit_invoice_lines(p_doc_id)
                    OTHERWISE
                        CALL utils_globals.show_info("Edit cancelled.")
                END CASE

            ON ACTION post ATTRIBUTES(TEXT="Post Invoice", IMAGE="ok")
                CALL post_invoice(p_doc_id)
                -- Reload to show updated status
                EXIT DISPLAY

            ON ACTION delete ATTRIBUTES(TEXT="Delete", IMAGE="delete")
                CALL delete_invoice(p_doc_id)
                EXIT DISPLAY

            ON ACTION close ATTRIBUTES(TEXT = "Close", IMAGE = "exit")
                EXIT DISPLAY
        END DISPLAY

    ELSE
        CALL utils_globals.show_error("Invoice not found.")
    END IF

    CLOSE WINDOW w_inv
END FUNCTION

-- ==============================================================
-- Function : can_edit_invoice (NEW)
-- ==============================================================
FUNCTION can_edit_invoice(p_invoice_id INTEGER, p_status VARCHAR(10))
    RETURNS SMALLINT

    -- Check status
    IF p_status = "POSTED" OR p_status = "PAID" OR p_status = "CANCELLED" THEN
        RETURN FALSE
    END IF

    RETURN TRUE

END FUNCTION

-- ==============================================================
-- Function : post_invoice (NEW - CRITICAL)
-- Purpose  : Post invoice and deduct stock
-- ==============================================================
FUNCTION post_invoice(p_invoice_id INTEGER)
    DEFINE l_invoice_hdr RECORD LIKE sa32_inv_hdr.*
    DEFINE l_stock_id INTEGER
    DEFINE l_quantity DECIMAL(15,2)

    -- Load invoice
    SELECT * INTO l_invoice_hdr.*
      FROM sa32_inv_hdr
     WHERE id = p_invoice_id

    IF SQLCA.SQLCODE != 0 THEN
        CALL utils_globals.show_error("Invoice not found")
        RETURN
    END IF

    -- Check status
    IF l_invoice_hdr.status = "POSTED" OR l_invoice_hdr.status = "PAID" THEN
        CALL utils_globals.show_error("Invoice already posted")
        RETURN
    END IF

    -- Confirm with user
    IF NOT utils_globals.show_confirm(
        SFMT("Post Invoice #%1?\nThis will deduct stock and lock the invoice.", l_invoice_hdr.doc_no),
        "Confirm Post") THEN
        RETURN
    END IF

    -- ===========================================
    -- Post invoice and deduct stock
    -- ===========================================
    BEGIN WORK
    TRY
        -- Deduct stock for each line (CRITICAL)
        DECLARE post_inv_lines_cur CURSOR FOR
            SELECT stock_id, qnty
              FROM sa32_inv_det
             WHERE hdr_id = p_invoice_id

        FOREACH post_inv_lines_cur INTO l_stock_id, l_quantity
            -- Deduct physical stock
            IF NOT update_stock_on_hand(l_stock_id, l_quantity, "OUT") THEN
                ROLLBACK WORK
                CALL utils_globals.show_error("Failed to update stock levels")
                RETURN
            END IF
        END FOREACH

        CLOSE post_inv_lines_cur
        FREE post_inv_lines_cur

        -- Update invoice status to POSTED
        UPDATE sa32_inv_hdr
            SET status = "POSTED",
                updated_at = CURRENT
            WHERE id = p_invoice_id

        COMMIT WORK

        CALL utils_globals.show_success(
            SFMT("Invoice #%1 posted successfully - Stock updated",
                 l_invoice_hdr.doc_no))

        -- Update module record
        LET m_rec_inv.status = "POSTED"
        DISPLAY BY NAME m_rec_inv.status

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to post invoice: %1", SQLCA.SQLCODE))
    END TRY

END FUNCTION

-- ==============================================================
-- Function : update_stock_on_hand (REUSED FROM ORDER)
-- Purpose  : Update physical stock when invoice is posted
-- ==============================================================
PRIVATE FUNCTION update_stock_on_hand(p_stock_id INTEGER, p_quantity DECIMAL,
                              p_direction VARCHAR(3))
    RETURNS SMALLINT

    DEFINE l_current_stock DECIMAL(15,2)

    BEGIN WORK

    TRY
        -- Lock the stock record
        SELECT stock_on_hand INTO l_current_stock
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

        ELSE IF p_direction = "IN" THEN
            -- Purchase/Return - increase stock
            UPDATE st01_mast
               SET stock_on_hand = stock_on_hand + p_quantity,
                   total_purch = total_purch + p_quantity,
                   updated_at = CURRENT
             WHERE stock_id = p_stock_id
        END IF
        END IF

        -- Record stock transaction
        INSERT INTO st30_trans (
            stock_id, trans_date, doc_type, direction, qnty,
            created_at, created_by
        ) VALUES (
            p_stock_id, TODAY, 'INVOICE', p_direction, p_quantity,
            CURRENT, l_user
        )

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
-- Function : prompt_edit_choice
-- ==============================================================
PRIVATE FUNCTION prompt_edit_choice() RETURNS SMALLINT
    DEFINE choice SMALLINT

    MENU "Edit Invoice" ATTRIBUTES (STYLE ="modal")
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
-- Function : edit_invoice_header (CORRECTED UPDATE syntax)
-- ==============================================================
FUNCTION edit_invoice_header(p_doc_id INTEGER)
    DEFINE new_hdr RECORD LIKE sa32_inv_hdr.*

    LET new_hdr.* = m_rec_inv.*

    DIALOG
        INPUT BY NAME new_hdr.cust_id, new_hdr.trans_date,
                      new_hdr.due_date,
                      new_hdr.ref_doc_type, new_hdr.ref_doc_no
            ATTRIBUTES(WITHOUT DEFAULTS)

            AFTER FIELD cust_id
                IF new_hdr.cust_id IS NOT NULL THEN
                    CALL load_customer_details(new_hdr.cust_id)
                        RETURNING new_hdr.cust_id, new_hdr.cust_name,
                                  new_hdr.cust_phone, new_hdr.cust_email,
                                  new_hdr.cust_address1,
                                  new_hdr.cust_address2, new_hdr.cust_address3,
                                  new_hdr.cust_postal_code, new_hdr.cust_vat_no,
                                  new_hdr.cust_payment_terms
                END IF

            ON ACTION save ATTRIBUTES(TEXT="Save", IMAGE="save")

                BEGIN WORK
                TRY
                    UPDATE sa32_inv_hdr
                        SET
                            trans_date = new_hdr.trans_date,
                            due_date = new_hdr.due_date,
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

                    LET m_rec_inv.* = new_hdr.*

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
-- Function : edit_invoice_lines (NEW)
-- ==============================================================
FUNCTION edit_invoice_lines(p_doc_id INTEGER)
    DIALOG
        DISPLAY ARRAY m_arr_inv_lines TO arr_sa_inv_lines.*
            BEFORE DISPLAY
                CALL DIALOG.setActionHidden("accept", TRUE)

            ON ACTION add ATTRIBUTES(TEXT = "Add Line", IMAGE = "new")
                CALL edit_or_add_invoice_line(p_doc_id, 0, TRUE)
                CALL calculate_invoice_totals()

            ON ACTION edit ATTRIBUTES(TEXT = "Edit Line", IMAGE = "pen")
                IF arr_curr() > 0 THEN
                    CALL edit_or_add_invoice_line(p_doc_id, arr_curr(), FALSE)
                    CALL calculate_invoice_totals()
                END IF

            ON ACTION delete ATTRIBUTES(TEXT = "Delete", IMAGE = "delete")
                IF arr_curr() > 0 THEN
                    CALL delete_invoice_line(p_doc_id, arr_curr())
                    CALL calculate_invoice_totals()
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Save", IMAGE = "save")
                CALL save_invoice_lines(p_doc_id)
                CALL save_invoice_header_totals()
                CALL utils_globals.show_success("Changes saved")
                EXIT DIALOG

            ON ACTION cancel
                EXIT DIALOG
        END DISPLAY
    END DIALOG
END FUNCTION

-- ==============================================================
-- Function : save_invoice (Legacy - CORRECTED)
-- ==============================================================
FUNCTION save_invoice()
    DEFINE exists INTEGER

    BEGIN WORK
    TRY
        SELECT COUNT(*) INTO exists FROM sa32_inv_hdr WHERE id = m_rec_inv.id

        IF exists = 0 THEN
            INSERT INTO sa32_inv_hdr VALUES m_rec_inv.*
            CALL utils_globals.show_success("Invoice saved")
        ELSE
            UPDATE sa32_inv_hdr
                SET doc_no = m_rec_inv.doc_no,
                    cust_id = m_rec_inv.cust_id,
                    trans_date = m_rec_inv.trans_date,
                    due_date = m_rec_inv.due_date,
                    gross_tot = m_rec_inv.gross_tot,
                    disc = m_rec_inv.disc,
                    vat = m_rec_inv.vat,
                    net_tot = m_rec_inv.net_tot,
                    status = m_rec_inv.status,
                    updated_at = CURRENT
                WHERE id = m_rec_inv.id
            CALL utils_globals.show_success("Invoice updated")
        END IF

        -- Save lines
        CALL save_invoice_lines(m_rec_inv.id)

        COMMIT WORK

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Save failed: %1", SQLCA.SQLCODE))
    END TRY

END FUNCTION

-- ==============================================================
-- Function : delete_invoice (CORRECTED with protections)
-- ==============================================================
FUNCTION delete_invoice(p_doc_id INTEGER)
    DEFINE ok SMALLINT
    DEFINE l_status VARCHAR(10)
    DEFINE l_doc_no VARCHAR(20)

    IF p_doc_id IS NULL THEN
        CALL utils_globals.show_info("No invoice selected for deletion.")
        RETURN
    END IF

    -- ===========================================
    -- Check if invoice can be deleted
    -- ===========================================

    -- Get invoice details
    SELECT status, doc_no INTO l_status, l_doc_no
      FROM sa32_inv_hdr
     WHERE id = p_doc_id

    -- Check status
    IF l_status = "POSTED" OR l_status = "PAID" THEN
        CALL utils_globals.show_error(
            "Cannot delete posted/paid invoices. Status: " || l_status)
        RETURN
    END IF

    -- Confirm deletion
    LET ok = utils_globals.show_confirm(
        SFMT("Delete Invoice #%1?", l_doc_no), "Confirm Delete")

    IF NOT ok THEN
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    -- Delete invoice
    BEGIN WORK
    TRY
        DELETE FROM sa32_inv_det WHERE hdr_id = p_doc_id
        DELETE FROM sa32_inv_hdr WHERE id = p_doc_id

        COMMIT WORK
        CALL utils_globals.show_success("Invoice deleted")

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Delete failed: %1", SQLCA.SQLCODE))
    END TRY

END FUNCTION

-- ==============================================================
-- Function : move_record (Navigation support)
-- ==============================================================
PRIVATE FUNCTION move_record(dir SMALLINT)
    DEFINE new_idx INTEGER

    IF m_arr_codes.getLength() == 0 THEN
        CALL utils_globals.show_info("No records to navigate.")
        RETURN
    END IF

    LET new_idx = utils_globals.navigate_records(m_arr_codes, m_curr_idx, dir)
    LET m_curr_idx = new_idx
    CALL load_invoice(m_arr_codes[m_curr_idx])
END FUNCTION

-- ==============================================================
-- Legacy Function : show_invoice (for compatibility)
-- ==============================================================
PUBLIC FUNCTION show_invoice(p_doc_id INTEGER)
    CALL load_invoice(p_doc_id)
END FUNCTION
