# ==============================================================
# Program   :   dl100_mast.4gl
# Purpose   :   Debtors Master program
# Module    :   Debtors (dl)
# Number    :   101
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.20.10
# ==============================================================

IMPORT FGL utils_ui -- utils for global / sharable utilities
IMPORT ui

MAIN
    -- set as child of mdi_wrapper
    CALL utils_ui.set_child_container()

    --open my window + form inside container
    OPEN WINDOW w_dl101
        WITH
        FORM "dl101_mast"
        ATTRIBUTES(STYLE = "child", TEXT = "Debtors Master")

    -- run my menu / input loop
    CALL run_debtors_master()

    -- close window when done
    CLOSE WINDOW w_dl101

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
