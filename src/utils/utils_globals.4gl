# ==============================================================
# Consolidated Global Utilities
# File: utils_globals.4gl
#
# Version: 2.0.0
# ==============================================================

IMPORT ui
IMPORT FGL utils_db
IMPORT FGL fgldialog
IMPORT util

-- ==============================================================
-- GLOBALS
-- ==============================================================
GLOBALS
    DEFINE g_debug_mode SMALLINT
    DEFINE g_user_authenticated SMALLINT
    DEFINE g_current_user STRING
    DEFINE g_standalone_mode
        SMALLINT -- TRUE if module running standalone, FALSE if in MDI
    DEFINE g_currency_symbol STRING -- currency prefix
END GLOBALS

-- ==============================================================
-- CONSTANTS
-- ==============================================================
CONSTANT APP_NAME = "XACT DEMO System"
CONSTANT APP_VERSION = "2.0.0"
CONSTANT STYLE_FILE = "main_styles.4st"

-- Message constants
-- Message constants - Standard Operations
CONSTANT MSG_NO_RECORD = "No records found matching your criteria."
CONSTANT MSG_SAVED = "Record has been saved successfully."
CONSTANT MSG_UPDATED = "Record has been updated successfully."
CONSTANT MSG_DELETED = "Record has been deleted successfully."
CONSTANT MSG_ERROR_SAVE = "Unable to save record. Please try again."
CONSTANT MSG_ERROR_UPDATE = "Unable to update record. Please try again."
CONSTANT MSG_ERROR_DELETE = "Unable to delete record. Please try again."
CONSTANT MSG_ERROR_LOAD = "Unable to load record. Please try again."

-- Message constants - Navigation
CONSTANT MSG_EOL = "End of list reached."
CONSTANT MSG_SOL = "Beginning of list reached."
CONSTANT MSG_NO_NEXT = "No more records available."
CONSTANT MSG_NO_PREVIOUS = "No previous records available."
CONSTANT MSG_RECORD_OF = "Record %1 of %2"
CONSTANT MSG_LOADING = "Loading records, please wait..."

-- Message constants - Search & Validation
CONSTANT MSG_NO_SEARCH = "Please enter an account code or name to search."
CONSTANT MSG_SEARCH_RESULTS = "%1 record(s) found."
CONSTANT MSG_INVALID_INPUT = "Invalid input. Please check your entry."
CONSTANT MSG_REQUIRED_FIELD = "This field is required."
CONSTANT MSG_INVALID_FORMAT = "Invalid format. Please check your entry."
CONSTANT MSG_VALUE_OUT_RANGE = "Value is out of acceptable range."

-- Message constants - Confirmations
CONSTANT MSG_CONFIRM_DELETE = "Are you sure you want to delete this record?"
CONSTANT MSG_CONFIRM_EXIT =
    "You have unsaved changes. Do you want to exit anyway?"
CONSTANT MSG_CONFIRM_CANCEL =
    "Are you sure you want to cancel? Any unsaved changes will be lost."
CONSTANT MSG_CONFIRM_OVERWRITE =
    "A record with this key already exists. Do you want to overwrite it?"
CONSTANT MSG_CONFIRM_PROCEED = "Do you want to proceed with this action?"

-- Message constants - Errors & Warnings
CONSTANT MSG_ERROR_DUPLICATES =
    "A duplicate record already exists in the system."
CONSTANT MSG_ERROR_DUPLICATE_KEY =
    "This %1 is already in use. Please enter a unique value."
CONSTANT MSG_DELETE_FAILED =
    "Record deletion failed. The operation has been rolled back."
CONSTANT MSG_SAVE_FAILED =
    "Record save failed. The operation has been rolled back."
CONSTANT MSG_UPDATE_FAILED =
    "Record update failed. The operation has been rolled back."
CONSTANT MSG_ERROR_DATABASE =
    "Database error occurred. Please contact your system administrator."
CONSTANT MSG_ERROR_NETWORK =
    "Network connection error. Please check your connection."
CONSTANT MSG_ERROR_PERMISSION =
    "You do not have permission to perform this action."
CONSTANT MSG_ERROR_LOCKED = "This record is currently locked by another user."
CONSTANT MSG_ERROR_NOT_FOUND = "The requested record could not be found."

