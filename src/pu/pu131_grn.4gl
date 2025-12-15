-- ==============================================================
-- Program   : pu131_grn.4gl
-- Purpose   : Good Received Note (Header + Lines)
-- Module    : Purchases (pu)
-- Author    : Bongani Dlamini
-- Version   : Genero 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL cl121_lkup
IMPORT FGL st121_st_lkup

SCHEMA demoappdb

-- =======================
-- Types / Globals
-- =======================
TYPE grn_hdr_t RECORD LIKE pu31_grn_hdr.*

DEFINE m_grn_hdr_rec grn_hdr_t
DEFINE m_grn_lines_arr DYNAMIC ARRAY OF RECORD LIKE pu31_grn_det.*

--DEFINE arr_codes DYNAMIC ARRAY OF STRING
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
--
--    OPTIONS INPUT WRAP
--    OPEN WINDOW w_pu_grn WITH FORM "pu131_grn" -- ATTRIBUTES(STYLE = "normal")
--
--    CALL init_grn_module()
--
--    CLOSE WINDOW w_pu_grn
--END MAIN

-- =======================
-- init Module
-- =======================
FUNCTION init_grn_module()
    DEFINE row_idx INTEGER
    DEFINE chosen_rec INTEGER
    DEFINE ok SMALLINT

    LET is_edit = FALSE
    INITIALIZE m_grn_hdr_rec.* TO NULL

    DIALOG ATTRIBUTES(UNBUFFERED)

        -- HEADER FIELDS
        INPUT BY NAME m_grn_hdr_rec.* 
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "grn_header")

            BEFORE FIELD id, trans_date, status
                IF NOT is_edit THEN
                    CALL utils_globals.show_info("Click New or Edit to modify.")
                    NEXT FIELD doc_no
                END IF

            AFTER FIELD trans_date
                IF m_grn_hdr_rec.trans_date IS NULL THEN
                    LET m_grn_hdr_rec.trans_date = TODAY
                    DISPLAY BY NAME m_grn_hdr_rec.trans_date
                END IF

            ON ACTION new
                CALL new_pu_grn()
                LET is_edit = TRUE

            ON ACTION edit
                IF m_grn_hdr_rec.doc_no IS NULL OR m_grn_hdr_rec.doc_no = 0 THEN
                    CALL utils_globals.show_info("No GRN selected.")
                ELSE
                    LET is_edit = TRUE
                    MESSAGE "Edit mode enabled."
                END IF

            ON ACTION save
                IF is_edit THEN
                    CALL save_pu_grn()
                    LET is_edit = FALSE
                END IF

            ON ACTION find
                TRY
                    LET chosen_rec = lookup_posted_po()
                    IF chosen_rec IS NOT NULL THEN
                        LET ok = converted_po_into_grn(chosen_rec)
                        IF ok THEN
                            MESSAGE "PO loaded into GRN successfully."
                        ELSE
                            CALL utils_globals.show_warning("Failed to load GRN from PO.")
                        END IF
                    END IF
                CATCH
                    CALL utils_globals.show_error("Find PO failed: " || STATUS)
                END TRY

            ON ACTION quit
                EXIT DIALOG
        END INPUT


        -- LINE ARRAY
        INPUT ARRAY m_grn_lines_arr FROM grn_lines_arr.*
            ATTRIBUTES(INSERT ROW=TRUE, DELETE ROW=TRUE, APPEND ROW=TRUE)

            BEFORE INPUT
                IF NOT is_edit THEN
                    CALL utils_globals.show_info("Switch to New/Edit to change lines.")
                    NEXT FIELD FIRST
                END IF

            BEFORE ROW
                LET row_idx = arr_curr()

            AFTER FIELD qnty, unit_cost
                CALL calc_pu_grn_line_total(row_idx)

        END INPUT

    END DIALOG
END FUNCTION


-- ===============================================
-- PO Lookup - Display posted POs
-- ===============================================
FUNCTION lookup_posted_po() RETURNS INTEGER
    DEFINE selected_po_id INTEGER
    DEFINE idx INTEGER
    DEFINE dlg ui.Dialog
    DEFINE sel INTEGER

    DEFINE
        po_arr DYNAMIC ARRAY OF RECORD
            id LIKE pu30_ord_hdr.id,
            doc_no LIKE pu30_ord_hdr.doc_no,
            trans_date LIKE pu30_ord_hdr.trans_date,
            supp_name LIKE pu30_ord_hdr.supp_name,
            net_tot LIKE pu30_ord_hdr.net_tot,
            status LIKE pu30_ord_hdr.status
        END RECORD,

        po_rec RECORD
            id LIKE pu30_ord_hdr.id,
            doc_no LIKE pu30_ord_hdr.doc_no,
            trans_date LIKE pu30_ord_hdr.trans_date,
            supp_name LIKE pu30_ord_hdr.supp_name,
            net_tot LIKE pu30_ord_hdr.net_tot,
            status LIKE pu30_ord_hdr.status
        END RECORD

    LET idx = 0
    LET selected_po_id = NULL

    OPEN WINDOW w_po_lkup WITH FORM "cl121_lkup" ATTRIBUTES(STYLE = "dialog")

    -- Load posted POs only
    TRY
        DECLARE po_curs CURSOR FOR
            SELECT id, doc_no, trans_date, supp_name, net_tot, status
                FROM pu30_ord_hdr
                WHERE status = 'posted'
                ORDER BY doc_no DESC

        CALL po_arr.clear()

        FOREACH po_curs INTO po_rec.*
            LET idx = idx + 1
            LET po_arr[idx].* = po_rec.*
        END FOREACH
    CATCH
        CALL utils_globals.show_error("PO lookup failed: " || STATUS)
    END TRY

    -- Show array only if records exist
    IF idx > 0 THEN
        DIALOG ATTRIBUTES(UNBUFFERED)
            DISPLAY ARRAY po_arr TO r_creditors_list.* ATTRIBUTES(COUNT = idx)

                BEFORE DISPLAY
                    LET dlg = ui.Dialog.getCurrent()
                    IF po_arr.getLength() > 0 THEN
                        CALL dlg.setCurrentRow("r_creditors_list", 1)
                    END IF

                ON ACTION accept
                    LET sel = dlg.getCurrentRow("r_creditors_list")
                    IF sel > 0 AND sel <= po_arr.getLength() THEN
                        LET selected_po_id = po_arr[sel].id
                    END IF
                    EXIT DIALOG

                ON ACTION cancel
                    LET selected_po_id = NULL
                    EXIT DIALOG

                ON KEY(RETURN)
                    LET sel = dlg.getCurrentRow("r_creditors_list")
                    IF sel > 0 AND sel <= po_arr.getLength() THEN
                        LET selected_po_id = po_arr[sel].id
                    END IF
                    EXIT DIALOG

                ON KEY(ESCAPE)
                    LET selected_po_id = NULL
                    EXIT DIALOG
            END DISPLAY
        END DIALOG
    ELSE
        CALL utils_globals.show_info("No posted purchase orders found.")
    END IF

    CLOSE WINDOW w_po_lkup
    RETURN selected_po_id
END FUNCTION

