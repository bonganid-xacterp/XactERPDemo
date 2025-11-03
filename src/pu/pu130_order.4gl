-- ==============================================================
-- Program   : pu130_order.4gl (simplified)
-- Purpose   : Purchase Order (Header + Lines)
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
TYPE po_hdr_t RECORD LIKE pu30_ord_hdr.*

DEFINE po_hdr_rec po_hdr_t

DEFINE po_lines_arr DYNAMIC ARRAY OF RECORD LIKE pu30_ord_det.*

DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx SMALLINT
DEFINE is_edit SMALLINT

-- =======================
-- MAIN
-- =======================
MAIN
    IF NOT utils_globals.initialize_application() THEN
        DISPLAY "Initialization failed."
        EXIT PROGRAM 1
    END IF
    OPTIONS INPUT WRAP
    OPEN WINDOW w_po WITH FORM "pu130_order" ATTRIBUTES(STYLE = "normal")
    CALL init_po_module()
    CLOSE WINDOW w_po
END MAIN

-- =======================
-- init Module
-- =======================
FUNCTION init_po_module()
    DEFINE row_idx INTEGER

    LET is_edit = FALSE
    INITIALIZE po_hdr_rec.* TO NULL

    CLEAR SCREEN

    INPUT BY NAME po_hdr_rec.*

    DIALOG ATTRIBUTES(UNBUFFERED)

        INPUT BY NAME po_hdr_rec.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "po_header")

            BEFORE FIELD acc_code, trans_date, status
                IF NOT is_edit THEN
                    CALL utils_globals.show_info("Click New or Edit to modify.")
                    NEXT FIELD doc_no
                END IF

            AFTER FIELD trans_date
                IF po_hdr_rec.trans_date IS NULL THEN
                    LET po_hdr_rec.trans_date = TODAY
                    DISPLAY BY NAME po_hdr_rec.trans_date
                END IF

            ON ACTION new ATTRIBUTES(TEXT = "New", IMAGE = "new")
                CALL new_po()
                LET is_edit = TRUE

            ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
                IF po_hdr_rec.doc_no IS NULL OR po_hdr_rec.doc_no = 0 THEN
                    CALL utils_globals.show_info("No PO selected to edit.")
                ELSE
                    IF po_hdr_rec.status <> "draft" THEN
                        CALL utils_globals.show_warning(
                            "Only 'draft' orders can be edited.")
                    ELSE
                        LET is_edit = TRUE
                        MESSAGE "Edit mode enabled."
                    END IF
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Save", IMAGE = "filesave")
                IF is_edit THEN
                    CALL save_po()
                    LET is_edit = FALSE
                END IF

            ON ACTION post ATTRIBUTES(TEXT = "Post", IMAGE = "ok")
                CALL do_post()

            ON ACTION find ATTRIBUTES(TEXT = "Find", IMAGE = "zoom")
                CALL do_find()

            ON ACTION quit ATTRIBUTES(TEXT = "Quit", IMAGE = "quit")
                EXIT DIALOG
        END INPUT

        INPUT ARRAY po_lines_arr
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
FUNCTION new_po()
    DEFINE next_doc INTEGER
    DEFINE ok SMALLINT

    -- Initialize header
    SELECT COALESCE(MAX(doc_no), 0) + 1 INTO next_doc FROM pu30_ord_hdr
    INITIALIZE po_hdr_rec.* TO NULL
    CALL po_lines_arr.clear()

    LET po_hdr_rec.doc_no = next_doc
    LET po_hdr_rec.trans_date = TODAY
    LET po_hdr_rec.status = "draft"
    LET po_hdr_rec.gross_tot = 0
    LET po_hdr_rec.disc = 0
    LET po_hdr_rec.vat = 0
    LET po_hdr_rec.net_tot = 0
    LET po_hdr_rec.created_at = CURRENT
    LET po_hdr_rec.created_by = 1

    -- Input header fields
    INPUT BY NAME po_hdr_rec.*
        WITHOUT DEFAULTS
        ATTRIBUTES(UNBUFFERED, ACCEPT = TRUE, CANCEL = TRUE)

        ON ACTION accept
            -- Validate header
            IF po_hdr_rec.acc_code IS NULL THEN
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
        INSERT INTO pu30_ord_hdr VALUES(po_hdr_rec.*)
        -- Get the generated hdr_id
        LET po_hdr_rec.id = SQLCA.SQLERRD[2]

        COMMIT WORK
        MESSAGE SFMT("PO Header %1 saved. ID=%2. Now add lines.",
            next_doc, po_hdr_rec.id)

        -- Now call function to input lines
        CALL input_po_lines()

    CATCH
        ROLLBACK WORK
        ERROR SFMT("Failed to save PO: %1", SQLCA.sqlawarn)
        RETURN
    END TRY

