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
DEFINE g_user_role STRING
DEFINE g_login_tries SMALLINT

CONSTANT MAX_LOGIN_ATTEMPTS = 3


FUNCTION login_user() RETURNS SMALLINT
    DEFINE f_username, f_password STRING
    DEFINE f ui.Form
    DEFINE ok SMALLINT

    -- Initialize
    LET ok = FALSE
    LET g_login_tries = 0

    -- ------------------------------------------------------------
    -- Open login window (dialog style)
    -- ------------------------------------------------------------
    OPTIONS INPUT WRAP
    OPEN WINDOW w_login WITH FORM "sy100_login" ATTRIBUTES(STYLE = "dialog")

    -- Attach current form reference
    IF ui.Window.getCurrent() IS NULL THEN
        DISPLAY "ERROR: Failed to get window reference"
        RETURN FALSE
    END IF

    LET f = ui.Window.getCurrent().getForm()

    -- Optional: Set company logo dynamically (if element exists)
    WHENEVER ERROR CONTINUE
        CALL f.setElementImage("company_logo", "company_logo.png")
    WHENEVER ERROR STOP

    IF STATUS != 0 THEN
        DISPLAY "Warning: Could not load company logo (company_logo.png)"
    END IF

    -- ------------------------------------------------------------
    -- Start dialog for login input
    -- ------------------------------------------------------------
    DIALOG ATTRIBUTES(UNBUFFERED)

        INPUT BY NAME f_username, f_password

            BEFORE INPUT
                CLEAR FORM
                NEXT FIELD f_username

            AFTER FIELD f_password
                -- Validate after user tabs out of password field
                IF f_password IS NOT NULL AND f_password.getLength() > 0 THEN
                    IF validate_login(f_username.trim(), f_password.trim()) THEN
                        LET g_current_user = f_username
                        MESSAGE "Welcome " || f_username || "!"
                        LET ok = TRUE
                        EXIT DIALOG
                    ELSE
                        LET g_login_tries = g_login_tries + 1

                        IF g_login_tries < MAX_LOGIN_ATTEMPTS THEN
                            ERROR SFMT("Invalid credentials (%1/%2)",
                                       g_login_tries, MAX_LOGIN_ATTEMPTS)
                            LET f_password = NULL
                            NEXT FIELD f_username
                        ELSE
                            CALL utils_globals.show_error(
                                "Maximum login attempts reached.")
                            EXIT DIALOG
                        END IF
                    END IF
                END IF

            ON ACTION cancel
                IF confirm_exit_login() THEN
                    EXIT DIALOG
                END IF

        END INPUT

    END DIALOG

    -- ------------------------------------------------------------
    -- Close login window and return result
    -- ------------------------------------------------------------
    CLOSE WINDOW w_login
    RETURN ok
END FUNCTION

-- --------------------------------------------------------------
-- SIMPLE DEMO VALIDATION (to replace with DB query later)
-- TODO: Replace hardcoded credentials with database lookup
-- TODO: Implement password hashing (BCrypt or similar)
-- TODO: Add audit logging for failed login attempts
-- --------------------------------------------------------------
FUNCTION validate_login(p_user STRING, p_pass STRING) RETURNS SMALLINT
    -- WARNING: HARDCODED CREDENTIALS - FOR DEMO PURPOSES ONLY!
    -- This is a SECURITY RISK in production environments
    -- Production implementation should:
    --   1. Query sy101_user and sy104_user_pwd tables
    --   2. Use password hashing (security.BCrypt.verify())
    --   3. Log attempts to sy130_logs table
    --   4. Implement account lockout after failed attempts

    CASE p_user.toLowerCase()
        WHEN "admin"
            IF p_pass = "1234" THEN  -- WEAK PASSWORD - CHANGE IN PRODUCTION
                LET g_user_role = "Administrator"
                RETURN TRUE
            END IF
        WHEN "user"
            IF p_pass = "user123" THEN  -- WEAK PASSWORD - CHANGE IN PRODUCTION
                LET g_user_role = "User"
                RETURN TRUE
            END IF
        WHEN "demo"
            IF p_pass = "demo" THEN  -- WEAK PASSWORD - CHANGE IN PRODUCTION
                LET g_user_role = "Demo User"
                RETURN TRUE
            END IF
    END CASE
    RETURN FALSE
END FUNCTION

-- --------------------------------------------------------------
-- SESSION GETTERS
-- --------------------------------------------------------------
FUNCTION get_current_user() RETURNS STRING
    RETURN g_current_user
END FUNCTION

FUNCTION get_user_role() RETURNS STRING
    RETURN g_user_role
END FUNCTION

-- --------------------------------------------------------------
-- CONFIRM EXIT PROMPT
-- --------------------------------------------------------------
FUNCTION confirm_exit_login() RETURNS SMALLINT
    DEFINE ans STRING
    LET ans =
        utils_globals.show_confirm("Exit Login", "Do you want to cancel login?")
    RETURN ans = "yes"
END FUNCTION

