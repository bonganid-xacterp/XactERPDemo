-- ==============================================================
-- Program   : sa130_quote.4gl (Slim CRUD Header + Lines)
-- Purpose   : Sales Quote Header CRUD + Navigate
-- Module    : Sales (sa)
-- Author    : Bongani Dlamini
-- Version   : Genero 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL st121_st_lkup
IMPORT FGL utils_doc_totals
IMPORT FGL utils_global_lkup
IMPORT FGL dl121_lkup

SCHEMA demoappdb

GLOBALS
    DEFINE g_hdr_saved SMALLINT
END GLOBALS

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE qt_hdr_t RECORD LIKE sa30_quo_hdr.*
TYPE qt_det_t DYNAMIC ARRAY OF RECORD LIKE sa30_quo_det.*
TYPE cust_t RECORD LIKE dl01_mast.*

DEFINE m_qt_hdr_rec qt_hdr_t
DEFINE m_qt_lines_arr qt_det_t
DEFINE m_cust_rec cust_t

DEFINE arr_codes DYNAMIC ARRAY OF STRING 
DEFINE curr_idx SMALLINT
DEFINE is_edit SMALLINT
DEFINE m_timestamp DATETIME YEAR TO SECOND

-- ==============================================================
-- Controller: minimal dialog with CRUD + navigate
-- ==============================================================
FUNCTION init_qt_module()
    LET is_edit = FALSE
    INITIALIZE m_qt_hdr_rec.* TO NULL
    CALL m_qt_lines_arr.clear()

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME m_qt_hdr_rec.* ATTRIBUTES(WITHOUT DEFAULTS)
            BEFORE INPUT
                -- Start in read-only mode with save disabled
                CALL DIALOG.setActionHidden("save", TRUE)
                CALL DIALOG.setFieldActive("*", FALSE)
        END INPUT

        -- Add a dummy display array to keep dialog alive
        DISPLAY ARRAY m_qt_lines_arr TO arr_sa_qt_lines.*
        END DISPLAY

        ON ACTION find ATTRIBUTES(TEXT = "Find", IMAGE = "zoom")
            TRY
                CALL find_quote()
                LET is_edit = FALSE
            CATCH
                CALL utils_globals.show_error("Find quote failed: " || STATUS)
            END TRY

        ON ACTION new ATTRIBUTES(TEXT = "New", IMAGE = "new")
            CALL new_quote()
            LET is_edit = TRUE
            -- Enable editing and save button
            CALL DIALOG.setActionActive("save", TRUE)
            CALL DIALOG.setFieldActive("*", TRUE)
            NEXT FIELD cust_id

        ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
            IF m_qt_hdr_rec.id IS NULL THEN
                CALL utils_globals.show_info("Load a record first.")
            ELSE
                LET is_edit = TRUE
                -- Enable editing and save button
                CALL DIALOG.setActionActive("save", TRUE)
                CALL DIALOG.setFieldActive("*", TRUE)
                NEXT FIELD cust_id
            END IF

        ON ACTION save ATTRIBUTES(TEXT = "Save Header", IMAGE = "save")
            IF NOT validate_quote_header() THEN
                CALL utils_globals.show_error("Please fix required fields.")
                CONTINUE DIALOG
            END IF

            IF NOT save_quote_header() THEN
                CALL utils_globals.show_error("Save failed.")
                CONTINUE DIALOG
            END IF

            LET g_hdr_saved = TRUE
            CALL utils_globals.show_info("Header saved successfully.")
            LET is_edit = FALSE
            -- Return to read-only mode
            CALL DIALOG.setActionActive("save", FALSE)
            CALL DIALOG.setFieldActive("*", FALSE)

        ON ACTION delete ATTRIBUTES(TEXT = "Delete", IMAGE = "delete")
            CALL delete_quote(m_qt_hdr_rec.id)
            LET is_edit = FALSE

        ON ACTION PREVIOUS
            ATTRIBUTES(TEXT = "Previous", IMAGE = "fa-chevron-left")
            CALL move_record(-1)

        ON ACTION NEXT ATTRIBUTES(TEXT = "Next", IMAGE = "fa-chevron-right")
            CALL move_record(1)

        ON ACTION close ATTRIBUTES(TEXT = "Close", IMAGE = "fa-times")
            EXIT DIALOG

        ON ACTION cancel ATTRIBUTES(TEXT = "Cancel", IMAGE = "cancel")
            EXIT DIALOG

        ON ACTION quit ATTRIBUTES(TEXT = "Exit", IMAGE = "quit")
            EXIT DIALOG
    END DIALOG
