-- ==============================================================
-- Program   : dl100_mast.4gl
-- Purpose   : Debtors Master maintenance
-- Module    : Debtors (dl)
-- Number    : 101
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

IMPORT ui

IMPORT FGL utils_globals
IMPORT FGL dl121_lkup
IMPORT FGL utils_status_const

SCHEMA xactdemo_db

-- ==============================================================
-- Record definitions
-- ==============================================================
TYPE debtor_t RECORD
    acc_code   LIKE dl01_mast.acc_code,
    cust_name  LIKE dl01_mast.cust_name,
    phone      LIKE dl01_mast.phone,
    email      LIKE dl01_mast.email,
    status     LIKE dl01_mast.status,
    address1   LIKE dl01_mast.address1,
    address2   LIKE dl01_mast.address2,
    address3   LIKE dl01_mast.address3,
    cr_limit   LIKE dl01_mast.cr_limit,
    balance    LIKE dl01_mast.balance
END RECORD

DEFINE rec_debt  debtor_t
DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx  INTEGER
DEFINE is_edit_mode SMALLINT

-- ==============================================================
-- MAIN
-- ==============================================================
MAIN
    IF NOT utils_globals.initialize_application() THEN
        DISPLAY "Initialization failed."
        EXIT PROGRAM 1
    END IF

    OPEN WINDOW w_dl101 WITH FORM "dl101_mast" ATTRIBUTES(STYLE = "main")
    CALL init_module()
    CLOSE WINDOW w_dl101
END MAIN

-- ==============================================================
-- Statuses popup
-- ==============================================================
PUBLIC FUNCTION get_status_desc(p_code SMALLINT) RETURNS STRING
    CASE p_code
        WHEN 1 RETURN "Active"
        WHEN 0 RETURN "Inactive"
        WHEN -1 RETURN "Archived"
        OTHERWISE RETURN "Unknown"
    END CASE
END FUNCTION


-- ==============================================================
-- Lookup popup
-- ==============================================================
FUNCTION query_debtor() RETURNS STRING
    DEFINE selected_code STRING
    LET selected_code = dl121_lkup.fetch_debt_list()
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
    LET field_list[1] = "cust_name"
    LET field_list[2] = "phone"
    LET field_list[3] = "email"
    LET field_list[4] = "address1"
    LET field_list[5] = "address2"
    LET field_list[6] = "address3"
    LET field_list[7] = "status"
    LET field_list[8] = "cr_limit"
    LET field_list[9] = "balance"
    
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
    --DEFINE dlg ui.Dialog

   CALL utils_status_const.populate_status_combobox()
    
    -- Start in read-only mode
    LET is_edit_mode = FALSE

    DIALOG ATTRIBUTES(UNBUFFERED)

        -- -------------------------
        -- Header section
        -- -------------------------
        INPUT BY NAME rec_debt.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME="debtors")

            BEFORE INPUT
                -- Make fields readonly initially
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)
                
            ON ACTION find  ATTRIBUTES(TEXT="Search", IMAGE="zoom")
                CALL query_debtors_lookup()
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)
                
            ON ACTION new  ATTRIBUTES(TEXT="Create", IMAGE="new")
                CALL new_debtor()
                -- After successful add, load in readonly mode
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)
                
            ON ACTION edit  ATTRIBUTES(TEXT="Edit", IMAGE="edit")
                IF rec_debt.acc_code IS NULL OR rec_debt.acc_code = "" THEN
                    CALL utils_globals.show_info("No record selected to edit.")
                ELSE
                    LET is_edit_mode = TRUE
                    CALL DIALOG.setActionActive("save", TRUE)
                    CALL DIALOG.setActionActive("edit", FALSE)
                    MESSAGE "Edit mode enabled. Make changes and click Update to save."
                END IF
                
            ON ACTION save  ATTRIBUTES(TEXT="Update", IMAGE="filesave")
                IF is_edit_mode THEN
                    CALL save_debtor()
                    LET is_edit_mode = FALSE
                    CALL DIALOG.setActionActive("save", FALSE)
                    CALL DIALOG.setActionActive("edit", TRUE)
                END IF
                
            ON ACTION DELETE  ATTRIBUTES(TEXT="Delete", IMAGE="delete")
                CALL delete_debtor()

            ON ACTION FIRST  ATTRIBUTES(TEXT="First Record", IMAGE="first")
                CALL move_record(-2)
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)
                
            ON ACTION PREVIOUS  ATTRIBUTES(TEXT="Previous", IMAGE="prev")
                CALL move_record(-1)
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)
                
            ON ACTION NEXT  ATTRIBUTES(TEXT="Next", IMAGE="next")
                CALL move_record(1)
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)
                
            ON ACTION LAST  ATTRIBUTES(TEXT="Last Record", IMAGE="last")
                CALL move_record(2)
                LET is_edit_mode = FALSE
                CALL DIALOG.setActionActive("save", FALSE)
                CALL DIALOG.setActionActive("edit", TRUE)

            ON ACTION QUIT ATTRIBUTES(TEXT="Quit", IMAGE="quit")
                EXIT DIALOG
                
            BEFORE FIELD cust_name, phone, email, address1, address2, address3, status, cr_limit, balance
                IF NOT is_edit_mode THEN
                    CALL utils_globals.show_info("Click Edit button to modify this record.")
                    NEXT FIELD acc_code
                END IF

        END INPUT

        BEFORE DIALOG
            -- Initial load in read-only mode
            LET ok = select_debtors("1=1")
            LET is_edit_mode = FALSE

    END DIALOG
