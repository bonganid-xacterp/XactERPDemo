# ==============================================================
# Program   :   globals.4gl
# Purpose   :   Global variables and utility functions
# Module    :   Global
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.20.10
# ==============================================================

IMPORT ui

-- Global application variables
DEFINE g_user_id INTEGER
DEFINE g_user_name VARCHAR(50)
DEFINE g_company_id INTEGER
DEFINE g_company_name VARCHAR(100)
DEFINE g_fiscal_year INTEGER
DEFINE g_fiscal_period INTEGER

-- =============================================================
-- UI Utility Functions
-- =============================================================

-- Show message with OK button
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

    LET f = ui.Window.getCurrent().getForm()
    CALL f.setElementText("alert_message", p_message)

    MENU l_title ATTRIBUTE(STYLE = "dialog")
        COMMAND "OK"
            EXIT MENU
    END MENU

    CLOSE WINDOW w_msg
END FUNCTION

-- Alert message
FUNCTION show_alert(p_message STRING, p_title STRING)
    CALL show_message(p_message, p_title, "alert")
END FUNCTION

-- Info message
FUNCTION show_info(p_message STRING, p_title STRING)
    CALL show_message(p_message, p_title, "info")
END FUNCTION

-- Warning message
FUNCTION show_warning(p_message STRING, p_title STRING)
    CALL show_message(p_message, p_title, "warning")
END FUNCTION

-- Error message
FUNCTION show_error(p_message STRING, p_title STRING)
    CALL show_message(p_message, p_title, "error")
END FUNCTION

-- Confirmation dialog
FUNCTION show_confirm(p_message STRING, p_title STRING) RETURNS SMALLINT
    DEFINE l_title STRING
    DEFINE result SMALLINT
    DEFINE f ui.Form

    IF p_title IS NULL OR p_title = "" THEN
        LET l_title = "Confirm"
    ELSE
        LET l_title = p_title
    END IF

    OPEN WINDOW w_confirm
        WITH
        FORM "utils_alert_form"
        ATTRIBUTES(STYLE = "dialog", TEXT = l_title)

    LET f = ui.Window.getCurrent().getForm()
    CALL f.setElementText("alert_message", p_message)

    MENU l_title ATTRIBUTE(STYLE = "dialog")
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

-- Set window title
FUNCTION set_page_title(p_title STRING)
    DEFINE g_win ui.Window
    LET g_win = ui.Window.getCurrent()
    IF g_win IS NOT NULL THEN
        CALL g_win.setText("XACT ERP – " || p_title)
    END IF
END FUNCTION

-- Set form label text
FUNCTION set_form_lbl(lbl_name STRING, new_text STRING)
    DEFINE g_form ui.Form
    LET g_form = ui.Window.getCurrent().getForm()
    CALL g_form.setElementText(lbl_name, new_text)
END FUNCTION

-- =============================================================
-- Date/Time Functions
-- =============================================================

-- Format date as DD/MM/YYYY
FUNCTION format_date(p_date DATE) RETURNS STRING
    IF p_date IS NULL THEN
        RETURN ""
    END IF
    RETURN p_date USING "dd/mm/yyyy"
END FUNCTION

-- Format datetime
FUNCTION format_datetime(p_datetime DATETIME YEAR TO SECOND) RETURNS STRING
    IF p_datetime IS NULL THEN
        RETURN ""
    END IF
    RETURN p_datetime USING "dd/mm/yyyy hh:mm:ss"
END FUNCTION

-- Get current timestamp
FUNCTION get_timestamp() RETURNS DATETIME YEAR TO SECOND
    RETURN CURRENT YEAR TO SECOND
END FUNCTION

-- =============================================================
-- Number Formatting
-- =============================================================

-- Format currency
--FUNCTION format_currency(p_amount DECIMAL) RETURNS STRING
--    IF p_amount IS NULL THEN
--        LET p_amount = 0
--    END IF
--    -- RETURN "R ", p_amount USING "---,---,--&.&&"
--END FUNCTION

-- Format quantity
FUNCTION format_quantity(p_qty DECIMAL) RETURNS STRING
    IF p_qty IS NULL THEN
        LET p_qty = 0
    END IF
    RETURN p_qty USING "---,---,--&.&&"
END FUNCTION

-- =============================================================
-- String Functions
-- =============================================================

-- Trim string
FUNCTION trim_str(p_str STRING) RETURNS STRING
    IF p_str IS NULL THEN
        RETURN ""
    END IF
    RETURN p_str.trim()
END FUNCTION

-- Check if string is empty
FUNCTION is_empty(p_str STRING) RETURNS SMALLINT
    IF p_str IS NULL THEN
        RETURN TRUE
    END IF
    IF LENGTH(p_str.trim()) = 0 THEN
        RETURN TRUE
    END IF
    RETURN FALSE
END FUNCTION

-- =============================================================
-- Validation Functions
-- =============================================================

-- Validate email
FUNCTION is_valid_email(p_email STRING) RETURNS SMALLINT
    IF p_email IS NULL THEN
        RETURN FALSE
    END IF

    -- Basic validation
    IF p_email NOT MATCHES "*@*.*" THEN
        RETURN FALSE
    END IF

    RETURN TRUE
END FUNCTION

-- Validate phone number
FUNCTION is_valid_phone(p_phone STRING) RETURNS SMALLINT
    DEFINE clean_phone STRING

    IF p_phone IS NULL THEN
        RETURN FALSE
    END IF

    -- Remove spaces and dashes
    LET clean_phone = p_phone.trim()

    IF LENGTH(clean_phone) < 10 THEN
        RETURN FALSE
    END IF

    RETURN TRUE
END FUNCTION
