-- ==============================================================
-- Program   : wh30_trans.4gl
-- Purpose   : Warehouse Transactions program
-- Module    : Warehouse (wh)
-- Number    : 30
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoapp_db

TYPE trans_hdr_t RECORD
    trans_no STRING,
    from_wh STRING,
    to_wh STRING,
    trans_date DATE,
    status SMALLINT
END RECORD

TYPE trans_det_t RECORD
    line_no INTEGER,
    stock_code STRING,
    description STRING,
    qty DECIMAL(10, 2),
    unit STRING
END RECORD

DEFINE rec_hdr trans_hdr_t
DEFINE arr_det DYNAMIC ARRAY OF trans_det_t
DEFINE curr_hdr_idx INTEGER
DEFINE curr_det_idx INTEGER
DEFINE is_edit_mode SMALLINT

DEFINE dlg ui.Dialog

MAIN
    IF NOT utils_globals.initialize_application() THEN
        EXIT PROGRAM 1
    END IF

    OPEN WINDOW w_wh30_trans WITH FORM "wh30_trans" ATTRIBUTES(STYLE = "main")
    CALL init_module()
    CLOSE WINDOW w_wh30_trans
END MAIN

FUNCTION init_module()
    CALL utils_globals.populate_status_combo("status")
    LET is_edit_mode = FALSE

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_hdr.* ATTRIBUTES(WITHOUT DEFAULTS, NAME = "header")

            BEFORE INPUT
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)

            ON ACTION new ATTRIBUTES(TEXT = "New Transaction", IMAGE = "new")
                CALL new_transaction()

            ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
                IF utils_globals.is_empty(rec_hdr.trans_no) THEN
                    CALL utils_globals.show_info(
                        "No transaction selected to edit.")
                ELSE
                    LET is_edit_mode = TRUE
                    CALL dlg.setActionActive("save", TRUE)
                    CALL dlg.setActionActive("edit", FALSE)
                END IF

            ON ACTION save
                ATTRIBUTES(TEXT = "Save Transaction", IMAGE = "filesave")
                IF is_edit_mode THEN
                    CALL save_transaction()
                    LET is_edit_mode = FALSE
                    CALL dlg.setActionActive("save", FALSE)
                    CALL dlg.setActionActive("edit", TRUE)
                END IF

            BEFORE FIELD from_wh, to_wh, trans_date, status
                IF NOT is_edit_mode THEN
                    CALL utils_globals.show_info("Click Edit to modify.")
                    NEXT FIELD trans_no
                END IF
        END INPUT

        INPUT ARRAY arr_det
            FROM details.*
            ATTRIBUTES(COUNT = arr_det.getLength(), MAXCOUNT = 100)

            BEFORE ROW
                LET curr_det_idx = arr_curr()

            ON ACTION add_line ATTRIBUTES(TEXT = "Add Line", IMAGE = "add")
                IF is_edit_mode THEN
                    CALL add_detail_line()
                ELSE
                    CALL utils_globals.show_info("Click Edit to modify.")
                END IF

            ON ACTION delete_line
                ATTRIBUTES(TEXT = "Delete Line", IMAGE = "delete")
                IF is_edit_mode THEN
                    CALL delete_detail_line()
                ELSE
                    CALL utils_globals.show_info("Click Edit to modify.")
                END IF

            BEFORE FIELD stock_code, description, qty, unit
                IF NOT is_edit_mode THEN
                    CALL utils_globals.show_info("Click Edit to modify.")
                    NEXT FIELD line_no
                END IF
        END INPUT

        ON ACTION QUIT ATTRIBUTES(TEXT = "Quit", IMAGE = "quit")
            EXIT DIALOG

        BEFORE DIALOG
            CALL load_sample_transaction()
    END DIALOG
END FUNCTION

FUNCTION load_sample_transaction()
    -- Load a sample transaction for demonstration
    INITIALIZE rec_hdr.* TO NULL
    LET rec_hdr.trans_no = "TRN001"
    LET rec_hdr.from_wh = "WH01"
    LET rec_hdr.to_wh = "WH02"
    LET rec_hdr.trans_date = TODAY
    LET rec_hdr.status = 1

    CALL arr_det.clear()
    LET arr_det[1].line_no = 1
    LET arr_det[1].stock_code = "STK001"
    LET arr_det[1].description = "Sample Item"
    LET arr_det[1].qty = 10.00
    LET arr_det[1].unit = "PCS"

    DISPLAY BY NAME rec_hdr.*
END FUNCTION

FUNCTION new_transaction()
    OPEN WINDOW w_new_trans WITH FORM "wh30_trans" ATTRIBUTES(STYLE = "dialog")

    INITIALIZE rec_hdr.* TO NULL
    CALL arr_det.clear()

    LET rec_hdr.trans_date = TODAY
    LET rec_hdr.status = 1

    DISPLAY BY NAME rec_hdr.*

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_hdr.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_header")

            ON ACTION save ATTRIBUTES(TEXT = "Save")
                IF validateTransactionFields() THEN
                    CALL save_new_transaction()
                    EXIT DIALOG
                END IF

            ON ACTION cancel
                EXIT DIALOG
        END INPUT

        INPUT ARRAY arr_det
            FROM details.*
            ATTRIBUTES(COUNT = arr_det.getLength(), MAXCOUNT = 100)

            ON ACTION add_line ATTRIBUTES(TEXT = "Add Line", IMAGE = "add")
                CALL add_detail_line()

            ON ACTION delete_line
                ATTRIBUTES(TEXT = "Delete Line", IMAGE = "delete")
                CALL delete_detail_line()
        END INPUT
    END DIALOG

    CLOSE WINDOW w_new_trans
END FUNCTION

FUNCTION save_new_transaction()
    DEFINE i INTEGER

    TRY
        BEGIN WORK

        -- Insert header
        INSERT INTO wh30_hdr(
            trans_no, from_wh, to_wh, trans_date, status)
            VALUES(rec_hdr.trans_no,
                rec_hdr.from_wh,
                rec_hdr.to_wh,
                rec_hdr.trans_date,
                rec_hdr.status)

        -- Insert details
        FOR i = 1 TO arr_det.getLength()
            IF NOT utils_globals.is_empty(arr_det[i].stock_code) THEN
                INSERT INTO wh31_det(
                    trans_no, line_no, stock_code, description, qty, unit)
                    VALUES(rec_hdr.trans_no,
                        arr_det[i].line_no,
                        arr_det[i].stock_code,
                        arr_det[i].description,
                        arr_det[i].qty,
                        arr_det[i].unit)
            END IF
        END FOR

        COMMIT WORK
        CALL utils_globals.show_success("Transaction saved successfully.")

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            "Failed to save transaction: " || SQLCA.SQLERRM)
    END TRY
END FUNCTION

FUNCTION save_transaction()
    DEFINE i INTEGER

    TRY
        BEGIN WORK

        -- Update header
        UPDATE wh30_hdr
            SET from_wh = rec_hdr.from_wh,
                to_wh = rec_hdr.to_wh,
                trans_date = rec_hdr.trans_date,
                status = rec_hdr.status
            WHERE trans_no = rec_hdr.trans_no

        -- Delete existing details
        DELETE FROM wh31_det WHERE trans_no = rec_hdr.trans_no

        -- Insert updated details
        FOR i = 1 TO arr_det.getLength()
            IF NOT utils_globals.is_empty(arr_det[i].stock_code) THEN
                INSERT INTO wh31_det(
                    trans_no, line_no, stock_code, description, qty, unit)
                    VALUES(rec_hdr.trans_no,
                        arr_det[i].line_no,
                        arr_det[i].stock_code,
                        arr_det[i].description,
                        arr_det[i].qty,
                        arr_det[i].unit)
            END IF
        END FOR

        COMMIT WORK
        CALL utils_globals.msg_updated()

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            "Failed to update transaction: " || SQLCA.SQLERRM)
    END TRY
END FUNCTION

FUNCTION add_detail_line()
    DEFINE new_line INTEGER

    LET new_line = arr_det.getLength() + 1
    LET arr_det[new_line].line_no = new_line
    LET arr_det[new_line].qty = 0.00
END FUNCTION

FUNCTION delete_detail_line()
    DEFINE current_row INTEGER

    LET current_row = arr_curr()
    IF current_row > 0 AND current_row <= arr_det.getLength() THEN
        CALL arr_det.deleteElement(current_row)
        -- Renumber lines
        CALL renumber_lines()
    END IF
END FUNCTION

FUNCTION renumber_lines()
    DEFINE i INTEGER

    FOR i = 1 TO arr_det.getLength()
        LET arr_det[i].line_no = i
    END FOR
END FUNCTION

FUNCTION validateTransactionFields() RETURNS BOOLEAN
    IF utils_globals.is_empty(rec_hdr.trans_no) THEN
        CALL utils_globals.show_error("Transaction Number is required.")
        RETURN FALSE
    END IF
    IF utils_globals.is_empty(rec_hdr.from_wh) THEN
        CALL utils_globals.show_error("From Warehouse is required.")
        RETURN FALSE
    END IF
    IF utils_globals.is_empty(rec_hdr.to_wh) THEN
        CALL utils_globals.show_error("To Warehouse is required.")
        RETURN FALSE
    END IF
    IF rec_hdr.from_wh = rec_hdr.to_wh THEN
        CALL utils_globals.show_error(
            "From and To warehouses cannot be the same.")
        RETURN FALSE
    END IF
    IF rec_hdr.trans_date IS NULL THEN
        CALL utils_globals.show_error("Transaction Date is required.")
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION
