-- ==============================================================
-- Program   : sa130_quote.4gl
-- Purpose   : Sales Quote Program
-- Module    : Sales Quote (sa)
-- Number    : 130
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Updated   : Added proper workflow, copy-to-order, status management
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL st121_st_lkup
IMPORT FGL utils_doc_totals
IMPORT FGL dl121_lkup

SCHEMA demoappdb

GLOBALS
    DEFINE g_hdr_saved SMALLINT
END GLOBALS

-- ==============================================================
-- Record Definitions
-- ==============================================================

-- header and master
TYPE qt_hdr_t RECORD LIKE sa30_quo_hdr.*
TYPE qt_line_arr DYNAMIC ARRAY OF RECORD LIKE sa30_quo_det.*
TYPE cust_t RECORD LIKE dl01_mast.*

DEFINE m_qt_hdr_rec qt_hdr_t
DEFINE m_qt_lines_arr qt_line_arr
DEFINE m_cust_rec cust_t

-- doc lines
DEFINE is_edit SMALLINT

-- indexes
DEFINE m_arr_codes DYNAMIC ARRAY OF STRING
DEFINE m_curr_idx INTEGER
DEFINE m_user SMALLINT

-- ==============================================================
-- Function : new_ord from master file (Header first, then lines)
-- ==============================================================
FUNCTION new_ord_from_master(p_cust_id INTEGER)
    DEFINE l_cust_id INTEGER
    LET l_cust_id = p_cust_id

    SELECT * INTO m_qt_hdr_rec.* FROM dl01_mast WHERE id = p_cust_id

    OPTIONS INPUT WRAP
    OPEN WINDOW w_sa130 WITH FORM "sa130_quote" -- ATTRIBUTES(STYLE = "normal")

    INITIALIZE m_qt_hdr_rec.* TO NULL
    
    LET m_qt_hdr_rec.doc_no = utils_globals.get_next_code('sa30_quo_hdr', 'id')
    LET m_qt_hdr_rec.trans_date = TODAY
    LET m_qt_hdr_rec.status = "draft"
    LET m_qt_hdr_rec.created_at = TODAY  -- FIXED: Changed from CURRENT
    LET m_qt_hdr_rec.created_by = utils_globals.get_random_user()

    -- link customer
    LET m_qt_hdr_rec.gross_tot = 0; 
    LET m_qt_hdr_rec.disc_tot = 0
    LET m_qt_hdr_rec.vat_tot   = 0; 
    LET m_qt_hdr_rec.net_tot  = 0

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME m_qt_hdr_rec.* ATTRIBUTES(WITHOUT DEFAULTS)
   
        ON ACTION save_header ATTRIBUTES(TEXT="Save Header")
            IF NOT save_order_header() THEN
                CALL utils_globals.show_error("Save failed.")
                RETURN 
            END IF

            LET g_hdr_saved = TRUE
            CONTINUE DIALOG

        ON ACTION CANCEL ATTRIBUTES(TEXT="Exit")
            EXIT DIALOG
        END INPUT

    END DIALOG

    CLOSE WINDOW w_sa130
END FUNCTION


-- ==============================================================
-- Save: insert or update
-- ==============================================================
FUNCTION save_order_header() RETURNS SMALLINT
    DEFINE ok SMALLINT
    BEGIN WORK
    TRY
        IF m_qt_hdr_rec.id IS NULL THEN
            INSERT INTO sa30_quo_hdr VALUES(m_qt_hdr_rec.*)
            CALL utils_globals.msg_saved()
        ELSE
            LET m_qt_hdr_rec.updated_at = TODAY 
            UPDATE sa30_quo_hdr SET m_qt_hdr_rec.* = m_qt_hdr_rec.* WHERE id = m_qt_hdr_rec.id
            IF SQLCA.SQLCODE = 0 THEN
                CALL utils_globals.msg_updated()
            END IF
        END IF
        COMMIT WORK
        LET ok = (m_qt_hdr_rec.id IS NOT NULL)
        RETURN ok
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error("Save failed:\n" || SQLCA.SQLERRM)
        RETURN FALSE
    END TRY
END FUNCTION