END FUNCTION

-- ==============================================================
-- Create new quote from customer master
-- ==============================================================
FUNCTION new_qt_from_master(p_cust_id INTEGER)
    DEFINE row_idx INTEGER
    DEFINE sel_code INTEGER
    DEFINE l_edit_header SMALLINT
    DEFINE l_edit_lines SMALLINT

    -- Keep customer_id in memory
    LET l_edit_header = TRUE -- Allow header edit for new quote
    LET l_edit_lines = TRUE -- Allow lines edit for new quote

    -- Load customer data
    TRY
        SELECT * INTO m_cust_rec.* FROM dl01_mast WHERE id = p_cust_id
    CATCH
        CALL utils_globals.show_sql_error("new_qt_from_master: Customer load failed")
        RETURN
    END TRY

    IF SQLCA.SQLCODE != 0 THEN
        CALL utils_globals.show_error("Customer not found.")
        RETURN
    END IF

    OPTIONS INPUT WRAP
    OPEN WINDOW w_sa130 WITH FORM "sa130_quote"

    INITIALIZE m_qt_hdr_rec.* TO NULL
    CALL m_qt_lines_arr.clear()

    -- Initialize timestamp
    LET m_timestamp = CURRENT

    -- Set the next doc number
    LET m_qt_hdr_rec.doc_no = utils_globals.get_next_code('sa30_quo_hdr', 'id')
    LET m_qt_hdr_rec.trans_date = TODAY
    LET m_qt_hdr_rec.status = "draft"
    LET m_qt_hdr_rec.created_at = m_timestamp
    LET m_qt_hdr_rec.created_by = utils_globals.get_current_user_id()

    -- Link customer
    LET m_qt_hdr_rec.cust_id = m_cust_rec.id
    LET m_qt_hdr_rec.cust_name = m_cust_rec.cust_name
    LET m_qt_hdr_rec.cust_phone = m_cust_rec.phone
    LET m_qt_hdr_rec.cust_email = m_cust_rec.email
    LET m_qt_hdr_rec.cust_address1 = m_cust_rec.address1
    LET m_qt_hdr_rec.cust_address2 = m_cust_rec.address2
    LET m_qt_hdr_rec.cust_address3 = m_cust_rec.address3
    LET m_qt_hdr_rec.cust_postal_code = m_cust_rec.postal_code
    LET m_qt_hdr_rec.cust_vat_no = m_cust_rec.vat_no
    LET m_qt_hdr_rec.cust_payment_terms = m_cust_rec.payment_terms
    LET m_qt_hdr_rec.gross_tot = 0.00
    LET m_qt_hdr_rec.disc_tot = 0.00
    LET m_qt_hdr_rec.vat_tot = 0.00
    LET m_qt_hdr_rec.net_tot = 0.00

    LET g_hdr_saved = FALSE

    DIALOG ATTRIBUTES(UNBUFFERED)
        -- Header Dialog
        INPUT BY NAME m_qt_hdr_rec.* ATTRIBUTES(WITHOUT DEFAULTS)

            BEFORE INPUT
                -- Disable header input if not in edit mode
                IF NOT l_edit_header THEN
                    NEXT FIELD NEXT
                END IF

            ON ACTION save_header ATTRIBUTES(TEXT = "Save Header")
                IF NOT l_edit_header THEN
                    CALL utils_globals.show_error(
                        "Please use 'Amend Quote' to edit.")
                    CONTINUE DIALOG
                END IF

                IF NOT validate_quote_header() THEN
                    CALL utils_globals.show_error("Please fix required fields.")
                    CONTINUE DIALOG
                END IF

                IF NOT save_quote_header() THEN
                    CALL utils_globals.show_error("Save failed.")
                    CONTINUE DIALOG
                END IF

                LET g_hdr_saved = TRUE
                LET l_edit_header = FALSE -- Disable editing after save

                CALL utils_globals.show_info(
                    "Header saved. You can now add lines.")

                -- Move focus to lines array
                NEXT FIELD stock_id
                CONTINUE DIALOG
        END INPUT

        -- Doc Lines Dialog
        INPUT ARRAY m_qt_lines_arr FROM arr_sa_qt_lines.*

            ATTRIBUTES(INSERT ROW = TRUE, DELETE ROW = TRUE, APPEND ROW = TRUE)
            BEFORE INPUT
                IF NOT g_hdr_saved THEN
                    CALL utils_globals.show_info(
                        "Please save header first before adding lines.")
                END IF
                -- Disable lines input if not in edit mode
                IF NOT l_edit_lines THEN
                    NEXT FIELD NEXT
                END IF

            BEFORE ROW
                LET row_idx = DIALOG.getCurrentRow("arr_sa_qt_lines")

            BEFORE FIELD stock_id
                IF NOT g_hdr_saved THEN
                    CALL utils_globals.show_error(
                        "Please save header first before adding lines.")
                    NEXT FIELD CURRENT
                END IF
                IF NOT l_edit_lines THEN
                    CALL utils_globals.show_error(
                        "Please use 'Amend Quote' to edit.")
                    NEXT FIELD CURRENT
                END IF

            BEFORE INSERT
                IF NOT g_hdr_saved THEN
                    CALL utils_globals.show_error(
                        "Please save header first before adding lines.")
                    CANCEL INSERT
                END IF
                IF NOT l_edit_lines THEN
                    CALL utils_globals.show_error(
                        "Please use 'Amend Quote' to edit.")
                    CANCEL INSERT
                END IF
                LET m_qt_lines_arr[row_idx].hdr_id = m_qt_hdr_rec.id
                LET m_qt_lines_arr[row_idx].status = 1
                LET m_qt_lines_arr[row_idx].created_at = TODAY
                LET m_qt_lines_arr[row_idx].created_by = m_qt_hdr_rec.created_by

            AFTER INSERT
                -- Renumber lines after insert
                CALL renumber_lines()

            ON ACTION stock_lookup
                ATTRIBUTES(TEXT = "Stock Lookup",
                    IMAGE = "zoom",
                    DEFAULTVIEW = YES)
                LET row_idx = DIALOG.getCurrentRow("arr_sa_qt_lines")
                TRY
                    LET sel_code = st121_st_lkup.fetch_list()
                CATCH
                    CALL utils_globals.show_error("Stock lookup failed: " || STATUS)
                    CONTINUE DIALOG
                END TRY
                IF sel_code IS NOT NULL AND sel_code != "" THEN
                    LET m_qt_lines_arr[row_idx].stock_id = sel_code
                    TRY
                        CALL load_stock_details(row_idx)
                    CATCH
                        CALL utils_globals.show_error("Load stock failed: " || STATUS)
                        CONTINUE DIALOG
                    END TRY
                    DISPLAY m_qt_lines_arr[row_idx].*
                        TO m_qt_lines_arr[row_idx].*
                END IF
                CONTINUE DIALOG

            AFTER FIELD stock_id
                IF m_qt_lines_arr[row_idx].stock_id IS NOT NULL THEN
                    CALL load_stock_details(row_idx)
                END IF

            AFTER FIELD qnty, unit_price, disc_pct, vat_rate
                CALL calculate_line_totals(row_idx)

            ON ACTION save_lines ATTRIBUTES(TEXT = "Save Lines", IMAGE = "save")
                IF m_qt_lines_arr.getLength() > 0 THEN
                    CALL save_qt_lines()
                ELSE
                    CALL utils_globals.show_info("No lines to save.")
                END IF
                CONTINUE DIALOG

            ON ACTION delete_line
                ATTRIBUTES(TEXT = "Delete Line", IMAGE = "delete")
                IF row_idx > 0 AND row_idx <= m_qt_lines_arr.getLength() THEN
                    CALL m_qt_lines_arr.deleteElement(row_idx)
                    CALL renumber_lines()
                    CALL recalculate_header_totals()
                    CALL utils_globals.show_info("Line deleted.")
                END IF
                CONTINUE DIALOG

            AFTER DELETE
                -- Renumber lines after delete
                CALL renumber_lines()
        END INPUT

        ON ACTION convert_to_order
            ATTRIBUTES(TEXT = "Convert to Order", IMAGE = "forward")
            -- Only show if quote is posted
            IF m_qt_hdr_rec.status != "posted" THEN
                CALL utils_globals.show_info(
                    "Convert to Order is only available for posted quotes.")
                CONTINUE DIALOG
            END IF

            IF utils_globals.show_confirm(
                "Convert this quote to order?", "Confirm") THEN
                CALL copy_quote_to_order(m_qt_hdr_rec.id)
                EXIT DIALOG
            END IF
            CONTINUE DIALOG

        ON ACTION CANCEL ATTRIBUTES(TEXT = "Exit")
            EXIT DIALOG
    END DIALOG

    CLOSE WINDOW w_sa130
