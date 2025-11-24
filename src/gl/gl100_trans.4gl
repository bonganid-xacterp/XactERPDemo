# ==============================================================
# Program   :   gl100_mast.4gl
# Purpose   :   A program for adding , edit and to display corresponding
#               transactions debtors
# Module    :   Debtors
# Number    :   100
# Author    :   Bongani Dlamini
# Version   :   Genero ver 3.20.10
# ==============================================================

IMPORT ui


SCHEMA demoappdb

-- ==============================================================
-- DEFINATIONS
-- ==============================================================
TYPE gl_lines_t RECORD LIKE gl31_lines.*

DEFINE gl_lines_rec gl_lines_t

DEFINE is_edit_mode SMALLINT

-- ==============================================================
-- Program init
-- ==============================================================
FUNCTION init_dl_module()
    DEFINE chosen_row SMALLINT
    LET is_edit_mode = FALSE

    INITIALIZE gl_lines_rec.* TO NULL

    DISPLAY BY NAME gl_lines_rec.*

    
END FUNCTION