END FUNCTION

-- ==============================================================
-- Query using Lookup Window
-- ==============================================================
FUNCTION query_debtors_lookup()
    DEFINE selected_code STRING
    
    LET selected_code = query_debtor()
    
    IF selected_code IS NOT NULL THEN
        CALL load_debtor(selected_code)
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
FUNCTION query_debtors()
    DEFINE where_clause STRING
    DEFINE ok SMALLINT

    CLEAR FORM

    CONSTRUCT BY NAME where_clause ON
        dl01_mast.acc_code,
        dl01_mast.cust_name,
        dl01_mast.phone

        IF int_flag THEN
        -- user pressed ESC or Cancel
        MESSAGE "Search cancelled."
        RETURN
    END IF

    IF where_clause IS NULL OR where_clause = "" THEN
        LET where_clause = "1=1"  -- default (show all)
    END IF

    LET ok = select_debtors(where_clause)
END FUNCTION

-- ==============================================================
-- SELECT Debtors into Array
-- ==============================================================
FUNCTION select_debtors(where_clause) RETURNS SMALLINT 
    DEFINE where_clause STRING
    DEFINE code STRING
    DEFINE idx INTEGER

    CALL arr_codes.clear()
    LET idx = 0

    DECLARE c_curs CURSOR FROM
        "SELECT acc_code FROM dl01_mast WHERE " || where_clause || " ORDER BY acc_code"

    FOREACH c_curs INTO code
        LET idx = idx + 1
        LET arr_codes[idx] = code
    END FOREACH
    FREE c_curs

    IF arr_codes.getLength() == 0 THEN
        CALL utils_globals.get_msg_no_record()
        RETURN FALSE
    END IF

    LET curr_idx = 1
    CALL load_debtor(arr_codes[curr_idx])
    RETURN TRUE
END FUNCTION

-- ==============================================================
-- Load Single Debtor
-- ==============================================================
FUNCTION load_debtor(p_code STRING)
    DEFINE p_status SMALLINT

    SELECT acc_code, cust_name, phone, email, address1, address2,
           address3, status, cr_limit, balance
      INTO rec_debt.*
      FROM dl01_mast
     WHERE acc_code = p_code

     LET p_status = rec_debt.status
     -- Show only saved value for view mode
    -- CALL utils_status_const.populate_status_single(p_status)

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_debt.*
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
                CALL utils_globals.get_msg_sol()
                RETURN
            END IF
        WHEN 1
            IF curr_idx < arr_codes.getLength() THEN
                LET curr_idx = curr_idx + 1
            ELSE
                --MESSAGE msg05
                CALL utils_globals.get_msg_eol()
                RETURN
            END IF
        WHEN 2
            LET curr_idx = arr_codes.getLength()
    END CASE

    CALL load_debtor(arr_codes[curr_idx])
END FUNCTION

