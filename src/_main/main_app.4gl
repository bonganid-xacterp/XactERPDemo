
-- Program   :   main_app.4gl
-- Purpose   :   App entry point with login + main container
-- Module    :   Main
-- Number    :
-- Author    :   Bongani Dlamini
-- Version   :   Genero BDL 3.20.10

IMPORT os
IMPORT ui
IMPORT security -- For password hashing (if available)
IMPORT util -- For crypto functions
IMPORT FGL sy100_login -- Login handling
IMPORT FGL utils_globals -- UI utilities
IMPORT FGL utils_db -- Database utilities
IMPORT FGL main_shell -- Application shell
IMPORT FGL main_menu -- Application menu

-- GLOBAL VARIABLES

DEFINE g_user_authenticated SMALLINT


-- MAIN ENTRY POINT
MAIN
    -- Prevent CTRL+C interrupt crash
    DEFER INTERRUPT

    -- Close default SCREEN window
    CLOSE WINDOW SCREEN

    -- Initialize application
    IF NOT initialize_application() THEN
        CALL utils_globals.show_alert(
            "Application initialization failed!", "Critical Error")
        EXIT PROGRAM 1
    END IF

    -- Run login process (with retry logic)
    IF run_login_with_retry() THEN
        -- If login OK, open container
        CALL open_main_container()
    ELSE
        CALL utils_globals.show_alert("Login failed or cancelled", "System")
    END IF

    -- Cleanup before exit
    CALL cleanup_application()

END MAIN


-- INITIALIZATION
FUNCTION initialize_application()
    DEFINE db_result SMALLINT
    DEFINE style_loaded SMALLINT

    TRY
        -- Load application styles first
        CALL ui.Interface.loadStyles("main_styles.4st")
        LET style_loaded = TRUE

        -- Set application properties
        CALL ui.Interface.setText("XACT ERP System")

        -- Initialize database connection
        LET db_result = utils_db.initialize_database()

        IF NOT db_result THEN
            CALL utils_globals.show_alert(
                "Database initialization failed!", "Critical Error")
            RETURN FALSE
        END IF

        -- Initialize global variables
        LET g_user_authenticated = FALSE

        DISPLAY "Application initialized successfully"
        RETURN TRUE

    CATCH
        DISPLAY "ERROR: Application initialization failed - ", STATUS
        RETURN FALSE
    END TRY

END FUNCTION


-- LOGIN FLOW WITH RETRY
FUNCTION run_login_with_retry()
    DEFINE login_result SMALLINT
    DEFINE retry_count SMALLINT
    DEFINE max_retries SMALLINT

    LET max_retries = 3
    LET retry_count = 0

    WHILE retry_count < max_retries
        LET login_result = sy100_login.login_user()

        IF login_result THEN
            LET g_user_authenticated = TRUE
            DISPLAY "Login successful for user: ",
                sy100_login.get_current_user()
            RETURN TRUE
        ELSE
            LET retry_count = retry_count + 1

            IF retry_count < max_retries THEN
                CALL utils_globals.show_alert(
                    "Login failed. Attempt "
                        || retry_count
                        || " of "
                        || max_retries,
                    "Login Error")
            END IF
        END IF
    END WHILE

    -- Max retries reached
    CALL utils_globals.show_alert(
        "Maximum login attempts exceeded. Application will close.",
        "Security Alert")
    RETURN FALSE

END FUNCTION

-- Backward compatibility wrapper
FUNCTION run_login()
    RETURN run_login_with_retry()
END FUNCTION


-- MAIN MDI CONTAINER
FUNCTION open_main_container()
    DEFINE int_flag_saved SMALLINT
    DEFINE w ui.Window

    TRY
        -- Save interrupt flag state
        LET int_flag_saved = int_flag

        -- Configure MDI container BEFORE opening window
        CALL ui.Interface.setContainer("mdi_wrapper")
        CALL ui.Interface.setName("mdi_wrapper")
        CALL ui.Interface.setType("container")

        -- Open the main shell form as MDI container
        OPEN WINDOW w_main WITH FORM "main_shell"

        -- Get window reference for additional configuration
        LET w = ui.Window.getCurrent()

        -- Set window properties
        CALL w.setText("XACT ERP - " || sy100_login.get_current_user())

        -- Set dashboard title with logged-in user
        CALL utils_globals.set_page_title(
            "Dashboard - " || sy100_login.get_current_user())

        -- Run main application menu
        CALL main_menu.main_application_menu()

        -- Close after menu exit
        CLOSE WINDOW w_main

        -- Restore interrupt flag
        LET int_flag = int_flag_saved
        DISPLAY "Nansi le flag mfo , asibone yenzeka kanjani" || int_flag

    CATCH
        CALL utils_globals.show_alert(
            "Error opening main container: " || STATUS, "System Error")

        -- Ensure window is closed even on error
        IF ui.Window.getCurrent() IS NOT NULL THEN
            CLOSE WINDOW w_main
        END IF
    END TRY

END FUNCTION


-- CLEANUP AND EXIT
FUNCTION cleanup_application()

    TRY
        -- Close database connection
        # CALL utils_db.close_database()

        -- Clear user session
        LET g_user_authenticated = FALSE

        -- Log application exit
        DISPLAY "Application shutdown complete for user: ",
            sy100_login.get_current_user()

        -- Additional cleanup if needed
        -- CALL close_all_child_windows()
        -- CALL clear_temp_files()

    CATCH
        DISPLAY "Warning: Cleanup encountered errors - ", STATUS
    END TRY

END FUNCTION


-- UTILITY: Emergency Exit Handler (Optional)
FUNCTION emergency_exit(exit_code SMALLINT)

    DISPLAY "EMERGENCY EXIT TRIGGERED - Code: ", exit_code

    -- Force cleanup
    CALL cleanup_application()

    -- Exit with code
    EXIT PROGRAM exit_code

END FUNCTION
