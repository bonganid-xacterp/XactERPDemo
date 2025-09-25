# Database Utilities

FUNCTION initialize_database(p_dbname STRING)

    -- Set your database name/connection string
    LET p_dbname = "xactapp_db"

    -- Connect to database
    TRY
        DATABASE p_dbname
        DISPLAY "Connected to database: ", p_dbname
    CATCH
        DISPLAY "Database connection failed: ", SQLCA.SQLCODE
        DISPLAY "Error message: ", SQLCA.SQLERRM
        EXIT PROGRAM
    END TRY
END FUNCTION
