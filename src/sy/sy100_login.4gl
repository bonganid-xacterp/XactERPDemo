# ==============================================================
# Program   : sy100_login.4gl
# Purpose   : Handles user login and authentication
# Module    : System (sy)
# Author    : Bongani Dlamini
# Version   : Genero ver 3.20.10
# ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL utils_logger

-- --------------------------------------------------------------
-- GLOBAL VARIABLES
-- --------------------------------------------------------------
DEFINE g_current_user STRING
DEFINE g_user_role STRING
DEFINE g_login_tries SMALLINT
DEFINE g_last_error STRING

CONSTANT MAX_LOGIN_ATTEMPTS = 3

-- --------------------------------------------------------------
-- Main login function with comprehensive error handling
-- --------------------------------------------------------------
FUNCTION login_user() RETURNS SMALLINT
    DEFINE f_username, f_password STRING
    DEFINE f ui.Form
    DEFINE w ui.Window
    DEFINE ok SMALLINT

    -- Initialize
    LET ok = FALSE
    LET g_login_tries = 0
    LET g_last_error = NULL

    TRY
        -- ------------------------------------------------------------
        -- Open login window (dialog style)
        -- ------------------------------------------------------------
        OPTIONS INPUT WRAP
        OPEN WINDOW w_login WITH FORM "sy100_login" 
            ATTRIBUTES(STYLE = "modal")

        -- Attach current form reference
        LET w = ui.Window.getCurrent()
        
        IF w IS NULL THEN
            CALL log_error("login_user", "Failed to get window reference")
            CALL utils_globals.show_error(
                "System Error: Unable to initialize login window")
            RETURN FALSE
        END IF

        TRY
            LET f = w.getForm()

            -- Optional: Set company logo dynamically
            TRY
                CALL f.setElementImage("company_logo", "company_logo.png")
            CATCH
                -- Log but don't fail - logo is optional
                CALL log_warning("login_user", 
                    "Could not load company logo: " || STATUS || " - " || SQLCA.SQLERRM)
            END TRY

            -- ------------------------------------------------------------
            -- Start dialog for login input
            -- ------------------------------------------------------------
            CALL run_login_dialog() RETURNING ok, f_username, f_password

        CATCH
            CALL log_error("login_user", 
                "Form initialization error: " || STATUS || " - " || SQLCA.SQLERRM)
            CALL utils_globals.show_error(
                "Unable to initialize login form. Please contact support.")
            LET ok = FALSE
        END TRY

        -- ------------------------------------------------------------
        -- Close login window
        -- ------------------------------------------------------------
        TRY
            CLOSE WINDOW w_login
        CATCH
            CALL log_error("login_user", 
                "Error closing window: " || STATUS || " - " || SQLCA.SQLERRM)
            -- Continue anyway - window closure error shouldn't block login
        END TRY

    CATCH
        CALL log_error("login_user", 
            "Critical error: " || STATUS || " - " || SQLCA.SQLERRM)
        CALL utils_globals.show_error(
            "A critical error occurred. Please restart the application.")
        LET ok = FALSE
    END TRY

    RETURN ok
END FUNCTION

