# ==============================================================
# Program   :   dl100_mast.4gl
# Purpose   :   Debtors Master program
# Module    :   Debtors (dl)
# Number    :   101
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.20.10
# ==============================================================

IMPORT FGL utils_globals -- utils for global / sharable utilities
IMPORT ui
IMPORT FGL utils_lookup
IMPORT FGL utils_status_const

SCHEMA xactapp_db

-- record fields
DEFINE rec RECORD
    acc_code LIKE dl01_mast.acc_code,
    cust_name LIKE dl01_mast.cust_name,
    address1 LIKE dl01_mast.address1,
    phone LIKE dl01_mast.phone,
    email LIKE dl01_mast.email,
    balance LIKE dl01_mast.balance,
    cr_limit LIKE dl01_mast.cr_limit,
    status LIKE dl01_mast.status
END RECORD

MAIN
    -- set as child of mdi_wrapper
    CALL utils_globals.set_child_container()

    -- temp code to be removed later
    -- TODOS: This will be reomoved once the meina menu is working
    CALL utils_globals.hide_screen()

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
    CALL populate_status_combobox()

    MENU "Debtors Master"
        COMMAND "Find"
            PROMPT "Search (* for all): " FOR search
            LET code = utils_lookup.run_lookup("DL", search)

            IF code IS NOT NULL THEN
                CALL load_debtor(code)
            ELSE
                ERROR 'No records found.', 'System Info', 'info'
            END IF
        COMMAND "Create"
            CALL add_debtor()
        COMMAND "Edit"
            MESSAGE "Edit existing debtor (TODO)"
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
        INTO rec.*
        FROM dl01_mast
        WHERE acc_code = p_code

    -- show record on form
    DISPLAY BY NAME rec.*
END FUNCTION

-- add new debtor
FUNCTION add_debtor()
    INITIALIZE rec.* TO NULL
    LET rec.status = 1 -- default Active

    INPUT BY NAME rec.* ATTRIBUTE(UNBUFFERED, ACCEPT = "ALL")

        ON ACTION ACCEPT
            -- Save to database
            INSERT INTO dl01_mast VALUES(rec.*)

            -- Confirmation popup
            CALL show_message("Debtor added successfully.", "Success", "info")

            EXIT INPUT

        ON ACTION cancel
            CALL show_message("Operation cancelled.", "Notice", "info")
            EXIT INPUT
    END INPUT
END FUNCTION

-- load status combos
FUNCTION populate_status_combobox()
    DEFINE f ui.Form
    DEFINE i INTEGER

    -- initialize statuses
    CALL utils_status_const.init_status_constants()

    LET f = ui.Window.getCurrent().getForm()

    -- clear old values first

    -- loop through global array and add items

END FUNCTION