END FUNCTION

-- ==============================================================
-- Create new header (defaults only)
-- ==============================================================
FUNCTION new_quote()
    DEFINE next_doc INTEGER
    DEFINE l_cust_id STRING

    -- Initialize timestamp
    LET m_timestamp = CURRENT

    LET next_doc = utils_globals.get_next_code('sa30_quo_hdr', 'id')

    INITIALIZE m_qt_hdr_rec.* TO NULL
    CALL m_qt_lines_arr.clear()

    -- Set default values for new quote
    LET m_qt_hdr_rec.doc_no = next_doc
    LET m_qt_hdr_rec.trans_date = TODAY
    LET m_qt_hdr_rec.status = "draft"
    LET m_qt_hdr_rec.created_at = TODAY
    LET m_qt_hdr_rec.created_by = utils_globals.get_current_user_id()
    LET m_qt_hdr_rec.gross_tot = 0.00
    LET m_qt_hdr_rec.disc_tot = 0.00
    LET m_qt_hdr_rec.vat_tot = 0.00
    LET m_qt_hdr_rec.net_tot = 0.00

    LET g_hdr_saved = FALSE

    -- Display the header fields
    DISPLAY BY NAME m_qt_hdr_rec.*

    -- Open customer lookup to select customer
    LET l_cust_id = dl121_lkup.load_lookup_form_with_search()

    IF l_cust_id IS NOT NULL AND l_cust_id != "" THEN
        -- Load customer data and populate header
        TRY
            SELECT * INTO m_cust_rec.* FROM dl01_mast WHERE id = l_cust_id

            -- Populate customer info in header
            LET m_qt_hdr_rec.cust_id = m_cust_rec.id
            LET m_qt_hdr_rec.cust_name = m_cust_rec.cust_name
            LET m_qt_hdr_rec.cust_phone = m_cust_rec.phone
            LET m_qt_hdr_rec.cust_email = m_cust_rec.email
            LET m_qt_hdr_rec.cust_address1 = m_cust_rec.address1
            LET m_qt_hdr_rec.cust_address2 = m_cust_rec.address2
            LET m_qt_hdr_rec.cust_address3 = m_cust_rec.address3
            LET m_qt_hdr_rec.cust_postal_code = m_cust_rec.postal_code
            LET m_qt_hdr_rec.cust_vat_no = m_cust_rec.vat_no
            LET m_qt_hdr_rec.cust_payment_terms = m_cust_rec.payment_terms

            -- Display updated header
            DISPLAY BY NAME m_qt_hdr_rec.*

        CATCH
            CALL utils_globals.show_sql_error("new_quote: Error loading customer")
        END TRY
    END IF

    MESSAGE SFMT("New Quote #%1 - Enter customer and header details, then save header",
        next_doc)

