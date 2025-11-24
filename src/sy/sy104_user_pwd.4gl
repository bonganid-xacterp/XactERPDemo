-- ==============================================================
-- Program   : sy104_user_pwd.4gl
-- Purpose   : Change Password
-- Author    : Bongani Dlamini
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT security

SCHEMA demoapp_db   -- ? ensure this matches your actual schema

TYPE pass_change_t RECORD
    password STRING,             -- current password
    new_password STRING,         -- new password
    confirm_new_password STRING  -- confirm new password
END RECORD

DEFINE rec_pass_change pass_change_t
DEFINE m_username STRING

-- ==============================================================
-- Change Password
-- ==============================================================
FUNCTION change_password(p_username STRING) RETURNS SMALLINT
    DEFINE stored_pwd STRING
    DEFINE keep_running SMALLINT

    LET m_username = p_username
    INITIALIZE rec_pass_change.* TO NULL
    LET keep_running = TRUE

    OPEN WINDOW w_pwd WITH FORM "sy104_user_pwd"

    DISPLAY BY NAME rec_pass_change.*

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_pass_change.*
            -- Live hinting on match/mismatch
            AFTER FIELD new_password, confirm_new_password
                IF rec_pass_change.new_password IS NOT NULL
                   AND rec_pass_change.confirm_new_password IS NOT NULL THEN
                    IF rec_pass_change.new_password != rec_pass_change.confirm_new_password THEN
                        DISPLAY "Passwords don't match" TO __status__
                    ELSE
                        DISPLAY "" TO __status__
                    END IF
                END IF
        END INPUT

        -- Click of the form button or menu action "Change"
        ON ACTION bin_change_pwd
            -- Validate current password present
            IF rec_pass_change.password IS NULL OR rec_pass_change.password = "" THEN
                CALL utils_globals.show_error("Enter current password.")
                NEXT FIELD password
                CONTINUE DIALOG
            END IF

            -- Validate new password length
            IF rec_pass_change.new_password IS NULL
               OR LENGTH(rec_pass_change.new_password) < 4 THEN
                CALL utils_globals.show_error("New password must be 4+ characters.")
                NEXT FIELD new_password
                CONTINUE DIALOG
            END IF

            -- Validate confirmation
            IF rec_pass_change.new_password != rec_pass_change.confirm_new_password THEN
                CALL utils_globals.show_error("Passwords don't match.")
                NEXT FIELD confirm_new_password
                CONTINUE DIALOG
            END IF

            -- Prevent same password reuse (optional)
            LET stored_pwd = get_user_password_hash(m_username)
            IF stored_pwd IS NULL THEN
                CALL utils_globals.show_error("User not found.")
                CONTINUE DIALOG
            END IF

            IF encrypt_password(rec_pass_change.password) != stored_pwd THEN
                CALL utils_globals.show_error("Current password is wrong.")
                NEXT FIELD password
                CONTINUE DIALOG
            END IF

            IF encrypt_password(rec_pass_change.new_password) = stored_pwd THEN
                CALL utils_globals.show_error("New password must be different from current password.")
                NEXT FIELD new_password
                CONTINUE DIALOG
            END IF

            TRY
                UPDATE sy00_user
                   SET password   = encrypt_password(rec_pass_change.new_password),
                       updated_at = CURRENT,
                       updated_by = m_username
                 WHERE username   = m_username

                IF SQLCA.SQLCODE = 0 AND SQLCA.SQLERRD[3] = 1 THEN
                    CALL utils_globals.show_info("Password changed successfully.")
                    LET keep_running = FALSE
                    EXIT DIALOG
                ELSE
                    CALL utils_globals.show_error("Update failed.")
                    CONTINUE DIALOG
                END IF

            CATCH
                CALL utils_globals.show_sql_error("change_password: Error updating password")
                CONTINUE DIALOG
            END TRY

        -- Cancel/Close
        ON ACTION bin_cancel
        ON ACTION CLOSE
        ON ACTION cancel
            LET keep_running = FALSE
            EXIT DIALOG
    END DIALOG

    CLOSE WINDOW w_pwd
    RETURN keep_running = FALSE
END FUNCTION

-- ==============================================================
-- Helper: fetch stored password hash safely
-- ==============================================================
FUNCTION get_user_password_hash(p_user STRING) RETURNS STRING
    DEFINE v_hash STRING

    TRY
        SELECT password INTO v_hash
          FROM sy00_user
         WHERE username = p_user

        IF SQLCA.SQLCODE != 0 THEN
            RETURN NULL
        END IF
        RETURN v_hash

    CATCH
        CALL utils_globals.show_sql_error("get_user_password_hash: Error fetching password hash")
        RETURN NULL
    END TRY
END FUNCTION

-- ==============================================================
-- Hash function (prefer SHA-256 over MD5)
-- ==============================================================
PRIVATE FUNCTION encrypt_password(pwd STRING) RETURNS STRING
    DEFINE digest security.Digest
    -- If SHA256 is unavailable in your runtime, fallback to "MD5" (not recommended)
    LET digest = security.Digest.CreateDigest("SHA256")
    CALL digest.AddStringData(NVL(pwd,""))
    RETURN digest.DoHexBinaryDigest()
END FUNCTION
