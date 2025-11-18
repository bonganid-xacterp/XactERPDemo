-- ==============================================================
-- Program   : sy101_user.4gl
-- Purpose   : User Master maintenance (CRUD operations)
-- Module    : System (sy)
-- Number    : 101
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Master file maintenance for system users
--              Provides full CRUD operations with password encryption
--              Password is only updated when a new value is provided
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL sy104_user_pwd
IMPORT security

SCHEMA demoappdb

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE user_t RECORD LIKE sy00_user.*
DEFINE rec_user user_t
DEFINE rec_password_input STRING  -- Separate field for password input

DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

-- ==============================================================
-- MAIN (Standalone or Child Mode)
-- ==============================================================
MAIN
    IF NOT utils_globals.initialize_application() THEN
        CALL utils_globals.show_error("Initialization failed.")
        EXIT PROGRAM 1
    END IF

    IF utils_globals.is_standalone() THEN
        OPEN WINDOW w_sy101 WITH FORM "sy101_user" -- -- ATTRIBUTES(STYLE = "normal")
    ELSE
        OPEN WINDOW w_sy101 WITH FORM "sy101_user" ATTRIBUTES(STYLE = "child")
    END IF

    CALL init_user_module()

    IF utils_globals.is_standalone() THEN
        CLOSE WINDOW w_sy101
    END IF
END MAIN

-- ==============================================================
-- Main Controller Menu
-- ==============================================================
FUNCTION init_user_module()
    LET is_edit_mode = FALSE
    CALL utils_globals.set_form_label("lbl_form_title", "USER MASTER MAINTENANCE")

    -- Populate role dropdown
    CALL populate_role_combo()

    -- Initialize the list of records
    CALL load_all_users()

    MENU "User Menu"

        COMMAND "Find"
            CALL query_users()
            LET is_edit_mode = FALSE

        COMMAND "New"
            CALL new_user()
            LET is_edit_mode = FALSE

        COMMAND "Edit"
            IF rec_user.username IS NULL OR rec_user.username = "" THEN
                CALL utils_globals.show_info("No user selected to edit.")
            ELSE
                LET is_edit_mode = TRUE
                CALL edit_user()
            END IF

        COMMAND "Delete"
            CALL delete_user()
            LET is_edit_mode = FALSE

        COMMAND "Previous"
            CALL move_record(-1)

        COMMAND "Next"
            CALL move_record(1)

        COMMAND "Change Password"
            IF rec_user.username IS NULL OR rec_user.username = "" THEN
                CALL utils_globals.show_info("No user selected.")
            ELSE
                CALL change_password_for_user()
            END IF

        COMMAND "Exit"
            EXIT MENU
    END MENU
END FUNCTION

-- ==============================================================
-- Load all users into array
-- ==============================================================
PRIVATE FUNCTION load_all_users()
    DEFINE ok SMALLINT
    LET ok = select_users("1=1")

    IF ok THEN
        MESSAGE SFMT("Loaded %1 user(s)", arr_codes.getLength())
    ELSE
        CALL utils_globals.show_info("No users found.")
        INITIALIZE rec_user.* TO NULL
        LET rec_password_input = NULL
        DISPLAY BY NAME rec_user.*
    END IF
END FUNCTION

-- ==============================================================
-- Query users (simple search for now - can be replaced with lookup)
-- ==============================================================
FUNCTION query_users()
    DEFINE search_username STRING
    DEFINE ok SMALLINT

    LET search_username = ""

    PROMPT "Enter Username to search:" FOR search_username

    IF search_username IS NULL OR search_username = "" THEN
        CALL load_all_users()
        RETURN
    END IF

    LET ok = select_users(SFMT("username LIKE '%%%1%%'", search_username))

    IF NOT ok THEN
        CALL utils_globals.show_info("No users found matching criteria.")
    END IF
END FUNCTION

-- ==============================================================
-- Select users into array
-- ==============================================================
FUNCTION select_users(where_clause STRING) RETURNS SMALLINT
    DEFINE username STRING
    DEFINE idx INTEGER
    DEFINE sql_stmt STRING

    CALL arr_codes.clear()
    LET idx = 0
    LET sql_stmt = "SELECT username FROM sy00_user"

    IF where_clause IS NOT NULL AND where_clause != "" THEN
        LET sql_stmt = sql_stmt || " WHERE " || where_clause
    END IF

    LET sql_stmt = sql_stmt || " ORDER BY username"

    PREPARE stmt_select FROM sql_stmt
    DECLARE c_curs CURSOR FOR stmt_select

    FOREACH c_curs INTO username
        LET idx = idx + 1
        LET arr_codes[idx] = username
    END FOREACH

    CLOSE c_curs
    FREE c_curs
    FREE stmt_select

    IF arr_codes.getLength() == 0 THEN
        CALL utils_globals.msg_no_record()
        RETURN FALSE
    END IF

    LET curr_idx = 1
    CALL load_user(arr_codes[curr_idx])
    RETURN TRUE
END FUNCTION

-- ==============================================================
-- Load Single User
-- ==============================================================
FUNCTION load_user(p_username STRING)
    SELECT * INTO rec_user.* FROM sy00_user WHERE username = p_username

    IF SQLCA.SQLCODE = 0 THEN
        -- Don't display the password hash
        LET rec_password_input = NULL
        DISPLAY BY NAME rec_user.id,
                        rec_user.username,
                        rec_user.full_name,
                        rec_user.phone,
                        rec_user.email,
                        rec_user.status,
                        rec_user.role_id
        DISPLAY "" TO sy00_user.password
    ELSE
        INITIALIZE rec_user.* TO NULL
        LET rec_password_input = NULL
        DISPLAY BY NAME rec_user.*
    END IF
END FUNCTION

-- ==============================================================
-- Navigation
-- ==============================================================
PRIVATE FUNCTION move_record(dir SMALLINT)
    DEFINE new_idx INTEGER

    IF arr_codes.getLength() == 0 THEN
        CALL utils_globals.show_info("No records to navigate.")
        RETURN
    END IF

    LET new_idx = utils_globals.navigate_records(arr_codes, curr_idx, dir)
    LET curr_idx = new_idx
    CALL load_user(arr_codes[curr_idx])
END FUNCTION

-- ==============================================================
-- New User
-- ==============================================================
FUNCTION new_user()
    DEFINE dup_found, new_id SMALLINT
    DEFINE i, array_size INTEGER

    INITIALIZE rec_user.* TO NULL
    LET rec_password_input = NULL

    LET rec_user.status = "active"
    
    LET rec_user.created_at = CURRENT

    CALL utils_globals.set_form_label("lbl_form_title", "NEW USER")

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_user.id,
                      rec_user.username,
                      rec_user.full_name,
                      rec_user.phone,
                      rec_user.email,
                      rec_user.status,
                      rec_user.role_id
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_user")

            AFTER FIELD username
                IF rec_user.username IS NULL OR rec_user.username = "" THEN
                    CALL utils_globals.show_error("Username is required.")
                    NEXT FIELD username
                END IF
                -- Check if username already exists
                LET dup_found = check_username_unique(rec_user.username)
                IF dup_found != 0 THEN
                    CALL utils_globals.show_error("Username already exists.")
                    NEXT FIELD username
                END IF

            AFTER FIELD full_name
                IF rec_user.full_name IS NULL OR rec_user.full_name = "" THEN
                    CALL utils_globals.show_error("Full Name is required.")
                    NEXT FIELD full_name
                END IF

            AFTER FIELD email
                IF rec_user.email IS NOT NULL AND rec_user.email != "" THEN
                    IF NOT utils_globals.is_valid_email(rec_user.email) THEN
                        CALL utils_globals.show_error("Invalid email format.")
                        NEXT FIELD email
                    END IF
                END IF

        END INPUT

        INPUT rec_password_input FROM sy00_user.password
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_user_pwd")

            AFTER FIELD password
                IF rec_password_input IS NULL OR rec_password_input = "" THEN
                    CALL utils_globals.show_error("Password is required for new users.")
                    NEXT FIELD password
                END IF
                IF rec_password_input.getLength() < 6 THEN
                    CALL utils_globals.show_error("Password must be at least 6 characters.")
                    NEXT FIELD password
                END IF

        END INPUT

        ON ACTION save ATTRIBUTES(TEXT = "Save", IMAGE = "filesave")
            -- Validate before saving
            IF rec_user.username IS NULL OR rec_user.username = "" THEN
                CALL utils_globals.show_error("Username is required.")
                NEXT FIELD username
            END IF
            IF rec_user.full_name IS NULL OR rec_user.full_name = "" THEN
                CALL utils_globals.show_error("Full Name is required.")
                NEXT FIELD full_name
            END IF
            IF rec_password_input IS NULL OR rec_password_input = "" THEN
                CALL utils_globals.show_error("Password is required for new users.")
                NEXT FIELD password
            END IF
            IF rec_password_input.getLength() < 6 THEN
                CALL utils_globals.show_error("Password must be at least 6 characters.")
                NEXT FIELD password
            END IF
            CALL save_user()
            LET new_id = rec_user.id
            IF new_id IS NOT NULL THEN
                CALL utils_globals.show_info("User saved successfully.")
                EXIT DIALOG
            END IF

        ON ACTION cancel ATTRIBUTES(TEXT = "Cancel", IMAGE = "cancel")
            CALL utils_globals.show_info("Creation cancelled.")
            LET new_id = NULL
            EXIT DIALOG

    END DIALOG

    -- Reload the list and position to the new record
    IF new_id IS NOT NULL THEN
        CALL load_all_users()
        LET array_size = arr_codes.getLength()
        IF array_size > 0 THEN
            FOR i = 1 TO array_size
                IF arr_codes[i] = rec_user.username THEN
                    LET curr_idx = i
                    EXIT FOR
                END IF
            END FOR
        END IF
        CALL load_user(rec_user.username)
    ELSE
        LET array_size = arr_codes.getLength()
        IF array_size > 0 AND curr_idx >= 1 AND curr_idx <= array_size THEN
            CALL load_user(arr_codes[curr_idx])
        ELSE
            LET curr_idx = 0
            INITIALIZE rec_user.* TO NULL
            LET rec_password_input = NULL
            DISPLAY BY NAME rec_user.*
        END IF
    END IF

    CALL utils_globals.set_form_label("lbl_form_title", "USER MASTER MAINTENANCE")
END FUNCTION

-- ==============================================================
-- Edit User
-- ==============================================================
FUNCTION edit_user()
    CALL utils_globals.set_form_label("lbl_form_title", "EDIT USER")
    LET rec_password_input = NULL  -- Clear password input

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_user.id,
                      rec_user.username,
                      rec_user.full_name,
                      rec_user.phone,
                      rec_user.email,
                      rec_user.status,
                      rec_user.role_id
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "edit_user")

            BEFORE FIELD username
                -- Username should not be editable
                NEXT FIELD full_name

            AFTER FIELD full_name
                IF rec_user.full_name IS NULL OR rec_user.full_name = "" THEN
                    CALL utils_globals.show_error("Full Name is required.")
                    NEXT FIELD full_name
                END IF

            AFTER FIELD email
                IF rec_user.email IS NOT NULL AND rec_user.email != "" THEN
                    IF NOT utils_globals.is_valid_email(rec_user.email) THEN
                        CALL utils_globals.show_error("Invalid email format.")
                        NEXT FIELD email
                    END IF
                END IF

        END INPUT

        INPUT rec_password_input FROM sy00_user.password
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "edit_user_pwd")

            BEFORE INPUT
                MESSAGE "Leave password blank to keep current password"

            AFTER FIELD password
                -- Only validate if password is provided
                IF rec_password_input IS NOT NULL AND rec_password_input != "" THEN
                    IF rec_password_input.getLength() < 6 THEN
                        CALL utils_globals.show_error(
                            "Password must be at least 6 characters.")
                        NEXT FIELD password
                    END IF
                END IF

        END INPUT

        ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
            -- Validate before saving
            IF rec_user.full_name IS NULL OR rec_user.full_name = "" THEN
                CALL utils_globals.show_error("Full Name is required.")
                NEXT FIELD full_name
            END IF
            IF rec_password_input IS NOT NULL AND rec_password_input != "" THEN
                IF rec_password_input.getLength() < 6 THEN
                    CALL utils_globals.show_error("Password must be at least 6 characters.")
                    NEXT FIELD password
                END IF
            END IF
            CALL save_user()
            EXIT DIALOG

        ON ACTION cancel ATTRIBUTES(TEXT = "Cancel", IMAGE = "cancel")
            CALL load_user(rec_user.username)
            EXIT DIALOG

        ON ACTION btn_change_password ATTRIBUTES(TEXT = "Change Password", IMAGE = "fa-shield")
            IF rec_user.username IS NOT NULL AND rec_user.username != "" THEN
                CALL change_password_for_user()
            ELSE
                CALL utils_globals.show_info("No user selected.")
            END IF

    END DIALOG

    CALL utils_globals.set_form_label("lbl_form_title", "USER MASTER MAINTENANCE")
END FUNCTION

-- ==============================================================
-- Save / Update User
-- ==============================================================
FUNCTION save_user()
    DEFINE exists INTEGER
    DEFINE encrypted_pwd STRING

    BEGIN WORK
    TRY
        SELECT COUNT(*)
            INTO exists
            FROM sy00_user
            WHERE username = rec_user.username

        IF exists = 0 THEN
            -- New user - password is required
            IF rec_password_input IS NULL OR rec_password_input = "" THEN
                ROLLBACK WORK
                CALL utils_globals.show_error("Password is required for new users.")
                RETURN
            END IF

            -- Encrypt the password
            LET encrypted_pwd = encrypt_password(rec_password_input)
            LET rec_user.password = encrypted_pwd
            LET rec_user.created_at = CURRENT

            INSERT INTO sy00_user VALUES rec_user.*
            COMMIT WORK
            CALL utils_globals.msg_saved()
        ELSE
            -- Update existing user
            LET rec_user.updated_at = CURRENT

            -- Only update password if a new one was provided
            IF rec_password_input IS NOT NULL AND rec_password_input != "" THEN
                LET encrypted_pwd = encrypt_password(rec_password_input)
                UPDATE sy00_user
                    SET full_name = rec_user.full_name,
                        phone = rec_user.phone,
                        email = rec_user.email,
                        password = encrypted_pwd,
                        status = rec_user.status,
                        role_id = rec_user.role_id,
                        updated_at = rec_user.updated_at
                    WHERE username = rec_user.username
            ELSE
                -- Don't update password
                UPDATE sy00_user
                    SET full_name = rec_user.full_name,
                        phone = rec_user.phone,
                        email = rec_user.email,
                        status = rec_user.status,
                        role_id = rec_user.role_id,
                        updated_at = rec_user.updated_at
                    WHERE username = rec_user.username
            END IF
            COMMIT WORK
            CALL utils_globals.msg_updated()
        END IF

        -- Clear password input after save
        LET rec_password_input = NULL
        CALL load_user(rec_user.username)

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(SFMT("Save failed: %1", SQLCA.SQLCODE))
    END TRY
END FUNCTION

