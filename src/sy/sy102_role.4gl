-- ==============================================================
-- Program   : sy102_role.4gl
-- Purpose   : Role Master maintenance (CRUD operations)
-- Module    : System (sy)
-- Number    : 102
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Master file maintenance for system roles
--              Provides full CRUD operations
--              Future: Will include permissions management via checkboxes
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoappdb

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE role_t RECORD LIKE sy04_role.*
DEFINE rec_role role_t

-- Permission checkboxes array (for future use)
DEFINE arr_perms DYNAMIC ARRAY OF RECORD
    perm_id INTEGER,
    perm_name VARCHAR(120),
    perm_code VARCHAR(60),
    is_selected SMALLINT
END RECORD

DEFINE arr_codes DYNAMIC ARRAY OF INTEGER
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

-- ==============================================================
-- MAIN (Standalone or Child Mode)
-- ==============================================================
--MAIN
--    IF NOT utils_globals.initialize_application() THEN
--        CALL utils_globals.show_error("Initialization failed.")
--        EXIT PROGRAM 1
--    END IF
--
--    IF utils_globals.is_standalone() THEN
--        OPEN WINDOW w_sy102 WITH FORM "sy102_role" -- ATTRIBUTES(STYLE = "normal")
--    ELSE
--        OPEN WINDOW w_sy102 WITH FORM "sy102_role" ATTRIBUTES(STYLE = "child")
--    END IF
--
--    CALL init_role_module()
--
--    IF utils_globals.is_standalone() THEN
--        CLOSE WINDOW w_sy102
--    END IF
--END MAIN

-- ==============================================================
-- Main Controller Menu
-- ==============================================================
FUNCTION init_role_module()
    LET is_edit_mode = FALSE
    CALL utils_globals.set_form_label("lbl_form_title", "ROLES MASTER MAINTENANCE")

    -- Initialize the list of records
    CALL load_all_roles()

    MENU "Role Menu"

        COMMAND "Find"
            CALL query_roles()
            LET is_edit_mode = FALSE

        COMMAND "New"
            CALL new_role()
            LET is_edit_mode = FALSE

        COMMAND "Edit"
            IF rec_role.id IS NULL OR rec_role.id = 0 THEN
                CALL utils_globals.show_info("No role selected to edit.")
            ELSE
                LET is_edit_mode = TRUE
                CALL edit_role()
            END IF

        COMMAND "Delete"
            CALL delete_role()
            LET is_edit_mode = FALSE

        COMMAND "Previous"
            CALL move_record(-1)

        COMMAND "Next"
            CALL move_record(1)

        COMMAND "Exit"
            EXIT MENU
    END MENU
END FUNCTION

-- ==============================================================
-- Load All Roles
-- ==============================================================
FUNCTION load_all_roles()
    DEFINE l_id INTEGER
    DEFINE l_idx INTEGER

    CALL arr_codes.clear()
    LET l_idx = 0

    DECLARE role_curs CURSOR FOR
        SELECT id FROM sy04_role
        WHERE deleted_at IS NULL
        ORDER BY role_name

    FOREACH role_curs INTO l_id
        LET l_idx = l_idx + 1
        LET arr_codes[l_idx] = l_id
    END FOREACH

    CLOSE role_curs
    FREE role_curs

    IF arr_codes.getLength() = 0 THEN
        CALL utils_globals.msg_no_record()
        INITIALIZE rec_role.* TO NULL
        DISPLAY BY NAME rec_role.*
        RETURN
    END IF

    -- Load the first record
    LET curr_idx = 1
    CALL load_role(arr_codes[curr_idx])
END FUNCTION

-- ==============================================================
-- Load Role Record
-- ==============================================================
FUNCTION load_role(p_id INTEGER)
    SELECT * INTO rec_role.* FROM sy04_role WHERE id = p_id

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_role.*
        -- Future: Load permissions for this role
        -- CALL load_role_permissions(p_id)
    ELSE
        CALL utils_globals.show_error("Role not found.")
    END IF
END FUNCTION

-- ==============================================================
-- Query Roles (Search)
-- ==============================================================
FUNCTION query_roles()
    DEFINE l_search_name STRING
    DEFINE l_where STRING
    DEFINE l_id INTEGER
    DEFINE l_idx INTEGER

    LET l_search_name = ""

    PROMPT "Enter role name to search (or * for all):" FOR l_search_name

    IF l_search_name IS NULL OR l_search_name = "" THEN
        RETURN
    END IF

    -- Build WHERE clause
    IF l_search_name = "*" THEN
        LET l_where = "deleted_at IS NULL"
    ELSE
        LET l_where = SFMT("role_name ILIKE '%%%1%%' AND deleted_at IS NULL", l_search_name)
    END IF

    -- Clear and rebuild array
    CALL arr_codes.clear()
    LET l_idx = 0

    DECLARE search_curs CURSOR FROM
        "SELECT id FROM sy04_role WHERE " || l_where || " ORDER BY role_name"

    FOREACH search_curs INTO l_id
        LET l_idx = l_idx + 1
        LET arr_codes[l_idx] = l_id
    END FOREACH

    CLOSE search_curs
    FREE search_curs

    IF arr_codes.getLength() = 0 THEN
        CALL utils_globals.msg_no_record()
        RETURN
    END IF

    -- Load first matching record
    LET curr_idx = 1
    CALL load_role(arr_codes[curr_idx])
    CALL utils_globals.show_info(SFMT("Found %1 role(s)", arr_codes.getLength()))
