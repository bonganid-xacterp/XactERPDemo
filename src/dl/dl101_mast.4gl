# ==============================================================
# Program   :   dl100_mast.4gl
# Purpose   :   Debtors Master program
# Module    :   Debtors (dl)
# Number    :   101
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.20.10
# ==============================================================

IMPORT ui -- Genero UI functions
IMPORT FGL utils_globals -- UI common utilities
IMPORT FGL utils_lookup -- global lookup by program utilities
IMPORT FGL utils_db -- Database connection helpers
IMPORT FGL utils_status_const

SCHEMA xactdemo_db

TYPE t_status_item RECORD
    code SMALLINT,
    label STRING
END RECORD

-- record fields
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

DEFINE p_rec_nav_flag SMALLINT

-- Local status array for combobox

#DEFINE g_status_values DYNAMIC ARRAY OF t_status_item

MAIN

    DEFINE db_status SMALLINT
    -- set as child of mdi_wrapper
    -- CALL utils_globals.set_child_container()

    -- temp code to be removed later
    -- TODOS: This will be reomoved once the meina menu is working
    -- CALL utils_globals.hide_screen()
    -- check db connection
    -- LET db_status = utils_db.initialize_database()

    --open my window + form inside container

    OPEN WINDOW w_dl101 WITH FORM "dl101_mast" ATTRIBUTES(STYLE = "main")

    -- run my menu / input loop
    CALL run_debtors_master()

    -- close window when done
    CLOSE WINDOW w_dl101

END MAIN

-- Show menus
FUNCTION run_debtors_master()
    DEFINE code STRING
    DEFINE search STRING

    -- Load status options into combobox
    CALL utils_status_const.populate_status_combobox()

    MENU "Debtors Master"
        COMMAND "Find"
            CALL load_lookup_form()
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

-- load lookup form
FUNCTION load_lookup_form()

    OPEN WINDOW dl_lkup WITH FORM "dl121_lkup" ATTRIBUTES(TYPE = POPUP)
END FUNCTION

-- load customer list
FUNCTION fetch_debt_list()

END FUNCTION

-- display debtor
FUNCTION show_debt()
    DISPLAY BY NAME rec_mast.*
END FUNCTION

-- load selected debtor
FUNCTION query_debtor(p_code STRING)
    SELECT acc_code,
        cust_name,
        phone,
        email,
        status,
        address1,
        address2,
        address3,
        cr_limit,
        balance
        INTO rec_mast.*
        FROM dl01_mast
        WHERE acc_code = p_code

    -- show record on form
    DISPLAY BY NAME rec_mast.*
END FUNCTION

-- add new debtor
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

-- Edit / Update debtor
FUNCTION edit_debtor()

    DEFINE dup_found SMALLINT
    DEFINE code STRING

    PROMPT "Enter Account Code to edit: " FOR code

    IF code IS NULL OR code = "" THEN
        CALL utils_globals.show_error("Account Code is required.")
        RETURN
    END IF

    SELECT acc_code,
        cust_name,
        phone,
        email,
        status,
        address1,
        address2,
        address3,
        cr_limit,
        balance
        INTO rec_mast.acc_code,
            rec_mast.cust_name,
            rec_mast.phone,
            rec_mast.email,
            rec_mast.status,
            rec_mast.address1,
            rec_mast.address2,
            rec_mast.address3,
            rec_mast.cr_limit,
            rec_mast.balance
        FROM dl01_mast
        WHERE acc_code = code

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
                LET dup_found =
                    check_debtor_unique(
                        rec_mast.acc_code,
                        rec_mast.cust_name,
                        rec_mast.phone,
                        rec_mast.email)

                IF dup_found = 0 THEN
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
                END IF

            ON ACTION cancel
                CALL utils_globals.show_alert("Edit cancelled.", "Notice")
                EXIT DIALOG
        END INPUT
    END DIALOG
END FUNCTION

-- view next record
FUNCTION next_debtor()
    MESSAGE "next record "

END FUNCTION

-- view previous record
FUNCTION prev_debtor()
    MESSAGE "prev record"
END FUNCTION

-- check record uniquenesss
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
