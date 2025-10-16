-- ==============================================================
-- Program   : wb130_trans.4gl
-- Purpose   : Warehouse Bin Transaction processing
-- Module    : Warehouse Bin (wb)
-- Number    : 130
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Process bin transactions (IN/OUT/TRANSFER)
--              Handles stock movements between bins
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoapp_db

-- Transaction record structure
TYPE bin_trans_t RECORD
    trans_no STRING, -- Transaction number
    trans_date DATE, -- Transaction date
    wb_code STRING, -- Bin code
    wh_id STRING, -- Warehouse ID
    trans_type STRING, -- IN/OUT/TRANSFER
    stock_code STRING, -- Stock item code
    qty DECIMAL(10, 2), -- Quantity moved
    reference STRING, -- Reference document
    status SMALLINT -- Transaction status
END RECORD

DEFINE rec_trans bin_trans_t
DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

DEFINE dlg ui.Dialog

--MAIN
--    IF NOT utils_globals.initialize_application() THEN
--        EXIT PROGRAM 1
--    END IF
--
--    OPEN WINDOW w_wb130 WITH FORM "wb130_trans" ATTRIBUTES(STYLE = "main")
--    CALL init_module()
--    CLOSE WINDOW w_wb130
--END MAIN

FUNCTION init_module()
    CALL utils_globals.populate_status_combo("status")
    LET is_edit_mode = FALSE

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_trans.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "bin_transaction")

            BEFORE INPUT
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)

            ON ACTION new ATTRIBUTES(TEXT = "Create", IMAGE = "new")
                CALL new_transaction()

            ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
                IF utils_globals.is_empty(rec_trans.trans_no) THEN
                    CALL utils_globals.show_info("No record selected to edit.")
                ELSE
                    LET is_edit_mode = TRUE
                    CALL dlg.setActionActive("save", TRUE)
                    CALL dlg.setActionActive("edit", FALSE)
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
                IF is_edit_mode THEN
                    CALL save_transaction()
                    LET is_edit_mode = FALSE
                    CALL dlg.setActionActive("save", FALSE)
                    CALL dlg.setActionActive("edit", TRUE)
                END IF

            ON ACTION DELETE ATTRIBUTES(TEXT = "Delete", IMAGE = "delete")
                CALL delete_transaction()

            ON ACTION FIRST ATTRIBUTES(TEXT = "First", IMAGE = "first")
                CALL move_record(-2)
            ON ACTION PREVIOUS ATTRIBUTES(TEXT = "Previous", IMAGE = "prev")
                CALL move_record(-1)
            ON ACTION NEXT ATTRIBUTES(TEXT = "Next", IMAGE = "next")
                CALL move_record(1)
            ON ACTION LAST ATTRIBUTES(TEXT = "Last", IMAGE = "last")
                CALL move_record(2)
            ON ACTION QUIT ATTRIBUTES(TEXT = "Quit", IMAGE = "quit")
                EXIT DIALOG

            BEFORE FIELD trans_date,
                wb_code,
                wh_id,
                trans_type,
                qty,
                reference,
                status
                IF NOT is_edit_mode THEN
                    CALL utils_globals.show_info("Click Edit to modify.")
                    NEXT FIELD trans_no
                END IF
        END INPUT

        BEFORE DIALOG
            CALL select_transactions("1=1")
    END DIALOG
END FUNCTION

FUNCTION select_transactions(whereClause STRING)
    DEFINE code STRING
    DEFINE idx INTEGER

    CALL arr_codes.clear()
    LET idx = 0

    DECLARE c_trans CURSOR FROM "SELECT trans_no FROM wb30_trans WHERE "
        || whereClause
        || " ORDER BY trans_no DESC"

    FOREACH c_trans INTO code
        LET idx = idx + 1
        LET arr_codes[idx] = code
    END FOREACH
    FREE c_trans

    IF arr_codes.getLength() > 0 THEN
        LET curr_idx = 1
        CALL load_transaction(arr_codes[curr_idx])
    END IF
END FUNCTION

FUNCTION load_transaction(p_code STRING)
    SELECT trans_no,
        trans_date,
        wb_code,
        wh_id,
        trans_type,
        qty,
        reference,
        status
        INTO rec_trans.*
        FROM wb30_trans
        WHERE trans_no = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_trans.*
    END IF
END FUNCTION

FUNCTION move_record(dir SMALLINT)
    CASE dir
        WHEN -2
            LET curr_idx = 1
        WHEN -1
            IF curr_idx > 1 THEN
                LET curr_idx = curr_idx - 1
            ELSE
                CALL utils_globals.msg_start_of_list()
                RETURN
            END IF
        WHEN 1
            IF curr_idx < arr_codes.getLength() THEN
                LET curr_idx = curr_idx + 1
            ELSE
                CALL utils_globals.msg_end_of_list()
                RETURN
            END IF
        WHEN 2
            LET curr_idx = arr_codes.getLength()
    END CASE

    CALL load_transaction(arr_codes[curr_idx])
    LET is_edit_mode = FALSE
    CALL dlg.setActionActive("save", FALSE)
    CALL dlg.setActionActive("edit", TRUE)
END FUNCTION

FUNCTION new_transaction()
    INITIALIZE rec_trans.* TO NULL
    LET rec_trans.trans_date = TODAY
    LET rec_trans.qty = 0.00
    LET rec_trans.status = 1
    DISPLAY BY NAME rec_trans.*
    LET is_edit_mode = TRUE
    CALL dlg.setActionActive("save", TRUE)
    CALL dlg.setActionActive("edit", FALSE)
    MESSAGE "Enter new transaction details, then click Update to save."
END FUNCTION

FUNCTION save_transaction()
    DEFINE exists INTEGER

    IF NOT validateFields() THEN
        RETURN
    END IF

    SELECT COUNT(*)
        INTO exists
        FROM wb30_trans
        WHERE trans_no = rec_trans.trans_no

    IF exists = 0 THEN
        INSERT INTO wb30_trans(
            trans_no,
            trans_date,
            wb_code,
            wh_id,
            trans_type,
            qty,
            reference,
            status)
            VALUES(rec_trans.trans_no,
                rec_trans.trans_date,
                rec_trans.wb_code,
                rec_trans.wh_id,
                rec_trans.trans_type,
                rec_trans.qty,
                rec_trans.reference,
                rec_trans.status)
        CALL utils_globals.msg_saved()
        CALL select_transactions("1=1")
        CALL set_curr_idx_by_code(rec_trans.trans_no)
    ELSE
        UPDATE wb30_trans
            SET trans_date = rec_trans.trans_date,
                wb_code = rec_trans.wb_code,
                wh_id = rec_trans.wh_id,
                trans_type = rec_trans.trans_type,
                qty = rec_trans.qty,
                reference = rec_trans.reference,
                status = rec_trans.status
            WHERE trans_no = rec_trans.trans_no
        CALL utils_globals.msg_updated()
    END IF
    CALL load_transaction(rec_trans.trans_no)
END FUNCTION

FUNCTION delete_transaction()
    IF utils_globals.is_empty(rec_trans.trans_no) THEN
        CALL utils_globals.show_info("No transaction selected for deletion.")
        RETURN
    END IF

    IF utils_globals.show_confirm(
        "Delete transaction: " || rec_trans.trans_no || "?",
        "Confirm Delete") THEN
        DELETE FROM wb30_trans WHERE trans_no = rec_trans.trans_no
        CALL utils_globals.msg_deleted()
        CALL select_transactions("1=1")
    END IF
END FUNCTION

FUNCTION set_curr_idx_by_code(p_code STRING)
    DEFINE i INTEGER
    FOR i = 1 TO arr_codes.getLength()
        IF arr_codes[i] = p_code THEN
            LET curr_idx = i
            EXIT FOR
        END IF
    END FOR
END FUNCTION

FUNCTION validateFields() RETURNS BOOLEAN
    IF utils_globals.is_empty(rec_trans.trans_no) THEN
        CALL utils_globals.show_error("Transaction Number is required.")
        RETURN FALSE
    END IF
    IF rec_trans.trans_date IS NULL THEN
        CALL utils_globals.show_error("Transaction Date is required.")
        RETURN FALSE
    END IF
    IF utils_globals.is_empty(rec_trans.wb_code) THEN
        CALL utils_globals.show_error("Bin Code is required.")
        RETURN FALSE
    END IF
    IF utils_globals.is_empty(rec_trans.wh_id) THEN
        CALL utils_globals.show_error("Warehouse ID is required.")
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION
