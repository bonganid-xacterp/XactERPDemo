# ==============================================================
# Program   :   globals.4gl
# Purpose   :   Global variables and utility functions
# Module    :   Global
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.20.10
# ==============================================================

IMPORT ui
IMPORT FGL fgldialog

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

-- Load child form to the parent wrapper
FUNCTION set_child_container()
    CALL ui.Interface.setContainer("mdi_wrapper")
    CALL ui.Interface.setType("child")
END FUNCTION

-- Global hide screen code

FUNCTION hide_screen()
    -- Prevent CTRL+C interrupt crash
    DEFER INTERRUPT

    -- Close default SCREEN window
    CLOSE WINDOW SCREEN
END FUNCTION

-- Show message with OK button
FUNCTION show_message(p_message STRING, p_title STRING, style_name STRING)
    DEFINE l_title STRING
    DEFINE l_icon STRING
    
    LET l_title = IIF(p_title IS NULL OR p_title = "", "Message", p_title)
    
    CASE style_name
        WHEN "info"     LET l_icon = "information"
        WHEN "warning"  LET l_icon = "exclamation"
        WHEN "error"    LET l_icon = "stop"
        WHEN "question" LET l_icon = "question"
        OTHERWISE       LET l_icon = "information"
    END CASE
    
    CALL fgldialog.fgl_winmessage(l_title, p_message, l_icon)
END FUNCTION

-- ==============================================================
-- Function: show_alert
-- Purpose:  Quick alert message (convenience wrapper)
-- ==============================================================
PUBLIC FUNCTION show_alert(p_message STRING, p_title STRING)
    CALL show_message(p_message, p_title, "warning")
END FUNCTION

-- ==============================================================
-- Function: show_info
-- Purpose:  Information message
-- ==============================================================
PUBLIC FUNCTION show_info(p_message STRING)
    CALL show_message(p_message, "Information", "info")
END FUNCTION

-- ==============================================================
-- Function: show_warning
-- Purpose:  Warning message
-- ==============================================================
PUBLIC FUNCTION show_warning(p_message STRING)
    CALL show_message(p_message, "Warning", "warning")
END FUNCTION

-- ==============================================================
-- Function: show_error
-- Purpose:  Error message
-- ==============================================================
PUBLIC FUNCTION show_error(p_message STRING)
    CALL show_message(p_message, "Error", "error")
END FUNCTION

-- ==============================================================
-- Function: show_success
-- Purpose:  Success message
-- ==============================================================
PUBLIC FUNCTION show_success(p_message STRING)
    CALL show_message(p_message, "Success", "info")
END FUNCTION

-- ==============================================================
-- Function: Confirmation dialog 
-- Purpose:  Ask user for confirmation (Yes/No)
-- Returns:  TRUE if user clicked Yes, FALSE otherwise
-- ==============================================================
FUNCTION show_confirm(p_message STRING, p_title STRING)
    DEFINE l_title STRING
    DEFINE answer STRING
    
    IF p_title IS NULL OR p_title = "" THEN
        LET l_title = "Confirm"
    ELSE
        LET l_title = p_title
    END IF
    
    LET answer = fgldialog.fgl_winQuestion(l_title, p_message, 
                                  "no", "yes|no", "question", 0)
    
    RETURN (answer = "yes")
    
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
FUNCTION format_currency(p_amount DECIMAL) RETURNS STRING
    IF p_amount IS NULL THEN
        LET p_amount = 0
    END IF
    RETURN p_amount USING "---,---,--&.&&"
END FUNCTION

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

    IF LENGTH(clean_phone) < 10 OR LENGTH(clean_phone) >10 THEN
        RETURN FALSE
    END IF

    RETURN TRUE
END FUNCTION

-- handle sql errors
FUNCTION handle_sql_error()
    DEFINE errnum INTEGER
    DEFINE errmsg STRING

    LET errnum = SQLCA.SQLCODE
    LET errmsg = SQLCA.SQLERRM

    CASE errnum
        WHEN 0
            RETURN
        WHEN NOTFOUND
            CALL show_info("No more records to fetch.")
        OTHERWISE
            CALL show_error("SQL Error (" || errnum || "): " || errmsg)
    END CASE
END FUNCTION

