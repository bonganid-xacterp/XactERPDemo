-- ==============================================================
-- Program   : sy130_logs.4gl
-- Purpose   : System Logs Viewer and Management
-- Module    : System (sy)
-- Number    : 130
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: View and manage system activity logs
--              Provides filtering, search, and export capabilities
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoappdb

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE log_t RECORD LIKE sy02_logs.*

DEFINE m_filter_level STRING
DEFINE m_filter_user STRING
DEFINE m_filter_date_from DATE
DEFINE m_filter_date_to DATE
DEFINE m_filter_action STRING

-- ==============================================================
-- Constants
-- ==============================================================
CONSTANT LOG_LEVEL_INFO = "INFO"
CONSTANT LOG_LEVEL_WARNING = "WARNING"
CONSTANT LOG_LEVEL_ERROR = "ERROR"
CONSTANT LOG_LEVEL_DEBUG = "DEBUG"
CONSTANT LOG_LEVEL_SECURITY = "SECURITY"

-- ==============================================================
-- MAIN (Standalone or MDI Child)
-- ==============================================================
--MAIN
--    IF NOT utils_globals.initialize_application() THEN
--        CALL utils_globals.show_error("Initialization failed.")
--        EXIT PROGRAM 1
--    END IF
--
--    IF utils_globals.is_standalone() THEN
--        OPEN WINDOW w_sy130 WITH FORM "sy130_logs" -- ATTRIBUTES(STYLE = "normal")
--    END IF
--
--    CALL init_logs_module()
--
--    IF utils_globals.is_standalone() THEN
--        CLOSE WINDOW w_sy130
--    END IF
--END MAIN

-- ==============================================================
-- Module Controller
-- ==============================================================
FUNCTION init_logs_module()
    -- Initialize filters
    LET m_filter_date_from = TODAY - 7  -- Last 7 days
    LET m_filter_date_to = TODAY

    -- Load logs
    CALL view_logs()
END FUNCTION

-- ==============================================================
-- View System Logs
-- ==============================================================
FUNCTION view_logs()
    DEFINE arr_logs DYNAMIC ARRAY OF RECORD
            id INTEGER,
            log_date DATETIME YEAR TO SECOND,
            username STRING,
            level STRING,
            action STRING,
            details STRING
        END RECORD
    DEFINE rec_log RECORD
            id INTEGER,
            log_date DATETIME YEAR TO SECOND,
            username STRING,
            level STRING,
            action STRING,
            details STRING
        END RECORD
    DEFINE idx, curr_row INTEGER
    DEFINE sql_query STRING
    DEFINE where_clause STRING

    LET idx = 0

    -- Build where clause based on filters
    LET where_clause = build_filter_clause()

    -- Build SQL query
    LET sql_query = "SELECT l.id, l.created_at, u.username, l.level, l.action, l.details " ||
                    "FROM sy02_logs l " ||
                    "LEFT JOIN sy00_user u ON l.user_id = u.id " ||
                    "WHERE " || where_clause ||
                    " ORDER BY l.created_at DESC"

    CALL arr_logs.clear()

    TRY
        DECLARE log_curs CURSOR FROM sql_query

        FOREACH log_curs INTO rec_log.*
            LET idx = idx + 1
            LET arr_logs[idx].* = rec_log.*
        END FOREACH

        CLOSE log_curs
        FREE log_curs

    CATCH
        CALL utils_globals.show_error("Error loading logs: " || SQLCA.SQLERRM)
        RETURN
    END TRY

    IF idx = 0 THEN
        CALL utils_globals.msg_no_record()
        RETURN
    END IF

    -- Display logs in array
    MENU "System Logs"

        BEFORE MENU
            CALL show_log_array(arr_logs)

        COMMAND "Refresh"
            CALL view_logs()

        COMMAND "Filter"
            IF set_filter() THEN
                CALL view_logs()
            END IF

        COMMAND "Details"
            LET curr_row = arr_curr()
            IF curr_row > 0 AND curr_row <= arr_logs.getLength() THEN
                CALL show_log_details(arr_logs[curr_row].id)
            END IF

        COMMAND "Clear Old Logs"
            CALL clear_old_logs()
            CALL view_logs()

        COMMAND "Export"
            CALL export_logs(arr_logs)

        COMMAND "Exit"
            EXIT MENU
    END MENU
