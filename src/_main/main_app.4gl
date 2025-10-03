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


-- CONFIGURATION CONSTANTS
CONSTANT MAX_LOGIN_ATTEMPTS = 3
CONSTANT APP_NAME = "XACT ERP System"
CONSTANT APP_VERSION = "1.0.0"
CONSTANT STYLE_FILE = "$FGLDIR/lib/styles/main_styles.4st"
CONSTANT MAIN_FORM = "main_shell"
CONSTANT MAIN_WINDOW = "w_main"
CONSTANT MDI_CONTAINER = "mdi_wrapper"

-- GLOBAL VARIABLES
DEFINE g_user_authenticated SMALLINT
DEFINE g_debug_mode SMALLINT 

-- MAIN ENTRY POINT
MAIN
    -- Prevent CTRL+C interrupt crash
    DEFER INTERRUPT
    
    -- DON'T close SCREEN yet - we need it for error messages
    -- CLOSE WINDOW SCREEN  -- ? Comment this out
    
    -- Enable debug mode (set to FALSE in production)
    LET g_debug_mode = TRUE
    
    -- Initialize application
    IF NOT initialize_application() THEN
        CALL utils_globals.show_error(
            "Application initialization failed!\n\nPlease contact system administrator.")
        -- TODO: Log critical initialization failure
        EXIT PROGRAM 1
    END IF
    
    -- Close SCREEN after successful initialization
    CLOSE WINDOW SCREEN
    
    -- Run login process (with retry logic)
    IF run_login_with_retry() THEN
        -- If login OK, open container
        CALL open_main_container()
    ELSE
        CALL utils_globals.show_alert(
            "Login failed or cancelled", "System")
        -- TODO: Log failed login attempts
    END IF
    
    -- Cleanup before exit
    CALL cleanup_application()
    
END MAIN

-- INITIALIZATION
FUNCTION initialize_application()
    DEFINE db_result SMALLINT
    
    TRY
        -- Load application styles first
        CALL ui.Interface.loadStyles(STYLE_FILE)
        IF g_debug_mode THEN
            DISPLAY "Stylesheet loaded: ", STYLE_FILE
        END IF
        
        -- Set application properties
        CALL ui.Interface.setText(APP_NAME || " v" || APP_VERSION)
        
        -- Initialize database connection
        LET db_result = utils_db.initialize_database()
        
        IF NOT db_result THEN
            CALL utils_globals.show_error(
                "Database initialization failed!")
            -- TODO: Log database connection failure
            RETURN FALSE
        END IF
        
        -- Verify database connection
        --IF NOT utils_db.check_database_connection() THEN
        --    CALL utils_globals.show_error(
        --        "Database connection verification failed!")
        --    -- TODO: Log database verification failure
        --    RETURN FALSE
        --END IF
        
        -- Initialize global variables
        LET g_user_authenticated = FALSE
        
        IF g_debug_mode THEN
            DISPLAY "Application initialized successfully"
            DISPLAY "Version: ", APP_VERSION
            DISPLAY "Database: Connected"
        END IF
        
        -- TODO: Log successful application initialization
        RETURN TRUE
        
    CATCH
        DISPLAY "ERROR: Application initialization failed - ", STATUS
        -- TODO: Log initialization exception
        RETURN FALSE
    END TRY
    
END FUNCTION

-- LOGIN FLOW WITH RETRY
FUNCTION run_login_with_retry()
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
            
            -- TODO: Log successful login (username, timestamp, IP)
            
            -- Verify user authentication in database
            --IF NOT verify_user_authentication(username) THEN
            --    CALL utils_globals.show_error(
            --        "User authentication verification failed!")
            --    -- TODO: Log authentication verification failure
            --    RETURN FALSE
            --END IF
            
            RETURN TRUE
        ELSE
            LET retry_count = retry_count + 1
            
            -- TODO: Log failed login attempt
            
            IF retry_count < MAX_LOGIN_ATTEMPTS THEN
                -- Warn user before final attempt
                IF retry_count = MAX_LOGIN_ATTEMPTS - 1 THEN
                    CALL utils_globals.show_warning(
                        "WARNING: This is your final login attempt!\n\n" ||
                        "Account will be locked after one more failed attempt.")
                ELSE
                    CALL utils_globals.show_alert(
                        "Login failed. Attempt " || retry_count || 
                        " of " || MAX_LOGIN_ATTEMPTS, "Login Error")
                END IF
            END IF
        END IF
    END WHILE
    
    -- Max retries reached
    CALL utils_globals.show_error(
        "Maximum login attempts exceeded.\n\n" ||
        "Application will close for security reasons.")
    
    -- TODO: Log max login attempts exceeded (security event)
    RETURN FALSE
    
END FUNCTION

-- Backward compatibility wrapper
FUNCTION run_login()
    RETURN run_login_with_retry()
END FUNCTION

-- MAIN MDI CONTAINER
-- ==============================================================
-- Function: open_main_container
-- Purpose:  Open and configure main MDI container window
-- ==============================================================
FUNCTION open_main_container()
    DEFINE int_flag_saved SMALLINT
    DEFINE w ui.Window
    DEFINE username STRING
    
    TRY
        -- Save interrupt flag state (preserve user interrupt settings)
        LET int_flag_saved = int_flag
        
        -- Get current username
        LET username = sy100_login.get_current_user()
        
        -- Configure MDI container BEFORE opening window
        CALL ui.Interface.setContainer(MDI_CONTAINER)
        CALL ui.Interface.setName(MDI_CONTAINER)
        CALL ui.Interface.setType("container")
        
        IF g_debug_mode THEN
            DISPLAY "Opening MDI container: ", MDI_CONTAINER
            DISPLAY "Form: ", MAIN_FORM
            DISPLAY "User: ", username
        END IF
        
        -- Open the main shell form as MDI container
        -- Note: Form attributes (STYLE, TEXT) are defined in the .per file
        -- To override, add: ATTRIBUTES(STYLE="main", TEXT="Custom Title")
        OPEN WINDOW w_main WITH FORM MAIN_FORM
        
        -- Get window reference for additional configuration
        LET w = ui.Window.getCurrent()
        
        IF w IS NULL THEN
            CALL utils_globals.show_error(
                "Failed to get window reference!")
            -- TODO: Log window reference failure
            RETURN
        END IF
        
        -- Set dynamic window title with username
        CALL w.setText(APP_NAME || " - " || username)
        
        -- Set dashboard title with logged-in user
        CALL utils_globals.set_page_title(
            "Dashboard - " || username)
        
        -- TODO: Log main container opened
        
        -- Run main application menu
        CALL main_menu.main_application_menu()
        
        -- TODO: Log user exiting application (from menu)
        
        -- Close after menu exit
        IF ui.Window.getCurrent() IS NOT NULL THEN
            CLOSE WINDOW w_main
            IF g_debug_mode THEN
                DISPLAY "Main window closed successfully"
            END IF
        END IF
        
        -- Restore interrupt flag (restore user interrupt settings)
        LET int_flag = int_flag_saved
        
    CATCH
        CALL utils_globals.show_error(
            "Error opening main container: " || STATUS)
        
        -- TODO: Log main container error
        
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
