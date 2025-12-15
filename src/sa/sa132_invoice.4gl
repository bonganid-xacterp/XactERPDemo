-- ==============================================================
-- Program   : sa132_invoice.4gl
-- Purpose   : Sales Invoice Program
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
IMPORT FGL utils_global_stock_updater

SCHEMA demoappdb

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE invoice_hdr_t RECORD LIKE sa32_inv_hdr.*

DEFINE m_inv_hdr_rec invoice_hdr_t

DEFINE m_debt_rec RECORD LIKE dl01_mast.*
DEFINE m_inv_lines_arr DYNAMIC ARRAY OF RECORD LIKE sa32_inv_det.*

DEFINE m_arr_codes DYNAMIC ARRAY OF STRING
DEFINE m_curr_idx INTEGER
DEFINE m_is_edit SMALLINT

DEFINE g_hdr_saved SMALLINT

-- ==============================================================
-- Init Program
-- ==============================================================
FUNCTION init_inv_module()
    LET m_is_edit = FALSE
    INITIALIZE m_debt_rec.* TO NULL
    
    DISPLAY BY NAME m_debt_rec.*
        
    MENU "Invoice Menu"
        COMMAND "Find"
           CALL find_inv();
            LET m_is_edit = FALSE
        COMMAND "New"
            CALL new_invoice()
        COMMAND "Edit"
            IF m_debt_rec.id IS NULL OR m_debt_rec.id = 0 THEN
                CALL utils_globals.show_info("No record selected.")
            ELSE
                --CALL prompt_edit_choice( m_debt_rec.id)
            END IF
        COMMAND "Delete"
            CALL delete_invoice(m_debt_rec.id)
        COMMAND "Previous"
            CALL move_record(-1)
        COMMAND "Next"
            CALL move_record(1)

        COMMAND "Exit"
            EXIT MENU
    END MENU
END FUNCTION


-- ==============================================================
-- Find (simple lookup by doc_no)
-- ==============================================================
FUNCTION find_inv()
    DEFINE l_id INTEGER
    PROMPT "Enter Inv Number: " FOR l_id
    IF INT_FLAG OR l_id IS NULL THEN
        LET INT_FLAG = FALSE
        RETURN
    END IF

    INITIALIZE m_inv_hdr_rec.* TO NULL
    TRY
        SELECT * INTO m_inv_hdr_rec.* FROM sa32_inv_hdr WHERE id = l_id
    CATCH
        CALL utils_globals.show_sql_error("find_po: Find by doc_no failed")
        RETURN
    END TRY

    IF SQLCA.SQLCODE = NOTFOUND THEN
        CALL utils_globals.show_info(SFMT("Invoice %1 not found.", l_id))
        RETURN
    END IF

    DISPLAY BY NAME m_inv_hdr_rec.*
END FUNCTION

-- ==============================================================
-- Function : new_invoice (NEW - Header first, then lines)
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
    LET l_hdr.vat_tot = 0
    LET l_hdr.disc_tot = 0
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
                --CALL inv_load_customer_details(l_hdr.cust_id)
                --    RETURNING l_hdr.cust_id, l_hdr.cust_name,
                --              l_hdr.cust_phone, l_hdr.cust_email, l_hdr.cust_address1,
                --              l_hdr.cust_address2, l_hdr.cust_address3,
                --              l_hdr.cust_postal_code, l_hdr.cust_vat_no,
                --              l_hdr.cust_payment_terms

                IF l_hdr.cust_id IS NULL THEN
                    CALL utils_globals.show_error("Customer not found")
                    NEXT FIELD cust_id
                END IF
            END IF

        ON ACTION lookup_customer ATTRIBUTES(TEXT="Customer Lookup", IMAGE="zoom")
            CALL dl121_lkup.load_lookup_form_with_search() RETURNING l_hdr.cust_id
            IF l_hdr.cust_id IS NOT NULL THEN
                --CALL inv_load_customer_details(l_hdr.cust_id)
                --    RETURNING l_hdr.cust_id, l_hdr.cust_name,
                --              l_hdr.cust_phone, l_hdr.cust_email, l_hdr.cust_address1,
                --              l_hdr.cust_address2, l_hdr.cust_address3,
                --              l_hdr.cust_postal_code, l_hdr.cust_vat_no,
                --              l_hdr.cust_payment_terms
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
    LET m_inv_hdr_rec.* = l_hdr.*
    CALL m_inv_lines_arr.clear()

    CALL input_invoice_lines(l_new_hdr_id)

    -- ==========================================================
    -- 6. Load the complete invoice for viewing
    -- ==========================================================
    CALL load_invoice(l_new_hdr_id)