-- --------------------------------------------------------------
-- Separate dialog logic for better error handling
-- --------------------------------------------------------------
FUNCTION run_login_dialog() 
    RETURNS (SMALLINT, STRING, STRING)
    
    DEFINE f_username, f_password STRING
    DEFINE ok SMALLINT

    LET ok = FALSE

    TRY
        DIALOG ATTRIBUTES(UNBUFFERED)

            INPUT BY NAME f_username, f_password

                BEFORE INPUT
                    TRY
                        --CLEAR FORM
                        NEXT FIELD f_username
                    CATCH
                        CALL log_error("run_login_dialog", 
                            "Error in BEFORE INPUT: " || STATUS)
                    END TRY

                AFTER FIELD f_username
                    TRY
                        IF f_username IS NULL OR f_username.trim().getLength() = 0 THEN
                            ERROR "Username is required"
                            NEXT FIELD f_username
                        END IF
                    CATCH
                        CALL log_error("run_login_dialog", 
                            "Error validating username: " || STATUS)
                    END TRY

                AFTER FIELD f_password
                    TRY
                        IF f_password IS NOT NULL AND f_password.getLength() > 0 THEN
                            CALL attempt_login(f_username, f_password) RETURNING ok
                            
                            IF ok THEN
                                EXIT DIALOG
                            ELSE
                                IF g_login_tries >= MAX_LOGIN_ATTEMPTS THEN
                                    EXIT DIALOG
                                END IF
                                LET f_password = NULL
                                NEXT FIELD f_username
                            END IF
                        END IF
                    CATCH
                        CALL log_error("run_login_dialog", 
                            "Error in AFTER FIELD f_password: " || STATUS)
                        ERROR "An error occurred during login. Please try again."
                        LET f_password = NULL
                        NEXT FIELD f_username
                    END TRY

                ON ACTION login ATTRIBUTES (TEXT="Login", ACCELERATOR="Return")
                    TRY
                        -- Validate inputs first
                        IF f_username IS NULL OR f_username.trim().getLength() = 0 THEN
                            ERROR "Please enter a username"
                            NEXT FIELD f_username
                            CONTINUE DIALOG
                        END IF

                        IF f_password IS NULL OR f_password.getLength() = 0 THEN
                            ERROR "Please enter a password"
                            NEXT FIELD f_password
                            CONTINUE DIALOG
                        END IF

                        CALL attempt_login(f_username, f_password) RETURNING ok
                        
                        IF ok THEN
                            EXIT DIALOG
                        ELSE
                            IF g_login_tries >= MAX_LOGIN_ATTEMPTS THEN
                                EXIT DIALOG
                            ELSE
                                LET f_password = NULL
                                NEXT FIELD f_username
                            END IF
                        END IF
                    CATCH
                        CALL log_error("run_login_dialog", 
                            "Error in ON ACTION login: " || STATUS || " - " || SQLCA.SQLERRM)
                        CALL utils_globals.show_error(
                            "Login failed due to system error. Please try again.")
                        LET f_password = NULL
                        NEXT FIELD f_username
                    END TRY

                ON ACTION cancel ATTRIBUTES (TEXT="Exit", ACCELERATOR="Escape")
                    TRY
                        IF confirm_exit_login() THEN
                            EXIT DIALOG
                        END IF
                    CATCH
                        CALL log_error("run_login_dialog", 
                            "Error in ON ACTION cancel: " || STATUS)
                        LET ok = FALSE
                        EXIT DIALOG
                    END TRY

            END INPUT

        END DIALOG

    CATCH
        CALL log_error("run_login_dialog", 
            "Dialog error: " || STATUS || " - " || SQLCA.SQLERRM)
        CALL utils_globals.show_error(
            "An error occurred in the login dialog.")
        LET ok = FALSE
    END TRY

    RETURN ok, f_username, f_password
END FUNCTION

-- --------------------------------------------------------------
-- Consolidated login attempt with error handling
-- --------------------------------------------------------------
FUNCTION attempt_login(p_username STRING, p_password STRING) 
    RETURNS SMALLINT
    
    DEFINE l_trimmed_user, l_trimmed_pass STRING
    DEFINE l_success SMALLINT

    TRY
        -- Validate and trim inputs
        IF p_username IS NULL OR p_password IS NULL THEN
            ERROR "Username and password are required"
            RETURN FALSE
        END IF

        LET l_trimmed_user = p_username.trim()
        LET l_trimmed_pass = p_password.trim()

        IF l_trimmed_user.getLength() = 0 THEN
            ERROR "Username cannot be empty"
            RETURN FALSE
        END IF

        IF l_trimmed_pass.getLength() = 0 THEN
            ERROR "Password cannot be empty"
            RETURN FALSE
        END IF

        -- Attempt validation
        TRY
            LET l_success = validate_login(l_trimmed_user, l_trimmed_pass)
        CATCH
            CALL log_error("attempt_login", 
                "Validation error: " || STATUS || " - " || SQLCA.SQLERRM)
            CALL utils_globals.show_error(
                "Unable to validate credentials. Please try again.")
            RETURN FALSE
        END TRY

        IF l_success THEN
            LET g_current_user = l_trimmed_user
            MESSAGE "Welcome " || l_trimmed_user || "!"
            CALL log_info("attempt_login", "User logged in: " || l_trimmed_user)
            RETURN TRUE
        ELSE
            LET g_login_tries = g_login_tries + 1
            
            IF g_login_tries < MAX_LOGIN_ATTEMPTS THEN
                ERROR SFMT("Invalid credentials (%1/%2)",
                           g_login_tries, MAX_LOGIN_ATTEMPTS)
                CALL log_warning("attempt_login", 
                    SFMT("Failed login attempt %1/%2 for user: %3",
                         g_login_tries, MAX_LOGIN_ATTEMPTS, l_trimmed_user))
            ELSE
                CALL utils_globals.show_error(
                    "Maximum login attempts reached. Access denied.")
                CALL log_error("attempt_login", 
                    "Max login attempts reached for user: " || l_trimmed_user)
            END IF
            RETURN FALSE
        END IF

    CATCH
        CALL log_error("attempt_login", 
            "Unexpected error: " || STATUS || " - " || SQLCA.SQLERRM)
        CALL utils_globals.show_error(
            "An unexpected error occurred. Please contact support.")
        RETURN FALSE
    END TRY