-- Message constants - Warnings
CONSTANT MSG_WARN_UNSAVED = "You have unsaved changes."
CONSTANT MSG_WARN_READONLY = "This record is read-only and cannot be modified."
CONSTANT MSG_WARN_INACTIVE = "This record is marked as inactive."
CONSTANT MSG_WARN_EXPIRED = "This record has expired."

-- Message constants - Success Operations
CONSTANT MSG_OPERATION_COMPLETE = "Operation completed successfully."
CONSTANT MSG_RECORDS_IMPORTED = "%1 record(s) imported successfully."
CONSTANT MSG_RECORDS_EXPORTED = "%1 record(s) exported successfully."
CONSTANT MSG_BATCH_COMPLETE =
    "Batch operation completed: %1 successful, %2 failed."

-- Message constants - General UI
CONSTANT MSG_PROCESSING = "Processing, please wait..."
CONSTANT MSG_READY = "Ready"
CONSTANT MSG_CANCELED = "Operation canceled."
CONSTANT MSG_TIMEOUT = "Operation timed out. Please try again."
CONSTANT MSG_NO_DATA = "No data available to display."
CONSTANT MSG_SELECT_RECORD = "Please select a record first."

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

    -- Detect standalone mode: TRUE if no current window exists
    LET g_standalone_mode = (ui.Window.getCurrent() IS NULL)

    -- Hide default screen and disable Ctrl+C
    DEFER INTERRUPT
    CLOSE WINDOW SCREEN

    TRY
        -- Load the visual style for the application
        CALL ui.Interface.loadStyles(STYLE_FILE)

        -- Load the top menu
        CALL ui.Interface.loadTopmenu("main_topmenu")


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
-- STANDALONE MODE FUNCTIONS
-- ==============================================================

-- Check if module is running in standalone mode (detects based on window)
PUBLIC FUNCTION is_standalone() RETURNS SMALLINT
    RETURN g_standalone_mode
END FUNCTION

-- Set standalone mode (called by modules)
PUBLIC FUNCTION set_standalone_mode(p_standalone SMALLINT)
    LET g_standalone_mode = p_standalone
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
PUBLIC FUNCTION show_message(
    p_message STRING, message_type STRING, title STRING)
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

    CALL fgldialog.fgl_winmessage(window_title, p_message, icon)
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
    DEFINE answer SMALLINT
    LET title = IIF(title IS NULL, "Confirm", title)

    MENU title ATTRIBUTES(STYLE = "dialog", COMMENT = message)
        COMMAND "Yes"
            LET answer = TRUE
            EXIT MENU
        COMMAND "No"
            LET answer = FALSE
            EXIT MENU
    END MENU

    RETURN answer
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

PUBLIC FUNCTION msg_delete_failed()
    CALL show_info(MSG_DELETE_FAILED)
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
    DEFINE l_formatted STRING

    LET l_formatted = "R ", amount USING "---,--&.&&"
    RETURN l_formatted

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