END FUNCTION

-- ==============================================================
-- Lookup customers
-- ==============================================================
FUNCTION lookup_customers()
    DEFINE l_cust_id INTEGER

    TRY
        LET l_cust_id = utils_global_lkup.display_lookup('customers')
    CATCH
        CALL utils_globals.show_error("Customer lookup failed: " || STATUS)
        RETURN
    END TRY

    CALL new_qt_from_master(l_cust_id)

END FUNCTION

-- ==============================================================
-- Save: insert or update header
-- ==============================================================
FUNCTION save_quote_header() RETURNS SMALLINT
    DEFINE ok SMALLINT
    BEGIN WORK
    TRY

        DISPLAY m_qt_hdr_rec.*
        IF m_qt_hdr_rec.id IS NULL THEN
            INSERT INTO sa30_quo_hdr VALUES m_qt_hdr_rec.*
            LET m_qt_hdr_rec.id = SQLCA.SQLERRD[2]
            CALL utils_globals.msg_saved()

        ELSE
            LET m_qt_hdr_rec.updated_at = TODAY
            UPDATE sa30_quo_hdr
                SET sa30_quo_hdr.* = m_qt_hdr_rec.*
                WHERE id = m_qt_hdr_rec.id
            IF SQLCA.SQLCODE = 0 THEN
                CALL utils_globals.msg_updated()
            END IF
        END IF
        COMMIT WORK
        LET ok = (m_qt_hdr_rec.id IS NOT NULL)
        RETURN ok
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_sql_error("save_quote_header: Save failed")
        RETURN FALSE
    END TRY

