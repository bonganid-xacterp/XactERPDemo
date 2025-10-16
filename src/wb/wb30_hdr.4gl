-- ==============================================================
-- Program   : wb30_hdr.4gl
-- Purpose   : Warehouse Bin Transfer Header maintenance
-- Module    : Warehouse Bin (wb)
-- Number    : 30
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Header information for bin-to-bin transfers
--              Links to wb31_det for transfer line details
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoapp_db

-- Transfer header record structure
TYPE bin_transfer_hdr_t RECORD
    trans_no STRING, -- Transfer transaction number
    from_bin STRING, -- Source bin code
    to_bin STRING, -- Destination bin code
    from_wh STRING, -- Source warehouse
    to_wh STRING, -- Destination warehouse
    trans_date DATE, -- Transfer date
    reference STRING, -- Reference document
    total_qty DECIMAL(10, 2), -- Total quantity transferred
    status SMALLINT -- Transfer status (0=Draft, 1=Confirmed)
END RECORD

DEFINE rec_hdr bin_transfer_hdr_t
DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

DEFINE dlg ui.Dialog

MAIN
    IF NOT utils_globals.initialize_application() THEN
        EXIT PROGRAM 1
    END IF

    OPEN WINDOW w_wb30 WITH FORM "wb30_hdr" ATTRIBUTES(STYLE = "main")
    CALL init_module()
    CLOSE WINDOW w_wb30
END MAIN

FUNCTION init_module()
    CALL utils_globals.populate_status_combo("status")
    LET is_edit_mode = FALSE

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_hdr.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "bin_transfer_header")

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

            BEFORE FIELD from_bin,
                to_bin,
                from_wh,
                to_wh,
                trans_date,
                reference,
                status
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

    DECLARE c_trans CURSOR FROM "SELECT trans_no FROM wb30_hdr WHERE "
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

FUNCTION load_transfer(p_code STRING)
    SELECT trans_no,
        from_bin,
        to_bin,
        from_wh,
        to_wh,
        trans_date,
        reference,
        total_qty,
        status
        INTO rec_hdr.*
        FROM wb30_hdr
        WHERE trans_no = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_hdr.*
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

    CALL load_transfer(arr_codes[curr_idx])
    LET is_edit_mode = FALSE
    CALL dlg.setActionActive("save", FALSE)
    CALL dlg.setActionActive("edit", TRUE)
END FUNCTION

FUNCTION new_transfer()

    INITIALIZE rec_hdr.* TO NULL
    LET rec_hdr.trans_date = TODAY
    LET rec_hdr.status = 1
    LET rec_hdr.total_qty = 0.00
    DISPLAY BY NAME rec_hdr.*
    LET is_edit_mode = TRUE
    CALL dlg.setActionActive("save", TRUE)
    CALL dlg.setActionActive("edit", FALSE)
    MESSAGE "Enter new transfer details, then click Update to save."
END FUNCTION

FUNCTION save_transfer()
    DEFINE exists INTEGER

    IF NOT validateFields() THEN
        RETURN
    END IF

    SELECT COUNT(*) INTO exists FROM wb30_hdr WHERE trans_no = rec_hdr.trans_no

    IF exists = 0 THEN
        INSERT INTO wb30_hdr(
            trans_no,
            from_bin,
            to_bin,
            from_wh,
            to_wh,
            trans_date,
            reference,
            total_qty,
            status)
            VALUES(rec_hdr.trans_no,
                rec_hdr.from_bin,
                rec_hdr.to_bin,
                rec_hdr.from_wh,
                rec_hdr.to_wh,
                rec_hdr.trans_date,
                rec_hdr.reference,
                rec_hdr.total_qty,
                rec_hdr.status)
        CALL utils_globals.msg_saved()
        CALL select_transfers("1=1")
        CALL set_curr_idx_by_code(rec_hdr.trans_no)
    ELSE
        UPDATE wb30_hdr
            SET from_bin = rec_hdr.from_bin,
                to_bin = rec_hdr.to_bin,
                from_wh = rec_hdr.from_wh,
                to_wh = rec_hdr.to_wh,
                trans_date = rec_hdr.trans_date,
                reference = rec_hdr.reference,
                total_qty = rec_hdr.total_qty,
                status = rec_hdr.status
            WHERE trans_no = rec_hdr.trans_no
        CALL utils_globals.msg_updated()
    END IF
    CALL load_transfer(rec_hdr.trans_no)
END FUNCTION

FUNCTION delete_transfer()
    IF utils_globals.is_empty(rec_hdr.trans_no) THEN
        CALL utils_globals.show_info("No transfer selected for deletion.")
        RETURN
    END IF

    IF utils_globals.show_confirm(
        "Delete transfer: " || rec_hdr.trans_no || "?", "Confirm Delete") THEN
        -- Delete details first
        DELETE FROM wb31_det WHERE trans_no = rec_hdr.trans_no
        -- Delete header
        DELETE FROM wb30_hdr WHERE trans_no = rec_hdr.trans_no
        CALL utils_globals.msg_deleted()
        CALL select_transfers("1=1")
    END IF
END FUNCTION

FUNCTION show_transfer_details()
    IF utils_globals.is_empty(rec_hdr.trans_no) THEN
        CALL utils_globals.show_info("No transfer selected.")
        RETURN
    END IF

    CALL utils_globals.show_info("Transfer details for: " || rec_hdr.trans_no)
    -- RUN "wb31_det " || rec_hdr.trans_no
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
    IF utils_globals.is_empty(rec_hdr.trans_no) THEN
        CALL utils_globals.show_error("Transfer Number is required.")
        RETURN FALSE
    END IF
    IF utils_globals.is_empty(rec_hdr.from_bin) THEN
        CALL utils_globals.show_error("From Bin is required.")
        RETURN FALSE
    END IF
    IF utils_globals.is_empty(rec_hdr.to_bin) THEN
        CALL utils_globals.show_error("To Bin is required.")
        RETURN FALSE
    END IF
    IF rec_hdr.from_bin = rec_hdr.to_bin THEN
        CALL utils_globals.show_error("From and To bins cannot be the same.")
        RETURN FALSE
    END IF
    IF rec_hdr.trans_date IS NULL THEN
        CALL utils_globals.show_error("Transfer Date is required.")
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION
