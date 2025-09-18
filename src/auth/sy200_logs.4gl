# ==============================================================
# Program   :   sy200_logging.4gl
# Purpose   :   Centralized logging module for XACT ERP
# Module    :   System (sy)
# Number    :   200
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.2.1
# ==============================================================

IMPORT os
IMPORT util

# Constants for log levels
CONSTANT LOG_LEVEL_DEBUG = 1
CONSTANT LOG_LEVEL_INFO = 2
CONSTANT LOG_LEVEL_WARN = 3
CONSTANT LOG_LEVEL_ERROR = 4
CONSTANT LOG_LEVEL_FATAL = 5

# Constants for log types
CONSTANT LOG_TYPE_SYSTEM = "SYSTEM"
CONSTANT LOG_TYPE_LOGIN = "LOGIN"
CONSTANT LOG_TYPE_SECURITY = "SECURITY"
CONSTANT LOG_TYPE_DATABASE = "DATABASE"
CONSTANT LOG_TYPE_APPLICATION = "APPLICATION"

# Global variables for logging configuration
DEFINE g_log_enabled BOOLEAN
DEFINE g_log_level SMALLINT
DEFINE g_log_to_database BOOLEAN
DEFINE g_log_to_file BOOLEAN
DEFINE g_log_file_path STRING

# ------------------ INITIALIZATION -------------------
FUNCTION logging_init()
    -- Initialize logging configuration
    LET g_log_enabled = TRUE
    LET g_log_level = LOG_LEVEL_INFO
    LET g_log_to_database = TRUE
    LET g_log_to_file = TRUE
    LET g_log_file_path = "logs/xacterp.log"
    
    -- Create logs directory if it doesn't exist
    CALL create_log_directory()
    
    -- Log initialization
    CALL log_info(LOG_TYPE_SYSTEM, "Logging system initialized", NULL, NULL)
END FUNCTION

# ------------------ MAIN LOGGING FUNCTIONS -------------------
FUNCTION log_login_success(user_id INTEGER, username STRING, client_info STRING)
    DEFINE log_message STRING
    
    LET log_message = "User login successful - Username: " || username.trim()
    
    -- Log to system log
    CALL log_info(LOG_TYPE_LOGIN, log_message, user_id, client_info)
    
    -- Log to database login table
    IF g_log_to_database THEN
        CALL insert_login_log(user_id, username, "SUCCESS", NULL, client_info)
    END IF
    
    -- Update user's last login time
    CALL update_user_last_login(user_id)
END FUNCTION

FUNCTION log_login_failure(username STRING, reason STRING, client_info STRING)
    DEFINE log_message STRING
    
    LET log_message = "Login failed - Username: " || username.trim() || ", Reason: " || reason
    
    -- Log to system log
    CALL log_warn(LOG_TYPE_LOGIN, log_message, NULL, client_info)
    
    -- Log to database login table
    IF g_log_to_database THEN
        CALL insert_login_log(NULL, username, "FAILED", reason, client_info)
    END IF
    
    -- Increment failed login attempts
    CALL increment_failed_attempts(username)
END FUNCTION

FUNCTION log_security_event(event_type STRING, description STRING, user_id INTEGER, details STRING)
    DEFINE log_message STRING
    
    LET log_message = "Security event - Type: " || event_type || ", Description: " || description
    
    -- Security events are always logged as warnings or errors
    CALL log_warn(LOG_TYPE_SECURITY, log_message, user_id, details)
    
    -- Log to security audit table
    IF g_log_to_database THEN
        CALL insert_security_log(event_type, description, user_id, details)
    END IF
END FUNCTION

FUNCTION log_database_error(operation STRING, error_code INTEGER, error_message STRING, user_id INTEGER)
    DEFINE log_message STRING
    
    LET log_message = "Database error - Operation: " || operation || 
                      ", Code: " || error_code || 
                      ", Message: " || error_message
    
    CALL log_error(LOG_TYPE_DATABASE, log_message, user_id, NULL)
END FUNCTION

FUNCTION log_application_event(event_description STRING, user_id INTEGER, additional_data STRING)
    CALL log_info(LOG_TYPE_APPLICATION, event_description, user_id, additional_data)
END FUNCTION

