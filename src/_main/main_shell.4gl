-- ==============================================================
-- Program   : main_shell.4gl
-- Purpose   : MDI (Multiple Document Interface) window manager
--             Handles opening, closing, and tracking child windows
-- Module    : Main
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

-- ==============================================================
-- IMPORTS
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

-- ==============================================================
-- DATABASE SCHEMA
-- ==============================================================

SCHEMA demoappdb

-- ==============================================================
-- CONFIGURATION CONSTANTS
-- ==============================================================

CONSTANT MDI_CONTAINER = "main_shell"  -- Must match setContainer() in start_app
CONSTANT WINDOW_PREFIX = "w_"

-- ==============================================================
-- MODULE VARIABLES
-- ==============================================================

DEFINE m_open_modules DYNAMIC ARRAY OF RECORD
    prog STRING,
    winname STRING,
    title STRING,
    opened DATETIME YEAR TO SECOND
END RECORD

DEFINE m_debug_mode SMALLINT

-- ==============================================================
-- FUNCTION: launch_child_window
-- Purpose : Open a new MDI child window (prevents duplicates)
-- Returns : TRUE if window opened, FALSE if already open or error
-- ==============================================================

FUNCTION launch_child_window(formname STRING, wintitle STRING) RETURNS STRING
    DEFINE i INTEGER
    DEFINE winname STRING
    DEFINE child STRING 

    IF formname IS NULL OR formname.getLength() = 0 THEN
        RETURN NULL
    END IF

    -- Already open?
    FOR i = 1 TO m_open_modules.getLength()
        IF m_open_modules[i].prog = formname THEN
            CALL bring_window_to_front(m_open_modules[i].winname)
            RETURN m_open_modules[i].winname
        END IF
    END FOR

    -- Create window name
    LET winname = WINDOW_PREFIX || formname || "_" || (m_open_modules.getLength() + 1)

    TRY
        CALL ui.Interface.setType("child")
        CALL ui.Interface.setContainer(MDI_CONTAINER)

        OPEN WINDOW winname WITH FORM formname
            ATTRIBUTES(TEXT = wintitle, STYLE="Window.child")

        -- register window
        LET i = m_open_modules.getLength() + 1
        LET m_open_modules[i].prog = formname
        LET m_open_modules[i].winname = winname
        LET m_open_modules[i].title = wintitle
        LET m_open_modules[i].opened = CURRENT

    CATCH
        CALL utils_globals.show_error("Unable to open: " || formname)
        RETURN NULL
    END TRY

    RETURN winname
END FUNCTION


-- ==============================================================
-- FUNCTION: close_child_window
-- Purpose : Close specific child window by form name
-- Returns : TRUE if closed, FALSE if not found
-- ==============================================================

FUNCTION close_child_window(formname STRING) RETURNS BOOLEAN
    DEFINE i INTEGER
    DEFINE winname STRING
    DEFINE w ui.Window

    IF formname IS NULL OR formname.getLength() = 0 THEN
        RETURN FALSE
    END IF

    -- Find and close the window
    FOR i = 1 TO m_open_modules.getLength()
        IF m_open_modules[i].prog = formname THEN
            LET winname = m_open_modules[i].winname
            LET w = ui.Window.forName(winname)

            IF w IS NOT NULL THEN
            MENU
                ON ACTION close
                    EXIT MENU
            END MENU
            
                CLOSE WINDOW winname
                IF m_debug_mode THEN
                    DISPLAY "Closed window: ", winname
                END IF
            END IF

            CALL m_open_modules.deleteElement(i)

            IF m_debug_mode THEN
                DISPLAY "Removed from registry: ", formname
            END IF

            RETURN TRUE
        END IF
    END FOR

    IF m_debug_mode THEN
        DISPLAY "Window not found: ", formname
    END IF

    RETURN FALSE

END FUNCTION

-- ==============================================================
-- FUNCTION: close_all_child_windows
-- Purpose : Closes all open MDI child windows (for app exit)
-- ==============================================================

