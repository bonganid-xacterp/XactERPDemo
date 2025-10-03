-- ==============================================================
-- Program   :   main_shell.4gl
-- Purpose   :   Centralized MDI container with child window mgmt
-- Module    :   Main
-- Number    :
-- Author    :   Bongani Dlamini
-- Version   :   Genero BDL 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL fgldialog
IMPORT FGL utils_globals

SCHEMA xactapp_db

-- ==============================================================
-- CONFIGURATION CONSTANTS
-- ==============================================================
CONSTANT MDI_CONTAINER = "mdi_wrapper"
CONSTANT WINDOW_PREFIX = "w_"

-- ==============================================================
-- MODULE VARIABLES
-- ==============================================================

-- Track open child windows
DEFINE g_open_modules DYNAMIC ARRAY OF RECORD
    prog STRING,          -- Form/program name
    winname STRING,       -- Window identifier
    title STRING,         -- Window title
    opened DATETIME YEAR TO SECOND  -- When opened
END RECORD

DEFINE g_debug_mode SMALLINT

-- ==============================================================
-- Function: launch_child_window
-- Purpose:  Open child window with duplicate prevention
-- Parameters:
--   formname - Form file name (without .42f extension)
--   wintitle - Window title to display
-- Returns:  TRUE if window opened, FALSE if already open or error
-- ==============================================================
PUBLIC FUNCTION launch_child_window(formname STRING, wintitle STRING) 
    RETURNS SMALLINT
    DEFINE i INTEGER
    DEFINE winname STRING
    DEFINE existing_win ui.Window
    
    -- Validate parameters
    IF formname IS NULL OR formname = "" THEN
        CALL utils_globals.show_error("Invalid form name provided")
        -- TODO: Log invalid form name
        RETURN FALSE
    END IF
    
    IF wintitle IS NULL OR wintitle = "" THEN
        LET wintitle = formname  -- Use form name as title
    END IF
    
    -- Check if already open
    FOR i = 1 TO g_open_modules.getLength()
        IF g_open_modules[i].prog = formname THEN
            CALL utils_globals.show_info(
                wintitle || " is already open!")
            
            -- Bring existing window to front
            CALL bring_window_to_front(g_open_modules[i].winname)
            
            -- TODO: Log duplicate window attempt
            RETURN FALSE
        END IF
    END FOR
    
    -- Generate unique window name
    LET winname = WINDOW_PREFIX || formname || "_" || 
                  g_open_modules.getLength() + 1
    
    TRY
        -- Configure MDI child settings
        CALL ui.Interface.setContainer(MDI_CONTAINER)
        CALL ui.Interface.setType("child")
        
        IF g_debug_mode THEN
            DISPLAY "Opening child window:"
            DISPLAY "  Form: ", formname
            DISPLAY "  Window: ", winname
            DISPLAY "  Title: ", wintitle
        END IF
        
        -- Open child window
        OPEN WINDOW winname WITH FORM formname
            ATTRIBUTES(STYLE = "child", TEXT = wintitle)
        
        -- Verify window opened successfully
        LET existing_win = ui.Window.forName(winname)
        IF existing_win IS NULL THEN
            CALL utils_globals.show_error(
                "Failed to open window: " || wintitle)
            -- TODO: Log window open failure
            RETURN FALSE
        END IF
        
        -- Add to registry
        LET i = g_open_modules.getLength() + 1
        LET g_open_modules[i].prog = formname
        LET g_open_modules[i].winname = winname
        LET g_open_modules[i].title = wintitle
        LET g_open_modules[i].opened = CURRENT
        
        IF g_debug_mode THEN
            DISPLAY "Window registered: ", winname
            DISPLAY "Total open windows: ", g_open_modules.getLength()
        END IF
        
        -- TODO: Log window opened
        RETURN TRUE
        
    CATCH
        CALL utils_globals.show_error(
            "Error opening " || wintitle || ":\n" || STATUS)
        -- TODO: Log window open exception
        RETURN FALSE
    END TRY
    
END FUNCTION

-- ==============================================================
-- Function: close_child_window
-- Purpose:  Close child window and remove from registry
-- Parameters: formname - Form name to close
-- Returns:  TRUE if closed, FALSE if not found
-- ==============================================================
PUBLIC FUNCTION close_child_window(formname STRING) RETURNS SMALLINT
    DEFINE i INTEGER
    DEFINE winname STRING
    DEFINE w ui.Window
    
    IF formname IS NULL OR formname = "" THEN
        RETURN FALSE
    END IF
    
    -- Find in registry
    FOR i = 1 TO g_open_modules.getLength()
        IF g_open_modules[i].prog = formname THEN
            LET winname = g_open_modules[i].winname
            
            -- Close the window if still open
            LET w = ui.Window.forName(winname)
            IF w IS NOT NULL THEN
                CLOSE WINDOW winname
                IF g_debug_mode THEN
                    DISPLAY "Window closed: ", winname
                END IF
            END IF
            
            -- Remove from registry
            CALL g_open_modules.deleteElement(i)
            
            IF g_debug_mode THEN
                DISPLAY "Window unregistered: ", winname
                DISPLAY "Remaining windows: ", g_open_modules.getLength()
            END IF
            
            -- TODO: Log window closed
            RETURN TRUE
        END IF
    END FOR
    
    -- Not found
    IF g_debug_mode THEN
        DISPLAY "Window not found in registry: ", formname
    END IF
    
    RETURN FALSE
    
END FUNCTION

