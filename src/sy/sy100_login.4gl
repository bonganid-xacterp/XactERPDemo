# ==============================================================
# Program   :   sy100_login.4gl
# Purpose   :   App entry point for authentication
# Module    :   System (sy)
# Number    :   100
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.20.10
# ==============================================================

IMPORT ui
IMPORT FGL utils_globals

-- Global variables for user session
DEFINE g_current_user STRING
DEFINE g_user_role STRING
DEFINE g_login_attempts SMALLINT

FUNCTION login_user() RETURNS SMALLINT
    DEFINE login_result SMALLINT
    DEFINE f_username STRING
    DEFINE f_password STRING
    DEFINE max_attempts SMALLINT
    DEFINE f ui.Form

    LET max_attempts = 3
    LET g_login_attempts = 0
    LET login_result = FALSE

    OPEN WINDOW w_login
        WITH
        FORM "sy100_login"
        ATTRIBUTE(STYLE = "dialog", TEXT = "XactERP Login")

    LET f = ui.Window.getCurrent().getForm()
    CALL f.setElementImage("company_logo", "logo.png")

    DIALOG
        INPUT BY NAME f_username, f_password
            BEFORE INPUT
                CLEAR FORM
                NEXT FIELD f_username

            AFTER FIELD f_password
                LET login_result =
                    try_login(f_username, f_password, max_attempts)
                IF login_result = TRUE THEN
                    EXIT DIALOG
                END IF

                IF g_login_attempts < max_attempts THEN
                    NEXT FIELD f_password
                ELSE
                    EXIT DIALOG
                END IF

            ON ACTION cancel
                IF confirm_exit_login() THEN
                    LET login_result = FALSE
                    EXIT DIALOG
                END IF

        END INPUT
    END DIALOG

    CLOSE WINDOW w_login
    RETURN login_result
END FUNCTION

-- LOGIN CHECK
FUNCTION try_login(
    f_username STRING, f_password STRING, max_attempts SMALLINT)
    RETURNS SMALLINT
    DEFINE result SMALLINT
    LET result = FALSE

    LET g_login_attempts = g_login_attempts + 1
    LET f_username = f_username.trim()
    LET f_password = f_password.trim()

    IF validate_login(f_username, f_password) THEN
        LET g_current_user = f_username
        MESSAGE "Welcome " || f_username || "!"
        LET result = TRUE
    ELSE
        IF g_login_attempts >= max_attempts THEN
            ERROR "Maximum login attempts exceeded."
        ELSE
            ERROR "Invalid credentials. Attempt "
                || g_login_attempts
                || " of "
                || max_attempts
        END IF
    END IF
    RETURN result
END FUNCTION

-- HARDCODED DEMO VALIDATION (replace with DB later)
FUNCTION validate_login(f_username STRING, f_password STRING) RETURNS SMALLINT
    CASE f_username.toLowerCase()
        WHEN "admin"
            IF f_password = "1234" THEN
                LET g_user_role = "Administrator"
                RETURN TRUE
            END IF
        WHEN "user"
            IF f_password = "user123" THEN
                LET g_user_role = "User"
                RETURN TRUE
            END IF
        WHEN "demo"
            IF f_password = "demo" THEN
                LET g_user_role = "Demo User"
                RETURN TRUE
            END IF
    END CASE

    RETURN FALSE
END FUNCTION

-- SESSION HELPERS
FUNCTION get_current_user() RETURNS STRING
    RETURN g_current_user
END FUNCTION

FUNCTION get_user_role() RETURNS STRING
    RETURN g_user_role
END FUNCTION

FUNCTION confirm_exit_login() RETURNS SMALLINT
    DEFINE result SMALLINT
    MENU "Confirm Exit" ATTRIBUTE(STYLE = "dialog")
        COMMAND "Yes"
            LET result = TRUE
            EXIT MENU
        COMMAND "No"
            LET result = FALSE
            EXIT MENU
    END MENU
    RETURN result
END FUNCTION
