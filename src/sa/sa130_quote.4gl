-- ==============================================================
-- Program   : sa130_qt.4gl
-- Purpose   : Sales Quote Program
-- Module    : Sales Quote (sa)
-- Number    : 130
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoapp_db

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE quote_hdr_t RECORD LIKE sa30_quo_hdr.*
DEFINE qt_hdr_rec quote_hdr_t

DEFINE arr_sa_ord_lines DYNAMIC ARRAY OF RECORD LIKE sa30_quo_det.*

DEFINE arr_codes  DYNAMIC ARRAY OF STRING
DEFINE curr_idx   INTEGER
--DEFINE is_edit_mode SMALLINT


-- ==============================================================
-- MAIN
-- ==============================================================
MAIN
    IF NOT utils_globals.initialize_application() THEN
        DISPLAY "Initialization failed."
        EXIT PROGRAM 1
    END IF
        OPTIONS INPUT WRAP
        OPEN WINDOW w_dl101 WITH FORM "sa130_quote" ATTRIBUTES(STYLE = "child")

    CALL init_dl_module()

        CLOSE WINDOW w_dl101
END MAIN

-- new sales quote
FUNCTION init_dl_module()

    DEFINE l_debtor RECORD LIKE dl01_mast.*
    DEFINE next_num INTEGER
    DEFINE next_full STRING

    CLEAR FORM

    -- (p_table STRING, p_prefix STRING
    CALL utils_globals.get_next_number("sa30_quo_hdr", "QT")
        RETURNING next_num, next_full

        LET qt_hdr_rec.doc_no = next_num
        LET qt_hdr_rec.trans_date = TODAY
        LET qt_hdr_rec.status = 'draft'
        LET qt_hdr_rec.gross_tot = 0.00
        LET qt_hdr_rec.disc = 0.00
        LET qt_hdr_rec.vat = 0.00
        LET qt_hdr_rec.net_tot = 0.00

        
    
     DIALOG ATTRIBUTES(UNBUFFERED)

        -- Header section fields
        INPUT BY NAME qt_hdr_rec.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME="order_header")

            ON ACTION save ATTRIBUTES(TEXT="Save",IMAGE="filesave")
                CALL save_quote()
                EXIT DIALOG

            ON ACTION close ATTRIBUTES(TEXT="Close",IMAGE="exit")
                EXIT DIALOG
        END INPUT

        -- Lines section (display array for order details)
        DISPLAY ARRAY arr_sa_ord_lines TO arr_sa_ord_lines.*

            ON ACTION add
                CALL add_quote_line()
            ON ACTION delete
               CALL delete_line(arr_curr())
            ON ACTION save
                CALL save_quote()
            ON ACTION close
                EXIT DIALOG
        END DISPLAY
    END DIALOG

    
    
END FUNCTION 

-- ==============================================================
-- Public entry point (called from Debtors or MDI menu)
-- ==============================================================
PUBLIC FUNCTION show_quote(p_doc_no INTEGER)
    -- Open the quote window inside the MDI container
    OPTIONS INPUT WRAP
    OPEN WINDOW w_qt130 WITH FORM "sa130_quote" ATTRIBUTES(STYLE="child")

    -- Load header + lines
   CALL load_quote(p_doc_no)

    -- View/edit the quote
    CALL edit_quote_dialog()

    CLOSE WINDOW w_qt130
END FUNCTION

-- ==============================================================
-- Load Quote Header and Lines
-- ==============================================================
FUNCTION load_quote(p_doc_no INTEGER)
    DEFINE idx INTEGER

    ERROR p_doc_no

    INITIALIZE qt_hdr_rec.* TO NULL
    CALL arr_sa_ord_lines.clear()

    SELECT * INTO qt_hdr_rec.* FROM sa30_quo_hdr WHERE doc_no = p_doc_no

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME qt_hdr_rec.*
        -- Load lines for this quote
        DECLARE c_lines CURSOR FOR
            SELECT * FROM sa30_quo_det WHERE doc_no = p_doc_no ORDER BY line_no

        FOREACH c_lines INTO arr_sa_ord_lines[idx + 1].*
            LET idx = idx + 1
        END FOREACH

        CLOSE c_lines
        FREE c_lines
    ELSE
        CALL utils_globals.show_error("Quote not found.")
    END IF
END FUNCTION

