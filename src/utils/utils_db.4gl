-- ==============================================================
-- Program   :   utils_db.4gl
-- Purpose   :   Database connection and initialization
-- Module    :   Utils (utils)
-- Number    :
-- Author    :   Bongani Dlamini
-- Version   :   Genero BDL 3.20.10
-- ==============================================================

-- ==============================================================
-- Function: initialize_database
-- Purpose:  Establish connection to PostgreSQL database
-- Returns:  TRUE (1) if successful, FALSE (0) if failed
-- ==============================================================
FUNCTION initialize_database() RETURNS SMALLINT

    TRY
        -- Connect to PostgreSQL database
        CONNECT TO "xactdemo_db@localhost:5432+driver='dbmpgs_9'"
            USER "postgres" USING "napoleon"

        DISPLAY "Connected to database: xactdemo_db"

        -- Verify connection
        --IF check_database_connection() THEN
        RETURN TRUE
        --ELSE
        --    RETURN FALSE
        --END IF

    CATCH
        -- Display detailed error information
        DISPLAY "Database connection failed!"
        DISPLAY "SQLCA.SQLCODE: ", SQLCA.SQLCODE
        DISPLAY "Error message: ", SQLCA.SQLERRM

        -- Return failure
        RETURN FALSE
    END TRY

END FUNCTION

-- ==============================================================
-- Function: close_database
-- Purpose:  Disconnect from database cleanly
-- Returns:  TRUE if successful, FALSE otherwise
-- ==============================================================
FUNCTION close_database() RETURNS SMALLINT

    TRY
        -- Check if there's an active connection
        IF SQLCA.SQLCODE = 0 THEN
            DISCONNECT CURRENT
            DISPLAY "Database connection closed successfully"
        END IF

        RETURN 1

    CATCH
        DISPLAY "Warning: Database disconnect error - ", SQLCA.SQLCODE
        DISPLAY "Error message: ", SQLCA.SQLERRM
        RETURN 0
    END TRY

END FUNCTION

-- ==============================================================
-- Function: check_database_connection
-- Purpose:  Verify database connection is active
-- Returns:  TRUE if connected, FALSE otherwise
-- ==============================================================
PRIVATE FUNCTION check_database_connection() RETURNS SMALLINT
    DEFINE test_count INTEGER

    TRY
        -- Simple query to verify connection
        SELECT COUNT(*) INTO test_count FROM systables WHERE tabid = 1

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

-- ==============================================================
-- Function: reconnect_database
-- Purpose:  Attempt to reconnect to database
-- Returns:  TRUE if successful, FALSE otherwise
-- ==============================================================
FUNCTION reconnect_database() RETURNS SMALLINT

    -- First, try to close existing connection
    #CALL close_database()

    -- Wait a moment
    SLEEP 1

    -- Attempt reconnection
    RETURN initialize_database()

END FUNCTION

-- ==============================================================
-- Function: get_database_info
-- Purpose:  Return current database connection information
-- Returns:  String with database details
-- ==============================================================
FUNCTION get_database_info() RETURNS STRING
    DEFINE info STRING

    LET info = "Database: xactdemo_db\n"
    LET info = info || "Server: localhost:5432\n"
    LET info = info || "Driver: dbmpgs_9 (PostgreSQL)\n"
    LET info = info || "User: postgres\n"
    LET info = info || "Status: "

    IF check_database_connection() THEN
        LET info = info || "Connected"
    ELSE
        LET info = info || "Disconnected"
    END IF

    RETURN info

END FUNCTION

-- ==============================================================
-- Function: test_database_connection
-- Purpose:  Test database connection with detailed diagnostics
-- Returns:  TRUE if all tests pass
-- ==============================================================
FUNCTION test_database_connection() RETURNS SMALLINT
    DEFINE test_result SMALLINT

    DISPLAY "=========================================="
    DISPLAY "Database Connection Test"
    DISPLAY "=========================================="

    -- Test 1: Connection exists
    DISPLAY "Test 1: Checking connection..."
    IF check_database_connection() THEN
        DISPLAY "? Connection active"
    ELSE
        DISPLAY "? Connection failed"
        RETURN FALSE
    END IF

    -- Test 2: Can query system tables
    DISPLAY "Test 2: Querying system tables..."
    TRY
        DECLARE test_cursor CURSOR FOR
            SELECT tabname FROM systables WHERE tabid < 10

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

-- ==============================================================
-- Function: begin_transaction
-- Purpose:  Start a database transaction
-- Returns:  TRUE if successful
-- ==============================================================
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

-- ==============================================================
-- Function: commit_transaction
-- Purpose:  Commit current transaction
-- Returns:  TRUE if successful
-- ==============================================================
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

-- ==============================================================
-- Function: rollback_transaction
-- Purpose:  Rollback current transaction
-- Returns:  TRUE if successful
-- ==============================================================
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
