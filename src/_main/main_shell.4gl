# ==============================================================
# Program   : main_shell.4gl
# Purpose   : Centralized container window module for loading
#             other programs via TopMenu
# Module    : main
# Number    : 100
# Author    : Bongani Dlamini
# Version   : Genero BDL 3.2.1
# ==============================================================

IMPORT FGL utils_ui

FUNCTION main_application_menu()

    -- Set page title (optional helper)
    CALL utils_ui.set_page_title("Dashboard")

    -- TopMenu actions come from main_shell.4fd
    MENU "Main Menu"

        -- =======================
        -- Debtors
        -- =======================
        ON ACTION dl_enq
            CALL launch_child_window("debtor_enquiry")

        ON ACTION dl_maint
            CALL launch_child_window("debtor_maintenance")

        -- =======================
        -- Creditors
        -- =======================
        ON ACTION cl_enq
            CALL launch_child_window("creditor_enquiry")

        ON ACTION cl_maint
            CALL launch_child_window("creditor_maintenance")

        -- =======================
        -- Stock + Warehouse
        -- =======================
        ON ACTION st_enq
            CALL launch_child_window("stock_enquiry")

        ON ACTION st_maint
            CALL launch_child_window("stock_maintenance")

        ON ACTION st_cat_enq
            CALL launch_child_window("stock_category_enquiry")

        ON ACTION st_cat_maint
            CALL launch_child_window("stock_category_maintenance")

        ON ACTION wh_enq
            CALL launch_child_window("warehouse_enquiry")

        ON ACTION wh_maint
            CALL launch_child_window("warehouse_maintenance")

        ON ACTION wb_enq
            CALL launch_child_window("warehouse_bin_enquiry")

        ON ACTION wb_maint
            CALL launch_child_window("warehouse_bin_maintenance")

        -- =======================
        -- Finance
        -- =======================
        ON ACTION gl_enq
            CALL launch_child_window("gl_enquiry")

        ON ACTION gl_maint
            CALL launch_child_window("gl_maintenance")

        ON ACTION jnl_enq
            CALL launch_child_window("journal_enquiry")

        ON ACTION jnl_maint
            CALL launch_child_window("journal_maintenance")

        -- =======================
        -- Sales
        -- =======================
        ON ACTION sa_ord_enq
            CALL launch_child_window("sales_order_enquiry")

        ON ACTION sa_ord_maint
            CALL launch_child_window("sales_order_maintenance")

        ON ACTION sa_inv_enq
            CALL launch_child_window("sales_invoice_enquiry")

        ON ACTION sa_inv_maint
            CALL launch_child_window("sales_invoice_maintenance")

        ON ACTION sa_crn_enq
            CALL launch_child_window("sales_crn_enquiry")

        ON ACTION sa_crn_maint
            CALL launch_child_window("sales_crn_maintenance")

        ON ACTION sa_qt_enq
            CALL launch_child_window("sales_quote_enquiry")

        ON ACTION sa_qt_maint
            CALL launch_child_window("sales_quote_maintenance")

        -- =======================
        -- Purchases
        -- =======================
        ON ACTION pu_po_enq
            CALL launch_child_window("purchase_order_enquiry")

        ON ACTION pu_po_maint
            CALL launch_child_window("purchase_order_maintenance")

        ON ACTION pu_grn_enq
            CALL launch_child_window("purchase_grn_enquiry")

        ON ACTION pu_grn_maint
            CALL launch_child_window("purchase_grn_maintenance")

        -- =======================
        -- System
        -- =======================
        ON ACTION sy_usr_enq
            CALL launch_child_window("user_enquiry")

        ON ACTION sy_usr_maint
            CALL launch_child_window("user_maintenance")

        ON ACTION sy_roles_enq
            CALL launch_child_window("roles_enquiry")

        ON ACTION sy_roles_maint
            CALL launch_child_window("roles_maintenance")

        ON ACTION sys_perm_enq
            CALL launch_child_window("permissions_enquiry")

        ON ACTION sy_perm_maint
            CALL launch_child_window("permissions_maintenance")

        ON ACTION sys_sett
            CALL launch_child_window("system_settings")

        ON ACTION sys_logs
            CALL launch_child_window("system_logs")

        -- =======================
        -- Help
        -- =======================
        ON ACTION sy_about
            CALL launch_child_window("about")

        -- =======================
        -- Exit
        -- =======================
        ON ACTION main_exit
            IF confirm_exit() THEN
                EXIT MENU
            END IF

    END MENU
END FUNCTION

-- confirm apploication exit
FUNCTION confirm_exit() DISPLAY "Exiting..." RETURN 1 END FUNCTION


