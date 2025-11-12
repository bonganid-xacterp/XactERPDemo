-- ==============================================================
-- Program   : wh30_trf_hdr.4gl
-- Purpose   : Warehouse Transfer Header maintenance
-- Module    : Warehouse (wh)
-- Number    : 30
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Header information for warehouse-to-warehouse transfers
--              Links to wh31_det for transfer line details
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoappdb -- Use correct schema name

-- Warehouse transfer header record structure
TYPE transfer_hdr_t RECORD LIKE wh30_trf_hdr.*

DEFINE rec_hdr transfer_hdr_t
DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

DEFINE dlg ui.Dialog

MAIN
    IF NOT utils_globals.initialize_application() THEN
        EXIT PROGRAM 1
    END IF

    OPEN WINDOW w_wh30 WITH FORM "wh30_trf_hdr" ATTRIBUTES(STYLE = "main")
    CALL run_wh_transfer()
    CLOSE WINDOW w_wh30
END MAIN

FUNCTION run_wh_transfer()
    CALL utils_globals.populate_status_combo("status")
    LET is_edit_mode = FALSE

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_hdr.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "transfer_header")

            BEFORE INPUT
                CALL dlg.setActionActive("save", FALSE)
                CALL dlg.setActionActive("edit", TRUE)

            ON ACTION new ATTRIBUTES(TEXT = "Create", IMAGE = "new")
                CALL new_transfer()

            ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
                IF utils_globals.is_empty(rec_hdr.trans_no) THEN
                    CALL utils_globals.show_info("No record selected to edit.")
                ELSE
                    LET is_edit_mode = TRUE
                    CALL dlg.setActionActive("save", TRUE)
                    CALL dlg.setActionActive("edit", FALSE)
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
                IF is_edit_mode THEN
                    CALL save_transfer()
                    LET is_edit_mode = FALSE
                    CALL dlg.setActionActive("save", FALSE)
                    CALL dlg.setActionActive("edit", TRUE)
                END IF

            ON ACTION DELETE ATTRIBUTES(TEXT = "Delete", IMAGE = "delete")
                CALL delete_transfer()

            ON ACTION details ATTRIBUTES(TEXT = "Details", IMAGE = "detail")
                CALL show_transfer_details()

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

            BEFORE FIELD rec_mast
                IF NOT is_edit_mode THEN
                    CALL utils_globals.show_info("Click Edit to modify.")
                    NEXT FIELD trans_no
                END IF
        END INPUT

        BEFORE DIALOG
            CALL select_transfers("1=1")
    END DIALOG
END FUNCTION

FUNCTION select_transfers(whereClause STRING)
    DEFINE code STRING
    DEFINE idx INTEGER

    CALL arr_codes.clear()
    LET idx = 0

    DECLARE c_trans CURSOR FROM "SELECT trans_no FROM wh30_trf_hdr WHERE "
        || whereClause
        || " ORDER BY trans_no DESC"

    FOREACH c_trans INTO code
        LET idx = idx + 1
        LET arr_codes[idx] = code
    END FOREACH
    FREE c_trans

    IF arr_codes.getLength() > 0 THEN
        LET curr_idx = 1
        CALL load_transfer(arr_codes[curr_idx])
    END IF
END FUNCTION

-- load transfer
FUNCTION load_transfer(p_code STRING)
    SELECT rec_hdr.* INTO rec_hdr.* FROM wh30_trf_hdr WHERE trans_no = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_hdr.*
    END IF
END FUNCTION

-- navigate record
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

    CALL load_transfer(arr_codes[curr_idx])
    LET is_edit_mode = FALSE
    CALL dlg.setActionActive("save", FALSE)
    CALL dlg.setActionActive("edit", TRUE)
END FUNCTION

-- new transfer
FUNCTION new_transfer()
    DEFINE new_trans_no STRING

    OPEN WINDOW w_new WITH FORM "wh30_trf_hdr" ATTRIBUTES(STYLE = "dialog")
    INITIALIZE rec_hdr.* TO NULL
    LET rec_hdr.trans_date = TODAY
    LET rec_hdr.status = 1

    DISPLAY BY NAME rec_hdr.*

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_hdr.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_transfer")

            ON ACTION save ATTRIBUTES(TEXT = "Save")
                IF validate_transfer_fields() THEN
                    IF check_transfer_uniqueness() THEN
                        INSERT INTO wh30_trf_hdr VALUES rec_hdr.*
                        CALL utils_globals.show_success(
                            "Transfer saved successfully.")
                        LET new_trans_no = rec_hdr.trans_no
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
        CALL load_transfer(new_trans_no)
        CALL arr_codes.clear()
        LET arr_codes[1] = new_trans_no
        LET curr_idx = 1
    END IF
END FUNCTION

-- save warehouse transfer
FUNCTION save_transfer()
    DEFINE exists INTEGER
    SELECT COUNT(*) INTO exists FROM wh30_trf_hdr WHERE trans_no = rec_hdr.trans_no

    IF exists = 0 THEN

        INSERT INTO wh30_trf_hdr VALUES rec_hdr.*
        
        CALL utils_globals.msg_saved()
    ELSE
    
        UPDATE wh30_trf_hdr SET wh30_trf_hdr.* = rec_hdr.* 
            WHERE trans_no = rec_hdr.trans_no
            
        CALL utils_globals.msg_updated()
        
    END IF
    CALL load_transfer(rec_hdr.trans_no)
END FUNCTION

-- delete warehouse transfer
FUNCTION delete_transfer()
    IF utils_globals.is_empty(rec_hdr.trans_no) THEN
        CALL utils_globals.show_info("No transfer selected for deletion.")
        RETURN
    END IF

    IF utils_globals.show_confirm(
        "Delete transfer: " || rec_hdr.trans_no || "?", "Confirm Delete") THEN
        BEGIN WORK
        TRY
            -- Delete details first
            DELETE FROM wh31_det WHERE trans_no = rec_hdr.trans_no
            -- Delete header
            DELETE FROM wh30_trf_hdr WHERE trans_no = rec_hdr.trans_no
            COMMIT WORK
            CALL utils_globals.msg_deleted()
            CALL select_transfers("1=1")
        CATCH
            ROLLBACK WORK
            CALL utils_globals.msg_delete_failed()
        END TRY
    END IF
END FUNCTION

--show transfer details
FUNCTION show_transfer_details()
    IF utils_globals.is_empty(rec_hdr.trans_no) THEN
        CALL utils_globals.show_info("No transfer selected.")
        RETURN
    END IF

    -- This would open the detail maintenance window
    CALL utils_globals.show_info("Transfer details for: " || rec_hdr.trans_no)
    -- RUN "wh31_det " || rec_hdr.trans_no
END FUNCTION

-- validate the transfer fields
FUNCTION validate_transfer_fields() RETURNS BOOLEAN
    IF utils_globals.is_empty(rec_hdr.trans_no) THEN
        CALL utils_globals.show_error("Transfer Number is required.")
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
        CALL utils_globals.show_error("Transfer Date is required.")
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION

--check transfer uniqueness
FUNCTION check_transfer_uniqueness() RETURNS BOOLEAN
    DEFINE l_count INTEGER
    SELECT COUNT(*) INTO l_count FROM wh30_trf_hdr WHERE trans_no = rec_hdr.trans_no
    IF l_count > 0 THEN
        CALL utils_globals.show_error("Transfer number already exists.")
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION
