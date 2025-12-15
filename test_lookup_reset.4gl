-- ==============================================================
-- Test program for lookup reset functionality
-- ==============================================================

IMPORT FGL utils_global_lkup_form
IMPORT FGL utils_globals

SCHEMA demoappdb

MAIN
    DEFINE result STRING

    DEFER INTERRUPT
    DEFER QUIT

    -- Connect to database
    CALL utils_globals.connect_to_db()

    IF NOT utils_globals.is_connected() THEN
        DISPLAY "Failed to connect to database"
        EXIT PROGRAM
    END IF

    OPEN FORM test_form FROM "test_lookup_reset"

    DISPLAY "Testing Lookup with Reset Functionality"
    DISPLAY "========================================"
    DISPLAY ""
    DISPLAY "Test 1: Stock Lookup (with search and reset)"

    LET result = utils_global_lkup_form.lookup_stock()

    IF result IS NOT NULL THEN
        DISPLAY "Selected Stock ID: ", result
    ELSE
        DISPLAY "No selection made"
    END IF

    DISPLAY ""
    DISPLAY "Test 2: Customer Lookup"

    LET result = utils_global_lkup_form.lookup_customer()

    IF result IS NOT NULL THEN
        DISPLAY "Selected Customer ID: ", result
    ELSE
        DISPLAY "No selection made"
    END IF

    DISPLAY ""
    DISPLAY "Testing complete!"
    DISPLAY "Press any key to exit..."

    MENU "Test Complete"
        COMMAND "Exit"
            EXIT MENU
    END MENU

    CALL utils_globals.disconnect_from_db()

END MAIN