END FUNCTION

-- input the order lines
--FUNCTION input_po_lines()
--    INPUT ARRAY po_lines_arr FROM scr_lines.*
--        ATTRIBUTES(UNBUFFERED, APPEND ROW=TRUE, DELETE ROW=TRUE)
--
--        BEFORE INSERT
--            LET po_lines_arr[arr_curr()].hdr_id = po_hdr_rec.id
--            LET po_lines_arr[arr_curr()].stock_code = arr_curr()
--
--        ON ACTION save_lines
--            -- Save all lines to database
--            CALL save_po_lines()
--            EXIT INPUT
--
--    END INPUT
--END FUNCTION

-- save the po lines to the database
-- Save PO lines to database
FUNCTION save_po_lines()
    DEFINE i INTEGER
    DEFINE line_rec RECORD LIKE pu30_ord_det.*

    BEGIN WORK
    TRY
        -- First delete existing lines for this header (in case of edit)
        DELETE FROM pu30_ord_det WHERE hdr_id = po_hdr_rec.id

        -- Insert all lines
        FOR i = 1 TO po_lines_arr.getLength()
            IF po_lines_arr[i].stock_code IS NOT NULL THEN
                LET line_rec.* = po_lines_arr[i].*
                LET line_rec.hdr_id = po_hdr_rec.id
                LET line_rec.stock_code = i

                INSERT INTO pu30_ord_det VALUES(line_rec.*)
            END IF
        END FOR

        -- Recalculate header totals
        CALL recalc_po_totals()

        -- Update header with new totals
        UPDATE pu30_ord_hdr
            SET gross_tot = po_hdr_rec.gross_tot,
                disc = po_hdr_rec.disc,
                vat = po_hdr_rec.vat,
                net_tot = po_hdr_rec.net_tot,
                updated_at = CURRENT
            WHERE id = po_hdr_rec.id

        COMMIT WORK
        MESSAGE SFMT("PO lines saved successfully. Total: %1",
            po_hdr_rec.net_tot)

    CATCH
        ROLLBACK WORK
        ERROR SFMT("Failed to save lines: %1", SQLCA.sqlawarn)
    END TRY
END FUNCTION