-- ==================================================
-- Convert PO data into GRN
-- ==================================================
FUNCTION converted_po_into_grn(p_po_id INTEGER) RETURNS SMALLINT
    DEFINE l_po_hdr_rec RECORD LIKE pu30_ord_hdr.*
    DEFINE l_po_line_arr RECORD LIKE pu30_ord_det.*
    DEFINE i INTEGER
    DEFINE next_grn_doc INTEGER

    -- Load creditor data and transaction info
    SELECT * INTO l_po_hdr_rec.* FROM pu30_ord_hdr WHERE id = p_po_id
    SELECT * INTO l_po_line_arr.* FROM pu30_ord_det WHERE hdr_id = p_po_id

    TRY
        SELECT COALESCE(MAX(id), 0) + 1 INTO next_grn_doc FROM pu31_grn_hdr

    -- Load PO header
    SELECT * INTO l_po_hdr_rec.* FROM pu30_ord_hdr WHERE id = p_po_id

    IF SQLCA.SQLCODE <> 0 THEN
        CALL utils_globals.show_error("Purchase Order not found.")
        RETURN FALSE
    END IF

    -- Check if PO is posted
    IF l_po_hdr_rec.status <> "posted" THEN
        CALL utils_globals.show_warning("Only posted POs can be receipted.")
        RETURN FALSE
    END IF

    -- Initialize GRN header from PO
    INITIALIZE m_grn_hdr_rec.* TO NULL

    LET m_grn_hdr_rec.id = next_grn_doc
    LET m_grn_hdr_rec.doc_no = next_grn_doc
    LET m_grn_hdr_rec.ref_doc_type = "PO"
    LET m_grn_hdr_rec.ref_doc_no = l_po_hdr_rec.doc_no
    LET m_grn_hdr_rec.trans_date = TODAY
    LET m_grn_hdr_rec.supp_id = l_po_hdr_rec.supp_id
    LET m_grn_hdr_rec.supp_name = l_po_hdr_rec.supp_name
    LET m_grn_hdr_rec.supp_phone = l_po_hdr_rec.supp_phone
    LET m_grn_hdr_rec.supp_email = l_po_hdr_rec.supp_email
    LET m_grn_hdr_rec.supp_address1 = l_po_hdr_rec.supp_address1
    LET m_grn_hdr_rec.supp_address2 = l_po_hdr_rec.supp_address2
    LET m_grn_hdr_rec.supp_address3 = l_po_hdr_rec.supp_address3
    LET m_grn_hdr_rec.supp_postal_code = l_po_hdr_rec.supp_postal_code
    LET m_grn_hdr_rec.supp_vat_no = l_po_hdr_rec.supp_vat_no
    LET m_grn_hdr_rec.supp_payment_terms = l_po_hdr_rec.supp_payment_terms
    LET m_grn_hdr_rec.gross_tot = l_po_hdr_rec.gross_tot
    LET m_grn_hdr_rec.vat_tot = l_po_hdr_rec.vat_tot
    LET m_grn_hdr_rec.net_tot = l_po_hdr_rec.net_tot
    LET m_grn_hdr_rec.status = "draft"
    LET m_grn_hdr_rec.created_at = CURRENT
    LET m_grn_hdr_rec.created_by = utils_globals.get_current_user_id()

    -- Display header
    DISPLAY BY NAME m_grn_hdr_rec.*

    -- Load PO lines into GRN array
    CALL m_grn_lines_arr.clear()
    LET i = 0

    DECLARE po_lines_curs CURSOR FOR
        SELECT * FROM pu30_ord_det WHERE hdr_id = p_po_id ORDER BY line_no

    FOREACH po_lines_curs INTO l_po_line_arr.*
        LET i = i + 1

        -- Initialize GRN line from PO line
        INITIALIZE m_grn_lines_arr[i].* TO NULL

        LET m_grn_lines_arr[i].line_no = i
        LET m_grn_lines_arr[i].stock_id = l_po_line_arr.stock_id
        LET m_grn_lines_arr[i].item_name = l_po_line_arr.item_name
        LET m_grn_lines_arr[i].uom = l_po_line_arr.uom
        LET m_grn_lines_arr[i].qnty = l_po_line_arr.qnty
        LET m_grn_lines_arr[i].unit_cost = l_po_line_arr.unit_cost
        LET m_grn_lines_arr[i].disc_pct = l_po_line_arr.disc_pct
        LET m_grn_lines_arr[i].disc_amt = l_po_line_arr.disc_amt
        LET m_grn_lines_arr[i].gross_amt = l_po_line_arr.gross_amt
        LET m_grn_lines_arr[i].vat_rate = l_po_line_arr.vat_rate
        LET m_grn_lines_arr[i].vat_amt = l_po_line_arr.vat_amt
        LET m_grn_lines_arr[i].net_excl_amt = l_po_line_arr.net_excl_amt
        LET m_grn_lines_arr[i].line_total = l_po_line_arr.line_total
        LET m_grn_lines_arr[i].po_line_id = l_po_line_arr.id
        LET m_grn_lines_arr[i].wh_id = ""
        LET m_grn_lines_arr[i].wb_id = ""
        LET m_grn_lines_arr[i].status = "active"
        LET m_grn_lines_arr[i].created_at = CURRENT
        LET m_grn_lines_arr[i].created_by = 1
    END FOREACH

    -- Recalculate totals
    CALL recalc_pu_grn_totals()

    MESSAGE SFMT("PO %1 loaded with %2 line(s). Reference: %3",
        l_po_hdr_rec.doc_no, i, l_po_hdr_rec.doc_no)
        RETURN TRUE 
