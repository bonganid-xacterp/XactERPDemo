-- ==============================================================
-- Program   : utils_db.4gl
-- Purpose   : Database connection and initialization utilities
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

-- Establish connection to PostgreSQL database
FUNCTION initialize_database() RETURNS SMALLINT
    TRY
        CONNECT TO "demoapp_db@localhost:5432+driver='dbmpgs_9'"
            USER "postgres" USING "napoleon"
        DISPLAY "Connected to database: demoapp_db"
        RETURN TRUE
    CATCH
        DISPLAY "Database connection failed!"
        DISPLAY "SQLCODE: ", SQLCA.SQLCODE
        DISPLAY "Error: ", SQLCA.SQLERRM
        RETURN FALSE
    END TRY

END FUNCTION

-- Disconnect from database cleanly
FUNCTION close_database() RETURNS SMALLINT
    TRY
        DISCONNECT CURRENT
        DISPLAY "Database connection closed successfully"
        RETURN TRUE
    CATCH
        DISPLAY "Warning: Database disconnect error - ", SQLCA.SQLCODE
        DISPLAY "Error message: ", SQLCA.SQLERRM
        RETURN FALSE
    END TRY
END FUNCTION

-- Verify database connection is active
FUNCTION check_database_connection() RETURNS SMALLINT
    DEFINE test_count INTEGER
    TRY
        SELECT COUNT(*)
            INTO test_count
            FROM pg_tables
            WHERE schemaname = 'public'
        IF SQLCA.SQLCODE = 0 THEN
            DISPLAY "Database connection verified"
            RETURN TRUE
        ELSE
            DISPLAY "Database connection verification failed"
            RETURN FALSE
        END IF
    CATCH
        DISPLAY "Database connection test failed: ", SQLCA.SQLCODE
        RETURN FALSE
    END TRY
END FUNCTION

-- Attempt to reconnect to database
FUNCTION reconnect_database() RETURNS SMALLINT
    DEFINE db_result SMALLINT
    LET db_result = close_database()
    SLEEP 1
    RETURN initialize_database()
END FUNCTION

-- Return current database connection information
FUNCTION get_database_info() RETURNS STRING
    DEFINE info STRING
    LET info = "Database: demoapp_db\n"
    LET info = info || "Server  : localhost:5432\n"
    LET info = info || "Driver  : dbmpgs_9 (PostgreSQL)\n"
    LET info = info || "User    : postgres\n"
    LET info = info || "Status  : "
    IF check_database_connection() THEN
        LET info = info || "Connected"
    ELSE
        LET info = info || "Disconnected"
    END IF
    RETURN info
END FUNCTION

-- Run diagnostic tests on database connectivity
FUNCTION test_database_connection() RETURNS SMALLINT
    DEFINE test_result SMALLINT
    DISPLAY "=========================================="
    DISPLAY "Database Connection Test"
    DISPLAY "=========================================="
    DISPLAY "Test 1: Checking connection..."
    IF NOT check_database_connection() THEN
        DISPLAY "? Connection failed"
        RETURN FALSE
    END IF
    DISPLAY "? Connection active"
    DISPLAY "Test 2: Querying system tables..."
    TRY
        DECLARE test_cursor CURSOR FOR
            SELECT tablename FROM pg_tables WHERE schemaname = 'public'
        OPEN test_cursor
        CLOSE test_cursor
        FREE test_cursor
        DISPLAY "? System tables accessible"
        LET test_result = TRUE
    CATCH
        DISPLAY "? System table query failed: ", SQLCA.SQLCODE
        LET test_result = FALSE
    END TRY
    DISPLAY "=========================================="
    RETURN test_result
END FUNCTION
