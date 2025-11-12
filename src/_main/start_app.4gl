-- ==============================================================
-- Program   : start_app.4gl
-- Purpose   : Simple MDI Container for XactERP
-- Author    : Bongani Dlamini
-- Version   : Genero 3.20.10
-- Description: Simple MDI parent window that loads child modules
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL sy100_login
IMPORT FGL sy104_user_pwd

-- Module imports for direct execution
IMPORT FGL st101_mast
IMPORT FGL st102_cat
IMPORT FGL wh101_mast
IMPORT FGL wb101_mast
IMPORT FGL cl101_mast
IMPORT FGL dl101_mast
IMPORT FGL sy101_user

SCHEMA demoappdb

CONSTANT APP_NAME = "XACT ERP System"
CONSTANT MAX_LOGIN_ATTEMPTS = 3

GLOBALS
    DEFINE g_user_authenticated SMALLINT
    DEFINE g_current_username STRING
    DEFINE g_login_time DATETIME YEAR TO SECOND
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

    -- Open MDI container and show menu
    CALL open_mdi_container()

    -- Cleanup
    CALL cleanup_application()
END MAIN


-- ==============================================================
-- LOGIN LOGIC
-- ==============================================================
FUNCTION run_login_with_retry() RETURNS SMALLINT
    DEFINE result, attempts SMALLINT
    DEFINE username STRING
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
                "Invalid credentials (" || attempts || "/" || MAX_LOGIN_ATTEMPTS || "). Try again.")
        END IF
    END WHILE

    CALL utils_globals.show_error("Maximum login attempts exceeded. Application will close.")
    RETURN FALSE
END FUNCTION


-- ==============================================================
-- OPEN MDI CONTAINER
-- ==============================================================
FUNCTION open_mdi_container()
    -- Open MDI parent window with tabbed container
    OPEN WINDOW w_mdi WITH FORM "main_shell"
        ATTRIBUTES(TEXT = APP_NAME || " - " || g_current_username,
                   STYLE = "Window.w_main")

    -- Show main menu (top menu bar)
    CALL show_main_menu()

    CLOSE WINDOW w_mdi
END FUNCTION

-- ==============================================================
-- MAIN MENU (Top Menu Bar)
-- ==============================================================
FUNCTION show_main_menu()
    MENU "Main Menu"

        -- Stock Module
        COMMAND "Stocks"
            CALL launch_child_module("st101_mast", "Stock Master")

        COMMAND "Stock Categories"
            CALL launch_child_module("st102_cat", "Stock Categories")

        -- Warehouse Module
        COMMAND "Warehouses"
            CALL launch_child_module("wh101_mast", "Warehouse Master")

        COMMAND "Warehouse Bins"
            CALL launch_child_module("wb101_mast", "Warehouse Bins")

        -- Customers & Suppliers
        COMMAND "Customers"
            CALL launch_child_module("dl101_mast", "Customer Master")

        COMMAND "Suppliers"
            CALL launch_child_module("cl101_mast", "Supplier Master")

        -- System
        COMMAND "Users"
            CALL launch_child_module("sy101_user", "User Management")

        COMMAND "Change Password"
            CALL change_password()

        COMMAND "About"
            CALL show_about_dialog()

        COMMAND "Exit"
            IF confirm_exit() THEN
                EXIT MENU
            END IF

    END MENU
END FUNCTION

-- ==============================================================
-- LAUNCH CHILD MODULE (as tabbed window in MDI container)
-- ==============================================================
FUNCTION launch_child_module(module_name STRING, title STRING)
    DEFINE win_name STRING

    -- Generate unique window name
    LET win_name = "w_" || module_name

    -- Open child window as tab (without immediate CLOSE)
    CASE module_name
        WHEN "st101_mast"
            OPEN WINDOW w_st101 WITH FORM "st101_mast"
                ATTRIBUTES(TEXT = title)
            -- Module runs in its own window/tab

        WHEN "st102_cat"
            OPEN WINDOW w_st102 WITH FORM "st102_cat"
                ATTRIBUTES(TEXT = title)

        WHEN "wh101_mast"
            OPEN WINDOW w_wh101 WITH FORM "wh101_mast"
                ATTRIBUTES(TEXT = title)

        WHEN "wb101_mast"
            OPEN WINDOW w_wb101 WITH FORM "wb101_mast"
                ATTRIBUTES(TEXT = title)

        WHEN "dl101_mast"
            OPEN WINDOW w_dl101 WITH FORM "dl101_mast"
                ATTRIBUTES(TEXT = title)

        WHEN "cl101_mast"
            OPEN WINDOW w_cl101 WITH FORM "cl101_mast"
                ATTRIBUTES(TEXT = title)

        WHEN "sy101_user"
            OPEN WINDOW w_sy101 WITH FORM "sy101_user"
                ATTRIBUTES(TEXT = title)

        OTHERWISE
            CALL utils_globals.show_error("Module not implemented: " || module_name)
    END CASE
END FUNCTION

-- ==============================================================
-- HELPER FUNCTIONS
-- ==============================================================
FUNCTION change_password()
    DEFINE result SMALLINT
    LET result = sy104_user_pwd.change_password(g_current_username)
    IF result THEN
        CALL utils_globals.show_info("Password changed successfully.")
    END IF
END FUNCTION

FUNCTION show_about_dialog()
    DEFINE about_text STRING
    LET about_text = APP_NAME || "\n" ||
                    "Version: 1.0\n" ||
                    "User: " || g_current_username || "\n" ||
                    "Login Time: " || g_login_time USING "DD/MM/YYYY HH:MM:SS" || "\n\n" ||
                    "(c) 2025 XactERP Solutions"

    CALL utils_globals.show_info(about_text)
END FUNCTION

FUNCTION confirm_exit() RETURNS SMALLINT
    RETURN utils_globals.show_confirm("Are you sure you want to exit?", "Confirm Exit")
END FUNCTION

-- ==============================================================
-- CLEANUP
-- ==============================================================
FUNCTION cleanup_application()
    LET g_user_authenticated = FALSE
    LET g_current_username = NULL
    LET g_login_time = NULL
END FUNCTION