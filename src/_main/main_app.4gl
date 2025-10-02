# ==============================================================
# Program   :   main_app.4gl
# Purpose   :   App entry point with login + main container
# Module    :   Main
# Number    :
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.20.10
# ==============================================================

IMPORT os
IMPORT ui
IMPORT security -- For password hashing (if available)
IMPORT util -- For crypto functions
IMPORT FGL sy100_login -- login handling
IMPORT FGL utils_ui -- ui utils
IMPORT FGL utils_db -- db utils
IMPORT FGL main_shell -- application shell
IMPORT FGL main_menu -- application menu

SCHEMA xactapp_db

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
        CALL utils_ui.show_alert("Login failed or cancelled", "System Error")
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
    LET login_result = sy100_login.login_user()

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
    CALL ui.Interface.setContainer("mdi_wrapper")
    CALL ui.Interface.setName("mdi_wrapper")
    CALL ui.Interface.setType("container")
    CALL ui.Interface.loadStyles("main_styles")

    -- Set action defaults

    -- Open the main shell form as MDI
    OPEN WINDOW w_main WITH FORM "main_shell"

    -- Set dashboard title with logged-in user
    CALL utils_ui.set_page_title(
        "Dashboard - " || sy100_login.get_current_user())

    -- Run top menu
    CALL main_application_menu()

    -- Close after menu exit
    CLOSE WINDOW w_main

    -- Restore interrupt flag
    LET int_flag = int_flag_saved
END FUNCTION

-- CLEANUP
FUNCTION cleanup_application()
    DISPLAY "Application shutdown complete"
END FUNCTION
