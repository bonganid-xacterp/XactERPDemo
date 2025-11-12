-- ==============================================================
-- Program   : wh130_trans.4gl
-- Purpose   : Warehouse Transaction processing
-- Module    : Warehouse (wh)
-- Number    : 130
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Process warehouse transactions (IN/OUT/TRANSFER)
--              Handles stock movements and inventory adjustments
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoappdb -- Use correct schema name

-- Warehouse transaction record structure
TYPE trans_t RECORD
    trans_no STRING, -- Transaction number (primary key)
    trans_date DATE, -- Transaction date
    wh_code STRING, -- Warehouse code
    trans_type STRING, -- Transaction type (IN/OUT/TRANSFER/ADJUST)
    stock_code STRING, -- Stock item code
    qty DECIMAL(10, 2), -- Quantity moved
    reference STRING, -- Reference document
    status SMALLINT -- Transaction status (0=Draft, 1=Confirmed)
END RECORD

DEFINE rec_trans trans_t
DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

DEFINE dlg ui.Dialog

--MAIN
--    IF NOT utils_globals.initialize_application() THEN
--        EXIT PROGRAM 1
--    END IF
--      OPTIONS INPUT WRAP
--    OPEN WINDOW w_wh130 WITH FORM "wh130_trans" ATTRIBUTES(STYLE = "main")
--    CALL init_module()
--    CLOSE WINDOW w_wh130
--END MAIN

--FUNCTION init_module()
--    CALL utils_globals.populate_status_combo("status")
--    LET is_edit_mode = FALSE
--
--    DIALOG ATTRIBUTES(UNBUFFERED)
--        INPUT BY NAME rec_trans.*
--            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "transaction")
--
--            BEFORE INPUT
--                CALL dlg.setActionActive("save", FALSE)
--                CALL dlg.setActionActive("edit", TRUE)
--
--            ON ACTION new ATTRIBUTES(TEXT = "Create", IMAGE = "new")
--                CALL new_transaction()
--
--            ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
--                IF utils_globals.is_empty(rec_trans.trans_no) THEN
--                    CALL utils_globals.show_info("No record selected to edit.")
--                ELSE
--                    LET is_edit_mode = TRUE
--                    CALL dlg.setActionActive("save", TRUE)
--                    CALL dlg.setActionActive("edit", FALSE)
--                END IF
--
--            ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
--                IF is_edit_mode THEN
--                    CALL save_transaction()
--                    LET is_edit_mode = FALSE
--                    CALL dlg.setActionActive("save", FALSE)
--                    CALL dlg.setActionActive("edit", TRUE)
--                END IF
--
--            ON ACTION DELETE ATTRIBUTES(TEXT = "Delete", IMAGE = "delete")
--                CALL delete_transaction()
--
--            ON ACTION FIRST ATTRIBUTES(TEXT = "First", IMAGE = "first")
--                CALL move_record(-2)
--            ON ACTION PREVIOUS ATTRIBUTES(TEXT = "Previous", IMAGE = "prev")
--                CALL move_record(-1)
--            ON ACTION NEXT ATTRIBUTES(TEXT = "Next", IMAGE = "next")
--                CALL move_record(1)
--            ON ACTION LAST ATTRIBUTES(TEXT = "Last", IMAGE = "last")
--                CALL move_record(2)
--            ON ACTION QUIT ATTRIBUTES(TEXT = "Quit", IMAGE = "quit")
--                EXIT DIALOG
--
--            BEFORE FIELD trans_date, wh_code, trans_type, reference, status
--                IF NOT is_edit_mode THEN
--                    CALL utils_globals.show_info("Click Edit to modify.")
--                    NEXT FIELD trans_no
--                END IF
--        END INPUT
--
--        BEFORE DIALOG
--            CALL select_transactions("1=1")
--    END DIALOG
--END FUNCTION

FUNCTION select_transactions(whereClause STRING)
    DEFINE code STRING
    DEFINE idx INTEGER

    CALL arr_codes.clear()
    LET idx = 0

    DECLARE c_trans CURSOR FROM "SELECT trans_no FROM wh30_trans WHERE "
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
    SELECT trans_no, trans_date, wh_code, trans_type, reference, status
        INTO rec_trans.*
        FROM wh30_trans
        WHERE trans_no = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_trans.*
    END IF
END FUNCTION

--FUNCTION move_record(dir SMALLINT)
--    CASE dir
--        WHEN -2
--            LET curr_idx = 1
--        WHEN -1
--            IF curr_idx > 1 THEN
--                LET curr_idx = curr_idx - 1
--            ELSE
--                CALL utils_globals.msg_start_of_list()
--                RETURN
--            END IF
--        WHEN 1
--            IF curr_idx < arr_codes.getLength() THEN
--                LET curr_idx = curr_idx + 1
--            ELSE
--                CALL utils_globals.msg_end_of_list()
--                RETURN
--            END IF
--        WHEN 2
--            LET curr_idx = arr_codes.getLength()
--    END CASE
--
--    CALL load_transaction(arr_codes[curr_idx])
--    LET is_edit_mode = FALSE
--    CALL dlg.setActionActive("save", FALSE)
--    CALL dlg.setActionActive("edit", TRUE)
--END FUNCTION

FUNCTION new_transaction()
    DEFINE new_trans_no STRING
    OPTIONS INPUT WRAP
    OPEN WINDOW w_new WITH FORM "wh130_trans" ATTRIBUTES(STYLE = "dialog")
    INITIALIZE rec_trans.* TO NULL
    LET rec_trans.trans_date = TODAY
    LET rec_trans.status = 1
    DISPLAY BY NAME rec_trans.*

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_trans.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_transaction")

            ON ACTION save ATTRIBUTES(TEXT = "Save")
                IF validateTransactionFields() THEN
                    IF checkTransactionUniqueness() THEN
                        INSERT INTO wh30_trans(
                            trans_no,
                            trans_date,
                            wh_code,
                            trans_type,
                            reference,
                            status)
                            VALUES(rec_trans.trans_no,
                                rec_trans.trans_date,
                                rec_trans.wh_code,
                                rec_trans.trans_type,
                                rec_trans.reference,
                                rec_trans.status)

                        CALL utils_globals.show_success(
                            "Transaction saved successfully.")
                        LET new_trans_no = rec_trans.trans_no
                        EXIT DIALOG
                    END IF
                END IF

            ON ACTION cancel
                LET new_trans_no = NULL
                EXIT DIALOG
        END INPUT
    END DIALOG

    CLOSE WINDOW w_new

    IF new_trans_no IS NOT NULL THEN
        CALL load_transaction(new_trans_no)
        CALL arr_codes.clear()
        LET arr_codes[1] = new_trans_no
        LET curr_idx = 1
    END IF
END FUNCTION

FUNCTION save_transaction()
    DEFINE exists INTEGER
    SELECT COUNT(*)
        INTO exists
        FROM wh30_trans
        WHERE trans_no = rec_trans.trans_no

    IF exists = 0 THEN
        INSERT INTO wh30_trans(
            trans_no, trans_date, wh_code, trans_type, reference, status)
            VALUES(rec_trans.trans_no,
                rec_trans.trans_date,
                rec_trans.wh_code,
                rec_trans.trans_type,
                rec_trans.reference,
                rec_trans.status)
        CALL utils_globals.msg_saved()
    ELSE
        UPDATE wh30_trans
            SET trans_date = rec_trans.trans_date,
                wh_code = rec_trans.wh_code,
                trans_type = rec_trans.trans_type,
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
        DELETE FROM wh30_trans WHERE trans_no = rec_trans.trans_no
        CALL utils_globals.msg_deleted()
        CALL select_transactions("1=1")
    END IF
END FUNCTION

FUNCTION validateTransactionFields() RETURNS BOOLEAN
    IF utils_globals.is_empty(rec_trans.trans_no) THEN
        CALL utils_globals.show_error("Transaction Number is required.")
        RETURN FALSE
    END IF
    IF rec_trans.trans_date IS NULL THEN
        CALL utils_globals.show_error("Transaction Date is required.")
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION

FUNCTION checkTransactionUniqueness() RETURNS BOOLEAN
    DEFINE count INTEGER
    SELECT COUNT(*)
        INTO count
        FROM wh30_trans
        WHERE trans_no = rec_trans.trans_no
    IF COUNT > 0 THEN
        CALL utils_globals.show_error("Transaction number already exists.")
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION
