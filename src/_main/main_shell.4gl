# ==============================================================
# Program   :   main_shell.4gl
# Purpose   :   Centralized container window with menu + child mgmt
# Module    :   Main
# Number    :   120
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.2.1
# ==============================================================

IMPORT FGL utils_ui
IMPORT ui
IMPORT FGL main_auth

-- Track open modules
DEFINE g_open_modules DYNAMIC ARRAY OF RECORD
    prog STRING, -- form/program name
    winname STRING -- window identifier
END RECORD

FUNCTION main_application_menu()
    MENU "Main Menu"
        -- ====================
        -- Debtors
        -- ====================
        ON ACTION dl_enq
            CALL launch_child_window("dl101_mast", "Debtors Enquiry")
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
    RETURN utils_ui.show_alert("Are you sure you want to exit?", "Confirm Exit")
END FUNCTION

-- Launch child with duplicate check
FUNCTION launch_child_window(formname STRING, wintitle STRING)
    DEFINE i INTEGER
    DEFINE winname STRING

    -- Check if already open
    FOR i = 1 TO g_open_modules.getLength()
        IF g_open_modules[i].prog = formname THEN
            ERROR utils_ui.show_alert(
                wintitle || " is already open!", "System Alert")
            RETURN
        END IF
    END FOR

    -- Assign unique window name
    LET winname = "w_" || formname

    -- Attach child to mdi_wrapper container
    CALL ui.Interface.setContainer("mdi_wrapper")
    CALL ui.Interface.setType("Window.childModal")

    -- Open child window
    OPEN WINDOW winname
        WITH
        FORM formname
        ATTRIBUTES(STYLE = "child", TEXT = wintitle)

    -- Add to registry
    LET i = g_open_modules.getLength() + 1
    LET g_open_modules[i].prog = formname
    LET g_open_modules[i].winname = winname
END FUNCTION

-- Remove from registry when closed
FUNCTION unregister_program(formname STRING)
    DEFINE i INTEGER
    FOR i = 1 TO g_open_modules.getLength()
        IF g_open_modules[i].prog = formname THEN
            CALL g_open_modules.deleteElement(i)
            EXIT FOR
        END IF
    END FOR
END FUNCTION
