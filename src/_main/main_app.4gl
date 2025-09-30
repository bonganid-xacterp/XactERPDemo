# ==============================================================
# Program   :   sy100_main.4gl
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
IMPORT FGL main_auth
IMPORT FGL utils_ui -- ui utils
IMPORT FGL utils_db -- db utils
IMPORT FGL main_shell -- application shell

-- TODOS: Need to move the code that can be global to libs
-- DB Connection
-- Persistent user state
-- Error handler
-- Loading State
-- Alert messages
-- Look at the after password effect, it triggers some errors

DEFINE g_user_authenticated SMALLINT

MAIN
    DEFER INTERRUPT
    CLOSE WINDOW SCREEN

    -- Initialize application
    CALL initialize_application()

    -- Run login process
    IF run_login() THEN
        -- Login successful, open main container
        CALL open_main_container()
    ELSE
        -- Login failed or cancelled
        DISPLAY "Login failed or cancelled"
    END IF

    -- Cleanup
    CALL cleanup_application()
END MAIN

# ------------------ INITIALIZATION -------------------
FUNCTION initialize_application()

    DEFINE db_result SMALLINT

    -- Initialize database connection
    LET db_result = utils_db.initialize_database()

END FUNCTION

# ------------------ LOGIN FLOW -------------------
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

# ------------------ MAIN CONTAINER ----------------
FUNCTION open_main_container()
    DEFINE int_flag_saved SMALLINT

    -- Save current interrupt flag state
    LET int_flag_saved = int_flag

    -- Open the main application container
    OPEN WINDOW w_main
        WITH
        FORM "main_shell"
        ATTRIBUTE(STYLE = "main", TEXT = "XactERP Main System")

    -- Set page title (top bar, if defined in form)
    CALL utils_ui.set_page_title(
        "Dashboard" || main_auth.get_current_user())

    -- Main loop: keep the container alive with a menu
    CALL main_shell.main_application_menu()

    -- Close window when menu exits
    CLOSE WINDOW w_main

    -- Restore interrupt flag
    LET int_flag = int_flag_saved
END FUNCTION

FUNCTION cleanup_application()
    -- Close database connections
    -- Save user preferences
    -- Clean up temporary resources
    DISPLAY "Application shutdown complete"
END FUNCTION
