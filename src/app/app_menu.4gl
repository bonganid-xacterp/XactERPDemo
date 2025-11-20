-- ==============================================================
-- Program   : app_menu.4gl
-- Purpose   : Menu Handler for MDI Application
-- Author    : Bongani Dlamini
-- Version   : Genero 3.20.10
-- Description: Handles menu actions and module launching for app_start
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL app_start
IMPORT FGL sy104_user_pwd

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

-- ==============================================================
-- MAIN MENU (Top Menu Bar Handler)
-- ==============================================================
PUBLIC FUNCTION show_main_menu()
    DEFINE w ui.Window
    DEFINE f ui.Form

    LET w = ui.Window.getCurrent()
    LET f = w.getForm()

    -- Load top menu
    CALL ui.Interface.loadTopmenu("main_topmenu")

    MENU "Main Menu"

        -- File Menu Actions
        ON ACTION help
            CALL show_help()

        ON ACTION about
            CALL show_about_dialog()

        ON ACTION logout
            IF confirm_logout() THEN
                EXIT MENU
            END IF

        ON ACTION quit
            IF confirm_exit() THEN
                EXIT MENU
            END IF

        -- Inventory - Stock Items
        ON ACTION st_mast
            CALL launch_module("st101_mast", "Stock Master")

        ON ACTION st_uom
            CALL launch_module("st103_uom_mast", "Units of Measure")

        ON ACTION st_cat
            CALL launch_module("st102_cat", "Stock Categories")

        ON ACTION st_enq
            CALL launch_module("st120_enq", "Stock Enquiry")

        ON ACTION st_trans
            CALL launch_module("st130_trans", "Stock Transactions")

        -- Warehouse
        ON ACTION wh_mast
            CALL launch_module("wh101_mast", "Warehouses")

        ON ACTION wb_mast
            CALL launch_module("wb101_mast", "Warehouse Bins")

        -- Purchasing
        ON ACTION cl_mast
            CALL launch_module("cl101_mast", "Suppliers")

        ON ACTION pu_order
            CALL launch_module("pu130_order", "Purchase Orders")

        ON ACTION pu_grn
            CALL launch_module("pu131_grn", "Goods Received Notes")

        ON ACTION pu_inv
            CALL launch_module("pu132_inv", "Purchase Invoices")

        -- Sales
        ON ACTION dl_mast
            CALL launch_module("dl101_mast", "Customers")

        ON ACTION sa_quote
            CALL launch_module("sa130_quote", "Sales Quotations")

        ON ACTION sa_order
            CALL launch_module("sa131_order", "Sales Orders")

        ON ACTION sa_invoice
            CALL launch_module("sa132_invoice", "Sales Invoices")

        ON ACTION sa_crn
            CALL launch_module("sa133_crn", "Credit Notes")

        -- System
        ON ACTION sy_user
            CALL launch_module("sy101_user", "User Management")

        ON ACTION sy_role
            CALL launch_module("sy102_role", "User Roles")

        ON ACTION sy_perm
            CALL launch_module("sy103_perm", "User Permissions")

        ON ACTION sy_pwd
            CALL change_password()

        ON ACTION sy_logs
            CALL launch_module("sy130_logs", "System Logs")

        ON ACTION sy_lkup_config
            CALL launch_module("sy150_lkup_config", "Lookup Configuration")

        -- Window Management
        ON ACTION win_close
            CALL close_current_window()

        ON ACTION win_close_all
            CALL close_all_windows()

        ON ACTION win_list
            CALL app_start.show_window_manager()

    END MENU
END FUNCTION

