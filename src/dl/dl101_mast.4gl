-- ==============================================================
-- Program   : dl100_mast.4gl
-- Purpose   : Debtors Master maintenance
-- Module    : Debtors (dl)
-- Number    : 101
-- Author    : Bongani Dlamini
-- Version   : Genero BDL 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL utils_db
IMPORT FGL utils_lookup
IMPORT FGL utils_status_const
IMPORT FGL dl121_lkup

SCHEMA xactdemo_db

-- ==============================================================
-- Record definition
-- ==============================================================
DEFINE rec_mast RECORD

    acc_code LIKE dl01_mast.acc_code,
    cust_name LIKE dl01_mast.cust_name,
    phone LIKE dl01_mast.phone,
    email LIKE dl01_mast.email,
    status LIKE dl01_mast.status,
    address1 LIKE dl01_mast.address1,
    address2 LIKE dl01_mast.address2,
    address3 LIKE dl01_mast.address3,
    cr_limit LIKE dl01_mast.cr_limit,
    balance LIKE dl01_mast.balance
END RECORD

-- ==============================================================
-- MAIN
-- ==============================================================
MAIN
    IF NOT utils_globals.initialize_application() THEN
        DISPLAY "Initialization failed."
        EXIT PROGRAM 1
    END IF

    OPEN WINDOW w_dl101 WITH FORM "dl101_mast" ATTRIBUTES(STYLE = "modal")
    CALL run_debtors_master()
    CLOSE WINDOW w_dl101
END MAIN

-- ==============================================================
-- Menu controller
-- ==============================================================
FUNCTION run_debtors_master()
    DEFINE code STRING

    CALL utils_status_const.populate_status_combobox()

    MENU "Debtors Master"

        COMMAND "Find"
            LET code = query_debtor()
            IF code IS NOT NULL AND code <> "" THEN
                CALL load_debtor_by_code(code)
            ELSE
                CALL utils_globals.show_info("No record selected.")
            END IF

        COMMAND "Create"
            CALL add_debtor()

        COMMAND "Edit"
            CALL edit_debtor()

        COMMAND "Next"
            CALL next_debtor()

        COMMAND "Previous"
            CALL prev_debtor()

        COMMAND "Exit"
            EXIT MENU

    END MENU
END FUNCTION


-- ==============================================================
-- Lookup form popup - Enhanced version for frm_dl101_lkup
-- ==============================================================
FUNCTION query_debtor() RETURNS STRING
    DEFINE selected_code STRING

    -- Call the popup dialog from the lookup module
    LET selected_code = dl121_lkup.display_debt_list()

    IF selected_code IS NULL OR selected_code = "" THEN
        CALL utils_globals.show_info("No record selected.")
    ELSE
        CALL utils_globals.show_success("Selected: " || selected_code)
    END IF

    RETURN selected_code
END FUNCTION

-- ==============================================================
-- Alternative version with search capability using f_search field
-- ==============================================================
FUNCTION load_lookup_form_with_search() RETURNS STRING
    DEFINE selected_code STRING
    DEFINE debt_arr DYNAMIC ARRAY OF RECORD
        acc_code LIKE dl01_mast.acc_code,
        cust_name LIKE dl01_mast.cust_name,
        phone LIKE dl01_mast.phone,
        balance LIKE dl01_mast.balance
    END RECORD
    DEFINE search_text STRING
    DEFINE sel SMALLINT
    DEFINE row_count INTEGER

    LET selected_code = NULL
    LET search_text = ""

    -- Load all records initially
    CALL load_debtors_for_lookup(search_text) RETURNING debt_arr, row_count

    IF row_count = 0 THEN
        CALL utils_globals.show_info("No debtor records found.")
        RETURN NULL
    END IF

    OPEN WINDOW w_lkup WITH FORM "dl121_lkup" ATTRIBUTES(STYLE = "dialog")

    DIALOG ATTRIBUTES(UNBUFFERED)

        INPUT search_text FROM f_search
            ON CHANGE search_text
                -- Reload data based on search
                CALL load_debtors_for_lookup(
                    search_text)
                    RETURNING debt_arr, row_count
                CALL DIALOG.setCurrentRow("tbl_dl01", 1)
        END INPUT

        DISPLAY ARRAY debt_arr TO tbl_dl01.*

            BEFORE DISPLAY
                CALL DIALOG.setCurrentRow("tbl_dl01", 1)

            ON ACTION accept
                LET sel = DIALOG.getCurrentRow("tbl_dl01")
                IF sel > 0 AND sel <= debt_arr.getLength() THEN
                    LET selected_code = debt_arr[sel].acc_code
                    EXIT DIALOG
                END IF

            ON ACTION cancel
                LET selected_code = NULL
                EXIT DIALOG

            ON ACTION doubleclick
                LET sel = DIALOG.getCurrentRow("tbl_dl01")
                IF sel > 0 AND sel <= debt_arr.getLength() THEN
                    LET selected_code = debt_arr[sel].acc_code
                    EXIT DIALOG
                END IF

            ON KEY(RETURN)
                LET sel = DIALOG.getCurrentRow("tbl_dl01")
                IF sel > 0 AND sel <= debt_arr.getLength() THEN
                    LET selected_code = debt_arr[sel].acc_code
                    EXIT DIALOG
                END IF

        END DISPLAY

    END DIALOG

    CLOSE WINDOW w_lkup

    RETURN selected_code

