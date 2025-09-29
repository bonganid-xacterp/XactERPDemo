IMPORT FGL sy920_ui_utils
IMPORT FGL dl100_mast

FUNCTION main_application_menu()

    -- Set page title (top bar, if defined in form)
    CALL sy920_ui_utils.set_page_title("Dashboard")

    DISPLAY 'ver 1.0'
--
    MENU "Main Menu" ATTRIBUTES(STYLE = "")
--
        COMMAND "exit" "Exit System"
            IF confirm_exit() THEN
                EXIT MENU
            END IF
    END MENU
END FUNCTION

-- open debtors menu
FUNCTION add_debtors()
    CALL dl100_mast.open_debtors()
END FUNCTION

FUNCTION launch_child_window(module_name STRING)
    DISPLAY module_name
END FUNCTION

FUNCTION confirm_exit()
    DISPLAY "Exiting..."
    RETURN 1
END FUNCTION