-- Enhanced input_po_lines with validation
FUNCTION input_po_lines()
    DEFINE item_code STRING
    DEFINE line_tot DECIMAL(15, 2)

    INPUT ARRAY po_lines_arr
        FROM scr_lines.*
        ATTRIBUTES(UNBUFFERED,
            APPEND ROW = TRUE,
            DELETE ROW = TRUE,
            INSERT ROW = TRUE,
            MAXCOUNT = 999)

        BEFORE INSERT
            LET po_lines_arr[arr_curr()].hdr_id = po_hdr_rec.id
            LET po_lines_arr[arr_curr()].stock_code = arr_curr()
            LET po_lines_arr[arr_curr()].qnty = 1
            LET po_lines_arr[arr_curr()].unit_cost = 0
            LET po_lines_arr[arr_curr()].vat = 0
            LET po_lines_arr[arr_curr()].line_tot = 0

        BEFORE FIELD stock_code
            LET curr_idx = arr_curr()

        AFTER FIELD stock_code
            IF po_lines_arr[curr_idx].stock_code IS NOT NULL THEN
                -- Validate item exists
                SELECT description, unit_price
                    INTO item_code, po_lines_arr[curr_idx].unit_cost
                    FROM st10_item
                    WHERE stock_code = po_lines_arr[curr_idx].stock_code

                IF SQLCA.SQLCODE = NOTFOUND THEN
                    ERROR "Item not found"
                    LET po_lines_arr[curr_idx].stock_code = NULL
                    NEXT FIELD stock_code
                ELSE
                    LET po_lines_arr[curr_idx].stock_code = item_code
                    DISPLAY po_lines_arr[curr_idx].id
                        TO po_lines_arr[curr_idx].item_code
                END IF
            END IF

        ON CHANGE qnty, price, disc_pct
            -- Recalculate line amount
            IF po_lines_arr[curr_idx].qnty IS NOT NULL
                AND po_lines_arr[curr_idx].unit_cost IS NOT NULL THEN

                LET line_tot =
                    po_lines_arr[curr_idx].qnty
                        * po_lines_arr[curr_idx].unit_cost

                IF po_lines_arr[curr_idx].disc_pct > 0 THEN
                    LET line_tot =
                        line_tot * (1 - po_lines_arr[curr_idx].disc_pct / 100)
                END IF

                LET po_lines_arr[curr_idx].line_tot = line_tot
                DISPLAY po_lines_arr[curr_idx].line_tot
                    TO scr_lines[curr_idx].line_tot
            END IF

        ON ACTION item_lookup
            CALL lookup_item() RETURNING po_lines_arr[curr_idx].stock_code
            IF po_lines_arr[curr_idx].stock_code IS NOT NULL THEN
                -- Trigger AFTER FIELD logic
                CALL DIALOG.nextField("qnty")
            END IF

        ON ACTION save_lines
            -- Validate at least one line exists
            IF po_lines_arr.getLength() = 0 THEN
                ERROR "Please add at least one line item"
                CONTINUE INPUT
            END IF

            -- Check all lines have required fields
            IF NOT validate_lines() THEN
                CONTINUE INPUT
            END IF

            CALL save_po_lines()
            EXIT INPUT

        ON ACTION cancel
            IF confirm_cancel() THEN
                EXIT INPUT
            END IF

    END INPUT
END FUNCTION

-- Validate all lines
FUNCTION validate_lines()
    DEFINE i INTEGER
    DEFINE is_valid SMALLINT

    LET is_valid = TRUE

    FOR i = 1 TO po_lines_arr.getLength()
        IF po_lines_arr[i].stock_code IS NULL THEN
            ERROR SFMT("Line %1: Item code is required", i)
            LET is_valid = FALSE
            EXIT FOR
        END IF

        IF po_lines_arr[i].qnty IS NULL OR po_lines_arr[i].qnty <= 0 THEN
            ERROR SFMT("Line %1: Quantity must be greater than 0", i)
            LET is_valid = FALSE
            EXIT FOR
        END IF

        IF po_lines_arr[i].sell_price IS NULL
            OR po_lines_arr[i].sell_price < 0 THEN
            ERROR SFMT("Line %1: Price cannot be negative", i)
            LET is_valid = FALSE
            EXIT FOR
        END IF
    END FOR

    RETURN is_valid
END FUNCTION

-- Recalculate header totals from lines
FUNCTION recalc_po_totals()
    DEFINE i INTEGER
    DEFINE gross DECIMAL(15, 2)
    DEFINE disc_amt DECIMAL(15, 2)
    DEFINE vat_amt DECIMAL(15, 2)
    DEFINE vat_rate DECIMAL(5, 2)

    LET gross = 0
    LET vat_rate = 15.00 -- Adjust to your VAT rate

    FOR i = 1 TO po_lines_arr.getLength()
        IF po_lines_arr[i].line_tot IS NOT NULL THEN
            LET gross = gross + po_lines_arr[i].line_tot
        END IF
    END FOR

    LET po_hdr_rec.gross_tot = gross
    LET po_hdr_rec.disc = 0 -- Or calculate if you have header-level discount
    LET vat_amt = (gross - po_hdr_rec.disc) * (vat_rate / 100)
    LET po_hdr_rec.vat = vat_amt
    LET po_hdr_rec.net_tot = gross - po_hdr_rec.disc + vat_amt

    -- Update display
    DISPLAY BY NAME po_hdr_rec.gross_tot,
        po_hdr_rec.disc,
        po_hdr_rec.vat,
        po_hdr_rec.net_tot