END FUNCTION

--===============================================================
-- Create new Invoice form master
--===============================================================

-- ==============================================================
-- Create new po header from master
-- ==============================================================
FUNCTION new_inv_from_master(p_cust_id INTEGER)
    DEFINE row_idx INTEGER
    DEFINE sel_code INTEGER
    
    CALL populate_doc_header(p_cust_id)

    LET sel_code = st121_st_lkup.fetch_list()

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME m_inv_hdr_rec.* ATTRIBUTES(WITHOUT DEFAULTS)

            ON ACTION save_header ATTRIBUTES(TEXT = "Save Header")
                IF NOT validate_inv_header() THEN
                    CALL utils_globals.show_error("Please fix required fields.")
                    CONTINUE DIALOG
                END IF

                IF NOT save_inv_header() THEN
                    CALL utils_globals.show_error("Save failed.")
                    CONTINUE DIALOG
                END IF

                LET g_hdr_saved = TRUE
                CALL utils_globals.show_info(
                    "Header saved. You can now add lines.")

                -- Move focus to lines array
                NEXT FIELD stock_id
                CONTINUE DIALOG
        END INPUT

        INPUT ARRAY m_inv_lines_arr
            FROM po_lines_arr.*
            ATTRIBUTES(INSERT ROW = TRUE, DELETE ROW = TRUE, APPEND ROW = TRUE)
            BEFORE INPUT
                IF NOT g_hdr_saved THEN
                    CALL utils_globals.show_info(
                        "Please save header first before adding lines.")
                END IF

            BEFORE ROW
                LET row_idx = DIALOG.getCurrentRow("po_lines_arr")

            BEFORE FIELD stock_id
                IF NOT g_hdr_saved THEN
                    CALL utils_globals.show_error(
                        "Please save header first before adding lines.")
                    NEXT FIELD CURRENT
                END IF

            BEFORE INSERT
                IF NOT g_hdr_saved THEN
                    CALL utils_globals.show_error(
                        "Please save header first before adding lines.")
                    CANCEL INSERT
                END IF
                LET m_inv_lines_arr[row_idx].hdr_id = m_inv_hdr_rec.id
                LET m_inv_lines_arr[row_idx].status = "active"
                LET m_inv_lines_arr[row_idx].created_at = TODAY
                LET m_inv_lines_arr[row_idx].created_by = m_inv_hdr_rec.created_by

            AFTER INSERT
                -- Renumber lines after insert
                --CALL renumber_lines()

            ON ACTION row_select
                ATTRIBUTES(TEXT = "Add Line", IMAGE = "add", DEFAULTVIEW = YES)
                LET row_idx = DIALOG.getCurrentRow("po_lines_arr")
                --CALL populate_line_from_lookup(row_idx)
                CONTINUE DIALOG

            ON ACTION stock_lookup
                ATTRIBUTES(TEXT = "Stock Lookup",
                    IMAGE = "zoom",
                    DEFAULTVIEW = YES)

                 LET row_idx = DIALOG.getCurrentRow("po_lines_arr")

                         
                IF sel_code IS NOT NULL AND sel_code != "" THEN
                    LET m_inv_lines_arr[row_idx].stock_id = sel_code
                    --CALL load_stock_details(row_idx)
                    DISPLAY m_inv_lines_arr[row_idx].*
                        TO m_inv_lines_arr[row_idx].*
                END IF
                CONTINUE DIALOG

            AFTER FIELD stock_id
                IF m_inv_lines_arr[row_idx].stock_id IS NOT NULL THEN
                    --CALL load_stock_details(row_idx)
                END IF
