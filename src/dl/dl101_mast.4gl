-- ==============================================================
-- Program   : dl100_mast.4gl
-- Purpose   : Debtors Master Maintenance
-- Module    : Debtors (dl)
-- Number    : 101
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

IMPORT FGL dl121_lkup
IMPORT FGL utils_status_const
IMPORT FGL sa132_invoice
IMPORT FGL sa133_crn
IMPORT FGL sa131_order
IMPORT FGL sa130_quote

SCHEMA demoappdb

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE debtor_t RECORD LIKE dl01_mast.*
DEFINE rec_debt debtor_t

DEFINE arr_debt_trans DYNAMIC ARRAY OF RECORD LIKE dl30_trans.*
DEFINE arr_codes DYNAMIC ARRAY OF STRING

DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

-- ==============================================================
-- MAIN
-- ==============================================================
MAIN
    DEFINE ret SMALLINT

    IF NOT utils_globals.initialize_application() THEN
        DISPLAY "Initialization failed."
        EXIT PROGRAM 1
    END IF

    IF utils_globals.is_standalone() THEN
        OPTIONS INPUT WRAP
        OPEN WINDOW w_dl101
            WITH
            FORM "dl101_mast" --ATTRIBUTES(STYLE = "dialog")

        -- Call formatting HERE after form is ready
        --CALL utils_globals.apply_field_formatting() RETURNING *

    END IF

    CALL init_dl_module()

    IF utils_globals.is_standalone() THEN
        CLOSE WINDOW w_dl101
    END IF
END MAIN

-- ==============================================================
-- Program init
-- ==============================================================
FUNCTION init_dl_module()
    DEFINE chosen_row SMALLINT
    LET is_edit_mode = FALSE
    INITIALIZE rec_debt.* TO NULL
    DISPLAY BY NAME rec_debt.*
    DISPLAY ARRAY arr_debt_trans
        TO arr_debt_trans.*
        ATTRIBUTES(UNBUFFERED, DOUBLECLICK = row_select)
        BEFORE DISPLAY
            CALL DIALOG.setActionHidden("accept", TRUE)
            CALL DIALOG.setActionHidden("cancel", TRUE)
            CALL DIALOG.setActionHidden("row_select", TRUE)
        ON ACTION Find
            CALL query_debtors();
            LET is_edit_mode = FALSE
        ON ACTION New
            CALL new_debtor();
            LET is_edit_mode = FALSE
        ON ACTION row_select
            LET chosen_row = DIALOG.getCurrentRow("arr_debt_trans");
            IF chosen_row > 0 THEN
                CALL open_transaction_window(
                    arr_debt_trans[arr_curr()].doc_no,
                    arr_debt_trans[arr_curr()].doc_type)
            END IF
        ON ACTION List
            CALL load_all_debtors();
            LET is_edit_mode = FALSE
        ON ACTION Edit
            IF rec_debt.id IS NULL OR rec_debt.id = 0 THEN
                CALL utils_globals.show_info("No record selected to edit.")
            ELSE
                LET is_edit_mode = TRUE;
                CALL utils_globals.set_form_label(
                    'lbl_form_title', 'DEBTORS MAINTENANCE');
                CALL edit_debtor()
            END IF
        ON ACTION DELETE
            CALL delete_debtor();
            LET is_edit_mode = FALSE
        ON ACTION PREVIOUS
            CALL move_record(-1);
            DISPLAY ARRAY arr_debt_trans TO arr_debt_trans.*
                BEFORE DISPLAY
                    EXIT DISPLAY
            END DISPLAY
        ON ACTION Next
            CALL move_record(1);
            DISPLAY ARRAY arr_debt_trans TO arr_debt_trans.*
                BEFORE DISPLAY
                    EXIT DISPLAY
            END DISPLAY
        ON ACTION add_quote
            CALL sa130_quote.new_ord_from_master(rec_debt.id)
        ON ACTION add_order
            CONTINUE DISPLAY
        ON ACTION EXIT
            EXIT DISPLAY
    END DISPLAY
