-- ==============================================================
-- Program   : sa133_crn.4gl
-- Purpose   : Sales Credit Note Program
-- Module    : Sales Credit Note (sa)
-- Number    : 133
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Updated   : Complete rewrite with invoice copy, stock, balance, journal updates
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL st121_st_lkup
IMPORT FGL utils_doc_totals
IMPORT FGL dl121_lkup
IMPORT FGL utils_global_stock_updater
IMPORT FGL utils_global_journal_updater

SCHEMA demoappdb

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE crn_hdr_t RECORD LIKE sa33_crn_hdr.*
DEFINE m_crn_hdr_rec crn_hdr_t
DEFINE m_crn_lines_arr DYNAMIC ARRAY OF RECORD LIKE sa33_crn_det.*

DEFINE m_cust_rec RECORD LIKE dl01_mast.*
DEFINE m_arr_codes DYNAMIC ARRAY OF STRING
DEFINE m_curr_idx INTEGER

-- ==============================================================
-- Init Program
-- ==============================================================
FUNCTION init_crn_module()
    INITIALIZE m_cust_rec.* TO NULL

    MENU "Credit Note Menu"
        ON ACTION find 
            CALL find_invoice_for_crn()

        ON ACTION New 
            CALL new_crn_standalone()

        ON ACTION  edit
            CALL view_credit_note()

        ON ACTION Delete 
            CALL delete_credit_note()

        ON ACTION Exit
            EXIT MENU
    END MENU
END FUNCTION

-- ==============================================================
-- Find Invoice and Create Credit Note
-- ==============================================================
FUNCTION find_invoice_for_crn()
    DEFINE l_invoice_id INTEGER
    DEFINE l_inv_doc_no VARCHAR(20)

    -- Search for invoice
    PROMPT "Enter Invoice ID:" FOR l_inv_doc_no

    IF INT_FLAG THEN
        LET INT_FLAG = FALSE
        RETURN
    END IF

    -- Validate invoice exists
    SELECT id INTO l_invoice_id
      FROM sa32_inv_hdr
     WHERE doc_no = l_inv_doc_no
       AND status = "POSTED"

    IF SQLCA.SQLCODE != 0 THEN
        CALL utils_globals.show_error("Invoice not found or not posted")
        RETURN
    END IF

    -- Create credit note from invoice
    CALL create_crn_from_invoice(l_invoice_id)

END FUNCTION