END FUNCTION

-- Helper function to load debtors with optional search filter
FUNCTION load_debtors_for_lookup(search_filter STRING)
    RETURNS(
        DYNAMIC ARRAY OF RECORD
            acc_code LIKE dl01_mast.acc_code,
            cust_name LIKE dl01_mast.cust_name,
            phone LIKE dl01_mast.phone,
            balance LIKE dl01_mast.balance
        END RECORD,
        INTEGER)

    DEFINE rec RECORD
        acc_code LIKE dl01_mast.acc_code,
        cust_name LIKE dl01_mast.cust_name,
        phone LIKE dl01_mast.phone,
        balance LIKE dl01_mast.balance
    END RECORD
    DEFINE debt_arr DYNAMIC ARRAY OF RECORD
        acc_code LIKE dl01_mast.acc_code,
        cust_name LIKE dl01_mast.cust_name,
        phone LIKE dl01_mast.phone,
        balance LIKE dl01_mast.balance
    END RECORD
    DEFINE sql_stmt STRING
    DEFINE row_count INTEGER

    CALL debt_arr.clear()
    LET row_count = 0

    -- Build SQL with search filter
    LET sql_stmt = "SELECT acc_code, cust_name, phone, balance FROM dl01_mast"

    IF search_filter IS NOT NULL AND search_filter.getLength() > 0 THEN
        LET sql_stmt =
            sql_stmt
                || " WHERE acc_code LIKE '%"
                || search_filter
                || "%'"
                || " OR cust_name LIKE '%"
                || search_filter
                || "%'"
                || " OR phone LIKE '%"
                || search_filter
                || "%'"
    END IF

    LET sql_stmt = sql_stmt || " ORDER BY acc_code"

    WHENEVER ERROR CONTINUE
    PREPARE debt_prep FROM sql_stmt
    DECLARE debt_csr2 CURSOR FOR debt_prep
    OPEN debt_csr2

    IF SQLCA.SQLCODE = 0 THEN
        FETCH debt_csr2 INTO rec.*
        WHILE SQLCA.SQLCODE = 0
            LET row_count = row_count + 1
            LET debt_arr[row_count].* = rec.*
            FETCH debt_csr2 INTO rec.*
        END WHILE
    END IF

    CLOSE debt_csr2
    FREE debt_prep
    WHENEVER ERROR STOP

    RETURN debt_arr, row_count

END FUNCTION

-- ==============================================================
-- Query single debtor
-- ==============================================================
FUNCTION load_debtor_by_code(p_code STRING)
    SELECT acc_code, cust_name, phone, email, status, address1, address2,
           address3, cr_limit, balance
      INTO rec_mast.*
      FROM dl01_mast
     WHERE acc_code = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_mast.*
    ELSE
        CALL utils_globals.show_error("Debtor not found: " || p_code)
    END IF
END FUNCTION


-- ==============================================================
-- Add debtor
-- ==============================================================
FUNCTION add_debtor()
    DEFINE dup_found SMALLINT
    LET rec_mast.status = 1
    CLEAR FORM
    DIALOG
        INPUT BY NAME rec_mast.*
-- validattion
            AFTER FIELD acc_code
                IF rec_mast.acc_code IS NULL OR rec_mast.acc_code = "" THEN
                    CALL utils_globals.show_error("Account Code is required")
                    NEXT FIELD acc_code
                END IF
            AFTER FIELD cust_name
                IF rec_mast.cust_name IS NULL OR rec_mast.cust_name = "" THEN
                    CALL utils_globals.show_error("Customer Name is required")
                    NEXT FIELD cust_name
                END IF
            AFTER FIELD phone
                IF NOT utils_globals.is_valid_phone(rec_mast.phone) THEN
                    CALL utils_globals.show_error(
                        "Phone is required and must be 10 digits")
                    NEXT FIELD phone
                END IF
            AFTER FIELD email
                IF NOT utils_globals.is_valid_email(rec_mast.email) THEN
                    CALL utils_globals.show_error(
                        "Email is required and must be a valid format")
                    NEXT FIELD email
                END IF

            ON ACTION accept ATTRIBUTE(TEXT = 'Add Debtor')
                LET dup_found =
                    check_debtor_unique(
                        rec_mast.acc_code,
                        rec_mast.cust_name,
                        rec_mast.phone,
                        rec_mast.email)
                IF dup_found = 0 THEN
-- Save to database
                    INSERT INTO dl01_mast(
                        acc_code,
                        cust_name,
                        phone,
                        email,
                        status,
                        address1,
                        address2,
                        address3,
                        cr_limit,
                        balance)
                        VALUES(rec_mast.acc_code,
                            rec_mast.cust_name,
                            rec_mast.phone,
                            rec_mast.email,
                            rec_mast.status,
                            rec_mast.address1,
                            rec_mast.address2,
                            rec_mast.address3,
                            rec_mast.cr_limit,
                            rec_mast.balance);
-- Confirmation popup
                    CALL utils_globals.show_success(
                        rec_mast.cust_name || " added successfully.")
                    EXIT DIALOG
                END IF
            ON ACTION cancel
                CALL utils_globals.show_info("Operation cancelled.")
                EXIT DIALOG
        END INPUT
    END DIALOG
END FUNCTION

-- ==============================================================
-- Edit debtor
-- ==============================================================
FUNCTION edit_debtor()
    DEFINE code STRING
    PROMPT "Enter Account Code to edit: " FOR code

    IF code IS NULL OR code = "" THEN
        CALL utils_globals.show_error("Account Code is required.")
        RETURN
    END IF

    SELECT * INTO rec_mast.* FROM dl01_mast WHERE acc_code = code
    IF SQLCA.SQLCODE <> 0 THEN
        CALL utils_globals.show_error("Debtor not found: " || code)
        RETURN
    END IF

    CALL utils_status_const.populate_status_combobox()
    DISPLAY BY NAME rec_mast.*

    DIALOG
        INPUT BY NAME rec_mast.*
            AFTER FIELD cust_name
                IF rec_mast.cust_name IS NULL OR rec_mast.cust_name = "" THEN
                    CALL utils_globals.show_error("Customer Name is required.")
                    NEXT FIELD cust_name
                END IF

            AFTER FIELD phone
                IF NOT utils_globals.is_valid_phone(rec_mast.phone) THEN
                    CALL utils_globals.show_error("Phone must be 10 digits.")
                    NEXT FIELD phone
                END IF

            AFTER FIELD email
                IF NOT utils_globals.is_valid_email(rec_mast.email) THEN
                    CALL utils_globals.show_error("Invalid email format.")
                    NEXT FIELD email
                END IF

            ON ACTION accept
                UPDATE dl01_mast
                    SET cust_name = rec_mast.cust_name,
                        phone = rec_mast.phone,
                        email = rec_mast.email,
                        status = rec_mast.status,
                        address1 = rec_mast.address1,
                        address2 = rec_mast.address2,
                        address3 = rec_mast.address3,
                        cr_limit = rec_mast.cr_limit,
                        balance = rec_mast.balance
                    WHERE acc_code = rec_mast.acc_code

                CALL utils_globals.show_success(
                    rec_mast.cust_name || " updated successfully.")
                EXIT DIALOG

            ON ACTION cancel
                CALL utils_globals.show_info("Edit cancelled.")
                EXIT DIALOG
        END INPUT
    END DIALOG
END FUNCTION

-- ==============================================================
-- Record navigation (stubs)
-- ==============================================================
FUNCTION next_debtor()
    MESSAGE "Next record"
END FUNCTION

FUNCTION prev_debtor()
    MESSAGE "Previous record"
END FUNCTION

-- ==============================================================
-- Check debtor uniqueness (simplified)
-- ==============================================================
FUNCTION check_debtor_unique(
    p_acc_code STRING, p_cust_name STRING, p_phone STRING, p_email STRING)
    RETURNS SMALLINT
    DEFINE dup_count INTEGER
    DEFINE exists SMALLINT
    LET exists = 0
-- check for duplicate account code
    SELECT COUNT(*) INTO dup_count FROM dl01_mast WHERE acc_code = p_acc_code
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Duplicate account code already exists.")
        LET exists = 1
        RETURN exists
    END IF
-- check for duplicate name
    SELECT COUNT(*) INTO dup_count FROM dl01_mast WHERE cust_name = p_cust_name
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Customer name already exists.")
        LET exists = 1
        RETURN exists
    END IF
-- check for duplicate phone
    SELECT COUNT(*) INTO dup_count FROM dl01_mast WHERE phone = p_phone
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Phone number already exists.")
        LET exists = 1
        RETURN exists
    END IF
-- check for duplicate email
    SELECT COUNT(*) INTO dup_count FROM dl01_mast WHERE email = p_email
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Email already exists.")
        LET exists = 1
        RETURN exists
    END IF
    RETURN exists
END FUNCTION
