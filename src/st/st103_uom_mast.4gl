-- ==============================================================
-- Program   : st103_uom_mast.4gl
-- Purpose   : Stock UOM Master
-- Module    : UOM Master (uom)
-- Number    : 103
-- Author    : Bongani Dlamini
-- Version   : Genero 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL utils_db
IMPORT FGL utils_global_lkup

SCHEMA demoappdb

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE uom_t RECORD LIKE st03_uom_master.*
DEFINE uom_rec uom_t

DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

-- ==============================================================
-- Init Program
-- ==============================================================
FUNCTION init_uom_module()
    LET is_edit_mode = FALSE
    INITIALIZE uom_rec.* TO NULL
    DISPLAY BY NAME uom_rec.*
    MENU "UOM Master Menu"
        COMMAND "Find"       CALL query_uom_lookup(); LET is_edit_mode = FALSE
        COMMAND "New"        CALL new_uom()
        COMMAND "Edit"       IF uom_rec.id IS NULL OR uom_rec.id = 0 THEN CALL utils_globals.show_info("No record selected.") ELSE CALL edit_uom() END IF
        COMMAND "Delete"     CALL delete_uom()
        COMMAND "Previous"   CALL move_record(-1)
        COMMAND "Next"       CALL move_record(1)
        COMMAND "Exit"       EXIT MENU
    END MENU
END FUNCTION

-- ==============================================================
-- Query using Lookup Window
-- ==============================================================
FUNCTION query_uom_lookup()
    DEFINE selected_code STRING,
           l_code INTEGER,
           l_idx INTEGER,
           i INTEGER

    LET selected_code = utils_global_lkup.display_lookup('uom')

    IF selected_code IS NOT NULL THEN
        -- Load ALL records for navigation
        CALL arr_codes.clear()
        LET l_idx = 0

        TRY
            DECLARE uom_nav_curs CURSOR FOR
                SELECT id FROM st03_uom_master ORDER BY id DESC

            FOREACH uom_nav_curs INTO l_code
                LET l_idx = l_idx + 1
                LET arr_codes[l_idx] = l_code
            END FOREACH

            CLOSE uom_nav_curs
            FREE uom_nav_curs
        CATCH
            CALL utils_globals.show_sql_error("query_uom_lookup: Error loading navigation")
        END TRY

        -- Find the index of the selected record
        LET curr_idx = 1
        FOR i = 1 TO arr_codes.getLength()
            IF arr_codes[i] = selected_code THEN
                LET curr_idx = i
                EXIT FOR
            END IF
        END FOR

        CALL load_uom_item(selected_code)
    ELSE
        CALL utils_globals.show_error("No records found")
    END IF
END FUNCTION

-- ==============================================================
-- Load UOM Record
-- ==============================================================
FUNCTION load_uom_item(p_id INTEGER)
    TRY
        SELECT * INTO uom_rec.* FROM st03_uom_master WHERE id = p_id

        IF SQLCA.SQLCODE = 0 THEN
            --CALL refresh_display_fields()
            DISPLAY BY NAME uom_rec.*
        END IF
    CATCH
        CALL utils_globals.show_sql_error("load_uom_item: Error loading UOM")
    END TRY
END FUNCTION

-- ==============================================================
-- Lookup popup for UOM selection
-- ==============================================================
FUNCTION query_uom() RETURNS STRING
    DEFINE arr_uom DYNAMIC ARRAY OF RECORD
            c1     LIKE st03_uom_master.id,
            c2  LIKE st03_uom_master.uom_code,
            c3  LIKE st03_uom_master.uom_name
        END RECORD,
        lkup_rec RECORD
            c1     LIKE st03_uom_master.id,
            c2  LIKE st03_uom_master.uom_code,
            c3  LIKE st03_uom_master.uom_name
        END RECORD,
        ret_code STRING,
        curr_row, curr_idx SMALLINT,
        frm ui.Form

    LET curr_idx = 1
    LET ret_code = NULL

    OPEN WINDOW w_lkup WITH FORM "utils_global_lkup"
        ATTRIBUTES(STYLE = "lookup")

    -- Set column titles
    LET frm = ui.Window.getCurrent().getForm()
    CALL frm.setElementText("c1", "ID")
    CALL frm.setElementText("c2", "Code")
    CALL frm.setElementText("c3", "Name")

    TRY
        DECLARE uom_curs CURSOR FOR
            SELECT id, uom_code, uom_name
              FROM st03_uom_master
             ORDER BY id DESC

        CALL arr_uom.clear()

        FOREACH uom_curs INTO lkup_rec.*
            LET arr_uom[curr_idx].* = lkup_rec.*
            LET curr_idx = curr_idx + 1
        END FOREACH

        CLOSE uom_curs
        FREE uom_curs
    CATCH
        CALL utils_globals.show_sql_error("query_uom: Error loading UOM list")
    END TRY

    IF arr_uom.getLength() > 0 THEN
        DISPLAY ARRAY arr_uom TO tbl_lookup_list.*
            ATTRIBUTES(UNBUFFERED)
        LET curr_row = arr_curr()
        LET ret_code = arr_uom[curr_row].c1
    ELSE
        CALL utils_globals.msg_no_record()
    END IF

    CLOSE WINDOW w_lkup
    RETURN ret_code
END FUNCTION