{--------------------------------------------------------------------
  Apply formatting based on each FormField's "tag" attribute.
  Tags supported:
    currency  -> picture + right justify (numeric widgets)
    date      -> format dd/mm/yyyy       (DateEdit/Edit)
    datetime  -> format dd/mm/yyyy hh:mi (DateEdit/Edit)
  Call this immediately after: OPEN WINDOW ... WITH FORM "..."
---------------------------------------------------------------------}
PUBLIC FUNCTION apply_field_formatting() RETURNS SMALLINT
    DEFINE win ui.Window
    DEFINE form ui.Form
    DEFINE root om.DomNode
    DEFINE fields om.NodeList
    DEFINE fld om.DomNode
    DEFINE w om.DomNode
    DEFINE i INTEGER
    DEFINE tag, dtype, nm STRING
    
    LET win = ui.Window.getCurrent()
    IF win IS NULL THEN RETURN 0 END IF
    
    LET form = win.getForm()
    IF form IS NULL THEN RETURN 0 END IF
    
    LET root = form.getNode()
    IF root IS NULL THEN RETURN 0 END IF
    
    LET fields = root.selectByTagName("FormField")
    
    FOR i = 1 TO fields.getLength()
        LET fld = fields.item(i)
        
        -- Find the concrete widget under the FormField
        LET w = first_widget_child(fld)
        IF w IS NULL THEN
            CONTINUE FOR
        END IF
        
        -- Prefer widget.tag (your debug shows it is set there)
        LET tag = w.getAttribute("tag")
        IF tag IS NULL OR tag.trim() = "" THEN
            LET tag = fld.getAttribute("tag")
        END IF
        IF tag IS NULL THEN LET tag = "" END IF
        LET tag = tag.trim().toLowerCase()
        
        IF tag = "" THEN
            CONTINUE FOR
        END IF
        
        LET dtype = fld.getAttribute("dataType")
        IF dtype IS NULL THEN LET dtype = "" END IF
        LET dtype = dtype.trim().toUpperCase()
        
        LET nm = fld.getAttribute("name")
        IF nm IS NULL THEN LET nm = "(unnamed)" END IF
        
        CASE tag
            WHEN "currency"
                -- Only apply to numeric types
                IF dtype = "" OR dtype MATCHES "DECIMAL*" OR dtype MATCHES "NUMERIC*" OR 
                   dtype MATCHES "FLOAT*" OR dtype MATCHES "MONEY*" OR
                   dtype = "INTEGER" OR dtype = "SMALLINT" THEN
                    CALL w.setAttribute("picture", "R <<<<,<<<,<<<,<<&.&&")
                    CALL w.setAttribute("numAlign", "1")
                    -- Set picture on FormField too (this is valid)
                    CALL fld.setAttribute("picture", "R <<<<,<<<,<<<,<<&.&&")
                END IF
                
            WHEN "date"
                -- Only set format on widget, NOT on FormField
                CALL w.setAttribute("format", "dd/mm/yyyy")
                
            WHEN "datetime"
                -- Only set format on widget, NOT on FormField
                CALL w.setAttribute("format", "dd/mm/yyyy hh:mi")
        END CASE
        
        -- Debug to verify what actually got set
        DISPLAY "Formatted ", nm, " [", tag, "]",
                " picture=", NVL(w.getAttribute("picture"), ""),
                " format=",  NVL(w.getAttribute("format"), ""),
                " numAlign=", NVL(w.getAttribute("numAlign"), "")
    END FOR
    
    -- Force UI refresh so new attributes take effect
    CALL ui.Interface.refresh()
    
    RETURN 1
END FUNCTION

PRIVATE FUNCTION first_widget_child(fld om.DomNode) RETURNS om.DomNode
    DEFINE nl om.NodeList
    
    -- Try common input widgets
    LET nl = fld.selectByTagName("Edit")
    IF nl.getLength() > 0 THEN RETURN nl.item(1) END IF
    
    LET nl = fld.selectByTagName("DateEdit")
    IF nl.getLength() > 0 THEN RETURN nl.item(1) END IF
    
    LET nl = fld.selectByTagName("TimeEdit")
    IF nl.getLength() > 0 THEN RETURN nl.item(1) END IF
    
    LET nl = fld.selectByTagName("SpinEdit")
    IF nl.getLength() > 0 THEN RETURN nl.item(1) END IF
    
    LET nl = fld.selectByTagName("ComboBox")
    IF nl.getLength() > 0 THEN RETURN nl.item(1) END IF
    
    RETURN NULL
END FUNCTION

{--------------------------------------------------------------------
  Helper: set attribute on FormField AND its first input widget.
  We try common widget node names used in 4fd forms.
---------------------------------------------------------------------}
PRIVATE FUNCTION set_attr_on_field_and_widget(
    fld om.DomNode, attr STRING, val STRING)
    DEFINE widgets om.NodeList
    DEFINE w om.DomNode

    -- Always set on the FormField itself
    CALL fld.setAttribute(attr, val)

    -- Then set on the concrete widget node
    LET widgets = fld.selectByTagName("Edit")
    IF widgets.getLength() = 0 THEN
        LET widgets = fld.selectByTagName("DateEdit")
    END IF
    IF widgets.getLength() = 0 THEN
        LET widgets = fld.selectByTagName("TimeEdit")
    END IF
    IF widgets.getLength() = 0 THEN
        LET widgets = fld.selectByTagName("SpinEdit")
    END IF
    IF widgets.getLength() = 0 THEN
        LET widgets = fld.selectByTagName("ComboBox")
    END IF

    IF widgets.getLength() > 0 THEN
        LET w = widgets.item(1)
        CALL w.setAttribute(attr, val)
    END IF
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
    RETURN (clean_phone MATCHES "[0-9]{11}")
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