END FUNCTION

-- ==============================================================
-- New Role
-- ==============================================================
FUNCTION new_role()
    DEFINE l_frm ui.Form

    -- Initialize new record
    INITIALIZE rec_role.* TO NULL
    LET rec_role.status = "active"
    LET rec_role.created_at = TODAY

    -- Clear permissions (for future use)
    CALL arr_perms.clear()

    DISPLAY BY NAME rec_role.*

    LET l_frm = ui.Window.getCurrent().getForm()

    INPUT BY NAME rec_role.role_name, rec_role.status
        ATTRIBUTES(WITHOUT DEFAULTS)

        BEFORE INPUT
            MESSAGE "Enter new role details"

        AFTER FIELD role_name
            IF rec_role.role_name IS NULL OR rec_role.role_name = "" THEN
                CALL utils_globals.show_error("Role name is required.")
                NEXT FIELD role_name
            END IF
            -- Check for duplicate
            IF check_duplicate_role_name(rec_role.role_name, NULL) THEN
                CALL utils_globals.show_error("Role name already exists.")
                NEXT FIELD role_name
            END IF

        ON ACTION save ATTRIBUTES(TEXT="Save", IMAGE="save")
            IF validate_role() THEN
                IF save_role() THEN
                    CALL utils_globals.msg_saved()
                    EXIT INPUT
                END IF
            ELSE
                CALL utils_globals.show_error("Please complete all required fields.")
            END IF

        ON ACTION cancel ATTRIBUTES(TEXT="Cancel", IMAGE="cancel")
            INITIALIZE rec_role.* TO NULL
            DISPLAY BY NAME rec_role.*
            EXIT INPUT
    END INPUT

    -- Refresh the list
    IF rec_role.id IS NOT NULL THEN
        CALL load_all_roles()
    END IF
END FUNCTION

-- ==============================================================
-- Edit Role
-- ==============================================================
FUNCTION edit_role()
    DEFINE l_frm ui.Form
    DEFINE l_original_id INTEGER

    IF rec_role.id IS NULL OR rec_role.id = 0 THEN
        CALL utils_globals.show_info("No role selected to edit.")
        RETURN
    END IF

    LET l_original_id = rec_role.id
    LET l_frm = ui.Window.getCurrent().getForm()

    -- Future: Load permissions for editing
    -- CALL load_role_permissions(rec_role.id)

    INPUT BY NAME rec_role.role_name, rec_role.status
        ATTRIBUTES(WITHOUT DEFAULTS)

        BEFORE INPUT
            MESSAGE "Edit role details"

        AFTER FIELD role_name
            IF rec_role.role_name IS NULL OR rec_role.role_name = "" THEN
                CALL utils_globals.show_error("Role name is required.")
                NEXT FIELD role_name
            END IF
            -- Check for duplicate (exclude current record)
            IF check_duplicate_role_name(rec_role.role_name, rec_role.id) THEN
                CALL utils_globals.show_error("Role name already exists.")
                NEXT FIELD role_name
            END IF

        ON ACTION save ATTRIBUTES(TEXT="Save", IMAGE="save")
            IF validate_role() THEN
                LET rec_role.updated_at = TODAY
                IF save_role() THEN
                    CALL utils_globals.msg_updated()
                    EXIT INPUT
                END IF
            ELSE
                CALL utils_globals.show_error("Please complete all required fields.")
            END IF

        ON ACTION cancel ATTRIBUTES(TEXT="Cancel", IMAGE="cancel")
            -- Reload original data
            CALL load_role(l_original_id)
            EXIT INPUT
    END INPUT
END FUNCTION

-- ==============================================================
-- Save Role (Insert or Update)
-- ==============================================================
FUNCTION save_role() RETURNS SMALLINT
    DEFINE l_exists INTEGER

    BEGIN WORK

    TRY
        -- Check if record exists
        SELECT COUNT(*) INTO l_exists FROM sy04_role WHERE id = rec_role.id

        IF l_exists = 0 THEN
            -- Insert new record
            INSERT INTO sy04_role (role_name, status, created_at)
                VALUES (rec_role.role_name, rec_role.status, rec_role.created_at)
            LET rec_role.id = SQLCA.SQLERRD[2]

            -- Future: Save permissions
            -- CALL save_role_permissions(rec_role.id)
        ELSE
            -- Update existing record
            UPDATE sy04_role SET
                role_name = rec_role.role_name,
                status = rec_role.status,
                updated_at = rec_role.updated_at
            WHERE id = rec_role.id

            -- Future: Update permissions
            -- CALL save_role_permissions(rec_role.id)
        END IF

        COMMIT WORK
        DISPLAY BY NAME rec_role.*
        RETURN TRUE

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error("Save failed:\n" || SQLCA.SQLERRM)
        RETURN FALSE
    END TRY
