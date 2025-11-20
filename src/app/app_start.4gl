-- ==============================================================
-- Program   : app_start.4gl
-- Purpose   : MDI Container Application Launcher
-- Author    : Bongani Dlamini
-- Version   : Genero 3.20.10
-- Description: Alternative MDI parent window for modular application launch
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL sy100_login
IMPORT FGL sy104_user_pwd
IMPORT FGL app_menu

SCHEMA demoappdb

CONSTANT APP_NAME = "XACT ERP Application"
CONSTANT MAX_LOGIN_ATTEMPTS = 3

GLOBALS
    DEFINE g_user_authenticated SMALLINT
    DEFINE g_current_username STRING
    DEFINE g_login_time DATETIME YEAR TO SECOND
    DEFINE g_window_count INTEGER
    DEFINE g_child_windows DYNAMIC ARRAY OF RECORD
        win_name STRING,
        module_name STRING,
        title STRING,
        is_active SMALLINT
    END RECORD
END GLOBALS

MAIN
    -- Initialize application
    IF NOT utils_globals.initialize_application() THEN
        CALL utils_globals.show_error("Application initialization failed.")
        EXIT PROGRAM 1
    END IF

    -- Login
    IF NOT run_login_with_retry() THEN
        CALL utils_globals.show_info("Login cancelled or failed.")
        EXIT PROGRAM
    END IF

    -- Open MDI container
    CALL open_mdi_container()

    -- Cleanup
    CALL cleanup_application()
END MAIN

-- ==============================================================
-- LOGIN LOGIC
-- ==============================================================
FUNCTION run_login_with_retry() RETURNS SMALLINT
    DEFINE result, attempts SMALLINT
    LET attempts = 0

    WHILE attempts < MAX_LOGIN_ATTEMPTS
        LET result = sy100_login.login_user()
        IF result THEN
            LET g_user_authenticated = TRUE
            LET g_current_username = sy100_login.get_current_user()
            LET g_login_time = CURRENT
            RETURN TRUE
        END IF
        LET attempts = attempts + 1
        IF attempts < MAX_LOGIN_ATTEMPTS THEN
            CALL utils_globals.show_warning(
                "Invalid credentials ("
                    || attempts
                    || "/"
                    || MAX_LOGIN_ATTEMPTS
                    || "). Try again.")
        END IF
    END WHILE

    CALL utils_globals.show_error(
        "Maximum login attempts exceeded. Application will close.")
    RETURN FALSE
END FUNCTION

-- ==============================================================
-- OPEN MDI CONTAINER
-- ==============================================================
FUNCTION open_mdi_container()
    DEFINE w ui.Window
    DEFINE f ui.Form

    -- Setup MDI container
    CALL ui.Interface.setContainer('app_shell')
    CALL ui.Interface.setName('app_shell')
    CALL ui.Interface.setType('container')

    -- Open MDI parent window
    OPEN WINDOW w_app_main WITH FORM "app_shell"
        ATTRIBUTES(TEXT = APP_NAME || " - " || g_current_username)

    LET w = ui.Window.getCurrent()
    LET f = w.getForm()

    -- Initialize window registry
    CALL g_child_windows.clear()
    LET g_window_count = 0

    -- Load menu and start main loop
    CALL app_menu.show_main_menu()

    CLOSE WINDOW w_app_main
END FUNCTION