CATCH
    CALL utils_globals.show_error("Load PO into GRN failed: " || STATUS)
    RETURN FALSE
END TRY
END FUNCTION

-- =======================
-- New Purchase Order
-- =======================
FUNCTION new_pu_grn()
    DEFINE next_doc INTEGER
    DEFINE ok SMALLINT

    -- Initialize header
    LET next_doc = utils_globals.get_next_code('pu31_grn_hdr', 'id')

    INITIALIZE m_grn_hdr_rec.* TO NULL

    CALL m_grn_lines_arr.clear()

    LET m_grn_hdr_rec.doc_no = next_doc
    LET m_grn_hdr_rec.trans_date = TODAY
    LET m_grn_hdr_rec.status = "draft"
    LET m_grn_hdr_rec.gross_tot = 0
    LET m_grn_hdr_rec.vat_tot = 0
    LET m_grn_hdr_rec.net_tot = 0
    LET m_grn_hdr_rec.created_at = CURRENT
    LET m_grn_hdr_rec.created_by = utils_globals.get_current_user_id()

    -- Input header fields
    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME m_grn_hdr_rec.* ATTRIBUTES(WITHOUT DEFAULTS)

            ON ACTION accept
                IF m_grn_hdr_rec.supp_id IS NULL OR m_grn_hdr_rec.supp_id = 0 THEN
                    ERROR "Supplier is required"
                    NEXT FIELD supp_id
                END IF

            ON ACTION cancel
                LET ok = FALSE
        END INPUT
    END DIALOG

    IF INT_FLAG THEN
        LET INT_FLAG = FALSE
        RETURN
    END IF

    -- Save header to database
    BEGIN WORK
    TRY
        INSERT INTO pu31_grn_hdr VALUES(m_grn_hdr_rec.*)
        -- Get the generated hdr_id
        LET m_grn_hdr_rec.id = SQLCA.SQLERRD[2]

        COMMIT WORK
        MESSAGE SFMT("GRN Header %1 saved. ID=%2. Now add lines.",
            next_doc, m_grn_hdr_rec.id)

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
--    INPUT ARRAY m_grn_lines_arr FROM scr_lines.*
--        ATTRIBUTES(UNBUFFERED, APPEND ROW=TRUE, DELETE ROW=TRUE)
--
--        BEFORE INSERT
--            LET m_grn_lines_arr[arr_curr()].hdr_id = m_grn_hdr_rec.id
--            LET m_grn_lines_arr[arr_curr()].stock_id = arr_curr()
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
        DELETE FROM pu31_grn_det WHERE hdr_id = m_grn_hdr_rec.id

        -- Insert all lines
        FOR i = 1 TO m_grn_lines_arr.getLength()
            IF m_grn_lines_arr[i].stock_id IS NOT NULL THEN
                LET line_rec.* = m_grn_lines_arr[i].*
                LET line_rec.hdr_id = m_grn_hdr_rec.id
                LET line_rec.stock_id = m_grn_lines_arr[i].stock_id

                INSERT INTO pu31_grn_det VALUES(line_rec.*)
            END IF
        END FOR

        -- Recalculate header totals
        CALL recalc_pu_grn_totals()

        -- Update header with new totals
        UPDATE pu31_grn_hdr
            SET gross_tot = m_grn_hdr_rec.gross_tot,
                vat_tot = m_grn_hdr_rec.vat_tot,
                net_tot = m_grn_hdr_rec.net_tot,
                updated_at = CURRENT
            WHERE id = m_grn_hdr_rec.id

        COMMIT WORK
        MESSAGE SFMT("PO lines saved successfully. Total: %1",
            m_grn_hdr_rec.net_tot)

    CATCH
        ROLLBACK WORK
        ERROR SFMT("Failed to save lines: %1", SQLCA.sqlawarn)
    END TRY
