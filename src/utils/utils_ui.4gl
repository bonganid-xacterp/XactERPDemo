# ==============================================================
# Program   :   utils_ui.4gl
# Purpose   :   Utilities for shared UI components (dialogs, helpers)
# Module    :   Utilities
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.20
# ==============================================================

IMPORT ui

-- =============================================================
-- Generic single-button popup (informational only)
-- style_name: "alert", "info", "warning", "error"
-- =============================================================
FUNCTION show_message(p_message STRING, p_title STRING, style_name STRING)
    DEFINE l_title STRING
    DEFINE f ui.Form

    IF p_title IS NULL OR p_title = "" THEN
        LET l_title = "Message"
    ELSE
        LET l_title = p_title
    END IF

    OPEN WINDOW w_msg
        WITH
        FORM "utils_alert_form"
        ATTRIBUTES(STYLE = style_name, TEXT = l_title)

    -- Get current form and set message text
    LET f = ui.Window.getCurrent().getForm()
    CALL f.setElementText("alert_message", p_message)

    MENU l_title ATTRIBUTE(STYLE = "dialog")
        COMMAND "OK"
            EXIT MENU
    END MENU

    CLOSE WINDOW w_msg
END FUNCTION

-- =============================================================
-- Specific wrappers for message types
-- =============================================================
FUNCTION show_alert(p_message STRING, p_title STRING)
    CALL show_message(p_message, p_title, "alert")
END FUNCTION

FUNCTION show_info(p_message STRING, p_title STRING)
    CALL show_message(p_message, p_title, "info")
END FUNCTION

FUNCTION show_warning(p_message STRING, p_title STRING)
    CALL show_message(p_message, p_title, "warning")
END FUNCTION

FUNCTION show_error(p_message STRING, p_title STRING)
    CALL show_message(p_message, p_title, "error")
END FUNCTION

-- =============================================================
-- Confirmation dialog (Yes/No) - returns TRUE or FALSE
-- =============================================================
FUNCTION show_confirm(p_message STRING, p_title STRING) RETURNS SMALLINT
    DEFINE l_title STRING
    DEFINE result SMALLINT
    DEFINE f ui.Form

    -- Default title
    IF p_title IS NULL OR p_title = "" THEN
        LET l_title = "Confirm"
    ELSE
        LET l_title = p_title
    END IF

    -- Open the confirmation dialog window
--    OPEN WINDOW w_confirm
--        WITH
--        FORM "utils_alert_form"
--        ATTRIBUTES(STYLE = "dialog", TEXT = l_title)
--
--    -- Get current form handle
    LET f = ui.Window.getCurrent().getForm()
--
--    -- Set the message text in the form label/textedit
    CALL f.setElementText("alert_message", p_message)

    MENU l_title ATTRIBUTE(STYLE = "dialog")
        COMMAND "Yes"
            LET result = TRUE
            EXIT MENU
        COMMAND "No"
            LET result = FALSE
            EXIT MENU
    END MENU

    -- CLOSE WINDOW w_confirm
    RETURN result
END FUNCTION

-- =============================================================
-- Other helpers
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