# ------------------ CORE LOGGING FUNCTIONS -------------------
FUNCTION log_debug(log_type STRING, message STRING, user_id INTEGER, additional_data STRING)
    IF g_log_enabled AND g_log_level <= LOG_LEVEL_DEBUG THEN
        CALL write_log_entry(LOG_LEVEL_DEBUG, log_type, message, user_id, additional_data)
    END IF
END FUNCTION

FUNCTION log_info(log_type STRING, message STRING, user_id INTEGER, additional_data STRING)
    IF g_log_enabled AND g_log_level <= LOG_LEVEL_INFO THEN
        CALL write_log_entry(LOG_LEVEL_INFO, log_type, message, user_id, additional_data)
    END IF
END FUNCTION

FUNCTION log_warn(log_type STRING, message STRING, user_id INTEGER, additional_data STRING)
    IF g_log_enabled AND g_log_level <= LOG_LEVEL_WARN THEN
        CALL write_log_entry(LOG_LEVEL_WARN, log_type, message, user_id, additional_data)
    END IF
END FUNCTION

FUNCTION log_error(log_type STRING, message STRING, user_id INTEGER, additional_data STRING)
    IF g_log_enabled AND g_log_level <= LOG_LEVEL_ERROR THEN
        CALL write_log_entry(LOG_LEVEL_ERROR, log_type, message, user_id, additional_data)
    END IF
END FUNCTION

FUNCTION log_fatal(log_type STRING, message STRING, user_id INTEGER, additional_data STRING)
    IF g_log_enabled AND g_log_level <= LOG_LEVEL_FATAL THEN
        CALL write_log_entry(LOG_LEVEL_FATAL, log_type, message, user_id, additional_data)
    END IF
END FUNCTION

# ------------------ LOG WRITING FUNCTIONS -------------------
FUNCTION write_log_entry(level SMALLINT, log_type STRING, message STRING, user_id INTEGER, additional_data STRING)
    DEFINE log_entry STRING
    DEFINE timestamp STRING
    DEFINE level_text STRING
    
    -- Get current timestamp
    LET timestamp = CURRENT YEAR TO FRACTION(3)
    
    -- Convert log level to text
    CASE level
        WHEN LOG_LEVEL_DEBUG
            LET level_text = "DEBUG"
        WHEN LOG_LEVEL_INFO
            LET level_text = "INFO"
        WHEN LOG_LEVEL_WARN
            LET level_text = "WARN"
        WHEN LOG_LEVEL_ERROR
            LET level_text = "ERROR"
        WHEN LOG_LEVEL_FATAL
            LET level_text = "FATAL"
        OTHERWISE
            LET level_text = "UNKNOWN"
    END CASE
    
    -- Format log entry
    LET log_entry = timestamp || " [" || level_text || "] [" || log_type || "] " ||
                    "User:" || NVL(user_id, 0) || " - " || message
    
    IF additional_data IS NOT NULL THEN
        LET log_entry = log_entry || " | Data: " || additional_data
    END IF
    
    -- Write to file if enabled
    IF g_log_to_file THEN
        CALL write_to_log_file(log_entry)
    END IF
    
    -- Write to database if enabled
    IF g_log_to_database THEN
        CALL insert_system_log(level, log_type, message, user_id, additional_data)
    END IF
    
    -- Also display to console for development
    DISPLAY log_entry
END FUNCTION

FUNCTION write_to_log_file(log_entry STRING)
    DEFINE log_channel base.Channel
    
    TRY
        LET log_channel = base.Channel.create()
        CALL log_channel.openFile(g_log_file_path, "a")  -- Append mode
        CALL log_channel.writeLine(log_entry)
        CALL log_channel.close()
    CATCH
        -- If file logging fails, at least display the error
        DISPLAY "Error writing to log file: ", STATUS
        DISPLAY "Log entry: ", log_entry
    END TRY
END FUNCTION