--
--            AFTER FIELD qnty, unit_price, disc_pct, vat_rate
--                CALL calculate_line_totals(row_idx)

            ON ACTION save_lines ATTRIBUTES(TEXT = "Save Lines", IMAGE = "save")
                IF m_inv_lines_arr.getLength() > 0 THEN
                    CALL save_invoice_lines(m_debt_rec.id)
                    CALL utils_globals.show_info("Lines saved successfully.")
                ELSE
                    CALL utils_globals.show_info("No lines to save.")
                END IF
                CONTINUE DIALOG

            ON ACTION delete_line
                ATTRIBUTES(TEXT = "Delete Line", IMAGE = "delete")
                IF row_idx > 0 AND row_idx <= m_inv_lines_arr.getLength() THEN
                    CALL m_inv_lines_arr.deleteElement(row_idx)
                    --CALL renumber_lines()
                    CALL recalculate_header_totals()
                    CALL utils_globals.show_info("Line deleted.")
                END IF
                CONTINUE DIALOG

            AFTER DELETE
                -- Renumber lines after delete
                --CALL renumber_lines()
        END INPUT

        ON ACTION CANCEL ATTRIBUTES(TEXT = "Exit")
            EXIT DIALOG
    END DIALOG

    CLOSE WINDOW w_pu130
END FUNCTION


-- ==============================================================
-- Populate the document header
-- ==============================================================
FUNCTION populate_doc_header(p_cust_id INTEGER)
    DEFINE l_cust_id INTEGER

    LET l_cust_id = p_cust_id

    -- load customer data
    TRY
        SELECT * INTO m_debt_rec.* FROM dl01_mast WHERE id = l_cust_id
    CATCH
        CALL utils_globals.show_sql_error("populate_doc_header: Error loading customer")
        RETURN
    END TRY

    OPTIONS INPUT WRAP -- Prevent program from exiting when tabbing out of the last input field
    OPEN WINDOW w_pu130 WITH FORM "pu130_order" -- ATTRIBUTES(STYLE = "normal")

    INITIALIZE m_inv_hdr_rec.* TO NULL
    CALL m_inv_lines_arr.clear()

    -- Set the next doc number to be last doc number + 1
    LET m_inv_hdr_rec.doc_no = utils_globals.get_next_code('sa32_inv_hdr', 'id')
    LET m_inv_hdr_rec.trans_date = TODAY
    LET m_inv_hdr_rec.status = "draft"
    LET m_inv_hdr_rec.created_at = TODAY -- FIXED: Changed from CURRENT
    LET m_inv_hdr_rec.created_by = utils_globals.get_current_user_id()

    -- link supplier
    LET m_inv_hdr_rec.cust_id = m_debt_rec.id
    LET m_inv_hdr_rec.cust_name = m_debt_rec.cust_name
    LET m_inv_hdr_rec.cust_phone = m_debt_rec.phone
    LET m_inv_hdr_rec.cust_email = m_debt_rec.email
    LET m_inv_hdr_rec.cust_address1 = m_debt_rec.address1
    LET m_inv_hdr_rec.cust_address2 = m_debt_rec.address2
    LET m_inv_hdr_rec.cust_address3 = m_debt_rec.address3
    LET m_inv_hdr_rec.cust_postal_code = m_debt_rec.postal_code
    LET m_inv_hdr_rec.cust_vat_no = m_debt_rec.vat_no
    LET m_inv_hdr_rec.cust_payment_terms = m_debt_rec.payment_terms
    LET m_inv_hdr_rec.gross_tot = 0.00
    LET m_inv_hdr_rec.disc_tot = 0.00
    LET m_inv_hdr_rec.vat_tot = 0.00
    LET m_inv_hdr_rec.net_tot = 0.00

    LET g_hdr_saved = FALSE
    
END FUNCTION 