PUBLIC FUNCTION set_form_label(label_name STRING, p_text STRING)
    DEFINE f ui.Form
    LET f = ui.Window.getCurrent().getForm()
    CALL f.setElementText(label_name, p_text)
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
        CONNECT TO "demoappdb@localhost:5432+driver='dbmpgs_9'"
            USER "postgres" USING "napoleon"
        RETURN TRUE
    CATCH
        CALL show_error("Database connection failed: " || SQLCA.SQLERRM)
        RETURN FALSE
    END TRY
END FUNCTION

-- disconnect the database
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
-- MASTER CRUD, NAV UTILITIES
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
    DEFINE l_codes DYNAMIC ARRAY OF STRING
    DEFINE l_code STRING
    DEFINE l_idx INTEGER
    DEFINE l_sql STRING

    CALL l_codes.clear()

    LET l_idx = 0
    LET l_sql =
        "SELECT "
            || master.key_field
            || " FROM "
            || master.table_name
            || " WHERE "
            || where_clause
            || " ORDER BY "
            || master.key_field

    TRY
        DECLARE c_select CURSOR FROM l_sql
        FOREACH c_select INTO l_code
            LET l_idx = l_idx + 1
            LET l_codes[l_idx] = l_code
        END FOREACH
        FREE c_select
    CATCH
        CALL show_error("Query failed: " || SQLCA.SQLERRM)
    END TRY

    IF l_codes.getLength() = 0 THEN
        CALL msg_no_record()
    END IF

    RETURN l_codes
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
    table_name STRING, field_name STRING, p_value STRING)
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
        EXECUTE stmt_count USING p_value INTO COUNT

        FREE stmt_count

        RETURN COUNT
    CATCH
        RETURN 0
    END TRY
END FUNCTION

-- ==============================================================
-- Utility : Document Numbering Helper
-- ==============================================================
FUNCTION lpad_number(p_num INTEGER, p_width INTEGER) RETURNS STRING
    DEFINE s_num STRING
    DEFINE zeros STRING
    DEFINE need INTEGER
    DEFINE i INTEGER

    LET s_num = "" || p_num -- force to string
    LET need = p_width - LENGTH(s_num)
    IF need <= 0 THEN
        RETURN s_num
    END IF

    LET zeros = ""
    FOR i = 1 TO need
        LET zeros = zeros || "0"
    END FOR
    RETURN zeros || s_num
END FUNCTION

-- ==============================================================
-- Generate next numeric and full account codes (3.20-safe)
-- ==============================================================

FUNCTION get_next_number(p_table STRING, p_prefix STRING)
    DEFINE last_num INTEGER
    DEFINE next_num INTEGER
    DEFINE next_full STRING
    DEFINE sql_stmt STRING
    DEFINE stmt STRING
    DEFINE formatted_num STRING

    LET last_num = 0
    LET sql_stmt = SFMT("SELECT MAX(id) FROM %1", p_table)
    PREPARE stmt FROM sql_stmt
    EXECUTE stmt INTO last_num
    FREE stmt

    IF last_num IS NULL THEN
        LET last_num = 0
    END IF

    LET next_num = last_num + 1

    -- Format the number with leading zeros (4 digits)
    LET formatted_num = next_num
    LET next_full = p_prefix || formatted_num

    RETURN next_num, next_full
END FUNCTION

-- ==============================================================
-- Generate next numeric
-- ==============================================================
PUBLIC FUNCTION get_next_code(p_table STRING, p_field STRING)
    DEFINE last_num INTEGER
    DEFINE next_num INTEGER
    DEFINE sql_stmt STRING
    DEFINE l_stmt STRING

    LET last_num = 0
    LET next_num = 0

    -- Build safe dynamic SQL
    LET sql_stmt = SFMT("SELECT MAX(%1)::INTEGER FROM %2", p_field, p_table)

    PREPARE l_stmt FROM sql_stmt
    EXECUTE l_stmt INTO last_num

    FREE stmt

    IF last_num IS NULL THEN
        LET last_num = 0
    END IF

    LET next_num = last_num + 1

    DISPLAY SFMT("Next available code for %1.%2 = %3", p_table, p_field, next_num)

    RETURN next_num
END FUNCTION


-- ==============================================================
-- Generate next record document number
-- ==============================================================
PUBLIC FUNCTION set_next_doc_no(p_table STRING, p_field STRING)
    DEFINE last_num INTEGER
    DEFINE next_num INTEGER
    DEFINE sql_stmt STRING
    DEFINE l_stmt STRING

    LET last_num = 0
    LET next_num = 0

    -- Build safe dynamic SQL
    LET sql_stmt = SFMT("SELECT MAX(id)::INTEGER FROM %2", p_field, p_table)

    PREPARE l_stmt FROM sql_stmt
    EXECUTE l_stmt INTO last_num

    FREE stmt

    IF last_num IS NULL THEN
        LET last_num = 0
    END IF

    LET next_num = last_num + 1

    DISPLAY SFMT("Next available code for %1.%2 = %3", p_table, p_field, next_num)

    RETURN next_num
END FUNCTION

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
-- Get Username by User ID
-- ==============================================================
PUBLIC FUNCTION get_username(p_user_id INTEGER) RETURNS STRING
    DEFINE l_username STRING

    -- Handle null or system user IDs first
    IF p_user_id IS NULL OR p_user_id = 0 THEN
        RETURN "System"
    END IF

    TRY
        SELECT username INTO l_username FROM sy00_user WHERE id = p_user_id

        IF SQLCA.SQLCODE = 100 THEN
            -- No record found
            RETURN "Unknown"
        END IF

        RETURN l_username

    CATCH
        -- Any SQL or runtime error (DB down, bad schema, etc.)
        DISPLAY "get_username(): SQL error ",
            SQLCA.SQLCODE,
            " - ",
            SQLCA.SQLERRM
        RETURN "Error"

    END TRY
END FUNCTION

-- ==============================================================
-- Get Random User ID
-- ==============================================================
FUNCTION get_random_user() RETURNS INTEGER

    DEFINE r_user_id INTEGER

    LET r_user_id = util.Math.rand(5)

    RETURN r_user_id
END FUNCTION

-- ==============================================================
-- Get Current User ID (useful for audit trails)
-- ==============================================================
PUBLIC FUNCTION get_current_user_id() RETURNS SMALLINT

    DEFINE user_id INTEGER

    LET user_id = util.Math.rand(5)

    RETURN user_id

END FUNCTION

-- ==============================================================
-- Get Current Username
-- ==============================================================
PUBLIC FUNCTION get_current_username(user_id INTEGER) RETURNS STRING
    DEFINE username STRING

    SELECT username INTO username FROM sy00_user WHERE id = user_id

    RETURN username

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
        LET full_message =
            SFMT("SQL WARNING (Not Found): %1 - No records matched the query criteria.",
                p_context)
    ELSE
        -- Format the detailed error message
        LET full_message =
            SFMT("Database Error: %1\n(SQLCODE: %2 / SQLSTATE: %3)\nError: %4",
                p_context,
                sql_code,
                -- sql_state,
                sql_errm)
    END IF

    CALL show_error(full_message)

END FUNCTION

-- ============================================================
-- Function : apply_currency_prefix()
-- Purpose  : Dynamically set "R " prefix to all tagged currency fields
-- ============================================================
PUBLIC FUNCTION apply_currency_prefix()
--    DEFINE f ui.Form
--    DEFINE field_name STRING
--    DEFINE fields DYNAMIC ARRAY OF STRING
--    DEFINE i INTEGER
--
--    LET f = ui.Window.getCurrent().getForm()
--    IF f IS NULL THEN
--        RETURN
--    END IF
--
--    -- Enumerate all fields on the form
--    CALL f.getNode(fields)
--
--    FOR i = 1 TO fields.getLength()
--        LET field_name = fields[i]
--
--        IF fgl_getFieldTag(field_name) = "currency" THEN
--            -- Get current value (string)
--            DEFINE val DECIMAL(12,2)
--            LET val = fgl_getFieldValue(field_name)
--
--            -- Re-display with currency prefix (R)
--            CALL f.setFieldValue(field_name, SFMT("R %1", val))
--        END IF
--    END FOR
END FUNCTION


-- =======================
-- Confirm Exit
-- =======================
FUNCTION confirm_exit()
    
   
END FUNCTION
