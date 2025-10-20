-- ==============================================================
-- Program   : wh103_tag.4gl
-- Purpose   : Warehouse Tag Master maintenance (CRUD operations)
-- Module    : Warehouse (wh)
-- Number    : 103
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Master file maintenance for warehouse tags
--              Provides full CRUD operations for tag records
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoapp_db -- Use correct schema name

-- Warehouse tag record structure
TYPE tag_t RECORD
    tag_code STRING, -- Tag code (primary key)
    tag_name STRING, -- Tag name
    wh_code STRING, -- Associated warehouse code
    description STRING, -- Tag description
    status SMALLINT -- Status (1=Active, 0=Inactive)
END RECORD

DEFINE rec_tag tag_t
DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT
DEFINE master_config utils_globals.master_record

--MAIN
--    IF NOT utils_globals.initialize_application() THEN
--        EXIT PROGRAM 1
--    END IF
--
--    CALL initMasterConfig()
--    OPEN WINDOW w_wh102 WITH FORM "wh102_tag" ATTRIBUTES(STYLE = "main")
--    CALL init_module()
--    CLOSE WINDOW w_wh102
--END MAIN

FUNCTION initMasterConfig()
    LET master_config.table_name = "wh02_tag"
    LET master_config.key_field = "tag_code"
    LET master_config.name_field = "tag_name"
    LET master_config.phone_field = ""
    LET master_config.email_field = ""
END FUNCTION

--FUNCTION init_module()
--    CALL utils_globals.populate_status_combo("status")
--    LET is_edit_mode = FALSE
--
--    DIALOG ATTRIBUTES(UNBUFFERED)
--        INPUT BY NAME rec_tag.* ATTRIBUTES(WITHOUT DEFAULTS, NAME = "tag")
--
--            BEFORE INPUT
--                -- CALL MasterCRUD.setEditMode(DIALOG, FALSE)
--
--            ON ACTION new ATTRIBUTES(TEXT = "Create", IMAGE = "new")
--                CALL new_tag()
--                -- CALL MasterCRUD.setEditMode(DIALOG, FALSE)
--
--            ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
--                IF utils_globals.is_empty(rec_tag.tag_code) THEN
--                    CALL utils_globals.show_info("No record selected to edit.")
--                ELSE
--                    LET is_edit_mode = TRUE
--                    -- CALL MasterCRUD.setEditMode(DIALOG, TRUE)
--                END IF
--
--            ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
--                IF is_edit_mode THEN
--                    CALL save_tag()
--                    LET is_edit_mode = FALSE
--                    -- CALL MasterCRUD.setEditMode(DIALOG, FALSE)
--                END IF
--
--            ON ACTION DELETE ATTRIBUTES(TEXT = "Delete", IMAGE = "delete")
--                CALL delete_tag()
--
--            ON ACTION FIRST ATTRIBUTES(TEXT = "First", IMAGE = "first")
--                CALL move_record(-2)
--            ON ACTION PREVIOUS ATTRIBUTES(TEXT = "Previous", IMAGE = "prev")
--                CALL move_record(-1)
--            ON ACTION NEXT ATTRIBUTES(TEXT = "Next", IMAGE = "next")
--                CALL move_record(1)
--            ON ACTION LAST ATTRIBUTES(TEXT = "Last", IMAGE = "last")
--                CALL move_record(2)
--            ON ACTION QUIT ATTRIBUTES(TEXT = "Quit", IMAGE = "quit")
--                EXIT DIALOG
--
--            BEFORE FIELD tag_name, wh_code, description, status
--                IF NOT is_edit_mode THEN
--                    CALL utils_globals.show_info("Click Edit to modify.")
--                    NEXT FIELD tag_code
--                END IF
--        END INPUT
--
--        BEFORE DIALOG
--            --LET arr_codes = utils_globals.select_records(master_config.table_name, "1=1")
--            --IF arr_codes.getLength() > 0 THEN
--            --    LET curr_idx = 1
--            --    CALL load_tag(arr_codes[curr_idx])
--            --END IF
--    END DIALOG
--END FUNCTION

