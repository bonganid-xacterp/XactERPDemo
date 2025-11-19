-- ==============================================================
-- Program   : start_app.4gl
-- Purpose   : MDI Container for XactERP with Top Menu
-- Author    : Bongani Dlamini
-- Version   : Genero 3.20.10
-- Description: MDI parent window with comprehensive top menu bar
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL sy100_login
IMPORT FGL sy104_user_pwd
IMPORT FGL main_shell

-- Stock Module imports
IMPORT FGL st101_mast
IMPORT FGL st102_cat
IMPORT FGL st103_uom_mast
IMPORT FGL st120_enq
IMPORT FGL st130_trans
IMPORT FGL st140_hist

-- Warehouse Module imports
IMPORT FGL wh101_mast
IMPORT FGL wb101_mast

-- Customer/Supplier imports
IMPORT FGL cl101_mast
IMPORT FGL dl101_mast

-- Purchase Module imports
IMPORT FGL pu130_order
IMPORT FGL pu131_grn
IMPORT FGL pu132_inv
IMPORT FGL pu140_hist

-- Sales Module imports
IMPORT FGL sa130_quote
IMPORT FGL sa131_order
IMPORT FGL sa132_invoice
IMPORT FGL sa133_crn
IMPORT FGL sa140_hist

-- System Module imports
IMPORT FGL sy101_user
IMPORT FGL sy102_role
IMPORT FGL sy103_perm
IMPORT FGL sy130_logs
IMPORT FGL sy150_lkup_config

SCHEMA demoappdb

CONSTANT APP_NAME = "XACT ERP System"
CONSTANT MAX_LOGIN_ATTEMPTS = 3

GLOBALS
    DEFINE g_user_authenticated SMALLINT
    DEFINE g_current_username STRING
    DEFINE g_login_time DATETIME YEAR TO SECOND
    DEFINE g_window_count INTEGER
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

    -- Open MDI container with top menu
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

    -- MDI container setup
    CALL ui.Interface.setContainer('main_shell')
    CALL ui.Interface.setName('main_shell')
    CALL ui.Interface.setType('container')

    -- Open MDI parent window with tabbed container
    OPEN WINDOW w_main WITH FORM "main_shell"
        ATTRIBUTES(TEXT = APP_NAME || " - " || g_current_username)

    LET w = ui.Window.getCurrent()
    LET f = w.getForm()

    -- Load top menu
    CALL ui.Interface.loadTopmenu("main_topmenu")

    -- Show main menu (handles top menu actions)
    CALL show_main_menu()

    --CLOSE WINDOW w_main
END FUNCTION

-- ==============================================================
-- MAIN MENU (Top Menu Bar Handler)
-- ==============================================================
FUNCTION show_main_menu()
    MENU "Main Menu"

        -- File Menu Actions
        ON ACTION help      CALL show_help()
        ON ACTION about     CALL show_about_dialog()

        ON ACTION logout
            IF confirm_logout() THEN
                EXIT MENU
            END IF

        ON ACTION quit
            IF confirm_exit() THEN
                EXIT MENU
            END IF

            -- Inventory - Stock Items
        ON ACTION st_mast       CALL launch_child_module("st101_mast", "Stock Master")
        ON ACTION st_uom        CALL launch_child_module("st103_uom_mast", "Units of Measure")
        ON ACTION st_cat        CALL launch_child_module("st102_cat", "Stock Categories")

            -- Warehouse
        ON ACTION wh_mast       CALL launch_child_module("wh101_mast", "Warehouses")
        ON ACTION wb_mast       CALL launch_child_module("wb101_mast", "Warehouse Bins")

            -- Purchasing
        ON ACTION cl_mast       CALL launch_child_module("cl101_mast", "Suppliers")
        ON ACTION pu_order      CALL launch_child_module("pu130_order", "Purchase Orders")
        ON ACTION pu_grn        CALL launch_child_module("pu131_grn", "Goods Received Notes")

            -- Sales
        ON ACTION dl_mast       CALL launch_child_module("dl101_mast", "Customers")
        ON ACTION sa_quote      CALL launch_child_module("sa130_quote", "Sales Quotations")
        ON ACTION sa_order      CALL launch_child_module("sa131_order", "Sales Orders")
        ON ACTION sa_invoice    CALL launch_child_module("sa132_invoice", "Sales Invoices")
        ON ACTION sa_crn        CALL launch_child_module("sa133_crn", "Credit Notes")

            -- System
        ON ACTION sy_user       CALL launch_child_module("sy101_user", "User Management")
        ON ACTION sy_role       CALL launch_child_module("sy102_role", "User Roles")
        ON ACTION sy_perm       CALL launch_child_module("sy103_perm", "User Permissions")
        ON ACTION sy_pwd        CALL change_password()
        ON ACTION sy_logs       CALL launch_child_module("sy130_logs", "System Logs")
        ON ACTION sy_lkup_config       CALL launch_child_module("sy150_lkup_config", "System Lookup Config")

            -- Window Management
        ON ACTION win_close     CALL close_current_window()
        ON ACTION win_close_all CALL close_all_windows()
        ON ACTION win_list      CALL main_shell.show_window_manager()
        
    END MENU
END FUNCTION