-- ==============================================================
-- Function : new_quote (Header first, then lines)
-- ==============================================================
FUNCTION new_quote()
    DEFINE l_hdr_rec RECORD LIKE sa30_quo_hdr.*
    DEFINE l_next_doc_no INTEGER
    DEFINE l_new_hdr_id INTEGER

    -- ==========================================================
    -- 1. Generate next document number
    -- ==========================================================
    SELECT COALESCE(MAX(id), 0) + 1 INTO l_next_doc_no FROM sa30_quo_hdr

    -- ==========================================================
    -- 2. Initialize header
    -- ==========================================================
    INITIALIZE l_hdr_rec.* TO NULL
    LET l_hdr_rec.doc_no = l_next_doc_no
    LET l_hdr_rec.trans_date = TODAY
    LET l_hdr_rec.status = "draft"
    LET l_hdr_rec.created_at = CURRENT
    LET l_hdr_rec.created_by = utils_globals.get_current_user_id()
    LET l_hdr_rec.gross_tot = 0
    LET l_hdr_rec.vat_tot = 0
    LET l_hdr_rec.disc_tot = 0
    LET l_hdr_rec.net_tot = 0

    -- ==========================================================
    -- 3. Input Header Details
    -- ==========================================================
    --OPEN WINDOW w_quote_hdr WITH FORM "sa130_quote" --ATTRIBUTES(STYLE="dialog")

    CALL utils_globals.set_form_label("lbl_form_title", "New Sales Quote - Header")

    INPUT BY NAME l_hdr_rec.*
        ATTRIBUTES(WITHOUT DEFAULTS, UNBUFFERED)

        BEFORE INPUT
            DISPLAY BY NAME l_hdr_rec.doc_no, l_hdr_rec.status, l_hdr_rec.trans_date
            MESSAGE SFMT("Enter quote header details for Quote #%1", l_next_doc_no)

        AFTER FIELD doc_no
            IF l_hdr_rec.id IS NOT NULL THEN
                CALL load_customer_details(l_hdr_rec.id)
                    RETURNING l_hdr_rec.cust_id, l_hdr_rec.cust_name, l_hdr_rec.cust_id,
                              l_hdr_rec.cust_phone, l_hdr_rec.cust_email, l_hdr_rec.cust_address1,
                              l_hdr_rec.cust_address2, l_hdr_rec.cust_address3,
                              l_hdr_rec.cust_postal_code, l_hdr_rec.cust_vat_no,
                              l_hdr_rec.cust_payment_terms

                IF l_hdr_rec.cust_id IS NULL THEN
                    CALL utils_globals.show_error("Customer not found")
                    NEXT FIELD id
                END IF
            END IF

        ON ACTION lookup_customer ATTRIBUTES(TEXT="Customer Lookup", IMAGE="zoom")
            CALL dl121_lkup.load_lookup_form_with_search() RETURNING l_hdr_rec.id
            IF l_hdr_rec.id IS NOT NULL THEN
                CALL load_customer_details(l_hdr_rec.id)
                    RETURNING l_hdr_rec.cust_id, l_hdr_rec.cust_name, l_hdr_rec.cust_id,
                              l_hdr_rec.cust_phone, l_hdr_rec.cust_email, l_hdr_rec.cust_address1,
                              l_hdr_rec.cust_address2, l_hdr_rec.cust_address3,
                              l_hdr_rec.cust_postal_code, l_hdr_rec.cust_vat_no,
                              l_hdr_rec.cust_payment_terms
                DISPLAY BY NAME l_hdr_rec.id
            END IF

        ON ACTION accept ATTRIBUTES(TEXT="Save Header", IMAGE="save")
            -- Validate header
            IF l_hdr_rec.id IS NULL THEN
                CALL utils_globals.show_error("Customer is required")
                NEXT FIELD id
            END IF

            IF l_hdr_rec.trans_date IS NULL THEN
                LET l_hdr_rec.trans_date = TODAY
            END IF

            ACCEPT INPUT

        ON ACTION cancel ATTRIBUTES(TEXT="Cancel", IMAGE="exit")
            CALL utils_globals.show_info("Quote creation cancelled.")
            --CLOSE WINDOW w_quote_hdr
            RETURN
    END INPUT

    -- Check if cancelled
    IF INT_FLAG THEN
        LET INT_FLAG = FALSE
        --CLOSE WINDOW w_quote_hdr
        RETURN
    END IF

    -- ==========================================================
    -- 4. Save Header to Database (CRITICAL STEP)
    -- ==========================================================
    BEGIN WORK
    TRY
        INSERT INTO sa30_quo_hdr VALUES(l_hdr_rec.*)

        -- Get the generated header ID
        LET l_new_hdr_id = SQLCA.SQLERRD[2]
        LET l_hdr_rec.id = l_new_hdr_id

        COMMIT WORK

        CALL utils_globals.show_success(
            SFMT("Quote header #%1 saved. ID=%2. Now add quote lines.",
                 l_next_doc_no, l_new_hdr_id))

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to save quote header: %1", SQLCA.SQLCODE))
        --CLOSE WINDOW w_quote_hdr
        RETURN
    END TRY

    --CLOSE WINDOW w_quote_hdr

    -- ==========================================================
    -- 5. Now add lines (header ID exists)
    -- ==========================================================
    LET m_qt_hdr_rec.* = l_hdr_rec.*
    CALL m_qt_lines_arr.clear()

    CALL input_quote_lines(l_new_hdr_id)

    -- ==========================================================
    -- 6. Load the complete quote for viewing
    -- ==========================================================
    CALL load_quote(l_new_hdr_id)

END FUNCTION

-- ==============================================================
-- Function : input_quote_lines
-- ==============================================================
FUNCTION input_quote_lines(p_hdr_id INTEGER)

    OPEN WINDOW w_quote_lines WITH FORM "sa130_quote" ATTRIBUTES(STYLE="dialog")

    CALL utils_globals.set_form_label("lbl_form_title",
        SFMT("Quote #%1 - Add Lines", m_qt_hdr_rec.doc_no))

    -- Display only fields that exist in the form
    DISPLAY BY NAME m_qt_hdr_rec.doc_no, m_qt_hdr_rec.ref_no, m_qt_hdr_rec.id,
                    m_qt_hdr_rec.trans_date, m_qt_hdr_rec.status, m_qt_hdr_rec.gross_tot,
                    m_qt_hdr_rec.disc_tot, m_qt_hdr_rec.vat_tot, m_qt_hdr_rec.net_tot

    DIALOG ATTRIBUTES(UNBUFFERED)

        DISPLAY ARRAY m_qt_lines_arr TO arr_sa_qt_lines.*
            BEFORE DISPLAY
                CALL DIALOG.setActionHidden("accept", TRUE)

            ON ACTION add ATTRIBUTES(TEXT="Add Line", IMAGE="new")
                CALL edit_or_add_qt_line(p_hdr_id, 0, TRUE)
                CALL calculate_quote_totals()

            ON ACTION edit ATTRIBUTES(TEXT="Edit Line", IMAGE="pen")
                IF arr_curr() > 0 THEN
                    CALL edit_or_add_qt_line(p_hdr_id, arr_curr(), FALSE)
                    CALL calculate_quote_totals()
                END IF

            ON ACTION delete ATTRIBUTES(TEXT="Delete Line", IMAGE="delete")
                IF arr_curr() > 0 THEN
                    CALL delete_qt_line(p_hdr_id, arr_curr())
                    CALL calculate_quote_totals()
                END IF

            ON ACTION save ATTRIBUTES(TEXT="Save Lines", IMAGE="save")
                CALL save_qt_lines(p_hdr_id)
                CALL save_quote_header_totals()
                CALL utils_globals.show_success("Quote lines saved successfully.")
                EXIT DIALOG

            ON ACTION close ATTRIBUTES(TEXT="Close", IMAGE="exit")
                IF m_qt_lines_arr.getLength() > 0 THEN
                    IF utils_globals.show_confirm(
                        "Save lines before closing?", "Confirm") THEN
                        CALL save_qt_lines(p_hdr_id)
                        CALL save_quote_header_totals()
                    END IF
                END IF
                EXIT DIALOG
        END DISPLAY

    END DIALOG

    CLOSE WINDOW w_quote_lines

END FUNCTION

