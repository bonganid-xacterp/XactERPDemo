-- ==============================================================
-- Program   :   main_menu.4gl
-- Purpose   :   Main application menu with module access
-- Module    :   Main
-- Number    :
-- Author    :   Bongani Dlamini
-- Version   :   Genero BDL 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL fgldialog
IMPORT FGL utils_globals
IMPORT FGL main_shell
IMPORT FGL sy100_login

SCHEMA xactdemo_db

-- ==============================================================
-- CONFIGURATION CONSTANTS
-- ==============================================================
CONSTANT APP_NAME = "XACT ERP System"
CONSTANT MENU_TIMEOUT_MINUTES = 30

-- ==============================================================
-- MODULE VARIABLES
-- ==============================================================
DEFINE g_debug_mode SMALLINT
DEFINE g_last_activity DATETIME YEAR TO SECOND

-- ==============================================================
-- Function: main_application_menu
-- Purpose:  Display main application menu with all modules
-- ==============================================================
PUBLIC FUNCTION main_application_menu()
    DEFINE current_user STRING
    
    -- Get current user
    LET current_user = sy100_login.get_current_user()
    
    -- Initialize activity tracking
    LET g_last_activity = CURRENT
    
    IF g_debug_mode THEN
        DISPLAY "Opening main menu for user: ", current_user
    END IF
    
    -- TODO: Log menu opened
    
    MENU "Main Menu"
        
        -- ==============================================================
        -- DEBTORS MODULE
        -- ==============================================================
        BEFORE MENU
            -- Configure menu display
            CALL setup_menu_display(current_user)
            -- TODO: Check and apply user permissions
        
        ON ACTION dl_enq
            CALL launch_module("dl120_enq", "Debtors Enquiry", "DL_VIEW")
            
        ON ACTION dl_maint
            CALL launch_module("dl101_mast", "Debtors Maintenance", "DL_EDIT")
        
        -- ==============================================================
        -- CREDITORS MODULE
        -- ==============================================================
        ON ACTION cl_enq
            CALL launch_module("cl120_enq", "Creditors Enquiry", "CL_VIEW")
            
        ON ACTION cl_maint
            CALL launch_module("cl101_mast", "Creditors Maintenance", "CL_EDIT")
        
        -- ==============================================================
        -- STOCK MODULE
        -- ==============================================================
        ON ACTION st_enq
            CALL launch_module("st120_enq", "Stock Enquiry", "ST_VIEW")
            
        ON ACTION st_maint
            CALL launch_module("st101_mast", "Stock Maintenance", "ST_EDIT")
        
        -- ==============================================================
        -- GENERAL LEDGER MODULE
        -- ==============================================================
        ON ACTION gl_enq
            CALL launch_module("gl120_enq", "GL Enquiry", "GL_VIEW")
            
        ON ACTION gl_maint
            CALL launch_module("gl101_acc", "GL Maintenance", "GL_EDIT")
        
        -- ==============================================================
        -- SALES MODULE
        -- ==============================================================
        ON ACTION sa_ord_enq
            CALL launch_module("sa120_enq", "Sales Orders Enquiry", "SA_VIEW")
            
        ON ACTION sa_ord_maint
            CALL launch_module("sa130_hdr", "Sales Orders Maintenance", "SA_EDIT")
        
        -- ==============================================================
        -- PURCHASES MODULE
        -- ==============================================================
        ON ACTION pu_po_enq
            CALL launch_module("pu120_enq", "Purchase Orders Enquiry", "PU_VIEW")
            
        ON ACTION pu_po_maint
            CALL launch_module("pu130_hdr", "Purchase Orders Maintenance", "PU_EDIT")
        
        -- ==============================================================
        -- SYSTEM ADMINISTRATION
        -- ==============================================================
        ON ACTION sy_usr_enq
            CALL launch_module("sy120_enq", "Users Enquiry", "SY_VIEW")
            
        ON ACTION sy_usr_maint
            CALL launch_module("sy100_user", "Users Maintenance", "SY_ADMIN")
        
        -- ==============================================================
        -- UTILITIES
        -- ==============================================================
        ON ACTION window_manager
            CALL show_window_manager()
        
        ON ACTION about
            CALL show_about_dialog()
        
        ON ACTION help
            CALL show_help()
        
        -- ==============================================================
        -- EXIT APPLICATION
        -- ==============================================================
        ON ACTION main_exit
            IF confirm_exit() THEN
                CALL cleanup_before_exit()
                EXIT MENU
            END IF
        
        ON ACTION close
            IF confirm_exit() THEN
                CALL cleanup_before_exit()
                EXIT MENU
            END IF
        
        -- ==============================================================
        -- IDLE TIMEOUT (Optional - for session management)
        -- ==============================================================
        --ON IDLE MENU_TIMEOUT_MINUTES * 60  -- Convert minutes to seconds
        --    IF check_session_timeout() THEN
        --        CALL utils_globals.show_warning(
        --            "Your session has timed out due to inactivity.\n\n" ||
        --            "Please log in again.")
        --        -- TODO: Log session timeout
        --        EXIT MENU
        --    END IF
        
    END MENU
    
    IF g_debug_mode THEN
        DISPLAY "Main menu closed"
    END IF
    
    -- TODO: Log menu closed
    
END FUNCTION

-- ==============================================================
-- Function: launch_module
-- Purpose:  Launch module with permission checking
-- Parameters:
--   formname - Form file name
--   title - Window title
--   permission - Required permission code
-- ==============================================================
PRIVATE FUNCTION launch_module(formname STRING, title STRING, 
                               permission STRING)
    DEFINE current_user STRING
    DEFINE has_permission SMALLINT
    
    -- Update activity timestamp
    LET g_last_activity = CURRENT
    
    -- Get current user
    LET current_user = sy100_login.get_current_user()
    
    -- TODO: Check user permissions
    CALL check_user_permission(current_user, permission)
        RETURNING has_permission
    -- 
    IF NOT has_permission THEN
         CALL utils_globals.show_warning(
             "You do not have permission to access:\n" || title)
         RETURN
     END IF
    
    -- Launch the module
    IF main_shell.launch_child_window(formname, title) THEN
        IF g_debug_mode THEN
            DISPLAY "Module launched: ", title, " (", formname, ")"
        END IF
        -- TODO: Log module access (user, module, timestamp)
    ELSE
        IF g_debug_mode THEN
            DISPLAY "Module launch failed or already open: ", formname
        END IF
    END IF
    
END FUNCTION

-- ==============================================================
-- Function: setup_menu_display
-- Purpose:  Configure menu appearance and permissions
-- Parameters: p_username - Current user
-- ==============================================================
PRIVATE FUNCTION setup_menu_display(p_username STRING)
    DEFINE d ui.Dialog
    
    -- Get dialog reference
    LET d = ui.Dialog.getCurrent()
    
    IF d IS NOT NULL THEN
        -- Set menu title with username
        CALL d.setActionText("main_exit", 
            "Exit (" || p_username || ")")
        
        -- TODO: Hide menu items based on permissions
        -- Example:
        -- IF NOT has_permission(p_username, "SY_ADMIN") THEN
        --     CALL d.setActionHidden("sy_usr_maint", TRUE)
        -- END IF
        
        IF g_debug_mode THEN
            DISPLAY "Menu configured for user: ", p_username
        END IF
    END IF
    
END FUNCTION

-- ==============================================================
-- Function: show_window_manager
-- Purpose:  Display list of open windows
-- ==============================================================
PRIVATE FUNCTION show_window_manager()
    DEFINE window_list STRING
    DEFINE open_count INTEGER
    
    LET open_count = main_shell.get_open_window_count()
    
    IF open_count = 0 THEN
        CALL utils_globals.show_info("No windows are currently open.")
        RETURN
    END IF
    
    LET window_list = main_shell.get_open_window_list()
    
    CALL fgldialog.fgl_winmessage(
        "Window Manager",
        window_list,
        "information")
    
    -- TODO: Log window manager accessed
    
END FUNCTION

-- ==============================================================
-- Function: show_about_dialog
-- Purpose:  Display about/version information
-- ==============================================================
PRIVATE FUNCTION show_about_dialog()
    DEFINE about_text STRING
    DEFINE current_user STRING
    
    LET current_user = sy100_login.get_current_user()
    
    LET about_text = APP_NAME || "\n" ||
                     "Version 1.0.0\n\n" ||
                     "Logged in as: " || current_user || "\n" ||
                     "Database: xactdemo_db\n\n" ||
                     "Copyright © 2025\n" ||
                     "All rights reserved."
    
    CALL fgldialog.fgl_winmessage(
        "About " || APP_NAME,
        about_text,
        "information")
    
END FUNCTION