END FUNCTION

-- Enhanced input_pu_grn_lines with validation
FUNCTION input_pu_grn_lines()
    DEFINE item_code STRING
    DEFINE line_total DECIMAL(15, 2)

    INPUT ARRAY m_grn_lines_arr
        FROM scr_lines.*
        ATTRIBUTES(UNBUFFERED,
            APPEND ROW = TRUE,
            DELETE ROW = TRUE,
            INSERT ROW = TRUE,
            MAXCOUNT = 999)

        BEFORE INSERT
            LET m_grn_lines_arr[arr_curr()].hdr_id = m_grn_hdr_rec.id
            LET m_grn_lines_arr[arr_curr()].stock_id = arr_curr()
            LET m_grn_lines_arr[arr_curr()].qnty = 1
            LET m_grn_lines_arr[arr_curr()].unit_cost = 0
            LET m_grn_lines_arr[arr_curr()].vat_amt = 0
            LET m_grn_lines_arr[arr_curr()].line_total = 0

        BEFORE FIELD stock_id
            LET curr_idx = arr_curr()

        AFTER FIELD stock_id
            IF m_grn_lines_arr[curr_idx].stock_id IS NOT NULL THEN
                -- Validate item exists
                TRY
                    SELECT description, unit_price
                        INTO item_code, m_grn_lines_arr[curr_idx].unit_cost
                        FROM st10_item
                        WHERE stock_id = m_grn_lines_arr[curr_idx].stock_id
                CATCH
                    ERROR "Item lookup failed"
                    NEXT FIELD stock_id
                END TRY

                IF SQLCA.SQLCODE = NOTFOUND THEN
                    ERROR "Item not found"
                    LET m_grn_lines_arr[curr_idx].stock_id = NULL
                    NEXT FIELD stock_id
                ELSE
                    LET m_grn_lines_arr[curr_idx].stock_id = item_code
                    DISPLAY m_grn_lines_arr[curr_idx].id
                        TO m_grn_lines_arr[curr_idx].item_code
                END IF
            END IF

        ON CHANGE qnty, price
            -- Recalculate line amount
            IF m_grn_lines_arr[curr_idx].qnty IS NOT NULL
                AND m_grn_lines_arr[curr_idx].unit_cost IS NOT NULL THEN

                LET line_total =
                    m_grn_lines_arr[curr_idx].qnty
                        * m_grn_lines_arr[curr_idx].unit_cost

                --IF m_grn_lines_arr[curr_idx].disc_pct > 0 THEN
                --    LET line_total =
                --        line_total * (1 - m_grn_lines_arr[curr_idx].disc_pct / 100)
                --END IF

                LET m_grn_lines_arr[curr_idx].line_total = line_total
                DISPLAY m_grn_lines_arr[curr_idx].line_total
                    TO scr_lines[curr_idx].line_total
            END IF

        ON ACTION item_lookup
            -- CALL lookup_item() RETURNING m_grn_lines_arr[curr_idx].stock_id
            IF m_grn_lines_arr[curr_idx].stock_id IS NOT NULL THEN
                -- Trigger AFTER FIELD logic
                CALL DIALOG.nextField("qnty")
            END IF

        ON ACTION save_lines
            -- Validate at least one line exists
            IF m_grn_lines_arr.getLength() = 0 THEN
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
            EXIT INPUT

    END INPUT
