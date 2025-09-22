# ==============================================================
# Program   :   sy100_main.4gl
# Purpose   :   App entry point with login + main container
# Module    :   Main
# Number    :   100
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.2.1
# ==============================================================

IMPORT os
IMPORT ui
IMPORT security -- For password hashing (if available)
IMPORT util -- For crypto functions

-- TODO: Need to move the code that can be global to libs
# DB Connection
# Persistant user state
# Error handler
# Loading State
# Alert messages

DEFINE g_win ui.Window
DEFINE g_form ui.Form
DEFINE f_username STRING
DEFINE f_password STRING
DEFINE g_env STRING 

MAIN
    DEFER INTERRUPT
    CLOSE WINDOW SCREEN
    -- Initialize database connection
    #CALL initialize_database()
    #CALL run_console_login()
    CALL run_login()
END MAIN

# ----------------- RUN CONSOLE LOGIN ----------------
FUNCTION run_console_login()

  
END FUNCTION

# ------------------ DATABASE INITIALIZATION -------------------
FUNCTION initialize_database()
    DEFINE db_name STRING

    -- Set your database name/connection string
    LET db_name = "xactdemo"

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

# ------------------ LOGIN FLOW -------------------
FUNCTION run_login()
    DEFINE login_state SMALLINT

    -- Open login window
    OPEN WINDOW w_login WITH FORM "frm_login"
    LET g_win = ui.Window.getCurrent()
    LET g_form = g_win.getForm()
    CALL g_win.setText("XACT ERP Demo – Login")

    -- Setup and display company logo
    CALL setup_login_image()

    -- Run login interaction
    DIALOG
        INPUT BY NAME f_username, f_password

            ON ACTION Login
                LET login_state = validate_login(f_username, f_password)

                IF login_state = 1 THEN
                    CLOSE WINDOW w_login
                    CALL open_main_container()
                    MESSAGE "Successfully logged in as: " || f_username
                    EXIT DIALOG
                ELSE
                    ERROR "Invalid username or password"
                END IF

            ON ACTION CANCEL
                CLOSE WINDOW w_login
                EXIT PROGRAM
        END INPUT
        
    END DIALOG

END FUNCTION

# ------------------ COMPANY LOGO SETUP -------------------
FUNCTION setup_login_image()
    DEFINE company_logo STRING

    -- Try different possible image paths
    LET company_logo = "resources/logo.png"

    -- Set the image
    DISPLAY company_logo
END FUNCTION

# ------------------ AUTH VALIDATION -------------------
FUNCTION validate_login(f_username STRING, f_password STRING)
    -- Simple validation logic (replace with database check)
    IF f_username = "admin" AND f_password = "1234" THEN
        MESSAGE "Login successful!"
        RETURN 1
        -- Continue to main application
    ELSE
        ERROR "Invalid username or password"
        RETURN 0
        -- Return to login form or exit
    END IF
END FUNCTION
# ------------------ MAIN CONTAINER ----------------
FUNCTION open_main_container()
    -- Open main container window
    OPEN WINDOW w_main WITH FORM "main_container"
    LET g_win = ui.Window.getCurrent()
    LET g_form = g_win.getForm()
    CALL g_win.setText("XACT ERP Demo – Main Container")

    MENU
        COMMAND "About"
            MESSAGE "About the app"
            #CALL show_about_dialog()

        COMMAND "User Profile"
            MESSAGE "User: " || f_username

        COMMAND "Quit"
            EXIT MENU

    END MENU

    CLOSE WINDOW w_main
END FUNCTION
