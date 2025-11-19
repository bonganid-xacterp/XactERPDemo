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
-- MAIN
-- ==============================================================
--MAIN
--    IF NOT utils_globals.initialize_application() THEN
--        DISPLAY "Initialization failed."
--        EXIT PROGRAM 1
--    END IF
--
--    IF utils_globals.is_standalone() THEN
--        OPTIONS INPUT WRAP
--        OPEN WINDOW w_st103 WITH FORM "st103_uom_mast" -- ATTRIBUTES(STYLE = "normal")
--    END IF
--
--    CALL init_uom_module()
--
--    IF utils_globals.is_standalone() THEN
--        CLOSE WINDOW w_st103
--    END IF
--END MAIN

-- ==============================================================
-- Menu Controller
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
    DEFINE selected_code STRING

    LET selected_code = query_uom()

    IF selected_code IS NOT NULL THEN
        CALL load_uom_item(selected_code)

        -- Update the array to contain just this record for navigation
        CALL arr_codes.clear()
        LET arr_codes[1] = selected_code
        LET curr_idx = 1
    ELSE
        CALL utils_globals.show_error("No records found")
    END IF
END FUNCTION

-- ==============================================================
-- Load UOM Record
-- ==============================================================
FUNCTION load_uom_item(p_id INTEGER)
    SELECT * INTO uom_rec.* FROM st03_uom_master WHERE id = p_id

    IF SQLCA.SQLCODE = 0 THEN
        --CALL refresh_display_fields()
        DISPLAY BY NAME uom_rec.*
        END IF 
END FUNCTION

-- ==============================================================
-- Lookup popup for UOM selection
-- ==============================================================
FUNCTION query_uom() RETURNS STRING
    DEFINE arr_uom DYNAMIC ARRAY OF RECORD
            id     LIKE st03_uom_master.id,
            uom_code  LIKE st03_uom_master.uom_code,
            uom_name  LIKE st03_uom_master.uom_name,
            is_active LIKE st03_uom_master.status
        END RECORD,
        rec_list RECORD
            id     LIKE st03_uom_master.id,
            uom_code  LIKE st03_uom_master.uom_code,
            uom_name  LIKE st03_uom_master.uom_name,
            is_active LIKE st03_uom_master.status
        END RECORD,
        ret_code STRING,
        curr_row, curr_idx SMALLINT

    LET curr_idx = 0
    LET ret_code = NULL

    OPEN WINDOW w_lkup WITH FORM "st103_uom_lkup"
        ATTRIBUTES(TYPE = POPUP, STYLE = "lookup")

    DECLARE uom_curs CURSOR FOR
        SELECT id, uom_code, uom_name, status
          FROM st03_uom_master
         ORDER BY id DESC

    CALL arr_uom.clear()

    FOREACH uom_curs INTO rec_list.*
        LET arr_uom[curr_idx].* = rec_list.*
        LET curr_idx = curr_idx + 1
    END FOREACH

    IF curr_idx > 0 THEN
        DISPLAY ARRAY arr_uom TO rec_list.*
            ATTRIBUTES(COUNT = curr_idx, UNBUFFERED)
        LET curr_row = arr_curr()
        LET ret_code = arr_uom[curr_row].id
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
                INSERT INTO st03_uom_master VALUES uom_rec.*
                CALL utils_globals.msg_saved()
                EXIT INPUT
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

    SELECT COUNT(*) INTO r_exists FROM st03_uom_master WHERE id = uom_rec.id
    IF r_exists = 0 THEN
        INSERT INTO st03_uom_master VALUES uom_rec.*
        CALL utils_globals.msg_saved()
    ELSE
        UPDATE st03_uom_master SET st03_uom_master.* = uom_rec.* WHERE id = uom_rec.id
        CALL utils_globals.msg_updated()
    END IF

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

    -- Open and fetch all matching records
    DECLARE uom_select_curs CURSOR FROM l_sql

    FOREACH uom_select_curs INTO l_code
        LET l_idx = l_idx + 1
        LET arr_codes[l_idx] = l_code
    END FOREACH

    CLOSE uom_select_curs
    FREE uom_select_curs

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
    SELECT COUNT(*) INTO dup_count FROM st03_uom_master WHERE uom_code = p_uom_code
    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Duplicate UOM code exists.")
        RETURN 1
    END IF
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
END FUNCTION