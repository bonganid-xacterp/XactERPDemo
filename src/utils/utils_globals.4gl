# ==============================================================
# Consolidated Global Utilities
# File: utils_globals.4gl
# Purpose: Single source of truth for all utility functions
# Version: 2.0.0
# ==============================================================

IMPORT ui
IMPORT FGL fgldialog
IMPORT FGL utils_db

-- ==============================================================
-- GLOBALS
-- ==============================================================
GLOBALS
    DEFINE g_debug_mode SMALLINT
    DEFINE g_user_authenticated SMALLINT
END GLOBALS

-- ==============================================================
-- CONSTANTS
-- ==============================================================
CONSTANT APP_NAME = "XACT DEMO System"
CONSTANT APP_VERSION = "2.0.0"
CONSTANT STYLE_FILE = "main_styles.4st"

-- Message constants
CONSTANT MSG_NO_RECORD = "No records found."
CONSTANT MSG_SAVED = "Record saved successfully."
CONSTANT MSG_UPDATED = "Record updated successfully."
CONSTANT MSG_DELETED = "Record deleted successfully."
CONSTANT MSG_EOL = "End of list."
CONSTANT MSG_SOL = "Start of list."
CONSTANT MSG_NO_SEARCH = "Enter account code or name to search."
CONSTANT MSG_CONFIRM_DELETE = "Do you want to delete this record?"
CONSTANT MSG_ERROR_DUPLICATES = "Duplicate record was found."
CONSTANT MSG_CONFIRM_EXIT = "You are about to close the application, continue ?"

-- Status constants
PUBLIC CONSTANT STATUS_ACTIVE = 1
PUBLIC CONSTANT STATUS_INACTIVE = 0
PUBLIC CONSTANT STATUS_ARCHIVED = -1

-- ==============================================================
-- PUBLIC TYPE DEFINITIONS
-- ==============================================================
PUBLIC TYPE r_lookup_result RECORD
    code STRING,
    description STRING,
    field3 STRING,
    field4 STRING,
    field5 STRING
END RECORD

PUBLIC TYPE master_record RECORD
    table_name STRING,
    key_field STRING,
    name_field STRING,
    phone_field STRING,
    email_field STRING
END RECORD

-- ==============================================================
-- APPLICATION INITIALIZATION
-- ==============================================================
PUBLIC FUNCTION initialize_application() RETURNS BOOLEAN
    DEFINE db_result SMALLINT

    LET g_debug_mode = FALSE
    LET g_user_authenticated = FALSE

    -- Hide default screen and disable Ctrl+C
    DEFER INTERRUPT
    CLOSE WINDOW SCREEN

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
-- GLOBAL EDIT MODE  FUNCTIONS
-- Function : set_view_mode
-- Purpose  : Enables view-only actions; disables editing actions
-- ==============================================================

PUBLIC FUNCTION set_view_mode()
    DEFINE dlg ui.Dialog
    LET dlg = ui.Dialog.getCurrent()

    IF dlg IS NULL THEN
        RETURN
    END IF

    CALL dlg.setActionActive("find", TRUE)
    -- Disable editing actions
    CALL dlg.setActionActive("save", FALSE)
    CALL dlg.setActionActive("cancel", FALSE)

    -- Enable navigation and lookup actions
    CALL dlg.setActionActive("edit", TRUE)
    CALL dlg.setActionActive("new", TRUE)
    CALL dlg.setActionActive("delete", TRUE)
    CALL dlg.setActionActive("previous", TRUE)
    CALL dlg.setActionActive("next", TRUE)
END FUNCTION

-- ==============================================================
-- Function : set_edit_mode
-- Purpose  : Enables editing actions; disables non-edit actions
-- ==============================================================

PUBLIC FUNCTION set_edit_mode()
    DEFINE dlg ui.Dialog
    LET dlg = ui.Dialog.getCurrent()

    IF dlg IS NULL THEN
        RETURN
    END IF

    CALL dlg.setActionActive("find", FALSE)

    -- Enable save and cancel
    CALL dlg.setActionActive("save", TRUE)
    CALL dlg.setActionActive("cancel", TRUE)

    -- Disable actions that should not be used during edit
    CALL dlg.setActionActive("edit", FALSE)
    CALL dlg.setActionActive("new", FALSE)
    CALL dlg.setActionActive("delete", FALSE)
    CALL dlg.setActionActive("previous", FALSE)
    CALL dlg.setActionActive("next", FALSE)
