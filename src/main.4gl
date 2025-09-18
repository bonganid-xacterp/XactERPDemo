# ==============================================================
# Program   :   sy100_main.4gl
# Purpose   :   App entry point with login + main container
# Module    :   System (sy)
# Number    :   100
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.2.1
# ==============================================================

IMPORT os

CONSTANT k_app_version = "XACT ERP Demo v0.1"

DEFINE g_win ui.Window
DEFINE g_form ui.Form
DEFINE f_username STRING
DEFINE f_password STRING

MAIN
    DEFER INTERRUPT
    CALL run_login()
END MAIN

# ------------------ LOGIN FLOW -------------------
FUNCTION run_login()
    DEFINE ok SMALLINT

    CLOSE WINDOW SCREEN

    -- Open login window
    OPEN WINDOW w_login WITH FORM "frm_login"

    LET g_win = ui.Window.getCurrent()
    LET g_form = g_win.getForm()
    CALL g_win.setText("XACT ERP Demo – Login")

    -- Run login interaction
    DIALOG
        INPUT BY NAME f_username, f_password
            ON ACTION login
                LET ok = validate_login(f_username, f_password)
                IF ok = 1 THEN
                    MESSAGE "Successfully logged in"
                    EXIT DIALOG
                END IF

            ON ACTION cancel
                EXIT PROGRAM
        END INPUT
    END DIALOG

    CLOSE WINDOW w_login

    IF ok = 1 THEN
        CALL open_main_container()
    END IF
END FUNCTION

# ------------------ VALIDATION -------------------
FUNCTION validate_login(p_user STRING, p_pass STRING)
    DEFINE db_pass STRING
    DEFINE db_status SMALLINT
    DEFINE input_hash STRING

    -- Empty checks
    IF p_user IS NULL OR p_user = "" THEN
        ERROR "Username cannot be empty"
        RETURN 0
    END IF

    IF p_pass IS NULL OR p_pass = "" THEN
        ERROR "Password cannot be empty"
        RETURN 0
    END IF

    -- Fetch encrypted password
    SELECT password, status
        INTO db_pass, db_status
        FROM sy00_user
        WHERE username = p_user AND deleted_at IS NULL AND status = 1

    WHENEVER NOT FOUND CONTINUE

    IF db_pass IS NULL THEN
        ERROR "Invalid username or password"
        RETURN 0
    END IF

    -- Hash entered password with bcrypt
    #ET input_hash = check_password(p_pass, db_pass)

    IF input_hash = db_pass THEN
        RETURN 1
    ELSE
        ERROR "Invalid username or password"
        RETURN 0
    END IF
END FUNCTION

# ------------------ MAIN CONTAINER ----------------
FUNCTION open_main_container()
    CLOSE WINDOW SCREEN

    OPEN WINDOW w_main WITH FORM "main_container"

    LET g_win = ui.Window.getCurrent()
    LET g_form = g_win.getForm()
    CALL g_win.setText("XACT ERP Demo – Main Container")

    MENU "XACT ERP Demo"
        COMMAND "About"
            MESSAGE k_app_version
        COMMAND "Quit"
            EXIT MENU
    END MENU

    CLOSE WINDOW w_main
END FUNCTION
