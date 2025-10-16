-- ==============================================================
-- Program   : utils_status_const.4gl
-- Purpose   : DEPRECATED - Use utils_globals.4gl instead
-- ==============================================================

IMPORT FGL utils_globals

-- Redirect to optimized implementation
FUNCTION populate_status_combobox()
    CALL utils_globals.populate_status_combo("status")
END FUNCTION
