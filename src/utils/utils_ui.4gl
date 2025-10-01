# ==============================================================
# Program   :   utils_ui.4gl
# Purpose   :   Utilities for shared ui components
# Module    :   Utilities
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.2.1
# ==============================================================

IMPORT ui

-- =============================================================
-- Show a generic alert dialog
-- =============================================================
FUNCTION show_alert(p_message STRING, p_title STRING)
    DEFINE l_title STRING
    DEFINE result SMALLINT

    -- Default title
    IF p_title IS NULL OR p_title = "" THEN
        LET l_title = "System Alert"
    ELSE
        LET l_title = p_title
    END IF

    MENU l_title ATTRIBUTE(STYLE = "dialog")
        COMMAND "OK"
            DISPLAY p_message
            LET result = TRUE
            EXIT MENU
    END MENU

    RETURN result
END FUNCTION

-- =============================================================
-- Show an error alert (alias of show_alert but different naming)
-- =============================================================
FUNCTION show_error_alert(p_message STRING, p_title STRING)
    RETURN show_alert(p_message, p_title)
END FUNCTION

-- =============================================================
-- Set the current window page title
-- =============================================================
FUNCTION set_page_title(p_title STRING)
    DEFINE g_win ui.Window
    LET g_win = ui.Window.getCurrent()
    IF g_win IS NOT NULL THEN
        CALL g_win.setText("XACT ERP Demo – " || p_title)
    END IF
END FUNCTION

-- =============================================================
-- Set the value of a label element in the current form
-- =============================================================
FUNCTION set_form_lbl(lbl_name STRING, new_text STRING)
    DEFINE g_form ui.Form
    LET g_form = ui.Window.getCurrent().getForm()

    CALL g_form.setElementText(lbl_name, new_text)
END FUNCTION

-- =============================================================
-- Mark this program as a child of the mdi_wrapper
-- =============================================================
FUNCTION set_child_container()
    CALL ui.Interface.setContainer("mdi_wrapper")
    CALL ui.Interface.setType("childModal")

END FUNCTION