-- ==============================================================
-- Function: close_all_child_windows
-- Purpose:  Close all open child windows
-- ==============================================================
PUBLIC FUNCTION close_all_child_windows()
    DEFINE i INTEGER
    DEFINE winname STRING
    DEFINE w ui.Window
    DEFINE closed_count INTEGER
    
    LET closed_count = 0
    
    IF g_debug_mode THEN
        DISPLAY "Closing all child windows..."
        DISPLAY "Total open: ", g_open_modules.getLength()
    END IF
    
    -- Close all windows (iterate backwards to avoid index issues)
    FOR i = g_open_modules.getLength() TO 1 STEP -1
        LET winname = g_open_modules[i].winname
        
        -- Close window if still open
        LET w = ui.Window.forName(winname)
        IF w IS NOT NULL THEN
            TRY
                CLOSE WINDOW winname
                LET closed_count = closed_count + 1
                IF g_debug_mode THEN
                    DISPLAY "Closed: ", winname
                END IF
            CATCH
                DISPLAY "Warning: Failed to close ", winname
            END TRY
        END IF
    END FOR
    
    -- Clear registry
    CALL g_open_modules.clear()
    
    IF g_debug_mode THEN
        DISPLAY "All windows closed. Total: ", closed_count
    END IF
    
    -- TODO: Log all windows closed
    
END FUNCTION

-- ==============================================================
-- Function: bring_window_to_front
-- Purpose:  Bring existing window to front/focus
-- Parameters: winname - Window name to focus
-- ==============================================================
PRIVATE FUNCTION bring_window_to_front(winname STRING)
    DEFINE w ui.Window
    
    LET w = ui.Window.forName(winname)
    
    IF w IS NOT NULL THEN
        TRY
            -- Refresh the interface to update window states
            CALL ui.Interface.refresh()
            
            -- The window is already visible in MDI container
            -- Just acknowledge it exists
            IF g_debug_mode THEN
                DISPLAY "Window already open and visible: ", winname
            END IF
            
        CATCH
            DISPLAY "Warning: Could not access window: ", winname
        END TRY
    END IF
    
END FUNCTION

-- ==============================================================
-- Function: is_window_open
-- Purpose:  Check if a window is already open
-- Parameters: formname - Form name to check
-- Returns:  TRUE if open, FALSE otherwise
-- ==============================================================
PUBLIC FUNCTION is_window_open(formname STRING) RETURNS SMALLINT
    DEFINE i INTEGER
    
    FOR i = 1 TO g_open_modules.getLength()
        IF g_open_modules[i].prog = formname THEN
            RETURN TRUE
        END IF
    END FOR
    
    RETURN FALSE
    
END FUNCTION

-- ==============================================================
-- Function: get_open_window_count
-- Purpose:  Get count of open child windows
-- Returns:  Number of open windows
-- ==============================================================
PUBLIC FUNCTION get_open_window_count() RETURNS INTEGER
    RETURN g_open_modules.getLength()
END FUNCTION

-- ==============================================================
-- Function: get_open_window_list
-- Purpose:  Get list of all open windows
-- Returns:  String with window list
-- ==============================================================
PUBLIC FUNCTION get_open_window_list() RETURNS STRING
    DEFINE i INTEGER
    DEFINE list STRING
    
    IF g_open_modules.getLength() = 0 THEN
        RETURN "No windows open"
    END IF
    
    LET list = "Open Windows (" || g_open_modules.getLength() || "):\n"
    
    FOR i = 1 TO g_open_modules.getLength()
        LET list = list || i || ". " || g_open_modules[i].title || 
                   " (" || g_open_modules[i].prog || ")\n"
    END FOR
    
    RETURN list
    
END FUNCTION

-- ==============================================================
-- Function: cleanup_stale_windows
-- Purpose:  Remove registry entries for windows that no longer exist
-- ==============================================================
PUBLIC FUNCTION cleanup_stale_windows()
    DEFINE i INTEGER
    DEFINE w ui.Window
    DEFINE cleaned_count INTEGER
    
    LET cleaned_count = 0
    
    IF g_debug_mode THEN
        DISPLAY "Cleaning up stale window registry entries..."
    END IF
    
    -- Check each registered window (iterate backwards)
    FOR i = g_open_modules.getLength() TO 1 STEP -1
        LET w = ui.Window.forName(g_open_modules[i].winname)
        
        -- If window no longer exists, remove from registry
        IF w IS NULL THEN
            IF g_debug_mode THEN
                DISPLAY "Removing stale entry: ", g_open_modules[i].winname
            END IF
            CALL g_open_modules.deleteElement(i)
            LET cleaned_count = cleaned_count + 1
        END IF
    END FOR
    
    IF g_debug_mode THEN
        DISPLAY "Cleanup complete. Removed: ", cleaned_count
    END IF
    
    -- TODO: Log stale window cleanup
    
END FUNCTION

-- ==============================================================
-- Function: set_debug_mode
-- Purpose:  Enable/disable debug output
-- Parameters: p_enabled - TRUE to enable, FALSE to disable
-- ==============================================================
PUBLIC FUNCTION shell_set_debug_mode(p_enabled SMALLINT)
    LET g_debug_mode = p_enabled
    IF g_debug_mode THEN
        DISPLAY "Debug mode enabled for main_shell"
    END IF
END FUNCTION

-- ==============================================================
-- Function: show_window_manager
-- Purpose:  Display window manager dialog
-- ==============================================================
PUBLIC FUNCTION show_window_manager()
    DEFINE answer STRING
    DEFINE window_list STRING
    
    LET window_list = get_open_window_list()
    
    CALL fgldialog.fgl_winmessage(
        "Window Manager",
        window_list,
        "information")
    
END FUNCTION