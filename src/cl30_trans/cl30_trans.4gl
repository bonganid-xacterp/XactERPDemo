IMPORT FGL sy920_ui_utils

FUNCTION show_cl_trans()

    -- Set page title (top bar, if defined in form)
    CALL sy920_ui_utils.set_page_title("Dashboard")

    DISPLAY 'Creditor Transactions'
--
    MENU "Main Menu"

        COMMAND "exit" "Exit System"
            EXIT PROGRAM
    END MENU
END FUNCTION
