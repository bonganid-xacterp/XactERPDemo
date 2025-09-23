FUNCTION main_application_menu()
    MENU "Main Menu"

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
    DISPLAY module_name
END FUNCTION

FUNCTION confirm_exit()
    DISPLAY "Exiting..."
    RETURN 1
END FUNCTION 
