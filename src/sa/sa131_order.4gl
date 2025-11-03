-- ==============================================================
-- Program   : sa130_ord.4gl
-- Purpose   : Sales Order Program
-- Module    : Sales Order (sa)
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
TYPE order_hdr_t RECORD LIKE sa31_ord_hdr.*
DEFINE rec_ord order_hdr_t

DEFINE arr_ord_line DYNAMIC ARRAY OF RECORD LIKE sa31_ord_det.*

DEFINE arr_codes  DYNAMIC ARRAY OF STRING
DEFINE curr_idx   INTEGER
--DEFINE is_edit_mode SMALLINT

-- ==============================================================
-- Public entry point (called from Debtors or MDI menu)
-- ==============================================================
PUBLIC FUNCTION show_order(p_doc_no INTEGER)
    -- Open the order window inside the MDI container
    OPTIONS INPUT WRAP
    OPEN WINDOW w_ord WITH FORM "sa131_order" ATTRIBUTES(STYLE="child")

    -- Load header + lines
    CALL load_order(p_doc_no)

    -- View/edit the order
    CALL edit_order_dialog()

    CLOSE WINDOW w_ord
END FUNCTION

-- ==============================================================
-- Load order Header and Lines
-- ==============================================================
FUNCTION load_order(p_doc_no INTEGER)
    DEFINE idx INTEGER

    INITIALIZE rec_ord.* TO NULL
    CALL arr_ord_line.clear()

    SELECT * INTO rec_ord.* FROM sa31_ord_hdr WHERE doc_no = p_doc_no

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_ord.*
        -- Load lines for this order
        DECLARE c_lines CURSOR FOR
            SELECT * FROM sa31_ord_det WHERE doc_no = p_doc_no ORDER BY line_no

        FOREACH c_lines INTO arr_ord_line[idx + 1].*
            LET idx = idx + 1
        END FOREACH

        CLOSE c_lines
        FREE c_lines
    ELSE
        CALL utils_globals.show_error("order not found.")
    END IF
END FUNCTION

-- ==============================================================
-- Edit / View order (dialog)
-- ==============================================================
FUNCTION edit_order_dialog()
    DIALOG ATTRIBUTES(UNBUFFERED)

        -- Header section fields
        INPUT BY NAME rec_ord.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME="order_header")

            ON ACTION save ATTRIBUTES(TEXT="Save",IMAGE="filesave")
                CALL save_order()
                EXIT DIALOG

            ON ACTION close ATTRIBUTES(TEXT="Close",IMAGE="exit")
                EXIT DIALOG
        END INPUT

        -- Lines section (display array for order details)
        DISPLAY ARRAY arr_ord_line TO sr_order_lines.*

            ON ACTION add
                CALL add_order_line()
            ON ACTION delete
               CALL delete_order_line(arr_curr())
            ON ACTION save
                CALL save_order()
            ON ACTION close
                EXIT DIALOG
        END DISPLAY
    END DIALOG
END FUNCTION

-- ==============================================================
-- Add order Line
-- ==============================================================
FUNCTION add_order_line()
    DEFINE new_line RECORD LIKE sa31_ord_det.*
    LET new_line.line_no = arr_ord_line.getLength() + 1

    INPUT BY NAME new_line.*
        ATTRIBUTES(WITHOUT DEFAULTS, NAME="new_line")

        ON ACTION save
            LET arr_ord_line[arr_ord_line.getLength() + 1] = new_line
            CALL utils_globals.show_info("Line added.")
            EXIT INPUT

        ON ACTION cancel
            EXIT INPUT
    END INPUT
END FUNCTION

-- ==============================================================
-- Delete Selected Line
-- ==============================================================
FUNCTION delete_order_line(p_curr_row INTEGER)  -- FIX: Added parameter
    IF arr_ord_line.getLength() = 0 THEN
        CALL utils_globals.show_info("No line to delete.")
        RETURN
    END IF

    IF p_curr_row < 1 OR p_curr_row > arr_ord_line.getLength() THEN
        CALL utils_globals.show_info("Invalid line selected.")
        RETURN
    END IF

    CALL arr_ord_line.deleteElement(p_curr_row)  -- FIX: Use correct method
    CALL utils_globals.show_info("Line deleted.")
END FUNCTION

-- ==============================================================
-- Save order (Header + Lines)
-- ==============================================================
FUNCTION save_order()
    DEFINE exists INTEGER

    SELECT COUNT(*) INTO exists FROM sa31_ord_hdr WHERE doc_no = rec_ord.doc_no

    IF exists = 0 THEN
        INSERT INTO sa31_ord_hdr VALUES rec_ord.*
        CALL utils_globals.msg_saved()
    ELSE
        UPDATE sa31_ord_hdr SET sa31_ord_hdr.* = rec_ord.* WHERE doc_no = rec_ord.doc_no
        CALL utils_globals.msg_updated()
    END IF

    -- Save lines
    DELETE FROM sa31_ord_det WHERE doc_no = rec_ord.doc_no
    FOR curr_idx = 1 TO arr_ord_line.getLength()
        INSERT INTO sa31_ord_det VALUES arr_ord_line[curr_idx].*
    END FOR
END FUNCTION

-- ==============================================================
-- Delete order
-- ==============================================================
FUNCTION delete_order(p_doc_no INTEGER)
    DEFINE ok SMALLINT

    IF p_doc_no IS NULL THEN
        CALL utils_globals.show_info("No order selected for deletion.")
        RETURN
    END IF

    LET ok = utils_globals.show_confirm("Delete this order?", "Confirm Delete")

    IF NOT ok THEN
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    DELETE FROM sa31_ord_det WHERE doc_no = p_doc_no
    DELETE FROM sa31_ord_hdr WHERE doc_no = p_doc_no
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
    CALL load_order(arr_codes[curr_idx])
END FUNCTION
