# Database Utilities

IMPORT FGL sy920_ui_utils

FUNCTION initialize_database(p_dbname STRING)
    TRY
        DATABASE p_dbname
        DISPLAY "Connected to database: ", p_dbname
    CATCH
        CALL sy920_ui_utils.show_alert(
            "Database connection failed: " || SQLCA.SQLCODE || " " || SQLCA.SQLERRM,
            "DB Error"
        )
        EXIT PROGRAM
    END TRY
END FUNCTION
