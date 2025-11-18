-- ==============================================================
-- Program   : main_menu.4gl
-- Purpose   : Main application menu for launching all ERP modules.
--              Supports Parent/Child window management (MDI style).
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
IMPORT FGL main_shell
IMPORT FGL sy100_login

-- Module imports for execution
IMPORT FGL st101_mast
IMPORT FGL st102_cat
IMPORT FGL wh101_mast
IMPORT FGL cl101_mast
IMPORT FGL dl101_mast

-- ==============================================================
-- DATABASE CONTEXT
-- ==============================================================
SCHEMA demoappdb

-- ==============================================================
-- CONFIGURATION CONSTANTS
-- ==============================================================

CONSTANT APP_NAME = "XACT ERP System"
CONSTANT MENU_TIMEOUT_MINUTES = 30 -- Inactivity timeout

-- ==============================================================
-- MODULE VARIABLES
-- ==============================================================

DEFINE m_debug_mode SMALLINT
DEFINE m_last_activity DATETIME YEAR TO SECOND

-- ==============================================================
-- MAIN ENTRY: Application Menu
-- ==============================================================
FUNCTION main_application_menu()
    DEFINE current_user STRING

    -- Get logged-in username
    LET current_user = sy100_login.get_current_user()

    -- Track session start time
    LET m_last_activity = CURRENT

    IF m_debug_mode THEN
        DISPLAY "Main menu started for user: ", current_user
    END IF

    -- ==========================================================
    -- MAIN MENU
    -- ==========================================================
    MENU "XACT ERP - Main Menu"

        BEFORE MENU
            -- Set menu title and permissions
            CALL setup_menu_display(current_user)

            -- ------------------------------------------------------
            -- DEBTORS MODULE
            -- ------------------------------------------------------
        ON ACTION dl_mast
            CALL launch_module("dl101_mast", "Debtors")

        ON ACTION dl_maint
            CALL launch_module("dl101_mast", "Debtors Ageing Report")

            -- ------------------------------------------------------
            -- CREDITORS MODULE
            -- ------------------------------------------------------
        ON ACTION cl_mast
            CALL launch_module("cl101_mast", "Creditors")

        ON ACTION cl_maint
             CALL launch_module("cl101_mast", "Creditors Age Report")

            -- ------------------------------------------------------
            -- STOCK & WAREHOUSE MODULES
            -- ------------------------------------------------------
        ON ACTION st_mast
            CALL launch_module("st101_mast", "Stocks")

        ON ACTION st_maint
            CALL launch_module("st101_mast", "Stock Maintenance")

        ON ACTION st_cat
            CALL launch_module("st102_cat", "Stock Categories")

        ON ACTION wh_mast
            CALL launch_module("wh101_mast", "Warehouses")

        ON ACTION wb_mast
            CALL launch_module("wb101_mast", "Warehouse Bins")
            -- ------------------------------------------------------
            -- GENERAL LEDGER MODULE
            -- ------------------------------------------------------
        ON ACTION gl_maint
             CALL launch_module("gl101_acc", "GL Accounts")

        ON ACTION gl_jnls
             CALL launch_module("gl130_jnls", "Journals")

            -- ------------------------------------------------------
            -- SALES MODULE
            -- ------------------------------------------------------
        ON ACTION sa_qt
             CALL launch_module("sa130_quote", "Sales Quotes")

            ON ACTION sa_ord
             CALL launch_module("sa131_order", "Sales Orders")

        ON ACTION sa_inv
             CALL launch_module("sa132_invoice", "Sales Invoices")
             
           ON ACTION sa_crn
               CALL launch_module("sa133_crn", "Credit Notes")

            -- ------------------------------------------------------
            -- PURCHASES MODULE
            -- ------------------------------------------------------
        ON ACTION pu_po_inv
             CALL launch_module("pu120_enq", "Purchase Orders Enquiry")

        ON ACTION pu_po_maint
             CALL launch_module("pu130_hdr", "Purchase Orders Maintenance")

            -- ------------------------------------------------------
            -- SYSTEM ADMINISTRATION
            -- ------------------------------------------------------
        ON ACTION sy_usr
             CALL launch_module("sy101_user", "Users")

        ON ACTION sy_role
             CALL launch_module("sy102_role", "User Roles")

            -- ------------------------------------------------------
            -- UTILITIES / INFO
            -- ------------------------------------------------------
        ON ACTION window_manager
            CALL show_window_manager()

        ON ACTION about
            CALL show_about_dialog()

        ON ACTION help
            CALL show_help()

            -- ------------------------------------------------------
            -- EXIT APPLICATION
            -- ------------------------------------------------------
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

    END MENU

    IF m_debug_mode THEN
        DISPLAY "Main menu closed for user: ", current_user
    END IF