END FUNCTION

-- --------------------------------------------------------------
-- VALIDATION WITH DATABASE QUERY (replaces hardcoded version)
-- --------------------------------------------------------------
FUNCTION validate_login(p_user STRING, p_pass STRING) RETURNS SMALLINT
    DEFINE l_db_password STRING
    DEFINE l_db_role STRING
    DEFINE l_is_active SMALLINT
    DEFINE l_hashed_input STRING

    TRY
        -- TODO: Replace with actual password hashing
        -- LET l_hashed_input = hash_password(p_pass)
        LET l_hashed_input = p_pass  -- TEMPORARY - USE HASHING IN PRODUCTION

        -- Query user from database
        TRY
            SELECT user_password, user_role, is_active
              INTO l_db_password, l_db_role, l_is_active
              FROM sys_users
             WHERE LOWER(username) = LOWER(p_user)

            -- Check if query returned results
            IF SQLCA.SQLCODE = NOTFOUND THEN
                CALL log_warning("validate_login", 
                    "User not found: " || p_user)
                RETURN FALSE
            END IF

            IF SQLCA.SQLCODE < 0 THEN
                CALL log_error("validate_login", 
                    "Database error: " || SQLCA.SQLCODE || " - " || SQLCA.SQLERRM)
            END IF

        CATCH
            -- If table doesn't exist, fall back to demo credentials
            CALL log_warning("validate_login", 
                "Database query failed, using demo mode: " || STATUS)
            RETURN validate_login_demo(p_user, p_pass)
        END TRY

        -- Check if account is active
        IF l_is_active = 0 THEN
            CALL log_warning("validate_login", 
                "Inactive account login attempt: " || p_user)
            ERROR "Account is disabled. Contact administrator."
            RETURN FALSE
        END IF

        -- Validate password
        IF l_db_password = l_hashed_input THEN
            LET g_user_role = l_db_role
            RETURN TRUE
        ELSE
            RETURN FALSE
        END IF

    CATCH
        CALL log_error("validate_login", 
            "Critical validation error: " || STATUS || " - " || SQLCA.SQLERRM)
        RETURN FALSE
    END TRY
END FUNCTION

-- --------------------------------------------------------------
-- DEMO VALIDATION (fallback for development/testing)
-- --------------------------------------------------------------
FUNCTION validate_login_demo(p_user STRING, p_pass STRING) RETURNS SMALLINT
    
    TRY
        CASE p_user.toLowerCase()
            WHEN "admin"
                IF p_pass = "1234" THEN
                    LET g_user_role = "Administrator"
                    RETURN TRUE
                END IF
            WHEN "user"
                IF p_pass = "user123" THEN
                    LET g_user_role = "User"
                    RETURN TRUE
                END IF
            WHEN "demo"
                IF p_pass = "demo" THEN
                    LET g_user_role = "Demo User"
                    RETURN TRUE
                END IF
        END CASE
        RETURN FALSE
    CATCH
        CALL log_error("validate_login_demo", 
            "Error in demo validation: " || STATUS)
        RETURN FALSE
    END TRY
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

FUNCTION get_last_error() RETURNS STRING
    RETURN g_last_error
END FUNCTION

-- --------------------------------------------------------------
-- CONFIRM EXIT PROMPT
-- --------------------------------------------------------------
FUNCTION confirm_exit_login() RETURNS SMALLINT
    DEFINE ans SMALLINT

    TRY
        LET ans = utils_globals.show_confirm(
            "Are you sure you want to exit login?",
            "Exit Login")
        RETURN ans
    CATCH
        CALL log_error("confirm_exit_login",
            "Error showing confirmation: " || STATUS)
        -- Default to exiting on error (safer to allow exit)
        RETURN TRUE
    END TRY
END FUNCTION

-- --------------------------------------------------------------
-- TODO: Implement password hashing function
-- --------------------------------------------------------------
-- FUNCTION hash_password(p_password STRING) RETURNS STRING
--     -- Use SHA-256 or bcrypt
--     -- RETURN crypto.digest(p_password, "SHA256")
-- END FUNCTION