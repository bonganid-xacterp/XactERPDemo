# ==============================================================
# Program   :   cl100_mast.4gl
# Purpose   :   Creditors Maintanance progragm for adding, edit, update and delete.
# Module    :   Creditors (cl)
# Number    :   100
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.20.10
# ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL utils_db
IMPORT FGL utils_lookup
IMPORT FGL utils_status_const
IMPORT FGL cl121_lkup

SCHEMA xactdemo_db

-- ==============================================================
-- Record definition
-- ==============================================================
DEFINE rec_mast RECORD
    acc_code LIKE cl01_mast.acc_code,
    supp_name LIKE cl01_mast.supp_name,
    phone LIKE cl01_mast.phone,
    email LIKE cl01_mast.email,
    address1 LIKE cl01_mast.address1,
    address2 LIKE cl01_mast.address2,
    address3 LIKE cl01_mast.address3,
    status LIKE cl01_mast.status,
    balance LIKE cl01_mast.balance
END RECORD

-- ==============================================================
-- MAIN
-- ==============================================================
MAIN
    IF NOT utils_globals.initialize_application() THEN
        DISPLAY "Initialization failed."
        EXIT PROGRAM 1
    END IF

    OPEN WINDOW w_cl101 WITH FORM "cl101_mast" ATTRIBUTES(STYLE = "modal")
    
    CALL run_creditors_master()
    CLOSE WINDOW w_cl101
END MAIN

-- ==============================================================
-- Menu controller
-- ==============================================================
FUNCTION run_creditors_master()
    DEFINE code STRING

    CALL utils_status_const.populate_status_combobox()

    MENU "MENU"

        COMMAND "Find"
            LET code = query_creditor()
            DISPLAY "Chosen acc code received in master profile " || code
            IF code IS NOT NULL THEN
                CALL load_creditor_by_code(code)
            ELSE
                CALL utils_globals.show_info("No record selected.")
            END IF

        COMMAND "Create"
            CALL add_creditor()

        COMMAND "Edit"
            CALL edit_creditor()

        COMMAND "Next"
            CALL next_creditor()

        COMMAND "Previous"
            CALL prev_creditor()

        COMMAND "Exit"
            EXIT MENU

    END MENU
END FUNCTION

-- ==============================================================
-- Lookup form popup - Enhanced version for frm_cl101_lkup
-- ==============================================================
FUNCTION query_creditor() RETURNS STRING
    DEFINE selected_code STRING

    -- Call the popup dialog from the lookup module
    LET selected_code = cl121_lkup.display_cred_list()

    IF selected_code IS NULL OR selected_code = "" THEN
        CALL utils_globals.show_info("No record selected.")
    ELSE
        CALL utils_globals.show_success("Selected: " || selected_code)
    END IF

    RETURN selected_code
END FUNCTION


-- ==============================================================
-- Add creditor
-- ==============================================================
FUNCTION add_creditor()
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
            AFTER FIELD supp_name
                IF rec_mast.supp_name IS NULL OR rec_mast.supp_name = "" THEN
                    CALL utils_globals.show_error("Customer Name is required")
                    NEXT FIELD supp_name
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

            ON ACTION accept ATTRIBUTE(TEXT = 'Add creditor')
                LET dup_found =
                    check_creditor_unique(
                        rec_mast.acc_code,
                        rec_mast.supp_name,
                        rec_mast.phone,
                        rec_mast.email)
                IF dup_found = 0 THEN
                    -- Save to database
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
                        VALUES(rec_mast.acc_code,
                            rec_mast.supp_name,
                            rec_mast.phone,
                            rec_mast.email,
                            rec_mast.status,
                            rec_mast.address1,
                            rec_mast.address2,
                            rec_mast.address3,
                            rec_mast.balance);
                    -- Confirmation popup
                    CALL utils_globals.show_success(
                        rec_mast.supp_name || " added successfully.")
                    EXIT DIALOG
                END IF
            ON ACTION cancel
                CALL utils_globals.show_info("Operation cancelled.")
                EXIT DIALOG
        END INPUT
    END DIALOG
END FUNCTION

-- ==============================================================
-- Edit creditor
-- ==============================================================
FUNCTION edit_creditor()
    DEFINE code STRING
    PROMPT "Enter Account Code to edit: " FOR code

    IF code IS NULL OR code = "" THEN
        CALL utils_globals.show_error("Account Code is required.")
        RETURN
    END IF

    SELECT * INTO rec_mast.* FROM cl01_mast WHERE acc_code = code
    IF SQLCA.SQLCODE <> 0 THEN
        CALL utils_globals.show_error("creditor not found: " || code)
        RETURN
    END IF

    CALL utils_status_const.populate_status_combobox()
    DISPLAY BY NAME rec_mast.*

    DIALOG
        INPUT BY NAME rec_mast.*
            AFTER FIELD supp_name
                IF rec_mast.supp_name IS NULL OR rec_mast.supp_name = "" THEN
                    CALL utils_globals.show_error("Customer Name is required.")
                    NEXT FIELD supp_name
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
                UPDATE cl01_mast
                    SET supp_name = rec_mast.supp_name,
                        phone = rec_mast.phone,
                        email = rec_mast.email,
                        status = rec_mast.status,
                        address1 = rec_mast.address1,
                        address2 = rec_mast.address2,
                        address3 = rec_mast.address3,
                        balance = rec_mast.balance
                    WHERE acc_code = rec_mast.acc_code

                CALL utils_globals.show_success(
                    rec_mast.supp_name || " updated successfully.")
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
FUNCTION next_creditor()
    MESSAGE "Next record"
END FUNCTION

FUNCTION prev_creditor()
    MESSAGE "Previous record"
END FUNCTION

-- ==============================================================
-- Check creditor uniqueness (simplified)
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
        CALL utils_globals.show_error("Customer name already exists.")
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

-- ==============================================================
-- Query single creditor
-- ==============================================================
FUNCTION load_creditor_by_code(p_code STRING)
    
    LET p_code = p_code.trim()  -- Remove any whitespace
    
    SELECT acc_code, supp_name, phone, email, status, address1, address2,
           address3, balance
      INTO rec_mast.*
      FROM cl01_mast
     WHERE acc_code = p_code
     
    CASE SQLCA.SQLCODE
        WHEN 0
            DISPLAY BY NAME rec_mast.*
        WHEN NOTFOUND
            CALL utils_globals.show_error("Creditor not found: " || p_code)
        OTHERWISE
            CALL utils_globals.show_error("Database error: " || SQLCA.SQLCODE)
    END CASE
END FUNCTION