-- ==============================================================
-- Calculate line totals
-- ==============================================================
PRIVATE FUNCTION calculate_line_totals(p_idx INTEGER)
    DEFINE l_gross DECIMAL(12, 2)
    DEFINE l_disc DECIMAL(12, 2)
    DEFINE l_vat DECIMAL(12, 2)
    DEFINE l_net DECIMAL(12, 2)

    -- Initialize defaults
    IF m_inv_lines_arr[p_idx].qnty IS NULL THEN
        LET m_inv_lines_arr[p_idx].qnty = 0
    END IF
    IF m_inv_lines_arr[p_idx].unit_price IS NULL THEN
        LET m_inv_lines_arr[p_idx].unit_price = 0
    END IF
    IF m_inv_lines_arr[p_idx].disc_pct IS NULL THEN
        LET m_inv_lines_arr[p_idx].disc_pct = 0
    END IF
    IF m_inv_lines_arr[p_idx].vat_rate IS NULL THEN
        LET m_inv_lines_arr[p_idx].vat_rate = 0
    END IF

    -- Calculate gross amount
    LET l_gross = m_inv_lines_arr[p_idx].qnty * m_inv_lines_arr[p_idx].unit_price
    LET m_inv_lines_arr[p_idx].gross_amt = l_gross

    -- Calculate discount
    LET l_disc = l_gross * (m_inv_lines_arr[p_idx].disc_pct / 100)
    LET m_inv_lines_arr[p_idx].disc_amt = l_disc

    -- Calculate net before VAT
    LET l_net = l_gross - l_disc
    LET m_inv_lines_arr[p_idx].net_excl_amt = l_net

    -- Calculate VAT
    LET l_vat = l_net * (m_inv_lines_arr[p_idx].vat_rate / 100)
    LET m_inv_lines_arr[p_idx].vat_amt = l_vat

    -- Calculate line total (net + VAT)
    LET m_inv_lines_arr[p_idx].line_total = l_net + l_vat

    -- Recalculate header totals
    CALL recalculate_header_totals()
END FUNCTION

-- ==============================================================
-- Recalculate header totals from all lines
-- ==============================================================
PRIVATE FUNCTION recalculate_header_totals()
    DEFINE i INTEGER
    DEFINE l_gross_tot DECIMAL(12, 2)
    DEFINE l_disc_tot DECIMAL(12, 2)
    DEFINE l_vat_tot DECIMAL(12, 2)
    DEFINE l_net_tot DECIMAL(12, 2)

    LET l_gross_tot = 0
    LET l_disc_tot = 0
    LET l_vat_tot = 0
    LET l_net_tot = 0

    FOR i = 1 TO m_inv_lines_arr.getLength()
        IF m_inv_lines_arr[i].gross_amt IS NOT NULL THEN
            LET l_gross_tot = l_gross_tot + m_inv_lines_arr[i].gross_amt
        END IF
        IF m_inv_lines_arr[i].disc_amt IS NOT NULL THEN
            LET l_disc_tot = l_disc_tot + m_inv_lines_arr[i].disc_amt
        END IF
        IF m_inv_lines_arr[i].vat_amt IS NOT NULL THEN
            LET l_vat_tot = l_vat_tot + m_inv_lines_arr[i].vat_amt
        END IF
        IF m_inv_lines_arr[i].line_total IS NOT NULL THEN
            LET l_net_tot = l_net_tot + m_inv_lines_arr[i].line_total
        END IF
    END FOR

    LET m_inv_hdr_rec.gross_tot = l_gross_tot
    LET m_inv_hdr_rec.disc_tot = l_disc_tot
    LET m_inv_hdr_rec.vat_tot = l_vat_tot
    LET m_inv_hdr_rec.net_tot = l_net_tot

    DISPLAY BY NAME m_inv_hdr_rec.gross_tot,
        m_inv_hdr_rec.disc_tot,
        m_inv_hdr_rec.vat_tot,
        m_inv_hdr_rec.net_tot
END FUNCTION


