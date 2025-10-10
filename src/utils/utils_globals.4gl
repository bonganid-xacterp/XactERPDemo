-- ==============================================================
-- Program   : utils_globals.4gl
-- Purpose   : Global variables, constants, and utility functions
-- Module    : Utilities (Global)
-- Author    : Bongani Dlamini
-- Version   : Genero BDL 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL fgldialog
IMPORT FGL utils_db

-- ==============================================================
-- GLOBAL VARIABLES
-- ==============================================================

DEFINE g_debug_mode SMALLINT
DEFINE g_user_authenticated SMALLINT

CONSTANT APP_NAME = "XACT DEMO System"
CONSTANT APP_VERSION = "1.0.0"
CONSTANT STYLE_FILE = "main_styles.4st" -- Style file (keep in project folder)

-- ==============================================================
-- STANDARD NOTIFICATION CONSTANTS
-- ==============================================================
CONSTANT MSG_NO_RECORD     = "No records found."
CONSTANT MSG_SAVED         = "Record saved successfully."
CONSTANT MSG_UPDATED       = "Record updated successfully."
CONSTANT MSG_DELETED       = "Record deleted successfully."
CONSTANT MSG_EOL           = "End of list."
CONSTANT MSG_SOL           = "Start of list."
CONSTANT MSG_NO_SEARCH     = "Enter account code or name to search."

-- ==============================================================
-- INITIALIZATION SECTION
-- ==============================================================

PUBLIC FUNCTION initialize_application() RETURNS SMALLINT
    DEFINE db_result SMALLINT
    LET g_debug_mode = TRUE

    -- Hide default screen and disable Ctrl+C
    CALL hide_screen()

    TRY
        -- Load the visual style for the application
        CALL ui.Interface.loadStyles(STYLE_FILE)

        IF g_debug_mode THEN
            DISPLAY "Stylesheet loaded from: ", STYLE_FILE
        END IF

        -- Initialize database connection
        LET db_result = utils_db.initialize_database()

        IF NOT db_result THEN
            CALL show_error("Database initialization failed!")
            RETURN FALSE
        END IF

        LET g_user_authenticated = FALSE

        IF g_debug_mode THEN
            DISPLAY "Application initialized successfully"
            DISPLAY "Version: ", APP_VERSION
        END IF

        RETURN TRUE

    CATCH
        DISPLAY "ERROR during initialization: ", STATUS
        RETURN FALSE
    END TRY
END FUNCTION

-- ==============================================================
-- UI UTILITY FUNCTIONS
-- ==============================================================

FUNCTION hide_screen()
    DEFER INTERRUPT
    CLOSE WINDOW SCREEN
END FUNCTION

PUBLIC FUNCTION show_message(
    p_message STRING, p_title STRING, style_name STRING)
    DEFINE l_title STRING
    DEFINE l_icon STRING

    LET l_title = IIF(p_title IS NULL OR p_title = "", "Message", p_title)

    CASE style_name
        WHEN "info"
            LET l_icon = "information"
        WHEN "warning"
            LET l_icon = "exclamation"
        WHEN "error"
            LET l_icon = "stop"
        WHEN "question"
            LET l_icon = "question"
        OTHERWISE
            LET l_icon = "information"
    END CASE

    CALL fgldialog.fgl_winmessage(l_title, p_message, l_icon)
END FUNCTION

PUBLIC FUNCTION show_alert(p_message STRING, p_title STRING)
    CALL show_message(p_message, p_title, "warning")
END FUNCTION

PUBLIC FUNCTION show_info(p_message STRING)
    CALL show_message(p_message, "Information", "info")
END FUNCTION

PUBLIC FUNCTION show_warning(p_message STRING)
    CALL show_message(p_message, "Warning", "warning")
END FUNCTION

PUBLIC FUNCTION show_error(p_message STRING)
    CALL show_message(p_message, "Error", "error")
END FUNCTION

PUBLIC FUNCTION show_success(p_message STRING)
    CALL show_message(p_message, "Success", "info")
END FUNCTION

PUBLIC FUNCTION show_confirm(p_message STRING, p_title STRING) RETURNS SMALLINT
    DEFINE answer STRING
    DEFINE l_title STRING

    LET l_title = IIF(p_title IS NULL OR p_title = "", "Confirm", p_title)

    LET answer =
        fgldialog.fgl_winQuestion(
            l_title, p_message, "no", "yes|no", "question", 0)

    RETURN (answer = "yes")
