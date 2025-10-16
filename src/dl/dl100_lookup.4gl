-- ==============================================================
-- File     : dl100_lookup.4gl
-- Purpose  : Debtors (DL) - Lookup functionality
-- Module   : Debtors (dl)
-- Number   : 100
-- Author   : Bongani Dlamini
-- Version  : Genero BDL 3.20.10
-- Description: Search and selection functionality for debtors
-- ==============================================================

IMPORT FGL utils_globals

SCHEMA demoapp_db

-- Search and select debtor
FUNCTION dl_search() RETURNS STRING
    -- Implementation for debtor search/lookup
    RETURN ""
END FUNCTION

-- Lookup debtor by code or name
FUNCTION lookup_debtor(search_val STRING) RETURNS STRING
    RETURN utils_globals.generic_lookup("dl01_mast", "acc_code", "name", search_val, "Debtor", "")
END FUNCTION 