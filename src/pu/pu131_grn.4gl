-- ==============================================================
-- Program   : pu131_grn.4gl
-- Purpose   : Good Received Note (Header + Lines)
-- Module    : Purchases (pu)
-- Author    : Bongani Dlamini
-- Version   : Genero 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
-- Optional lookups (uncomment if you have them wired)
-- IMPORT FGL cl121_lkup
-- IMPORT FGL st121_st_lkup

SCHEMA demoapp_db

-- =======================
-- Types / Globals
-- =======================
TYPE grn_hdr_t RECORD LIKE pu31_grn_hdr.*

DEFINE grn_hdr_rec grn_hdr_t

DEFINE grn_lines_arr DYNAMIC ARRAY OF RECORD LIKE pu31_grn_det.*

DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx SMALLINT
DEFINE is_edit SMALLINT

-- =======================
-- MAIN
-- =======================
--MAIN
--    IF NOT utils_globals.initialize_application() THEN
--        DISPLAY "Initialization failed."
--        EXIT PROGRAM 1
--    END IF
--        OPTIONS INPUT WRAP
--    OPEN WINDOW w_pu_grn WITH FORM "pu131_grn" ATTRIBUTES(STYLE = "dialog")
--    CALL init_grn_module()
--    CLOSE WINDOW w_pu_grn
--END MAIN

-- =======================
-- init Module
-- =======================
FUNCTION init_grn_module()
    DEFINE row_idx INTEGER

    LET is_edit = FALSE
    INITIALIZE grn_hdr_rec.* TO NULL

    CLEAR SCREEN

    INPUT BY NAME grn_hdr_rec.*

    DIALOG ATTRIBUTES(UNBUFFERED)

        INPUT BY NAME grn_hdr_rec.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "grn_header")

            BEFORE FIELD acc_code, trans_date, status
                IF NOT is_edit THEN
                    CALL utils_globals.show_info("Click New or Edit to modify.")
                    NEXT FIELD doc_no
                END IF

            AFTER FIELD trans_date
                IF grn_hdr_rec.trans_date IS NULL THEN
                    LET grn_hdr_rec.trans_date = TODAY
                    DISPLAY BY NAME grn_hdr_rec.trans_date
                END IF

            ON ACTION new ATTRIBUTES(TEXT = "New", IMAGE = "new")
                CALL new_pu_grn()
                LET is_edit = TRUE

            ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
                IF grn_hdr_rec.doc_no IS NULL OR grn_hdr_rec.doc_no = 0 THEN
                    CALL utils_globals.show_info("No PO selected to edit.")
                ELSE
                    IF grn_hdr_rec.status <> "draft" THEN
                        CALL utils_globals.show_warning(
                            "Only 'draft' orders can be edited.")
                    ELSE
                        LET is_edit = TRUE
                        MESSAGE "Edit mode enabled."
                    END IF
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Save", IMAGE = "filesave")
                IF is_edit THEN
                    CALL save_pu_grn()
                    LET is_edit = FALSE
                END IF

            ON ACTION post ATTRIBUTES(TEXT = "Post", IMAGE = "ok")
                CALL do_post()

            ON ACTION find ATTRIBUTES(TEXT = "Find", IMAGE = "zoom")
                CALL do_find()

            ON ACTION quit ATTRIBUTES(TEXT = "Quit", IMAGE = "quit")
                EXIT DIALOG
        END INPUT

        INPUT ARRAY grn_lines_arr
            FROM pu130_ord_trans.*
            ATTRIBUTES(INSERT ROW = TRUE, DELETE ROW = TRUE, APPEND ROW = TRUE)
            BEFORE INPUT
                IF NOT is_edit THEN
                    CALL utils_globals.show_info(
                        "Switch to Edit/New to change lines.")
                END IF

            BEFORE ROW
                LET row_idx = arr_curr()

            AFTER FIELD qnty, unit_cost
                CALL calc_line_total(row_idx)
        END INPUT

    END DIALOG
END FUNCTION