END FUNCTION

FUNCTION set_page_title(p_title STRING)
    DEFINE w ui.Window
    LET w = ui.Window.getCurrent()
    IF w IS NOT NULL THEN
        CALL w.setText(APP_NAME || " - " || p_title)
    END IF
END FUNCTION

FUNCTION set_form_lbl(lbl_name STRING, new_text STRING)
    DEFINE f ui.Form
    LET f = ui.Window.getCurrent().getForm()
    CALL f.setElementText(lbl_name, new_text)
END FUNCTION

PUBLIC FUNCTION set_field_status(
    field_list DYNAMIC ARRAY OF STRING, p_hidden SMALLINT)
    DEFINE f ui.Form
    DEFINE i INTEGER

    LET f = ui.Window.getCurrent().getForm()
    FOR i = 1 TO field_list.getLength()
        CALL f.setFieldHidden(field_list[i], p_hidden)
    END FOR
END FUNCTION

-- ==============================================================
-- STANDARD NOTIFICATION MESSAGE FUNCTIONS
-- ==============================================================

PUBLIC FUNCTION get_msg_no_record()
    CALL show_info(MSG_NO_RECORD)
END FUNCTION

PUBLIC FUNCTION get_msg_saved()
    CALL show_info(MSG_SAVED)
END FUNCTION
PUBLIC FUNCTION get_msg_updated()
    CALL show_info(MSG_UPDATED)
END FUNCTION

PUBLIC FUNCTION get_msg_deleted()
    CALL show_info(MSG_DELETED)
END FUNCTION

PUBLIC FUNCTION get_msg_eol()
    CALL show_info(MSG_EOL)
END FUNCTION

PUBLIC FUNCTION get_msg_sol()
    CALL show_info(MSG_SOL)
END FUNCTION

PUBLIC FUNCTION get_msg_no_search()
    CALL show_info(MSG_NO_SEARCH)
END FUNCTION


-- ==============================================================
-- DATE/TIME UTILITIES
-- ==============================================================

FUNCTION format_date(p_date DATE) RETURNS STRING
    RETURN IIF(p_date IS NULL, "", p_date USING "dd/mm/yyyy")
END FUNCTION

FUNCTION format_datetime(p_datetime DATETIME YEAR TO SECOND) RETURNS STRING
    RETURN IIF(p_datetime IS NULL, "", p_datetime USING "dd/mm/yyyy hh:mm:ss")
END FUNCTION

FUNCTION get_timestamp() RETURNS DATETIME YEAR TO SECOND
    RETURN CURRENT YEAR TO SECOND
END FUNCTION

-- ==============================================================
-- NUMBER FORMAT UTILITIES
-- ==============================================================

FUNCTION format_currency(p_amount DECIMAL) RETURNS STRING
    RETURN (NVL(p_amount, 0) USING "---,---,--&.&&")
END FUNCTION

FUNCTION format_quantity(p_qty DECIMAL) RETURNS STRING
    RETURN (NVL(p_qty, 0) USING "---,---,--&.&&")
END FUNCTION

-- ==============================================================
-- STRING UTILITIES
-- ==============================================================

FUNCTION trim_str(p_str STRING) RETURNS STRING
    RETURN IIF(p_str IS NULL, "", p_str.trim())
END FUNCTION

FUNCTION is_empty(p_str STRING) RETURNS SMALLINT
    RETURN (p_str IS NULL OR LENGTH(p_str.trim()) = 0)
END FUNCTION

-- ==============================================================
-- VALIDATION FUNCTIONS
-- ==============================================================

FUNCTION is_valid_email(p_email STRING) RETURNS SMALLINT
    RETURN (p_email IS NOT NULL AND p_email MATCHES "*@*.*")
END FUNCTION

FUNCTION is_valid_phone(p_phone STRING) RETURNS SMALLINT
    DEFINE clean STRING
    LET clean = p_phone.trim()
    RETURN (LENGTH(clean) = 10)
END FUNCTION

-- ==============================================================
-- SQL ERROR HANDLER
-- ==============================================================

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
