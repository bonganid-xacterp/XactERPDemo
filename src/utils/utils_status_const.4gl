# ==============================================================
# Program   : utils_status_const.4gl
# Purpose   : Global constants and utility arrays
# Module    : Utils (utils)
# Number    :
# Author    : Bongani Dlamini
# Version   : Genero BDL 3.20.10
# ==============================================================

CONSTANT STATUS_ACTIVE = 1
CONSTANT STATUS_INACTIVE = 0

# Array for combobox options
DEFINE g_status_values DYNAMIC ARRAY OF RECORD
    code SMALLINT,
    label STRING
END RECORD

-- Get active and inactive statuses
FUNCTION init_status_constants()
    -- Initialize status values (only once)
    IF g_status_values.getLength() = 0 THEN
        LET g_status_values[1].code = STATUS_ACTIVE
        LET g_status_values[1].label = "Active"

        LET g_status_values[2].code = STATUS_INACTIVE
        LET g_status_values[2].label = "Inactive"
    END IF
END FUNCTION
