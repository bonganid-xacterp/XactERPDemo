-- ==============================================================
-- Program   : utils_logger.4gl
-- Purpose   : System activity logger utilities
--             Provides convenient logging wrapper for sy130_logs
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Centralized logging utility that wraps sy130_logs
--              Provides both console and database logging
-- ==============================================================

IMPORT FGL sy130_logs
IMPORT FGL utils_globals

SCHEMA demoappdb

-- ==============================================================
-- GLOBAL VARIABLES
-- ==============================================================
GLOBALS
    DEFINE g_last_error STRING
    DEFINE g_logging_enabled SMALLINT
    DEFINE g_log_to_console SMALLINT
    DEFINE g_log_to_database SMALLINT
    DEFINE g_min_log_level STRING  -- Minimum level to log
END GLOBALS

-- ==============================================================
-- LOG LEVEL CONSTANTS
-- ==============================================================
CONSTANT LOG_LEVEL_DEBUG = "DEBUG"
CONSTANT LOG_LEVEL_INFO = "INFO"
CONSTANT LOG_LEVEL_WARNING = "WARNING"
CONSTANT LOG_LEVEL_ERROR = "ERROR"
CONSTANT LOG_LEVEL_SECURITY = "SECURITY"

-- ==============================================================
-- INITIALIZATION
-- ==============================================================
FUNCTION init_logger()
    -- Enable logging by default
    LET g_logging_enabled = TRUE
    LET g_log_to_console = TRUE
    LET g_log_to_database = TRUE
    LET g_min_log_level = LOG_LEVEL_INFO  -- Don't log DEBUG by default
END FUNCTION

-- ==============================================================
-- CONFIGURATION FUNCTIONS
-- ==============================================================
FUNCTION set_logging_enabled(p_enabled SMALLINT)
    LET g_logging_enabled = p_enabled
END FUNCTION

FUNCTION set_console_logging(p_enabled SMALLINT)
    LET g_log_to_console = p_enabled
END FUNCTION

FUNCTION set_database_logging(p_enabled SMALLINT)
    LET g_log_to_database = p_enabled
END FUNCTION

FUNCTION set_min_log_level(p_level STRING)
    -- Set minimum log level: DEBUG, INFO, WARNING, ERROR, SECURITY
    LET g_min_log_level = p_level
END FUNCTION

-- ==============================================================
-- CORE LOGGING FUNCTION
-- ==============================================================
PRIVATE FUNCTION write_log(p_level STRING, p_function STRING, p_message STRING,
                           p_details STRING)
    DEFINE l_timestamp DATETIME YEAR TO FRACTION(3)
    DEFINE l_user_id INTEGER
    DEFINE l_should_log SMALLINT

    -- Check if logging is enabled
    IF NOT g_logging_enabled THEN
        RETURN
    END IF

    -- Check if this level should be logged based on minimum level
    LET l_should_log = should_log_level(p_level)
    IF NOT l_should_log THEN
        RETURN
    END IF

    LET l_timestamp = CURRENT YEAR TO FRACTION(3)

    -- Get current user ID
    TRY
        LET l_user_id = utils_globals.get_current_user_id()
    CATCH
        LET l_user_id = 0  -- Unknown user
    END TRY

    -- Log to console if enabled
    IF g_log_to_console THEN
        IF p_details IS NOT NULL AND p_details.getLength() > 0 THEN
            DISPLAY SFMT("[%1] %2 | %3 | %4 | %5",
                p_level, l_timestamp, p_function, p_message, p_details)
        ELSE
            DISPLAY SFMT("[%1] %2 | %3 | %4",
                p_level, l_timestamp, p_function, p_message)
        END IF
    END IF

    -- Log to database if enabled
    IF g_log_to_database THEN
        TRY
            CASE p_level
                WHEN LOG_LEVEL_INFO
                    CALL sy130_logs.log_info(l_user_id, p_function || ": " || p_message, p_details)
                WHEN LOG_LEVEL_WARNING
                    CALL sy130_logs.log_warning(l_user_id, p_function || ": " || p_message, p_details)
                WHEN LOG_LEVEL_ERROR
                    CALL sy130_logs.log_error(l_user_id, p_function || ": " || p_message, p_details)
                WHEN LOG_LEVEL_DEBUG
                    CALL sy130_logs.log_debug(l_user_id, p_function || ": " || p_message, p_details)
                WHEN LOG_LEVEL_SECURITY
                    CALL sy130_logs.log_security(l_user_id, p_function || ": " || p_message, p_details)
            END CASE
        CATCH
            -- Silent fail - don't break application if logging fails
            DISPLAY "WARNING: Failed to write log to database"
        END TRY
    END IF
