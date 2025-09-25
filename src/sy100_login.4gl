# ==============================================================
# Program   :   sy100_login.4gl
# Purpose   :   App entry point for auth
# Module    :   Login
# Number    :   100
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.2.1
# ==============================================================

IMPORT ui
IMPORT FGL sy920_ui_utils

-- Global variables for user session
DEFINE g_current_user STRING
DEFINE g_user_role STRING
DEFINE g_login_attempts SMALLINT

FUNCTION login_user() RETURNS SMALLINT
    DEFINE login_result SMALLINT
    DEFINE f_username STRING
    DEFINE f_password STRING
    DEFINE max_attempts SMALLINT

    LET max_attempts = 3
    LET g_login_attempts = 0
    LET login_result = FALSE

    OPEN WINDOW w_login WITH FORM "sy100_frm_login"
    ATTRIBUTE(STYLE="dialog", TEXT="XactERP Login")


    CALL sy920_ui_utils.set_page_title("Login")

    DIALOG
        INPUT BY NAME f_username, f_password
            BEFORE INPUT
                CLEAR FORM
                NEXT FIELD f_username

            AFTER FIELD f_password
                -- Try to login after leaving password field
                LET login_result =
                    try_login(f_username, f_password, max_attempts)
                IF login_result = TRUE OR g_login_attempts >= max_attempts THEN
                    EXIT DIALOG
                END IF

            ON ACTION login
                -- Try to login on button press
                LET login_result =
                    try_login(f_username, f_password, max_attempts)
                IF login_result = TRUE OR g_login_attempts >= max_attempts THEN
                    EXIT DIALOG
                END IF

            ON ACTION cancel
                IF confirm_exit_login() THEN
                    LET login_result = FALSE
                    EXIT DIALOG
                END IF

            ON ACTION credentials ATTRIBUTE(TEXT = "Credentials")
                CALL show_help_dialog()

        END INPUT

        ON ACTION close
            IF confirm_exit_login() THEN
                LET login_result = FALSE
                EXIT DIALOG
            END IF
    END DIALOG

    CLOSE WINDOW w_login
    RETURN login_result
END FUNCTION

-- Centralized login validation logic
FUNCTION try_login(
    f_username STRING, f_password STRING, max_attempts SMALLINT)
    RETURNS SMALLINT
    DEFINE result SMALLINT
    LET result = FALSE

    LET g_login_attempts = g_login_attempts + 1

    IF validate_login(f_username, f_password) THEN
        LET g_current_user = f_username
        MESSAGE "Welcome " || f_username || "!"
        LET result = TRUE
    ELSE
        IF g_login_attempts >= max_attempts THEN
            ERROR "Maximum login attempts exceeded. Exiting system."
        ELSE
            ERROR "Invalid credentials. Attempt "
                || g_login_attempts
                || " of "
                || max_attempts
            CLEAR f_password
        END IF
    END IF

    RETURN result
END FUNCTION

-- ------------------ AUTH VALIDATION -------------------
FUNCTION validate_login(f_username STRING, f_password STRING) RETURNS SMALLINT
    DEFINE is_valid SMALLINT

    LET is_valid = FALSE

    -- Remove leading/trailing spaces
    LET f_username = f_username.trim()
    LET f_password = f_password.trim()

    -- Check for empty fields
    IF f_username.getLength() = 0 THEN
        ERROR "Username is required"
        RETURN FALSE
    END IF

    IF f_password.getLength() = 0 THEN
        ERROR "Password is required"
        RETURN FALSE
    END IF

    -- TODOS: Replace with database lookup
    CASE f_username.toLowerCase()
        WHEN "admin"
            IF f_password = "1234" THEN
                LET g_user_role = "Administrator"
                LET is_valid = TRUE
            END IF

        WHEN "user"
            IF f_password = "user123" THEN
                LET g_user_role = "User"
                LET is_valid = TRUE
            END IF

        WHEN "demo"
            IF f_password = "demo" THEN
                LET g_user_role = "Demo User"
                LET is_valid = TRUE
            END IF

        OTHERWISE
            LET is_valid = FALSE
    END CASE

    IF NOT is_valid THEN
        -- Log failed attempt (TODO: implement logging)
        DISPLAY "Failed login attempt for user: ", f_username
    END IF

    RETURN is_valid
END FUNCTION

-- ------------------ UTILITY FUNCTIONS -------------------
FUNCTION get_current_user() RETURNS STRING
    RETURN g_current_user
END FUNCTION

FUNCTION get_user_role() RETURNS STRING
    RETURN g_user_role
END FUNCTION

FUNCTION confirm_exit_login() RETURNS SMALLINT
    DEFINE result SMALLINT

    MENU "Confirm Exit"
        ATTRIBUTE(STYLE = "dialog",
            COMMENT = "Are you sure you want to cancel login?")
        COMMAND "Yes"
            LET result = TRUE
            EXIT MENU
        COMMAND "No"
            LET result = FALSE
            EXIT MENU
    END MENU

    RETURN result
END FUNCTION

FUNCTION show_help_dialog()
    ERROR "Login Help:\n\nDemo Credentials:\n"
        || "Username: admin, Password: 1234\n"
        || "Username: user, Password: user123\n"
        || "Username: demo, Password: demo\n\n"
        || "Press F1 for help, ESC to cancel"
END FUNCTION

-- ------------------ SESSION MANAGEMENT -------------------
FUNCTION clear_user_session()
    LET g_current_user = NULL
    LET g_user_role = NULL
    LET g_login_attempts = 0
END FUNCTION

FUNCTION is_user_authenticated() RETURNS SMALLINT
    RETURN (g_current_user IS NOT NULL AND g_current_user.getLength() > 0)
END FUNCTION