-- ==============================================================
-- New UOM
-- ==============================================================
FUNCTION new_uom()
    DEFINE frm ui.Form

    INITIALIZE uom_rec.* TO NULL

    LET uom_rec.status = "active"
    LET uom_rec.created_at = TODAY

    LET frm = ui.Window.getCurrent().getForm()
    CALL frm.setFieldHidden("id", TRUE) -- make id read-only for new

    INPUT BY NAME uom_rec.* ATTRIBUTES(WITHOUT DEFAULTS)

        ON ACTION save
            IF check_uom_unique(uom_rec.uom_code) = 0 THEN
                TRY
                    INSERT INTO st03_uom_master VALUES uom_rec.*
                    CALL utils_globals.msg_saved()
                    EXIT INPUT
                CATCH
                    CALL utils_globals.show_sql_error("new_uom: Error saving UOM")
                END TRY
            END IF

        ON ACTION cancel
            EXIT INPUT
    END INPUT

    IF uom_rec.id IS NOT NULL THEN
        CALL load_uom_item(uom_rec.id)
    END IF
END FUNCTION

-- ==============================================================
-- Edit UOM
-- ==============================================================
FUNCTION edit_uom()
    DEFINE frm ui.Form
    LET frm = ui.Window.getCurrent().getForm()
    CALL frm.setFieldHidden("id", TRUE) -- id is read-only during edit

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME uom_rec.* ATTRIBUTES(WITHOUT DEFAULTS)

            ON ACTION save ATTRIBUTES(TEXT="Update")
                CALL save_uom()
                EXIT DIALOG
            ON ACTION cancel ATTRIBUTES(TEXT="Exit")
                CALL load_uom_item(uom_rec.id)
                EXIT DIALOG
        END INPUT
    END DIALOG
END FUNCTION

-- ==============================================================
-- Save / Update
-- ==============================================================
FUNCTION save_uom()
    DEFINE r_exists INTEGER

    TRY
        SELECT COUNT(*) INTO r_exists FROM st03_uom_master WHERE id = uom_rec.id
        IF r_exists = 0 THEN
            INSERT INTO st03_uom_master VALUES uom_rec.*
            CALL utils_globals.msg_saved()
        ELSE
            UPDATE st03_uom_master SET st03_uom_master.* = uom_rec.* WHERE id = uom_rec.id
            CALL utils_globals.msg_updated()
        END IF
    CATCH
        CALL utils_globals.show_sql_error("save_uom: Error saving UOM")
    END TRY

    CALL load_uom_item(uom_rec.id)
END FUNCTION

-- ==============================================================
-- Navigation and Utilities
-- ==============================================================
FUNCTION select_uom_items(p_where STRING) RETURNS SMALLINT
    DEFINE
        l_sql STRING,
        l_code INTEGER,
        l_idx INTEGER

    -- Reset navigation array
    CALL arr_codes.clear()
    LET l_idx = 0

    -- Build SQL dynamically and safely
    LET l_sql = SFMT("SELECT id FROM st03_uom_master WHERE %1 ORDER BY uom_code", p_where)

    TRY
        -- Open and fetch all matching records
        DECLARE uom_select_curs CURSOR FROM l_sql

        FOREACH uom_select_curs INTO l_code
            LET l_idx = l_idx + 1
            LET arr_codes[l_idx] = l_code
        END FOREACH

        CLOSE uom_select_curs
        FREE uom_select_curs
    CATCH
        CALL utils_globals.show_sql_error("select_uom_items: Error selecting UOM items")
        RETURN FALSE
    END TRY

    -- Handle no records found
    IF arr_codes.getLength() = 0 THEN
        CALL utils_globals.msg_no_record()
        RETURN FALSE
    END IF

    -- Load the first record by default
    LET curr_idx = 1
    CALL load_uom_item(arr_codes[curr_idx])

    RETURN TRUE
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
    CALL load_uom_item(arr_codes[curr_idx])
END FUNCTION

-- ==============================================================
-- Check UOM uniqueness
-- ==============================================================
FUNCTION check_uom_unique(p_uom_code STRING) RETURNS SMALLINT
    DEFINE dup_count INTEGER
    TRY
        SELECT COUNT(*) INTO dup_count FROM st03_uom_master WHERE uom_code = p_uom_code
        IF dup_count > 0 THEN
            CALL utils_globals.show_error("Duplicate UOM code exists.")
            RETURN 1
        END IF
    CATCH
        CALL utils_globals.show_sql_error("check_uom_unique: Error checking UOM uniqueness")
        RETURN 1
    END TRY
    RETURN 0
END FUNCTION

-- ==============================================================
-- Delete UOM
-- ==============================================================
FUNCTION delete_uom()
    DEFINE
        usage_count INTEGER,
        ok SMALLINT

    IF uom_rec.id IS NULL OR uom_rec.id = 0 THEN
        CALL utils_globals.show_info("No UOM selected.")
        RETURN
    END IF

    TRY
        -- Check if UOM is being used in stock items
        SELECT COUNT(*)
            INTO usage_count
            FROM st04_stock_uom
            WHERE uom_id = uom_rec.id
        IF usage_count > 0 THEN
            CALL utils_globals.show_error("Cannot delete UOM that is in use.")
            RETURN
        END IF

        LET ok = utils_globals.show_confirm("Delete this UOM?", "Confirm")
        IF ok THEN
            DELETE FROM st03_uom_master WHERE id = uom_rec.id
            CALL utils_globals.msg_deleted()
            LET ok = select_uom_items("1=1")
        END IF
    CATCH
        CALL utils_globals.show_sql_error("delete_uom: Error deleting UOM")
    END TRY
END FUNCTION