END FUNCTION

-- Validate all lines
FUNCTION validate_pu_grn_lines()
    DEFINE i INTEGER
    DEFINE is_valid SMALLINT

    LET is_valid = TRUE

    FOR i = 1 TO m_grn_lines_arr.getLength()
        IF m_grn_lines_arr[i].stock_id IS NULL THEN
            ERROR SFMT("Line %1: Item code is required", i)
            LET is_valid = FALSE
            EXIT FOR
        END IF

        IF m_grn_lines_arr[i].qnty IS NULL OR m_grn_lines_arr[i].qnty <= 0 THEN
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
    LET vat_rate = 15.00 -- Adjust to your vat_tot rate

    FOR i = 1 TO m_grn_lines_arr.getLength()
        IF m_grn_lines_arr[i].line_total IS NOT NULL THEN
            LET gross = gross + m_grn_lines_arr[i].line_total
        END IF
    END FOR

    LET m_grn_hdr_rec.gross_tot = gross
    LET vat_amt = gross * (vat_rate / 100)
    LET m_grn_hdr_rec.vat_tot = vat_amt
    LET m_grn_hdr_rec.net_tot = gross + vat_amt

    -- Update display
    DISPLAY BY NAME m_grn_hdr_rec.gross_tot,
        m_grn_hdr_rec.vat_tot,
        m_grn_hdr_rec.net_tot
END FUNCTION