-- ==============================================================
-- New Debtor
-- ==============================================================
FUNCTION new_debtor()
   DEFINE dup_found SMALLINT
   DEFINE ok SMALLINT 
   DEFINE new_acc_code STRING
   
    -- open a modal popup window just for the new debtor
    OPEN WINDOW w_new WITH FORM "dl101_mast" ATTRIBUTES(STYLE="main")

    -- Clear all fields and set defaults
    INITIALIZE rec_debt.* TO NULL
    LET rec_debt.status = 1
    LET rec_debt.balance = 0.00
    LET rec_debt.cr_limit = 0.00
    
    DISPLAY BY NAME rec_debt.*

    MESSAGE "Enter new debtor details, then click Save or Cancel."

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_debt.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME="new_debtor")

            -- validations
            AFTER FIELD acc_code
                IF rec_debt.acc_code IS NULL OR rec_debt.acc_code = "" THEN
                    CALL utils_globals.show_error("Account Code is required.")
                    NEXT FIELD acc_code
                END IF

            AFTER FIELD cust_name
                IF rec_debt.cust_name IS NULL OR rec_debt.cust_name = "" THEN
                    CALL utils_globals.show_error("Customer Name is required.")
                    NEXT FIELD cust_name
                END IF

            AFTER FIELD email
                IF NOT utils_globals.is_valid_email(rec_debt.email) THEN
                    CALL utils_globals.show_error("Invalid email format.")
                    NEXT FIELD email
                END IF

            -- main actions
            ON ACTION save ATTRIBUTES (TEXT="Save")
                LET dup_found = check_debtor_unique(
                    rec_debt.acc_code,
                    rec_debt.cust_name,
                    rec_debt.phone,
                    rec_debt.email)

                IF dup_found = 0 THEN
                    INSERT INTO dl01_mast (
                        acc_code, cust_name, phone, email,
                        status, address1, address2, address3,
                        cr_limit, balance)
                    VALUES (
                        rec_debt.acc_code, rec_debt.cust_name, rec_debt.phone, rec_debt.email,
                        rec_debt.status, rec_debt.address1, rec_debt.address2, rec_debt.address3,
                        rec_debt.cr_limit, rec_debt.balance)

                    CALL utils_globals.show_success("Debtor saved successfully.")
                    LET new_acc_code = rec_debt.acc_code
                    EXIT DIALOG
                END IF

            ON ACTION cancel
                CALL utils_globals.show_info("New debtor cancelled.")
                LET new_acc_code = NULL
                EXIT DIALOG
        END INPUT
    END DIALOG

    CLOSE WINDOW w_new
    
    -- Load the newly added record in readonly mode
    IF new_acc_code IS NOT NULL THEN
        CALL load_debtor(new_acc_code)
        CALL arr_codes.clear()
        LET arr_codes[1] = new_acc_code
        LET curr_idx = 1
    ELSE
        -- Cancelled, reload the list
        LET ok = select_debtors("1=1")
    END IF
END FUNCTION

-- ==============================================================
-- Save / Update
-- ==============================================================
FUNCTION save_debtor()
    DEFINE exists INTEGER

    SELECT COUNT(*) INTO exists FROM dl01_mast
     WHERE acc_code = rec_debt.acc_code

    IF exists = 0 THEN
    -- save data into the db
        INSERT INTO dl01_mast
            (acc_code, cust_name, phone, email,
             address1, address2, address3, status,
             cr_limit, balance)
        VALUES
            (rec_debt.acc_code, rec_debt.cust_name,
             rec_debt.phone, rec_debt.email,
             rec_debt.address1, rec_debt.address2,
             rec_debt.address3, rec_debt.status,
             rec_debt.cr_limit, rec_debt.balance)
        CALL utils_globals.get_msg_saved()
    ELSE
    -- update record
        UPDATE dl01_mast SET
            cust_name = rec_debt.cust_name,
            phone     = rec_debt.phone,
            email     = rec_debt.email,
            address1  = rec_debt.address1,
            address2  = rec_debt.address2,
            address3  = rec_debt.address3,
            status    = rec_debt.status,
            cr_limit  = rec_debt.cr_limit,
            balance   = rec_debt.balance
        WHERE acc_code = rec_debt.acc_code
        CALL utils_globals.get_msg_updated()
    END IF

   CALL load_debtor(rec_debt.acc_code)
END FUNCTION

-- ==============================================================
-- Delete Debtor
-- ==============================================================
FUNCTION delete_debtor()
    DEFINE ok SMALLINT
   -- If no record is loaded, skip
    IF rec_debt.acc_code IS NULL OR rec_debt.acc_code = "" THEN
        CALL utils_globals.show_info('No debtor selected for deletion.')
        RETURN
    END IF

    -- Confirm delete
    LET ok = utils_globals.show_confirm("Delete this debtor: " || rec_debt.cust_name || "?", "Confirm Delete")

    IF NOT ok THEN
        MESSAGE "Delete cancelled."
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    DELETE FROM dl01_mast WHERE acc_code = rec_debt.acc_code
    CALL utils_globals.get_msg_deleted()
    LET ok  = select_debtors("1=1")
END FUNCTION

-- ==============================================================
-- Check debtor uniqueness
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