-- ==============================================================
-- Function : input_invoice_lines (NEW)
-- ==============================================================
FUNCTION input_invoice_lines(p_hdr_id INTEGER)

    OPEN WINDOW w_invoice_lines WITH FORM "sa132_invoice" ATTRIBUTES(STYLE="dialog")

    CALL utils_globals.set_form_label("lbl_form_title",
        SFMT("Invoice #%1 - Add Lines", m_inv_hdr_rec.doc_no))

    DISPLAY BY NAME m_inv_hdr_rec.*

    DIALOG ATTRIBUTES(UNBUFFERED)

        DISPLAY ARRAY m_inv_lines_arr TO arr_sa_inv_lines.*
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
                    CALL delete_invoice_line(arr_curr())
                    CALL calculate_invoice_totals()
                END IF

            ON ACTION save ATTRIBUTES(TEXT="Save Lines", IMAGE="save")
                CALL save_invoice_lines(p_hdr_id)
                CALL save_invoice_header_totals()
                CALL utils_globals.show_success("Invoice lines saved successfully.")
                EXIT DIALOG

            ON ACTION close ATTRIBUTES(TEXT="Close", IMAGE="exit")
                IF m_inv_lines_arr.getLength() > 0 THEN
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
        LET l_line.line_no = m_inv_lines_arr.getLength() + 1
        LET l_line.vat_rate = 15.00
        LET l_line.disc_pct = 0
        LET l_line.status = 1
        LET l_line.created_at = CURRENT
        LET l_line.created_by = utils_globals.get_current_user_id()
    ELSE
        -- Load from existing array line
        LET l_line.* = m_inv_lines_arr[p_row].*
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
            CALL st121_st_lkup.fetch_list() RETURNING l_stock_id

            IF l_stock_id IS NOT NULL AND l_stock_id > 0 THEN
                LET l_line.stock_id = l_stock_id

                -- Load stock defaults

                LET l_line.item_name = l_item_desc

                DISPLAY BY NAME l_line.stock_id, l_line.unit_price, l_line.item_name

                NEXT FIELD qnty
            END IF

        AFTER FIELD qnty, unit_cost, disc_pct, vat_rate
                IF p_row > 0 AND p_row <= m_inv_lines_arr.getLength() THEN
                    CALL calculate_line_totals(p_row)
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
                LET m_inv_lines_arr[m_inv_lines_arr.getLength() + 1].* = l_line.*
            ELSE
                LET m_inv_lines_arr[p_row].* = l_line.*
            END IF

            CALL utils_globals.show_success("Line saved")
            EXIT INPUT

        ON ACTION cancel
            EXIT INPUT
    END INPUT

    CLOSE WINDOW w_line_edit

END FUNCTION


