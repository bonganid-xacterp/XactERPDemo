-- ==============================================================
-- Program   : sa133_crn.4gl
-- Purpose   : Sales Credit Note Program
-- Module    : Sales Credit Note (sa)
-- Number    : 133
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL st121_st_lkup
IMPORT FGL utils_doc_totals
IMPORT FGL dl121_lkup

SCHEMA demoappdb

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE crn_hdr_t RECORD LIKE sa33_crn_hdr.*
DEFINE m_crn_lines_arr DYNAMIC ARRAY OF RECORD LIKE sa33_crn_det.*

DEFINE m_crn_hdr_rec crn_hdr_t
DEFINE m_cust_rec RECORD LIKE dl01_mast.*

DEFINE m_arr_codes DYNAMIC ARRAY OF STRING
DEFINE m_curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

-- ==============================================================
-- Init Program
-- ==============================================================
FUNCTION init_crn_module()
    LET is_edit_mode = FALSE
    INITIALIZE m_cust_rec.* TO NULL
    
    DISPLAY BY NAME m_cust_rec.*
        
    MENU "Credit Note Menu"
        COMMAND "Find"
           -- CALL ();
            LET is_edit_mode = FALSE
        COMMAND "New"
            CALL new_crn()
        COMMAND "Edit"
            IF m_cust_rec.id IS NULL OR m_cust_rec.id = 0 THEN
                CALL utils_globals.show_info("No record selected.")
            ELSE
                --CALL prompt_edit_choice( m_cust_rec.id)
            END IF
        COMMAND "Delete"
            CALL delete_credit_note(m_cust_rec.id)
        COMMAND "Previous"
            CALL move_record(-1)
        COMMAND "Next"
            CALL move_record(1)

        COMMAND "Exit"
            EXIT MENU
    END MENU
END FUNCTION

-- ==============================================================
-- Add New Credit Note
-- ==============================================================
FUNCTION new_crn()
    DEFINE l_hdr_rec RECORD LIKE sa33_crn_hdr.*
    DEFINE l_next_doc_no INTEGER
    DEFINE l_new_hdr_id INTEGER

    -- ==========================================================
    -- 1. Generate next document number
    -- ==========================================================
    SELECT COALESCE(MAX(id), 0) + 1 INTO l_next_doc_no FROM sa33_crn_hdr

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
    -- 4. Save Header to Database
    -- ==========================================================
    BEGIN WORK
    TRY
        INSERT INTO sa33_crn_hdr VALUES(l_hdr_rec.*)

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
        RETURN
    END TRY

    -- ==========================================================
    -- 5. Now add lines (header ID exists)
    -- ==========================================================
    LET m_crn_hdr_rec.* = l_hdr_rec.*
    CALL m_crn_lines_arr.clear()

    CALL input_quote_lines(l_new_hdr_id)

    -- ==========================================================
    -- 6. Load the complete quote for viewing
    -- ==========================================================
    --CALL load_crn(l_new_hdr_id)

END FUNCTION

-- ==============================================================
-- Edit an Credit Note
-- ==============================================================
FUNCTION edit_crn()
    DEFINE is_hdr SMALLINT
    
    LET  is_hdr = utils_globals.show_confirm('Do you want to edit headers or footer', 'Edit credit Document')

END FUNCTION 

-- ==============================================================
-- Add or Edit an Credit Note line
-- ==============================================================
FUNCTION edit_or_add_crn_line(p_doc_id INTEGER, p_row INTEGER, p_is_new SMALLINT)
    DEFINE l_line RECORD LIKE sa33_crn_det.*
    DEFINE l_stock_id STRING
    DEFINE l_vat_rate DECIMAL(10,2)
    DEFINE l_gross, l_line_totalal, l_vat DECIMAL(15,2)

    IF p_is_new THEN
        -- Initialize new line
        INITIALIZE l_line.* TO NULL
        LET l_line.hdr_id = p_doc_id
        LET l_line.line_no = m_crn_lines_arr.getLength() + 1
        LET l_vat_rate = 15.00
    ELSE
        -- Load from existing array line
        LET l_line.* = m_crn_lines_arr[p_row].*
        LET l_vat_rate = 15.00
    END IF

    -- ==============================
    -- Input Dialog for editing/adding
    -- ==============================
    DIALOG
        INPUT BY NAME l_line.stock_id, l_line.qnty, l_line.disc_amt, l_line.vat_amt
            ATTRIBUTES(WITHOUT DEFAULTS)

            BEFORE FIELD stock_id
                -- call lookup popup
                LET l_stock_id = lookup_stock_item()
                
                IF l_stock_id IS NOT NULL THEN
                
                    LET l_line.stock_id = l_stock_id
                    
                    CALL load_stock_defaults(l_stock_id)

                    DISPLAY BY NAME l_line.unit_price
                    
                END IF

            AFTER FIELD qnty, disc_amt, vat_amt
                -- calculate the line total 
                --LET l_line.line_total =  utils_doc_totals.calculate_line_totals(
                --                    l_line.qnty, 
                --                    l_line.unit_price, 
                --                    l_line.disc_amt, 
                --                    l_line.vat_amt)

                
                DISPLAY BY NAME l_line.line_total, l_line.vat_amt

            ON ACTION save
                IF p_is_new THEN
                    LET m_crn_lines_arr[m_crn_lines_arr.getLength() + 1].* = l_line.*
                ELSE
                    LET m_crn_lines_arr[p_row].* = l_line.*
                END IF
                CALL utils_globals.msg_saved()
                EXIT DIALOG

            ON ACTION cancel
                EXIT DIALOG
        END INPUT
    END DIALOG
END FUNCTION

-- ==============================================================
-- Lookup item from Stock Master
-- ==============================================================
PRIVATE FUNCTION lookup_stock_item() RETURNS STRING
    DEFINE l_stock_id STRING
    LET l_stock_id = st121_st_lkup.fetch_list() -- your lookup popup
    RETURN l_stock_id
END FUNCTION

-- ==============================================================
-- Lookup item from Stock Master
-- ==============================================================
private FUNCTION load_stock_defaults(p_stock_id STRING)
    SELECT unit_price, uom,
      INTO p_cost, p_price
      FROM st01_mast
     WHERE stock_id = p_stock_id
END FUNCTION

-- ==============================================================
-- Delete selected Credit Note line
-- ==============================================================
FUNCTION delete_crn_line(p_doc_id INTEGER, p_row INTEGER)
    IF p_row > 0 THEN
        IF utils_globals.confirm_delete(p_row, p_doc_id) THEN
            CALL m_crn_lines_arr.deleteElement(p_row)
            CALL utils_globals.msg_deleted()
        END IF
    END IF
END FUNCTION

-- ==============================================================
-- Save all lines to database
-- ==============================================================
FUNCTION save_crn_lines(p_doc_id INTEGER)
    DEFINE i INTEGER

    DELETE FROM sa33_crn_det WHERE hdr_id = p_doc_id

    FOR i = 1 TO m_crn_lines_arr.getLength()
        INSERT INTO sa33_crn_det VALUES m_crn_lines_arr[i].*
    END FOR
END FUNCTION