-- Confirm cancel action
--FUNCTION confirm_pu_grn_cancel()
--
--    MENU "Cancel PO Lines"
--        ATTRIBUTES(STYLE = "dialog", COMMENT = "Discard unsaved changes?")
--        COMMAND "Yes"
--            RETURN TRUE
--        COMMAND "No"
--            RETURN FALSE
--    END MENU
--
--END FUNCTION

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
    IF m_grn_hdr_rec.id IS NULL THEN
        CALL utils_globals.show_warning("Please select a supplier (id).")
        RETURN
    END IF
    IF m_grn_lines_arr.getLength() = 0 THEN
        CALL utils_globals.show_warning("Please add at least one line.")
        RETURN
    END IF

    -- Final totals
    --CALL recalc_totals()

    BEGIN WORK
    TRY
        SELECT COUNT(*)
            INTO exists_cnt
            FROM pu31_grn_hdr
            WHERE doc_no = m_grn_hdr_rec.doc_no

        IF exists_cnt = 0 THEN
            INSERT INTO pu31_grn_hdr VALUES m_grn_hdr_rec.*
        ELSE
            LET m_grn_hdr_rec.updated_at = CURRENT
            UPDATE pu31_grn_hdr
                SET pu31_grn_hdr.* = m_grn_hdr_rec.*
                WHERE doc_no = m_grn_hdr_rec.doc_no
        END IF

        DELETE FROM pu31_grn_det WHERE doc_no = m_grn_hdr_rec.doc_no

        FOR i = 1 TO m_grn_lines_arr.getLength()
            IF m_grn_lines_arr[i].stock_id IS NOT NULL THEN
                -- Ensure doc_no and stock_id are correct
                LET m_grn_lines_arr[i].hdr_id = m_grn_hdr_rec.doc_no
                IF m_grn_lines_arr[i].stock_id IS NULL
                    OR m_grn_lines_arr[i].stock_id = 0 THEN
                    LET m_grn_lines_arr[i].stock_id = i
                END IF
                --CALL calc_line_total(i)
                INSERT INTO pu31_grn_det VALUES m_grn_lines_arr[i].*
            END IF
        END FOR

        COMMIT WORK
        CALL utils_globals.show_info(SFMT("PO %1 saved.", m_grn_hdr_rec.doc_no))
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

    IF m_grn_hdr_rec.doc_no IS NULL THEN
        CALL utils_globals.show_info("No PO selected.")
        RETURN
    END IF
    IF m_grn_hdr_rec.status <> "draft" THEN
        CALL utils_globals.show_warning("This order is already posted.")
        RETURN
    END IF
    IF m_grn_lines_arr.getLength() = 0 THEN
        CALL utils_globals.show_warning("Cannot post an empty order.")
        RETURN
    END IF

    PROMPT "Post this PO? (yes/no) " FOR answer
    IF answer <> "yes" THEN
        RETURN
    END IF

    BEGIN WORK
    TRY
        FOR i = 1 TO m_grn_lines_arr.getLength()
            IF m_grn_lines_arr[i].stock_id IS NOT NULL THEN
                UPDATE st01_mast
                    SET stock_on_order
                        = stock_on_order + COALESCE(m_grn_lines_arr[i].qnty, 0)
                    WHERE stock_id = m_grn_lines_arr[i].stock_id
            END IF
        END FOR

        UPDATE pu31_grn_hdr
            SET status = "posted", updated_at = CURRENT
            WHERE doc_no = m_grn_hdr_rec.doc_no

        LET m_grn_hdr_rec.status = "posted"
        DISPLAY BY NAME m_grn_hdr_rec.status

        COMMIT WORK
        CALL utils_globals.show_info(SFMT("PO %1 posted.", m_grn_hdr_rec.doc_no))
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

    INITIALIZE m_grn_hdr_rec.* TO NULL
    CALL m_grn_lines_arr.clear()

    SELECT * INTO m_grn_hdr_rec.* FROM pu31_grn_hdr WHERE doc_no = p_doc
    IF SQLCA.SQLCODE <> 0 THEN
        CALL utils_globals.show_info(SFMT("PO %1 not found.", p_doc))
        RETURN
    END IF

    LET i = 0
    DECLARE c CURSOR FOR
        SELECT * FROM pu31_grn_det WHERE doc_no = p_doc ORDER BY stock_id
    FOREACH c INTO m_grn_lines_arr[i + 1].*
        LET i = i + 1
    END FOREACH
    FREE c

    DISPLAY BY NAME m_grn_hdr_rec.*
    -- DISPLAY BY NAME m_grn_lines_arr.getLength()
    MESSAGE SFMT("PO %1 loaded (%2 line(s)).", p_doc, i)
END FUNCTION

-- =======================
-- Calc helpers
-- =======================
FUNCTION calc_pu_grn_line_total(idx INTEGER)
    IF idx < 1 OR idx > m_grn_lines_arr.getLength() THEN
        RETURN
    END IF
    IF m_grn_lines_arr[idx].qnty IS NULL THEN
        LET m_grn_lines_arr[idx].qnty = 0
    END IF
    IF m_grn_lines_arr[idx].unit_cost IS NULL THEN
        LET m_grn_lines_arr[idx].unit_cost = 0
    END IF
    LET m_grn_lines_arr[idx].line_total =
        m_grn_lines_arr[idx].qnty * m_grn_lines_arr[idx].unit_cost
    -- CALL recalc_totals()
END FUNCTION

--FUNCTION recalc_pu_grn_totals()
--    DEFINE i INTEGER
--    DEFINE subtotal DECIMAL(15, 2)
--    LET subtotal = 0
--    FOR i = 1 TO m_grn_lines_arr.getLength()
--        IF m_grn_lines_arr[i].line_total IS NOT NULL THEN
--            LET subtotal =
--                subtotal + m_grn_lines_arr[i].line_total -- FIX: sum line_total
--        END IF
--    END FOR
--    LET m_grn_hdr_rec.gross_tot = subtotal
--    LET m_grn_hdr_rec.vat_tot = subtotal * 0.15
--    DISPLAY BY NAME m_grn_hdr_rec.gross_tot, m_grn_hdr_rec.vat_tot
--END FUNCTION