# ======================================================================
# Centralized child window launcher
# ======================================================================
FUNCTION launch_child_window(module_name STRING)
    CASE module_name

        -- =======================
        -- Debtors
        -- =======================
        WHEN "debtor_enquiry"
            CALL open_program("w_dl_enq", "dl120_enq", "Debtors Enquiry")

        WHEN "debtor_maintenance"
            CALL open_program("w_dl_maint", "dl101_mast", "Debtors Maintenance")

        -- =======================
        -- Creditors
        -- =======================
        WHEN "creditor_enquiry"
            CALL open_program("w_cl_enq", "cl120_enq", "Creditors Enquiry")

        WHEN "creditor_maintenance"
            CALL open_program("w_cl_maint", "cl101_mast", "Creditors Maintenance")

        -- =======================
        -- Stock + Warehouse
        -- =======================
        WHEN "stock_enquiry"
            CALL open_program("w_st_enq", "st120_enq", "Stock Enquiry")

        WHEN "stock_maintenance"
            CALL open_program("w_st_maint", "st101_mast", "Stock Maintenance")

        WHEN "stock_category_enquiry"
            CALL open_program("w_st_cat_enq", "st121_enq", "Stock Category Enquiry")

        WHEN "stock_category_maintenance"
            CALL open_program("w_st_cat_maint", "st102_cat", "Stock Category Maintenance")

        WHEN "warehouse_enquiry"
            CALL open_program("w_wh_enq", "wh120_enq", "Warehouse Enquiry")

        WHEN "warehouse_maintenance"
            CALL open_program("w_wh_maint", "wh101_mast", "Warehouse Maintenance")

        WHEN "warehouse_bin_enquiry"
            CALL open_program("w_wb_enq", "wb120_enq", "Warehouse Bin Enquiry")

        WHEN "warehouse_bin_maintenance"
            CALL open_program("w_wb_maint", "wb101_mast", "Warehouse Bin Maintenance")

        -- =======================
        -- Finance (GL + Journals)
        -- =======================
        WHEN "gl_enquiry"
            CALL open_program("w_gl_enq", "gl120_enq", "G/L Enquiry")

        WHEN "gl_maintenance"
            CALL open_program("w_gl_maint", "gl101_acc", "G/L Maintenance")

        WHEN "journal_enquiry"
            CALL open_program("w_jnl_enq", "gl121_enq", "Journal Enquiry")

        WHEN "journal_maintenance"
            CALL open_program("w_jnl_maint", "gl130_jrn", "Journal Maintenance")

        -- =======================
        -- Sales
        -- =======================
        WHEN "sales_order_enquiry"
            CALL open_program("w_sa_ord_enq", "sa120_enq", "Sales Orders Enquiry")

        WHEN "sales_order_maintenance"
            CALL open_program("w_sa_ord_maint", "sa130_hdr", "Sales Orders Maintenance")

        WHEN "sales_invoice_enquiry"
            CALL open_program("w_sa_inv_enq", "sa121_enq", "Sales Invoices Enquiry")

        WHEN "sales_invoice_maintenance"
            CALL open_program("w_sa_inv_maint", "sa131_hdr", "Sales Invoices Maintenance")

        WHEN "sales_crn_enquiry"
            CALL open_program("w_sa_crn_enq", "sa122_enq", "Sales Credit Notes Enquiry")

        WHEN "sales_crn_maintenance"
            CALL open_program("w_sa_crn_maint", "sa132_hdr", "Sales Credit Notes Maintenance")

        WHEN "sales_quote_enquiry"
            CALL open_program("w_sa_qt_enq", "sa123_enq", "Sales Quotes Enquiry")

        WHEN "sales_quote_maintenance"
            CALL open_program("w_sa_qt_maint", "sa133_hdr", "Sales Quotes Maintenance")

        -- =======================
        -- Purchases
        -- =======================
        WHEN "purchase_order_enquiry"
            CALL open_program("w_pu_ord_enq", "pu120_enq", "Purchase Orders Enquiry")

        WHEN "purchase_order_maintenance"
            CALL open_program("w_pu_ord_maint", "pu130_hdr", "Purchase Orders Maintenance")

        WHEN "purchase_grn_enquiry"
            CALL open_program("w_pu_grn_enq", "pu121_enq", "Purchase GRN Enquiry")

        WHEN "purchase_grn_maintenance"
            CALL open_program("w_pu_grn_maint", "pu131_hdr", "Purchase GRN Maintenance")

        -- =======================
        -- System
        -- =======================
        WHEN "user_enquiry"
            CALL open_program("w_sy_usr_enq", "sy120_enq", "Users Enquiry")

        WHEN "user_maintenance"
            CALL open_program("w_sy_usr_maint", "sy100_user", "Users Maintenance")

        WHEN "roles_enquiry"
            CALL open_program("w_sy_roles_enq", "sy121_enq", "Roles Enquiry")

        WHEN "roles_maintenance"
            CALL open_program("w_sy_roles_maint", "sy101_role", "Roles Maintenance")

        WHEN "permissions_enquiry"
            CALL open_program("w_sy_perm_enq", "sy122_enq", "Permissions Enquiry")

        WHEN "permissions_maintenance"
            CALL open_program("w_sy_perm_maint", "sy102_perm", "Permissions Maintenance")

        WHEN "system_settings"
            CALL open_program("w_sy_sett", "sy103_sett", "System Settings")

        WHEN "system_logs"
            CALL open_program("w_sy_logs", "sy104_logs", "System Logs")

        -- =======================
        -- Help
        -- =======================
        WHEN "about"
            CALL open_program("w_sy_about", "sy900_about", "About XactERP")

        OTHERWISE
            MESSAGE "Unknown module: " || module_name
    END CASE
END FUNCTION

# ======================================================================
# Safe wrapper to open child windows inside mdi_area
# ======================================================================
FUNCTION open_program(winname STRING, formname STRING, wintitle STRING)
    TRY
        OPEN WINDOW winname WITH FORM formname
            ATTRIBUTES(STYLE="child", TEXT=wintitle)
        CURRENT WINDOW IS winname
    CATCH
        CALL utils_ui.show_alert("Failed to open form: " || formname , 'System Error' )
    END TRY
END FUNCTION


