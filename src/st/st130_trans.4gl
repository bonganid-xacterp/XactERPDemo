-- ==============================================================
-- Program   : st130_trans.4gl
-- Purpose   : Stock Transaction
-- Module    : Stock Transactions (st)
-- Number    : 130
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL utils_db
IMPORT FGL utils_lookup
IMPORT FGL utils_status_const

SCHEMA xactdemo_db

-- ==============================================================
-- Record definition
-- ==============================================================


-- ==============================================================
-- MAIN
-- ==============================================================
MAIN
    IF NOT utils_globals.initialize_application() THEN
        DISPLAY "Initialization failed."
        EXIT PROGRAM 1
    END IF

    OPEN WINDOW w WITH FORM "st130_trans" ATTRIBUTES(STYLE = "modal")
    CALL run_stock_trans()
    CLOSE WINDOW w
END MAIN

-- run stock in the system
FUNCTION run_stock_trans()
    DISPLAY "display here"

END FUNCTION 