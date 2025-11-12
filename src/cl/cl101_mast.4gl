-- ==============================================================
-- Program   : cl100_mast.4gl
-- Purpose   : Creditors Master Maintenance
-- Module    : Creditors (cl)
-- Number    : 101
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

IMPORT FGL cl121_lkup
IMPORT FGL utils_status_const
IMPORT FGL pu132_inv
IMPORT FGL pu131_grn
IMPORT FGL pu130_order

SCHEMA demoappdb

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE creditor_t RECORD LIKE cl01_mast.*
DEFINE m_rec_cred creditor_t

DEFINE arr_cred_trans DYNAMIC ARRAY OF RECORD LIKE cl30_trans.*
DEFINE arr_codes DYNAMIC ARRAY OF STRING

DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

-- ==============================================================
-- MAIN
-- ==============================================================
MAIN

    IF NOT utils_globals.initialize_application() THEN
        DISPLAY "Initialization failed."
        EXIT PROGRAM 1
    END IF
    
    OPTIONS INPUT WRAP

    IF utils_globals.is_standalone() THEN
        OPEN WINDOW w_cl101 WITH FORM "cl101_mast" ATTRIBUTES(STYLE = "normal")
    ELSE
        OPEN WINDOW w_cl101 WITH FORM "cl101_mast" ATTRIBUTES(STYLE = "child")
    END IF

    CALL init_cl_module()

    IF utils_globals.is_standalone() THEN
        CLOSE WINDOW w_cl101
    END IF
END MAIN

-- ==============================================================
-- Program init
-- ==============================================================
FUNCTION init_cl_module()

    DEFINE chosen_row SMALLINT

    LET is_edit_mode = FALSE

    -- initialize the list of records
    CALL load_all_creditors()

    CALL utils_globals.set_form_label('lbl_form_title', 'CREDITORS ENQUIRY')

    DISPLAY ARRAY arr_cred_trans
        TO arr_cred_trans.*
        ATTRIBUTES(UNBUFFERED, DOUBLECLICK = row_select)
        BEFORE DISPLAY

            CALL DIALOG.setActionHidden("accept", TRUE)
            CALL DIALOG.setActionHidden("cancel", TRUE)
            CALL DIALOG.setActionHidden("row_select", TRUE)

        ON ACTION Find ATTRIBUTES(TEXT = "Find", IMAGE = "zoom")
            CALL query_creditors()
            LET is_edit_mode = FALSE

        ON ACTION New ATTRIBUTES(TEXT = "New", IMAGE = "new")
            CALL new_creditor()
            LET is_edit_mode = FALSE

        ON ACTION row_select
            LET chosen_row = DIALOG.getCurrentRow("arr_cred_trans")
            IF chosen_row > 0 THEN
                CALL open_transaction_window(
                    arr_cred_trans[chosen_row].doc_no,
                    arr_cred_trans[arr_curr()].doc_type)
            END IF

        ON ACTION List ATTRIBUTES(TEXT = "Reload List", IMAGE = "fa-list")
            DISPLAY "List All"
            CALL load_all_creditors()
            LET is_edit_mode = FALSE

        ON ACTION Edit ATTRIBUTES(TEXT = "Edit", IMAGE = "pen")
            DISPLAY "Edit Record"
            IF m_rec_cred.id IS NULL OR m_rec_cred.id = 0 THEN
                CALL utils_globals.show_info("No record selected to edit.")
            ELSE
                LET is_edit_mode = TRUE
                CALL utils_globals.set_form_label(
                    'lbl_form_title', 'CREDITORS MAINTENANCE')
                CALL edit_creditor()
            END IF

        ON ACTION DELETE ATTRIBUTES(TEXT = "Delete", IMAGE = "fa-trash")
            CALL delete_creditor()
            LET is_edit_mode = FALSE

        ON ACTION PREVIOUS
            CALL move_record(-1)
            DISPLAY ARRAY arr_cred_trans TO arr_cred_trans.*
                BEFORE DISPLAY
                    EXIT DISPLAY
            END DISPLAY

        ON ACTION Next
            CALL move_record(1)
            DISPLAY ARRAY arr_cred_trans TO arr_cred_trans.*
                BEFORE DISPLAY
                    EXIT DISPLAY
            END DISPLAY

        ON ACTION add_order
            ATTRIBUTES(TEXT = "Add P/Order", IMAGE = "fa-reorder")
            DISPLAY "Add Quote"
            CALL pu130_order.new_po_from_master(m_rec_cred.id)

        ON ACTION EXIT ATTRIBUTES(TEXT = "Exit", IMAGE = "fa-close")
            EXIT DISPLAY
    END DISPLAY

