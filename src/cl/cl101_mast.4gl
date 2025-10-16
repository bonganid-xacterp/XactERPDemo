-- ==============================================================
-- Program   : cl101_mast.4gl
-- Purpose   :creditors Master maintenance
-- Module    :creditors (cl)
-- Number    : 101
-- Author    : Bongani clamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

IMPORT ui

IMPORT FGL utils_globals
IMPORT FGL cl121_lkup
IMPORT FGL utils_status_const

SCHEMA demoapp_db

-- ==============================================================
-- Record definitions
-- ==============================================================
TYPE creditor_t RECORD
    acc_code LIKE cl01_mast.acc_code,
    supp_name LIKE cl01_mast.supp_name,
    phone LIKE cl01_mast.phone,
    email LIKE cl01_mast.email,
    status LIKE cl01_mast.status,
    address1 LIKE cl01_mast.address1,
    address2 LIKE cl01_mast.address2,
    address3 LIKE cl01_mast.address3,
    balance LIKE cl01_mast.balance
END RECORD

DEFINE rec_cred creditor_t
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

    OPEN WINDOW w_cl101 WITH FORM "cl101_mast" ATTRIBUTES(STYLE = "main")
    CALL init_module()
    CLOSE WINDOW w_cl101
END MAIN

-- ==============================================================
-- Lookup popup
-- ==============================================================
FUNCTION query_creditor() RETURNS STRING
    DEFINE selected_code STRING
    LET selected_code = cl121_lkup.load_lookup_form_with_search()
    RETURN selected_code
END FUNCTION

-- ==============================================================
-- Set fields editable/readonly
-- ==============================================================
FUNCTION set_fields_editable(editable SMALLINT)
    DEFINE f ui.Form
    --DEFINE fields STRING
    DEFINE i INTEGER
    DEFINE field_list DYNAMIC ARRAY OF STRING

    LET f = ui.Window.getCurrent().getForm()

    -- Define all fields that should be editable/readonly
    LET field_list[1] = "supp_name"
    LET field_list[2] = "phone"
    LET field_list[3] = "email"
    LET field_list[4] = "status"
    LET field_list[5] = "address1"
    LET field_list[6] = "address2"
    LET field_list[7] = "address3"
    LET field_list[8] = "balance"

    FOR i = 1 TO field_list.getLength()
        IF editable THEN
            CALL f.setFieldHidden(field_list[i], FALSE)
        ELSE
            -- In readonly mode, make fields non-editable
            CALL f.setFieldHidden(field_list[i], FALSE)
        END IF
    END FOR

    -- acc_code is always readonly after initial entry
    LET is_edit_mode = editable
END FUNCTION

-- ==============================================================
-- DIALOG Controller
-- ==============================================================
FUNCTION init_module()

    DEFINE ok SMALLINT

    -- Start in read-only mode
    LET is_edit_mode = FALSE

    DIALOG ATTRIBUTES(UNBUFFERED)

        -- -------------------------
        -- Header section
        -- -------------------------
        INPUT BY NAME rec_cred.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "creditors")

            BEFORE INPUT
                -- Make fields readonly initially
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION find ATTRIBUTES(TEXT = "Search", IMAGE = "zoom")
                CALL query_creditors_lookup()
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION new ATTRIBUTES(TEXT = "Create", IMAGE = "new")
                CALL new_creditor()
                -- After successful add, load in readonly mode
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
                IF rec_cred.acc_code IS NULL OR rec_cred.acc_code = "" THEN
                    CALL utils_globals.show_info("No record selected to edit.")
                ELSE
                    LET is_edit_mode = TRUE
                    CALL DIALOG.setActionActive("save", TRUE)
                    CALL DIALOG.setActionActive("edit", FALSE)
                    MESSAGE "Edit mode enabled. Make changes and click Update to save."
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
                IF is_edit_mode THEN
                    CALL save_creditor()
                    LET is_edit_mode = FALSE
                    CALL DIALOG.setActionActive("save", FALSE)
                    CALL DIALOG.setActionActive("edit", TRUE)
                END IF

            ON ACTION DELETE ATTRIBUTES(TEXT = "Delete", IMAGE = "delete")
                CALL delete_creditor()

            ON ACTION FIRST ATTRIBUTES(TEXT = "First Record", IMAGE = "first")
                CALL move_record(-2)
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION PREVIOUS ATTRIBUTES(TEXT = "Previous", IMAGE = "prev")
                CALL move_record(-1)
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION NEXT ATTRIBUTES(TEXT = "Next", IMAGE = "next")
                CALL move_record(1)
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION LAST ATTRIBUTES(TEXT = "Last Record", IMAGE = "last")
                CALL move_record(2)
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION QUIT ATTRIBUTES(TEXT = "Quit", IMAGE = "quit")
                EXIT DIALOG

            BEFORE FIELD acc_code,
                supp_name,
                phone,
                email,
                status,
                address1,
                address2,
                address3,
                balance
                IF NOT is_edit_mode THEN
                    CALL utils_globals.show_info(
                        "Click Edit button to modify this record.")
                    NEXT FIELD supp_name
                END IF

        END INPUT

        BEFORE DIALOG
            -- Initial load in read-only mode
            LET ok = select_creditors("1=1")
            LET is_edit_mode = FALSE

    END DIALOG