END FUNCTION

-- ==============================================================
-- Display Log Array
-- ==============================================================
FUNCTION show_log_array(arr_logs DYNAMIC ARRAY OF RECORD
        id INTEGER,
        log_date DATETIME YEAR TO SECOND,
        username STRING,
        level STRING,
        action STRING,
        details STRING
    END RECORD)

    DISPLAY ARRAY arr_logs TO sr_logs.*
        ATTRIBUTES(COUNT = arr_logs.getLength(), UNBUFFERED)

        BEFORE DISPLAY
            -- Set status message
            MESSAGE SFMT("%1 log entries found", arr_logs.getLength())
    END DISPLAY
END FUNCTION

-- ==============================================================
-- Build Filter Clause
-- ==============================================================
FUNCTION build_filter_clause() RETURNS STRING
    DEFINE where_parts DYNAMIC ARRAY OF STRING
    DEFINE idx INTEGER
    DEFINE clause STRING

    LET idx = 0

    -- Date range filter (always applied)
    LET idx = idx + 1
    LET where_parts[idx] = SFMT("DATE(l.created_at) >= '%1'",
                                m_filter_date_from USING "YYYY-MM-DD")

    LET idx = idx + 1
    LET where_parts[idx] = SFMT("DATE(l.created_at) <= '%1'",
                                m_filter_date_to USING "YYYY-MM-DD")

    -- Level filter
    IF m_filter_level IS NOT NULL AND m_filter_level.getLength() > 0 THEN
        LET idx = idx + 1
        LET where_parts[idx] = SFMT("l.level = '%1'", m_filter_level)
    END IF

    -- User filter
    IF m_filter_user IS NOT NULL AND m_filter_user.getLength() > 0 THEN
        LET idx = idx + 1
        LET where_parts[idx] = SFMT("u.username LIKE '%%%1%%'", m_filter_user)
    END IF

    -- Action filter
    IF m_filter_action IS NOT NULL AND m_filter_action.getLength() > 0 THEN
        LET idx = idx + 1
        LET where_parts[idx] = SFMT("l.action LIKE '%%%1%%'", m_filter_action)
    END IF

    -- Build final clause
    LET clause = "1=1"
    FOR idx = 1 TO where_parts.getLength()
        LET clause = clause || " AND " || where_parts[idx]
    END FOR

    RETURN clause
END FUNCTION

-- ==============================================================
-- Set Filters
-- ==============================================================
FUNCTION set_filter() RETURNS SMALLINT
    DEFINE ok SMALLINT

    LET ok = FALSE

    INPUT BY NAME m_filter_date_from, m_filter_date_to,
                  m_filter_level, m_filter_user, m_filter_action
        ATTRIBUTES(WITHOUT DEFAULTS = TRUE, UNBUFFERED)

        AFTER FIELD m_filter_date_from
            IF m_filter_date_from IS NULL THEN
                ERROR "Start date is required"
                NEXT FIELD m_filter_date_from
            END IF

        AFTER FIELD m_filter_date_to
            IF m_filter_date_to IS NULL THEN
                ERROR "End date is required"
                NEXT FIELD m_filter_date_to
            END IF
            IF m_filter_date_to < m_filter_date_from THEN
                ERROR "End date must be after start date"
                NEXT FIELD m_filter_date_to
            END IF

        ON ACTION accept
            LET ok = TRUE
            EXIT INPUT

        ON ACTION cancel
            LET ok = FALSE
            EXIT INPUT
    END INPUT

    RETURN ok
END FUNCTION

-- ==============================================================
-- Show Log Details
-- ==============================================================
FUNCTION show_log_details(p_log_id INTEGER)
    DEFINE rec_log log_t
    DEFINE username STRING
    DEFINE details_text STRING

    SELECT l.*, u.username
      INTO rec_log.*, username
      FROM sy02_logs l
      LEFT JOIN sy00_user u ON l.user_id = u.id
     WHERE l.id = p_log_id

    IF SQLCA.SQLCODE = NOTFOUND THEN
        CALL utils_globals.show_error("Log entry not found")
        RETURN
    END IF

    -- Format details for display
    LET details_text = "Log ID: " || rec_log.id || "\n" ||
                       "Date/Time: " || rec_log.created_at USING "YYYY-MM-DD HH:MM:SS" || "\n" ||
                       "User: " || username || "\n" ||
                       "Level: " || rec_log.level || "\n" ||
                       "Action: " || rec_log.action || "\n\n" ||
                       "Details:\n" || rec_log.details

    CALL utils_globals.show_info(details_text)
END FUNCTION

-- ==============================================================
-- Clear Old Logs
-- ==============================================================
FUNCTION clear_old_logs()
    DEFINE days_to_keep INTEGER
    DEFINE cutoff_date DATE
    DEFINE deleted_count INTEGER

    LET days_to_keep = 90  -- Default 90 days

    IF NOT utils_globals.show_confirm(
        SFMT("Delete logs older than %1 days?", days_to_keep),
        "Confirm Delete") THEN
        RETURN
    END IF

    LET cutoff_date = TODAY - days_to_keep

    TRY
        DELETE FROM sy02_logs
         WHERE DATE(created_at) < cutoff_date

        LET deleted_count = SQLCA.SQLERRD[3]

        CALL utils_globals.show_info(
            SFMT("%1 log entries deleted", deleted_count))

    CATCH
        CALL utils_globals.show_error(
            "Error deleting logs: " || SQLCA.SQLERRM)
    END TRY
END FUNCTION

-- ==============================================================
-- Export Logs to Text File
-- ==============================================================
FUNCTION export_logs(arr_logs DYNAMIC ARRAY OF RECORD
        id INTEGER,
        log_date DATETIME YEAR TO SECOND,
        username STRING,
        level STRING,
        action STRING,
        details STRING
    END RECORD)

    DEFINE filename STRING
    DEFINE ch base.Channel
    DEFINE i INTEGER
    DEFINE line STRING

    LET filename = SFMT("logs_%1.txt", TODAY USING "YYYYMMDD")

    TRY
        LET ch = base.Channel.create()
        CALL ch.openFile(filename, "w")

        -- Write header
        CALL ch.writeLine("==============================================")
        CALL ch.writeLine("         System Logs Export")
        CALL ch.writeLine("==============================================")
        CALL ch.writeLine(SFMT("Exported: %1", CURRENT USING "YYYY-MM-DD HH:MM:SS"))
        CALL ch.writeLine(SFMT("Total Records: %1", arr_logs.getLength()))
        CALL ch.writeLine("==============================================")
        CALL ch.writeLine("")

        -- Write log entries
        FOR i = 1 TO arr_logs.getLength()
            LET line = SFMT("[%1] [%2] [%3] %4",
                arr_logs[i].log_date USING "YYYY-MM-DD HH:MM:SS",
                arr_logs[i].level,
                arr_logs[i].username,
                arr_logs[i].action)
            CALL ch.writeLine(line)

            IF arr_logs[i].details IS NOT NULL THEN
                CALL ch.writeLine("  Details: " || arr_logs[i].details)
            END IF
            CALL ch.writeLine("")
        END FOR

        CALL ch.close()

        CALL utils_globals.show_info(
            SFMT("Logs exported to: %1", filename))

    CATCH
        CALL utils_globals.show_error(
            "Error exporting logs: " || STATUS)
    END TRY
END FUNCTION