END FUNCTION

-- Confirm cancel action
FUNCTION confirm_cancel()
    DEFINE answer STRING

    MENU "Cancel PO Lines"
        ATTRIBUTES(STYLE = "dialog", COMMENT = "Discard unsaved changes?")
        COMMAND "Yes"
            RETURN TRUE
        COMMAND "No"
            RETURN FALSE
    END MENU
END FUNCTION

-- Item lookup helper (optional)
FUNCTION lookup_item()
    DEFINE selected_code STRING
    -- Implement your item lookup window here
    -- OPEN WINDOW w_lookup...
    -- ...selection logic...
    RETURN selected_code
END FUNCTION

-- =======================
-- Save (insert/update)
-- =======================
FUNCTION save_po()
    DEFINE exists_cnt INTEGER
    DEFINE i INTEGER

    -- Basic validation
    IF po_hdr_rec.acc_code IS NULL THEN
        CALL utils_globals.show_warning("Please select a supplier (acc_code).")
        RETURN
    END IF
    IF po_lines_arr.getLength() = 0 THEN
        CALL utils_globals.show_warning("Please add at least one line.")
        RETURN
    END IF

    -- Final totals
    CALL recalc_totals()

    BEGIN WORK
    TRY
        SELECT COUNT(*)
            INTO exists_cnt
            FROM pu30_ord_hdr
            WHERE doc_no = po_hdr_rec.doc_no

        IF exists_cnt = 0 THEN
            INSERT INTO pu30_ord_hdr VALUES po_hdr_rec.*
        ELSE
            LET po_hdr_rec.updated_at = CURRENT
            UPDATE pu30_ord_hdr
                SET pu30_ord_hdr.* = po_hdr_rec.*
                WHERE doc_no = po_hdr_rec.doc_no
        END IF

        DELETE FROM pu30_ord_det WHERE doc_no = po_hdr_rec.doc_no

        FOR i = 1 TO po_lines_arr.getLength()
            IF po_lines_arr[i].stock_code IS NOT NULL THEN
                -- Ensure doc_no and stock_code are correct
                LET po_lines_arr[i].hdr_id = po_hdr_rec.doc_no
                IF po_lines_arr[i].stock_code IS NULL
                    OR po_lines_arr[i].stock_code = 0 THEN
                    LET po_lines_arr[i].stock_code = i
                END IF
                CALL calc_line_total(i)
                INSERT INTO pu30_ord_det VALUES po_lines_arr[i].*
            END IF
        END FOR

        COMMIT WORK
        CALL utils_globals.show_info(SFMT("PO %1 saved.", po_hdr_rec.doc_no))
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error("Save failed:\n" || SQLCA.SQLERRM)
    END TRY
END FUNCTION

-- =======================
-- Post (mark posted + update stock_on_order)
-- =======================
FUNCTION do_post()
    DEFINE i INTEGER
    DEFINE answer STRING

    IF po_hdr_rec.doc_no IS NULL THEN
        CALL utils_globals.show_info("No PO selected.")
        RETURN
    END IF
    IF po_hdr_rec.status <> "draft" THEN
        CALL utils_globals.show_warning("This order is already posted.")
        RETURN
    END IF
    IF po_lines_arr.getLength() = 0 THEN
        CALL utils_globals.show_warning("Cannot post an empty order.")
        RETURN
    END IF

    PROMPT "Post this PO? (yes/no) " FOR answer
    IF answer <> "yes" THEN
        RETURN
    END IF

    BEGIN WORK
    TRY
        FOR i = 1 TO po_lines_arr.getLength()
            IF po_lines_arr[i].stock_code IS NOT NULL THEN
                UPDATE st01_mast
                    SET stock_on_order
                        = stock_on_order + COALESCE(po_lines_arr[i].qnty, 0)
                    WHERE stock_code = po_lines_arr[i].stock_code
            END IF
        END FOR

        UPDATE pu30_ord_hdr
            SET status = "posted", updated_at = CURRENT
            WHERE doc_no = po_hdr_rec.doc_no

        LET po_hdr_rec.status = "posted"
        DISPLAY BY NAME po_hdr_rec.status

        COMMIT WORK
        CALL utils_globals.show_info(SFMT("PO %1 posted.", po_hdr_rec.doc_no))
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error("Post failed:\n" || SQLCA.SQLERRM)
    END TRY