END FUNCTION

-- ==============================================================
-- Function : set_new_mode
-- Purpose  : Prepares form for new record creation
-- ==============================================================

PUBLIC FUNCTION set_new_mode()
    DEFINE dlg ui.Dialog
    LET dlg = ui.Dialog.getCurrent()

    IF dlg IS NULL THEN
        RETURN
    END IF

    CALL dlg.setActionActive("find", FALSE)
    -- Enable save and cancel
    CALL dlg.setActionActive("save", TRUE)
    CALL dlg.setActionActive("cancel", TRUE)

    -- Disable or hide irrelevant actions
    CALL dlg.setActionActive("edit", FALSE)
    CALL dlg.setActionActive("delete", FALSE)

    CALL dlg.setActionActive("previous", FALSE)
    CALL dlg.setActionActive("next", FALSE)
END FUNCTION

-- ==============================================================
-- MESSAGE FUNCTIONS
-- ==============================================================

-- Base message function
PUBLIC FUNCTION show_message(message STRING, message_type STRING, title STRING)
    DEFINE icon STRING
    DEFINE window_title STRING

    LET window_title = IIF(title IS NULL, "Message", title)

    CASE message_type
        WHEN "info"
            LET icon = "information"
        WHEN "warning"
            LET icon = "exclamation"
        WHEN "error"
            LET icon = "stop"
        WHEN "question"
            LET icon = "question"
        OTHERWISE
            LET icon = "information"
    END CASE

    CALL fgldialog.fgl_winmessage(window_title, message, icon)
END FUNCTION

-- Simplified message wrappers
PUBLIC FUNCTION show_info(msg STRING)
    CALL show_message(msg, "info", "Information")
END FUNCTION

PUBLIC FUNCTION show_warning(msg STRING)
    CALL show_message(msg, "warning", "Warning")
END FUNCTION

PUBLIC FUNCTION show_error(msg STRING)
    CALL show_message(msg, "error", "Error")
END FUNCTION

PUBLIC FUNCTION show_success(msg STRING)
    CALL show_message(msg, "info", "Success")
END FUNCTION

-- Confirmation dialog
PUBLIC FUNCTION show_confirm(message STRING, title STRING) RETURNS BOOLEAN
    DEFINE answer STRING
    LET title = IIF(title IS NULL, "Confirm", title)
    LET answer =
        fgldialog.fgl_winQuestion(title, message, "no", "yes|no", "question", 0)
    RETURN (answer = "yes")
END FUNCTION

-- Standard constant message functions
PUBLIC FUNCTION msg_no_record()
    CALL show_info(MSG_NO_RECORD)
END FUNCTION

PUBLIC FUNCTION msg_saved()
    CALL show_info(MSG_SAVED)
END FUNCTION

PUBLIC FUNCTION msg_updated()
    CALL show_info(MSG_UPDATED)
END FUNCTION

PUBLIC FUNCTION msg_deleted()
    CALL show_info(MSG_DELETED)
END FUNCTION

PUBLIC FUNCTION msg_end_of_list()
    CALL show_info(MSG_EOL)
END FUNCTION

PUBLIC FUNCTION msg_start_of_list()
    CALL show_info(MSG_SOL)
END FUNCTION

PUBLIC FUNCTION msg_no_search()
    CALL show_info(MSG_NO_SEARCH)
END FUNCTION

PUBLIC FUNCTION msg_error_duplicates()
    CALL show_error(MSG_ERROR_DUPLICATES)
END FUNCTION

PUBLIC FUNCTION msg_confirm_delete() RETURNS BOOLEAN
    RETURN show_confirm(MSG_CONFIRM_DELETE, "Delete Record")
END FUNCTION

PUBLIC FUNCTION msg_confirm_exit() RETURNS BOOLEAN
    RETURN show_confirm(MSG_CONFIRM_EXIT, "Warning")
END FUNCTION

-- ==============================================================
-- FORMAT FUNCTIONS
-- ==============================================================

-- Single format function for decimals
PUBLIC FUNCTION format_decimal(value DECIMAL, pattern STRING) RETURNS STRING
    RETURN (NVL(value, 0) USING pattern)
END FUNCTION

PUBLIC FUNCTION format_currency(amount DECIMAL) RETURNS STRING
    RETURN format_decimal(amount, "---,---,--&.&&")
END FUNCTION

PUBLIC FUNCTION format_quantity(qty DECIMAL) RETURNS STRING
    RETURN format_decimal(qty, "---,---,--&.&&")
END FUNCTION

-- Date formatting
PUBLIC FUNCTION format_date(p_date DATE) RETURNS STRING
    RETURN IIF(p_date IS NULL, "", p_date USING "dd/mm/yyyy")
END FUNCTION

PUBLIC FUNCTION format_date_time(
    date_time DATETIME YEAR TO SECOND)
    RETURNS STRING
    RETURN IIF(date_time IS NULL, "", date_time USING "dd/mm/yyyy hh:mm:ss")
END FUNCTION

-- ==============================================================
-- VALIDATION FUNCTIONS
-- ==============================================================

PUBLIC FUNCTION is_empty(str STRING) RETURNS BOOLEAN
    RETURN (str IS NULL OR LENGTH(str.trim()) = 0)
END FUNCTION

PUBLIC FUNCTION trim_string(str STRING) RETURNS STRING
    RETURN IIF(str IS NULL, "", str.trim())
END FUNCTION

PUBLIC FUNCTION is_valid_email(email STRING) RETURNS BOOLEAN
    RETURN (email IS NOT NULL AND email MATCHES "*@*.*")
END FUNCTION

PUBLIC FUNCTION is_valid_phone(phone STRING) RETURNS BOOLEAN
    DEFINE clean_phone STRING

    IF phone IS NULL OR phone = "" THEN
        RETURN FALSE
    END IF

    LET clean_phone = trim_string(phone)
    -- Check for exactly 10 digits only (no other characters)
    RETURN (clean_phone
        MATCHES "[0-9]{11}")
END FUNCTION

-- Generic field validation for master records
PUBLIC FUNCTION validate_master_fields(
    acc_code STRING, name STRING, email STRING, phone STRING)
    RETURNS BOOLEAN
    -- Required field validation
    IF is_empty(acc_code) THEN
        CALL show_error("Account Code is required.")
        RETURN FALSE
    END IF

    IF is_empty(name) THEN
        CALL show_error("Name is required.")
        RETURN FALSE
    END IF

    -- Format validation
    IF NOT is_empty(email) AND NOT is_valid_email(email) THEN
        CALL show_error("Invalid email format.")
        RETURN FALSE
    END IF

    IF NOT is_empty(phone) AND NOT is_valid_phone(phone) THEN
        CALL show_error("Invalid phone format. Must be 10 digits.")
        RETURN FALSE
    END IF

    RETURN TRUE
END FUNCTION

-- ==============================================================
-- UI UTILITIES
-- ==============================================================

PUBLIC FUNCTION set_page_title(title STRING)
    DEFINE w ui.Window
    LET w = ui.Window.getCurrent()
    IF w IS NOT NULL THEN
        CALL w.setText(APP_NAME || " - " || title)
    END IF
END FUNCTION

PUBLIC FUNCTION set_form_label(label_name STRING, text STRING)
    DEFINE f ui.Form
    LET f = ui.Window.getCurrent().getForm()
    CALL f.setElementText(label_name, text)
END FUNCTION

PUBLIC FUNCTION set_fields_visibility(
    fields DYNAMIC ARRAY OF STRING, hidden BOOLEAN)
    DEFINE f ui.Form
    DEFINE i INTEGER

    LET f = ui.Window.getCurrent().getForm()
    FOR i = 1 TO fields.getLength()
        CALL f.setFieldHidden(fields[i], hidden)
    END FOR
END FUNCTION

-- Status combobox population
PUBLIC FUNCTION populate_status_combo(field_name STRING)
    DEFINE cb ui.ComboBox

    LET cb = ui.ComboBox.forName(field_name)
    IF cb IS NOT NULL THEN
        CALL cb.clear()
        CALL cb.addItem(STATUS_ACTIVE, "Active")
        CALL cb.addItem(STATUS_INACTIVE, "Inactive")
        CALL cb.addItem(STATUS_ARCHIVED, "Archived")
    END IF
END FUNCTION