END FUNCTION

-- ==============================================================
-- Load All creditors
-- ==============================================================
FUNCTION load_all_creditors()
    DEFINE ok SMALLINT
    LET ok = select_creditors("1=1")

    IF ok THEN
        MESSAGE SFMT("Loaded %1 creditor(s)", arr_codes.getLength())
        IF arr_codes.getLength() > 0 THEN
            CALL load_creditor(arr_codes[1])
        END IF
    ELSE
        CALL utils_globals.show_info("No creditors found.")
        INITIALIZE m_rec_cred.* TO NULL
        DISPLAY BY NAME m_rec_cred.*
        CALL arr_cred_trans.clear()
    END IF
END FUNCTION

-- ==============================================================
-- Query creditors via Lookup
-- ==============================================================
FUNCTION query_creditors()
    DEFINE selected_code STRING
    DEFINE found_idx, i INTEGER

    LET selected_code = cl121_lkup.fetch_list()

    IF selected_code IS NULL OR selected_code = "" THEN
        RETURN
    END IF

    LET found_idx = 0
    FOR i = 1 TO arr_codes.getLength()
        IF arr_codes[i] = selected_code THEN
            LET found_idx = i
            EXIT FOR
        END IF
    END FOR

    IF found_idx > 0 THEN
        LET curr_idx = found_idx
        CALL load_creditor(selected_code)
    ELSE
        CALL load_all_creditors()
        FOR i = 1 TO arr_codes.getLength()
            IF arr_codes[i] = selected_code THEN
                LET curr_idx = i
                EXIT FOR
            END IF
        END FOR
        CALL load_creditor(selected_code)
    END IF
END FUNCTION

-- ==============================================================
-- New creditor
-- ==============================================================
FUNCTION new_creditor()
    DEFINE dup_found, new_acc_code, next_num, i, array_size INTEGER
    DEFINE next_full STRING
    DEFINE username STRING

    INITIALIZE m_rec_cred.* TO NULL
    CLEAR FORM
    LET m_rec_cred.status = 'active'
    LET m_rec_cred.balance = 0.00
    LET m_rec_cred.created_at = CURRENT
    LET m_rec_cred.created_by = utils_globals.get_random_user()

    LET username = utils_globals.get_username(m_rec_cred.created_by)

    DISPLAY username

    CALL utils_globals.set_form_label('lbl_form_title', 'CREATE CREDITOR')

    CALL utils_globals.get_next_number("cl01_mast", "DL")
        RETURNING next_num, next_full

    LET m_rec_cred.id = next_num

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME m_rec_cred.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_creditor")

            AFTER FIELD supp_name
                IF m_rec_cred.supp_name IS NULL
                    OR m_rec_cred.supp_name = "" THEN
                    CALL utils_globals.show_error("Customer Name is required.")
                    NEXT FIELD supp_name
                END IF

            AFTER FIELD email
                IF m_rec_cred.email IS NOT NULL AND m_rec_cred.email != "" THEN
                    IF NOT utils_globals.is_valid_email(m_rec_cred.email) THEN
                        CALL utils_globals.show_error("Invalid email format.")
                        NEXT FIELD email
                    END IF
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Save", IMAGE = "filesave")

                LET dup_found =
                    check_creditor_unique(
                        m_rec_cred.id,
                        m_rec_cred.supp_name,
                        m_rec_cred.phone,
                        m_rec_cred.email)

                IF dup_found = 0 THEN

                    CALL save_creditor()
                    LET new_acc_code = m_rec_cred.id
                    EXIT DIALOG
                ELSE
                    CALL utils_globals.show_error("Duplicate creditor found.")
                END IF

            ON ACTION cancel ATTRIBUTES(TEXT = "Cancel", IMAGE = "cancel")
                LET new_acc_code = NULL
                CALL utils_globals.show_info("Creation cancelled.")
                EXIT DIALOG
        END INPUT
    END DIALOG

    IF new_acc_code IS NOT NULL THEN
        CALL load_all_creditors()
        LET array_size = arr_codes.getLength()
        IF array_size > 0 THEN
            FOR i = 1 TO array_size
                IF arr_codes[i] = new_acc_code THEN
                    LET curr_idx = i
                    EXIT FOR
                END IF
            END FOR
        END IF
        CALL load_creditor(new_acc_code)
    ELSE
        LET array_size = arr_codes.getLength()
        IF array_size > 0 AND curr_idx >= 1 AND curr_idx <= array_size THEN
            CALL load_creditor(arr_codes[curr_idx])
        ELSE
            LET curr_idx = 0
            INITIALIZE m_rec_cred.* TO NULL
            DISPLAY BY NAME m_rec_cred.*
        END IF
    END IF