END FUNCTION

-- =======================
-- Find by doc_no
-- =======================
FUNCTION do_find()
    DEFINE n INTEGER
    PROMPT "Enter PO number: " FOR n
    IF n IS NULL THEN
        RETURN
    END IF
    CALL load_po(n)
END FUNCTION

-- =======================
-- Load header + lines
-- =======================
FUNCTION load_po(p_doc INTEGER)
    DEFINE i INTEGER

    INITIALIZE po_hdr_rec.* TO NULL
    CALL po_lines_arr.clear()

    SELECT * INTO po_hdr_rec.* FROM pu30_ord_hdr WHERE doc_no = p_doc
    IF SQLCA.SQLCODE <> 0 THEN
        CALL utils_globals.show_info(SFMT("PO %1 not found.", p_doc))
        RETURN
    END IF

    LET i = 0
    DECLARE c CURSOR FOR
        SELECT * FROM pu30_ord_det WHERE doc_no = p_doc ORDER BY stock_code
    FOREACH c INTO po_lines_arr[i + 1].*
        LET i = i + 1
    END FOREACH
    FREE c

    DISPLAY BY NAME po_hdr_rec.*
    -- DISPLAY BY NAME po_lines_arr.getLength()
    MESSAGE SFMT("PO %1 loaded (%2 line(s)).", p_doc, i)
END FUNCTION


-- =======================
-- Load PO header + lines 
-- =======================
FUNCTION load_po_via_cred(p_doc INTEGER)
    DEFINE i INTEGER

    INITIALIZE po_hdr_rec.* TO NULL
    CALL po_lines_arr.clear()

    SELECT * INTO po_hdr_rec.* FROM pu30_ord_hdr WHERE doc_no = p_doc
    IF SQLCA.SQLCODE <> 0 THEN
        CALL utils_globals.show_info(SFMT("PO %1 not found.", p_doc))
        RETURN
    END IF

    LET i = 0
    DECLARE c CURSOR FOR
        SELECT * FROM pu30_ord_det WHERE doc_no = p_doc ORDER BY stock_code
    FOREACH c INTO po_lines_arr[i + 1].*
        LET i = i + 1
    END FOREACH
    FREE c

    DISPLAY BY NAME po_hdr_rec.*
    -- DISPLAY BY NAME po_lines_arr.getLength()
    MESSAGE SFMT("PO %1 loaded (%2 line(s)).", p_doc, i)
END FUNCTION


-- =======================
-- Calc helpers
-- =======================
FUNCTION calc_line_total(idx INTEGER)
    IF idx < 1 OR idx > po_lines_arr.getLength() THEN
        RETURN
    END IF
    IF po_lines_arr[idx].qnty IS NULL THEN
        LET po_lines_arr[idx].qnty = 0
    END IF
    IF po_lines_arr[idx].unit_cost IS NULL THEN
        LET po_lines_arr[idx].unit_cost = 0
    END IF
    LET po_lines_arr[idx].line_tot =
        po_lines_arr[idx].qnty * po_lines_arr[idx].unit_cost
    CALL recalc_totals()
END FUNCTION

FUNCTION recalc_totals()
    DEFINE i INTEGER
    DEFINE subtotal DECIMAL(15, 2)
    LET subtotal = 0
    FOR i = 1 TO po_lines_arr.getLength()
        IF po_lines_arr[i].line_tot IS NOT NULL THEN
            LET subtotal =
                subtotal + po_lines_arr[i].line_tot -- FIX: sum line_tot
        END IF
    END FOR
    LET po_hdr_rec.gross_tot = subtotal
    LET po_hdr_rec.vat = subtotal * 0.15
    DISPLAY BY NAME po_hdr_rec.gross_tot, po_hdr_rec.vat
END FUNCTION