-- Get status description
PUBLIC FUNCTION get_status_description(code SMALLINT) RETURNS STRING
    CASE code
        WHEN STATUS_ACTIVE
            RETURN "Active"
        WHEN STATUS_INACTIVE
            RETURN "Inactive"
        WHEN STATUS_ARCHIVED
            RETURN "Archived"
        OTHERWISE
            RETURN "Unknown"
    END CASE
END FUNCTION

-- ==============================================================
-- DATABASE UTILITIES
-- ==============================================================

-- Single database connection function
PUBLIC FUNCTION connect_database() RETURNS BOOLEAN
    TRY
        CONNECT TO "demoapp_db@localhost:5432+driver='dbmpgs_9'"
            USER "postgres" USING "napoleon"
        RETURN TRUE
    CATCH
        CALL show_error("Database connection failed: " || SQLCA.SQLERRM)
        RETURN FALSE
    END TRY
END FUNCTION

PUBLIC FUNCTION disconnect_database() RETURNS BOOLEAN
    TRY
        DISCONNECT CURRENT
        RETURN TRUE
    CATCH
        RETURN FALSE
    END TRY
END FUNCTION

-- Transaction management
PUBLIC FUNCTION execute_transaction(operation STRING) RETURNS BOOLEAN
    TRY
        CASE operation
            WHEN "BEGIN"
                BEGIN WORK
            WHEN "COMMIT"
                COMMIT WORK
            WHEN "ROLLBACK"
                ROLLBACK WORK
        END CASE
        RETURN TRUE
    CATCH
        CALL show_error(
            "Transaction " || operation || " failed: " || SQLCA.SQLERRM)
        RETURN FALSE
    END TRY
END FUNCTION

-- ==============================================================
-- LOOKUP UTILITIES
-- ==============================================================

-- Generic lookup function (replaces multiple specific lookup functions)
PUBLIC FUNCTION generic_lookup(
    table_name STRING,
    code_field STRING,
    desc_field STRING,
    search_value STRING,
    title STRING,
    return_field STRING)
    RETURNS STRING

    DEFINE sql STRING
    DEFINE results DYNAMIC ARRAY OF r_lookup_result
    DEFINE selected_index INTEGER
    DEFINE where_clause STRING

    -- Build WHERE clause if search value provided
    IF NOT is_empty(search_value) THEN
        LET where_clause =
            " WHERE "
                || code_field
                || " ILIKE '%"
                || search_value
                || "%' OR "
                || desc_field
                || " ILIKE '%"
                || search_value
                || "%'"
    ELSE
        LET where_clause = ""
    END IF

    LET sql =
        "SELECT "
            || code_field
            || ", "
            || desc_field
            || " FROM "
            || table_name
            || where_clause
            || " ORDER BY "
            || code_field

    CALL execute_lookup_query(sql, results)

    IF results.getLength() > 0 THEN
        LET selected_index = display_lookup_dialog(results, title)
        IF selected_index > 0 THEN
            CASE return_field
                WHEN "code"
                    RETURN results[selected_index].code
                WHEN "description"
                    RETURN results[selected_index].description
                OTHERWISE
                    RETURN results[selected_index].code
            END CASE
        END IF
    END IF

    RETURN ""
END FUNCTION

-- Specific lookup wrappers
PUBLIC FUNCTION lookup_debtor(search STRING) RETURNS STRING
    RETURN generic_lookup(
        "dl01_mast", "acc_code", "name", search, "Customer Lookup", "code")
END FUNCTION

PUBLIC FUNCTION lookup_supplier(search STRING) RETURNS STRING
    RETURN generic_lookup(
        "cl01_mast", "acc_code", "name", search, "Supplier Lookup", "code")
END FUNCTION

-- Helper function for lookup queries
PRIVATE FUNCTION execute_lookup_query(
    sql STRING, results DYNAMIC ARRAY OF r_lookup_result)
    DEFINE idx INTEGER
    LET idx = 0

    TRY
        DECLARE lookup_cursor CURSOR FROM sql
        FOREACH lookup_cursor
            INTO results[idx + 1].code, results[idx + 1].description
            LET idx = idx + 1
        END FOREACH
        CLOSE lookup_cursor
        FREE lookup_cursor
    CATCH
        CALL show_error("Lookup query failed: " || SQLCA.SQLERRM)
    END TRY
END FUNCTION