FUNCTION create_log_directory()
    DEFINE log_dir STRING
    DEFINE pos INTEGER
    
    -- Extract directory from log file path
    #LET pos = os.Path.fullPath(/logs)  -- Find last slash
    IF pos > 0 THEN
        LET log_dir = g_log_file_path.subString(1, pos-1)
        
        -- Create directory if it doesn't exist
        IF NOT os.Path.exists(log_dir) THEN
            TRY
                #CALL os.Path.mkdir(log_dir)
                DISPLAY "Created log directory: ", log_dir
            CATCH
                DISPLAY "Warning: Could not create log directory: ", log_dir
                -- Fall back to current directory
                LET g_log_file_path = "xacterp.log"
            END TRY
        END IF
    END IF
END FUNCTION

# ------------------ DATABASE LOGGING FUNCTIONS -------------------
{
FUNCTION insert_login_log(user_id INTEGER, username STRING, status STRING, failure_reason STRING, client_info STRING)
    DEFINE ip_address STRING
    DEFINE user_agent STRING
    
    -- Parse client info (assuming format: "IP:USER_AGENT")
    CALL parse_client_info(client_info) RETURNING ip_address, user_agent
    
    TRY
        INSERT INTO sy00_login_log (
            user_id,
            username,
            login_time,
            status,
            failure_reason,
            ip_address,
            user_agent
        ) VALUES (
            user_id,
            username.trim(),
            CURRENT,
            status,
            failure_reason,
            ip_address,
            user_agent
        )
    CATCH
        -- Log database insertion error to file only (avoid recursion)
        DISPLAY "Error inserting login log: ", SQLCA.SQLERRM
    END TRY
END FUNCTION

FUNCTION insert_system_log(level SMALLINT, log_type STRING, message STRING, user_id INTEGER, additional_data STRING)
    TRY
        -- Check if system log table exists, create if not
        CALL ensure_system_log_table()
        
        INSERT INTO sy00_system_log (
            log_level,
            log_type,
            message,
            user_id,
            additional_data,
            created_at
        ) VALUES (
            level,
            log_type,
            message,
            user_id,
            additional_data,
            CURRENT
        )
    CATCH
        -- Don't recursively log this error, just display
        DISPLAY "Error inserting system log: ", SQLCA.SQLERRM
    END TRY
END FUNCTION

FUNCTION insert_security_log(event_type STRING, description STRING, user_id INTEGER, details STRING)
    TRY
        -- Check if security log table exists, create if not
        CALL ensure_security_log_table()
        
        INSERT INTO sy00_security_log (
            event_type,
            description,
            user_id,
            details,
            created_at
        ) VALUES (
            event_type,
            description,
            user_id,
            details,
            CURRENT
        )
    CATCH
        DISPLAY "Error inserting security log: ", SQLCA.SQLERRM
    END TRY
END FUNCTION
}
# ------------------ HELPER FUNCTIONS -------------------
FUNCTION parse_client_info(client_info STRING) RETURNS (STRING, STRING)
    DEFINE ip_address STRING
    DEFINE user_agent STRING
    DEFINE colon_pos INTEGER
    
    IF client_info IS NULL THEN
        RETURN "unknown", "unknown"
    END IF
    
    LET colon_pos = client_info.getIndexOf(":", 1)
    IF colon_pos > 0 THEN
        LET ip_address = client_info.subString(1, colon_pos-1)
        LET user_agent = client_info.subString(colon_pos+1, client_info.getLength())
    ELSE
        LET ip_address = client_info
        LET user_agent = "unknown"
    END IF
    
    RETURN ip_address, user_agent
END FUNCTION

FUNCTION get_client_info() RETURNS STRING
    DEFINE client_ip STRING
    DEFINE user_agent STRING
    
    -- Get client IP
    TRY
        LET client_ip = fgl_getenv("REMOTE_ADDR")
        IF client_ip IS NULL THEN
            LET client_ip = "127.0.0.1"
        END IF
    CATCH
        LET client_ip = "unknown"
    END TRY
    
    -- Get user agent
    TRY
        LET user_agent = fgl_getenv("HTTP_USER_AGENT")
        IF user_agent IS NULL THEN
            LET user_agent = "Genero Desktop Client"
        END IF
    CATCH
        LET user_agent = "unknown"
    END TRY
    
    RETURN client_ip || ":" || user_agent
END FUNCTION

