-- ==============================================================
-- Program      : wb31_trf_det.4gl
-- Purpose      : Warehouse Bin Transaction processing
-- Module       : Warehouse Bin (wb)
-- Number       : 130
-- Author       : Bongani Dlamini
-- Version      : Genero ver 3.20.10
-- Description  : Process bin transactions (IN/OUT/TRANSFER)
--                  Handles stock movements between bins
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoappdb

-- ==============================================================
-- Transaction record structure
-- ==============================================================

TYPE bin_trans_t RECORD LIKE wb31_trf_det.*

DEFINE wb_trans_rec bin_trans_t
DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

DEFINE dlg ui.Dialog

-- ==============================================================
-- main program 
-- ==============================================================
--MAIN
--    IF NOT utils_globals.initialize_application() THEN
--        EXIT PROGRAM 1
--    END IF
--
--    OPEN WINDOW w_wb130 WITH FORM "wb130_trans" ATTRIBUTES(STYLE = "main")
--    CALL init_wb_tfr_module()
--    CLOSE WINDOW w_wb130
--END MAIN

-- ==============================================================
-- module init
-- ==============================================================
FUNCTION init_wb_tfr_module()
    CALL utils_globals.populate_status_combo("status")
    LET is_edit_mode = FALSE

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME wb_trans_rec.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "bin_transaction")

            BEFORE INPUT
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)

            ON ACTION new ATTRIBUTES(TEXT = "Create", IMAGE = "new")
                CALL new_transaction()

           ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
                IF wb_trans_rec.id IS NULL OR wb_trans_rec.id = "" THEN
                    CALL utils_globals.show_info("No record selected to edit.")
                ELSE
                    LET is_edit_mode = TRUE
                    CALL DIALOG.setActionActive("save", TRUE)
                    CALL DIALOG.setActionActive("edit", FALSE)
                    CALL utils_globals.show_info(
                        "Edit mode enabled. Make changes and click Update to save.")
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

        END INPUT

        BEFORE DIALOG
            CALL select_transactions("1=1")
    END DIALOG
END FUNCTION

-- ==============================================================
-- select transaction
-- ==============================================================
FUNCTION select_transactions(whereClause STRING)
    DEFINE code STRING
    DEFINE idx INTEGER

    CALL arr_codes.clear()
    LET idx = 0

    DECLARE c_trans CURSOR FROM "SELECT id FROM wb30_trans WHERE "
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
-- load transaction
-- ==============================================================
FUNCTION load_transaction(p_code STRING)

    SELECT * INTO wb_trans_rec.* FROM wb31_trf_det  WHERE id = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME wb_trans_rec.*
    END IF
END FUNCTION

-- ==============================================================
-- navigate records
-- ==============================================================
PRIVATE FUNCTION move_record(dir SMALLINT)
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
--bin transaction
-- ==============================================================
FUNCTION new_transaction()

    INITIALIZE wb_trans_rec.* TO NULL
        
    DISPLAY BY NAME wb_trans_rec.*
    
    LET is_edit_mode = TRUE
    
    CALL dlg.setActionActive("save", TRUE)
    CALL dlg.setActionActive("edit", FALSE)
    
    MESSAGE "Enter new transaction details, then click Update to save."
    
END FUNCTION

-- ==============================================================
-- save transaction
-- ==============================================================
FUNCTION save_transaction()
    DEFINE exists INTEGER

    IF NOT validate_fields() THEN
        RETURN
    END IF

    SELECT COUNT(*) INTO EXISTS FROM wb130_trans
        WHERE id = wb_trans_rec.id

    IF exists = 0 THEN
    
        --INSERT INTO wb130_trf VALUES wb_trans_rec.*
        
        CALL utils_globals.msg_saved()
        CALL select_transactions("1=1")
        CALL set_curr_idx_by_code(wb_trans_rec.id)
        
    ELSE
        UPDATE wb31_trf_det SET wb31_trf_det = wb_trans_rec.id WHERE id = wb_trans_rec.id

        CALL utils_globals.msg_updated()
        
    END IF
    
    CALL load_transaction(wb_trans_rec.id)
    
END FUNCTION

-- delete transaction
FUNCTION delete_transaction()

    IF utils_globals.is_empty(wb_trans_rec.id) THEN
        CALL utils_globals.show_info("No transaction selected for deletion.")
        RETURN
    END IF

    IF utils_globals.show_confirm(
        "Delete transaction: " || wb_trans_rec.id || "?",
        "Confirm Delete") THEN
        DELETE FROM wb31_trf_det WHERE wb31_trf_det.id = wb_trans_rec.id
        
        CALL utils_globals.msg_deleted()
        CALL select_transactions("1=1")
        
    END IF
END FUNCTION

-- set record to be current
FUNCTION set_curr_idx_by_code(p_code STRING)
    DEFINE i INTEGER
    FOR i = 1 TO arr_codes.getLength()
        IF arr_codes[i] = p_code THEN
            LET curr_idx = i
            EXIT FOR
        END IF
    END FOR
END FUNCTION

-- validate fields on save
FUNCTION validate_fields() RETURNS BOOLEAN
    IF utils_globals.is_empty(wb_trans_rec.id) THEN
        CALL utils_globals.show_error("Transaction Number is required.")
        RETURN FALSE
    END IF
    IF wb_trans_rec.qnty IS NULL THEN
        CALL utils_globals.show_error("Transaction Date is required.")
        RETURN FALSE
    END IF
   
    RETURN TRUE
END FUNCTION
