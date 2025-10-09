# ==============================================================
# Program   : sy100_login.4gl
# Purpose   : Handles user login and authentication
# Module    : System (sy)
# Author    : Bongani Dlamini
# Version   : Genero ver 3.20.10
# ==============================================================

IMPORT ui
IMPORT FGL utils_globals

-- --------------------------------------------------------------
-- GLOBAL VARIABLES
-- --------------------------------------------------------------
DEFINE g_current_user STRING
DEFINE g_user_role    STRING
DEFINE g_login_tries  SMALLINT

CONSTANT MAX_LOGIN_ATTEMPTS = 3

-- --------------------------------------------------------------
-- MAIN LOGIN FUNCTION
-- --------------------------------------------------------------
PUBLIC FUNCTION login_user() RETURNS SMALLINT
    DEFINE f_username, f_password STRING
    DEFINE f ui.Form
    DEFINE ok SMALLINT

    LET g_login_tries = 0
    LET ok = FALSE

    -- Open login window
    OPEN WINDOW w_login WITH FORM "sy100_login"
        ATTRIBUTES(STYLE="dialog", TEXT="XACT ERP Login")

    -- Show company logo if available
    LET f = ui.Window.getCurrent().getForm()
    CALL f.setElementImage("company_logo", "logo.png")

    DIALOG
        INPUT BY NAME f_username, f_password

            BEFORE INPUT
                CLEAR FORM
                NEXT FIELD f_username

            AFTER FIELD f_password
                IF try_login(f_username, f_password) THEN
                    LET ok = TRUE
                    EXIT DIALOG
                ELSE
                    IF g_login_tries < MAX_LOGIN_ATTEMPTS THEN
                        NEXT FIELD f_password
                    ELSE
                        EXIT DIALOG
                    END IF
                END IF

            ON ACTION cancel
                IF confirm_exit_login() THEN
                    EXIT DIALOG
                END IF
        END INPUT
    END DIALOG

    CLOSE WINDOW w_login
    RETURN ok
END FUNCTION

-- --------------------------------------------------------------
-- TRY LOGIN (handles retry and validation)
-- --------------------------------------------------------------
FUNCTION try_login(p_user STRING, p_pass STRING) RETURNS SMALLINT
    DEFINE valid SMALLINT
    LET g_login_tries = g_login_tries + 1
    LET valid = FALSE

    IF validate_login(p_user.trim(), p_pass.trim()) THEN
        LET g_current_user = p_user
        MESSAGE "Welcome " || p_user || "!"
        LET valid = TRUE
    ELSE
        IF g_login_tries >= MAX_LOGIN_ATTEMPTS THEN
            ERROR "Maximum login attempts exceeded."
        ELSE
            ERROR "Invalid credentials (" || g_login_tries || "/" ||
                   MAX_LOGIN_ATTEMPTS || ")"
        END IF
    END IF

    RETURN valid
END FUNCTION

-- --------------------------------------------------------------
-- SIMPLE DEMO VALIDATION (to replace with DB query later)
-- --------------------------------------------------------------
FUNCTION validate_login(p_user STRING, p_pass STRING) RETURNS SMALLINT
    CASE p_user.toLowerCase()
        WHEN "admin" IF p_pass = "1234" THEN LET g_user_role = "Administrator"; RETURN TRUE END IF
        WHEN "user"  IF p_pass = "user123" THEN LET g_user_role = "User"; RETURN TRUE END IF
        WHEN "demo"  IF p_pass = "demo" THEN LET g_user_role = "Demo User"; RETURN TRUE END IF
    END CASE
    RETURN FALSE
END FUNCTION

-- --------------------------------------------------------------
-- SESSION GETTERS
-- --------------------------------------------------------------
PUBLIC FUNCTION get_current_user() RETURNS STRING
    RETURN g_current_user
END FUNCTION

PUBLIC FUNCTION get_user_role() RETURNS STRING
    RETURN g_user_role
END FUNCTION

-- --------------------------------------------------------------
-- CONFIRM EXIT PROMPT
-- --------------------------------------------------------------
FUNCTION confirm_exit_login() RETURNS SMALLINT
    DEFINE ans STRING
    LET ans = utils_globals.show_confirm("Exit Login", "Do you want to cancel login?")
    RETURN ans = "yes"
END FUNCTION