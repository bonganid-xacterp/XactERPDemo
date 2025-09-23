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
IMPORT FGL sy100_login
IMPORT FGL sy900_utils
-- TODO: Need to move the code that can be global to libs
-- DB Connection
-- Persistent user state
-- Error handler
-- Loading State
-- Alert messages

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
    -- Initialize database connection
    -- CALL initialize_database()
    
    -- Set global application settings
    LET g_user_authenticated = FALSE
    
    -- Set application properties
    CALL ui.Interface.setText("XactERP Demo System")
END FUNCTION

# ------------------ LOGIN FLOW -------------------
FUNCTION run_login()
    DEFINE login_result SMALLINT
    
    LET login_result = sy100_login.run_login()
    
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
    
    -- Open main container window
    OPEN WINDOW w_main WITH FORM "main_container"
        ATTRIBUTE (STYLE="dialog", TEXT="XactERP Main System")
    
    -- Set page title
    CALL set_page_title("Dashboard")
    
    -- Main application loop
    CALL main_menu()
    
    CLOSE WINDOW w_main
    
    -- Restore interrupt flag
    LET int_flag = int_flag_saved
END FUNCTION

# ------------------ MAIN MENU -------------------
FUNCTION main_menu()
    MENU "Main Menu"
        COMMAND "Dashboard"
            -- TODO: Open dashboard
            MESSAGE "Dashboard selected"
            
        COMMAND "Exit"
            EXIT MENU
            
        ON INTERRUPT
            IF confirm_exit() THEN
                EXIT MENU
            END IF
            
    END MENU
END FUNCTION

# ------------------ UTILITY FUNCTIONS -------------------
FUNCTION set_page_title(title STRING)
    CALL ui.Interface.setText(title)
END FUNCTION

FUNCTION confirm_exit()
    DEFINE result SMALLINT
    
    MENU "Confirm Exit" ATTRIBUTE(STYLE="dialog", COMMENT="Are you sure you want to exit?")
        COMMAND "Yes"
            LET result = TRUE
            EXIT MENU
        COMMAND "No"
            LET result = FALSE
            EXIT MENU
    END MENU
    
    RETURN result
END FUNCTION

FUNCTION cleanup_application()
    -- Close database connections
    -- Save user preferences
    -- Clean up temporary resources
    DISPLAY "Application shutdown complete"
END FUNCTION