FUNCTION close_all_child_windows()
    DEFINE i INTEGER
    DEFINE winname STRING
    DEFINE w ui.Window
    DEFINE closed_count INTEGER

    LET closed_count = 0

    IF m_debug_mode THEN
        DISPLAY "Closing all child windows..."
    END IF

    -- Loop backwards to avoid shifting indexes
    FOR i = m_open_modules.getLength() TO 1 STEP -1
        LET winname = m_open_modules[i].winname
        LET w = ui.Window.forName(winname)

        IF w IS NOT NULL THEN
            TRY
                CLOSE WINDOW winname
                LET closed_count = closed_count + 1
                IF m_debug_mode THEN
                    DISPLAY "Closed: ", winname
                END IF
            CATCH
                DISPLAY "Warning: Failed to close ", winname
            END TRY
        END IF
    END FOR

    CALL m_open_modules.clear()

    IF m_debug_mode THEN
        DISPLAY "All child windows closed. Total: ", closed_count
    END IF
END FUNCTION

-- ==============================================================
-- FUNCTION: bring_window_to_front
-- Purpose : Refresh/focus an already open child window
-- ==============================================================

PRIVATE FUNCTION bring_window_to_front(winname STRING)
    DEFINE w ui.Window

    LET w = ui.Window.forName(winname)

    IF w IS NOT NULL THEN
        TRY
            CALL ui.Interface.refresh()
        CATCH
            ERROR "Warning: Could not refresh window: ", winname
        END TRY
    END IF
END FUNCTION

-- ==============================================================
-- FUNCTION: is_window_open
-- Purpose : Returns TRUE if the given form is already open
-- ==============================================================

FUNCTION is_window_open(formname STRING) RETURNS SMALLINT
    DEFINE i INTEGER

    FOR i = 1 TO m_open_modules.getLength()
        IF m_open_modules[i].prog = formname THEN
            RETURN TRUE
        END IF
    END FOR

    RETURN FALSE
END FUNCTION

-- ==============================================================
-- FUNCTION: get_open_window_count
-- Purpose : Returns how many child windows are currently open
-- ==============================================================

FUNCTION get_open_window_count() RETURNS INTEGER
    RETURN m_open_modules.getLength()
END FUNCTION

-- ==============================================================
-- FUNCTION: get_open_window_list
-- Purpose : Returns a readable list of all open child windows
-- ==============================================================

FUNCTION get_open_window_list() RETURNS STRING
    DEFINE i INTEGER
    DEFINE list STRING

    IF m_open_modules.getLength() = 0 THEN
        RETURN "No windows open."
    END IF

    LET list = "Open Windows (" || m_open_modules.getLength() || "):\n"

    FOR i = 1 TO m_open_modules.getLength()
        LET list =
            list
                || i
                || ". "
                || m_open_modules[i].title
                || " ("
                || m_open_modules[i].prog
                || ")\n"
    END FOR

    RETURN list
END FUNCTION

-- ==============================================================
-- FUNCTION: cleanup_stale_windows
-- Purpose : Removes any registry entries for closed windows
-- ==============================================================

FUNCTION cleanup_stale_windows()
    DEFINE i INTEGER
    DEFINE w ui.Window
    DEFINE cleaned_count INTEGER

    LET cleaned_count = 0

    IF m_debug_mode THEN
        DISPLAY "Cleaning up stale window entries..."
    END IF

    FOR i = m_open_modules.getLength() TO 1 STEP -1
        LET w = ui.Window.forName(m_open_modules[i].winname)

        IF w IS NULL THEN
            IF m_debug_mode THEN
                DISPLAY "Removing stale entry: ", m_open_modules[i].winname
            END IF
            CALL m_open_modules.deleteElement(i)
            LET cleaned_count = cleaned_count + 1
        END IF
    END FOR

    IF m_debug_mode THEN
        DISPLAY "Cleanup complete. Removed: ", cleaned_count
    END IF
END FUNCTION

-- ==============================================================
-- FUNCTION: shell_set_debug_mode
-- Purpose : Turn debug output on/off
-- ==============================================================

FUNCTION shell_set_debug_mode(p_enabled SMALLINT)
    LET m_debug_mode = p_enabled
    IF m_debug_mode THEN
        DISPLAY "Debug mode enabled for main_shell."
    END IF
END FUNCTION

-- ==============================================================
-- FUNCTION: show_window_manager
-- Purpose : Displays list of open windows in dialog
-- ==============================================================

FUNCTION show_window_manager()
    DEFINE window_list STRING

    LET window_list = get_open_window_list()

    CALL utils_globals.show_info(window_list)
END FUNCTION
