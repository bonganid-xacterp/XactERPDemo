-- ==============================================================
-- Program   : sa132_ord.4gl
-- Purpose   : Sales Invoice Program
-- Module    : Sales Invoice (sa)
-- Number    : 132
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoapp_db

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE invoice_hdr_t RECORD LIKE sa32_inv_hdr.*
DEFINE rec_inv invoice_hdr_t

DEFINE arr_inv_line DYNAMIC ARRAY OF RECORD LIKE sa32_inv_det.*

DEFINE arr_codes  DYNAMIC ARRAY OF STRING
DEFINE curr_idx   INTEGER

-- ==============================================================
-- Show Invoice
-- ==============================================================
PUBLIC FUNCTION show_invoice(p_doc_no INTEGER)
    -- Open the invoice window inside the MDI container
    OPTIONS INPUT WRAP
    OPEN WINDOW w_inv WITH FORM "sa131_invoice" ATTRIBUTES(STYLE="child")

    -- Load header + lines
    CALL load_invoice(p_doc_no)

    -- View/edit the invoice
    CALL edit_invoice_dialog()

    CLOSE WINDOW w_inv
END FUNCTION

-- ==============================================================
-- Load invoice Header and Lines
-- ==============================================================
FUNCTION load_invoice(p_doc_no INTEGER)
    DEFINE idx INTEGER

    INITIALIZE rec_inv.* TO NULL
    CALL arr_inv_line.clear()

    SELECT * INTO rec_inv.* FROM sa32_inv_hdr WHERE doc_no = p_doc_no

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_inv.*
        -- Load lines for this invoice
        DECLARE c_lines CURSOR FOR
            SELECT * FROM sa32_inv_det WHERE doc_no = p_doc_no ORDER BY line_no

        FOREACH c_lines INTO arr_inv_line[idx + 1].*
            LET idx = idx + 1
        END FOREACH

        CLOSE c_lines
        FREE c_lines
    ELSE
        CALL utils_globals.show_error("invoice not found.")
    END IF
END FUNCTION

-- ==============================================================
-- Edit / View invoice (dialog)
-- ==============================================================
FUNCTION edit_invoice_dialog()
    DIALOG ATTRIBUTES(UNBUFFERED)

        -- Header section fields
        INPUT BY NAME rec_inv.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME="invoice_header")

            ON ACTION save ATTRIBUTES(TEXT="Save",IMAGE="filesave")
                CALL save_invoice()
                EXIT DIALOG

            ON ACTION close ATTRIBUTES(TEXT="Close",IMAGE="exit")
                EXIT DIALOG
        END INPUT

        -- Lines section (display array for invoice details)
        DISPLAY ARRAY arr_inv_line TO sr_invoice_lines.*

            ON ACTION add
                CALL add_invoice_line()
            ON ACTION delete
               CALL delete_invoice_line(arr_curr())
            ON ACTION save
                CALL save_invoice()
            ON ACTION close
                EXIT DIALOG
        END DISPLAY
    END DIALOG
END FUNCTION

-- ==============================================================
-- Add invoice Line
-- ==============================================================
FUNCTION add_invoice_line()
    DEFINE new_line RECORD LIKE sa32_inv_det.*
    LET new_line.line_no = arr_inv_line.getLength() + 1

    INPUT BY NAME new_line.*
        ATTRIBUTES(WITHOUT DEFAULTS, NAME="new_line")

        ON ACTION save
            LET arr_inv_line[arr_inv_line.getLength() + 1] = new_line
            CALL utils_globals.show_info("Line added.")
            EXIT INPUT

        ON ACTION cancel
            EXIT INPUT
    END INPUT
END FUNCTION

-- ==============================================================
-- Delete Selected Line
-- ==============================================================
FUNCTION delete_invoice_line(p_curr_row INTEGER)  -- FIX: Added parameter
    IF arr_inv_line.getLength() = 0 THEN
        CALL utils_globals.show_info("No line to delete.")
        RETURN
    END IF

    IF p_curr_row < 1 OR p_curr_row > arr_inv_line.getLength() THEN
        CALL utils_globals.show_info("Invalid line selected.")
        RETURN
    END IF

    CALL arr_inv_line.deleteElement(p_curr_row)  -- FIX: Use correct method
    CALL utils_globals.show_info("Line deleted.")
END FUNCTION

-- ==============================================================
-- Save invoice (Header + Lines)
-- ==============================================================
FUNCTION save_invoice()
    DEFINE exists INTEGER

    SELECT COUNT(*) INTO exists FROM sa32_inv_hdr WHERE doc_no = rec_inv.doc_no

    IF exists = 0 THEN
        INSERT INTO sa32_inv_hdr VALUES rec_inv.*
        CALL utils_globals.msg_saved()
    ELSE
        UPDATE sa32_inv_hdr SET sa32_inv_hdr.* = rec_inv.* WHERE doc_no = rec_inv.doc_no
        CALL utils_globals.msg_updated()
    END IF

    -- Save lines
    DELETE FROM sa32_inv_det WHERE doc_no = rec_inv.doc_no
    FOR curr_idx = 1 TO arr_inv_line.getLength()
        INSERT INTO sa32_inv_det VALUES arr_inv_line[curr_idx].*
    END FOR
END FUNCTION

-- ==============================================================
-- Delete invoice
-- ==============================================================
FUNCTION delete_inv(p_doc_no INTEGER)
    DEFINE ok SMALLINT

    IF p_doc_no IS NULL THEN
        CALL utils_globals.show_info("No invoice selected for deletion.")
        RETURN
    END IF

    LET ok = utils_globals.show_confirm("Delete this invoice?", "Confirm Delete")

    IF NOT ok THEN
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    DELETE FROM sa32_inv_det WHERE doc_no = p_doc_no
    DELETE FROM sa32_inv_hdr WHERE doc_no = p_doc_no
    CALL utils_globals.msg_deleted()
END FUNCTION

-- ==============================================================
-- Navigation
-- ==============================================================
FUNCTION move_record(dir SMALLINT)
    DEFINE new_idx INTEGER

    IF arr_codes.getLength() == 0 THEN
        CALL utils_globals.show_info("No records to navigate.")
        RETURN
    END IF

    LET new_idx = utils_globals.navigate_records(arr_codes, curr_idx, dir)
    LET curr_idx = new_idx
    CALL load_invoice(arr_codes[curr_idx])
END FUNCTION