-- ==============================================================
-- LAUNCH CHILD MODULE IN MDI
-- ==============================================================
PUBLIC FUNCTION launch_child_window(module_name STRING, title STRING) RETURNS SMALLINT
    DEFINE win_name STRING
    DEFINE w ui.Window
    DEFINE winname STRING
    DEFINE idx INTEGER

    -- Generate unique window name
    LET g_window_count = g_window_count + 1
    LET win_name = "w_" || module_name || "_" || g_window_count

    -- Check if module already has an active window
    FOR idx = 1 TO g_child_windows.getLength()
        IF g_child_windows[idx].module_name = module_name
           AND g_child_windows[idx].is_active = TRUE THEN
            CALL utils_globals.show_info("Module '" || title || "' is already open.")
            CALL activate_window(g_child_windows[idx].win_name)
            RETURN FALSE
        END IF
    END FOR

    -- Create child window inside MDI container
    TRY
        CALL ui.Interface.setType("child")
        CALL ui.Interface.setName(winname)
        CALL ui.Interface.setContainer("mdi_container")  <!-- ? POINT TO THE ACTUAL CONTAINER -->

        OPEN WINDOW winname WITH FORM formname
            ATTRIBUTES(TEXT = wintitle, STYLE="Window.child")

        -- register window
        LET i = module_name.getLength() + 1
        LET module_name[i].prog = formname
        LET module_name[i].winname = winname
        LET module_name[i].title = wintitle
        LET module_name[i].opened = CURRENT

    CATCH
        CALL utils_globals.show_error("Unable to open: " || formname)
        RETURN NULL
    END TRY

    RETURN winname
END FUNCTION

-- ==============================================================
-- CLOSE CHILD WINDOW
-- ==============================================================
PUBLIC FUNCTION close_child_window(module_name STRING) RETURNS SMALLINT
    DEFINE idx INTEGER
    DEFINE win_name STRING

    -- Find and close the window
    FOR idx = 1 TO g_child_windows.getLength()
        IF g_child_windows[idx].module_name = module_name
           AND g_child_windows[idx].is_active = TRUE THEN
            LET win_name = g_child_windows[idx].win_name
            TRY
                CLOSE WINDOW win_name
                LET g_child_windows[idx].is_active = FALSE
                RETURN TRUE
            CATCH
                CALL utils_globals.show_error(
                    "Unable to close window: " || win_name)
                RETURN FALSE
            END TRY
        END IF
    END FOR

    RETURN FALSE
END FUNCTION

-- ==============================================================
-- CLOSE ALL CHILD WINDOWS
-- ==============================================================
PUBLIC FUNCTION close_all_child_windows()
    DEFINE idx INTEGER
    DEFINE closed_count INTEGER
    DEFINE win_name STRING

    LET closed_count = 0

    FOR idx = 1 TO g_child_windows.getLength()
        IF g_child_windows[idx].is_active = TRUE THEN
            LET win_name = g_child_windows[idx].win_name
            TRY
                CLOSE WINDOW win_name
                LET g_child_windows[idx].is_active = FALSE
                LET closed_count = closed_count + 1
            CATCH
                -- Continue closing other windows
            END TRY
        END IF
    END FOR

    -- Clean up registry
    CALL cleanup_window_registry()
END FUNCTION

-- ==============================================================
-- ACTIVATE WINDOW
-- ==============================================================
FUNCTION activate_window(win_name STRING)
    DEFINE w ui.Window

    TRY
        LET w = ui.Window.forName(win_name)
        IF w IS NOT NULL THEN
            --CALL w.getForm().getNode()
        END IF
    CATCH
        -- Window may already be focused or doesn't exist
    END TRY
END FUNCTION