-- =======================
-- New Purchase Order
-- =======================
FUNCTION new_pu_grn()
    DEFINE next_doc INTEGER
    DEFINE ok SMALLINT

    -- Initialize header
    SELECT COALESCE(MAX(doc_no), 0) + 1 INTO next_doc FROM pu31_grn_hdr
    INITIALIZE grn_hdr_rec.* TO NULL
    CALL grn_lines_arr.clear()

    LET grn_hdr_rec.doc_no = next_doc
    LET grn_hdr_rec.trans_date = TODAY
    LET grn_hdr_rec.status = "draft"
    LET grn_hdr_rec.gross_tot = 0
    LET grn_hdr_rec.vat = 0
    LET grn_hdr_rec.net_tot = 0
    LET grn_hdr_rec.created_at = CURRENT
    LET grn_hdr_rec.created_by = 1

    -- Input header fields
    INPUT BY NAME grn_hdr_rec.*
        WITHOUT DEFAULTS
        ATTRIBUTES(UNBUFFERED, ACCEPT = TRUE, CANCEL = TRUE)

        ON ACTION accept
            -- Validate header
            IF grn_hdr_rec.acc_code IS NULL THEN
                ERROR "Supplier is required"
                NEXT FIELD acc_code
            END IF
            ACCEPT INPUT

        ON ACTION cancel
            LET ok = FALSE
            EXIT INPUT
    END INPUT

    IF INT_FLAG THEN
        LET INT_FLAG = FALSE
        RETURN
    END IF

    -- Save header to database
    BEGIN WORK
    TRY
        INSERT INTO pu31_grn_hdr VALUES(grn_hdr_rec.*)
        -- Get the generated hdr_id
        LET grn_hdr_rec.id = SQLCA.SQLERRD[2]

        COMMIT WORK
        MESSAGE SFMT("PO Header %1 saved. ID=%2. Now add lines.",
            next_doc, grn_hdr_rec.id)

        -- Now call function to input lines
        CALL input_pu_grn_lines()

    CATCH
        ROLLBACK WORK
        ERROR SFMT("Failed to save PO: %1", SQLCA.sqlawarn)
        RETURN
    END TRY

END FUNCTION

-- input the order lines
--FUNCTION input_pu_grn_lines()
--    INPUT ARRAY grn_lines_arr FROM scr_lines.*
--        ATTRIBUTES(UNBUFFERED, APPEND ROW=TRUE, DELETE ROW=TRUE)
--
--        BEFORE INSERT
--            LET grn_lines_arr[arr_curr()].hdr_id = grn_hdr_rec.id
--            LET grn_lines_arr[arr_curr()].stock_code = arr_curr()
--
--        ON ACTION save_lines
--            -- Save all lines to database
--            CALL save_pu_grn_lines()
--            EXIT INPUT
--
--    END INPUT
--END FUNCTION

-- save the po lines to the database
-- Save PO lines to database
FUNCTION save_pu_grn_lines()
    DEFINE i INTEGER
    DEFINE line_rec RECORD LIKE pu31_grn_det.*

    BEGIN WORK
    TRY
        -- First delete existing lines for this header (in case of edit)
        DELETE FROM pu31_grn_det WHERE hdr_id = grn_hdr_rec.id

        -- Insert all lines
        FOR i = 1 TO grn_lines_arr.getLength()
            IF grn_lines_arr[i].stock_code IS NOT NULL THEN
                LET line_rec.* = grn_lines_arr[i].*
                LET line_rec.hdr_id = grn_hdr_rec.id
                LET line_rec.stock_code = i

                INSERT INTO pu31_grn_det VALUES(line_rec.*)
            END IF
        END FOR

        -- Recalculate header totals
        CALL recalc_pu_grn_totals()

        -- Update header with new totals
        UPDATE pu31_grn_hdr
            SET gross_tot = grn_hdr_rec.gross_tot,
                vat = grn_hdr_rec.vat,
                net_tot = grn_hdr_rec.net_tot,
                updated_at = CURRENT
            WHERE id = grn_hdr_rec.id

        COMMIT WORK
        MESSAGE SFMT("PO lines saved successfully. Total: %1",
            grn_hdr_rec.net_tot)

    CATCH
        ROLLBACK WORK
        ERROR SFMT("Failed to save lines: %1", SQLCA.sqlawarn)
    END TRY
END FUNCTION

