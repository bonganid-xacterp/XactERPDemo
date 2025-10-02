# ==============================================================
# Program   :   main_menu.4gl
# Purpose   :   Loads App menu
# Module    :   Main
# Number    :
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.20.10
# ==============================================================

IMPORT FGL utils_ui
IMPORT FGL main_shell

FUNCTION main_application_menu()
    MENU "Main Menu"
        -- ====================
        -- Debtors
        -- ====================
        ON ACTION dl_enq
            CALL launch_child_window("dl120_enq", "Debtors Enquiry")
        ON ACTION dl_maint
            CALL launch_child_window("dl101_mast", "Debtors Maintenance")

            -- ====================
            -- Creditors
            -- ====================
        ON ACTION cl_enq
            CALL launch_child_window("cl120_enq", "Creditors Enquiry")
        ON ACTION cl_maint
            CALL launch_child_window("cl101_mast", "Creditors Maintenance")

            -- ====================
            -- Stock
            -- ====================
        ON ACTION st_enq
            CALL launch_child_window("st120_enq", "Stock Enquiry")
        ON ACTION st_maint
            CALL launch_child_window("st101_mast", "Stock Maintenance")

            -- ====================
            -- Finance
            -- ====================
        ON ACTION gl_enq
            CALL launch_child_window("gl120_enq", "GL Enquiry")
        ON ACTION gl_maint
            CALL launch_child_window("gl101_acc", "GL Maintenance")

            -- ====================
            -- Sales
            -- ====================
        ON ACTION sa_ord_enq
            CALL launch_child_window("sa120_enq", "Sales Orders Enquiry")
        ON ACTION sa_ord_maint
            CALL launch_child_window("sa130_hdr", "Sales Orders Maintenance")

            -- ====================
            -- Purchases
            -- ====================
        ON ACTION pu_po_enq
            CALL launch_child_window("pu120_enq", "Purchase Orders Enquiry")
        ON ACTION pu_po_maint
            CALL launch_child_window("pu130_hdr", "Purchase Orders Maintenance")

            -- ====================
            -- System
            -- ====================
        ON ACTION sy_usr_enq
            CALL launch_child_window("sy120_enq", "Users Enquiry")
        ON ACTION sy_usr_maint
            CALL launch_child_window("sy100_user", "Users Maintenance")

            -- ====================
            -- Exit
            -- ====================
        ON ACTION main_exit
            IF confirm_exit() THEN
                EXIT MENU
            END IF
    END MENU
END FUNCTION

-- Confirm application exit
FUNCTION confirm_exit()
    RETURN utils_ui.show_confirm(
        "Are you sure you want to exit?", "Confirm Exit")
END FUNCTION
