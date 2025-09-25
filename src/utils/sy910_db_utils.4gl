
# ==============================================================
# Program   :   sy900_db_utils.4gl
# Purpose   :   database connection and init programs 
# Module    :   DB Utils
# Number    :   910
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.2.1
# ==============================================================

FUNCTION initialize_database() RETURNS SMALLINT
    DEFINE db_status SMALLINT
    -- Connect to database
    LET db_status = 0

    TRY
        CONNECT TO "xactapp_db@localhost:5432+driver='dbmpgs_9'"
            USER "postgres" USING "napoleon"
        RETURN 1

        DISPLAY "Connected to database: "
    CATCH

        ERROR   "Database connection failed: ", SQLCA.SQLCODE  ||
                "Error message: ", SQLCA.SQLERRM
        EXIT PROGRAM
    END TRY
    RETURN 0

END FUNCTION
