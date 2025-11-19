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


SCHEMA demoappdb

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE crn_hdr_t RECORD LIKE sa33_crn_hdr.*
 
DEFINE m_rec_crn crn_hdr_t

DEFINE m_arr_crn_lines DYNAMIC ARRAY OF RECORD LIKE sa33_crn_det.*

DEFINE m_arr_codes DYNAMIC ARRAY OF STRING
DEFINE m_curr_idx INTEGER
--DEFINE is_edit_mode SMALLINT

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
        LET l_line.line_no = m_arr_crn_lines.getLength() + 1
        LET l_vat_rate = 15.00
    ELSE
        -- Load from existing array line
        LET l_line.* = m_arr_crn_lines[p_row].*
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
                    LET m_arr_crn_lines[m_arr_crn_lines.getLength() + 1].* = l_line.*
                ELSE
                    LET m_arr_crn_lines[p_row].* = l_line.*
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
            CALL m_arr_crn_lines.deleteElement(p_row)
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

    FOR i = 1 TO m_arr_crn_lines.getLength()
        INSERT INTO sa33_crn_det VALUES m_arr_crn_lines[i].*
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
    INITIALIZE m_rec_crn.* TO NULL
    CALL m_arr_crn_lines.clear()

    -- ===========================================
    -- Load header record
    -- ===========================================
    SELECT * INTO m_rec_crn.* 
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

        FOREACH ord_lines_cur INTO m_arr_crn_lines[idx + 1].*
            LET idx = idx + 1
        END FOREACH

        CLOSE ord_lines_cur
        FREE ord_lines_cur

        -- ===========================================
        -- Show form in view mode first
        -- ===========================================
        DISPLAY BY NAME m_rec_crn.*
        DISPLAY ARRAY m_arr_crn_lines TO arr_sa_crn_items.*

            BEFORE DISPLAY
                CALL DIALOG.setActionHidden("cancel", TRUE)
                CALL DIALOG.setActionHidden("accept", TRUE)

            ON ACTION edit ATTRIBUTES(TEXT="Edit C/Note", IMAGE="pen")
                LET user_choice = prompt_edit_choice()

                CASE user_choice
                    WHEN 1
                        CALL edit_crn_header(p_doc_id)
                        DISPLAY BY NAME m_rec_crn.*  -- Refresh
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

    LET new_hdr.* = m_rec_crn.*

    DIALOG
        INPUT BY NAME new_hdr.*
        
            ON ACTION save
            
                UPDATE sa33_crn_hdr SET sa33_crn_hdr.* = new_hdr.* 
                 WHERE id = p_doc_id
                LET m_rec_crn.* = new_hdr.*
                
                CALL utils_globals.msg_saved()

            ON ACTION cancel
                EXIT DIALOG
        END INPUT
        
    END DIALOG
END FUNCTION


FUNCTION edit_crn_lines(p_doc_id INTEGER)
    DIALOG
        DISPLAY ARRAY m_arr_crn_lines TO arr_sa_crn_items.*
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

    SELECT COUNT(*) INTO exists FROM sa33_crn_hdr WHERE id = m_rec_crn.id

    IF exists = 0 THEN
        INSERT INTO sa33_crn_hdr VALUES m_rec_crn.*
        CALL utils_globals.msg_saved()
    ELSE
        UPDATE sa33_crn_hdr
            SET sa33_crn_hdr.* = m_rec_crn.*
            WHERE id = m_rec_crn.id
        CALL utils_globals.msg_updated()
    END IF

    -- Save lines
    DELETE FROM sa33_crn_det WHERE hdr_id = m_rec_crn.id

    FOR m_curr_idx = 1 TO m_arr_crn_lines.getLength()
        INSERT INTO sa33_crn_det VALUES m_arr_crn_lines[m_curr_idx].*
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