END FUNCTION

-- ==============================================================
-- Delete creditor
-- ==============================================================
FUNCTION delete_creditor()
    DEFINE ok, deleted_code, array_size INTEGER

    IF m_rec_cred.id IS NULL OR m_rec_cred.id = 0 THEN
        CALL utils_globals.show_info("No creditor selected for deletion.")
        RETURN
    END IF

    LET ok =
        utils_globals.show_confirm(
            "Delete this creditor: " || m_rec_cred.supp_name || "?",
            "Confirm Delete")

    IF NOT ok THEN
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    LET deleted_code = m_rec_cred.id
    DELETE FROM cl01_mast WHERE id = deleted_code
    CALL utils_globals.msg_deleted()

    CALL load_all_creditors()
    LET array_size = arr_codes.getLength()

    IF array_size > 0 THEN
        IF curr_idx > array_size THEN
            LET curr_idx = array_size
        END IF
        IF curr_idx < 1 THEN
            LET curr_idx = 1
        END IF
        CALL load_creditor(arr_codes[curr_idx])
    ELSE
        LET curr_idx = 0
        INITIALIZE m_rec_cred.* TO NULL
        DISPLAY BY NAME m_rec_cred.*
    END IF
END FUNCTION

-- ==============================================================
-- Select creditors
-- ==============================================================
FUNCTION select_creditors(where_clause STRING) RETURNS SMALLINT
    DEFINE code, idx INTEGER
    DEFINE sql_stmt STRING

    CALL arr_codes.clear()
    LET idx = 0

    LET sql_stmt = "SELECT id FROM cl01_mast"
    
    IF where_clause IS NOT NULL AND where_clause != "" THEN
        LET sql_stmt = sql_stmt || " WHERE " || where_clause
    END IF
    
    LET sql_stmt = sql_stmt || " ORDER BY id"

    PREPARE stmt_select FROM sql_stmt
    DECLARE c_curs CURSOR FOR stmt_select

    FOREACH c_curs INTO code
        LET idx = idx + 1
        LET arr_codes[idx] = code
    END FOREACH

    CLOSE c_curs
    FREE c_curs
    FREE stmt_select

    IF arr_codes.getLength() == 0 THEN
        CALL utils_globals.msg_no_record()
        RETURN FALSE
    END IF

    LET curr_idx = 1
    CALL load_creditor(arr_codes[curr_idx])
    RETURN TRUE
END FUNCTION

-- ==============================================================
-- Load Single creditor (and transactions)
-- ==============================================================
FUNCTION load_creditor(p_code INTEGER)
    DEFINE l_found SMALLINT

    CALL utils_globals.set_form_label('lbl_form_title', 'CREDITORS MAINTENANCE')

    SELECT * INTO m_rec_cred.* FROM cl01_mast WHERE id = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME m_rec_cred.*

        LET l_found = TRUE
        CALL load_creditor_transactions(p_code)
    ELSE
        INITIALIZE m_rec_cred.* TO NULL
        DISPLAY BY NAME m_rec_cred.*
        LET l_found = FALSE
    END IF
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
    CALL load_creditor(arr_codes[curr_idx])
END FUNCTION

-- ==============================================================
-- Save / Update creditor
-- ==============================================================
FUNCTION save_creditor()
    DEFINE exists INTEGER

    LET m_rec_cred.updated_at = current

    SELECT COUNT(*)
        INTO exists
        FROM cl01_mast
        WHERE id = m_rec_cred.id

    IF exists = 0 THEN
        INSERT INTO cl01_mast  VALUES m_rec_cred.*

        CALL utils_globals.msg_saved()
    ELSE
        UPDATE cl01_mast
           SET id = m_rec_cred.id,
               supp_name = m_rec_cred.supp_name,
               phone = m_rec_cred.phone,
               email = m_rec_cred.email,
               balance = m_rec_cred.balance,
               status = m_rec_cred.status,
               address1 = m_rec_cred.address1,
               address2 = m_rec_cred.address2,
               address3 = m_rec_cred.address3,
               postal_code = m_rec_cred.postal_code,
               vat_no = m_rec_cred.vat_no,
               payment_terms = m_rec_cred.payment_terms,
               created_by = m_rec_cred.created_by
         WHERE id = m_rec_cred.id

        CALL utils_globals.msg_updated()
    END IF

    CALL load_creditor(m_rec_cred.id)