PRIVATE FUNCTION display_lookup_dialog(
    results DYNAMIC ARRAY OF r_lookup_result, title STRING)
    RETURNS INTEGER
    -- Simplified dialog implementation
    IF g_debug_mode THEN
        DISPLAY "Lookup dialog: ", title
    END IF
    -- In real implementation, would show proper lookup form
    IF results.getLength() = 1 THEN
        RETURN 1 -- Auto-select if only one result
    END IF

    -- For now, return first result
    RETURN IIF(results.getLength() > 0, 1, 0)
END FUNCTION

-- ==============================================================
-- MASTER CRUD UTILITIES
-- ==============================================================

-- Generic navigation
PUBLIC FUNCTION navigate_records(
    codes DYNAMIC ARRAY OF STRING, current_index INTEGER, direction SMALLINT)
    RETURNS INTEGER
    DEFINE new_index INTEGER

    CASE direction
        WHEN -2 -- First
            LET new_index = 1
        WHEN -1 -- Previous
            IF current_index > 1 THEN
                LET new_index = current_index - 1
            ELSE
                CALL msg_start_of_list()
                RETURN current_index
            END IF
        WHEN 1 -- Next
            IF current_index < codes.getLength() THEN
                LET new_index = current_index + 1
            ELSE
                CALL msg_end_of_list()
                RETURN current_index
            END IF
        WHEN 2 -- Last
            LET new_index = codes.getLength()
    END CASE

    RETURN new_index
END FUNCTION

-- Generic record selection
PUBLIC FUNCTION select_records(master master_record, where_clause STRING)
    DEFINE codes DYNAMIC ARRAY OF STRING
    DEFINE code STRING
    DEFINE idx INTEGER
    DEFINE sql STRING

    CALL codes.clear()
    LET idx = 0
    LET sql =
        "SELECT "
            || master.key_field
            || " FROM "
            || master.table_name
            || " WHERE "
            || where_clause
            || " ORDER BY "
            || master.key_field

    TRY
        DECLARE c_select CURSOR FROM sql
        FOREACH c_select INTO code
            LET idx = idx + 1
            LET codes[idx] = code
        END FOREACH
        FREE c_select
    CATCH
        CALL show_error("Query failed: " || SQLCA.SQLERRM)
    END TRY

    IF codes.getLength() = 0 THEN
        CALL msg_no_record()
    END IF

    RETURN codes
END FUNCTION

-- Generic uniqueness check
PUBLIC FUNCTION check_uniqueness(
    master master_record,
    acc_code STRING,
    name STRING,
    phone STRING,
    email STRING)
    RETURNS BOOLEAN
    DEFINE count INTEGER

    -- Check account code
    IF NOT is_empty(acc_code) THEN
        LET count =
            get_field_count(master.table_name, master.key_field, acc_code)
        IF COUNT > 0 THEN
            CALL show_error("Duplicate account code already exists.")
            RETURN FALSE
        END IF
    END IF

    -- Check name
    IF NOT is_empty(name) AND NOT is_empty(master.name_field) THEN
        LET count = get_field_count(master.table_name, master.name_field, name)
        IF COUNT > 0 THEN
            CALL show_error("Name already exists.")
            RETURN FALSE
        END IF
    END IF

    -- Check phone
    IF NOT is_empty(phone) AND NOT is_empty(master.phone_field) THEN
        LET count =
            get_field_count(master.table_name, master.phone_field, phone)
        IF COUNT > 0 THEN
            CALL show_error("Phone number already exists.")
            RETURN FALSE
        END IF
    END IF

    -- Check email
    IF NOT is_empty(email) AND NOT is_empty(master.email_field) THEN
        LET count =
            get_field_count(master.table_name, master.email_field, email)
        IF COUNT > 0 THEN
            CALL show_error("Email already exists.")
            RETURN FALSE
        END IF
    END IF

    RETURN TRUE
END FUNCTION

-- Generic delete confirmation
PUBLIC FUNCTION confirm_delete(
    entity_name STRING, record_name STRING)
    RETURNS BOOLEAN
    DEFINE message STRING
    LET message = "Delete this " || entity_name || ": " || record_name || "?"
    RETURN show_confirm(message, "Confirm Delete")
END FUNCTION