-- ==============================================================
-- LAUNCH MODULE (using app_start MDI functions)
-- ==============================================================
FUNCTION launch_module(module_name STRING, title STRING)
    DEFINE ok SMALLINT

    -- Ask app_start to create and register the window inside MDI
    IF app_start.launch_child_window(module_name, title) THEN

        CASE module_name

            -- Stock
            WHEN "st101_mast"
                CALL st101_mast.init_st_module()

            WHEN "st102_cat"
                CALL st102_cat.init_category_module()

            WHEN "st103_uom_mast"
                CALL st103_uom_mast.init_uom_module()

            WHEN "st120_enq"
                CALL st120_enq.init_st_enq_module()

            WHEN "st130_trans"
                CALL st130_trans.init_st_trans_module()

            -- Warehouse & Bin
            WHEN "wh101_mast"
                CALL wh101_mast.init_wh_module()

            WHEN "wb101_mast"
                CALL wb101_mast.init_wb_module()

            -- Customers/Suppliers
            WHEN "dl101_mast"
                CALL dl101_mast.init_dl_module()

            WHEN "cl101_mast"
                CALL cl101_mast.init_cl_module()

            -- Purchases
            WHEN "pu130_order"
                CALL pu130_order.new_po()

            WHEN "pu131_grn"
                CALL pu131_grn.new_pu_grn()

            WHEN "pu132_inv"
                CALL pu132_inv.new_pu_inv()

            -- Sales
            WHEN "sa130_quote"
                CALL sa130_quote.new_quote()

            WHEN "sa131_order"
                CALL sa131_order.new_order()

            WHEN "sa132_invoice"
                CALL sa132_invoice.new_invoice()

            WHEN "sa133_crn"
                CALL sa133_crn.new_crn()

            -- System
            WHEN "sy101_user"
                CALL sy101_user.init_user_module()

            WHEN "sy102_role"
                CALL sy102_role.init_role_module()

            WHEN "sy103_perm"
                CALL sy103_perm.init_perm_module()

            WHEN "sy130_logs"
                CALL sy130_logs.init_logs_module()

            WHEN "sy150_lkup_config"
                CALL sy150_lkup_config.init_lkup_config_module()

            OTHERWISE
                CALL utils_globals.show_error("Module not implemented: " || module_name)

        END CASE

        -- Close the child window when module returns
        LET ok = app_start.close_child_window(module_name)

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

    LET winname = w.getText()

    IF winname MATCHES "*Application*" OR winname MATCHES "*XACT ERP*" THEN
        CALL utils_globals.show_info("Cannot close main application window.")
        RETURN
    END IF

    TRY
        CLOSE WINDOW winname
        CALL app_start.cleanup_stale_windows()
    CATCH
        CALL utils_globals.show_error("Unable to close current window.")
    END TRY
END FUNCTION

FUNCTION close_all_windows()
    IF utils_globals.show_confirm("Close all open windows?", "Confirm") THEN
        CALL app_start.close_all_child_windows()
        CALL utils_globals.show_info("All windows closed.")
    END IF
END FUNCTION

-- ==============================================================
-- HELPER FUNCTIONS
-- ==============================================================
FUNCTION show_help()
    DEFINE help_text STRING
    DEFINE active_count INTEGER

    LET active_count = app_start.get_active_window_count()

    LET help_text =
        "XACT ERP Application - Help\n\n"
            || "Navigation:\n"
            || "- Use the top menu to access modules\n"
            || "- Multiple windows can be open simultaneously\n"
            || "- Use Window menu to manage open windows\n\n"
            || "Active Windows: " || active_count || "\n\n"
            || "Keyboard Shortcuts:\n"
            || "- F1: Help\n"
            || "- Ctrl+W: Close current window\n"
            || "- Ctrl+Q: Quit application\n\n"
            || "For more help, contact support."

    CALL utils_globals.show_info(help_text)
END FUNCTION

FUNCTION change_password()
    DEFINE result SMALLINT
    DEFINE username STRING

    LET username = app_start.get_current_user()
    LET result = sy104_user_pwd.change_password(username)

    IF result THEN
        CALL utils_globals.show_info("Password changed successfully.")
    END IF
END FUNCTION

FUNCTION show_about_dialog()
    DEFINE about_text STRING
    DEFINE username STRING
    DEFINE login_time DATETIME YEAR TO SECOND
    DEFINE formatted_login STRING

    LET username = app_start.get_current_user()
    LET login_time = app_start.get_login_time()

    LET formatted_login = ""
    IF login_time IS NOT NULL THEN
        LET formatted_login = login_time USING "DD/MM/YYYY HH:MM:SS"
    END IF

    LET about_text =
        "XACT ERP Application\n"
            || "Version: 1.0\n"
            || "Build: 2025.01\n\n"
            || "Current User: " || username || "\n"
            || "Login Time: " || formatted_login || "\n"
            || "Active Windows: " || app_start.get_active_window_count() || "\n\n"
            || "(c) 2025 XactERP Solutions\n"
            || "All rights reserved."

    CALL utils_globals.show_info(about_text)
END FUNCTION

FUNCTION confirm_logout() RETURNS SMALLINT
    DEFINE active_count INTEGER

    LET active_count = app_start.get_active_window_count()

    IF active_count > 0 THEN
        IF NOT utils_globals.show_confirm(
            "You have " || active_count || " open window(s).\n"
                || "All windows will be closed.\n\n"
                || "Are you sure you want to logout?",
            "Confirm Logout") THEN
            RETURN FALSE
        END IF
    END IF

    RETURN utils_globals.show_confirm(
        "Are you sure you want to logout?", "Confirm Logout")
END FUNCTION

FUNCTION confirm_exit() RETURNS SMALLINT
    DEFINE active_count INTEGER

    LET active_count = app_start.get_active_window_count()

    IF active_count > 0 THEN
        IF NOT utils_globals.show_confirm(
            "You have " || active_count || " open window(s).\n"
                || "All windows will be closed.\n\n"
                || "Are you sure you want to exit?",
            "Confirm Exit") THEN
            RETURN FALSE
        END IF
    END IF

    RETURN utils_globals.show_confirm(
        "Are you sure you want to exit the application?", "Confirm Exit")
END FUNCTION
