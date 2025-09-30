# ==============================================================
# Program   :   main_shell.4gl
# Purpose   :   Centralized container window module for loading
#               other programs.
# Module    :   main
# Number    :   
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.2.1
# ==============================================================



IMPORT FGL utils_ui
IMPORT FGL dl100_mast

FUNCTION main_application_menu()

    -- Set page title (top bar, if defined in form)
    CALL utils_ui.set_page_title("Dashboard")

    MESSAGE 'ver 1.0'
--
    MENU "" ATTRIBUTES(STYLE = "" )

        COMMAND "exit" "Exit System"
            IF confirm_exit() THEN
                EXIT MENU
            END IF
    END MENU
END FUNCTION

-- open debtors menu
FUNCTION debtors()
    CALL dl100_mast.open_debtors()
END FUNCTION

FUNCTION launch_child_window(module_name STRING)
    DISPLAY module_name
END FUNCTION

FUNCTION confirm_exit()
    DISPLAY "Exiting..."
    RETURN 1
END FUNCTION