END FUNCTION

-- ==============================================================
-- Validation
-- ==============================================================
FUNCTION validate_quote_header() RETURNS SMALLINT
    IF m_qt_hdr_rec.trans_date IS NULL THEN
        RETURN FALSE
    END IF
    IF m_qt_hdr_rec.cust_id IS NULL OR m_qt_hdr_rec.cust_id = 0 THEN
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION

-- ==============================================================
-- Delete quote
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

    -- Get quote details
    TRY
        SELECT status, doc_no
            INTO l_status, l_doc_no
            FROM sa30_quo_hdr
            WHERE id = p_doc_id
    CATCH
        CALL utils_globals.show_sql_error("delete_quote: Query failed")
        RETURN
    END TRY

    -- Check status
    IF l_status = "CONVERTED" THEN
        CALL utils_globals.show_error(
            "Cannot delete converted quotes. Status: " || l_status)
        RETURN
    END IF

    -- Check for linked orders
    SELECT COUNT(*)
        INTO l_order_count
        FROM sa31_ord_hdr
        WHERE ref_doc_type = "QUOTE" AND ref_doc_no = l_doc_no

    IF l_order_count > 0 THEN
        CALL utils_globals.show_error(
            SFMT("Cannot delete quote - it has %1 linked order(s)",
                l_order_count))
        RETURN
    END IF

    -- Confirm deletion
    LET ok =
        utils_globals.show_confirm(
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
        CALL utils_globals.msg_deleted()
        INITIALIZE m_qt_hdr_rec.* TO NULL
        DISPLAY BY NAME m_qt_hdr_rec.doc_no,
            m_qt_hdr_rec.trans_date,
            m_qt_hdr_rec.cust_id,
            m_qt_hdr_rec.status

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_sql_error("delete_quote: Delete failed")
    END TRY

END FUNCTION

-- ==============================================================
-- Load by id
-- ==============================================================
FUNCTION load_quote(p_id INTEGER)

    INITIALIZE m_qt_hdr_rec.* TO NULL
    CALL m_qt_lines_arr.clear()

    -- Load header
    TRY
        SELECT * INTO m_qt_hdr_rec.* FROM sa30_quo_hdr WHERE id = p_id

        IF SQLCA.SQLCODE != 0 THEN
            CALL utils_globals.show_error("Quote header not found.")
            RETURN
        END IF
    CATCH
        CALL utils_globals.show_sql_error("load_quote: Quote header query failed")
        RETURN
    END TRY

    -- Load lines
    TRY
        DECLARE qt_curs CURSOR FOR
            SELECT * FROM sa30_quo_det WHERE hdr_id = p_id ORDER BY id

        FOREACH qt_curs INTO m_qt_lines_arr[m_qt_lines_arr.getLength() + 1].*
        END FOREACH

        CLOSE qt_curs
        FREE qt_curs
    CATCH
        CALL utils_globals.show_sql_error("load_quote: Quote lines query failed")
        RETURN
    END TRY

    OPEN WINDOW w_sa130 WITH FORM "sa130_quote"
    -- Show header fields
    DISPLAY BY NAME m_qt_hdr_rec.*

    -- Show line details
    DISPLAY ARRAY m_qt_lines_arr TO arr_sa_qt_lines.*

    CLOSE WINDOW w_sa130

END FUNCTION

-- ==============================================================
-- Find (simple lookup by doc_no)
-- ==============================================================
FUNCTION find_quote()
    DEFINE selected_code STRING

    LET selected_code = utils_global_lkup.display_lookup('sa_quote')

    IF selected_code IS NULL OR selected_code.getLength() = 0 THEN
        RETURN
    END IF

    CALL load_quote(selected_code)
END FUNCTION

-- ==============================================================
-- Navigation wrapper
-- ==============================================================
FUNCTION move_record(dir SMALLINT)
    DEFINE new_idx INTEGER

    IF arr_codes.getLength() == 0 THEN
        CALL utils_globals.show_info("No records to navigate.")
        RETURN
    END IF

    LET new_idx = utils_globals.navigate_records(arr_codes, curr_idx, dir)
    LET curr_idx = new_idx
    CALL load_quote(arr_codes[curr_idx])
END FUNCTION

-- ==============================================================
-- Load stock details when stock_id is entered
-- ==============================================================
FUNCTION load_stock_details(p_idx INTEGER)
    DEFINE l_stock RECORD LIKE st01_mast.*

    IF m_qt_lines_arr[p_idx].stock_id IS NULL
        OR m_qt_lines_arr[p_idx].stock_id = 0 THEN
        RETURN
    END IF

    TRY
        SELECT description, sell_price
            INTO l_stock.description, l_stock.sell_price
            FROM st01_mast
            WHERE id = m_qt_lines_arr[p_idx].stock_id
    CATCH
        CALL utils_globals.show_error("Stock details query failed: " || SQLCA.SQLERRM)
        RETURN
    END TRY

    IF SQLCA.SQLCODE = 0 THEN
        LET m_qt_lines_arr[p_idx].item_name = l_stock.description
        LET m_qt_lines_arr[p_idx].uom = l_stock.uom -- Default unit of measure
        LET m_qt_lines_arr[p_idx].unit_price = l_stock.sell_price
        LET m_qt_lines_arr[p_idx].vat_rate = 15 -- Default VAT rate

        -- Calculate line totals if quantity is already entered
        IF m_qt_lines_arr[p_idx].qnty IS NOT NULL THEN
            CALL calculate_line_totals(p_idx)
        END IF
    ELSE
        CALL utils_globals.show_error("Stock item not found.")
    END IF
END FUNCTION

-- ==============================================================
-- Calculate line totals
-- ==============================================================
FUNCTION calculate_line_totals(p_idx INTEGER)
    DEFINE l_gross DECIMAL(12, 2)
    DEFINE l_disc DECIMAL(12, 2)
    DEFINE l_vat DECIMAL(12, 2)
    DEFINE l_net DECIMAL(12, 2)

    -- Initialize defaults
    IF m_qt_lines_arr[p_idx].qnty IS NULL THEN
        LET m_qt_lines_arr[p_idx].qnty = 0
    END IF
    IF m_qt_lines_arr[p_idx].unit_price IS NULL THEN
        LET m_qt_lines_arr[p_idx].unit_price = 0
    END IF
    IF m_qt_lines_arr[p_idx].disc_pct IS NULL THEN
        LET m_qt_lines_arr[p_idx].disc_pct = 0
    END IF
    IF m_qt_lines_arr[p_idx].vat_rate IS NULL THEN
        LET m_qt_lines_arr[p_idx].vat_rate = 0
    END IF

    -- Calculate gross amount
    LET l_gross = m_qt_lines_arr[p_idx].qnty * m_qt_lines_arr[p_idx].unit_price
    LET m_qt_lines_arr[p_idx].gross_amt = l_gross

    -- Calculate discount
    LET l_disc = l_gross * (m_qt_lines_arr[p_idx].disc_pct / 100)
    LET m_qt_lines_arr[p_idx].disc_amt = l_disc

    -- Calculate net before VAT
    LET l_net = l_gross - l_disc
    LET m_qt_lines_arr[p_idx].net_excl_amt = l_net

    -- Calculate VAT
    LET l_vat = l_net * (m_qt_lines_arr[p_idx].vat_rate / 100)
    LET m_qt_lines_arr[p_idx].vat_amt = l_vat

    -- Calculate line total (net + VAT)
    LET m_qt_lines_arr[p_idx].line_total = l_net + l_vat

    -- Recalculate header totals
    CALL recalculate_header_totals()
END FUNCTION

-- ==============================================================
-- Renumber all line numbers sequentially
-- ==============================================================
FUNCTION renumber_lines()
    DEFINE i INTEGER

    FOR i = 1 TO m_qt_lines_arr.getLength()
        LET m_qt_lines_arr[i].line_no = i
    END FOR
END FUNCTION

-- ==============================================================
-- Recalculate header totals from all lines
-- ==============================================================
FUNCTION recalculate_header_totals()
    DEFINE i INTEGER
    DEFINE l_gross_tot DECIMAL(12, 2)
    DEFINE l_disc_tot DECIMAL(12, 2)
    DEFINE l_vat_tot DECIMAL(12, 2)
    DEFINE l_net_tot DECIMAL(12, 2)

    LET l_gross_tot = 0
    LET l_disc_tot = 0
    LET l_vat_tot = 0
    LET l_net_tot = 0

    FOR i = 1 TO m_qt_lines_arr.getLength()
        IF m_qt_lines_arr[i].gross_amt IS NOT NULL THEN
            LET l_gross_tot = l_gross_tot + m_qt_lines_arr[i].gross_amt
        END IF
        IF m_qt_lines_arr[i].disc_amt IS NOT NULL THEN
            LET l_disc_tot = l_disc_tot + m_qt_lines_arr[i].disc_amt
        END IF
        IF m_qt_lines_arr[i].vat_amt IS NOT NULL THEN
            LET l_vat_tot = l_vat_tot + m_qt_lines_arr[i].vat_amt
        END IF
        IF m_qt_lines_arr[i].line_total IS NOT NULL THEN
            LET l_net_tot = l_net_tot + m_qt_lines_arr[i].line_total
        END IF
    END FOR

    LET m_qt_hdr_rec.gross_tot = l_gross_tot
    LET m_qt_hdr_rec.disc_tot = l_disc_tot
    LET m_qt_hdr_rec.vat_tot = l_vat_tot
    LET m_qt_hdr_rec.net_tot = l_net_tot

    DISPLAY BY NAME m_qt_hdr_rec.gross_tot,
        m_qt_hdr_rec.disc_tot,
        m_qt_hdr_rec.vat_tot,
        m_qt_hdr_rec.net_tot
END FUNCTION

-- ==============================================================
-- Save quote lines to database
-- ==============================================================
FUNCTION save_qt_lines()
    DEFINE i INTEGER
    DEFINE l_line RECORD LIKE sa30_quo_det.*

    DISPLAY l_line.*

    -- Renumber lines before saving
    CALL renumber_lines()

    MESSAGE m_timestamp

    BEGIN WORK
    TRY
        -- Delete existing lines for this header
        DELETE FROM sa30_quo_det WHERE hdr_id = m_qt_hdr_rec.id

        -- Insert all lines
        FOR i = 1 TO m_qt_lines_arr.getLength()
            IF m_qt_lines_arr[i].stock_id IS NOT NULL
                AND m_qt_lines_arr[i].stock_id > 0 THEN
                -- Clear the id field to let database auto-generate it
                INITIALIZE l_line.* TO NULL

                -- Copy all fields from array to record
                LET l_line.hdr_id = m_qt_hdr_rec.id
                LET l_line.line_no = i
                LET l_line.stock_id = m_qt_lines_arr[i].stock_id
                LET l_line.item_name = m_qt_lines_arr[i].item_name
                LET l_line.uom = m_qt_lines_arr[i].uom
                LET l_line.qnty = m_qt_lines_arr[i].qnty
                LET l_line.unit_price = m_qt_lines_arr[i].unit_price
                LET l_line.disc_pct = m_qt_lines_arr[i].disc_pct
                LET l_line.disc_amt = m_qt_lines_arr[i].disc_amt
                LET l_line.gross_amt = m_qt_lines_arr[i].gross_amt
                LET l_line.vat_rate = m_qt_lines_arr[i].vat_rate
                LET l_line.vat_amt = m_qt_lines_arr[i].vat_amt
                LET l_line.net_excl_amt = m_qt_lines_arr[i].net_excl_amt
                LET l_line.line_total = m_qt_lines_arr[i].line_total
                LET l_line.notes = m_qt_lines_arr[i].notes
                LET l_line.status = m_qt_lines_arr[i].status
                LET l_line.created_at = m_timestamp
                LET l_line.created_by = utils_globals.get_current_user_id()

                INSERT INTO sa30_quo_det VALUES l_line.*

            END IF
        END FOR

        -- Update header totals
        UPDATE sa30_quo_hdr
            SET gross_tot = m_qt_hdr_rec.gross_tot,
                disc_tot = m_qt_hdr_rec.disc_tot,
                vat_tot = m_qt_hdr_rec.vat_tot,
                net_tot = m_qt_hdr_rec.net_tot,
                status = 'posted',
                updated_at = m_timestamp
            WHERE id = m_qt_hdr_rec.id

        COMMIT WORK
        CALL utils_globals.msg_saved()

        -- Load current quote in read only mode after adding it
        CALL load_quote(m_qt_hdr_rec.id)

    CATCH
        ROLLBACK WORK

        DISPLAY SQLCA.SQLERRM

        CALL utils_globals.show_error(
            "Failed to save lines:\n" || SQLCA.SQLERRM)
    END TRY

END FUNCTION

-- ==============================================================
-- Function : copy_quote_to_order
-- ==============================================================
FUNCTION copy_quote_to_order(p_quote_id INTEGER)
    DEFINE l_quote_hdr RECORD LIKE sa30_quo_hdr.*
    DEFINE l_order_hdr RECORD LIKE sa31_ord_hdr.*
    DEFINE l_new_order_id INTEGER
    DEFINE l_new_order_doc_no INTEGER
    DEFINE l_order_count INTEGER
    DEFINE m_user SMALLINT

    -- Check if already converted
    SELECT COUNT(*)
        INTO l_order_count
        FROM sa31_ord_hdr
        WHERE ref_doc_type = "QUOTE"
            AND ref_doc_no
                =
                (SELECT doc_no FROM sa30_quo_hdr WHERE id = p_quote_id)

    IF l_order_count > 0 THEN
        CALL utils_globals.show_error(
            "Quote has already been converted to an order")
        RETURN
    END IF

    -- Load quote
    TRY
        SELECT * INTO l_quote_hdr.* FROM sa30_quo_hdr WHERE id = p_quote_id

        IF SQLCA.SQLCODE != 0 THEN
            CALL utils_globals.show_error("Quote not found")
            RETURN
        END IF
    CATCH
        CALL utils_globals.show_sql_error("copy_quote_to_order: Quote load failed")
        RETURN
    END TRY

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

    BEGIN WORK
    TRY
        -- Get next order number
        SELECT COALESCE(MAX(doc_no), 0) + 1
            INTO l_new_order_doc_no
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

        -- Copy quote lines to order
        INSERT INTO sa31_ord_det(
            hdr_id,
            line_no,
            stock_id,
            item_name,
            uom,
            qnty,
            unit_price,
            disc_pct,
            disc_amt,
            gross_amt,
            net_excl_amt,
            vat_rate,
            vat_amt,
            line_total,
            status,
            created_at,
            created_by)
            SELECT l_new_order_id,
                line_no,
                stock_id,
                item_name,
                uom,
                qnty,
                unit_price,
                disc_pct,
                disc_amt,
                gross_amt,
                net_excl_amt,
                vat_rate,
                vat_amt,
                line_total,
                status,
                CURRENT,
                m_user
                FROM sa30_quo_det
                WHERE hdr_id = p_quote_id

        -- Update quote status to CONVERTED
        UPDATE sa30_quo_hdr
            SET status = "CONVERTED", updated_at = CURRENT
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