END FUNCTION

-- ==============================================================
-- Load All Debtors
-- ==============================================================
FUNCTION load_all_debtors()
    DEFINE ok SMALLINT
    LET ok = select_debtors("1=1")

    IF ok THEN
        MESSAGE SFMT("Loaded %1 debtor(s)", arr_codes.getLength())
        IF arr_codes.getLength() > 0 THEN
            CALL load_debtor(arr_codes[1])
        END IF
    ELSE
        CALL utils_globals.show_info("No debtors found.")
        INITIALIZE rec_debt.* TO NULL
        DISPLAY BY NAME rec_debt.*
        CALL arr_debt_trans.clear()
    END IF
END FUNCTION

-- ==============================================================
-- Query Debtors via Lookup
-- ==============================================================
FUNCTION query_debtors()
    DEFINE selected_code STRING
    DEFINE found_idx, i INTEGER

    LET selected_code = dl121_lkup.get_debtors_list()

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
        CALL load_debtor(selected_code)
    ELSE
        CALL load_all_debtors()
        FOR i = 1 TO arr_codes.getLength()
            IF arr_codes[i] = selected_code THEN
                LET curr_idx = i
                EXIT FOR
            END IF
        END FOR
        CALL load_debtor(selected_code)
    END IF
END FUNCTION

-- ==============================================================
-- New Debtor
-- ==============================================================
FUNCTION new_debtor()
    DEFINE dup_found, new_acc_code, next_num, i, array_size INTEGER
    DEFINE next_full STRING
    DEFINE username STRING

    INITIALIZE rec_debt.* TO NULL
    CLEAR FORM
    LET rec_debt.status = 'active'
    LET rec_debt.balance = 0.00
    LET rec_debt.cr_limit = 0.00
    LET rec_debt.created_at = CURRENT
    LET rec_debt.created_by = utils_globals.get_random_user()

    LET username = utils_globals.get_username(rec_debt.created_by)

    DISPLAY username

    CALL utils_globals.set_form_label('lbl_form_title', 'DEBTORS MAINTENANCE')

    CALL utils_globals.get_next_number("dl01_mast", "DL")
        RETURNING next_num, next_full

    LET rec_debt.id = next_num

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_debt.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_debtor")

            AFTER FIELD cust_name
                IF rec_debt.cust_name IS NULL OR rec_debt.cust_name = "" THEN
                    CALL utils_globals.show_error("Customer Name is required.")
                    NEXT FIELD cust_name
                END IF

            AFTER FIELD email
                IF rec_debt.email IS NOT NULL AND rec_debt.email != "" THEN
                    IF NOT utils_globals.is_valid_email(rec_debt.email) THEN
                        CALL utils_globals.show_error("Invalid email format.")
                        NEXT FIELD email
                    END IF
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Save", IMAGE = "filesave")

                LET dup_found =
                    check_debtor_unique(
                        rec_debt.id,
                        rec_debt.cust_name,
                        rec_debt.phone,
                        rec_debt.email)

                IF dup_found = 0 THEN

                    CALL save_debtor()
                    LET new_acc_code = rec_debt.id

                    CALL utils_globals.show_info("Debtor saved successfully.")

                    EXIT DIALOG
                ELSE
                    CALL utils_globals.show_error("Duplicate debtor found.")
                END IF

            ON ACTION cancel ATTRIBUTES(TEXT = "Cancel", IMAGE = "cancel")
                LET new_acc_code = NULL
                CALL utils_globals.show_info("Creation cancelled.")
                EXIT DIALOG
        END INPUT
    END DIALOG

    IF new_acc_code IS NOT NULL THEN
        CALL load_all_debtors()
        LET array_size = arr_codes.getLength()
        IF array_size > 0 THEN
            FOR i = 1 TO array_size
                IF arr_codes[i] = new_acc_code THEN
                    LET curr_idx = i
                    EXIT FOR
                END IF
            END FOR
        END IF
        CALL load_debtor(new_acc_code)
    ELSE
        LET array_size = arr_codes.getLength()
        IF array_size > 0 AND curr_idx >= 1 AND curr_idx <= array_size THEN
            CALL load_debtor(arr_codes[curr_idx])
        ELSE
            LET curr_idx = 0
            INITIALIZE rec_debt.* TO NULL
            DISPLAY BY NAME rec_debt.*
        END IF
    END IF
END FUNCTION

-- ==============================================================
-- Delete Debtor
-- ==============================================================
FUNCTION delete_debtor()
    DEFINE ok, deleted_code, array_size INTEGER

    IF rec_debt.id IS NULL OR rec_debt.id = 0 THEN
        CALL utils_globals.show_info("No debtor selected for deletion.")
        RETURN
    END IF

    LET ok =
        utils_globals.show_confirm(
            "Delete this debtor: " || rec_debt.cust_name || "?",
            "Confirm Delete")

    IF NOT ok THEN
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    LET deleted_code = rec_debt.id
    DELETE FROM dl01_mast WHERE id = deleted_code
    CALL utils_globals.msg_deleted()

    CALL load_all_debtors()
    LET array_size = arr_codes.getLength()

    IF array_size > 0 THEN
        IF curr_idx > array_size THEN
            LET curr_idx = array_size
        END IF
        IF curr_idx < 1 THEN
            LET curr_idx = 1
        END IF
        CALL load_debtor(arr_codes[curr_idx])
    ELSE
        LET curr_idx = 0
        INITIALIZE rec_debt.* TO NULL
        DISPLAY BY NAME rec_debt.*
    END IF
END FUNCTION

-- ==============================================================
-- Select Debtors
-- ==============================================================
FUNCTION select_debtors(where_clause STRING) RETURNS SMALLINT
    DEFINE code, idx INTEGER
    DEFINE sql_stmt STRING

    CALL arr_codes.clear()
    LET idx = 0
    LET sql_stmt = "SELECT id FROM dl01_mast"

    IF where_clause IS NOT NULL AND where_clause != "" THEN
        LET sql_stmt = sql_stmt || " WHERE " || where_clause || " ORDER BY id"
    END IF

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
    CALL load_debtor(arr_codes[curr_idx])
    RETURN TRUE
END FUNCTION

-- ==============================================================
-- Load Single Debtor (and transactions)
-- ==============================================================
FUNCTION load_debtor(p_code INTEGER)
    DEFINE l_found SMALLINT

    SELECT * INTO rec_debt.* FROM dl01_mast WHERE id = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_debt.*

        LET l_found = TRUE
        CALL load_debtor_transactions(p_code)
    ELSE
        INITIALIZE rec_debt.* TO NULL
        DISPLAY BY NAME rec_debt.*
        LET l_found = FALSE
    END IF

    IF l_found AND arr_debt_trans.getLength() = 0 THEN
        CALL utils_globals.show_info("No transactions found for this debtor.")
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
    CALL load_debtor(arr_codes[curr_idx])
END FUNCTION

-- ==============================================================
-- Save / Update Debtor
-- ==============================================================
FUNCTION save_debtor()
    DEFINE exists INTEGER

    SELECT COUNT(*) INTO exists FROM dl01_mast WHERE id = rec_debt.id

    IF exists = 0 THEN
        INSERT INTO dl01_mast VALUES rec_debt.*
        CALL utils_globals.msg_saved()
    ELSE
        UPDATE dl01_mast SET dl01_mast.* = rec_debt.* WHERE id = rec_debt.id
        CALL utils_globals.msg_updated()
    END IF

    CALL load_debtor(rec_debt.id)
END FUNCTION

-- ==============================================================
-- Edit Debtor
-- ==============================================================
FUNCTION edit_debtor()

    CALL utils_globals.set_form_label('lbl_form_title', 'DEBTORS MAINTENANCE')

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_debt.* ATTRIBUTES(WITHOUT DEFAULTS, NAME = "debtors")

            ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
                CALL save_debtor()
                EXIT DIALOG

            ON ACTION cancel
                CALL load_debtor(rec_debt.id)
                EXIT DIALOG

            AFTER FIELD cust_name
                IF rec_debt.cust_name IS NULL OR rec_debt.cust_name = "" THEN
                    CALL utils_globals.show_error("Debtor Name is required.")
                    NEXT FIELD cust_name
                END IF
        END INPUT
    END DIALOG
END FUNCTION

-- ==============================================================
-- Check Uniqueness
-- ==============================================================
FUNCTION check_debtor_unique(
    p_acc_code INTEGER, p_cust_name STRING, p_phone STRING, p_email STRING)
    RETURNS SMALLINT
    DEFINE dup_count INTEGER

    SELECT COUNT(*) INTO dup_count FROM dl01_mast WHERE id = p_acc_code
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Duplicate account code already exists.")
        RETURN 1
    END IF

    IF p_cust_name IS NOT NULL AND p_cust_name != "" THEN
        SELECT COUNT(*)
            INTO dup_count
            FROM dl01_mast
            WHERE cust_name = p_cust_name
        IF dup_count > 0 THEN
            CALL utils_globals.show_error("Customer name already exists.")
            RETURN 1
        END IF
    END IF

    IF p_phone IS NOT NULL AND p_phone != "" THEN
        SELECT COUNT(*) INTO dup_count FROM dl01_mast WHERE phone = p_phone
        IF dup_count > 0 THEN
            CALL utils_globals.show_error("Phone number already exists.")
            RETURN 1
        END IF
    END IF

    IF p_email IS NOT NULL AND p_email != "" THEN
        SELECT COUNT(*) INTO dup_count FROM dl01_mast WHERE email = p_email
        IF dup_count > 0 THEN
            CALL utils_globals.show_error("Email already exists.")
            RETURN 1
        END IF
    END IF

    RETURN 0
END FUNCTION

-- ==============================================================
-- Load Debtor Transactions
-- ==============================================================
FUNCTION load_debtor_transactions(p_cust_id INTEGER)
    DEFINE idx INTEGER

    CALL arr_debt_trans.clear()

    DECLARE debt_trans_curs CURSOR FOR
        SELECT *
            FROM dl30_trans
            WHERE cust_id = p_cust_id
            ORDER BY trans_date DESC, doc_no DESC

    LET idx = 1
    FOREACH debt_trans_curs
        INTO arr_debt_trans[idx].id,
            arr_debt_trans[idx].cust_id,
            arr_debt_trans[idx].doc_no,
            arr_debt_trans[idx].trans_date,
            arr_debt_trans[idx].doc_type,
            arr_debt_trans[idx].gross_tot,
            arr_debt_trans[idx].vat,
            arr_debt_trans[idx].disc,
            arr_debt_trans[idx].net_tot
        LET idx = idx + 1
    END FOREACH

    CLOSE debt_trans_curs
    FREE debt_trans_curs
END FUNCTION

-- ==============================================================
-- Open Related Document (inactive case block)
-- ==============================================================
FUNCTION open_transaction_window(p_doc_id INTEGER, l_type STRING)

    IF SQLCA.SQLCODE != 0 THEN
        CALL utils_globals.show_error("Document not found.")
        RETURN
    END IF

    DISPLAY "Loaded the doc no for doc : " || p_doc_id

    CASE l_type
        WHEN "QT"
            CALL sa130_quote.load_quote(p_doc_id)
        WHEN "ORD"
            CALL sa131_order.load_order(p_doc_id)
        WHEN "INV"
            CALL sa132_invoice.show_invoice(p_doc_id)
        WHEN "CRN"
            CALL sa133_crn.load_credit_note(p_doc_id)
        OTHERWISE
            CALL utils_globals.show_info("Unknown document type: " || l_type)
    END CASE

END FUNCTION