-- Enhanced input_pu_grn_lines with validation
FUNCTION input_pu_grn_lines()
    DEFINE item_code STRING
    DEFINE line_tot DECIMAL(15, 2)

    INPUT ARRAY grn_lines_arr
        FROM scr_lines.*
        ATTRIBUTES(UNBUFFERED,
            APPEND ROW = TRUE,
            DELETE ROW = TRUE,
            INSERT ROW = TRUE,
            MAXCOUNT = 999)

        BEFORE INSERT
            LET grn_lines_arr[arr_curr()].hdr_id = grn_hdr_rec.id
            LET grn_lines_arr[arr_curr()].stock_code = arr_curr()
            LET grn_lines_arr[arr_curr()].qnty = 1
            LET grn_lines_arr[arr_curr()].unit_cost = 0
            LET grn_lines_arr[arr_curr()].vat = 0
            LET grn_lines_arr[arr_curr()].line_tot = 0

        BEFORE FIELD stock_code
            LET curr_idx = arr_curr()

        AFTER FIELD stock_code
            IF grn_lines_arr[curr_idx].stock_code IS NOT NULL THEN
                -- Validate item exists
                SELECT description, unit_price
                    INTO item_code, grn_lines_arr[curr_idx].unit_cost
                    FROM st10_item
                    WHERE stock_code = grn_lines_arr[curr_idx].stock_code

                IF SQLCA.SQLCODE = NOTFOUND THEN
                    ERROR "Item not found"
                    LET grn_lines_arr[curr_idx].stock_code = NULL
                    NEXT FIELD stock_code
                ELSE
                    LET grn_lines_arr[curr_idx].stock_code = item_code
                    DISPLAY grn_lines_arr[curr_idx].id
                        TO grn_lines_arr[curr_idx].item_code
                END IF
            END IF

        ON CHANGE qnty, price
            -- Recalculate line amount
            IF grn_lines_arr[curr_idx].qnty IS NOT NULL
                AND grn_lines_arr[curr_idx].unit_cost IS NOT NULL THEN

                LET line_tot =
                    grn_lines_arr[curr_idx].qnty
                        * grn_lines_arr[curr_idx].unit_cost

                --IF grn_lines_arr[curr_idx].disc_pct > 0 THEN
                --    LET line_tot =
                --        line_tot * (1 - grn_lines_arr[curr_idx].disc_pct / 100)
                --END IF

                LET grn_lines_arr[curr_idx].line_tot = line_tot
                DISPLAY grn_lines_arr[curr_idx].line_tot
                    TO scr_lines[curr_idx].line_tot
            END IF

        ON ACTION item_lookup
            CALL lookup_item() RETURNING grn_lines_arr[curr_idx].stock_code
            IF grn_lines_arr[curr_idx].stock_code IS NOT NULL THEN
                -- Trigger AFTER FIELD logic
                CALL DIALOG.nextField("qnty")
            END IF

        ON ACTION save_lines
            -- Validate at least one line exists
            IF grn_lines_arr.getLength() = 0 THEN
                ERROR "Please add at least one line item"
                CONTINUE INPUT
            END IF

            -- Check all lines have required fields
            IF NOT validate_pu_grn_lines() THEN
                CONTINUE INPUT
            END IF

            CALL save_pu_grn_lines()
            EXIT INPUT

        ON ACTION cancel
            IF confirm_cancel() THEN
                EXIT INPUT
            END IF

    END INPUT
END FUNCTION

-- Validate all lines
FUNCTION validate_pu_grn_lines()
    DEFINE i INTEGER
    DEFINE is_valid SMALLINT

    LET is_valid = TRUE

    FOR i = 1 TO grn_lines_arr.getLength()
        IF grn_lines_arr[i].stock_code IS NULL THEN
            ERROR SFMT("Line %1: Item code is required", i)
            LET is_valid = FALSE
            EXIT FOR
        END IF

        IF grn_lines_arr[i].qnty IS NULL OR grn_lines_arr[i].qnty <= 0 THEN
            ERROR SFMT("Line %1: Quantity must be greater than 0", i)
            LET is_valid = FALSE
            EXIT FOR
        END IF

    END FOR

    RETURN is_valid