FUNCTION load_tag(p_code STRING)
    SELECT tag_code, tag_name, wh_code, description, status
        INTO rec_tag.*
        FROM wh02_tag
        WHERE tag_code = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_tag.*
    END IF
END FUNCTION

--FUNCTION move_record(dir SMALLINT)
--    LET curr_idx = utils_globals.navigate_records(arr_codes, curr_idx, dir)
--    CALL load_tag(arr_codes[curr_idx])
--    -- CALL MasterCRUD.setEditMode(DIALOG, FALSE)
--    LET is_edit_mode = FALSE
--END FUNCTION

FUNCTION new_tag()
    DEFINE new_code STRING

    OPEN WINDOW w_new WITH FORM "wh102_tag" ATTRIBUTES(STYLE = "dialog")
    INITIALIZE rec_tag.* TO NULL
    LET rec_tag.status = 1
    DISPLAY BY NAME rec_tag.*

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_tag.* ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_tag")

            ON ACTION save ATTRIBUTES(TEXT = "Save")
                IF validateFields() THEN
                    IF checkUniqueness() THEN
                        INSERT INTO wh02_tag(
                            tag_code, tag_name, wh_code, description, status)
                            VALUES(rec_tag.tag_code,
                                rec_tag.tag_name,
                                rec_tag.wh_code,
                                rec_tag.description,
                                rec_tag.status)

                        CALL utils_globals.show_success(
                            "Tag saved successfully.")
                        LET new_code = rec_tag.tag_code
                        EXIT DIALOG
                    END IF
                END IF

            ON ACTION cancel
                LET new_code = NULL
                EXIT DIALOG
        END INPUT
    END DIALOG

    CLOSE WINDOW w_new

    IF new_code IS NOT NULL THEN
        CALL load_tag(new_code)
        CALL arr_codes.clear()
        LET arr_codes[1] = new_code
        LET curr_idx = 1
    END IF
END FUNCTION

FUNCTION save_tag()
    DEFINE exists INTEGER
    SELECT COUNT(*) INTO exists FROM wh02_tag WHERE tag_code = rec_tag.tag_code

    IF exists = 0 THEN
        INSERT INTO wh02_tag(
            tag_code, tag_name, wh_code, description, status)
            VALUES(rec_tag.tag_code,
                rec_tag.tag_name,
                rec_tag.wh_code,
                rec_tag.description,
                rec_tag.status)
        CALL utils_globals.msg_saved()
    ELSE
        UPDATE wh02_tag
            SET tag_name = rec_tag.tag_name,
                wh_code = rec_tag.wh_code,
                description = rec_tag.description,
                status = rec_tag.status
            WHERE tag_code = rec_tag.tag_code
        CALL utils_globals.msg_updated()
    END IF
    CALL load_tag(rec_tag.tag_code)
END FUNCTION

FUNCTION delete_tag()
    IF utils_globals.is_empty(rec_tag.tag_code) THEN
        CALL utils_globals.show_info("No tag selected for deletion.")
        RETURN
    END IF

    IF utils_globals.confirm_delete("tag", rec_tag.tag_name) THEN
        DELETE FROM wh02_tag WHERE tag_code = rec_tag.tag_code
        CALL utils_globals.msg_deleted()
        --LET arr_codes = utils_globals.select_records(master_config.table_name, "1=1")
        --IF arr_codes.getLength() > 0 THEN
        --    LET curr_idx = 1
        --    CALL load_tag(arr_codes[curr_idx])
        --END IF
    END IF
END FUNCTION

FUNCTION validateFields() RETURNS BOOLEAN
    IF utils_globals.is_empty(rec_tag.tag_code) THEN
        CALL utils_globals.show_error("Tag Code is required.")
        RETURN FALSE
    END IF
    IF utils_globals.is_empty(rec_tag.tag_name) THEN
        CALL utils_globals.show_error("Tag Name is required.")
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION

FUNCTION checkUniqueness() RETURNS BOOLEAN
    DEFINE count INTEGER
    SELECT COUNT(*) INTO count FROM wh02_tag WHERE tag_code = rec_tag.tag_code
    IF COUNT > 0 THEN
        CALL utils_globals.show_error("Tag code already exists.")
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION
