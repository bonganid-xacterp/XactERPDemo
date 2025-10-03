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

SCHEMA xactapp_db

TYPE t_status_item RECORD
    code SMALLINT,
    label STRING
END RECORD

-- record fields
DEFINE rec_mast RECORD
    acc_code LIKE dl01_mast.acc_code,
    cust_name LIKE dl01_mast.cust_name,
    address1 LIKE dl01_mast.address1,
    phone LIKE dl01_mast.phone,
    email LIKE dl01_mast.email,
    balance LIKE dl01_mast.balance,
    cr_limit LIKE dl01_mast.cr_limit,
    status LIKE dl01_mast.status
END RECORD

-- Local status array for combobox

#DEFINE g_status_values DYNAMIC ARRAY OF t_status_item

MAIN

    DEFINE db_status INT
    -- set as child of mdi_wrapper
    # CALL utils_globals.set_child_container()

    -- temp code to be removed later
    -- TODOS: This will be reomoved once the meina menu is working
    CALL utils_globals.hide_screen()
    -- check db connection
    LET db_status = utils_db.initialize_database()

    --open my window + form inside container

    OPEN WINDOW w_dl101
        WITH
        FORM "dl101_mast"
        ATTRIBUTES(STYLE = "main", TEXT = "Debtors Master")

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
            PROMPT "Search (* for all): " FOR search
            LET code = utils_lookup.run_lookup("DL", search)

            IF code IS NOT NULL THEN
                CALL load_debtor(code)
            ELSE
                CALL utils_globals.show_alert('No records found.', 'System Info')
            END IF
        COMMAND "Create"
            CALL add_debtor()
        COMMAND "Edit"
           CALL edit_debtor()
        COMMAND "Next"
            DISPLAY "Next Record"
        COMMAND "Previous"
            DISPLAY "Previous record"
        COMMAND "Exit"
            EXIT MENU
    END MENU
END FUNCTION

-- load
FUNCTION load_debtor(p_code STRING)
    SELECT acc_code,
        cust_name,
        address1,
        phone,
        email,
        balance,
        cr_limit,
        status
        INTO rec_mast.*
        FROM dl01_mast
        WHERE acc_code = p_code

    -- show record on form
    DISPLAY BY NAME rec_mast.*
END FUNCTION

-- add new debtor
FUNCTION add_debtor()

    CLEAR FORM

    INPUT BY NAME rec_mast.* ATTRIBUTE(UNBUFFERED)

        ON ACTION ACCEPT ATTRIBUTE(TEXT='Add Debtor')
            -- Save to database
            INSERT INTO dl01_mast(
                acc_code,
                cust_name,
                address1,
                phone,
                email,
                balance,
                cr_limit,
                status)
                VALUES(rec_mast.acc_code,
                    rec_mast.cust_name,
                    rec_mast.address1,
                    rec_mast.phone,
                    rec_mast.email,
                    rec_mast.balance,
                    rec_mast.cr_limit,
                    rec_mast.status);

            -- Confirmation popup
            CALL show_message("Debtor added successfully.", "Success", "info")

            EXIT INPUT

        ON ACTION cancel
            CALL show_message("Operation cancelled.", "Notice", "info")
            EXIT INPUT
    END INPUT
END FUNCTION

-- Edit / Update debtor
FUNCTION edit_debtor()
    
END FUNCTION 