# ==============================================================
# Program   :   utils_ui.4gl
# Purpose   :   Utilities for shared UI components (dialogs, helpers)
# Module    :   Utilities
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.20
# ==============================================================

IMPORT ui

-- =============================================================
-- Generic single-button popup
-- style_name: "alert", "info", "warning", "error"
-- =============================================================
FUNCTION show_message(p_message STRING, p_title STRING, style_name STRING) RETURNS SMALLINT
    DEFINE l_title STRING
    DEFINE result SMALLINT

    IF p_title IS NULL OR p_title = "" THEN
        LET l_title = "Message"
    ELSE
        LET l_title = p_title
    END IF

    OPEN WINDOW w_msg WITH FORM "alert_form"
        ATTRIBUTES (STYLE=style_name, TEXT=l_title)

    MENU l_title ATTRIBUTE(STYLE="dialog")
        COMMAND "OK"
            DISPLAY p_message
            LET result = TRUE
            EXIT MENU
    END MENU

    CLOSE WINDOW w_msg
    RETURN result
END FUNCTION

-- =============================================================
-- Specific wrappers for message types
-- =============================================================
FUNCTION show_alert(p_message STRING, p_title STRING) RETURNS SMALLINT
    RETURN show_message(p_message, p_title, "alert")
END FUNCTION

FUNCTION show_info(p_message STRING, p_title STRING) RETURNS SMALLINT
    RETURN show_message(p_message, p_title, "info")
END FUNCTION

FUNCTION show_warning(p_message STRING, p_title STRING) RETURNS SMALLINT
    RETURN show_message(p_message, p_title, "warning")
END FUNCTION

FUNCTION show_error(p_message STRING, p_title STRING) RETURNS SMALLINT
    RETURN show_message(p_message, p_title, "error")
END FUNCTION

-- =============================================================
-- Confirmation dialog (Yes/No)
-- =============================================================
FUNCTION show_confirm(p_message STRING, p_title STRING) RETURNS SMALLINT
    DEFINE l_title STRING
    DEFINE result SMALLINT

    IF p_title IS NULL OR p_title = "" THEN
        LET l_title = "Confirm"
    ELSE
        LET l_title = p_title
    END IF

    OPEN WINDOW w_confirm WITH FORM "alert_form"
        ATTRIBUTES (STYLE="confirm", TEXT=l_title)

    MENU l_title ATTRIBUTE(STYLE="dialog")
        COMMAND "Yes"
            LET result = TRUE
            EXIT MENU
        COMMAND "No"
            LET result = FALSE
            EXIT MENU
    END MENU

    CLOSE WINDOW w_confirm
    RETURN result
END FUNCTION

-- =============================================================
-- Other helpers (unchanged)
-- =============================================================
FUNCTION set_page_title(p_title STRING)
    DEFINE g_win ui.Window
    LET g_win = ui.Window.getCurrent()
    IF g_win IS NOT NULL THEN
        CALL g_win.setText("XACT ERP Demo – " || p_title)
    END IF
END FUNCTION

FUNCTION set_form_lbl(lbl_name STRING, new_text STRING)
    DEFINE g_form ui.Form
    LET g_form = ui.Window.getCurrent().getForm()
    CALL g_form.setElementText(lbl_name, new_text)
END FUNCTION

-- =============================================================
-- Load child form to the parent wrapper
-- =============================================================
FUNCTION set_child_container()
    CALL ui.Interface.setContainer("mdi_wrapper")
    CALL ui.Interface.setType("child")
END FUNCTION