-- ==============================================================
-- PUBLIC LOGGING FUNCTIONS (Called from other modules)
-- ==============================================================

-- Log Info Level
FUNCTION log_info(p_user_id INTEGER, p_action STRING, p_details STRING)
    CALL write_log(p_user_id, LOG_LEVEL_INFO, p_action, p_details)
END FUNCTION

-- Log Warning Level
FUNCTION log_warning(p_user_id INTEGER, p_action STRING, p_details STRING)
    CALL write_log(p_user_id, LOG_LEVEL_WARNING, p_action, p_details)
END FUNCTION

-- Log Error Level
FUNCTION log_error(p_user_id INTEGER, p_action STRING, p_details STRING)
    CALL write_log(p_user_id, LOG_LEVEL_ERROR, p_action, p_details)
END FUNCTION

-- Log Debug Level
FUNCTION log_debug(p_user_id INTEGER, p_action STRING, p_details STRING)
    CALL write_log(p_user_id, LOG_LEVEL_DEBUG, p_action, p_details)
END FUNCTION

-- Log Security Events
FUNCTION log_security(p_user_id INTEGER, p_action STRING, p_details STRING)
    CALL write_log(p_user_id, LOG_LEVEL_SECURITY, p_action, p_details)
END FUNCTION

-- ==============================================================
-- Write Log Entry
-- ==============================================================
PRIVATE FUNCTION write_log(p_user_id INTEGER, p_level STRING,
                           p_action STRING, p_details STRING)
    DEFINE rec_log log_t

    -- Prepare log record
    LET rec_log.user_id = p_user_id
    LET rec_log.level = p_level
    LET rec_log.action = p_action
    LET rec_log.details = p_details
    LET rec_log.created_at = CURRENT

    TRY
        INSERT INTO sy02_logs (user_id, level, action, details, created_at)
            VALUES (rec_log.user_id, rec_log.level, rec_log.action,
                    rec_log.details, rec_log.created_at)
    CATCH
        -- Silent fail - don't break application if logging fails
        DISPLAY "WARNING: Failed to write log: ", SQLCA.SQLERRM
    END TRY
END FUNCTION

-- ==============================================================
-- Log User Login
-- ==============================================================
FUNCTION log_user_login(p_user_id INTEGER, p_username STRING, p_success SMALLINT)
    DEFINE action, details STRING

    IF p_success THEN
        LET action = "User Login Success"
        LET details = SFMT("User '%1' logged in successfully", p_username)
        CALL log_security(p_user_id, action, details)
    ELSE
        LET action = "User Login Failed"
        LET details = SFMT("Failed login attempt for user '%1'", p_username)
        CALL log_security(0, action, details)
    END IF
END FUNCTION

-- ==============================================================
-- Log User Logout
-- ==============================================================
FUNCTION log_user_logout(p_user_id INTEGER, p_username STRING)
    DEFINE action, details STRING

    LET action = "User Logout"
    LET details = SFMT("User '%1' logged out", p_username)
    CALL log_info(p_user_id, action, details)
END FUNCTION

-- ==============================================================
-- Log Data Modification
-- ==============================================================
FUNCTION log_data_change(p_user_id INTEGER, p_table STRING,
                         p_operation STRING, p_record_id INTEGER)
    DEFINE action, details STRING

    LET action = SFMT("Data %1", p_operation)
    LET details = SFMT("Table: %1, Record ID: %2, Operation: %3",
                       p_table, p_record_id, p_operation)
    CALL log_info(p_user_id, action, details)
END FUNCTION

-- ==============================================================
-- Log System Error
-- ==============================================================
FUNCTION log_system_error(p_user_id INTEGER, p_module STRING,
                          p_error_code INTEGER, p_error_message STRING)
    DEFINE action, details STRING

    LET action = SFMT("System Error in %1", p_module)
    LET details = SFMT("Error Code: %1, Message: %2",
                       p_error_code, p_error_message)
    CALL log_error(p_user_id, action, details)
END FUNCTION