-- ==============================================================
-- LAUNCH CHILD MODULE (using main_shell MDI functions)
-- ==============================================================
FUNCTION launch_child_module(module_name STRING, title STRING)

DEFINE win_name STRING   
DEFINE ok SMALLINT 

    LET g_window_count = g_window_count + 1
    LET win_name = module_name || "_" || g_window_count
    
    -- Ask main_shell to create and register the window inside MDI
    IF main_shell.launch_child_window(module_name, title) THEN
        
        CASE module_name

            -- Stock
            WHEN "st101_mast"       CALL st101_mast.init_st_module()
            WHEN "st102_cat"        CALL st102_cat.init_category_module()
            WHEN "st103_uom_mast"   CALL st103_uom_mast.init_uom_module()

            -- Warehouse & Bin
            WHEN "wh101_mast"       CALL wh101_mast.init_wh_module()
            WHEN "wb101_mast"       CALL wb101_mast.init_wb_module()

            -- Customers/Suppliers
            WHEN "dl101_mast"       CALL dl101_mast.init_dl_module()
            WHEN "cl101_mast"       CALL cl101_mast.init_cl_module()

            -- Purchases
            WHEN "pu130_order"      CALL pu130_order.new_po()
            WHEN "pu131_grn"        CALL pu131_grn.new_pu_grn()

            -- Sales
            WHEN "sa130_quote"      CALL sa130_quote.new_quote()
            WHEN "sa131_order"      CALL sa131_order.new_order()
            WHEN "sa132_invoice"    CALL sa132_invoice.new_invoice()

            -- System
            WHEN "sy101_user"       CALL sy101_user.init_user_module()
            WHEN "sy102_role"       CALL sy102_role.init_role_module()
            WHEN "sy103_perm"       CALL sy103_perm.init_perm_module()
            WHEN "sy130_logs"       CALL sy130_logs.init_logs_module()
            WHEN "sy150_lkup_config"       CALL sy150_lkup_config.init_lkup_config_module()

            OTHERWISE
                CALL utils_globals.show_error("Module not implemented: " || module_name)

        END CASE

        -- Close the child window when module returns
        LET ok =  main_shell.close_child_window(module_name)

    END IF

END FUNCTION

-- ==============================================================
-- WINDOW MANAGEMENT FUNCTIONS
-- ==============================================================
FUNCTION close_current_window()
    DEFINE w ui.Window
    DEFINE winname STRING

    LET w = ui.Window.getCurrent()

    IF w IS NULL THEN
        CALL utils_globals.show_info("No active window.")
        RETURN
    END IF

    LET winname = ui.Interface.getContainer()


    IF winname = "w_main" THEN
        CALL utils_globals.show_info("Cannot close main window.")
        RETURN
    END IF

    TRY
        CLOSE WINDOW winname
        CALL main_shell.cleanup_stale_windows()
    CATCH
        CALL utils_globals.show_error("Unable to close window: " || winname)
    END TRY
END FUNCTION


-- ==============================================================
-- CLOSE ALL WINDOW 
-- ==============================================================
FUNCTION close_all_windows()
    IF utils_globals.show_confirm("Close all open windows?", "Confirm") THEN
        CALL main_shell.close_all_child_windows()
        CALL utils_globals.show_info("All windows closed.")
    END IF
END FUNCTION

-- ==============================================================
-- HELPER FUNCTIONS
-- ==============================================================
FUNCTION show_help()
    DEFINE help_text STRING
    LET help_text =
        "XACT ERP System - Help\n\n"
            || "Navigation:\n"
            || "- Use the top menu to access modules\n"
            || "- Multiple windows can be open simultaneously\n"
            || "- Use Window menu to manage open windows\n\n"
            || "For more help, contact support."

    CALL utils_globals.show_info(help_text)
END FUNCTION

FUNCTION change_password()
    DEFINE result SMALLINT
    LET result = sy104_user_pwd.change_password(g_current_username)
    IF result THEN
        CALL utils_globals.show_info("Password changed successfully.")
    END IF
END FUNCTION

FUNCTION show_about_dialog()
    DEFINE about_text STRING
    DEFINE formatted_login STRING
    LET formatted_login = ""
    IF g_login_time IS NOT NULL THEN
        LET formatted_login = g_login_time USING "DD/MM/YYYY HH:MM:SS"
    END IF

    LET about_text =
        APP_NAME
                || "\n"
                || "Version: 1.0\n"
                || "User: "
                || g_current_username
                || "\n"
                || "Login Time: "
                || formatted_login
                || "\n\n"
                || "(c) 2025 XactERP Solutions"

    CALL utils_globals.show_info(about_text)
END FUNCTION

FUNCTION confirm_logout() RETURNS SMALLINT
    RETURN utils_globals.show_confirm(
        "Are you sure you want to logout?", "Confirm Logout")
END FUNCTION

FUNCTION confirm_exit() RETURNS SMALLINT
    RETURN utils_globals.show_confirm(
        "Are you sure you want to exit?", "Confirm Exit")
END FUNCTION

-- ==============================================================
-- CLEANUP
-- ==============================================================
FUNCTION cleanup_application()
    CALL main_shell.close_all_child_windows()
    LET g_user_authenticated = FALSE
    LET g_current_username = NULL
    LET g_login_time = NULL
END FUNCTION
