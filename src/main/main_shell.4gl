
IMPORT FGL sy920_ui_utils

FUNCTION main_application_menu()

    -- Set page title (top bar, if defined in form)
    CALL sy920_ui_utils.set_page_title("Dashboard")

    
    DISPLAY 'ver 1.0'
--    
--    MENU "Main Menu"
--
--        COMMAND "exit" "Exit System"
--            IF confirm_exit() THEN
--                EXIT MENU
--            END IF
--    END MENU
END FUNCTION


FUNCTION launch_child_window(module_name STRING)
    DISPLAY module_name
END FUNCTION

FUNCTION confirm_exit()
    DISPLAY "Exiting..."
    RETURN 1
END FUNCTION 