-- ==============================================================
-- Edit / View Quote (dialog)
-- ==============================================================
FUNCTION edit_quote_dialog()
    DIALOG ATTRIBUTES(UNBUFFERED)

        -- Header section fields
        INPUT BY NAME qt_hdr_rec.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME="quote_header")

            ON ACTION save ATTRIBUTES(TEXT="Save",IMAGE="filesave")
                CALL save_quote()
                EXIT DIALOG

            ON ACTION close ATTRIBUTES(TEXT="Close",IMAGE="exit")
                EXIT DIALOG
        END INPUT

        -- Lines section (display array for quote details)
        DISPLAY ARRAY arr_sa_ord_lines TO sr_quote_lines.*

            ON ACTION add
                CALL add_quote_line()
            ON ACTION delete
               CALL delete_line(arr_curr())
            ON ACTION save
                CALL save_quote()
            ON ACTION close
                EXIT DIALOG
        END DISPLAY
    END DIALOG
END FUNCTION

-- ==============================================================
-- Add Quote Line
-- ==============================================================
FUNCTION add_quote_line()
    DEFINE new_line RECORD LIKE sa30_quo_det.*
    LET new_line.line_no = arr_sa_ord_lines.getLength() + 1

    INPUT BY NAME new_line.*
        ATTRIBUTES(WITHOUT DEFAULTS, NAME="new_line")

        ON ACTION save
            LET arr_sa_ord_lines[arr_sa_ord_lines.getLength() + 1] = new_line
            CALL utils_globals.show_info("Line added.")
            EXIT INPUT

        ON ACTION cancel
            EXIT INPUT
    END INPUT
END FUNCTION

-- ==============================================================
-- Delete Selected Line
-- ==============================================================
FUNCTION delete_line(p_curr_row INTEGER)  -- FIX: Added parameter
    IF arr_sa_ord_lines.getLength() = 0 THEN
        CALL utils_globals.show_info("No line to delete.")
        RETURN
    END IF

    IF p_curr_row < 1 OR p_curr_row > arr_sa_ord_lines.getLength() THEN
        CALL utils_globals.show_info("Invalid line selected.")
        RETURN
    END IF

    CALL arr_sa_ord_lines.deleteElement(p_curr_row)  -- FIX: Use correct method
    CALL utils_globals.show_info("Line deleted.")
END FUNCTION

-- ==============================================================
-- Save Quote (Header + Lines)
-- ==============================================================
FUNCTION save_quote()
    DEFINE exists INTEGER

    SELECT COUNT(*) INTO exists FROM sa30_quo_hdr WHERE doc_no = qt_hdr_rec.doc_no

    IF exists = 0 THEN
        INSERT INTO sa30_quo_hdr VALUES qt_hdr_rec.*
        CALL utils_globals.msg_saved()
    ELSE
        UPDATE sa30_quo_hdr SET sa30_quo_hdr.* = qt_hdr_rec.* WHERE doc_no = qt_hdr_rec.doc_no
        CALL utils_globals.msg_updated()
    END IF

    -- Save lines
    DELETE FROM sa30_quo_det WHERE doc_no = qt_hdr_rec.doc_no
    FOR curr_idx = 1 TO arr_sa_ord_lines.getLength()
        INSERT INTO sa30_quo_det VALUES arr_sa_ord_lines[curr_idx].*
    END FOR
END FUNCTION

-- ==============================================================
-- Delete Quote
-- ==============================================================
FUNCTION delete_qt(p_doc_no INTEGER)
    DEFINE ok SMALLINT

    IF p_doc_no IS NULL THEN
        CALL utils_globals.show_info("No quote selected for deletion.")
        RETURN
    END IF

    LET ok = utils_globals.show_confirm("Delete this quote?", "Confirm Delete")

    IF NOT ok THEN
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    DELETE FROM sa30_quo_det WHERE doc_no = p_doc_no
    DELETE FROM sa30_quo_hdr WHERE doc_no = p_doc_no
    CALL utils_globals.msg_deleted()
END FUNCTION

-- ==============================================================
-- Navigation
-- ==============================================================
PRIVATE FUNCTION move_record(dir SMALLINT)
    DEFINE new_idx INTEGER

    IF arr_codes.getLength() == 0 THEN
        CALL utils_globals.show_info("No records to navigate.")
        RETURN
    END IF

    LET new_idx = utils_globals.navigate_records(arr_codes, curr_idx, dir)
    LET curr_idx = new_idx
    CALL load_quote(arr_codes[curr_idx])
END FUNCTION