-- ==============================================================
-- Save: insert or update
-- ==============================================================
FUNCTION save_inv_header() RETURNS SMALLINT
    DEFINE ok SMALLINT
    BEGIN WORK
    TRY

        DISPLAY m_inv_hdr_rec.*
        IF m_inv_hdr_rec.id IS NULL THEN
            INSERT INTO sa32_inv_hdr VALUES m_inv_hdr_rec.*
            LET m_inv_hdr_rec.id = SQLCA.SQLERRD[2]
            CALL utils_globals.msg_saved()

        ELSE
            LET m_inv_hdr_rec.updated_at = TODAY
            UPDATE sa32_inv_hdr
                SET sa32_inv_hdr.* = m_inv_hdr_rec.*
                WHERE id = m_inv_hdr_rec.id
            IF SQLCA.SQLCODE = 0 THEN
                CALL utils_globals.msg_updated()
            END IF
        END IF
        COMMIT WORK
        LET ok = (m_inv_hdr_rec.id IS NOT NULL)
        RETURN ok
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_sql_error("save_header: Save failed")
        RETURN FALSE
    END TRY

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
        WHERE id = p_stock_id

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
FUNCTION delete_invoice_line( p_row INTEGER)
    IF p_row > 0 THEN
        IF utils_globals.show_confirm(
            SFMT("Delete line %1?", p_row), "Confirm Delete") THEN
            CALL m_inv_lines_arr.deleteElement(p_row)
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

        FOR i = 1 TO m_inv_lines_arr.getLength()
            -- Ensure hdr_id is set
            LET m_inv_lines_arr[i].hdr_id = p_doc_id
            INSERT INTO sa32_inv_det VALUES m_inv_lines_arr[i].*
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

    FOR i = 1 TO m_inv_lines_arr.getLength()
        LET l_gross = l_gross + NVL(m_inv_lines_arr[i].gross_amt, 0)
        LET l_disc_tot = l_disc_tot + NVL(m_inv_lines_arr[i].disc_amt, 0)
        LET l_vat_tot = l_vat_tot + NVL(m_inv_lines_arr[i].vat_amt, 0)
    END FOR

    LET l_net = l_gross - l_disc_tot + l_vat_tot

    LET m_inv_hdr_rec.gross_tot = l_gross
    LET m_inv_hdr_rec.disc_tot = l_disc_tot
    LET m_inv_hdr_rec.vat_tot = l_vat_tot
    LET m_inv_hdr_rec.net_tot = l_net

    DISPLAY BY NAME m_inv_hdr_rec.gross_tot, m_inv_hdr_rec.disc_tot,
                     m_inv_hdr_rec.vat_tot, m_inv_hdr_rec.net_tot

    MESSAGE SFMT("Totals: Gross=%1, disc_amt=%2, vat_tot=%3, Net=%4",
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
            SET gross_tot = m_inv_hdr_rec.gross_tot,
                disc_tot = m_inv_hdr_rec.disc_tot,
                vat_tot = m_inv_hdr_rec.vat_tot,
                net_tot = m_inv_hdr_rec.net_tot,
                updated_at = CURRENT
            WHERE id = m_inv_hdr_rec.id

        COMMIT WORK

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to update totals: %1", SQLCA.SQLCODE))
    END TRY

END FUNCTION

-- ==============================================================
-- Function : inv_load_customer_details (NEW)
-- ==============================================================
--FUNCTION inv_inv_load_customer_details(p_cust_id INTEGER)
--    RETURNS (INTEGER, VARCHAR(100), VARCHAR(20), VARCHAR(100),
--             VARCHAR(100), VARCHAR(100), VARCHAR(100), VARCHAR(10),
--             VARCHAR(20), VARCHAR(50))
--
--    DEFINE l_cust_id INTEGER
--    DEFINE l_cust_name VARCHAR(100)
--    DEFINE l_phone VARCHAR(20)
--    DEFINE l_email VARCHAR(100)
--    DEFINE l_addr1 VARCHAR(100)
--    DEFINE l_addr2 VARCHAR(100)
--    DEFINE l_addr3 VARCHAR(100)
--    DEFINE l_postal VARCHAR(10)
--    DEFINE l_vat VARCHAR(20)
--    DEFINE l_terms VARCHAR(50)
--
--    SELECT id, cust_name, cust_id, phone, email,
--           address1, address2, address3, postal_code,
--           vat_no, payment_terms
--        INTO l_cust_id, l_cust_name,l_phone, l_email,
--             l_addr1, l_addr2, l_addr3, l_postal, l_vat, l_terms
--        FROM dl01_mast
--        WHERE cust_id = p_cust_id
--
--    IF SQLCA.SQLCODE = 0 THEN
--        MESSAGE SFMT("Customer: %1", l_cust_name)
--        RETURN l_cust_id, l_cust_name, l_phone, l_email,
--               l_addr1, l_addr2, l_addr3, l_postal, l_vat, l_terms
--    ELSE
--        RETURN NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
--    END IF
--
--END FUNCTION

-- ==============================================================
-- Function : load_invoice (with status checks)
-- ==============================================================
FUNCTION load_invoice(p_doc_id INTEGER)
    DEFINE idx INTEGER
    DEFINE user_choice SMALLINT
    DEFINE l_can_edit SMALLINT

    OPTIONS INPUT WRAP

    -- Open window and attach the form
    OPEN WINDOW w_inv WITH FORM "sa132_invoice" ATTRIBUTES(STYLE = "dialog")

    -- Initialize variables
    INITIALIZE m_inv_hdr_rec.* TO NULL
    CALL m_inv_lines_arr.clear()

    -- ==========================================================
    -- Load header record
    -- ==========================================================
    SELECT * INTO m_inv_hdr_rec.*
      FROM sa32_inv_hdr
     WHERE id = p_doc_id

    IF SQLCA.SQLCODE = 0 THEN
        -- ===========================================
        -- Check if invoice can be edited
        -- ===========================================
        LET l_can_edit = can_edit_invoice(m_inv_hdr_rec.status)

        -- ======================================================
        -- Load invoice line items
        -- ======================================================
        LET idx = 0

        DECLARE inv_lines_cur CURSOR FOR
            SELECT *
              FROM sa32_inv_det
             WHERE hdr_id = p_doc_id
             ORDER BY line_no

        FOREACH inv_lines_cur INTO m_inv_lines_arr[idx + 1].*
            LET idx = idx + 1
        END FOREACH

        CLOSE inv_lines_cur
        FREE inv_lines_cur

        -- ======================================================
        -- Display header and lines
        -- ======================================================
        CALL utils_globals.set_form_label("lbl_form_title",
            SFMT("Sales Invoice #%1 - Status: %2", m_inv_hdr_rec.doc_no, m_inv_hdr_rec.status))

        DISPLAY BY NAME m_inv_hdr_rec.*

        -- DISPLAY ARRAY m_inv_lines_arr TO arr_sa_inv_lines.*
        DISPLAY ARRAY m_inv_lines_arr TO arr_sa_inv_lines.*

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
                        "Cannot edit invoice with status: " || m_inv_hdr_rec.status)
                    CONTINUE DISPLAY
                END IF

                LET user_choice = prompt_edit_choice()

                CASE user_choice
                    WHEN 1
                        CALL edit_invoice_header(p_doc_id)
                        DISPLAY BY NAME m_inv_hdr_rec.* -- Refresh header
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
FUNCTION can_edit_invoice(p_status VARCHAR(10))
    RETURNS SMALLINT

    -- Check status
    IF p_status = "POSTED" OR p_status = "PAID" OR p_status = "CANCELLED" THEN
        RETURN FALSE
    END IF

    RETURN TRUE

