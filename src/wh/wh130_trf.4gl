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
IMPORT FGL utils_global_lkup

SCHEMA demoappdb -- Use correct schema name
-- ==============================================================
-- DEFINATION
-- ==============================================================

-- Warehouse transaction record structure
TYPE wh_trans_t RECORD LIKE wh30_trans.*

DEFINE m_wh_trans_rec wh_trans_t 

DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

DEFINE dlg ui.Dialog

-- ==============================================================
-- Init module
-- ==============================================================

FUNCTION init_wh_trf_module()
    CALL utils_globals.populate_status_combo("status")
    LET is_edit_mode = FALSE

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME m_wh_trans_rec.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "transaction")

            BEFORE INPUT
                LET dlg = ui.Dialog.getCurrent()
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)

            ON ACTION new ATTRIBUTES(TEXT = "Create", IMAGE = "new")
                CALL new_transaction()

            ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
                IF utils_globals.is_empty(m_wh_trans_rec.id) THEN
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

            ON ACTION PREVIOUS ATTRIBUTES(TEXT = "Previous", IMAGE = "prev")
                CALL move_record(-1)
            ON ACTION NEXT ATTRIBUTES(TEXT = "Next", IMAGE = "next")
                CALL move_record(1)

            ON ACTION QUIT ATTRIBUTES(TEXT = "Quit", IMAGE = "quit")
                EXIT DIALOG

            BEFORE FIELD trans_date, wh_code, trans_type, reference, status
                IF NOT is_edit_mode THEN
                    CALL utils_globals.show_info("Click Edit to modify.")
                    NEXT FIELD id
                END IF
        END INPUT

        BEFORE DIALOG
            CALL select_transactions("1=1")
    END DIALOG
END FUNCTION


-- ==============================================================
-- Choose transfer transaction to open record details
-- ==============================================================
FUNCTION select_transactions(whereClause STRING)
    DEFINE code STRING
    DEFINE idx INTEGER

    CALL arr_codes.clear()
    LET idx = 0

    DECLARE c_trans CURSOR FROM "SELECT id FROM wh30_trans WHERE "
        || whereClause
        || " ORDER BY id DESC"

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

-- ==============================================================
-- Load transfer transactions
-- ==============================================================
FUNCTION load_transaction(p_code STRING)

    SELECT * INTO m_wh_trans_rec.*
        FROM wh30_trans
        WHERE id = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME m_wh_trans_rec.*
    END IF
END FUNCTION

-- ==============================================================
-- Navigate records
-- ==============================================================
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

-- ==============================================================
-- Add new transaction to the transactions table
-- ==============================================================
FUNCTION new_transaction()
    DEFINE new_id STRING

    OPTIONS INPUT WRAP
    OPEN WINDOW w_new WITH FORM "wh130_trans" ATTRIBUTES(STYLE = "dialog")

    INITIALIZE m_wh_trans_rec.* TO NULL

    LET m_wh_trans_rec.trans_date = TODAY
    LET m_wh_trans_rec.status = 'draft'
    LET m_wh_trans_rec.created_by = utils_globals.get_random_user()

    DISPLAY BY NAME m_wh_trans_rec.*

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME m_wh_trans_rec.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_transaction")

            ON ACTION save ATTRIBUTES(TEXT = "Save")
                IF validateTransactionFields() THEN
                    IF checkTransactionUniqueness() THEN
                        CALL save_transaction()
                        LET new_id = m_wh_trans_rec.id
                        EXIT DIALOG
                    END IF
                END IF

            ON ACTION cancel
                LET new_id = NULL
                EXIT DIALOG
        END INPUT
    END DIALOG

    CLOSE WINDOW w_new

    IF new_id IS NOT NULL THEN
        CALL load_transaction(new_id)
        CALL arr_codes.clear()
        LET arr_codes[1] = new_id
        LET curr_idx = 1
    END IF
END FUNCTION

-- ==============================================================
-- Save transactions
-- ==============================================================
FUNCTION save_transaction()

    DEFINE exists INTEGER
    TRY
    SELECT COUNT(*)
        INTO exists
        FROM wh30_trans
        WHERE id = m_wh_trans_rec.id

    IF exists = 0 THEN
        INSERT INTO wh30_trans
            VALUES m_wh_trans_rec.*
        CALL utils_globals.msg_saved()
    ELSE
        UPDATE wh30_trans
            SET wh30_trans.* = m_wh_trans_rec.*
            WHERE id = m_wh_trans_rec.id
        CALL utils_globals.msg_updated()
    END IF
    CALL load_transaction(m_wh_trans_rec.id)
    CATCH
        CALL utils_globals.show_sql_error( 'Error saving record: ' || SQLERRMESSAGE)
    END TRY
END FUNCTION

-- ==============================================================
-- Delete Transaction
-- ==============================================================
FUNCTION delete_transaction()
    IF utils_globals.is_empty(m_wh_trans_rec.id) THEN
        CALL utils_globals.show_info("No transaction selected for deletion.")
        RETURN
    END IF

    IF utils_globals.show_confirm(
        "Delete transaction: " || m_wh_trans_rec.id || "?",
        "Confirm Delete") THEN
        DELETE FROM wh30_trans WHERE id = m_wh_trans_rec.id
        CALL utils_globals.msg_deleted()
        CALL select_transactions("1=1")
    END IF
END FUNCTION

-- ==============================================================
-- Validate transaction fields
-- ==============================================================
FUNCTION validateTransactionFields() RETURNS BOOLEAN
    IF utils_globals.is_empty(m_wh_trans_rec.id) THEN
        CALL utils_globals.show_error("Transaction Number is required.")
        RETURN FALSE
    END IF
    IF m_wh_trans_rec.trans_date IS NULL THEN
        CALL utils_globals.show_error("Transaction Date is required.")
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION

-- ==============================================================
-- Check for duplicates
-- ==============================================================
FUNCTION checkTransactionUniqueness() RETURNS BOOLEAN
    DEFINE count INTEGER
    SELECT COUNT(*)
        INTO count
        FROM wh30_trans
        WHERE id = m_wh_trans_rec.id
    IF count > 0 THEN
        CALL utils_globals.show_error("Transaction number already exists.")
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION
