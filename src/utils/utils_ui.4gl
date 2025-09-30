# ==============================================================
# Program   :   utils_ui.4gl
# Purpose   :   Utilities for shared ui components
# Module    :   Utilities
# Number    :   
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.2.1
# ==============================================================


FUNCTION show_alert(p_message STRING, p_title STRING)
    DEFINE l_title STRING

    -- If caller passed NULL/empty, fall back to default
    IF p_title IS NULL OR p_title = "" THEN
        LET l_title = "System Alert"
    ELSE
        LET l_title = p_title
    END IF

    DIALOG
        INPUT BY NAME p_message
            ON ACTION ok
                EXIT DIALOG
        END INPUT
    END DIALOG

END FUNCTION

-- set the window page title
FUNCTION set_page_title(p_title STRING)
    DEFINE g_win ui.Window
    LET g_win = ui.Window.getCurrent()
    IF g_win IS NOT NULL THEN
        CALL g_win.setText("XACT ERP Demo – " || p_title)
    END IF
END FUNCTION

-- set label value
FUNCTION set_form_lbl(lbl_name STRING, new_text STRING )
    DEFINE g_form ui.Form
    LET g_form = ui.Window.getCurrent().getForm()
    
    # Set the text for the specified label element
    # The element must exist in the form (.per file)
    CALL g_form.setElementText(lbl_name, new_text)

END FUNCTION    
