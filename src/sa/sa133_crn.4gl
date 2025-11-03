-- ==============================================================
-- Program   : sa133_crn.4gl
-- Purpose   : Sales Credit Note Program
-- Module    : Sales Credit Note (sa)
-- Number    : 132
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoapp_db

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE cr_note_hdr_t RECORD LIKE sa33_crn_hdr.*
DEFINE rec_crn cr_note_hdr_t

DEFINE arr_crn_line DYNAMIC ARRAY OF RECORD LIKE sa33_crn_det.*

DEFINE arr_codes  DYNAMIC ARRAY OF STRING
DEFINE curr_idx   INTEGER

-- ==============================================================
-- Show cr_note
-- ==============================================================
FUNCTION show_cr_note(p_doc_no INTEGER)
    -- Open the cr_note window inside the MDI container
    OPTIONS INPUT WRAP
    OPEN WINDOW w_crn WITH FORM "sa131_cr_note" ATTRIBUTES(STYLE="child")

    -- Load header + lines
    CALL load_cr_note(p_doc_no)

    -- View/edit the cr_note
    CALL edit_cr_note_dialog()

    CLOSE WINDOW w_crn
END FUNCTION


-- ==============================================================
-- Load cr_note Header and Lines
-- ==============================================================
FUNCTION load_cr_note(p_doc_no INTEGER)
    DEFINE idx INTEGER

    INITIALIZE rec_crn.* TO NULL
    CALL arr_crn_line.clear()

    SELECT * INTO rec_crn.* FROM sa33_crn_hdr WHERE doc_no = p_doc_no

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_crn.*
        -- Load lines for this cr_note
        DECLARE c_lines CURSOR FOR
            SELECT * FROM sa33_crn_det WHERE doc_no = p_doc_no ORDER BY line_no

        FOREACH c_lines INTO arr_crn_line[idx + 1].*
            LET idx = idx + 1
        END FOREACH

        CLOSE c_lines
        FREE c_lines
    ELSE
        CALL utils_globals.show_error("cr_note not found.")
    END IF
END FUNCTION

-- ==============================================================
-- Edit / View cr_note (dialog)
-- ==============================================================
FUNCTION edit_cr_note_dialog()
    DIALOG ATTRIBUTES(UNBUFFERED)

        -- Header section fields
        INPUT BY NAME rec_crn.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME="cr_note_header")

            ON ACTION save ATTRIBUTES(TEXT="Save",IMAGE="filesave")
                CALL save_cr_note()
                EXIT DIALOG

            ON ACTION close ATTRIBUTES(TEXT="Close",IMAGE="exit")
                EXIT DIALOG
        END INPUT

        -- Lines section (display array for cr_note details)
        DISPLAY ARRAY arr_crn_line TO sr_cr_note_lines.*

            ON ACTION add
                CALL add_cr_note_line()
            ON ACTION delete
               CALL delete_cr_note_line(arr_curr())
            ON ACTION save
                CALL save_cr_note()
            ON ACTION close
                EXIT DIALOG
        END DISPLAY
        
    END DIALOG
END FUNCTION


-- ==============================================================
-- Add cr_note Line
-- ==============================================================
FUNCTION add_cr_note_line()
    DEFINE new_line RECORD LIKE sa33_crn_det.*
    LET new_line.line_no = arr_crn_line.getLength() + 1

    INPUT BY NAME new_line.*
        ATTRIBUTES(WITHOUT DEFAULTS, NAME="new_line")

        ON ACTION save
            LET arr_crn_line[arr_crn_line.getLength() + 1] = new_line
            CALL utils_globals.show_info("Line added.")
            EXIT INPUT

        ON ACTION cancel
            EXIT INPUT
    END INPUT
END FUNCTION


-- ==============================================================
-- Delete Selected Line
-- ==============================================================
FUNCTION delete_cr_note_line(p_curr_row INTEGER)  -- FIX: Added parameter
    IF arr_crn_line.getLength() = 0 THEN
        CALL utils_globals.show_info("No line to delete.")
        RETURN
    END IF

    IF p_curr_row < 1 OR p_curr_row > arr_crn_line.getLength() THEN
        CALL utils_globals.show_info("Invalid line selected.")
        RETURN
    END IF

    CALL arr_crn_line.deleteElement(p_curr_row)  -- FIX: Use correct method
    CALL utils_globals.show_info("Line deleted.")
END FUNCTION


-- ==============================================================
-- Save cr_note (Header + Lines)
-- ==============================================================
FUNCTION save_cr_note()
    DEFINE exists INTEGER

    SELECT COUNT(*) INTO exists FROM sa33_crn_hdr WHERE doc_no = rec_crn.doc_no

    IF exists = 0 THEN
        INSERT INTO sa33_crn_hdr VALUES rec_crn.*
        CALL utils_globals.msg_saved()
    ELSE
        UPDATE sa33_crn_hdr SET sa33_crn_hdr.* = rec_crn.* WHERE doc_no = rec_crn.doc_no
        CALL utils_globals.msg_updated()
    END IF

    -- Save lines
    DELETE FROM sa33_crn_det WHERE doc_no = rec_crn.doc_no
    FOR curr_idx = 1 TO arr_crn_line.getLength()
        INSERT INTO sa33_crn_det VALUES arr_crn_line[curr_idx].*
    END FOR
    
END FUNCTION


-- ==============================================================
-- Delete cr_note
-- ==============================================================
FUNCTION delete_crn(p_doc_no INTEGER)
    DEFINE ok SMALLINT

    IF p_doc_no IS NULL THEN
        CALL utils_globals.show_info("No Credit Note selected for deletion.")
        RETURN
    END IF

    LET ok = utils_globals.show_confirm("Delete this Credit Note?", "Confirm Delete")

    IF NOT ok THEN
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    DELETE FROM sa33_crn_det WHERE doc_no = p_doc_no
    DELETE FROM sa33_crn_hdr WHERE doc_no = p_doc_no
    CALL utils_globals.msg_deleted()
    
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
    CALL load_cr_note(arr_codes[curr_idx])
END FUNCTION
