# ==============================================================
# Program   :   sy130_logs.4gl
# Purpose   :   Centralized logging module for system activities
#
# Module    :   System (sy)
# Number    :   130
# Author    :   Bongani Dlamini
# Version   :   Genero ver 3.20.10
# ==============================================================

DEFINE log_rec RECORD
    user_id INT,
    level STRING,
    user_action STRING,
    details STRING
    END RECORD 
    
    

-- Log an activity
-- TODOS: add the logic for logging activity
FUNCTION add_log()
    # LET log_rec.user_id = log_data.
END FUNCTION

-- Loads system logs
FUNCTION load_logs()

END FUNCTION

-- DIsplay log details
FUNCTION log_details()

END FUNCTION
