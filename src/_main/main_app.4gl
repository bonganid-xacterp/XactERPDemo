# ==============================================================
# Program   :   main_app.4gl
# Purpose   :   App entry point with login + main container
# Module    :   Main
# Number    :   100
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.2.1
# ==============================================================

IMPORT os
IMPORT ui
IMPORT security -- For password hashing (if available)
IMPORT util -- For crypto functions
IMPORT FGL main_auth -- login handling
IMPORT FGL utils_ui -- ui utils
IMPORT FGL utils_db -- db utils
IMPORT FGL main_shell -- application shell

DEFINE g_user_authenticated SMALLINT

MAIN
    -- Prevent CTRL+C interrupt crash
    DEFER INTERRUPT
    -- Close default SCREEN window
    CLOSE WINDOW SCREEN

    -- Initialize application
    CALL initialize_application()

    -- Run login process
    IF run_login() THEN
        -- If login OK, open container
        CALL open_main_container()
    ELSE
        ERROR utils_ui.show_alert("Login failed or cancelled", "System Error")
    END IF

    -- Cleanup before exit
    CALL cleanup_application()
END MAIN

-- INITIALIZATION
FUNCTION initialize_application()
    DEFINE db_result SMALLINT
    LET db_result = utils_db.initialize_database()
END FUNCTION

-- LOGIN FLOW
FUNCTION run_login()
    DEFINE login_result SMALLINT
    LET login_result = main_auth.login_user()

    IF login_result THEN
        LET g_user_authenticated = TRUE
        RETURN TRUE
    ELSE
        RETURN FALSE
    END IF
END FUNCTION

-- MAIN MDI CONTAINER
FUNCTION open_main_container()
    DEFINE int_flag_saved SMALLINT
    LET int_flag_saved = int_flag

    -- Tell Genero this is the MDI wrapper container
    CALL ui.Interface.setName("mdi_wrapper")
    CALL ui.Interface.setType("container")
    CALL ui.Interface.loadStyles("xactapp_style")

    -- Open the main shell form as MDI
    OPEN WINDOW w_main
        WITH
        FORM "main_shell"
        ATTRIBUTES(STYLE = "main", TEXT = "XactERP Demo System")

    -- Set dashboard title with logged-in user
    CALL utils_ui.set_page_title("Dashboard - " || main_auth.get_current_user())

    -- Run top menu
    CALL main_shell.main_application_menu()

    -- Close after menu exit
    CLOSE WINDOW w_main

    -- Restore interrupt flag
    LET int_flag = int_flag_saved
END FUNCTION

-- CLEANUP
FUNCTION cleanup_application()
    DISPLAY "Application shutdown complete"
END FUNCTION
