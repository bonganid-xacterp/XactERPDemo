-- ==============================================================
-- Program   : st01_mast.4gl
-- Purpose   : Stock Master maintenance
-- Module    : Stock Master (st)
-- Number    : 01
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
-- MAIN
-- ==============================================================
--MAIN
--    IF NOT utils_globals.initialize_application() THEN
--        DISPLAY "Initialization failed."
--        EXIT PROGRAM 1
--    END IF
--
--    OPEN WINDOW w WITH FORM "st101_mast" ATTRIBUTES(STYLE = "modal")
--    CALL run_stock_master()
--    CLOSE WINDOW w
--END MAIN

-- run stock in the system
FUNCTION run_stock_master()
    DISPLAY "display here"

END FUNCTION