END FUNCTION

-- Recalculate header totals from lines
FUNCTION recalc_pu_grn_totals()
    DEFINE i INTEGER
    DEFINE gross DECIMAL(15, 2)
    DEFINE vat_amt DECIMAL(15, 2)
    DEFINE vat_rate DECIMAL(5, 2)

    LET gross = 0
    LET vat_rate = 15.00 -- Adjust to your VAT rate

    FOR i = 1 TO grn_lines_arr.getLength()
        IF grn_lines_arr[i].line_tot IS NOT NULL THEN
            LET gross = gross + grn_lines_arr[i].line_tot
        END IF
    END FOR

    LET grn_hdr_rec.gross_tot = gross
    LET vat_amt = gross  * (vat_rate / 100)
    LET grn_hdr_rec.vat = vat_amt
    LET grn_hdr_rec.net_tot = gross + vat_amt

    -- Update display
    DISPLAY BY NAME grn_hdr_rec.gross_tot,
        grn_hdr_rec.vat,
        grn_hdr_rec.net_tot
END FUNCTION

-- Confirm cancel action
FUNCTION confirm_pu_grn_cancel()

    MENU "Cancel PO Lines"
        ATTRIBUTES(STYLE = "dialog", COMMENT = "Discard unsaved changes?")
        COMMAND "Yes"
            RETURN TRUE
        COMMAND "No"
            RETURN FALSE
    END MENU
    
END FUNCTION

-- Item lookup helper (optional)
FUNCTION lookup_pu_grn_item()
    DEFINE selected_code STRING
    -- Implement your item lookup window here
    -- OPEN WINDOW w_lookup...
    -- ...selection logic...
    RETURN selected_code
END FUNCTION

-- =======================
-- Save (insert/update)
-- =======================
FUNCTION save_pu_grn()
    DEFINE exists_cnt INTEGER
    DEFINE i INTEGER

    -- Basic validation
    IF grn_hdr_rec.acc_code IS NULL THEN
        CALL utils_globals.show_warning("Please select a supplier (acc_code).")
        RETURN
    END IF
    IF grn_lines_arr.getLength() = 0 THEN
        CALL utils_globals.show_warning("Please add at least one line.")
        RETURN
    END IF

    -- Final totals
    CALL recalc_totals()

    BEGIN WORK
    TRY
        SELECT COUNT(*)
            INTO exists_cnt
            FROM pu31_grn_hdr
            WHERE doc_no = grn_hdr_rec.doc_no

        IF exists_cnt = 0 THEN
            INSERT INTO pu31_grn_hdr VALUES grn_hdr_rec.*
        ELSE
            LET grn_hdr_rec.updated_at = CURRENT
            UPDATE pu31_grn_hdr
                SET pu31_grn_hdr.* = grn_hdr_rec.*
                WHERE doc_no = grn_hdr_rec.doc_no
        END IF

        DELETE FROM pu31_grn_det WHERE doc_no = grn_hdr_rec.doc_no

        FOR i = 1 TO grn_lines_arr.getLength()
            IF grn_lines_arr[i].stock_code IS NOT NULL THEN
                -- Ensure doc_no and stock_code are correct
                LET grn_lines_arr[i].hdr_id = grn_hdr_rec.doc_no
                IF grn_lines_arr[i].stock_code IS NULL
                    OR grn_lines_arr[i].stock_code = 0 THEN
                    LET grn_lines_arr[i].stock_code = i
                END IF
                CALL calc_line_total(i)
                INSERT INTO pu31_grn_det VALUES grn_lines_arr[i].*
            END IF
        END FOR

        COMMIT WORK
        CALL utils_globals.show_info(SFMT("PO %1 saved.", grn_hdr_rec.doc_no))
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error("Save failed:\n" || SQLCA.SQLERRM)
    END TRY
END FUNCTION

