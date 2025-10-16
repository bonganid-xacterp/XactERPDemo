-- ==============================================================
-- Program   : main_shell.4gl
-- Purpose   : Centralized MDI (Multiple Document Interface)
--              container and child window manager.
--              Handles opening, closing, listing, and cleanup
--              of all child forms (modules).
-- Module    : Main
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

-- ==============================================================
-- IMPORTS
-- ==============================================================

IMPORT ui
IMPORT FGL fgldialog
IMPORT FGL utils_globals

-- ==============================================================
-- DATABASE SCHEMA
-- ==============================================================
SCHEMA demoapp_db

-- ==============================================================
-- CONFIGURATION CONSTANTS
-- ==============================================================

CONSTANT MDI_CONTAINER = "mdi_wrapper" -- Name of MDI container form element
CONSTANT WINDOW_PREFIX = "w_" -- Prefix for child window names

-- ==============================================================
-- MODULE VARIABLES
-- ==============================================================

-- Array to track open windows
DEFINE m_open_modules DYNAMIC ARRAY OF RECORD
    prog STRING, -- Program/form name
    winname STRING, -- Window identifier
    title STRING, -- Display title
    opened DATETIME YEAR TO SECOND -- When opened
END RECORD

DEFINE m_debug_mode SMALLINT -- Enables debug output

-- ==============================================================
-- FUNCTION: launch_child_window
-- Purpose : Open a new MDI child window (prevents duplicates)
-- ==============================================================

FUNCTION launch_child_window(formname STRING, wintitle STRING) RETURNS SMALLINT
    DEFINE i INTEGER
    DEFINE winname STRING
    DEFINE existing_win ui.Window

    -- Validate parameters
    IF formname IS NULL THEN
        CALL utils_globals.show_error("Invalid form name provided.")
        RETURN FALSE
    END IF

    IF wintitle IS NULL THEN
        LET wintitle = formname
    END IF

    -- Check if already open
    FOR i = 1 TO m_open_modules.getLength()
        IF m_open_modules[i].prog = formname THEN
            CALL utils_globals.show_info(wintitle || " is already open.")
            CALL bring_window_to_front(m_open_modules[i].winname)
            RETURN FALSE
        END IF
    END FOR

    -- Create unique window name
    LET winname =
        WINDOW_PREFIX || formname || "_" || m_open_modules.getLength() + 1

    TRY
        -- Tell Genero this is an MDI child
        CALL ui.Interface.setContainer(MDI_CONTAINER)
        CALL ui.Interface.setType("child")
        CALL ui.Interface.loadStyles("main_styles.4st")

        IF m_debug_mode THEN
            DISPLAY "Opening child window..."
            DISPLAY "  Form: ", formname
            DISPLAY "  Window: ", winname
            DISPLAY "  Title: ", wintitle
        END IF

        -- Open window as child
        OPEN WINDOW winname
            WITH
            FORM formname
            ATTRIBUTES(STYLE = "child", TEXT = wintitle)

        -- Confirm it opened successfully
        LET existing_win = ui.Window.forName(winname)
        IF existing_win IS NULL THEN
            CALL utils_globals.show_error("Failed to open window: " || wintitle)
            RETURN FALSE
        END IF

        -- Register window in tracking list
        LET i = m_open_modules.getLength() + 1
        LET m_open_modules[i].prog = formname
        LET m_open_modules[i].winname = winname
        LET m_open_modules[i].title = wintitle
        LET m_open_modules[i].opened = CURRENT

        IF m_debug_mode THEN
            DISPLAY "Registered window: ", winname
            DISPLAY "Total open: ", m_open_modules.getLength()
        END IF

        RETURN TRUE

    CATCH
        CALL utils_globals.show_error(
            "Error opening " || wintitle || ":\n" || STATUS)
        RETURN FALSE
    END TRY
END FUNCTION

-- ==============================================================
-- FUNCTION: close_child_window
-- Purpose : Close one specific child window by form name
-- ==============================================================

FUNCTION close_child_window(formname STRING) RETURNS SMALLINT
    DEFINE i INTEGER
    DEFINE winname STRING
    DEFINE w ui.Window

    IF formname IS NULL OR formname = "" THEN
        RETURN FALSE
    END IF

    FOR i = 1 TO m_open_modules.getLength()
        IF m_open_modules[i].prog = formname THEN
            LET winname = m_open_modules[i].winname
            LET w = ui.Window.forName(winname)

            IF w IS NOT NULL THEN
                CLOSE WINDOW winname
                IF m_debug_mode THEN
                    DISPLAY "Closed window: ", winname
                END IF
            END IF

            CALL m_open_modules.deleteElement(i)

            IF m_debug_mode THEN
                DISPLAY "Removed from registry: ", winname
            END IF

            RETURN TRUE
        END IF
    END FOR

    IF m_debug_mode THEN
        DISPLAY "Window not found in registry: ", formname
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
            IF m_debug_mode THEN
                DISPLAY "Window refreshed (front): ", winname
            END IF
        CATCH
            DISPLAY "Warning: Could not refresh window: ", winname
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

    CALL fgldialog.fgl_winmessage("Window Manager", window_list, "information")
END FUNCTION
