IMPORT ui

SCHEMA "xactdemo"

FUNCTION main_application_menu()
    MENU "Main Menu"
        BEFORE MENU
            CALL update_status("Select an option from the menu")

        COMMAND "customer" "Customer Management"
            CALL launch_child_window("customer_management")

        COMMAND "orders" "Order Processing"
            CALL launch_child_window("order_entry")

        COMMAND "inventory" "Inventory Management"
            CALL launch_child_window("inventory_management")

        COMMAND "reports" "Reports & Analytics"
            CALL launch_child_window("reports_menu")

        COMMAND "admin" "System Administration"
            CALL launch_child_window("system_admin")

        COMMAND "exit" "Exit System"
            IF confirm_exit() THEN
                EXIT MENU
            END IF
    END MENU
END FUNCTION


FUNCTION launch_child_window(module_name STRING)
    DEFINE cmd STRING
    LET cmd = module_name CLIPPED
    CALL update_status("Launching " || cmd || "...")
    RUN cmd WITHOUT WAITING
    CALL update_status("Ready - " || cmd || " launched")
END FUNCTION


FUNCTION update_status(p_msg STRING)
    DEFINE w ui.Window
    DEFINE f ui.Form

    LET w = ui.Window.getCurrent()
    IF w IS NULL THEN
        -- Nothing displayed yet; avoid crashing
        RETURN
    END IF

    LET f = w.getForm()
    IF f IS NULL THEN
        RETURN
    END IF

    -- Fast, stable API for changing a label's text
    CALL f.setElementText("status_bar", p_msg)
END FUNCTION


FUNCTION confirm_exit() RETURNS BOOLEAN
    DEFINE result BOOLEAN

    OPEN WINDOW w_confirm WITH 4 ROWS, 50 COLUMNS
        ATTRIBUTE(STYLE="dialog", TEXT="Confirm Exit")

    DISPLAY "Are you sure you want to exit?" AT 1,5

    MENU "Confirm"
        COMMAND "yes" "Yes, Exit"
            LET result = TRUE
            EXIT MENU
        COMMAND "no" "No, Cancel"
            LET result = FALSE
            EXIT MENU
    END MENU

    CLOSE WINDOW w_confirm
    RETURN result
END FUNCTION


FUNCTION shutdown_application()
    CALL update_status("Shutting down...")
    SLEEP 1
END FUNCTION