-- Helper function for count queries
PRIVATE FUNCTION get_field_count(
    table_name STRING, field_name STRING, value STRING)
    RETURNS INTEGER
    DEFINE count INTEGER
    DEFINE sql STRING

    -- Skip check if field_name is empty
    IF is_empty(field_name) THEN
        RETURN 0
    END IF

    LET sql =
        "SELECT COUNT(*) FROM "
            || table_name
            || " WHERE "
            || field_name
            || " = ?"

    TRY
        PREPARE stmt_count FROM sql
        EXECUTE stmt_count USING value INTO count
        FREE stmt_count
        RETURN COUNT
    CATCH
        RETURN 0
    END TRY
END FUNCTION

-- ==============================================================
-- Utility : Document Numbering Helper
-- Author  : Bongani Dlamini
-- Version : Genero 3.20.10
-- ==============================================================

--FUNCTION doc_numbering(p_table STRING, p_field STRING, p_prefix STRING)
--    RETURNS STRING
--
--    DEFINE l_sql      STRING
--    DEFINE l_last_no  STRING
--    DEFINE l_next_no  STRING
--    DEFINE l_num_part STRING
--    DEFINE l_num      INTEGER
--
--    -- ==========================
--    -- 1. Build dynamic SQL
--    -- ==========================
--    LET l_sql = "SELECT MAX(" || p_field || ") FROM " || p_table ||
--                " WHERE " || p_field || " LIKE ?"
--
--    -- ==========================
--    -- 2. Execute dynamic SQL
--    -- ==========================
--    PREPARE stmt_doc FROM l_sql
--    EXECUTE stmt_doc USING p_prefix || '%' INTO l_last_no
--    FREE stmt_doc
--
--    IF l_last_no IS NULL OR l_last_no = "" THEN
--        -- No previous document exists
--        LET l_next_no = p_prefix || "0001"
--    ELSE
--        -- ==========================
--        -- 3. Extract numeric part
--        -- ==========================
--        LET l_num_part = l_last_no[ (length(p_prefix)+1) TO length(l_last_no) ]
--        LET l_num = l_num_part USING "#####"
--        LET l_num = l_num + 1
--
--        -- ==========================
--        -- 4. Format back to new number
--        -- ==========================
--        LET l_next_no = p_prefix || l_num USING "0000"
--    END IF
--
--    RETURN l_next_no
--END FUNCTION



-- ==============================================================
-- DB  UTILITIES
-- ==============================================================

-- Start a database transaction
FUNCTION begin_transaction() RETURNS SMALLINT
    TRY
        BEGIN WORK
        DISPLAY "Transaction started"
        RETURN TRUE
    CATCH
        DISPLAY "Error starting transaction: ", SQLCA.SQLCODE
        RETURN FALSE
    END TRY
END FUNCTION

-- Commit current transaction
FUNCTION commit_transaction() RETURNS SMALLINT
    TRY
        COMMIT WORK
        DISPLAY "Transaction committed"
        RETURN TRUE
    CATCH
        DISPLAY "Error committing transaction: ", SQLCA.SQLCODE
        RETURN FALSE
    END TRY
END FUNCTION

-- Rollback current transaction
FUNCTION rollback_transaction() RETURNS SMALLINT
    TRY
        ROLLBACK WORK
        DISPLAY "Transaction rolled back"
        RETURN TRUE
    CATCH
        DISPLAY "Error rolling back transaction: ", SQLCA.SQLCODE
        RETURN FALSE
    END TRY
END FUNCTION


-- ==============================================================
-- SQL Error Handler
-- ==============================================================

-- Displays a standardized SQL error message using global SQLCA variables.
FUNCTION show_sql_error(p_context STRING)
    DEFINE full_message STRING
    DEFINE sql_code INTEGER = SQLCA.SQLCODE
    DEFINE sql_errm STRING = SQLCA.SQLERRM
    --DEFINE sql_state STRING = SQLCA.SQLSTATE
    
    -- Check if the error is "No Data Found" or "End of Cursor" (often handled gracefully)
    IF sql_code = NOTFOUND THEN
        LET full_message = SFMT("SQL WARNING (Not Found): %1 - No records matched the query criteria.", p_context)
    ELSE
        -- Format the detailed error message
        LET full_message = SFMT(
            "Database Error: %1\n(SQLCODE: %2 / SQLSTATE: %3)\nError: %4",
            p_context,
            sql_code,
            -- sql_state,
            sql_errm
        )
    END IF

    CALL show_error(full_message)

END FUNCTION