END FUNCTION

-- ==============================================================
-- LOG LEVEL CHECKING
-- ==============================================================
PRIVATE FUNCTION should_log_level(p_level STRING) RETURNS SMALLINT
    DEFINE l_level_priority INTEGER
    DEFINE l_min_priority INTEGER

    LET l_level_priority = get_level_priority(p_level)
    LET l_min_priority = get_level_priority(g_min_log_level)

    -- Log if message level priority >= minimum priority
    RETURN (l_level_priority >= l_min_priority)
END FUNCTION

PRIVATE FUNCTION get_level_priority(p_level STRING) RETURNS INTEGER
    -- Higher number = higher priority
    CASE p_level
        WHEN LOG_LEVEL_DEBUG
            RETURN 1
        WHEN LOG_LEVEL_INFO
            RETURN 2
        WHEN LOG_LEVEL_WARNING
            RETURN 3
        WHEN LOG_LEVEL_ERROR
            RETURN 4
        WHEN LOG_LEVEL_SECURITY
            RETURN 5
        OTHERWISE
            RETURN 2  -- Default to INFO priority
    END CASE
END FUNCTION

-- ==============================================================
-- PUBLIC LOGGING FUNCTIONS
-- ==============================================================

-- Log Error Message
FUNCTION log_error(p_function STRING, p_message STRING)
    LET g_last_error = p_message
    CALL write_log(LOG_LEVEL_ERROR, p_function, p_message, NULL)
END FUNCTION

-- Log Error with Details
FUNCTION log_error_detail(p_function STRING, p_message STRING, p_details STRING)
    LET g_last_error = p_message
    CALL write_log(LOG_LEVEL_ERROR, p_function, p_message, p_details)
END FUNCTION

-- Log Warning Message
FUNCTION log_warning(p_function STRING, p_message STRING)
    CALL write_log(LOG_LEVEL_WARNING, p_function, p_message, NULL)
END FUNCTION

-- Log Warning with Details
FUNCTION log_warning_detail(p_function STRING, p_message STRING, p_details STRING)
    CALL write_log(LOG_LEVEL_WARNING, p_function, p_message, p_details)
END FUNCTION

-- Log Info Message
FUNCTION log_info(p_function STRING, p_message STRING)
    CALL write_log(LOG_LEVEL_INFO, p_function, p_message, NULL)
END FUNCTION

-- Log Info with Details
FUNCTION log_info_detail(p_function STRING, p_message STRING, p_details STRING)
    CALL write_log(LOG_LEVEL_INFO, p_function, p_message, p_details)
END FUNCTION

-- Log Debug Message (typically disabled in production)
FUNCTION log_debug(p_function STRING, p_message STRING)
    CALL write_log(LOG_LEVEL_DEBUG, p_function, p_message, NULL)
END FUNCTION

-- Log Debug with Details
FUNCTION log_debug_detail(p_function STRING, p_message STRING, p_details STRING)
    CALL write_log(LOG_LEVEL_DEBUG, p_function, p_message, p_details)
END FUNCTION

-- Log Security Event
FUNCTION log_security(p_function STRING, p_message STRING)
    CALL write_log(LOG_LEVEL_SECURITY, p_function, p_message, NULL)
END FUNCTION

-- Log Security Event with Details
FUNCTION log_security_detail(p_function STRING, p_message STRING, p_details STRING)
    CALL write_log(LOG_LEVEL_SECURITY, p_function, p_message, p_details)
END FUNCTION

-- ==============================================================
-- SPECIALIZED LOGGING FUNCTIONS
-- ==============================================================

-- Log SQL Error
FUNCTION log_sql_error(p_function STRING, p_operation STRING)
    DEFINE l_message STRING
    DEFINE l_details STRING

    LET l_message = SFMT("SQL Error in %1", p_operation)
    LET l_details = SFMT("SQLCODE: %1, SQLERRD[2]: %2, Message: %3",
                         SQLCA.SQLCODE, SQLCA.SQLERRD[2], SQLCA.SQLERRM)

    CALL log_error_detail(p_function, l_message, l_details)
END FUNCTION

-- Log User Login
FUNCTION log_user_login_attempt(p_username STRING, p_success SMALLINT, p_user_id INTEGER)
    DEFINE l_message STRING
    DEFINE l_details STRING

    IF p_success THEN
        LET l_message = "User Login Success"
        LET l_details = SFMT("User '%1' logged in successfully", p_username)
        CALL sy130_logs.log_user_login(p_user_id, p_username, TRUE)
    ELSE
        LET l_message = "User Login Failed"
        LET l_details = SFMT("Failed login attempt for user '%1'", p_username)
        CALL sy130_logs.log_user_login(0, p_username, FALSE)
    END IF

    IF g_log_to_console THEN
        DISPLAY SFMT("[SECURITY] %1 | %2", l_message, l_details)
    END IF
END FUNCTION

-- Log User Logout
FUNCTION log_user_logout_event(p_username STRING, p_user_id INTEGER)
    CALL sy130_logs.log_user_logout(p_user_id, p_username)

    IF g_log_to_console THEN
        DISPLAY SFMT("[INFO] User Logout | User '%1' logged out", p_username)
    END IF
END FUNCTION

-- Log Data Insert
FUNCTION log_data_insert(p_function STRING, p_table STRING, p_record_id INTEGER)
    DEFINE l_message STRING
    DEFINE l_user_id INTEGER

    LET l_message = SFMT("Record inserted into %1", p_table)

    TRY
        LET l_user_id = utils_globals.get_current_user_id()
        CALL sy130_logs.log_data_change(l_user_id, p_table, "INSERT", p_record_id)
    CATCH
        LET l_user_id = 0
    END TRY

    IF g_log_to_console THEN
        DISPLAY SFMT("[INFO] %1 | %2 | Record ID: %3",
            p_function, l_message, p_record_id)
    END IF
END FUNCTION

-- Log Data Update
FUNCTION log_data_update(p_function STRING, p_table STRING, p_record_id INTEGER)
    DEFINE l_message STRING
    DEFINE l_user_id INTEGER

    LET l_message = SFMT("Record updated in %1", p_table)

    TRY
        LET l_user_id = utils_globals.get_current_user_id()
        CALL sy130_logs.log_data_change(l_user_id, p_table, "UPDATE", p_record_id)
    CATCH
        LET l_user_id = 0
    END TRY

    IF g_log_to_console THEN
        DISPLAY SFMT("[INFO] %1 | %2 | Record ID: %3",
            p_function, l_message, p_record_id)
    END IF
END FUNCTION

-- Log Data Delete
FUNCTION log_data_delete(p_function STRING, p_table STRING, p_record_id INTEGER)
    DEFINE l_message STRING
    DEFINE l_user_id INTEGER

    LET l_message = SFMT("Record deleted from %1", p_table)

    TRY
        LET l_user_id = utils_globals.get_current_user_id()
        CALL sy130_logs.log_data_change(l_user_id, p_table, "DELETE", p_record_id)
    CATCH
        LET l_user_id = 0
    END TRY

    IF g_log_to_console THEN
        DISPLAY SFMT("[INFO] %1 | %2 | Record ID: %3",
            p_function, l_message, p_record_id)
    END IF
END FUNCTION

-- Log Permission Check
FUNCTION log_permission_check(p_module STRING, p_user_id INTEGER, p_granted SMALLINT)
    DEFINE l_message STRING
    DEFINE l_details STRING

    IF p_granted THEN
        LET l_message = "Permission Check"
        LET l_details = SFMT("Access GRANTED to module '%1'", p_module)
    ELSE
        LET l_message = "Permission Denied"
        LET l_details = SFMT("Access DENIED to module '%1'", p_module)
    END IF

    CALL sy130_logs.log_security(p_user_id, l_message, l_details)

    IF g_log_to_console THEN
        DISPLAY SFMT("[SECURITY] %1 | %2", l_message, l_details)
    END IF
