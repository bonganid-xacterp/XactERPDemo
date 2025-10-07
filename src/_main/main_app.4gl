-- ==============================================================
-- Program   : main_app.4gl
-- Purpose   : Starting point of the XACT ERP System
--              - Initializes environment and database
--              - Handles user login (with retry)
--              - Opens the main application window (MDI)
-- Module    : Main
-- Author    : Bongani Dlamini
-- Version   : Genero BDL 3.20.10
-- ==============================================================


-- ==============================================================
-- IMPORTS
-- These bring in other modules and utilities
-- ==============================================================

IMPORT os
IMPORT ui
IMPORT security          -- Optional: password encryption support
IMPORT util              -- General utilities (date, crypto, etc.)

IMPORT FGL sy100_login   -- Handles user login logic
IMPORT FGL utils_globals -- Common UI helper functions
IMPORT FGL utils_db      -- Database connection helpers
IMPORT FGL main_shell    -- The main application form
IMPORT FGL main_menu     -- The application’s menu system


-- ==============================================================
-- CONFIGURATION CONSTANTS
-- ==============================================================

CONSTANT APP_NAME        = "XACT ERP System"
CONSTANT APP_VERSION     = "1.0.0"
CONSTANT STYLE_FILE      = "main_styles.4st"         -- Style sheet file
CONSTANT MAIN_FORM       = "main_shell"              -- Main form name
CONSTANT MAIN_WINDOW     = "w_main"                  -- Window name
CONSTANT MAX_LOGIN_ATTEMPTS = 3                      -- Allowed retries


-- ==============================================================
-- GLOBAL VARIABLES
-- ==============================================================

DEFINE g_user_authenticated SMALLINT   -- Tracks if the user is logged in
DEFINE g_debug_mode SMALLINT           -- Enables debug messages


-- ==============================================================
-- MAIN ENTRY POINT
-- ==============================================================

MAIN
    -- Disable Ctrl+C to prevent crashing
    DEFER INTERRUPT

    -- Optional: Hide the default screen window
    CALL utils_globals.hide_screen()

    -- Enable debug mode (set to FALSE in production)
    LET g_debug_mode = TRUE

    -- Step 1: Initialize the application (styles, database, etc.)
    IF NOT initialize_application() THEN
        CALL utils_globals.show_error(
            "Initialization failed! Please contact your system administrator.")
        EXIT PROGRAM 1
    END IF

    -- Step 2: Run login process (allows up to 3 attempts)
    IF run_login_with_retry() THEN
        CALL open_main_container()
    ELSE
        CALL utils_globals.show_alert("Login failed or cancelled.", "System")
    END IF

    -- Step 3: Perform cleanup on exit
    CALL cleanup_application()

END MAIN


-- ==============================================================
-- FUNCTION: initialize_application
-- Purpose : Load styles, connect to database, set flags
-- ==============================================================

FUNCTION initialize_application() RETURNS SMALLINT
    DEFINE db_result SMALLINT

    TRY
        -- Load application stylesheet
        IF NOT utils_globals.load_ui_styles("main_styles.4st") THEN
            DISPLAY "?  UI Style file not loaded — using default theme."
        END IF
    
        IF g_debug_mode THEN
            DISPLAY "Loaded style file: ", STYLE_FILE
        END IF

        -- Initialize database connection
        LET db_result = utils_db.initialize_database()
        IF NOT db_result THEN
            CALL utils_globals.show_error("Database initialization failed.")
            RETURN FALSE
        END IF

        -- Initialize global variables
        LET g_user_authenticated = FALSE

        IF g_debug_mode THEN
            DISPLAY "Application initialized successfully (v", APP_VERSION, ")"
        END IF

        RETURN TRUE

    CATCH
        DISPLAY "Error during initialization: ", STATUS
        RETURN FALSE
    END TRY

END FUNCTION


-- ==============================================================
-- FUNCTION: run_login_with_retry
-- Purpose : Allow up to 3 login attempts before exit
-- ==============================================================

FUNCTION run_login_with_retry() RETURNS SMALLINT
    DEFINE login_result SMALLINT
    DEFINE retry_count SMALLINT
    DEFINE username STRING

    LET retry_count = 0

    WHILE retry_count < MAX_LOGIN_ATTEMPTS
        -- Show login screen
        LET login_result = sy100_login.login_user()

        IF login_result THEN
            LET g_user_authenticated = TRUE
            LET username = sy100_login.get_current_user()

            IF g_debug_mode THEN
                DISPLAY "User logged in: ", username
            END IF

            RETURN TRUE
        ELSE
            LET retry_count = retry_count + 1

            IF retry_count < MAX_LOGIN_ATTEMPTS THEN
                CALL utils_globals.show_alert(
                    "Login failed. Attempt " || retry_count || 
                    " of " || MAX_LOGIN_ATTEMPTS, "Login Error")
            END IF
        END IF
    END WHILE

    CALL utils_globals.show_error(
        "Too many failed login attempts. The system will now exit.")
    RETURN FALSE

END FUNCTION


-- ==============================================================
-- FUNCTION: open_main_container
-- Purpose : Opens main MDI window and menu after login
-- ==============================================================

FUNCTION open_main_container()
    DEFINE username STRING

    TRY
        LET username = sy100_login.get_current_user()

        -- Open main MDI window
        OPEN WINDOW w_main WITH FORM "main_shell"
            ATTRIBUTES(STYLE="mdi", TEXT=APP_NAME || " - " || username)

        -- Update dashboard title (if your form supports it)
        CALL utils_globals.set_page_title("Welcome, " || username)


        -- Load main application menu
        CALL main_menu.main_application_menu()

        -- Close main window after exiting menu
        CLOSE WINDOW w_main

        IF g_debug_mode THEN
            DISPLAY "Main window closed."
        END IF

    CATCH
        CALL utils_globals.show_error("Error opening main container: " || STATUS)
        IF ui.Window.getCurrent() IS NOT NULL THEN
            CLOSE WINDOW w_main
        END IF
    END TRY
END FUNCTION


-- ==============================================================
-- FUNCTION: cleanup_application
-- Purpose : Close DB and clear session on exit
-- ==============================================================

FUNCTION cleanup_application()
    TRY
        -- CALL utils_db.close_database()  -- Uncomment if needed
        LET g_user_authenticated = FALSE

        DISPLAY "Application closed for user: ",
            sy100_login.get_current_user()

    CATCH
        DISPLAY "Warning: Cleanup error: ", STATUS
    END TRY
END FUNCTION
