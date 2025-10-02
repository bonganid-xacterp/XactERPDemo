# ==============================================================
# Program   :   dl100_mast.4gl
# Purpose   :   Debtors Master maintenance program
# Module    :   Debtors
# Number    :   100
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.20.10
# ==============================================================

IMPORT FGL utils_ui
IMPORT ui

MAIN
    -- Step 1: set myself as child of mdi_wrapper
    CALL utils_ui.set_child_container()

    -- Step 2: open my window + form inside container
    OPEN WINDOW w_dl100
        WITH
        FORM "dl100_mast"
        ATTRIBUTES(STYLE = "child", TEXT = "Debtors Master")

    -- Step 3: run my menu / input loop
    CALL run_debtors_master()

    -- Step 4: close window when done
    CLOSE WINDOW w_dl100

END MAIN

FUNCTION run_debtors_master()
    MENU "Debtors Master"
        COMMAND "New"
            MESSAGE "Add new debtor (TODO)"
        COMMAND "Edit"
            MESSAGE "Edit existing debtor (TODO)"
        COMMAND "Exit"
            EXIT MENU
    END MENU
END FUNCTION