END FUNCTION

-- Log Module Access
FUNCTION log_module_access(p_module STRING, p_user_id INTEGER)
    DEFINE l_message STRING
    DEFINE l_details STRING

    LET l_message = "Module Access"
    LET l_details = SFMT("User accessed module '%1'", p_module)

    CALL sy130_logs.log_info(p_user_id, l_message, l_details)

    IF g_log_to_console THEN
        DISPLAY SFMT("[INFO] %1 | User ID: %2", l_details, p_user_id)
    END IF
END FUNCTION

-- ==============================================================
-- ERROR RETRIEVAL
-- ==============================================================
FUNCTION get_last_error() RETURNS STRING
    RETURN g_last_error
END FUNCTION

FUNCTION clear_last_error()
    LET g_last_error = NULL
END FUNCTION

-- ==============================================================
-- UTILITY FUNCTIONS
-- ==============================================================

-- Log Function Entry (for debugging)
FUNCTION log_function_entry(p_function STRING, p_params STRING)
    IF g_min_log_level = LOG_LEVEL_DEBUG THEN
        CALL log_debug_detail(p_function, "Function Entry",
            SFMT("Parameters: %1", p_params))
    END IF
END FUNCTION

-- Log Function Exit (for debugging)
FUNCTION log_function_exit(p_function STRING, p_result STRING)
    IF g_min_log_level = LOG_LEVEL_DEBUG THEN
        CALL log_debug_detail(p_function, "Function Exit",
            SFMT("Result: %1", p_result))
    END IF
END FUNCTION

-- Log Performance Metric
FUNCTION log_performance(p_function STRING, p_operation STRING, p_duration FLOAT)
    DEFINE l_message STRING
    DEFINE l_details STRING

    LET l_message = SFMT("Performance: %1", p_operation)
    LET l_details = SFMT("Duration: %1 seconds", p_duration USING "<<,<<<.###")

    IF p_duration > 5.0 THEN
        -- Log slow operations as warnings
        CALL log_warning_detail(p_function, l_message, l_details)
    ELSE
        CALL log_debug_detail(p_function, l_message, l_details)
    END IF
END FUNCTION

-- Log Business Rule Violation
FUNCTION log_business_rule_violation(p_function STRING, p_rule STRING, p_details STRING)
    DEFINE l_message STRING

    LET l_message = SFMT("Business Rule Violation: %1", p_rule)
    CALL log_warning_detail(p_function, l_message, p_details)
END FUNCTION

-- Log Configuration Change
FUNCTION log_config_change(p_function STRING, p_setting STRING,
                           p_old_value STRING, p_new_value STRING)
    DEFINE l_message STRING
    DEFINE l_details STRING
    DEFINE l_user_id INTEGER

    LET l_message = SFMT("Configuration Changed: %1", p_setting)
    LET l_details = SFMT("Old Value: '%1', New Value: '%2'", p_old_value, p_new_value)

    TRY
        LET l_user_id = utils_globals.get_current_user_id()
    CATCH
        LET l_user_id = 0
    END TRY

    CALL sy130_logs.log_info(l_user_id, l_message, l_details)

    IF g_log_to_console THEN
        DISPLAY SFMT("[INFO] %1 | %2 | %3", p_function, l_message, l_details)
    END IF
END FUNCTION

-- ==============================================================
-- TRANSACTION LOGGING
-- ==============================================================

-- Log Transaction Start
FUNCTION log_transaction_start(p_function STRING, p_transaction_type STRING)
    CALL log_debug_detail(p_function, "Transaction Start",
        SFMT("Type: %1", p_transaction_type))
END FUNCTION

-- Log Transaction Commit
FUNCTION log_transaction_commit(p_function STRING, p_transaction_type STRING)
    CALL log_debug_detail(p_function, "Transaction Commit",
        SFMT("Type: %1", p_transaction_type))
END FUNCTION

-- Log Transaction Rollback
FUNCTION log_transaction_rollback(p_function STRING, p_transaction_type STRING, p_reason STRING)
    CALL log_warning_detail(p_function, "Transaction Rollback",
        SFMT("Type: %1, Reason: %2", p_transaction_type, p_reason))
END FUNCTION