FUNCTION update_user_last_login(user_id INTEGER)
    TRY
        UPDATE sy00_user
        SET last_login_at = CURRENT,
            login_attempts = 0  -- Reset failed attempts on successful login
        WHERE user_id = user_id
    CATCH
        -- Don't fail the login process if this fails
        DISPLAY "Warning: Could not update last login time for user ", user_id
    END TRY
END FUNCTION
--
{
FUNCTION increment_failed_attempts(username STRING)
    TRY
        UPDATE sy00_user
        SET login_attempts = NVL(login_attempts, 0) + 1
        WHERE LOWER(username) = LOWER(username.trim())
        AND deleted_at IS NULL
    CATCH
        DISPLAY "Warning: Could not increment failed login attempts for ", username
    END TRY
END FUNCTION
}
# ------------------ TABLE CREATION FUNCTIONS -------------------
FUNCTION ensure_system_log_table()
    DEFINE table_exists INTEGER
    
    -- Check if table exists
    SELECT COUNT(*) INTO table_exists
    FROM systables
    WHERE tabname = "sy00_system_log"
    
    IF table_exists = 0 THEN
        CALL create_system_log_table()
    END IF
END FUNCTION

FUNCTION ensure_security_log_table()
    DEFINE table_exists INTEGER
    
    -- Check if table exists
    SELECT COUNT(*) INTO table_exists
    FROM systables
    WHERE tabname = "sy00_security_log"
    
    IF table_exists = 0 THEN
        CALL create_security_log_table()
    END IF
END FUNCTION

FUNCTION create_system_log_table()
    TRY
        CREATE TABLE sy00_system_log (
            log_id SERIAL NOT NULL,
            log_level SMALLINT NOT NULL,
            log_type VARCHAR(20) NOT NULL,
            message VARCHAR(500) NOT NULL,
            user_id INTEGER,
            additional_data VARCHAR(1000),
            created_at DATETIME YEAR TO FRACTION DEFAULT CURRENT,
            
            PRIMARY KEY (log_id)
        )
        
        CREATE INDEX idx_system_log_type ON sy00_system_log(log_type)
        CREATE INDEX idx_system_log_user ON sy00_system_log(user_id)
        CREATE INDEX idx_system_log_time ON sy00_system_log(created_at)
        
        DISPLAY "System log table created successfully"
    CATCH
        DISPLAY "Error creating system log table: ", SQLCA.SQLERRM
    END TRY
END FUNCTION

FUNCTION create_security_log_table()
    TRY
        CREATE TABLE sy00_security_log (
            log_id SERIAL NOT NULL,
            event_type VARCHAR(50) NOT NULL,
            description VARCHAR(500) NOT NULL,
            user_id INTEGER,
            details VARCHAR(1000),
            created_at DATETIME YEAR TO FRACTION DEFAULT CURRENT,
            
            PRIMARY KEY (log_id)
        )
        
        CREATE INDEX idx_security_log_type ON sy00_security_log(event_type)
        CREATE INDEX idx_security_log_user ON sy00_security_log(user_id)
        CREATE INDEX idx_security_log_time ON sy00_security_log(created_at)
        
        DISPLAY "Security log table created successfully"
    CATCH
        DISPLAY "Error creating security log table: ", SQLCA.SQLERRM
    END TRY
END FUNCTION

# ------------------ CONFIGURATION FUNCTIONS -------------------
FUNCTION set_log_level(level SMALLINT)
    LET g_log_level = level
    CALL log_info(LOG_TYPE_SYSTEM, "Log level changed to " || level, NULL, NULL)
END FUNCTION

FUNCTION set_log_file_path(file_path STRING)
    LET g_log_file_path = file_path
    CALL create_log_directory()
    CALL log_info(LOG_TYPE_SYSTEM, "Log file path changed to " || file_path, NULL, NULL)
END FUNCTION

FUNCTION enable_database_logging(enabled BOOLEAN)
    LET g_log_to_database = enabled
    CALL log_info(LOG_TYPE_SYSTEM, "Database logging " || IIF(enabled, "enabled", "disabled"), NULL, NULL)
END FUNCTION

FUNCTION enable_file_logging(enabled BOOLEAN)
    LET g_log_to_file = enabled
    CALL log_info(LOG_TYPE_SYSTEM, "File logging " || IIF(enabled, "enabled", "disabled"), NULL, NULL)
END FUNCTION