END FUNCTION

-- ==============================================================
-- Edit creditor
-- ==============================================================
FUNCTION edit_creditor()

    CALL utils_globals.set_form_label('lbl_form_title', 'EDIT CREDITOR')

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME m_rec_cred.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "creditors")

            ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
                CALL save_creditor()
                EXIT DIALOG

            ON ACTION cancel
                CALL load_creditor(m_rec_cred.id)
                EXIT DIALOG

            AFTER FIELD supp_name
                IF m_rec_cred.supp_name IS NULL
                    OR m_rec_cred.supp_name = "" THEN
                    CALL utils_globals.show_error("creditor Name is required.")
                    NEXT FIELD supp_name
                END IF
        END INPUT
    END DIALOG
END FUNCTION

-- ==============================================================
-- Check Uniqueness
-- ==============================================================
FUNCTION check_creditor_unique(
    p_acc_code INTEGER, p_supp_name STRING, p_phone STRING, p_email STRING)
    RETURNS SMALLINT
    DEFINE dup_count INTEGER

    SELECT COUNT(*) INTO dup_count FROM cl01_mast WHERE id = p_acc_code
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Duplicate account code already exists.")
        RETURN 1
    END IF

    IF p_supp_name IS NOT NULL AND p_supp_name != "" THEN
        SELECT COUNT(*)
            INTO dup_count
            FROM cl01_mast
            WHERE supp_name = p_supp_name
        IF dup_count > 0 THEN
            CALL utils_globals.show_error("Customer name already exists.")
            RETURN 1
        END IF
    END IF

    IF p_phone IS NOT NULL AND p_phone != "" THEN
        SELECT COUNT(*) INTO dup_count FROM cl01_mast WHERE phone = p_phone
        IF dup_count > 0 THEN
            CALL utils_globals.show_error("Phone number already exists.")
            RETURN 1
        END IF
    END IF

    IF p_email IS NOT NULL AND p_email != "" THEN
        SELECT COUNT(*) INTO dup_count FROM cl01_mast WHERE email = p_email
        IF dup_count > 0 THEN
            CALL utils_globals.show_error("Email already exists.")
            RETURN 1
        END IF
    END IF

    RETURN 0
END FUNCTION

-- ==============================================================
-- Load creditor Transactions
-- ==============================================================
FUNCTION load_creditor_transactions(p_supp_id INTEGER)
    DEFINE idx INTEGER

    CALL arr_cred_trans.clear()

    DECLARE c_trans CURSOR FOR
        SELECT *
            FROM cl30_trans
            WHERE id = p_supp_id
            ORDER BY trans_date DESC, doc_no DESC

    LET idx = 1
    FOREACH c_trans
        INTO arr_cred_trans[idx].id,
            arr_cred_trans[idx].trans_date,
            arr_cred_trans[idx].doc_no,
            arr_cred_trans[idx].doc_type,
            arr_cred_trans[idx].gross_tot,
            arr_cred_trans[idx].disc_tot,
            arr_cred_trans[idx].vat_tot,
            arr_cred_trans[idx].net_tot,
            arr_cred_trans[idx].notes
        LET idx = idx + 1
    END FOREACH

    CLOSE c_trans
    FREE c_trans
END FUNCTION

-- ==============================================================
-- Open Related Document (inactive case block)
-- ==============================================================
FUNCTION open_transaction_window(p_doc_id INTEGER, l_type STRING)

    DISPLAY "Loaded the doc no for doc : " || p_doc_id

    CASE l_type
        WHEN "ORD"
            CALL pu130_order.load_po(p_doc_id)
        WHEN "INV"
            CALL pu132_inv.load_pu_inv(p_doc_id)
        WHEN "GRN"
            CALL pu131_grn.load_pu_grn(p_doc_id)
        OTHERWISE
            CALL utils_globals.show_info("Unknown document type: " || l_type)
    END CASE

END FUNCTION