-- ==============================================================
-- Function : edit_or_add_qt_line
-- ==============================================================
FUNCTION edit_or_add_qt_line(p_doc_id INTEGER, p_row INTEGER, p_is_new SMALLINT)
    DEFINE l_line RECORD LIKE sa30_quo_det.*
    DEFINE l_stock_id INTEGER
    DEFINE l_item_desc VARCHAR(150)

    -- Initialize new line
    IF p_is_new THEN
        INITIALIZE l_line.* TO NULL
        LET l_line.hdr_id = p_doc_id
        LET l_line.line_no = m_qt_lines_arr.getLength() + 1
        LET l_line.vat_rate = 15.00
        LET l_line.disc_pct = 0
        LET l_line.status = 1
        LET l_line.created_at = CURRENT
        LET l_line.created_by = utils_globals.get_current_user_id()
    ELSE
        -- Load from existing array line
        --LET l_line.* = m_qt_lines_arr[p_row].*
    END IF

    -- ==============================
    -- Input Dialog for editing/adding
    -- ==============================
    OPEN WINDOW w_line_edit WITH FORM "sa130_quote_line" ATTRIBUTES(STYLE="dialog")

    INPUT BY NAME l_line.stock_id, l_line.qnty, l_line.unit_price,
                  l_line.disc_pct, l_line.vat_rate
        ATTRIBUTES(WITHOUT DEFAULTS, UNBUFFERED)

        BEFORE INPUT
            DISPLAY BY NAME l_line.*

        BEFORE FIELD stock_id
            -- Stock lookup popup
            CALL st121_st_lkup.fetch_list() RETURNING l_stock_id

            IF l_stock_id IS NOT NULL AND l_stock_id > 0 THEN
                LET l_line.stock_id = l_stock_id
                LET l_line.stock_id = l_stock_id

                -- Load stock defaults (CORRECTED field names)
                CALL load_stock_defaults(l_stock_id)
                    RETURNING l_line.unit_price, l_line.unit_price, l_item_desc

                LET l_line.item_name = l_item_desc

                DISPLAY BY NAME l_line.stock_id, l_line.unit_price,
                                l_line.unit_price, l_line.item_name

                NEXT FIELD qnty
            END IF

        AFTER FIELD qnty
            IF l_line.qnty IS NOT NULL AND l_line.qnty > 0 THEN
                CALL utils_doc_totals.calculate_line_totals(l_line.qnty, l_line.unit_price,
                                          l_line.disc_pct, l_line.vat_rate)
                    RETURNING l_line.gross_amt, l_line.disc_amt,
                              l_line.net_amt, l_line.vat_amt, l_line.line_total

                DISPLAY BY NAME l_line.gross_amt, l_line.disc_amt,
                                l_line.net_amt, l_line.vat_amt, l_line.line_total
            END IF

        AFTER FIELD unit_price, disc_pct, vat_rate
            IF l_line.qnty IS NOT NULL THEN
                CALL utils_doc_totals.calculate_line_totals(l_line.qnty, l_line.unit_price,
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
            -- TODO:: Fix this so taht the lines are 
                --LET m_qt_lines_arr[m_qt_lines_arr.getLength() + 1].* = l_line.*
            ELSE
                --LET m_qt_lines_arr[p_row].* = l_line.*
            END IF

            CALL utils_globals.show_success("Line saved")
            EXIT INPUT

        ON ACTION cancel
            EXIT INPUT
    END INPUT

    CLOSE WINDOW w_line_edit

END FUNCTION

-- ==============================================================
-- Function : load_stock_defaults
-- ==============================================================
FUNCTION load_stock_defaults(p_stock_id INTEGER)
    RETURNS (DECIMAL, DECIMAL, VARCHAR(150))

    DEFINE l_cost DECIMAL(15,2)
    DEFINE l_price DECIMAL(15,2)
    DEFINE l_desc VARCHAR(150)

    SELECT unit_price, sell_price, description
        INTO l_cost, l_price, l_desc
        FROM st01_mast
        WHERE stock_id = p_stock_id

    IF SQLCA.SQLCODE != 0 THEN
        LET l_cost = 0
        LET l_price = 0
        LET l_desc = "Unknown Item"
    END IF

    RETURN l_cost, l_price, l_desc

END FUNCTION

-- ==============================================================
-- Function : delete_qt_line
-- ==============================================================
FUNCTION delete_qt_line(p_doc_id INTEGER, p_row INTEGER)
    IF p_row > 0 THEN
        IF utils_globals.show_confirm(
            SFMT("Delete line %1?", p_row), "Confirm Delete") THEN
            CALL m_qt_lines_arr.deleteElement(p_row)
            CALL utils_globals.show_success("Line deleted")
        END IF
    END IF
END FUNCTION

-- ==============================================================
-- Function : save_qt_lines
-- ==============================================================
FUNCTION save_qt_lines(p_doc_id INTEGER)
    DEFINE i INTEGER

    BEGIN WORK
    TRY
        DELETE FROM sa30_quo_det WHERE hdr_id = p_doc_id

        FOR i = 1 TO m_qt_lines_arr.getLength()
            -- Ensure hdr_id is set
            LET m_qt_lines_arr[i].hdr_id = p_doc_id
            INSERT INTO sa30_quo_det VALUES m_qt_lines_arr[i].*
        END FOR

        COMMIT WORK

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to save lines: %1", SQLCA.SQLCODE))
    END TRY

END FUNCTION

-- ==============================================================
-- Function : calculate_quote_totals (NEW)
-- ==============================================================
FUNCTION calculate_quote_totals()
    DEFINE i INTEGER
    DEFINE l_gross, l_disc_tot, l_vat_tot, l_net DECIMAL(15,2)

    LET l_gross = 0
    LET l_disc_tot = 0
    LET l_vat_tot = 0

    FOR i = 1 TO m_qt_lines_arr.getLength()
        LET l_gross = l_gross + NVL(m_qt_lines_arr[i].gross_amt, 0)
        LET l_disc_tot = l_disc_tot + NVL(m_qt_lines_arr[i].disc_amt, 0)
        LET l_vat_tot = l_vat_tot + NVL(m_qt_lines_arr[i].vat_amt, 0)
    END FOR

    LET l_net = l_gross - l_disc_tot + l_vat_tot

    LET m_qt_hdr_rec.gross_tot = l_gross
    LET m_qt_hdr_rec.disc_tot = l_disc_tot
    LET m_qt_hdr_rec.vat_tot = l_vat_tot
    LET m_qt_hdr_rec.net_tot = l_net

    DISPLAY BY NAME m_qt_hdr_rec.gross_tot, m_qt_hdr_rec.disc_tot,
                     m_qt_hdr_rec.vat_tot, m_qt_hdr_rec.net_tot

    MESSAGE SFMT("Totals: Gross=%1, disc_tot=%2, vat_tot=%3, Net=%4",
                 l_gross USING "<<<,<<<,<<&.&&",
                 l_disc_tot USING "<<<,<<<,<<&.&&",
                 l_vat_tot USING "<<<,<<<,<<&.&&",
                 l_net USING "<<<,<<<,<<&.&&")

END FUNCTION

-- ==============================================================
-- Function : save_quote_header_totals
-- ==============================================================
FUNCTION save_quote_header_totals()

    BEGIN WORK
    TRY
        UPDATE sa30_quo_hdr
            SET gross_tot = m_qt_hdr_rec.gross_tot,
                disc_tot = m_qt_hdr_rec.disc_tot,
                vat_tot = m_qt_hdr_rec.vat_tot,
                net_tot = m_qt_hdr_rec.net_tot,
                updated_at = CURRENT
            WHERE id = m_qt_hdr_rec.id

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
FUNCTION load_customer_details(p_acc_code INTEGER)
    RETURNS (INTEGER, VARCHAR(100), VARCHAR(30), VARCHAR(20), VARCHAR(100),
             VARCHAR(100), VARCHAR(100), VARCHAR(100), VARCHAR(10),
             VARCHAR(20), VARCHAR(50))

    DEFINE l_cust_id INTEGER
    DEFINE l_cust_name VARCHAR(100)
    DEFINE l_cust_acc_code VARCHAR(30)
    DEFINE l_phone VARCHAR(20)
    DEFINE l_email VARCHAR(100)
    DEFINE l_addr1 VARCHAR(100)
    DEFINE l_addr2 VARCHAR(100)
    DEFINE l_addr3 VARCHAR(100)
    DEFINE l_postal VARCHAR(10)
    DEFINE l_vat VARCHAR(20)
    DEFINE l_terms VARCHAR(50)

    SELECT id, cust_name, id, phone, email,
           address1, address2, address3, postal_code,
           vat_no, payment_terms
        INTO l_cust_id, l_cust_name, l_cust_acc_code, l_phone, l_email,
             l_addr1, l_addr2, l_addr3, l_postal, l_vat, l_terms
        FROM dl01_mast
        WHERE id = p_acc_code

    IF SQLCA.SQLCODE = 0 THEN
        MESSAGE SFMT("Customer: %1", l_cust_name)
        RETURN l_cust_id, l_cust_name, l_cust_acc_code, l_phone, l_email,
               l_addr1, l_addr2, l_addr3, l_postal, l_vat, l_terms
    ELSE
        RETURN NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
    END IF

END FUNCTION

-- ==============================================================
-- Function : load_quote
-- ==============================================================
FUNCTION load_quote(p_doc_id INTEGER)
    DEFINE idx INTEGER
    DEFINE user_choice SMALLINT
    DEFINE l_can_edit SMALLINT

    OPTIONS INPUT WRAP

    -- Open window and attach form
    OPEN WINDOW w_qt WITH FORM "sa130_quote" ATTRIBUTES(STYLE = "dialog")

    -- Initialize variables
    INITIALIZE m_qt_hdr_rec.* TO NULL
    CALL m_qt_lines_arr.clear()

    -- ===========================================
    -- Load header record
    -- ===========================================
    SELECT * INTO m_qt_hdr_rec.*
      FROM sa30_quo_hdr
     WHERE id = p_doc_id

    IF SQLCA.SQLCODE = 0 THEN
        -- ===========================================
        -- Check if quote can be edited
        -- ===========================================
        LET l_can_edit = can_edit_quote(m_qt_hdr_rec.id, m_qt_hdr_rec.status)

        -- ===========================================
        -- Load quote lines - populate both screen and full arrays
        -- ===========================================
        LET idx = 0
        DECLARE qt_lines_cur CURSOR FOR
            SELECT stock_id, batch_id, qnty, unit_price, sell_price,
                   disc_amt, vat_amt, line_total
              FROM sa30_quo_det
             WHERE hdr_id = p_doc_id
             ORDER BY line_no

        FOREACH qt_lines_cur INTO m_qt_lines_arr[idx + 1].*
            LET idx = idx + 1
        END FOREACH

        CLOSE qt_lines_cur
        FREE qt_lines_cur

        -- ===========================================
        -- Show form in view mode first
        -- ===========================================
        CALL utils_globals.set_form_label("lbl_form_title",
            SFMT("Sales Quote #%1 - Status: %2", m_qt_hdr_rec.doc_no, m_qt_hdr_rec.status))

        -- Display only fields that exist in the form
        DISPLAY BY NAME m_qt_hdr_rec.doc_no, m_qt_hdr_rec.ref_no, m_qt_hdr_rec.id,
                        m_qt_hdr_rec.trans_date, m_qt_hdr_rec.status, m_qt_hdr_rec.gross_tot,
                        m_qt_hdr_rec.disc_tot, m_qt_hdr_rec.vat_tot, m_qt_hdr_rec.net_tot

        DISPLAY ARRAY m_qt_lines_arr TO arr_sa_qt_lines.*

            BEFORE DISPLAY
                CALL DIALOG.setActionHidden("cancel", TRUE)
                CALL DIALOG.setActionHidden("accept", TRUE)

                -- Disable edit if converted
                IF NOT l_can_edit THEN
                    CALL DIALOG.setActionActive("edit", FALSE)
                    MESSAGE "Quote converted to order - cannot edit"
                END IF

            ON ACTION edit ATTRIBUTES(TEXT="Edit Quote", IMAGE="pen")
                IF NOT l_can_edit THEN
                    CALL utils_globals.show_error(
                        "Cannot edit quote with status: " || m_qt_hdr_rec.status)
                    CONTINUE DISPLAY
                END IF

                LET user_choice = prompt_edit_choice()

                CASE user_choice
                    WHEN 1
                        CALL edit_qt_header(p_doc_id)
                        -- Refresh header display - only fields that exist in form
                        DISPLAY BY NAME m_qt_hdr_rec.doc_no, m_qt_hdr_rec.ref_no, m_qt_hdr_rec.id,
                                        m_qt_hdr_rec.trans_date, m_qt_hdr_rec.status, m_qt_hdr_rec.gross_tot,
                                        m_qt_hdr_rec.disc_tot, m_qt_hdr_rec.vat_tot, m_qt_hdr_rec.net_tot
                    WHEN 2
                        CALL edit_qt_lines(p_doc_id)
                    OTHERWISE
                        CALL utils_globals.show_info("Edit cancelled.")
                END CASE

            ON ACTION copy_to_order ATTRIBUTES(TEXT="Copy to Order", IMAGE="forward")
                CALL copy_quote_to_order(p_doc_id)
                -- Reload to show updated status
                EXIT DISPLAY

            ON ACTION view_order ATTRIBUTES(TEXT="View Order", IMAGE="info")
                CALL view_linked_order(m_qt_hdr_rec.doc_no)

            ON ACTION delete ATTRIBUTES(TEXT="Delete", IMAGE="delete")
                CALL delete_quote(p_doc_id)
                EXIT DISPLAY

            ON ACTION close ATTRIBUTES(TEXT="Close", IMAGE="exit")
                EXIT DISPLAY
        END DISPLAY
    ELSE
        CALL utils_globals.show_error("Quote not found.")
    END IF

    CLOSE WINDOW w_qt
END FUNCTION

-- ==============================================================
-- Function : can_edit_quote (NEW)
-- ==============================================================
FUNCTION can_edit_quote(p_quote_id INTEGER, p_status VARCHAR(10))
    RETURNS SMALLINT

    DEFINE l_order_count INTEGER

    -- Check status
    IF p_status = "CONVERTED" OR p_status = "CANCELLED" THEN
        RETURN FALSE
    END IF

    -- Check for linked orders
    SELECT COUNT(*) INTO l_order_count
      FROM sa31_ord_hdr
     WHERE ref_doc_type = "QUOTE"
       AND ref_doc_no = (SELECT doc_no FROM sa30_quo_hdr WHERE id = p_quote_id)

    IF l_order_count > 0 THEN
        RETURN FALSE
    END IF

    RETURN TRUE

END FUNCTION

-- ==============================================================
-- Function : copy_quote_to_order (NEW - CRITICAL FEATURE)
-- ==============================================================
FUNCTION copy_quote_to_order(p_quote_id INTEGER)
    DEFINE l_quote_hdr RECORD LIKE sa30_quo_hdr.*
    DEFINE l_order_hdr RECORD LIKE sa31_ord_hdr.*
    DEFINE l_new_order_id INTEGER
    DEFINE l_new_order_doc_no INTEGER
    DEFINE l_order_count INTEGER

    -- ===========================================
    -- 1. Validate quote can be converted
    -- ===========================================

    -- Check if already converted
    SELECT COUNT(*) INTO l_order_count
      FROM sa31_ord_hdr
     WHERE ref_doc_type = "QUOTE"
       AND ref_doc_no = (SELECT doc_no FROM sa30_quo_hdr WHERE id = p_quote_id)

    IF l_order_count > 0 THEN
        CALL utils_globals.show_error("Quote has already been converted to an order")
        RETURN
    END IF

    -- Load quote
    SELECT * INTO l_quote_hdr.*
      FROM sa30_quo_hdr
     WHERE id = p_quote_id

    IF SQLCA.SQLCODE != 0 THEN
        CALL utils_globals.show_error("Quote not found")
        RETURN
    END IF

    -- Check status
    IF l_quote_hdr.status = "CONVERTED" THEN
        CALL utils_globals.show_error("Quote already converted")
        RETURN
    END IF

    -- Confirm with user
    IF NOT utils_globals.show_confirm(
        SFMT("Convert Quote #%1 to Sales Order?", l_quote_hdr.doc_no),
        "Confirm Conversion") THEN
        RETURN
    END IF

    -- ===========================================
    -- 2. Create order header
    -- ===========================================
    BEGIN WORK
    TRY
        -- Get next order number
        SELECT COALESCE(MAX(doc_no), 0) + 1 INTO l_new_order_doc_no
          FROM sa31_ord_hdr

        -- Copy quote to order
        INITIALIZE l_order_hdr.* TO NULL
        LET l_order_hdr.id = l_new_order_doc_no
        LET l_order_hdr.ref_doc_type = "QUOTE"
        LET l_order_hdr.ref_doc_no = l_quote_hdr.doc_no
        LET l_order_hdr.trans_date = TODAY
        LET l_order_hdr.gross_tot = l_quote_hdr.gross_tot
        LET l_order_hdr.disc_tot = l_quote_hdr.disc_tot
        LET l_order_hdr.vat_tot = l_quote_hdr.vat_tot
        LET l_order_hdr.net_tot = l_quote_hdr.net_tot
        LET l_order_hdr.status = "NEW"
        LET l_order_hdr.created_at = CURRENT
        LET l_order_hdr.created_by = utils_globals.get_current_user_id()

        -- Copy customer details
        LET l_order_hdr.cust_id = l_quote_hdr.cust_id
        LET l_order_hdr.cust_name = l_quote_hdr.cust_name
        LET l_order_hdr.cust_phone = l_quote_hdr.cust_phone
        LET l_order_hdr.cust_email = l_quote_hdr.cust_email
        LET l_order_hdr.cust_address1 = l_quote_hdr.cust_address1
        LET l_order_hdr.cust_address2 = l_quote_hdr.cust_address2
        LET l_order_hdr.cust_address3 = l_quote_hdr.cust_address3
        LET l_order_hdr.cust_postal_code = l_quote_hdr.cust_postal_code
        LET l_order_hdr.cust_vat_no = l_quote_hdr.cust_vat_no
        LET l_order_hdr.cust_payment_terms = l_quote_hdr.cust_payment_terms

        LET m_user = utils_globals.get_current_user_id()

        INSERT INTO sa31_ord_hdr VALUES(l_order_hdr.*)
        LET l_new_order_id = SQLCA.SQLERRD[2]

        -- ===========================================
        -- 3. Copy quote lines to order
        -- ===========================================
        INSERT INTO sa31_ord_det (
            hdr_id, line_no, stock_id, batch_id, qnty,
            unit_price, sell_price, vat_tot, line_tot, disc_tot,
            stock_id, item_name, uom, unit_price,
            disc_pct, disc_amt, gross_amt, net_amt,
            vat_rate, vat_amt, line_total, status,
            created_at, created_by
        )
        SELECT
            l_new_order_id, line_no, stock_id, batch_id, qnty,
            unit_price, sell_price, vat_tot, line_tot, disc_tot,
            stock_id, item_name, uom, unit_price,
            disc_pct, disc_amt, gross_amt, net_amt,
            vat_rate, vat_amt, line_total, status,
            CURRENT, m_user
        FROM sa30_quo_det
        WHERE hdr_id = p_quote_id

        -- ===========================================
        -- 4. Update quote status to CONVERTED
        -- ===========================================
        UPDATE sa30_quo_hdr
            SET status = "CONVERTED",
                updated_at = CURRENT
            WHERE id = p_quote_id

        COMMIT WORK

        CALL utils_globals.show_success(
            SFMT("Quote #%1 converted to Order #%2",
                 l_quote_hdr.doc_no, l_new_order_doc_no))

        -- Update module record
        LET m_qt_hdr_rec.status = "CONVERTED"
        DISPLAY BY NAME m_qt_hdr_rec.status

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to convert quote: %1", SQLCA.SQLCODE))
    END TRY

END FUNCTION

-- ==============================================================
-- Function : view_linked_order (NEW)
-- ==============================================================
FUNCTION view_linked_order(p_quote_doc_no INTEGER)
    DEFINE l_order_id INTEGER
    DEFINE l_order_doc_no INTEGER

    SELECT id, doc_no INTO l_order_id, l_order_doc_no
      FROM sa31_ord_hdr
     WHERE ref_doc_type = "QUOTE"
       AND ref_doc_no = p_quote_doc_no

    IF SQLCA.SQLCODE = 0 THEN
        CALL utils_globals.show_info(
            SFMT("This quote was converted to Order #%1", l_order_doc_no))
        -- TODO: Call order view function if available
        -- CALL sa131_order.load_order(l_order_id)
    ELSE
        CALL utils_globals.show_info("No linked order found")
    END IF

END FUNCTION

-- ==============================================================
-- Function : prompt_edit_choice
-- ==============================================================
FUNCTION prompt_edit_choice() RETURNS SMALLINT
    DEFINE choice SMALLINT

    MENU "Edit Quote"
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
-- Function : edit_qt_header
-- ==============================================================
FUNCTION edit_qt_header(p_doc_id INTEGER)
    DEFINE new_hdr RECORD LIKE sa30_quo_hdr.*

    LET new_hdr.* = m_qt_hdr_rec.*

    DIALOG
        INPUT BY NAME new_hdr.id, new_hdr.trans_date,
                      new_hdr.ref_no
            ATTRIBUTES(WITHOUT DEFAULTS)

            AFTER FIELD id
                IF new_hdr.id IS NOT NULL THEN
                    CALL load_customer_details(new_hdr.id)
                        RETURNING new_hdr.cust_id, new_hdr.cust_name,
                                  new_hdr.cust_id,
                                  new_hdr.cust_phone, new_hdr.cust_email,
                                  new_hdr.cust_address1,
                                  new_hdr.cust_address2, new_hdr.cust_address3,
                                  new_hdr.cust_postal_code, new_hdr.cust_vat_no,
                                  new_hdr.cust_payment_terms
                END IF

            ON ACTION save ATTRIBUTES(TEXT="Save", IMAGE="save")

                BEGIN WORK
                TRY
                    UPDATE sa30_quo_hdr
                        SET id = new_hdr.id,
                            trans_date = new_hdr.trans_date,
                            ref_no = new_hdr.ref_no,
                            cust_id = new_hdr.cust_id,
                            cust_name = new_hdr.cust_name,
                            cust_id = new_hdr.cust_id,
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

                    LET m_qt_hdr_rec.* = new_hdr.*

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
-- Function : edit_qt_lines
-- ==============================================================
FUNCTION edit_qt_lines(p_doc_id INTEGER)
    DIALOG
        DISPLAY ARRAY m_qt_lines_arr TO arr_sa_qt_lines.*
            BEFORE DISPLAY
                CALL DIALOG.setActionHidden("accept", TRUE)

            ON ACTION add ATTRIBUTES(TEXT="Add Line", IMAGE="new")
                CALL edit_or_add_qt_line(p_doc_id, 0, TRUE)
                CALL calculate_quote_totals()

            ON ACTION edit ATTRIBUTES(TEXT="Edit Line", IMAGE="pen")
                IF arr_curr() > 0 THEN
                    CALL edit_or_add_qt_line(p_doc_id, arr_curr(), FALSE)
                    CALL calculate_quote_totals()
                END IF

            ON ACTION delete ATTRIBUTES(TEXT="Delete", IMAGE="delete")
                IF arr_curr() > 0 THEN
                    CALL delete_qt_line(p_doc_id, arr_curr())
                    CALL calculate_quote_totals()
                END IF

            ON ACTION save ATTRIBUTES(TEXT="Save", IMAGE="save")
                CALL save_qt_lines(p_doc_id)
                CALL save_quote_header_totals()
                CALL utils_globals.show_success("Changes saved")
                EXIT DIALOG

            ON ACTION cancel
                EXIT DIALOG
        END DISPLAY
    END DIALOG
END FUNCTION

-- ==============================================================
-- Function : save_quote
-- ==============================================================
FUNCTION save_quote()
    DEFINE exists INTEGER

    BEGIN WORK
    TRY
        SELECT COUNT(*) INTO exists FROM sa30_quo_hdr WHERE id = m_qt_hdr_rec.id

        IF exists = 0 THEN
            INSERT INTO sa30_quo_hdr VALUES m_qt_hdr_rec.*
            CALL utils_globals.show_success("Quote saved")
        ELSE
            UPDATE sa30_quo_hdr
                SET doc_no = m_qt_hdr_rec.doc_no,
                    id = m_qt_hdr_rec.id,
                    trans_date = m_qt_hdr_rec.trans_date,
                    gross_tot = m_qt_hdr_rec.gross_tot,
                    disc_tot = m_qt_hdr_rec.disc_tot,
                    vat_tot = m_qt_hdr_rec.vat_tot,
                    net_tot = m_qt_hdr_rec.net_tot,
                    status = m_qt_hdr_rec.status,
                    updated_at = CURRENT
                WHERE id = m_qt_hdr_rec.id
            CALL utils_globals.show_success("Quote updated")
        END IF

        -- Save lines
        CALL save_qt_lines(m_qt_hdr_rec.id)

        COMMIT WORK

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Save failed: %1", SQLCA.SQLCODE))
    END TRY

END FUNCTION

-- ==============================================================
-- Function : delete_quote
-- ==============================================================
FUNCTION delete_quote(p_doc_id INTEGER)
    DEFINE ok SMALLINT
    DEFINE l_status VARCHAR(10)
    DEFINE l_doc_no INTEGER
    DEFINE l_order_count INTEGER

    IF p_doc_id IS NULL THEN
        CALL utils_globals.show_info("No quote selected for deletion.")
        RETURN
    END IF

    -- ===========================================
    -- Check if quote can be deleted
    -- ===========================================

    -- Get quote details
    SELECT status, doc_no INTO l_status, l_doc_no
      FROM sa30_quo_hdr
     WHERE id = p_doc_id

    -- Check status
    IF l_status = "CONVERTED" THEN
        CALL utils_globals.show_error(
            "Cannot delete converted quotes. Status: " || l_status)
        RETURN
    END IF

    -- Check for linked orders
    SELECT COUNT(*) INTO l_order_count
      FROM sa31_ord_hdr
     WHERE ref_doc_type = "QUOTE"
       AND ref_doc_no = l_doc_no

    IF l_order_count > 0 THEN
        CALL utils_globals.show_error(
            SFMT("Cannot delete quote - it has %1 linked order(s)", l_order_count))
        RETURN
    END IF

    -- Confirm deletion
    LET ok = utils_globals.show_confirm(
        SFMT("Delete Quote #%1?", l_doc_no), "Confirm Delete")

    IF NOT ok THEN
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    -- Delete quote
    BEGIN WORK
    TRY
        DELETE FROM sa30_quo_det WHERE hdr_id = p_doc_id
        DELETE FROM sa30_quo_hdr WHERE id = p_doc_id

        COMMIT WORK
        CALL utils_globals.show_success("Quote deleted")

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Delete failed: %1", SQLCA.SQLCODE))
    END TRY

END FUNCTION

-- ==============================================================
-- Function : move_record (Navigation custort)
-- ==============================================================
FUNCTION move_record(dir SMALLINT)
    DEFINE new_idx INTEGER

    IF m_arr_codes.getLength() == 0 THEN
        CALL utils_globals.show_info("No records to navigate.")
        RETURN
    END IF

    LET new_idx = utils_globals.navigate_records(m_arr_codes, m_curr_idx, dir)
    LET m_curr_idx = new_idx
    CALL load_quote(m_arr_codes[m_curr_idx])
END FUNCTION