END FUNCTION

-- ==============================================================
-- FUNCTION: launch_module
-- Purpose : Open a module inside a child window under the MDI parent
-- ==============================================================

PRIVATE FUNCTION launch_module(formname STRING, title STRING)
    DEFINE current_user STRING

    LET m_last_activity = CURRENT
    LET current_user = sy100_login.get_current_user()

    -- Open module as a new child window (under parent main window)
    IF main_shell.launch_child_window(formname, title) THEN

        -- Execute the module's main function
        TRY
            CALL execute_module(formname)
        CATCH
            CALL utils_globals.show_error(
                "Error executing module: "
                || title
                || "\n\nError: "
                || STATUS)
        END TRY
    ELSE
        CALL utils_globals.show_info("This module is already open.")
    END IF

END FUNCTION

-- ==============================================================
-- FUNCTION: execute_module
-- Purpose : Execute the appropriate module function based on form name
-- ==============================================================

PRIVATE FUNCTION execute_module(formname STRING)
    IF m_debug_mode THEN
        DISPLAY "Executing module: ", formname
    END IF

    CASE formname
        WHEN "dl101_mast"
            CALL dl101_mast.init_dl_module()
        WHEN "cl101_mast"
            CALL cl101_mast.init_cl_module()
        WHEN "st101_mast"
            CALL st101_mast.init_st_module()
        WHEN "wh101_mast"
             CALL wh101_mast.init_wh_module()
            DISPLAY "Stock Enq"
        WHEN "st102_cat"
            CALL st102_cat.init_category_module()
        OTHERWISE
            CALL utils_globals.show_error("Module not implemented: " || formname)
    END CASE

    IF m_debug_mode THEN
        DISPLAY "Module execution completed: ", formname
    END IF
END FUNCTION

-- ==============================================================
-- FUNCTION: setup_menu_display
-- Purpose : Customize menu UI for logged-in user
-- ==============================================================

PRIVATE FUNCTION setup_menu_display(p_username STRING)
    DEFINE d ui.Dialog

    LET d = ui.Dialog.getCurrent()

    IF d IS NOT NULL THEN
        -- Update Exit button text with username
        CALL d.setActionText("main_exit", "Exit (" || p_username || ")")

        -- TODO: hide or disable certain menu items based on permissions
        -- e.g. CALL d.setActionHidden("sy_usr_maint", TRUE)

        IF m_debug_mode THEN
            DISPLAY "Menu configured for user: ", p_username
        END IF
    END IF
END FUNCTION

-- ==============================================================
-- FUNCTION: show_window_manager
-- Purpose : Show list of all open child windows
-- ==============================================================

PRIVATE FUNCTION show_window_manager()
    DEFINE window_list STRING
    DEFINE w_count INTEGER

    LET w_count = main_shell.get_open_window_count()

    IF w_count = 0 THEN
        CALL utils_globals.show_info("No windows are currently open.")
        RETURN
    END IF

    LET window_list = main_shell.get_open_window_list()

    CALL fgldialog.fgl_winmessage(
        "Window Manager", "Open windows:\n\n" || window_list, "information")
END FUNCTION