-- ==============================================================
-- Function: show_help
-- Purpose:  Display help information
-- ==============================================================
PRIVATE FUNCTION show_help()
    DEFINE help_text STRING
    
    LET help_text = "XACT ERP System Help\n\n" ||
                    "Navigation:\n" ||
                    "• Use the menu to access different modules\n" ||
                    "• Multiple windows can be open at once\n" ||
                    "• Click on window tabs to switch between forms\n\n" ||
                    "Keyboard Shortcuts:\n" ||
                    "• ESC - Cancel current operation\n" ||
                    "• ENTER - Accept/Proceed\n" ||
                    "• F1 - Context help\n\n" ||
                    "For additional support, contact your system administrator."
    
    CALL fgldialog.fgl_winmessage(
        "Help",
        help_text,
        "information")
    
END FUNCTION

-- ==============================================================
-- Function: confirm_exit
-- Purpose:  Confirm application exit
-- Returns:  TRUE if user confirms, FALSE otherwise
-- ==============================================================
PRIVATE FUNCTION confirm_exit()
    DEFINE open_count INTEGER
    DEFINE answer STRING
    DEFINE message STRING
    
    -- Check for open windows
    LET open_count = main_shell.get_open_window_count()
    
    IF open_count > 0 THEN
        LET message = "You have " || open_count || 
                     " window(s) still open.\n\n" ||
                     "Are you sure you want to exit?"
    ELSE
        LET message = "Are you sure you want to exit?"
    END IF
    
    LET answer = fgldialog.fgl_winquestion(
        "Confirm Exit",
        message,
        "no",
        "yes|no",
        "question",
        0)
    
    IF answer = "yes" THEN
        -- TODO: Log user exit confirmation
        RETURN TRUE
    ELSE
        RETURN FALSE
    END IF
    
END FUNCTION

-- ==============================================================
-- Function: cleanup_before_exit
-- Purpose:  Clean up resources before exiting application
-- ==============================================================
PRIVATE FUNCTION cleanup_before_exit()
    DEFINE current_user STRING
    
    LET current_user = sy100_login.get_current_user()
    
    IF g_debug_mode THEN
        DISPLAY "Cleaning up before exit..."
    END IF
    
    -- Close all open child windows
    CALL main_shell.close_all_child_windows()
    
    IF g_debug_mode THEN
        DISPLAY "All child windows closed"
        DISPLAY "User exiting: ", current_user
    END IF
    
    -- TODO: Log application exit
    -- TODO: Update user session end time
    
END FUNCTION

-- ==============================================================
-- Function: check_session_timeout
-- Purpose:  Check if session has timed out due to inactivity
-- Returns:  TRUE if timed out, FALSE otherwise
-- ==============================================================
PRIVATE FUNCTION check_session_timeout() RETURNS SMALLINT
    DEFINE current_time DATETIME YEAR TO SECOND
    DEFINE elapsed_minutes INTEGER
    
    LET current_time = CURRENT
    LET elapsed_minutes = (current_time - g_last_activity) UNITS MINUTE
    
    IF elapsed_minutes >= MENU_TIMEOUT_MINUTES THEN
        IF g_debug_mode THEN
            DISPLAY "Session timeout detected"
            DISPLAY "Elapsed minutes: ", elapsed_minutes
        END IF
        RETURN TRUE
    END IF
    
    RETURN FALSE
    
END FUNCTION

-- ==============================================================
-- Function: set_debug_mode
-- Purpose:  Enable/disable debug output
-- Parameters: p_enabled - TRUE to enable, FALSE to disable
-- ==============================================================
PUBLIC FUNCTION menu_set_debug_mode(p_enabled SMALLINT)
    LET g_debug_mode = p_enabled
    IF g_debug_mode THEN
        DISPLAY "Debug mode enabled for main_menu"
    END IF
END FUNCTION

-- ==============================================================
-- Function: check_user_permission (Stub for future implementation)
-- Purpose:  Check if user has specific permission
-- Parameters:
--   p_username - Username to check
--   p_permission - Permission code
-- Returns:  TRUE if has permission, FALSE otherwise
-- ==============================================================
PRIVATE FUNCTION check_user_permission(p_username STRING, 
                                       p_permission STRING) 
    RETURNS SMALLINT
    
    -- TODO: Implement actual permission checking
    -- Query database for user permissions
    -- For now, return TRUE (all permissions granted)
    
    IF g_debug_mode THEN
        DISPLAY "Permission check: ", p_permission, " for ", p_username
        DISPLAY "Result: GRANTED (stub implementation)"
    END IF
    
    RETURN TRUE
    
END FUNCTION