-- ==============================================================
-- SHOW WINDOW MANAGER
-- ==============================================================
PUBLIC FUNCTION show_window_manager()
    DEFINE arr_active DYNAMIC ARRAY OF RECORD
        win_name STRING,
        title STRING,
        module_name STRING
    END RECORD
    DEFINE idx, active_idx INTEGER
    DEFINE sel_idx INTEGER

    -- Build list of active windows
    LET active_idx = 0
    FOR idx = 1 TO g_child_windows.getLength()
        IF g_child_windows[idx].is_active = TRUE THEN
            LET active_idx = active_idx + 1
            LET arr_active[active_idx].win_name = g_child_windows[idx].win_name
            LET arr_active[active_idx].title = g_child_windows[idx].title
            LET arr_active[active_idx].module_name = g_child_windows[idx].module_name
        END IF
    END FOR

    IF active_idx = 0 THEN
        CALL utils_globals.show_info("No active windows.")
        RETURN
    END IF

    -- Display window list
    OPEN WINDOW w_window_list WITH FORM "utils_lkup_form"
        ATTRIBUTES(TEXT = "Active Windows")

    DISPLAY ARRAY arr_active TO sr_lookup.*
        BEFORE DISPLAY
            CALL DIALOG.setActionHidden("accept", FALSE)
            CALL DIALOG.setActionHidden("cancel", FALSE)

        ON ACTION accept
            LET sel_idx = DIALOG.getCurrentRow("sr_lookup")
            IF sel_idx > 0 THEN
                CALL activate_window(arr_active[sel_idx].win_name)
            END IF
            EXIT DISPLAY

        ON ACTION cancel
            EXIT DISPLAY

        ON ACTION close_window
            LET sel_idx = DIALOG.getCurrentRow("sr_lookup")
            IF sel_idx > 0 THEN
                IF utils_globals.show_confirm(
                    "Close window: " || arr_active[sel_idx].title || "?",
                    "Confirm Close") THEN
                    --CALL close_child_window(arr_active[sel_idx].module_name)
                    CALL arr_active.deleteElement(sel_idx)
                    IF arr_active.getLength() = 0 THEN
                        EXIT DISPLAY
                    END IF
                END IF
            END IF
    END DISPLAY

    CLOSE WINDOW w_window_list
END FUNCTION

-- ==============================================================
-- CLEANUP WINDOW REGISTRY
-- ==============================================================
PUBLIC FUNCTION cleanup_window_registry()
    DEFINE idx INTEGER

    -- Remove inactive window entries
    FOR idx = g_child_windows.getLength() TO 1 STEP -1
        IF g_child_windows[idx].is_active = FALSE THEN
            CALL g_child_windows.deleteElement(idx)
        END IF
    END FOR
END FUNCTION

-- ==============================================================
-- CLEANUP STALE WINDOWS
-- ==============================================================
PUBLIC FUNCTION cleanup_stale_windows()
    DEFINE idx INTEGER
    DEFINE w ui.Window

    -- Check each registered window
    FOR idx = 1 TO g_child_windows.getLength()
        IF g_child_windows[idx].is_active = TRUE THEN
            TRY
                LET w = ui.Window.forName(g_child_windows[idx].win_name)
                IF w IS NULL THEN
                    -- Window is closed but registry wasn't updated
                    LET g_child_windows[idx].is_active = FALSE
                END IF
            CATCH
                LET g_child_windows[idx].is_active = FALSE
            END TRY
        END IF
    END FOR

    CALL cleanup_window_registry()
END FUNCTION

-- ==============================================================
-- GET WINDOW COUNT
-- ==============================================================
PUBLIC FUNCTION get_active_window_count() RETURNS INTEGER
    DEFINE idx, count INTEGER

    LET count = 0
    FOR idx = 1 TO g_child_windows.getLength()
        IF g_child_windows[idx].is_active = TRUE THEN
            LET count = count + 1
        END IF
    END FOR

    RETURN count
END FUNCTION

-- ==============================================================
-- HELPER FUNCTIONS
-- ==============================================================
PUBLIC FUNCTION get_current_user() RETURNS STRING
    RETURN g_current_username
END FUNCTION

PUBLIC FUNCTION get_login_time() RETURNS DATETIME YEAR TO SECOND
    RETURN g_login_time
END FUNCTION

PUBLIC FUNCTION is_authenticated() RETURNS SMALLINT
    RETURN g_user_authenticated
END FUNCTION

-- ==============================================================
-- CLEANUP
-- ==============================================================
FUNCTION cleanup_application()
    CALL close_all_child_windows()
    CALL g_child_windows.clear()
    LET g_user_authenticated = FALSE
    LET g_current_username = NULL
    LET g_login_time = NULL
    LET g_window_count = 0
END FUNCTION