-- ==============================================================
-- Function : load_customer
-- ==============================================================
private FUNCTION load_customer(p_debt_id STRING)

    DEFINE rec_cust RECORD
        cust_name LIKE dl01_mast.cust_name,
        phone     LIKE dl01_mast.phone,
        email     LIKE dl01_mast.email,
        address1  LIKE dl01_mast.address1,
        address2  LIKE dl01_mast.address2,
        address3  LIKE dl01_mast.address3,
        postal_code LIKE dl01_mast.postal_code
    END RECORD

    SELECT cust_name, phone, email, address1, address2, address3, postal_code
      INTO rec_cust.*
      FROM dl01_mast
     WHERE acc_code = p_debt_id

    IF SQLCA.SQLCODE = 0 THEN
        LET rec_cust.cust_name   = rec_cust.cust_name
        LET rec_cust.phone       = rec_cust.phone
        LET rec_cust.email       = rec_cust.email
        LET rec_cust.address1    = rec_cust.address1
        LET rec_cust.address2    = rec_cust.address2
        LET rec_cust.address3    = rec_cust.address3
        LET rec_cust.postal_code = rec_cust.postal_code
        DISPLAY BY NAME rec_cust.*
    ELSE
        CALL utils_globals.show_error("Customer not found for account " || p_debt_id)
    END IF
END FUNCTION

-- ==============================================================
-- Function : load_credit_note
-- ==============================================================
FUNCTION load_credit_note(p_doc_id INTEGER)
    DEFINE idx INTEGER
    DEFINE user_choice SMALLINT

    OPTIONS INPUT WRAP

    -- Open window and attach form
    OPEN WINDOW w_crn WITH FORM "sa133_crn" ATTRIBUTES(STYLE = "dialog")

    -- Initialize variables
    INITIALIZE m_crn_hdr_rec.* TO NULL
    CALL m_crn_lines_arr.clear()

    -- ===========================================
    -- Load header record
    -- ===========================================
    SELECT * INTO m_crn_hdr_rec.* 
      FROM sa33_crn_hdr 
     WHERE id = p_doc_id

    IF SQLCA.SQLCODE = 0 THEN
        -- ===========================================
        -- Load Credit Note lines
        -- ===========================================
        LET idx = 0
        DECLARE ord_lines_cur CURSOR FOR
            SELECT * 
              FROM sa33_crn_det 
             WHERE hdr_id = p_doc_id 
             ORDER BY line_no

        FOREACH ord_lines_cur INTO m_crn_lines_arr[idx + 1].*
            LET idx = idx + 1
        END FOREACH

        CLOSE ord_lines_cur
        FREE ord_lines_cur

        -- ===========================================
        -- Show form in view mode first
        -- ===========================================
        DISPLAY BY NAME m_crn_hdr_rec.*
        DISPLAY ARRAY m_crn_lines_arr TO arr_sa_crn_items.*

            BEFORE DISPLAY
                CALL DIALOG.setActionHidden("cancel", TRUE)
                CALL DIALOG.setActionHidden("accept", TRUE)

            ON ACTION edit ATTRIBUTES(TEXT="Edit C/Note", IMAGE="pen")
                LET user_choice = prompt_edit_choice()

                CASE user_choice
                    WHEN 1
                        CALL edit_crn_header(p_doc_id)
                        DISPLAY BY NAME m_crn_hdr_rec.*  -- Refresh
                    WHEN 2
                        CALL edit_crn_lines(p_doc_id)
                    OTHERWISE
                        CALL utils_globals.show_info("Edit cancelled.")
                END CASE

            ON ACTION close ATTRIBUTES(TEXT="Close", IMAGE="exit")
                EXIT DISPLAY
        END DISPLAY
    ELSE
        CALL utils_globals.show_error("Credit Note not found.")
    END IF

    CLOSE WINDOW w_crn
END FUNCTION

-- ==============================================================
-- Prompt Edit Choices
-- ==============================================================
PRIVATE FUNCTION prompt_edit_choice() RETURNS SMALLINT
    DEFINE choice SMALLINT

    MENU "Edit Credit Note"
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
-- Edit Credit Note header
-- ==============================================================
FUNCTION edit_crn_header(p_doc_id INTEGER)
    DEFINE new_hdr RECORD LIKE sa33_crn_hdr.*

    LET new_hdr.* = m_crn_hdr_rec.*

    DIALOG
        INPUT BY NAME new_hdr.*
        
            ON ACTION save
            
                UPDATE sa33_crn_hdr SET sa33_crn_hdr.* = new_hdr.* 
                 WHERE id = p_doc_id
                LET m_crn_hdr_rec.* = new_hdr.*
                
                CALL utils_globals.msg_saved()

            ON ACTION cancel
                EXIT DIALOG
        END INPUT
        
    END DIALOG