END FUNCTION

-- ==============================================================
-- Delete Role
-- ==============================================================
FUNCTION delete_role()
    DEFINE l_user_count INTEGER
    DEFINE l_confirm SMALLINT

    IF rec_role.id IS NULL OR rec_role.id = 0 THEN
        CALL utils_globals.show_info("No role selected to delete.")
        RETURN
    END IF

    -- Check if role is assigned to any users
    SELECT COUNT(*) INTO l_user_count FROM sy00_user
        WHERE role_id = rec_role.id
        AND deleted_at IS NULL

    IF l_user_count > 0 THEN
        CALL utils_globals.show_error(SFMT("Cannot delete role. It is assigned to %1 user(s).", l_user_count))
        RETURN
    END IF

    LET l_confirm = utils_globals.show_confirm(
        SFMT("Delete role '%1'?", rec_role.role_name),
        "Confirm Delete"
    )

    IF NOT l_confirm THEN
        RETURN
    END IF

    BEGIN WORK

    TRY
        -- Soft delete: set deleted_at timestamp
        UPDATE sy04_role SET deleted_at = TODAY WHERE id = rec_role.id

        -- Future: Delete role permissions
        -- DELETE FROM sy06_role_perm WHERE role_id = rec_role.id

        COMMIT WORK
        CALL utils_globals.msg_deleted()

        -- Reload list and move to next/previous record
        CALL load_all_roles()

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error("Delete failed:\n" || SQLCA.SQLERRM)
    END TRY
END FUNCTION

-- ==============================================================
-- Validate Role
-- ==============================================================
FUNCTION validate_role() RETURNS SMALLINT
    IF rec_role.role_name IS NULL OR rec_role.role_name = "" THEN
        RETURN FALSE
    END IF

    IF rec_role.status IS NULL OR rec_role.status = "" THEN
        RETURN FALSE
    END IF

    RETURN TRUE
END FUNCTION

-- ==============================================================
-- Check Duplicate Role Name
-- ==============================================================
FUNCTION check_duplicate_role_name(p_role_name STRING, p_exclude_id INTEGER) RETURNS SMALLINT
    DEFINE l_count INTEGER

    IF p_exclude_id IS NULL THEN
        SELECT COUNT(*) INTO l_count FROM sy04_role
            WHERE role_name = p_role_name
            AND deleted_at IS NULL
    ELSE
        SELECT COUNT(*) INTO l_count FROM sy04_role
            WHERE role_name = p_role_name
            AND id != p_exclude_id
            AND deleted_at IS NULL
    END IF

    RETURN (l_count > 0)
END FUNCTION

-- ==============================================================
-- Navigation
-- ==============================================================
FUNCTION move_record(p_direction SMALLINT)
    IF arr_codes.getLength() = 0 THEN
        CALL utils_globals.msg_no_record()
        RETURN
    END IF

    CASE p_direction
        WHEN -1  -- Previous
            IF curr_idx > 1 THEN
                LET curr_idx = curr_idx - 1
            ELSE
                CALL utils_globals.msg_start_of_list()
                RETURN
            END IF

        WHEN 1   -- Next
            IF curr_idx < arr_codes.getLength() THEN
                LET curr_idx = curr_idx + 1
            ELSE
                CALL utils_globals.msg_end_of_list()
                RETURN
            END IF
    END CASE

    CALL load_role(arr_codes[curr_idx])
END FUNCTION

-- ==============================================================
-- FUTURE: Permission Management Functions (Placeholder)
-- ==============================================================

-- Load permissions assigned to a role
FUNCTION load_role_permissions(p_role_id INTEGER)
    -- TODO: This will be implemented later
    -- Will load permissions from sy06_role_perm and sy05_perm
    -- and populate arr_perms array for checkbox display

    -- Example structure:
    -- SELECT p.id, p.perm_name, p.perm_code,
    --        CASE WHEN rp.role_id IS NULL THEN 0 ELSE 1 END AS is_selected
    -- FROM sy05_perm p
    -- LEFT JOIN sy06_role_perm rp ON rp.perm_id = p.id AND rp.role_id = p_role_id
    -- WHERE p.status = 'active'
    -- ORDER BY p.perm_name

    RETURN
END FUNCTION

-- Save permission assignments for a role
FUNCTION save_role_permissions(p_role_id INTEGER)
    -- TODO: This will be implemented later
    -- Will delete existing permissions for this role
    -- Then insert new ones based on arr_perms selections

    -- Example:
    -- DELETE FROM sy06_role_perm WHERE role_id = p_role_id
    -- FOR each item in arr_perms where is_selected = 1
    --     INSERT INTO sy06_role_perm (role_id, perm_id) VALUES (p_role_id, perm_id)

    RETURN
END FUNCTION

-- Display permissions in checkbox format
FUNCTION display_permissions()
    -- TODO: This will be implemented later
    -- Will use DISPLAY ARRAY or INPUT ARRAY to show checkboxes
    -- allowing user to select/deselect permissions for the role

    RETURN
END FUNCTION
