# ==============================================================
# Program   : utils_status_const.4gl
# Purpose   : Global constants and utility arrays
# Module    : Utils (utils)
# Number    :
# Author    : Bongani Dlamini
# Version   : Genero BDL 3.20.10
# ==============================================================

# Array for combobox options
DEFINE g_status_values DYNAMIC ARRAY OF RECORD
    code SMALLINT,
    label STRING
END RECORD

-- Get active and inactive statuses

-- load status combos
FUNCTION populate_status_combobox()
    DEFINE cb ui.ComboBox
    DEFINE i INTEGER
    
    -- Populate array
    LET g_status_values[1].code  = 1
    LET g_status_values[1].label = "Active"
    LET g_status_values[2].code  = 0
    LET g_status_values[2].label = "Inactive"
    LET g_status_values[3].code  = -1
    LET g_status_values[3].label = "Archived"
    
    -- Get combobox directly by field name
    LET cb = ui.ComboBox.forName("status")
    
    IF cb IS NOT NULL THEN
        -- Clear old values
        CALL cb.clear()
        
        -- Add new options
        FOR i = 1 TO g_status_values.getLength()
            CALL cb.addItem(g_status_values[i].code,
                            g_status_values[i].label)
        END FOR
    ELSE
        DISPLAY "Warning: ComboBox 'status' not found"
    END IF
    
END FUNCTION