END FUNCTION

-- ==============================================================
-- Edit Credit Lines
-- ==============================================================
FUNCTION edit_crn_lines(p_doc_id INTEGER)
    DIALOG
        DISPLAY ARRAY m_crn_lines_arr TO arr_sa_crn_items.*
            BEFORE DISPLAY
                CALL DIALOG.setActionHidden("accept", TRUE)

            ON ACTION add ATTRIBUTES(TEXT="Add Line", IMAGE="new")
                CALL edit_or_add_crn_line(p_doc_id, 0, TRUE)

            ON ACTION edit ATTRIBUTES(TEXT="Edit Line", IMAGE="pen")
                CALL edit_or_add_crn_line(p_doc_id, arr_curr(), FALSE)

            ON ACTION delete ATTRIBUTES(TEXT="Delete", IMAGE="delete")
                CALL delete_crn_line(p_doc_id, arr_curr())

            ON ACTION save ATTRIBUTES(TEXT="Save", IMAGE="save")
                CALL save_crn_lines(p_doc_id)
                CALL utils_globals.msg_saved()
                EXIT DIALOG

            ON ACTION cancel
                EXIT DIALOG
        END DISPLAY
    END DIALOG
END FUNCTION

-- ==============================================================
-- Save Credit Note (Header + Lines)
-- ==============================================================
FUNCTION save_credit_note()
    DEFINE exists INTEGER

    SELECT COUNT(*) INTO exists FROM sa33_crn_hdr WHERE id = m_crn_hdr_rec.id

    IF exists = 0 THEN
        INSERT INTO sa33_crn_hdr VALUES m_crn_hdr_rec.*
        CALL utils_globals.msg_saved()
    ELSE
        UPDATE sa33_crn_hdr
            SET sa33_crn_hdr.* = m_crn_hdr_rec.*
            WHERE id = m_crn_hdr_rec.id
        CALL utils_globals.msg_updated()
    END IF

    -- Save lines
    DELETE FROM sa33_crn_det WHERE hdr_id = m_crn_hdr_rec.id

    FOR m_curr_idx = 1 TO m_crn_lines_arr.getLength()
        INSERT INTO sa33_crn_det VALUES m_crn_lines_arr[m_curr_idx].*
    END FOR

END FUNCTION

-- ==============================================================
-- Delete Credit Note
-- ==============================================================
FUNCTION delete_credit_note(p_doc_id INTEGER)
    DEFINE ok SMALLINT

    IF p_doc_id IS NULL THEN
        CALL utils_globals.show_info("No Credit Note selected for deletion.")
        RETURN
    END IF

    LET ok = utils_globals.show_confirm("Delete this Credit Note?", "Confirm Delete")

    IF NOT ok THEN
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    DELETE FROM sa33_crn_det WHERE id = p_doc_id
    DELETE FROM sa33_crn_hdr WHERE id = p_doc_id
    CALL utils_globals.msg_deleted()
END FUNCTION

-- ==============================================================
-- Navigation
-- ==============================================================
PRIVATE FUNCTION move_record(dir SMALLINT)
    DEFINE new_idx INTEGER

    IF m_arr_codes.getLength() == 0 THEN
        CALL utils_globals.show_info("No records to navigate.")
        RETURN
    END IF

    LET new_idx = utils_globals.navigate_records(m_arr_codes, m_curr_idx, dir)
    LET m_curr_idx = new_idx
    CALL load_credit_note(m_arr_codes[m_curr_idx])
END FUNCTION