-- =======================
-- Post (mark posted + update stock_on_order)
-- =======================
FUNCTION do_pu_grn_post()
    DEFINE i INTEGER
    DEFINE answer STRING

    IF grn_hdr_rec.doc_no IS NULL THEN
        CALL utils_globals.show_info("No PO selected.")
        RETURN
    END IF
    IF grn_hdr_rec.status <> "draft" THEN
        CALL utils_globals.show_warning("This order is already posted.")
        RETURN
    END IF
    IF grn_lines_arr.getLength() = 0 THEN
        CALL utils_globals.show_warning("Cannot post an empty order.")
        RETURN
    END IF

    PROMPT "Post this PO? (yes/no) " FOR answer
    IF answer <> "yes" THEN
        RETURN
    END IF

    BEGIN WORK
    TRY
        FOR i = 1 TO grn_lines_arr.getLength()
            IF grn_lines_arr[i].stock_code IS NOT NULL THEN
                UPDATE st01_mast
                    SET stock_on_order
                        = stock_on_order + COALESCE(grn_lines_arr[i].qnty, 0)
                    WHERE stock_code = grn_lines_arr[i].stock_code
            END IF
        END FOR

        UPDATE pu31_grn_hdr
            SET status = "posted", updated_at = CURRENT
            WHERE doc_no = grn_hdr_rec.doc_no

        LET grn_hdr_rec.status = "posted"
        DISPLAY BY NAME grn_hdr_rec.status

        COMMIT WORK
        CALL utils_globals.show_info(SFMT("PO %1 posted.", grn_hdr_rec.doc_no))
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error("Post failed:\n" || SQLCA.SQLERRM)
    END TRY
END FUNCTION

-- =======================
-- Find by doc_no
-- =======================
FUNCTION do_pu_grn_find()
    DEFINE n INTEGER
    PROMPT "Enter PO number: " FOR n
    IF n IS NULL THEN
        RETURN
    END IF
    CALL load_pu_grn(n)
END FUNCTION

-- =======================
-- Load header + lines
-- =======================
FUNCTION load_pu_grn(p_doc INTEGER)
    DEFINE i INTEGER

    INITIALIZE grn_hdr_rec.* TO NULL
    CALL grn_lines_arr.clear()

    SELECT * INTO grn_hdr_rec.* FROM pu31_grn_hdr WHERE doc_no = p_doc
    IF SQLCA.SQLCODE <> 0 THEN
        CALL utils_globals.show_info(SFMT("PO %1 not found.", p_doc))
        RETURN
    END IF

    LET i = 0
    DECLARE c CURSOR FOR
        SELECT * FROM pu31_grn_det WHERE doc_no = p_doc ORDER BY stock_code
    FOREACH c INTO grn_lines_arr[i + 1].*
        LET i = i + 1
    END FOREACH
    FREE c

    DISPLAY BY NAME grn_hdr_rec.*
    -- DISPLAY BY NAME grn_lines_arr.getLength()
    MESSAGE SFMT("PO %1 loaded (%2 line(s)).", p_doc, i)
END FUNCTION

-- =======================
-- Calc helpers
-- =======================
FUNCTION calc_pu_grn_line_total(idx INTEGER)
    IF idx < 1 OR idx > grn_lines_arr.getLength() THEN
        RETURN
    END IF
    IF grn_lines_arr[idx].qnty IS NULL THEN
        LET grn_lines_arr[idx].qnty = 0
    END IF
    IF grn_lines_arr[idx].unit_cost IS NULL THEN
        LET grn_lines_arr[idx].unit_cost = 0
    END IF
    LET grn_lines_arr[idx].line_tot =
        grn_lines_arr[idx].qnty * grn_lines_arr[idx].unit_cost
    CALL recalc_totals()
END FUNCTION

--FUNCTION recalc_pu_grn_totals()
--    DEFINE i INTEGER
--    DEFINE subtotal DECIMAL(15, 2)
--    LET subtotal = 0
--    FOR i = 1 TO grn_lines_arr.getLength()
--        IF grn_lines_arr[i].line_tot IS NOT NULL THEN
--            LET subtotal =
--                subtotal + grn_lines_arr[i].line_tot -- FIX: sum line_tot
--        END IF
--    END FOR
--    LET grn_hdr_rec.gross_tot = subtotal
--    LET grn_hdr_rec.vat = subtotal * 0.15
--    DISPLAY BY NAME grn_hdr_rec.gross_tot, grn_hdr_rec.vat
--END FUNCTION