-- ==============================================================
-- Create Credit Note from Invoice
-- ==============================================================
FUNCTION create_crn_from_invoice(p_invoice_id INTEGER)
    DEFINE l_invoice_hdr RECORD LIKE sa32_inv_hdr.*
    DEFINE l_crn_hdr RECORD LIKE sa33_crn_hdr.*
    DEFINE l_new_crn_id INTEGER
    DEFINE l_next_doc_no INTEGER
    DEFINE l_user_id INTEGER

    -- Load invoice
    SELECT * INTO l_invoice_hdr.*
      FROM sa32_inv_hdr
     WHERE id = p_invoice_id

    IF SQLCA.SQLCODE != 0 THEN
        CALL utils_globals.show_error("Invoice not found")
        RETURN
    END IF

    -- Check invoice status
    IF l_invoice_hdr.status != "POSTED" THEN
        CALL utils_globals.show_error("Invoice must be POSTED to create credit note")
        RETURN
    END IF

    -- Confirm with user
    IF NOT utils_globals.show_confirm(
        SFMT("Create Credit Note for Invoice #%1?", l_invoice_hdr.doc_no),
        "Confirm") THEN
        RETURN
    END IF

    -- Get next credit note number
    SELECT COALESCE(MAX(doc_no), 0) + 1 INTO l_next_doc_no FROM sa33_crn_hdr

    -- Get user ID first
    LET l_user_id = utils_globals.get_current_user_id()

    BEGIN WORK
    TRY
        -- Create credit note header
        INITIALIZE l_crn_hdr.* TO NULL
        LET l_crn_hdr.doc_no = l_next_doc_no
        LET l_crn_hdr.ref_doc_type = "INVOICE"
        LET l_crn_hdr.ref_doc_no = l_invoice_hdr.doc_no
        LET l_crn_hdr.trans_date = TODAY
        LET l_crn_hdr.cust_id = l_invoice_hdr.cust_id
        LET l_crn_hdr.cust_name = l_invoice_hdr.cust_name
        LET l_crn_hdr.cust_phone = l_invoice_hdr.cust_phone
        LET l_crn_hdr.cust_email = l_invoice_hdr.cust_email
        LET l_crn_hdr.cust_address1 = l_invoice_hdr.cust_address1
        LET l_crn_hdr.cust_address2 = l_invoice_hdr.cust_address2
        LET l_crn_hdr.cust_address3 = l_invoice_hdr.cust_address3
        LET l_crn_hdr.cust_postal_code = l_invoice_hdr.cust_postal_code
        LET l_crn_hdr.cust_vat_no = l_invoice_hdr.cust_vat_no
        LET l_crn_hdr.cust_payment_terms = l_invoice_hdr.cust_payment_terms
        LET l_crn_hdr.gross_tot = l_invoice_hdr.gross_tot
        LET l_crn_hdr.disc_tot = l_invoice_hdr.disc_tot
        LET l_crn_hdr.vat_tot = l_invoice_hdr.vat_tot
        LET l_crn_hdr.net_tot = l_invoice_hdr.net_tot
        LET l_crn_hdr.status = "DRAFT"
        LET l_crn_hdr.created_at = CURRENT
        LET l_crn_hdr.created_by = l_user_id

        INSERT INTO sa33_crn_hdr VALUES(l_crn_hdr.*)
        LET l_new_crn_id = SQLCA.SQLERRD[2]

        -- Copy invoice lines to credit note
        INSERT INTO sa33_crn_det(
            hdr_id, line_no, stock_id, item_name, uom,
            qnty, unit_price, disc_pct, disc_amt,
            gross_amt, net_excl_amt, vat_rate, vat_amt, line_total,
            status, created_at, created_by)
        SELECT l_new_crn_id, line_no, stock_id, item_name, uom,
               qnty, unit_price, disc_pct, disc_amt,
               gross_amt, net_excl_amt, vat_rate, vat_amt, line_total,
               'ACTIVE', CURRENT, l_user_id
          FROM sa32_inv_det
         WHERE hdr_id = p_invoice_id

        COMMIT WORK

        CALL utils_globals.show_success(
            SFMT("Credit Note #%1 created from Invoice #%2",
                l_next_doc_no, l_invoice_hdr.doc_no))

        -- Load the credit note for review/edit
        CALL load_credit_note(l_new_crn_id)

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to create credit note: %1", SQLERRMESSAGE))
    END TRY

END FUNCTION

-- ==============================================================
-- Create Standalone Credit Note
-- ==============================================================
FUNCTION new_crn_standalone()
    DEFINE l_hdr_rec RECORD LIKE sa33_crn_hdr.*
    DEFINE l_next_doc_no INTEGER
    DEFINE l_new_hdr_id INTEGER
    DEFINE l_cust_id INTEGER

    -- Generate next document number
    SELECT COALESCE(MAX(doc_no), 0) + 1 INTO l_next_doc_no FROM sa33_crn_hdr

    -- Initialize header
    INITIALIZE l_hdr_rec.* TO NULL
    LET l_hdr_rec.doc_no = l_next_doc_no
    LET l_hdr_rec.trans_date = TODAY
    LET l_hdr_rec.status = "DRAFT"
    LET l_hdr_rec.created_at = CURRENT
    LET l_hdr_rec.created_by = utils_globals.get_current_user_id()
    LET l_hdr_rec.gross_tot = 0
    LET l_hdr_rec.vat_tot = 0
    LET l_hdr_rec.disc_tot = 0
    LET l_hdr_rec.net_tot = 0

    -- Customer lookup
    LET l_cust_id = dl121_lkup.load_lookup_form_with_search()

    IF l_cust_id IS NULL OR l_cust_id = 0 THEN
        CALL utils_globals.show_info("Credit Note creation cancelled")
        RETURN
    END IF

    -- Load customer details
    CALL load_customer_details(l_cust_id)
        RETURNING l_hdr_rec.cust_id, l_hdr_rec.cust_name,
                  l_hdr_rec.cust_phone, l_hdr_rec.cust_email,
                  l_hdr_rec.cust_address1, l_hdr_rec.cust_address2,
                  l_hdr_rec.cust_address3, l_hdr_rec.cust_postal_code,
                  l_hdr_rec.cust_vat_no, l_hdr_rec.cust_payment_terms

    IF l_hdr_rec.cust_id IS NULL THEN
        CALL utils_globals.show_error("Customer not found")
        RETURN
    END IF

    -- Save header to database
    BEGIN WORK
    TRY
        INSERT INTO sa33_crn_hdr VALUES(l_hdr_rec.*)
        LET l_new_hdr_id = SQLCA.SQLERRD[2]

        COMMIT WORK

        CALL utils_globals.show_success(
            SFMT("Credit Note #%1 created. Now add lines.", l_next_doc_no))

        -- Load for editing
        CALL load_credit_note(l_new_hdr_id)

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to save credit note: %1", SQLERRMESSAGE))
    END TRY

END FUNCTION

-- ==============================================================
-- Load Customer Details
-- ==============================================================
PRIVATE FUNCTION load_customer_details(p_cust_id INTEGER)
    RETURNS(INTEGER, VARCHAR(120), VARCHAR(11), VARCHAR(120),
            VARCHAR(100), VARCHAR(100), VARCHAR(100), VARCHAR(10),
            VARCHAR(20), VARCHAR(50))

    DEFINE l_cust_id INTEGER
    DEFINE l_cust_name VARCHAR(120)
    DEFINE l_phone VARCHAR(11)
    DEFINE l_email VARCHAR(120)
    DEFINE l_address1 VARCHAR(100)
    DEFINE l_address2 VARCHAR(100)
    DEFINE l_address3 VARCHAR(100)
    DEFINE l_postal_code VARCHAR(10)
    DEFINE l_vat_no VARCHAR(20)
    DEFINE l_payment_terms VARCHAR(50)

    SELECT id, cust_name, phone, email, address1, address2, address3,
           postal_code, vat_no, payment_terms
      INTO l_cust_id, l_cust_name, l_phone, l_email, l_address1,
           l_address2, l_address3, l_postal_code, l_vat_no, l_payment_terms
      FROM dl01_mast
     WHERE id = p_cust_id

    IF SQLCA.SQLCODE != 0 THEN
        RETURN NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
    END IF

    RETURN l_cust_id, l_cust_name, l_phone, l_email, l_address1,
           l_address2, l_address3, l_postal_code, l_vat_no, l_payment_terms

END FUNCTION

-- ==============================================================
-- View/Load Credit Note
-- ==============================================================
FUNCTION view_credit_note()
    DEFINE l_crn_id INTEGER

    PROMPT "Enter Credit Note ID:" FOR l_crn_id

    IF INT_FLAG THEN
        LET INT_FLAG = FALSE
        RETURN
    END IF

    CALL load_credit_note(l_crn_id)

END FUNCTION

-- ==============================================================
-- Load Credit Note for Viewing/Editing
-- ==============================================================
FUNCTION load_credit_note(p_crn_id INTEGER)
    DEFINE idx INTEGER
    DEFINE l_can_edit SMALLINT

    OPTIONS INPUT WRAP

    OPEN WINDOW w_crn WITH FORM "sa133_crn" ATTRIBUTES(STYLE="dialog")

    -- Initialize
    INITIALIZE m_crn_hdr_rec.* TO NULL
    CALL m_crn_lines_arr.clear()

    -- Load header
    SELECT * INTO m_crn_hdr_rec.*
      FROM sa33_crn_hdr
     WHERE id = p_crn_id

    IF SQLCA.SQLCODE != 0 THEN
        CALL utils_globals.show_error("Credit Note not found")
        CLOSE WINDOW w_crn
        RETURN
    END IF

    -- Check if can edit
    LET l_can_edit = (m_crn_hdr_rec.status = "DRAFT")

    -- Load lines
    LET idx = 0
    DECLARE crn_lines_cur CURSOR FOR
        SELECT * FROM sa33_crn_det
         WHERE hdr_id = p_crn_id
         ORDER BY line_no

    FOREACH crn_lines_cur INTO m_crn_lines_arr[idx + 1].*
        LET idx = idx + 1
    END FOREACH

    CLOSE crn_lines_cur
    FREE crn_lines_cur

    -- Display
    CALL utils_globals.set_form_label("lbl_form_title",
        SFMT("Credit Note #%1 - Status: %2",
            m_crn_hdr_rec.doc_no, m_crn_hdr_rec.status))

    DISPLAY BY NAME m_crn_hdr_rec.*

    DISPLAY ARRAY m_crn_lines_arr TO arr_crn_lines.*
        BEFORE DISPLAY
            CALL DIALOG.setActionHidden("accept", TRUE)

            IF NOT l_can_edit THEN
                CALL DIALOG.setActionActive("edit", FALSE)
                CALL DIALOG.setActionActive("add", FALSE)
                CALL DIALOG.setActionActive("delete", FALSE)
                MESSAGE "Credit Note posted - cannot edit"
            END IF

        ON ACTION add ATTRIBUTES(TEXT="Add Line", IMAGE="new")
            IF l_can_edit THEN
                CALL edit_or_add_crn_line(p_crn_id, 0, TRUE)
                CALL calculate_crn_totals()
            END IF

        ON ACTION edit ATTRIBUTES(TEXT="Edit Line", IMAGE="pen")
            IF l_can_edit AND arr_curr() > 0 THEN
                CALL edit_or_add_crn_line(p_crn_id, arr_curr(), FALSE)
                CALL calculate_crn_totals()
            END IF

        ON ACTION delete ATTRIBUTES(TEXT="Delete Line", IMAGE="delete")
            IF l_can_edit AND arr_curr() > 0 THEN
                CALL delete_crn_line(arr_curr())
                CALL calculate_crn_totals()
            END IF

        ON ACTION save ATTRIBUTES(TEXT="Save", IMAGE="save")
            IF l_can_edit THEN
                CALL save_crn_lines(p_crn_id)
                CALL save_crn_totals()
                CALL utils_globals.show_success("Credit Note saved")
            END IF

        ON ACTION post ATTRIBUTES(TEXT="Post", IMAGE="forward")
            IF l_can_edit THEN
                CALL post_credit_note(p_crn_id)
                EXIT DISPLAY
            END IF

        ON ACTION close ATTRIBUTES(TEXT="Close", IMAGE="exit")
            IF l_can_edit AND m_crn_lines_arr.getLength() > 0 THEN
                IF utils_globals.show_confirm("Save changes?", "Confirm") THEN
                    CALL save_crn_lines(p_crn_id)
                    CALL save_crn_totals()
                END IF
            END IF
            EXIT DISPLAY
    END DISPLAY

    CLOSE WINDOW w_crn

END FUNCTION

-- ==============================================================
-- Add/Edit Credit Note Line
-- ==============================================================
FUNCTION edit_or_add_crn_line(p_crn_id INTEGER, p_row INTEGER, p_is_new SMALLINT)
    DEFINE l_line RECORD LIKE sa33_crn_det.*
    DEFINE l_stock_id INTEGER
    DEFINE l_item_desc VARCHAR(150)

    IF p_is_new THEN
        INITIALIZE l_line.* TO NULL
        LET l_line.hdr_id = p_crn_id
        LET l_line.line_no = m_crn_lines_arr.getLength() + 1
        LET l_line.vat_rate = 15.00
        LET l_line.disc_pct = 0
        LET l_line.status = "ACTIVE"
        LET l_line.created_at = CURRENT
        LET l_line.created_by = utils_globals.get_current_user_id()
    ELSE
        LET l_line.* = m_crn_lines_arr[p_row].*
    END IF

    OPEN WINDOW w_line_edit WITH FORM "sa133_crn_line" ATTRIBUTES(STYLE="dialog")

    INPUT BY NAME l_line.stock_id, l_line.qnty, l_line.disc_pct, l_line.vat_rate
        ATTRIBUTES(WITHOUT DEFAULTS, UNBUFFERED)

        BEFORE INPUT
            DISPLAY BY NAME l_line.*

        BEFORE FIELD stock_id
            CALL st121_st_lkup.fetch_list() RETURNING l_stock_id

            IF l_stock_id IS NOT NULL AND l_stock_id > 0 THEN
                LET l_line.stock_id = l_stock_id

                CALL load_stock_defaults(l_stock_id)
                    RETURNING l_line.unit_price, l_item_desc

                LET l_line.item_name = l_item_desc

                DISPLAY BY NAME l_line.stock_id, l_line.unit_price, l_line.item_name
                NEXT FIELD qnty
            END IF

        AFTER FIELD qnty
            IF l_line.qnty IS NOT NULL AND l_line.qnty > 0 THEN
                CALL calculate_line_totals(l_line.qnty, l_line.unit_price,
                    l_line.disc_pct, l_line.vat_rate)
                    RETURNING l_line.gross_amt, l_line.disc_amt,
                              l_line.net_excl_amt, l_line.vat_amt, l_line.line_total

                DISPLAY BY NAME l_line.gross_amt, l_line.disc_amt,
                                l_line.net_excl_amt, l_line.vat_amt, l_line.line_total
            END IF

        AFTER FIELD unit_price, disc_pct, vat_rate
            IF l_line.qnty IS NOT NULL THEN
                CALL calculate_line_totals(l_line.qnty, l_line.unit_price,
                    l_line.disc_pct, l_line.vat_rate)
                    RETURNING l_line.gross_amt, l_line.disc_amt,
                              l_line.net_excl_amt, l_line.vat_amt, l_line.line_total

                DISPLAY BY NAME l_line.gross_amt, l_line.disc_amt,
                                l_line.net_excl_amt, l_line.vat_amt, l_line.line_total
            END IF

        ON ACTION accept ATTRIBUTES(TEXT="Save", IMAGE="save")
            IF l_line.stock_id IS NULL OR l_line.stock_id = 0 THEN
                CALL utils_globals.show_error("Stock item required")
                NEXT FIELD stock_id
            END IF

            IF l_line.qnty IS NULL OR l_line.qnty <= 0 THEN
                CALL utils_globals.show_error("Quantity must be greater than 0")
                NEXT FIELD qnty
            END IF

            IF p_is_new THEN
                LET m_crn_lines_arr[m_crn_lines_arr.getLength() + 1].* = l_line.*
            ELSE
                LET m_crn_lines_arr[p_row].* = l_line.*
            END IF

            EXIT INPUT

        ON ACTION cancel
            EXIT INPUT
    END INPUT

    CLOSE WINDOW w_line_edit

END FUNCTION

-- ==============================================================
-- Load Stock Defaults
-- ==============================================================
PRIVATE FUNCTION load_stock_defaults(p_stock_id INTEGER)
    RETURNS(DECIMAL, VARCHAR(150))

    DEFINE l_price DECIMAL(15,2)
    DEFINE l_desc VARCHAR(150)

    SELECT sell_price, description
      INTO l_price, l_desc
      FROM st01_mast
     WHERE id = p_stock_id

    IF SQLCA.SQLCODE != 0 THEN
        LET l_price = 0
        LET l_desc = "Unknown Item"
    END IF

    RETURN l_price, l_desc

END FUNCTION

-- ==============================================================
-- Calculate Line Totals
-- ==============================================================
PRIVATE FUNCTION calculate_line_totals(
    p_qnty DECIMAL, p_price DECIMAL, p_disc_pct DECIMAL, p_vat_rate DECIMAL)
    RETURNS(DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL)

    DEFINE l_gross, l_disc, l_net, l_vat, l_total DECIMAL(15,2)

    LET l_gross = p_qnty * p_price
    LET l_disc = l_gross * (p_disc_pct / 100)
    LET l_net = l_gross - l_disc
    LET l_vat = l_net * (p_vat_rate / 100)
    LET l_total = l_net + l_vat

    RETURN l_gross, l_disc, l_net, l_vat, l_total

END FUNCTION

-- ==============================================================
-- Calculate Credit Note Totals
-- ==============================================================
FUNCTION calculate_crn_totals()
    DEFINE i INTEGER
    DEFINE l_gross, l_disc, l_vat, l_net DECIMAL(15,2)

    LET l_gross = 0
    LET l_disc = 0
    LET l_vat = 0

    FOR i = 1 TO m_crn_lines_arr.getLength()
        LET l_gross = l_gross + NVL(m_crn_lines_arr[i].gross_amt, 0)
        LET l_disc = l_disc + NVL(m_crn_lines_arr[i].disc_amt, 0)
        LET l_vat = l_vat + NVL(m_crn_lines_arr[i].vat_amt, 0)
    END FOR

    LET l_net = l_gross - l_disc + l_vat

    LET m_crn_hdr_rec.gross_tot = l_gross
    LET m_crn_hdr_rec.disc_tot = l_disc
    LET m_crn_hdr_rec.vat_tot = l_vat
    LET m_crn_hdr_rec.net_tot = l_net

    DISPLAY BY NAME m_crn_hdr_rec.gross_tot, m_crn_hdr_rec.disc_tot,
                    m_crn_hdr_rec.vat_tot, m_crn_hdr_rec.net_tot

END FUNCTION

-- ==============================================================
-- Delete Credit Note Line
-- ==============================================================
FUNCTION delete_crn_line(p_row INTEGER)
    IF p_row > 0 THEN
        IF utils_globals.show_confirm(
            SFMT("Delete line %1?", p_row), "Confirm Delete") THEN
            CALL m_crn_lines_arr.deleteElement(p_row)
            CALL utils_globals.show_success("Line deleted")
        END IF
    END IF
END FUNCTION

-- ==============================================================
-- Save Credit Note Lines
-- ==============================================================
FUNCTION save_crn_lines(p_crn_id INTEGER)
    DEFINE i INTEGER

    BEGIN WORK
    TRY
        DELETE FROM sa33_crn_det WHERE hdr_id = p_crn_id

        FOR i = 1 TO m_crn_lines_arr.getLength()
            LET m_crn_lines_arr[i].hdr_id = p_crn_id
            INSERT INTO sa33_crn_det VALUES m_crn_lines_arr[i].*
        END FOR

        COMMIT WORK

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to save lines: %1", SQLERRMESSAGE))
    END TRY

END FUNCTION

-- ==============================================================
-- Save Credit Note Totals
-- ==============================================================
FUNCTION save_crn_totals()
    BEGIN WORK
    TRY
        UPDATE sa33_crn_hdr
           SET gross_tot = m_crn_hdr_rec.gross_tot,
               disc_tot = m_crn_hdr_rec.disc_tot,
               vat_tot = m_crn_hdr_rec.vat_tot,
               net_tot = m_crn_hdr_rec.net_tot,
               updated_at = CURRENT
         WHERE id = m_crn_hdr_rec.id

        COMMIT WORK

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to update totals: %1", SQLERRMESSAGE))
    END TRY

END FUNCTION

