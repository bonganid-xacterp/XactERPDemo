
# ==============================================================
# Program   :   sy900_utils.4gl
# Purpose   :   These are system wide reusable programs 
# Module    :   Utils
# Number    :   900
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.2.1
# ==============================================================


-- DATABASE INITIALIZATION
FUNCTION initialize_database()
    DEFINE db_name STRING

    -- Set your database name/connection string
    LET db_name = "xactapp_db"

    -- Connect to database
    TRY
        DATABASE db_name
        DISPLAY "Connected to database: ", db_name
    CATCH
        DISPLAY "Database connection failed: ", SQLCA.SQLCODE
        DISPLAY "Error message: ", SQLCA.SQLERRM
        EXIT PROGRAM
    END TRY

END FUNCTION

-- Utility functions for global dialogs and UI helpers

FUNCTION show_alert(p_message STRING)
    DEFINE g_alert_win ui.Window
    DEFINE g_alert_form ui.Form

    -- Open a small modal window with your alert form
    OPEN WINDOW w_alert WITH FORM "frm_sy900_alert"
    LET g_alert_win = ui.Window.getCurrent()
    LET g_alert_form = g_alert_win.getForm()
    CALL g_alert_win.setText("System Alert")

    -- Populate the form label with the passed message
    CALL g_alert_form.setElementText("lbl_message", p_message)

    -- Dialog waits for user to acknowledge
    DIALOG
        INPUT BY NAME p_message
            -- User presses OK
            ON ACTION ok
                EXIT DIALOG
        END INPUT
    END DIALOG

    CLOSE WINDOW w_alert
END FUNCTION

-- Utility function for setting the program page title

FUNCTION set_page_title(p_title STRING)
    DEFINE g_win ui.Window

    LET g_win = ui.Window.getCurrent()
    IF g_win IS NOT NULL THEN
        CALL g_win.setText("XACT ERP Demo – " || p_title)
    END IF
END FUNCTION