-- ==============================================================
-- FUNCTION: show_about_dialog
-- Purpose : Show app info and logged-in user
-- ==============================================================

PRIVATE FUNCTION show_about_dialog()
    DEFINE current_user STRING
    DEFINE text STRING

    LET current_user = sy100_login.get_current_user()

    LET text =
        APP_NAME
            || "\nVersion 1.0.0\n\n"
            || "Logged in as: "
            || current_user
            || "\n"
            || "Database: demoappdb\n\n"
            || "(c) 2025 XACT ERP Demo"

    CALL fgldialog.fgl_winmessage("About", text, "information")
END FUNCTION

-- ==============================================================
-- FUNCTION: show_help
-- Purpose : Show quick help guide
-- ==============================================================

PRIVATE FUNCTION show_help()
    DEFINE help_text STRING

    LET help_text =
        "XACT ERP System Help\n\n"
            || "Navigation:\n"
            || "- Use the menu to access modules\n"
            || "- Each module opens in its own child window\n"
            || "- Switch windows via tabs or the Window Manager\n\n"
            || "Shortcuts:\n"
            || "- ESC - Cancel current action\n"
            || "- ENTER - Confirm or next field\n"
            || "- F1 - Context Help"

    CALL fgldialog.fgl_winmessage("Help", help_text, "information")
END FUNCTION

-- ==============================================================
-- FUNCTION: confirm_exit
-- Purpose : Ask user to confirm before quitting
-- ==============================================================

PRIVATE FUNCTION confirm_exit() RETURNS SMALLINT
    DEFINE count INTEGER
    DEFINE answer STRING
    DEFINE msg STRING

    LET count = main_shell.get_open_window_count()

    IF count > 0 THEN
        LET msg =
            "You still have " || count || " open window(s).\n\nExit anyway?"
    ELSE
        LET msg = "Are you sure you want to exit?"
    END IF

    LET answer =
        fgldialog.fgl_winquestion(
            "Confirm Exit", msg, "no", "yes|no", "question", 0)

    RETURN (answer = "yes")
END FUNCTION

-- ==============================================================
-- FUNCTION: cleanup_before_exit
-- Purpose : Close all child windows before exiting
-- ==============================================================

PRIVATE FUNCTION cleanup_before_exit()
    DEFINE current_user STRING
    LET current_user = sy100_login.get_current_user()

    IF m_debug_mode THEN
        DISPLAY "Closing all open child windows..."
    END IF

    CALL main_shell.close_all_child_windows()

    IF m_debug_mode THEN
        DISPLAY "Exit complete for user: ", current_user
    END IF
END FUNCTION

-- ==============================================================
-- FUNCTION: check_session_timeout
-- Purpose : Detect user inactivity
-- ==============================================================

PRIVATE FUNCTION check_session_timeout() RETURNS SMALLINT
    DEFINE now DATETIME YEAR TO SECOND
    DEFINE elapsed INTEGER

    LET now = CURRENT
    LET elapsed = (now - m_last_activity) UNITS MINUTE

    IF elapsed >= MENU_TIMEOUT_MINUTES THEN
        RETURN TRUE
    END IF

    RETURN FALSE
END FUNCTION

-- ==============================================================
-- FUNCTION: menu_set_debug_mode
-- Purpose : Enable/disable debug display
-- ==============================================================

FUNCTION menu_set_debug_mode(p_enabled SMALLINT)
    LET m_debug_mode = p_enabled
    IF m_debug_mode THEN
        DISPLAY "Main menu debug mode enabled"
    END IF
END FUNCTION

-- ==============================================================
-- FUNCTION: check_user_permission
-- Purpose : (Stub) Always returns TRUE until real security is added
-- ==============================================================

PRIVATE FUNCTION check_user_permission(
    p_username STRING, p_permission STRING)
    RETURNS SMALLINT

    IF m_debug_mode THEN
        DISPLAY "Checking permission: ", p_permission, " for user: ", p_username
    END IF

    RETURN TRUE -- Allow all for now
END FUNCTION