-- ==============================================================
-- Post Credit Note (Stock, Balance, Journal)
-- ==============================================================
FUNCTION post_credit_note(p_crn_id INTEGER)
    DEFINE i INTEGER
    DEFINE l_stock_id INTEGER
    DEFINE l_quantity DECIMAL(15,2)
    DEFINE l_jrn_id INTEGER

    -- Validate
    IF m_crn_lines_arr.getLength() = 0 THEN
        CALL utils_globals.show_error("Cannot post - no lines")
        RETURN
    END IF

    -- Confirm
    IF NOT utils_globals.show_confirm(
        SFMT("Post Credit Note #%1?\nThis will:\n- Return stock\n- Credit customer\n- Create journal entries",
            m_crn_hdr_rec.doc_no), "Confirm Post") THEN
        RETURN
    END IF

    BEGIN WORK
    TRY
        -- Return stock for each line
        FOR i = 1 TO m_crn_lines_arr.getLength()
            LET l_stock_id = m_crn_lines_arr[i].stock_id
            LET l_quantity = m_crn_lines_arr[i].qnty

            IF NOT utils_global_stock_updater.update_stock_simple(
                l_stock_id, l_quantity, "IN", "CRN") THEN
                ROLLBACK WORK
                CALL utils_globals.show_error("Failed to return stock to inventory")
                RETURN
            END IF
        END FOR

        -- Credit customer balance
        UPDATE dl01_mast
           SET balance = balance - m_crn_hdr_rec.net_tot
         WHERE id = m_crn_hdr_rec.cust_id

        -- Create journal entry
        LET l_jrn_id = utils_global_journal_updater.create_sales_credit_note_journal(
            p_crn_id,
            m_crn_hdr_rec.doc_no,
            m_crn_hdr_rec.trans_date,
            m_crn_hdr_rec.cust_id,
            m_crn_hdr_rec.net_tot
        )

        IF l_jrn_id = 0 THEN
            ROLLBACK WORK
            CALL utils_globals.show_error("Failed to create journal entry")
            RETURN
        END IF

        -- Update credit note status
        UPDATE sa33_crn_hdr
           SET status = "POSTED",
               updated_at = CURRENT
         WHERE id = p_crn_id

        COMMIT WORK

        LET m_crn_hdr_rec.status = "POSTED"

        CALL utils_globals.show_success(
            SFMT("Credit Note #%1 posted successfully", m_crn_hdr_rec.doc_no))

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to post credit note: %1", SQLERRMESSAGE))
    END TRY

END FUNCTION

-- ==============================================================
-- Delete Credit Note
-- ==============================================================
FUNCTION delete_credit_note()
    DEFINE l_crn_id INTEGER

    PROMPT "Enter Credit Note ID to delete:" FOR l_crn_id

    IF INT_FLAG THEN
        LET INT_FLAG = FALSE
        RETURN
    END IF

    IF l_crn_id IS NULL OR l_crn_id = 0 THEN
        RETURN
    END IF

    -- Check status
    SELECT status INTO m_crn_hdr_rec.status
      FROM sa33_crn_hdr
     WHERE id = l_crn_id

    IF SQLCA.SQLCODE != 0 THEN
        CALL utils_globals.show_error("Credit Note not found")
        RETURN
    END IF

    IF m_crn_hdr_rec.status = "POSTED" THEN
        CALL utils_globals.show_error("Cannot delete posted credit note")
        RETURN
    END IF

    IF NOT utils_globals.show_confirm("Delete this Credit Note?", "Confirm Delete") THEN
        RETURN
    END IF

    BEGIN WORK
    TRY
        DELETE FROM sa33_crn_det WHERE hdr_id = l_crn_id
        DELETE FROM sa33_crn_hdr WHERE id = l_crn_id

        COMMIT WORK
        CALL utils_globals.show_success("Credit Note deleted")

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to delete: %1", SQLERRMESSAGE))
    END TRY

END FUNCTION