END FUNCTION

-- ==============================================================
-- Function : post_invoice (NEW - CRITICAL)
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
            IF NOT utils_global_stock_updater.update_stock_simple(l_stock_id, l_quantity, "OUT", 'SA_INV') THEN
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
        LET m_inv_hdr_rec.status = "POSTED"
        DISPLAY BY NAME m_inv_hdr_rec.status

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to post invoice: %1", SQLCA.SQLCODE))
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
-- Function : edit_invoice_header (UPDATE syntax)
-- ==============================================================
FUNCTION edit_invoice_header(p_doc_id INTEGER)
    DEFINE new_hdr RECORD LIKE sa32_inv_hdr.*

    LET new_hdr.* = m_inv_hdr_rec.*

    DIALOG
        INPUT BY NAME new_hdr.cust_id, new_hdr.trans_date,
                      new_hdr.due_date,
                      new_hdr.ref_doc_type, new_hdr.ref_doc_no
            ATTRIBUTES(WITHOUT DEFAULTS)

            AFTER FIELD cust_id
                IF new_hdr.cust_id IS NOT NULL THEN
                    --CALL inv_load_customer_details(new_hdr.cust_id)
                    --    RETURNING new_hdr.cust_id, new_hdr.cust_name,
                    --              new_hdr.cust_phone, new_hdr.cust_email,
                    --              new_hdr.cust_address1,
                    --              new_hdr.cust_address2, new_hdr.cust_address3,
                    --              new_hdr.cust_postal_code, new_hdr.cust_vat_no,
                    --              new_hdr.cust_payment_terms
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

                    LET m_inv_hdr_rec.* = new_hdr.*

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
        DISPLAY ARRAY m_inv_lines_arr TO arr_sa_inv_lines.*
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
                    CALL delete_invoice_line(arr_curr())
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
-- Function : save_invoice (Legacy)
-- ==============================================================
FUNCTION save_invoice()
    DEFINE exists INTEGER

    BEGIN WORK
    TRY
        SELECT COUNT(*) INTO exists FROM sa32_inv_hdr WHERE id = m_inv_hdr_rec.id

        IF exists = 0 THEN
            INSERT INTO sa32_inv_hdr VALUES m_inv_hdr_rec.*
            CALL utils_globals.show_success("Invoice saved")
        ELSE
            UPDATE sa32_inv_hdr
                SET doc_no = m_inv_hdr_rec.doc_no,
                    cust_id = m_inv_hdr_rec.cust_id,
                    trans_date = m_inv_hdr_rec.trans_date,
                    due_date = m_inv_hdr_rec.due_date,
                    gross_tot = m_inv_hdr_rec.gross_tot,
                    disc_tot = m_inv_hdr_rec.disc_tot,
                    vat_tot = m_inv_hdr_rec.vat_tot,
                    net_tot = m_inv_hdr_rec.net_tot,
                    status = m_inv_hdr_rec.status,
                    updated_at = CURRENT
                WHERE id = m_inv_hdr_rec.id
            CALL utils_globals.show_success("Invoice updated")
        END IF

        -- Save lines
        CALL save_invoice_lines(m_inv_hdr_rec.id)

        COMMIT WORK

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Save failed: %1", SQLCA.SQLCODE))
    END TRY

END FUNCTION

-- ==============================================================
-- Function : delete_invoice (with protections)
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


-- ==============================================================
-- Validation
-- ==============================================================
FUNCTION validate_inv_header() RETURNS SMALLINT
    IF m_inv_hdr_rec.trans_date IS NULL THEN
        RETURN FALSE
    END IF
    IF m_inv_hdr_rec.cust_id IS NULL OR m_inv_hdr_rec.cust_id = 0 THEN
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION
