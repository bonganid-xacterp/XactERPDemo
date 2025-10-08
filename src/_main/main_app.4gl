-- ==============================================================
-- Program   :   main_app.4gl
-- Purpose   :   Application entry point with login and main MDI container
-- Module    :   Main
-- Number    :
-- Author    :   Bongani Dlamini
-- Version   :   Genero ver 3.20.10
-- ==============================================================

IMPORT os
IMPORT ui
IMPORT security        -- For password hashing (if available)
IMPORT util            -- For crypto functions

IMPORT FGL sy100_login     -- Login handling
IMPORT FGL utils_globals   -- UI utilities
IMPORT FGL utils_db        -- Database utilities
IMPORT FGL main_shell      -- Application shell form
IMPORT FGL main_menu       -- Application menu logic


-- ==============================================================
-- CONFIGURATION CONSTANTS
-- ==============================================================

CONSTANT MAX_LOGIN_ATTEMPTS = 3
CONSTANT APP_NAME     = "XACT ERP System"
CONSTANT APP_VERSION  = "1.0.0"
CONSTANT STYLE_FILE   = "_main/main_styles.4st"  -- Style file (keep in project folder)
CONSTANT MAIN_FORM    = "main_shell"              -- Form file (main_shell.4fd)
CONSTANT MAIN_WINDOW  = "w_main"                  -- Window name


-- ==============================================================
-- GLOBAL VARIABLES
-- ==============================================================

DEFINE g_user_authenticated SMALLINT
DEFINE g_debug_mode SMALLINT

-- ==============================================================
-- MAIN ENTRY POINT
-- ==============================================================

MAIN
    -- Prevent program crash when user presses CTRL+C
    CALL utils_globals.hide_screen()

    -- Enable debug messages (set to FALSE in production)
    LET g_debug_mode = TRUE

    -- Initialize the application environment
    IF NOT initialize_application() THEN
        CALL utils_globals.show_error(
            "Application initialization failed!" ||
            "\n\nPlease contact your system administrator.")
        EXIT PROGRAM 1
    END IF

    -- Run login screen with retry logic
    IF run_login_with_retry() THEN
        -- If login successful, open main MDI container
        CALL open_main_container()
    ELSE
        CALL utils_globals.show_alert("Login failed or cancelled.", "System")
    END IF

    -- Cleanup before exit
    CALL cleanup_application()

END MAIN


-- ==============================================================
-- INITIALIZATION SECTION
-- ==============================================================

FUNCTION initialize_application() RETURNS SMALLINT
    DEFINE db_result SMALLINT

    TRY
        -- Load the visual style for the application
        -- CALL ui.Interface.loadStyles(STYLE_FILE)

        IF g_debug_mode THEN
            DISPLAY "Stylesheet loaded from: ", STYLE_FILE
        END IF

        -- Initialize database connection
        LET db_result = utils_db.initialize_database()

        IF NOT db_result THEN
            CALL utils_globals.show_error("Database initialization failed!")
            RETURN FALSE
        END IF

        -- Initialize global flags
        LET g_user_authenticated = FALSE

        IF g_debug_mode THEN
            DISPLAY "Application initialized successfully"
            DISPLAY "Version: ", APP_VERSION
        END IF

        RETURN TRUE

    CATCH
        DISPLAY "ERROR during initialization: ", STATUS
        RETURN FALSE
    END TRY

END FUNCTION


-- ==============================================================
-- LOGIN FLOW (with retry attempts)
-- ==============================================================

FUNCTION run_login_with_retry() RETURNS SMALLINT
    DEFINE login_result SMALLINT
    DEFINE retry_count SMALLINT
    DEFINE username STRING

    LET retry_count = 0

    WHILE retry_count < MAX_LOGIN_ATTEMPTS
        LET login_result = sy100_login.login_user()

        IF login_result THEN
            LET g_user_authenticated = TRUE
            LET username = sy100_login.get_current_user()

            IF g_debug_mode THEN
                DISPLAY "Login successful for user: ", username
            END IF

            RETURN TRUE
        ELSE
            LET retry_count = retry_count + 1

            IF retry_count < MAX_LOGIN_ATTEMPTS THEN
                IF retry_count = MAX_LOGIN_ATTEMPTS - 1 THEN
                    CALL utils_globals.show_warning(
                        "WARNING: This is your final login attempt!" ||
                        "\n\nAccount will be locked after one more failed attempt.")
                ELSE
                    CALL utils_globals.show_alert(
                        "Login failed. Attempt " || retry_count || " of " || MAX_LOGIN_ATTEMPTS,
                        "Login Error")
                END IF
            END IF
        END IF
    END WHILE

    CALL utils_globals.show_error(
        "Maximum login attempts exceeded.\n\nApplication will close for security reasons.")
    RETURN FALSE

END FUNCTION


-- Simple wrapper to allow backward compatibility
FUNCTION run_login() RETURNS SMALLINT
    RETURN run_login_with_retry()
END FUNCTION


-- ==============================================================
-- MAIN MDI CONTAINER
-- ==============================================================

FUNCTION open_main_container()
    DEFINE w ui.Window
    DEFINE username STRING

    TRY
        LET username = sy100_login.get_current_user()

        IF g_debug_mode THEN
            DISPLAY "Opening main container for user: ", username
        END IF

        -- Open the main MDI window with its form
        -- STYLE="mdi" enables multiple document interface mode
        OPEN WINDOW w_main WITH FORM "main_shell"
            ATTRIBUTES(STYLE="mdi", TEXT=APP_NAME || " - " || username)

        LET w = ui.Window.getCurrent()

        IF w IS NULL THEN
            CALL utils_globals.show_error("Failed to get current window reference.")
            RETURN
        END IF

        -- Set the page title on the dashboard (top area)
        CALL utils_globals.set_page_title("Dashboard - " || username)

        -- Launch the main menu after login
        CALL main_menu.main_application_menu()

        -- After user exits menu, close main window
        IF ui.Window.getCurrent() IS NOT NULL THEN
            CLOSE WINDOW w_main
            IF g_debug_mode THEN
                DISPLAY "Main window closed successfully."
            END IF
        END IF

    CATCH
        CALL utils_globals.show_error("Error opening main container. STATUS: " || STATUS)

        IF ui.Window.getCurrent() IS NOT NULL THEN
            CLOSE WINDOW w_main
        END IF
    END TRY

END FUNCTION


-- ==============================================================
-- CLEANUP AND EXIT
-- ==============================================================

FUNCTION cleanup_application()
    TRY
        -- Close database connections if open
        -- CALL utils_db.close_database()

        -- Clear user session variables
        LET g_user_authenticated = FALSE

        DISPLAY "Application shutdown complete for user: ",
            sy100_login.get_current_user()

    CATCH
        DISPLAY "Warning: Cleanup encountered errors - ", STATUS
    END TRY
END FUNCTION


-- ==============================================================
-- EMERGENCY EXIT HANDLER (Optional utility)
-- ==============================================================

FUNCTION emergency_exit(exit_code SMALLINT)
    DISPLAY "EMERGENCY EXIT TRIGGERED - Code: ", exit_code
    CALL cleanup_application()
    EXIT PROGRAM exit_code
END FUNCTION
