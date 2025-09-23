# ==============================================================
# Program   :   sy100_login.4gl
# Purpose   :   App entry point with login
# Module    :   Login
# Number    :   100
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.2.1
# ==============================================================

IMPORT ui
IMPORT FGL sy900_utils

-- Global variables for user session
DEFINE g_current_user STRING
DEFINE g_user_role STRING
DEFINE g_login_attempts SMALLINT

FUNCTION run_login() RETURNS SMALLINT
    DEFINE login_result SMALLINT
    DEFINE f_username STRING 
    DEFINE f_password STRING
    DEFINE max_attempts SMALLINT
    
    LET max_attempts = 3
    LET g_login_attempts = 0
    LET login_result = FALSE
    
    OPEN WINDOW w_login WITH FORM "sy100_frm_login"
        ATTRIBUTE (STYLE="dialog", TEXT="XactERP Login", NORMAL)
    
    CALL set_page_title("Login")  -- global title
    
    DIALOG
        INPUT BY NAME f_username, f_password
            BEFORE INPUT
                -- Clear fields and set focus
                CLEAR FORM
                NEXT FIELD f_username
                
            ON ACTION login
                LET g_login_attempts = g_login_attempts + 1
                
                IF validate_login(f_username, f_password) THEN
                    LET g_current_user = f_username
                    CALL show_alert("Welcome " || f_username || "!")
                    LET login_result = TRUE
                    EXIT DIALOG
                ELSE
                    IF g_login_attempts >= max_attempts THEN
                        CALL show_alert("Maximum login attempts exceeded. Exiting system.")
                        LET login_result = FALSE
                        EXIT DIALOG
                    ELSE
                        CALL show_alert("Invalid credentials. Attempt " || g_login_attempts || " of " || max_attempts)
                        CLEAR FORM
                        NEXT FIELD f_username
                    END IF
                END IF
                
            ON ACTION cancel
                IF confirm_exit_login() THEN
                    LET login_result = FALSE
                    EXIT DIALOG
                END IF
                
            ON KEY (F1)
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

-- ------------------ AUTH VALIDATION -------------------
FUNCTION validate_login(f_username STRING, f_password STRING) RETURNS SMALLINT
    DEFINE is_valid SMALLINT
    
    LET is_valid = FALSE
    
    -- Remove leading/trailing spaces
    LET f_username = f_username.trim()
    LET f_password = f_password.trim()
    
    -- Check for empty fields
    IF f_username.getLength() = 0 THEN
        CALL show_alert("Username is required")
        RETURN FALSE
    END IF
    
    IF f_password.getLength() = 0 THEN
        CALL show_alert("Password is required")
        RETURN FALSE
    END IF
    
    -- TODO: Replace with database lookup
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
    
    MENU "Confirm Exit" ATTRIBUTE(STYLE="dialog", COMMENT="Are you sure you want to cancel login?")
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
    CALL show_alert("Login Help:\n\nDemo Credentials:\n" ||
                   "Username: admin, Password: 1234\n" ||
                   "Username: user, Password: user123\n" ||
                   "Username: demo, Password: demo\n\n" ||
                   "Press F1 for help, ESC to cancel")
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