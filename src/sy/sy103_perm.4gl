-- ==============================================================
-- Program   : sy103_perm.4gl
-- Purpose   : Permission Master maintenance (CRUD operations)
-- Module    : System (sy)
-- Number    : 103
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Master file maintenance for system permissions
--              Provides full CRUD operations with array display
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoappdb

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE perm_t RECORD LIKE sy05_perm.*

DEFINE arr_perm DYNAMIC ARRAY OF perm_t
DEFINE curr_row INTEGER

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
--        OPEN WINDOW w_sy103 WITH FORM "sy103_perm" -- ATTRIBUTES(STYLE = "normal")
--    ELSE
--        OPEN WINDOW w_sy103 WITH FORM "sy103_perm" ATTRIBUTES(STYLE = "child")
--    END IF
--
--    CALL init_perm_module()
--
--    IF utils_globals.is_standalone() THEN
--        CLOSE WINDOW w_sy103
--    END IF
--END MAIN

-- ==============================================================
-- Main Controller
-- ==============================================================
FUNCTION init_perm_module()
    CALL utils_globals.set_form_label("lbl_form_title", "PERMISSIONS MASTER MAINTENANCE")

    -- Load all permissions
    CALL load_all_permissions()

    -- Display in interactive array
    CALL display_permissions_array()
END FUNCTION

-- ==============================================================
-- Load All Permissions
-- ==============================================================
FUNCTION load_all_permissions()
    DEFINE l_perm perm_t
    DEFINE l_idx INTEGER

    CALL arr_perm.clear()
    LET l_idx = 0

    TRY
        DECLARE perm_curs CURSOR FOR
            SELECT * FROM sy05_perm
            WHERE deleted_at IS NULL
            ORDER BY perm_code, perm_name

        FOREACH perm_curs INTO l_perm.*
            LET l_idx = l_idx + 1
            LET arr_perm[l_idx].* = l_perm.*
        END FOREACH

        CLOSE perm_curs
        FREE perm_curs

    CATCH
        CALL utils_globals.show_sql_error("load_all_permissions: Error loading permissions")
    END TRY

    IF arr_perm.getLength() = 0 THEN
        CALL utils_globals.show_info("No permissions found. Use 'Add' to create new permissions.")
    END IF
END FUNCTION

-- ==============================================================
-- Display Permissions in Interactive Array
-- ==============================================================
FUNCTION display_permissions_array()
    DIALOG ATTRIBUTES(UNBUFFERED)

        INPUT ARRAY arr_perm FROM arr_perm.*
            ATTRIBUTES(INSERT ROW = FALSE, DELETE ROW = FALSE, APPEND ROW = FALSE)

            BEFORE ROW
                LET curr_row = DIALOG.getCurrentRow("arr_perm")

            ON ACTION add ATTRIBUTES(TEXT="Add", IMAGE="plus")
                CALL new_permission()
                CALL load_all_permissions()
                EXIT DIALOG

            ON ACTION edit ATTRIBUTES(TEXT="Edit", IMAGE="edit")
                IF curr_row > 0 AND curr_row <= arr_perm.getLength() THEN
                    CALL edit_permission(arr_perm[curr_row].id)
                    CALL load_all_permissions()
                    EXIT DIALOG
                ELSE
                    CALL utils_globals.show_info("Please select a permission to edit.")
                END IF

            ON ACTION delete ATTRIBUTES(TEXT="Delete", IMAGE="trash")
                IF curr_row > 0 AND curr_row <= arr_perm.getLength() THEN
                    CALL delete_permission(arr_perm[curr_row].id)
                    CALL load_all_permissions()
                    EXIT DIALOG
                ELSE
                    CALL utils_globals.show_info("Please select a permission to delete.")
                END IF

            ON ACTION refresh ATTRIBUTES(TEXT="Refresh", IMAGE="reload")
                CALL load_all_permissions()
                EXIT DIALOG

            ON ACTION close ATTRIBUTES(TEXT="Close", IMAGE="cancel")
                EXIT DIALOG

        END INPUT

        ON ACTION close
            EXIT DIALOG

    END DIALOG

    -- Loop back to display unless explicitly closed
    IF int_flag = 0 THEN
        CALL display_permissions_array()
    END IF
END FUNCTION

-- ==============================================================
-- New Permission
-- ==============================================================
FUNCTION new_permission()
    DEFINE l_perm perm_t
    DEFINE l_random_user INTEGER

    -- Initialize new record
    INITIALIZE l_perm.* TO NULL
    LET l_perm.status = "active"
    LET l_perm.created_at = TODAY
    LET l_random_user = utils_globals.get_random_user()
    LET l_perm.created_by = l_random_user

    OPEN WINDOW w_perm_edit WITH FORM "sy103_perm_edit"
        ATTRIBUTES(STYLE="dialog", TEXT="New Permission")

    DISPLAY BY NAME l_perm.perm_name, l_perm.description,
                    l_perm.perm_code, l_perm.status

    INPUT BY NAME l_perm.perm_name, l_perm.description,
                  l_perm.perm_code, l_perm.status
        ATTRIBUTES(WITHOUT DEFAULTS)

        BEFORE INPUT
            MESSAGE "Enter new permission details"

        AFTER FIELD perm_name
            IF l_perm.perm_name IS NULL OR l_perm.perm_name = "" THEN
                CALL utils_globals.show_error("Permission name is required.")
                NEXT FIELD perm_name
            END IF

        AFTER FIELD perm_code
            IF l_perm.perm_code IS NULL OR l_perm.perm_code = "" THEN
                CALL utils_globals.show_error("Permission code is required.")
                NEXT FIELD perm_code
            END IF
            -- Check for duplicate
            IF check_duplicate_perm_code(l_perm.perm_code, NULL) THEN
                CALL utils_globals.show_error("Permission code already exists.")
                NEXT FIELD perm_code
            END IF

        ON ACTION save ATTRIBUTES(TEXT="Save", IMAGE="save")
            IF validate_permission(l_perm.*) THEN
                IF save_permission(l_perm.*) THEN
                    CALL utils_globals.msg_saved()
                    EXIT INPUT
                END IF
            ELSE
                CALL utils_globals.show_error("Please complete all required fields.")
            END IF

        ON ACTION cancel ATTRIBUTES(TEXT="Cancel", IMAGE="cancel")
            EXIT INPUT
    END INPUT

    CLOSE WINDOW w_perm_edit
END FUNCTION

-- ==============================================================
-- Edit Permission
-- ==============================================================
FUNCTION edit_permission(p_id INTEGER)
    DEFINE l_perm perm_t

    IF p_id IS NULL OR p_id = 0 THEN
        CALL utils_globals.show_info("Invalid permission ID.")
        RETURN
    END IF

    TRY
        -- Load permission
        SELECT * INTO l_perm.* FROM sy05_perm WHERE id = p_id

        IF SQLCA.SQLCODE != 0 THEN
            CALL utils_globals.show_error("Permission not found.")
            RETURN
        END IF

    CATCH
        CALL utils_globals.show_sql_error("edit_permission: Error loading permission")
        RETURN
    END TRY

    OPEN WINDOW w_perm_edit WITH FORM "sy103_perm_edit"
        ATTRIBUTES(STYLE="dialog", TEXT="Edit Permission")

    DISPLAY BY NAME l_perm.perm_name, l_perm.description,
                    l_perm.perm_code, l_perm.status

    INPUT BY NAME l_perm.perm_name, l_perm.description,
                  l_perm.perm_code, l_perm.status
        ATTRIBUTES(WITHOUT DEFAULTS)

        BEFORE INPUT
            MESSAGE "Edit permission details"

        AFTER FIELD perm_name
            IF l_perm.perm_name IS NULL OR l_perm.perm_name = "" THEN
                CALL utils_globals.show_error("Permission name is required.")
                NEXT FIELD perm_name
            END IF

        AFTER FIELD perm_code
            IF l_perm.perm_code IS NULL OR l_perm.perm_code = "" THEN
                CALL utils_globals.show_error("Permission code is required.")
                NEXT FIELD perm_code
            END IF
            -- Check for duplicate (exclude current record)
            IF check_duplicate_perm_code(l_perm.perm_code, l_perm.id) THEN
                CALL utils_globals.show_error("Permission code already exists.")
                NEXT FIELD perm_code
            END IF

        ON ACTION save ATTRIBUTES(TEXT="Save", IMAGE="save")
            IF validate_permission(l_perm.*) THEN
                LET l_perm.updated_at = TODAY
                IF save_permission(l_perm.*) THEN
                    CALL utils_globals.msg_updated()
                    EXIT INPUT
                END IF
            ELSE
                CALL utils_globals.show_error("Please complete all required fields.")
            END IF

        ON ACTION cancel ATTRIBUTES(TEXT="Cancel", IMAGE="cancel")
            EXIT INPUT
    END INPUT

    CLOSE WINDOW w_perm_edit
END FUNCTION

-- ==============================================================
-- Save Permission (Insert or Update)
-- ==============================================================
FUNCTION save_permission(p_perm perm_t) RETURNS SMALLINT
    DEFINE l_exists INTEGER

    BEGIN WORK

    TRY
        -- Check if record exists
        SELECT COUNT(*) INTO l_exists FROM sy05_perm WHERE id = p_perm.id

        IF l_exists = 0 THEN
            -- Insert new record
            INSERT INTO sy05_perm (perm_name, description, perm_code, status, created_at, created_by)
                VALUES (p_perm.perm_name, p_perm.description, p_perm.perm_code,
                        p_perm.status, p_perm.created_at, p_perm.created_by)
        ELSE
            -- Update existing record
            UPDATE sy05_perm SET
                perm_name = p_perm.perm_name,
                description = p_perm.description,
                perm_code = p_perm.perm_code,
                status = p_perm.status,
                updated_at = p_perm.updated_at
            WHERE id = p_perm.id
        END IF

        COMMIT WORK
        RETURN TRUE

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_sql_error("save_permission: Error saving permission")
        RETURN FALSE
    END TRY
END FUNCTION

-- ==============================================================
-- Delete Permission
-- ==============================================================
FUNCTION delete_permission(p_id INTEGER)
    DEFINE l_perm perm_t
    DEFINE l_role_count INTEGER
    DEFINE l_confirm SMALLINT

    IF p_id IS NULL OR p_id = 0 THEN
        CALL utils_globals.show_info("Invalid permission ID.")
        RETURN
    END IF

    TRY
        -- Load permission
        SELECT * INTO l_perm.* FROM sy05_perm WHERE id = p_id

        IF SQLCA.SQLCODE != 0 THEN
            CALL utils_globals.show_error("Permission not found.")
            RETURN
        END IF

        -- Check if permission is assigned to any roles
        SELECT COUNT(*) INTO l_role_count FROM sy06_role_perm
            WHERE perm_id = p_id

        IF l_role_count > 0 THEN
            CALL utils_globals.show_error(SFMT("Cannot delete permission. It is assigned to %1 role(s).", l_role_count))
            RETURN
        END IF

    CATCH
        CALL utils_globals.show_sql_error("delete_permission: Error checking permission usage")
        RETURN
    END TRY

    LET l_confirm = utils_globals.show_confirm(
        SFMT("Delete permission '%1'?", l_perm.perm_name),
        "Confirm Delete"
    )

    IF NOT l_confirm THEN
        RETURN
    END IF

    BEGIN WORK

    TRY
        -- Soft delete: set deleted_at timestamp
        UPDATE sy05_perm SET deleted_at = TODAY WHERE id = p_id

        COMMIT WORK
        CALL utils_globals.msg_deleted()

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_sql_error("delete_permission: Error deleting permission")
    END TRY
END FUNCTION

-- ==============================================================
-- Validate Permission
-- ==============================================================
FUNCTION validate_permission(p_perm perm_t) RETURNS SMALLINT
    IF p_perm.perm_name IS NULL OR p_perm.perm_name = "" THEN
        RETURN FALSE
    END IF

    IF p_perm.perm_code IS NULL OR p_perm.perm_code = "" THEN
        RETURN FALSE
    END IF

    IF p_perm.status IS NULL OR p_perm.status = "" THEN
        RETURN FALSE
    END IF

    RETURN TRUE
END FUNCTION

-- ==============================================================
-- Check Duplicate Permission Code
-- ==============================================================
FUNCTION check_duplicate_perm_code(p_perm_code STRING, p_exclude_id INTEGER) RETURNS SMALLINT
    DEFINE l_count INTEGER

    TRY
        IF p_exclude_id IS NULL THEN
            SELECT COUNT(*) INTO l_count FROM sy05_perm
                WHERE perm_code = p_perm_code
                AND deleted_at IS NULL
        ELSE
            SELECT COUNT(*) INTO l_count FROM sy05_perm
                WHERE perm_code = p_perm_code
                AND id != p_exclude_id
                AND deleted_at IS NULL
        END IF

        RETURN (l_count > 0)

    CATCH
        CALL utils_globals.show_sql_error("check_duplicate_perm_code: Error checking duplicate")
        RETURN FALSE
    END TRY
END FUNCTION
