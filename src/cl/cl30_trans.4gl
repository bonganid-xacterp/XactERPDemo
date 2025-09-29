IMPORT FGL utils_ui

FUNCTION show_cl_trans()

    -- Set page title (top bar, if defined in form)
    CALL utils_ui.set_page_title("Dashboard")

    DISPLAY 'Creditor Transactions'
--
    MENU "Main Menu"

        COMMAND "exit" "Exit System"
            EXIT PROGRAM
    END MENU
END FUNCTION