-- ==============================================================
-- Delete User
-- ==============================================================
FUNCTION delete_user()
    DEFINE ok SMALLINT
    DEFINE deleted_username STRING
    DEFINE array_size INTEGER

    IF rec_user.username IS NULL OR rec_user.username = "" THEN
        CALL utils_globals.show_info("No user selected for deletion.")
        RETURN
    END IF

    -- Prevent deleting admin user
    IF rec_user.username = "admin" THEN
        CALL utils_globals.show_error("Cannot delete admin user.")
        RETURN
    END IF

    LET ok =
        utils_globals.show_confirm(
            "Delete this user: " || rec_user.full_name || " (" || rec_user.username || ")?",
            "Confirm Delete")

    IF NOT ok THEN
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    LET deleted_username = rec_user.username

    BEGIN WORK
    TRY
        DELETE FROM sy00_user WHERE username = deleted_username
        COMMIT WORK
        CALL utils_globals.msg_deleted()
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(SFMT("Delete failed: %1", SQLCA.SQLCODE))
        RETURN
    END TRY

    -- Reload list and navigate to valid record
    CALL load_all_users()
    LET array_size = arr_codes.getLength()

    IF array_size > 0 THEN
        IF curr_idx > array_size THEN
            LET curr_idx = array_size
        END IF
        IF curr_idx < 1 THEN
            LET curr_idx = 1
        END IF
        CALL load_user(arr_codes[curr_idx])
    ELSE
        LET curr_idx = 0
        INITIALIZE rec_user.* TO NULL
        LET rec_password_input = NULL
        DISPLAY BY NAME rec_user.*
    END IF
END FUNCTION

-- ==============================================================
-- Check Username Uniqueness
-- ==============================================================
FUNCTION check_username_unique(p_username STRING) RETURNS SMALLINT
    DEFINE dup_count INTEGER

    SELECT COUNT(*) INTO dup_count FROM sy00_user WHERE username = p_username
    IF dup_count > 0 THEN
        RETURN 1
    END IF

    RETURN 0
END FUNCTION

-- ==============================================================
-- Encrypt Password (Simple MD5 or Base64 encoding)
-- ==============================================================
FUNCTION encrypt_password(p_password STRING) RETURNS STRING
    DEFINE encrypted STRING
    DEFINE digest security.Digest

    -- Use Genero security.Digest for MD5 hashing
    TRY
        LET digest = security.Digest.CreateDigest("MD5")
        CALL digest.AddStringData(p_password)
        LET encrypted = digest.DoHexBinaryDigest()
        RETURN encrypted
    CATCH
        -- Fallback to simple Base64 encoding if MD5 fails
        RETURN security.Base64.FromString(p_password)
    END TRY
END FUNCTION

-- ==============================================================
-- Validate Password (for login verification)
-- ==============================================================
FUNCTION validate_password(p_plain_password STRING, p_encrypted_password STRING)
    RETURNS SMALLINT
    DEFINE test_encrypted STRING

    LET test_encrypted = encrypt_password(p_plain_password)
    IF test_encrypted = p_encrypted_password THEN
        RETURN TRUE
    END IF
    RETURN FALSE
END FUNCTION

-- ==============================================================
-- Populate Role ComboBox
-- ==============================================================
FUNCTION populate_role_combo()
    DEFINE cb ui.ComboBox
    DEFINE role_id INTEGER
    DEFINE role_name STRING

    LET cb = ui.ComboBox.forName("sy00_user.role_id")
    CALL cb.clear()

    DECLARE c_roles CURSOR FOR
        SELECT id, role_name
        FROM sy04_role
        ORDER BY role_name

    FOREACH c_roles INTO role_id, role_name
        CALL cb.addItem(role_id, role_name)
    END FOREACH

    CLOSE c_roles
    FREE c_roles
END FUNCTION

-- ==============================================================
-- Change Password for Selected User
-- ==============================================================
PRIVATE FUNCTION change_password_for_user()
    DEFINE ok SMALLINT

    IF rec_user.username IS NULL OR rec_user.username = "" THEN
        CALL utils_globals.show_error("No user selected.")
        RETURN
    END IF

    -- Call the password change dialog
    LET ok = sy104_user_pwd.change_password(rec_user.username)

    IF ok THEN
        CALL utils_globals.show_info("Password changed successfully for " || rec_user.username)
    END IF
END FUNCTION

-- ==============================================================
-- Public functions for external calls
-- ==============================================================
FUNCTION list_users()
    CALL init_user_module()
END FUNCTION

FUNCTION add_user()
    CALL new_user()
END FUNCTION