END FUNCTION

-- ==============================================================
-- Query using Lookup Window
-- ==============================================================
FUNCTION query_creditors_lookup()
    DEFINE selected_code STRING

    LET selected_code = query_creditor()

    IF selected_code IS NOT NULL THEN
        CALL load_creditor_enq(selected_code)
        -- Update the array to contain just this record for navigation
        CALL arr_codes.clear()
        LET arr_codes[1] = selected_code
        LET curr_idx = 1
    ELSE
        CALL utils_globals.show_error("No records found")
    END IF
END FUNCTION

-- ==============================================================
-- Query  (CONSTRUCT)
-- ==============================================================
FUNCTION query_creditors()
    DEFINE where_clause STRING
    DEFINE ok SMALLINT

    CLEAR FORM

    CONSTRUCT BY NAME where_clause
        ON cl01_mast.acc_code, cl01_mast.supp_name, cl01_mast.phone

    IF int_flag THEN
        -- user pressed ESC or Cancel
        MESSAGE "Search cancelled."
        RETURN
    END IF

    IF where_clause IS NULL OR where_clause = "" THEN
        LET where_clause = "1=1" -- default (show all)
    END IF

    LET ok = select_creditors(where_clause)
END FUNCTION

-- ==============================================================
-- SELECTcreditors into Array
-- ==============================================================
FUNCTION select_creditors(where_clause) RETURNS SMALLINT
    DEFINE where_clause STRING
    DEFINE code STRING
    DEFINE idx INTEGER

    CALL arr_codes.clear()
    LET idx = 0

    DECLARE c_curs CURSOR FROM "SELECT acc_code FROM cl01_mast WHERE "
        || where_clause
        || " ORDER BY acc_code"

    FOREACH c_curs INTO code
        LET idx = idx + 1
        LET arr_codes[idx] = code
    END FOREACH
    FREE c_curs

    IF arr_codes.getLength() == 0 THEN
        CALL utils_globals.msg_no_record()
        RETURN FALSE
    END IF

    LET curr_idx = 1
    CALL load_creditor_enq(arr_codes[curr_idx])
    RETURN TRUE
END FUNCTION

-- ==============================================================
-- Load Singlecreditor
-- ==============================================================
FUNCTION load_creditor_enq(p_code STRING)

    SELECT acc_code,
        supp_name,
        phone,
        email,
        address1,
        address2,
        address3,
        status,
        balance
        INTO rec_cred.*
        FROM cl01_mast
        WHERE acc_code = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_cred.*
    END IF
END FUNCTION

-- ==============================================================
-- Navigation
-- ==============================================================
FUNCTION move_record(dir SMALLINT)
    CASE dir
        WHEN -2
            LET curr_idx = 1
        WHEN -1
            IF curr_idx > 1 THEN
                LET curr_idx = curr_idx - 1
            ELSE
                --MESSAGE msg06
                CALL utils_globals.msg_start_of_list()
                RETURN
            END IF
        WHEN 1
            IF curr_idx < arr_codes.getLength() THEN
                LET curr_idx = curr_idx + 1
            ELSE
                --MESSAGE msg05
                CALL utils_globals.msg_end_of_list()
                RETURN
            END IF
        WHEN 2
            LET curr_idx = arr_codes.getLength()
    END CASE

    CALL load_creditor_enq(arr_codes[curr_idx])
END FUNCTION

-- ==============================================================
-- Newcreditor
-- ==============================================================
FUNCTION new_creditor()
    DEFINE dup_found SMALLINT
    DEFINE ok SMALLINT
    DEFINE new_acc_code STRING

    -- open a modal popup window just for the newcreditor
    OPEN WINDOW w_new WITH FORM "cl101_mast" ATTRIBUTES(STYLE = "main")

    -- Clear all fields and set defaults
    INITIALIZE rec_cred.* TO NULL
    LET rec_cred.status = 1

    DISPLAY BY NAME rec_cred.*

    MESSAGE "Enter newcreditor details, then click Save or Cancel."

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_cred.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_creditor")

            -- validations
            AFTER FIELD acc_code
                IF rec_cred.acc_code IS NULL OR rec_cred.acc_code = "" THEN
                    CALL utils_globals.show_error("Account Code is required.")
                    NEXT FIELD acc_code
                END IF

            AFTER FIELD supp_name
                IF rec_cred.supp_name IS NULL OR rec_cred.supp_name = "" THEN
                    CALL utils_globals.show_error("Customer Name is required.")
                    NEXT FIELD supp_name
                END IF

            AFTER FIELD email
                IF NOT utils_globals.is_valid_email(rec_cred.email) THEN
                    CALL utils_globals.show_error("Invalid email format.")
                    NEXT FIELD email
                END IF

                -- main actions
            ON ACTION save ATTRIBUTES(TEXT = "Save")
                LET dup_found =
                    check_creditor_unique(
                        rec_cred.acc_code,
                        rec_cred.supp_name,
                        rec_cred.phone,
                        rec_cred.email)

                IF dup_found = 0 THEN
                    INSERT INTO cl01_mast(
                        acc_code,
                        supp_name,
                        phone,
                        email,
                        status,
                        address1,
                        address2,
                        address3,
                        balance)
                        VALUES(rec_cred.acc_code,
                            rec_cred.supp_name,
                            rec_cred.phone,
                            rec_cred.email,
                            rec_cred.status,
                            rec_cred.address1,
                            rec_cred.address2,
                            rec_cred.address3,
                            rec_cred.balance)

                    CALL utils_globals.show_success(
                        "Creditor saved successfully.")
                    LET new_acc_code = rec_cred.acc_code
                    EXIT DIALOG
                END IF

            ON ACTION cancel
                LET new_acc_code = NULL
                EXIT DIALOG
        END INPUT
    END DIALOG

    CLOSE WINDOW w_new

    -- Load the newly added record in readonly mode
    IF new_acc_code IS NOT NULL THEN
        CALL load_creditor_enq(new_acc_code)
        CALL arr_codes.clear()
        LET arr_codes[1] = new_acc_code
        LET curr_idx = 1
    ELSE
        -- Cancelled, reload the list
        LET ok = select_creditors("1=1")
    END IF
END FUNCTION

-- ==============================================================
-- Save / Update
-- ==============================================================
FUNCTION save_creditor()
    DEFINE exists INTEGER

    SELECT COUNT(*)
        INTO exists
        FROM cl01_mast
        WHERE acc_code = rec_cred.acc_code

    IF exists = 0 THEN
        -- save data into the db
        INSERT INTO cl01_mast(
            acc_code,
            supp_name,
            phone,
            email,
            address1,
            address2,
            address3,
            status,
            balance)
            VALUES(rec_cred.acc_code,
                rec_cred.supp_name,
                rec_cred.phone,
                rec_cred.email,
                rec_cred.address1,
                rec_cred.address2,
                rec_cred.address3,
                rec_cred.status,
                rec_cred.balance)
        CALL utils_globals.msg_saved()
    ELSE
        -- update record
        UPDATE cl01_mast
            SET supp_name = rec_cred.supp_name,
                phone = rec_cred.phone,
                email = rec_cred.email,
                address1 = rec_cred.address1,
                address2 = rec_cred.address2,
                address3 = rec_cred.address3,
                status = rec_cred.status,
                balance = rec_cred.balance
            WHERE acc_code = rec_cred.acc_code
        CALL utils_globals.msg_updated()
    END IF

    CALL load_creditor_enq(rec_cred.acc_code)
END FUNCTION

-- ==============================================================
-- Deletecreditor
-- ==============================================================
FUNCTION delete_creditor()
    DEFINE ok SMALLINT
    -- If no record is loaded, skip
    IF rec_cred.acc_code IS NULL OR rec_cred.acc_code = "" THEN
        CALL utils_globals.show_info('No creditor selected for deletion.')
        RETURN
    END IF

    -- Confirm delete
    LET ok =
        utils_globals.show_confirm(
            "Delete this creditor: " || rec_cred.supp_name || "?",
            "Confirm Delete")

    IF NOT ok THEN
        MESSAGE "Delete cancelled."
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    DELETE FROM cl01_mast WHERE acc_code = rec_cred.acc_code
    CALL utils_globals.msg_deleted()
    LET ok = select_creditors("1=1")
END FUNCTION

-- ==============================================================
-- Checkcreditor uniqueness
-- ==============================================================
FUNCTION check_creditor_unique(
    p_acc_code STRING, p_supp_name STRING, p_phone STRING, p_email STRING)
    RETURNS SMALLINT
    DEFINE dup_count INTEGER
    DEFINE exists SMALLINT
    LET exists = 0
-- check for duplicate account code
    SELECT COUNT(*) INTO dup_count FROM cl01_mast WHERE acc_code = p_acc_code
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Duplicate account code already exists.")
        LET exists = 1
        RETURN exists
    END IF
-- check for duplicate name
    SELECT COUNT(*) INTO dup_count FROM cl01_mast WHERE supp_name = p_supp_name
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Supplier name already exists.")
        LET exists = 1
        RETURN exists
    END IF
-- check for duplicate phone
    SELECT COUNT(*) INTO dup_count FROM cl01_mast WHERE phone = p_phone
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Phone number already exists.")
        LET exists = 1
        RETURN exists
    END IF
-- check for duplicate email
    SELECT COUNT(*) INTO dup_count FROM cl01_mast WHERE email = p_email
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Email already exists.")
        LET exists = 1
        RETURN exists
    END IF
    RETURN exists
END FUNCTION
