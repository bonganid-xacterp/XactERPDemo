-- ==============================================================
-- Program   : main_shell.4gl
-- Purpose   : MDI window manager for XACT ERP
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoappdb

CONSTANT MDI_CONTAINER = "main_shell"
CONSTANT WINDOW_PREFIX = "w_"

DEFINE m_open_modules DYNAMIC ARRAY OF RECORD
    prog    STRING,   -- logical module name (e.g. "st101_mast")
    winname STRING,   -- window name (e.g. "w_st101_mast_1")
    title   STRING,   -- window title
    opened  DATETIME YEAR TO SECOND
END RECORD

DEFINE m_debug_mode SMALLINT

-- ==============================================================
-- Launch or focus a child window
-- Returns: window name if opened, NULL if only focused or error
-- ==============================================================
FUNCTION launch_child_window(formname STRING, wintitle STRING) RETURNS STRING
    DEFINE i INTEGER
    DEFINE winname STRING
    DEFINE w ui.Window

    IF formname IS NULL OR formname.getLength() = 0 THEN
        RETURN NULL
    END IF

    -- If already open, just bring to front and return NULL
    FOR i = 1 TO m_open_modules.getLength()
        IF m_open_modules[i].prog = formname THEN
            CALL bring_window_to_front(m_open_modules[i].winname)
            RETURN NULL
        END IF
    END FOR

    -- Build a unique window name
    LET winname = WINDOW_PREFIX || formname || "_" || (m_open_modules.getLength() + 1)

    TRY
        CALL ui.Interface.setName(winname)
        CALL ui.Interface.setType("child")
        CALL ui.Interface.setContainer(MDI_CONTAINER)

        OPEN WINDOW winname WITH FORM formname
            ATTRIBUTES(TEXT = wintitle, STYLE = "Window.child")

        LET w = ui.Window.forName(winname)
        IF w IS NULL THEN
            CALL utils_globals.show_sql_error(SQLERRMESSAGE)
        END IF

        -- Register window
        LET i = m_open_modules.getLength() + 1
        LET m_open_modules[i].prog    = formname
        LET m_open_modules[i].winname = winname
        LET m_open_modules[i].title   = wintitle
        LET m_open_modules[i].opened  = CURRENT

        IF m_debug_mode THEN
            DISPLAY "Opened window:", winname, "for module:", formname
        END IF

    CATCH
        CALL utils_globals.show_error("Unable to open form: " || formname)
        RETURN NULL
    END TRY

    RETURN winname
END FUNCTION

-- ==============================================================
-- Close child window by module name
-- ==============================================================
FUNCTION close_child_window(formname STRING) RETURNS BOOLEAN
    DEFINE i INTEGER
    DEFINE winname STRING
    DEFINE w ui.Window

    IF formname IS NULL OR formname.getLength() = 0 THEN
        RETURN FALSE
    END IF

    FOR i = 1 TO m_open_modules.getLength()
        IF m_open_modules[i].prog = formname THEN
            LET winname = m_open_modules[i].winname
            LET w = ui.Window.forName(winname)

            IF w IS NOT NULL THEN
                CLOSE WINDOW winname
            END IF

            CALL m_open_modules.deleteElement(i)

            IF m_debug_mode THEN
                DISPLAY "Closed & deregistered window:", winname
            END IF

            RETURN TRUE
        END IF
    END FOR

    RETURN FALSE
END FUNCTION

-- ==============================================================
-- Close the currently active child window
-- ==============================================================
FUNCTION close_current_child_window()
    DEFINE w ui.Window
    DEFINE winname STRING
    DEFINE i INTEGER

    LET w = ui.Window.getCurrent()

    IF w IS NULL THEN
        CALL utils_globals.show_info("No active window.")
        RETURN
    END IF

    LET winname = ui.Interface.getName()

    -- Protect MDI parent window
    IF winname = "w_main" THEN
        CALL utils_globals.show_info("Cannot close main window.")
        RETURN
    END IF

    TRY
        CLOSE WINDOW winname
    CATCH
        CALL utils_globals.show_error("Unable to close window: " || winname)
        RETURN
    END TRY

    -- Remove from registry
    FOR i = m_open_modules.getLength() TO 1 STEP -1
        IF m_open_modules[i].winname = winname THEN
            CALL m_open_modules.deleteElement(i)
            EXIT FOR
        END IF
    END FOR
END FUNCTION

-- ==============================================================
-- Close all child windows
-- ==============================================================
FUNCTION close_all_child_windows()
    DEFINE i INTEGER
    DEFINE winname STRING
    DEFINE w ui.Window

    FOR i = m_open_modules.getLength() TO 1 STEP -1
        LET winname = m_open_modules[i].winname
        LET w = ui.Window.forName(winname)

        IF w IS NOT NULL THEN
            TRY
                CLOSE WINDOW winname
            CATCH
                DISPLAY "Warning: Failed to close ", winname
            END TRY
        END IF
    END FOR

    CALL m_open_modules.clear()
END FUNCTION

-- ==============================================================
-- Bring a window to front (simple refresh)
-- ==============================================================
PRIVATE FUNCTION bring_window_to_front(winname STRING)
    DEFINE w ui.Window
    LET w = ui.Window.forName(winname)
    IF w IS NOT NULL THEN
        TRY
            CALL ui.Interface.refresh()
        CATCH
            DISPLAY "Warning: Could not refresh window: ", winname
        END TRY
    END IF
END FUNCTION

-- ==============================================================
-- Queries
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
-- Queries
-- ==============================================================
FUNCTION get_open_window_count() RETURNS INTEGER
    RETURN m_open_modules.getLength()
END FUNCTION

-- ==============================================================
-- Queries
-- ==============================================================
FUNCTION get_open_window_list() RETURNS STRING
    DEFINE i INTEGER
    DEFINE list STRING

    IF m_open_modules.getLength() = 0 THEN
        RETURN "No windows open."
    END IF

    LET list = "Open Windows (" || m_open_modules.getLength() || "):\n"

    FOR i = 1 TO m_open_modules.getLength()
        LET list = list || i || ". "
                     || m_open_modules[i].title
                     || " (" || m_open_modules[i].prog || ")\n"
    END FOR

    RETURN list
END FUNCTION

-- ==============================================================
-- Queries
-- ==============================================================
FUNCTION cleanup_stale_windows()
    DEFINE i INTEGER
    DEFINE w ui.Window

    FOR i = m_open_modules.getLength() TO 1 STEP -1
        LET w = ui.Window.forName(m_open_modules[i].winname)
        IF w IS NULL THEN
            CALL m_open_modules.deleteElement(i)
        END IF
    END FOR
END FUNCTION

-- ==============================================================
-- Queries
-- ==============================================================
FUNCTION shell_set_debug_mode(p_enabled SMALLINT)
    LET m_debug_mode = p_enabled
    IF m_debug_mode THEN
        DISPLAY "Debug mode enabled for main_shell."
    END IF
END FUNCTION

-- ==============================================================
-- Queries
-- ==============================================================
FUNCTION show_window_manager()
    DEFINE window_list STRING
    LET window_list = get_open_window_list()
    CALL utils_globals.show_info(window_list)
END FUNCTION
