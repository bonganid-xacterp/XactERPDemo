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

SCHEMA demoapp_db

-- Transaction record structure
TYPE bin_trans_t RECORD LIKE wb31_trf_det.*

DEFINE rec_wb_trans bin_trans_t
DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

DEFINE dlg ui.Dialog

-- main program 
MAIN
    IF NOT utils_globals.initialize_application() THEN
        EXIT PROGRAM 1
    END IF

    OPEN WINDOW w_wb130 WITH FORM "wb130_trans" ATTRIBUTES(STYLE = "main")
    CALL init_wb130_trans_module()
    CLOSE WINDOW w_wb130
END MAIN

-- module init
FUNCTION init_wb130_trans_module()
    CALL utils_globals.populate_status_combo("status")
    LET is_edit_mode = FALSE

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_wb_trans.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "bin_transaction")

            BEFORE INPUT
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)

            ON ACTION new ATTRIBUTES(TEXT = "Create", IMAGE = "new")
                CALL new_transaction()

           ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
                IF rec_wb_trans.stock_code IS NULL OR rec_wb_trans.stock_code = "" THEN
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

-- select transaction
FUNCTION select_transactions(whereClause STRING)
    DEFINE code STRING
    DEFINE idx INTEGER

    CALL arr_codes.clear()
    LET idx = 0

    DECLARE c_trans CURSOR FROM "SELECT stock_code FROM wb30_trans WHERE "
        || whereClause
        || " ORDER BY stock_code DESC"

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

-- load transaction
FUNCTION load_transaction(p_code STRING)

    SELECT * INTO rec_wb_trans.* FROM wb31_trf_det  WHERE stock_code = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_wb_trans.*
    END IF
END FUNCTION

-- navigate records
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

--new bin transaction
FUNCTION new_transaction()

    INITIALIZE rec_wb_trans.* TO NULL
        
    DISPLAY BY NAME rec_wb_trans.*
    
    LET is_edit_mode = TRUE
    
    CALL dlg.setActionActive("save", TRUE)
    CALL dlg.setActionActive("edit", FALSE)
    
    MESSAGE "Enter new transaction details, then click Update to save."
    
END FUNCTION

-- save transaction
FUNCTION save_transaction()
    DEFINE exists INTEGER

    IF NOT validate_fields() THEN
        RETURN
    END IF

    SELECT COUNT(*)
        INTO exists
        FROM wb30_trans
        WHERE stock_code = rec_wb_trans.stock_code

    IF exists = 0 THEN
    
        INSERT INTO wb31_trf_det VALUES rec_wb_trans.*
        
        CALL utils_globals.msg_saved()
        CALL select_transactions("1=1")
        CALL set_curr_idx_by_code(rec_wb_trans.stock_code)
        
    ELSE
        UPDATE wb31_trf_det SET wb31_trf_det = rec_wb_trans.stock_code WHERE stock_code = rec_wb_trans.stock_code

        CALL utils_globals.msg_updated()
        
    END IF
    
    CALL load_transaction(rec_wb_trans.stock_code)
    
END FUNCTION

-- delete transaction
FUNCTION delete_transaction()

    IF utils_globals.is_empty(rec_wb_trans.stock_code) THEN
        CALL utils_globals.show_info("No transaction selected for deletion.")
        RETURN
    END IF

    IF utils_globals.show_confirm(
        "Delete transaction: " || rec_wb_trans.stock_code || "?",
        "Confirm Delete") THEN
        DELETE FROM wb31_trf_det WHERE wb31_trf_det.stock_code = rec_wb_trans.stock_code
        
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
    IF utils_globals.is_empty(rec_wb_trans.stock_code) THEN
        CALL utils_globals.show_error("Transaction Number is required.")
        RETURN FALSE
    END IF
    IF rec_wb_trans.qnty IS NULL THEN
        CALL utils_globals.show_error("Transaction Date is required.")
        RETURN FALSE
    END IF
   
    RETURN TRUE
END FUNCTION
