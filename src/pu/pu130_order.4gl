-- ==============================================================
-- Program   : pu130_order.4gl (Slim CRUD Header-Only)
-- Purpose   : Purchase Order Header CRUD + Navigate
-- Module    : Purchases (pu)
-- Author    : Bongani Dlamini
-- Version   : Genero 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL st121_st_lkup
IMPORT FGL pu_lkup_form

SCHEMA demoappdb

GLOBALS
    DEFINE g_hdr_saved SMALLINT
END GLOBALS

-- ==============================================================
-- Record Definitions
-- ==============================================================
TYPE po_hdr_t RECORD LIKE pu30_ord_hdr.*
TYPE po_det_t DYNAMIC ARRAY OF RECORD LIKE pu30_ord_det.*
TYPE cred_t RECORD LIKE cl01_mast.*

DEFINE m_po_hdr_rec po_hdr_t
DEFINE m_po_lines_arr po_det_t
DEFINE m_crd_rec cred_t

DEFINE arr_codes DYNAMIC ARRAY OF STRING -- doc id list for navigation
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
    OPEN WINDOW w_pu_order
        WITH
        FORM "pu130_order" -- ATTRIBUTES(STYLE = "normal")

    CALL init_po_module()

    CLOSE WINDOW w_pu_order
END MAIN

-- ==============================================================
-- Controller: minimal dialog with CRUD + navigate
-- ==============================================================
FUNCTION init_po_module()
    LET is_edit = FALSE
    INITIALIZE m_po_hdr_rec.* TO NULL

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME m_po_hdr_rec.doc_no,
            m_po_hdr_rec.trans_date,
            m_po_hdr_rec.supp_id,
            m_po_hdr_rec.status
            ATTRIBUTES(WITHOUT DEFAULTS)

            BEFORE FIELD doc_no, trans_date, supp_id, status
                IF NOT is_edit THEN
                    NEXT FIELD CURRENT
                END IF
        END INPUT

        ON ACTION new ATTRIBUTES(TEXT = "New", IMAGE = "new")
            CALL new_po()
            LET is_edit = TRUE
            NEXT FIELD supp_id

        ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
            IF m_po_hdr_rec.id IS NULL THEN
                CALL utils_globals.show_info("Load a record first.")
            ELSE
                LET is_edit = TRUE
                NEXT FIELD supp_id
            END IF

        ON ACTION delete ATTRIBUTES(TEXT = "Delete", IMAGE = "delete")
            CALL delete_po()

        ON ACTION find ATTRIBUTES(TEXT = "Find", IMAGE = "zoom")
            CALL find_po()

        ON ACTION PREVIOUS
            CALL move_record(-1)

        ON ACTION Next
            CALL move_record(1)

        ON ACTION quit ATTRIBUTES(TEXT = "Quit", IMAGE = "quit")
            EXIT DIALOG
    END DIALOG
END FUNCTION

FUNCTION run_po_dialog()
    DEFINE row_idx INTEGER
    --DEFINE sel_code STRING

    -- If the record already has an id, treat header as "saved"
    LET g_hdr_saved = (m_po_hdr_rec.id IS NOT NULL)

    DIALOG ATTRIBUTES(UNBUFFERED)

        -----------------------------------------------------------------
        -- HEADER BLOCK
        -----------------------------------------------------------------
        INPUT BY NAME m_po_hdr_rec.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "po_header")

            BEFORE INPUT
                -- You could add logic here to disable some fields
                -- when editing existing orders if desired
                -- (left open for flexibility)
                LET g_hdr_saved = (m_po_hdr_rec.id IS NOT NULL)

            ON ACTION save_header
                ATTRIBUTES(TEXT = "Save Header", IMAGE = "filesave")
                IF NOT validate_po_header() THEN
                    CALL utils_globals.show_error("Please fix required fields.")
                    CONTINUE DIALOG
                END IF

                IF NOT save_po_header() THEN
                    CALL utils_globals.show_error("Save failed.")
                    CONTINUE DIALOG
                END IF

                LET g_hdr_saved = TRUE
                CALL utils_globals.show_info(
                    SFMT("Header saved. PO #%1. You can now add lines.",
                        m_po_hdr_rec.doc_no))

                -- Move focus to lines array
                NEXT FIELD stock_id
                CONTINUE DIALOG

        END INPUT

        -----------------------------------------------------------------
        -- LINES BLOCK
        -----------------------------------------------------------------
        INPUT ARRAY m_po_lines_arr
            FROM po_lines_arr.*
            ATTRIBUTES(INSERT ROW = TRUE, DELETE ROW = TRUE, APPEND ROW = TRUE)

            BEFORE INPUT
                IF NOT g_hdr_saved THEN
                    CALL utils_globals.show_info(
                        "Please save the header first before adding lines.")
                END IF

            BEFORE ROW
                LET row_idx = DIALOG.getCurrentRow("po_lines_arr")

            BEFORE FIELD stock_id
                IF NOT g_hdr_saved THEN
                    CALL utils_globals.show_error(
                        "Please save the header first before adding lines.")
                    NEXT FIELD CURRENT
                END IF

            BEFORE INSERT
                IF NOT g_hdr_saved THEN
                    CALL utils_globals.show_error(
                        "Please save the header first before adding lines.")
                    CANCEL INSERT
                END IF

                -- Initialise new line defaults
                LET row_idx = DIALOG.getCurrentRow("m_po_lines_arr")
                LET m_po_lines_arr[row_idx].hdr_id = m_po_hdr_rec.id
                LET m_po_lines_arr[row_idx].status = "active"
                LET m_po_lines_arr[row_idx].created_at = TODAY
                LET m_po_lines_arr[row_idx].created_by = m_po_hdr_rec.created_by

            AFTER INSERT
                -- Renumber lines after insert
                CALL renumber_lines()

                -----------------------------------------------------------------
                -- ACTIONS on lines
                -----------------------------------------------------------------
            ON ACTION row_select
                ATTRIBUTES(TEXT = "Add Line", IMAGE = "add", DEFAULTVIEW = YES)
                LET row_idx = DIALOG.getCurrentRow("po_lines_arr")
                CALL populate_line_from_lookup(row_idx)
                CONTINUE DIALOG

            ON ACTION stock_lookup
                ATTRIBUTES(TEXT = "Stock Lookup",
                    IMAGE = "zoom",
                    DEFAULTVIEW = YES)
                LET row_idx = DIALOG.getCurrentRow("po_lines_arr")
                CALL open_stock_lookup(row_idx)
                CONTINUE DIALOG

            AFTER FIELD stock_id
                IF row_idx > 0
                    AND row_idx <= m_po_lines_arr.getLength()
                    AND m_po_lines_arr[row_idx].stock_id IS NOT NULL THEN
                    CALL load_stock_details(row_idx)
                END IF

            AFTER FIELD qnty, unit_cost, disc_pct, vat_rate
                IF row_idx > 0 AND row_idx <= m_po_lines_arr.getLength() THEN
                    CALL calculate_line_totals(row_idx)
                END IF

            ON ACTION save_lines
                ATTRIBUTES(TEXT = "Save Lines", IMAGE = "filesave")
                IF m_po_lines_arr.getLength() > 0 THEN
                    CALL save_po_lines()
                    CALL utils_globals.show_info("Lines saved successfully.")
                ELSE
                    CALL utils_globals.show_info("No lines to save.")
                END IF
                CONTINUE DIALOG

            ON ACTION delete_line
                ATTRIBUTES(TEXT = "Delete Line", IMAGE = "delete")
                IF row_idx > 0 AND row_idx <= m_po_lines_arr.getLength() THEN
                    CALL m_po_lines_arr.deleteElement(row_idx)
                    CALL renumber_lines()
                    CALL recalculate_header_totals()
                    CALL utils_globals.show_info("Line deleted.")
                END IF
                CONTINUE DIALOG

            AFTER DELETE
                -- Renumber lines after delete
                CALL renumber_lines()

        END INPUT

        -----------------------------------------------------------------
        -- GLOBAL EXIT
        -----------------------------------------------------------------
        ON ACTION cancel ATTRIBUTES(TEXT = "Exit", IMAGE = "quit")
            EXIT DIALOG

    END DIALOG

END FUNCTION

-- ==============================================================
-- Create new po header from master
-- ==============================================================
FUNCTION new_po_from_master(p_supp_id INTEGER)
    DEFINE l_supp_id INTEGER
    DEFINE row_idx INTEGER
    DEFINE sel_code STRING

    LET l_supp_id = p_supp_id

    -- load creditor data
    SELECT * INTO m_crd_rec.* FROM cl01_mast WHERE id = l_supp_id

    OPTIONS INPUT WRAP -- Prevent program from exiting when tabbing out of the last input field
    OPEN WINDOW w_pu130 WITH FORM "pu130_order" -- ATTRIBUTES(STYLE = "normal")

    INITIALIZE m_po_hdr_rec.* TO NULL
    CALL m_po_lines_arr.clear()

    -- Set the next doc number to be last doc number + 1
    LET m_po_hdr_rec.doc_no = utils_globals.get_next_code('pu30_ord_hdr', 'id')
    LET m_po_hdr_rec.trans_date = TODAY
    LET m_po_hdr_rec.status = "draft"
    LET m_po_hdr_rec.created_at = TODAY -- FIXED: Changed from CURRENT
    LET m_po_hdr_rec.created_by = utils_globals.get_random_user()

    -- link supplier
    LET m_po_hdr_rec.supp_id = l_supp_id
    -- link supplier
    LET m_po_hdr_rec.supp_id = m_crd_rec.id
    LET m_po_hdr_rec.supp_name = m_crd_rec.supp_name
    LET m_po_hdr_rec.supp_phone = m_crd_rec.phone
    LET m_po_hdr_rec.supp_email = m_crd_rec.email
    LET m_po_hdr_rec.supp_address1 = m_crd_rec.address1
    LET m_po_hdr_rec.supp_address2 = m_crd_rec.address2
    LET m_po_hdr_rec.supp_address3 = m_crd_rec.address3
    LET m_po_hdr_rec.supp_postal_code = m_crd_rec.postal_code
    LET m_po_hdr_rec.supp_vat_no = m_crd_rec.vat_no
    LET m_po_hdr_rec.supp_payment_terms = m_crd_rec.payment_terms
    LET m_po_hdr_rec.gross_tot = 0.00
    LET m_po_hdr_rec.disc_tot = 0.00
    LET m_po_hdr_rec.vat_tot = 0.00
    LET m_po_hdr_rec.net_tot = 0.00

    LET g_hdr_saved = FALSE

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME m_po_hdr_rec.* ATTRIBUTES(WITHOUT DEFAULTS)
            BEFORE INPUT
                IF g_hdr_saved THEN
                    -- Disable header fields after save
                    CALL DIALOG.setFieldActive("m_po_hdr_rec.*", FALSE)
                END IF

            ON ACTION save_header ATTRIBUTES(TEXT = "Save Header")
                IF NOT validate_po_header() THEN
                    CALL utils_globals.show_error("Please fix required fields.")
                    CONTINUE DIALOG
                END IF

                IF NOT save_po_header() THEN
                    CALL utils_globals.show_error("Save failed.")
                    CONTINUE DIALOG
                END IF

                LET g_hdr_saved = TRUE
                CALL utils_globals.show_info(
                    "Header saved. You can now add lines.")

                -- Move focus to lines array
                NEXT FIELD stock_id
                CONTINUE DIALOG
        END INPUT

        INPUT ARRAY m_po_lines_arr
            FROM po_lines_arr.*
            ATTRIBUTES(INSERT ROW = TRUE, DELETE ROW = TRUE, APPEND ROW = TRUE)
            BEFORE INPUT
                IF NOT g_hdr_saved THEN
                    CALL utils_globals.show_info(
                        "Please save header first before adding lines.")
                END IF

            BEFORE ROW
                LET row_idx = DIALOG.getCurrentRow("po_lines_arr")

            BEFORE FIELD stock_id
                IF NOT g_hdr_saved THEN
                    CALL utils_globals.show_error(
                        "Please save header first before adding lines.")
                    NEXT FIELD CURRENT
                END IF

            BEFORE INSERT
                IF NOT g_hdr_saved THEN
                    CALL utils_globals.show_error(
                        "Please save header first before adding lines.")
                    CANCEL INSERT
                END IF
                LET m_po_lines_arr[row_idx].hdr_id = m_po_hdr_rec.id
                LET m_po_lines_arr[row_idx].status = "active"
                LET m_po_lines_arr[row_idx].created_at = TODAY
                LET m_po_lines_arr[row_idx].created_by = m_po_hdr_rec.created_by

            AFTER INSERT
                -- Renumber lines after insert
                CALL renumber_lines()

            ON ACTION row_select
                ATTRIBUTES(TEXT = "Add Line", IMAGE = "add", DEFAULTVIEW = YES)
                LET row_idx = DIALOG.getCurrentRow("po_lines_arr")
                CALL populate_line_from_lookup(row_idx)
                CONTINUE DIALOG

            ON ACTION stock_lookup
                ATTRIBUTES(TEXT = "Stock Lookup",
                    IMAGE = "zoom",
                    DEFAULTVIEW = YES)
                LET row_idx = DIALOG.getCurrentRow("po_lines_arr")
                LET sel_code = st121_st_lkup.display_stocklist()
                IF sel_code IS NOT NULL AND sel_code != "" THEN
                    LET m_po_lines_arr[row_idx].stock_id = sel_code
                    CALL load_stock_details(row_idx)
                    DISPLAY m_po_lines_arr[row_idx].*
                        TO m_po_lines_arr[row_idx].*
                END IF
                CONTINUE DIALOG

            AFTER FIELD stock_id
                IF m_po_lines_arr[row_idx].stock_id IS NOT NULL THEN
                    CALL load_stock_details(row_idx)
                END IF

            AFTER FIELD qnty, unit_cost, disc_pct, vat_rate
                CALL calculate_line_totals(row_idx)

            ON ACTION save_lines ATTRIBUTES(TEXT = "Save Lines", IMAGE = "save")
                IF m_po_lines_arr.getLength() > 0 THEN
                    CALL save_po_lines()
                    CALL utils_globals.show_info("Lines saved successfully.")
                ELSE
                    CALL utils_globals.show_info("No lines to save.")
                END IF
                CONTINUE DIALOG

            ON ACTION delete_line
                ATTRIBUTES(TEXT = "Delete Line", IMAGE = "delete")
                IF row_idx > 0 AND row_idx <= m_po_lines_arr.getLength() THEN
                    CALL m_po_lines_arr.deleteElement(row_idx)
                    CALL renumber_lines()
                    CALL recalculate_header_totals()
                    CALL utils_globals.show_info("Line deleted.")
                END IF
                CONTINUE DIALOG

            AFTER DELETE
                -- Renumber lines after delete
                CALL renumber_lines()
        END INPUT

        ON ACTION CANCEL ATTRIBUTES(TEXT = "Exit")
            EXIT DIALOG
    END DIALOG

    CLOSE WINDOW w_pu130
END FUNCTION

-- ==============================================================
-- Create new header (defaults only)
-- ==============================================================
FUNCTION new_po()
    DEFINE next_doc INTEGER

    LET next_doc = utils_globals.get_next_code('pu30_ord_hdr', 'id')

    INITIALIZE m_po_hdr_rec.* TO NULL
    LET m_po_hdr_rec.doc_no = next_doc -- Added missing assignment
    LET m_po_hdr_rec.trans_date = TODAY
    LET m_po_hdr_rec.status = "draft"
    LET m_po_hdr_rec.created_at = TODAY -- FIXED: Changed from CURRENT
    LET m_po_hdr_rec.created_by = utils_globals.get_random_user()

    DISPLAY BY NAME m_po_hdr_rec.*
    MESSAGE SFMT("New PO #%1", next_doc)
END FUNCTION

-- ==============================================================
-- Save: insert or update
-- ==============================================================
FUNCTION save_po_header() RETURNS SMALLINT
    DEFINE ok SMALLINT
    BEGIN WORK
    TRY

        DISPLAY m_po_hdr_rec.*
        IF m_po_hdr_rec.id IS NULL THEN
            INSERT INTO pu30_ord_hdr VALUES m_po_hdr_rec.*
            LET m_po_hdr_rec.id = SQLCA.SQLERRD[2]
            CALL utils_globals.msg_saved()

        ELSE
            LET m_po_hdr_rec.updated_at = TODAY
            UPDATE pu30_ord_hdr
                SET pu30_ord_hdr.* = m_po_hdr_rec.*
                WHERE id = m_po_hdr_rec.id
            IF SQLCA.SQLCODE = 0 THEN
                CALL utils_globals.msg_updated()
            END IF
        END IF
        COMMIT WORK
        LET ok = (m_po_hdr_rec.id IS NOT NULL)
        RETURN ok
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error("Save failed:\n" || SQLCA.SQLERRM)
        RETURN FALSE
    END TRY

END FUNCTION

-- ==============================================================
-- Validation
-- ==============================================================
FUNCTION validate_po_header() RETURNS SMALLINT
    IF m_po_hdr_rec.trans_date IS NULL THEN
        RETURN FALSE
    END IF
    IF m_po_hdr_rec.supp_id IS NULL OR m_po_hdr_rec.supp_id = 0 THEN
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION

-- ==============================================================
-- Delete current record
-- ==============================================================
FUNCTION delete_po()
    DEFINE ok SMALLINT
    IF m_po_hdr_rec.id IS NULL THEN
        CALL utils_globals.show_info("Nothing to delete.")
        RETURN
    END IF

    LET ok = utils_globals.show_confirm("Delete this PO?", "Confirm")
    IF NOT ok THEN
        RETURN
    END IF

    BEGIN WORK
    TRY
        DELETE FROM pu30_ord_hdr WHERE id = m_po_hdr_rec.id
        COMMIT WORK
        CALL utils_globals.msg_deleted()
        INITIALIZE m_po_hdr_rec.* TO NULL
        DISPLAY BY NAME m_po_hdr_rec.doc_no,
            m_po_hdr_rec.trans_date,
            m_po_hdr_rec.supp_id,
            m_po_hdr_rec.status
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error("Delete failed:\n" || SQLCA.SQLERRM)
    END TRY
END FUNCTION

-- ==============================================================
-- Load by id
-- ==============================================================
FUNCTION load_po(p_id INTEGER)

    INITIALIZE m_po_hdr_rec.* TO NULL
    CALL m_po_lines_arr.clear()

    -- Load header
    SELECT * INTO m_po_hdr_rec.* FROM pu30_ord_hdr WHERE id = p_id

    IF SQLCA.SQLCODE != 0 THEN
        CALL utils_globals.show_error("PO header not found.")
        RETURN
    END IF

    -- Load lines
    DECLARE supp_curs CURSOR FOR
        SELECT * FROM pu30_ord_det WHERE hdr_id = p_id ORDER BY id;

    OPEN supp_curs
    FETCH supp_curs INTO m_po_lines_arr[m_po_lines_arr.getLength() + 1].*
    WHILE SQLCA.SQLCODE = 0
        FETCH supp_curs INTO m_po_lines_arr[m_po_lines_arr.getLength() + 1].*
    END WHILE
    CLOSE supp_curs

    -- Show header fields
    DISPLAY BY NAME m_po_hdr_rec.*

    -- Show line details
    DISPLAY ARRAY m_po_lines_arr TO po_lines_arr.*

END FUNCTION

-- ==============================================================
-- Find (simple lookup by doc_no)
-- ==============================================================
FUNCTION find_po()
    DEFINE doc_num INTEGER
    PROMPT "Enter PO Number: " FOR doc_num
    IF INT_FLAG OR doc_num IS NULL THEN
        LET INT_FLAG = FALSE
        RETURN
    END IF

    INITIALIZE m_po_hdr_rec.* TO NULL
    SELECT * INTO m_po_hdr_rec.* FROM pu30_ord_hdr WHERE doc_no = doc_num

    IF SQLCA.SQLCODE = NOTFOUND THEN
        CALL utils_globals.show_info(SFMT("PO %1 not found.", doc_num))
        RETURN
    END IF

    DISPLAY BY NAME m_po_hdr_rec.doc_no,
        m_po_hdr_rec.trans_date,
        m_po_hdr_rec.supp_id,
        m_po_hdr_rec.status
END FUNCTION

-- ==============================================================
-- Navigation wrapper
-- ==============================================================
FUNCTION move_record(dir SMALLINT)
    DEFINE new_idx INTEGER

    IF arr_codes.getLength() == 0 THEN
        CALL utils_globals.show_info("No records to navigate.")
        RETURN
    END IF

    LET new_idx = utils_globals.navigate_records(arr_codes, curr_idx, dir)
    LET curr_idx = new_idx
    CALL load_po(arr_codes[curr_idx])
END FUNCTION

-- ==============================================================
-- Open line details lookup form and populate line
-- ==============================================================
FUNCTION populate_line_from_lookup(p_idx INTEGER)
    DEFINE l_line_data RECORD
        id INTEGER,
        stock_id INTEGER,
        item_name STRING,
        uom STRING,
        qnty DECIMAL(12, 2),
        unit_cost DECIMAL(12, 2),
        disc_pct DECIMAL(5, 2),
        disc_amt DECIMAL(12, 2),
        gross_amt DECIMAL(12, 2),
        vat_rate DECIMAL(5, 2),
        vat_amt DECIMAL(12, 2),
        net_amt DECIMAL(12, 2),
        line_total DECIMAL(12, 2)
    END RECORD

    -- Call lookup form
    CALL pu_lkup_form.open_line_details_lookup('PURCHASE ORDER')
        RETURNING l_line_data.*

    -- If user selected data, populate the line
    IF l_line_data.stock_id IS NOT NULL AND l_line_data.stock_id > 0 THEN
        LET m_po_lines_arr[p_idx].stock_id = l_line_data.stock_id
        LET m_po_lines_arr[p_idx].item_name = l_line_data.item_name
        LET m_po_lines_arr[p_idx].uom = l_line_data.uom
        LET m_po_lines_arr[p_idx].qnty = l_line_data.qnty
        LET m_po_lines_arr[p_idx].unit_cost = l_line_data.unit_cost
        LET m_po_lines_arr[p_idx].disc_pct = l_line_data.disc_pct
        LET m_po_lines_arr[p_idx].disc_amt = l_line_data.disc_amt
        LET m_po_lines_arr[p_idx].gross_amt = l_line_data.gross_amt
        LET m_po_lines_arr[p_idx].vat_rate = l_line_data.vat_rate
        LET m_po_lines_arr[p_idx].vat_amt = l_line_data.vat_amt
        LET m_po_lines_arr[p_idx].net_amt = l_line_data.net_amt
        LET m_po_lines_arr[p_idx].line_total = l_line_data.line_total

        -- Display updated line
        DISPLAY m_po_lines_arr[p_idx].* TO m_po_lines_arr[p_idx].*

        -- Recalculate header totals
        CALL recalculate_header_totals()
    END IF
END FUNCTION

-- ==============================================================
-- Open stock lookup and populate line with selected stock
-- ==============================================================
FUNCTION open_stock_lookup(p_idx INTEGER)
    DEFINE l_stock_id STRING

    -- Call stock lookup function
    LET l_stock_id = st121_st_lkup.display_stocklist()

    IF l_stock_id IS NOT NULL AND l_stock_id != "" THEN
        LET m_po_lines_arr[p_idx].stock_id = l_stock_id
        -- Load stock details will populate other fields
        CALL load_stock_details(p_idx)
        DISPLAY m_po_lines_arr[p_idx].* TO m_po_lines_arr[p_idx].*
    END IF
END FUNCTION

-- ==============================================================
-- Load stock details when stock_id is entered
-- ==============================================================
FUNCTION load_stock_details(p_idx INTEGER)
    DEFINE l_stock RECORD
        description VARCHAR(200),
        unit_cost DECIMAL(12, 4)
    END RECORD

    IF m_po_lines_arr[p_idx].stock_id IS NULL
        OR m_po_lines_arr[p_idx].stock_id = 0 THEN
        RETURN
    END IF

    SELECT description, unit_cost
        INTO l_stock.description, l_stock.unit_cost
        FROM st01_mast
        WHERE id = m_po_lines_arr[p_idx].stock_id

    IF SQLCA.SQLCODE = 0 THEN
        LET m_po_lines_arr[p_idx].item_name = l_stock.description
        LET m_po_lines_arr[p_idx].uom = "EA" -- Default unit of measure
        LET m_po_lines_arr[p_idx].unit_cost = l_stock.unit_cost
        LET m_po_lines_arr[p_idx].vat_rate = 15 -- Default VAT rate

        -- Calculate line totals if quantity is already entered
        IF m_po_lines_arr[p_idx].qnty IS NOT NULL THEN
            CALL calculate_line_totals(p_idx)
        END IF
    ELSE
        CALL utils_globals.show_error("Stock item not found.")
    END IF
END FUNCTION

-- ==============================================================
-- Calculate line totals
-- ==============================================================
FUNCTION calculate_line_totals(p_idx INTEGER)
    DEFINE l_gross DECIMAL(12, 2)
    DEFINE l_disc DECIMAL(12, 2)
    DEFINE l_vat DECIMAL(12, 2)
    DEFINE l_net DECIMAL(12, 2)

    -- Initialize defaults
    IF m_po_lines_arr[p_idx].qnty IS NULL THEN
        LET m_po_lines_arr[p_idx].qnty = 0
    END IF
    IF m_po_lines_arr[p_idx].unit_cost IS NULL THEN
        LET m_po_lines_arr[p_idx].unit_cost = 0
    END IF
    IF m_po_lines_arr[p_idx].disc_pct IS NULL THEN
        LET m_po_lines_arr[p_idx].disc_pct = 0
    END IF
    IF m_po_lines_arr[p_idx].vat_rate IS NULL THEN
        LET m_po_lines_arr[p_idx].vat_rate = 0
    END IF

    -- Calculate gross amount
    LET l_gross = m_po_lines_arr[p_idx].qnty * m_po_lines_arr[p_idx].unit_cost
    LET m_po_lines_arr[p_idx].gross_amt = l_gross

    -- Calculate discount
    LET l_disc = l_gross * (m_po_lines_arr[p_idx].disc_pct / 100)
    LET m_po_lines_arr[p_idx].disc_amt = l_disc

    -- Calculate net before VAT
    LET l_net = l_gross - l_disc
    LET m_po_lines_arr[p_idx].net_amt = l_net

    -- Calculate VAT
    LET l_vat = l_net * (m_po_lines_arr[p_idx].vat_rate / 100)
    LET m_po_lines_arr[p_idx].vat_amt = l_vat

    -- Calculate line total (net + VAT)
    LET m_po_lines_arr[p_idx].line_total = l_net + l_vat

    -- Recalculate header totals
    CALL recalculate_header_totals()
END FUNCTION

-- ==============================================================
-- Renumber all line numbers sequentially
-- ==============================================================
FUNCTION renumber_lines()
    DEFINE i INTEGER

    FOR i = 1 TO m_po_lines_arr.getLength()
        LET m_po_lines_arr[i].line_no = i
    END FOR
END FUNCTION

-- ==============================================================
-- Recalculate header totals from all lines
-- ==============================================================
FUNCTION recalculate_header_totals()
    DEFINE i INTEGER
    DEFINE l_gross_tot DECIMAL(12, 2)
    DEFINE l_disc_tot DECIMAL(12, 2)
    DEFINE l_vat_tot DECIMAL(12, 2)
    DEFINE l_net_tot DECIMAL(12, 2)

    LET l_gross_tot = 0
    LET l_disc_tot = 0
    LET l_vat_tot = 0
    LET l_net_tot = 0

    FOR i = 1 TO m_po_lines_arr.getLength()
        IF m_po_lines_arr[i].gross_amt IS NOT NULL THEN
            LET l_gross_tot = l_gross_tot + m_po_lines_arr[i].gross_amt
        END IF
        IF m_po_lines_arr[i].disc_amt IS NOT NULL THEN
            LET l_disc_tot = l_disc_tot + m_po_lines_arr[i].disc_amt
        END IF
        IF m_po_lines_arr[i].vat_amt IS NOT NULL THEN
            LET l_vat_tot = l_vat_tot + m_po_lines_arr[i].vat_amt
        END IF
        IF m_po_lines_arr[i].line_total IS NOT NULL THEN
            LET l_net_tot = l_net_tot + m_po_lines_arr[i].line_total
        END IF
    END FOR

    LET m_po_hdr_rec.gross_tot = l_gross_tot
    LET m_po_hdr_rec.disc_tot   = l_disc_tot
    LET m_po_hdr_rec.vat_tot    = l_vat_tot
    LET m_po_hdr_rec.net_tot    = l_net_tot

    DISPLAY BY NAME m_po_hdr_rec.gross_tot,
        m_po_hdr_rec.disc_tot,
        m_po_hdr_rec.vat_tot,
        m_po_hdr_rec.net_tot
END FUNCTION

-- ==============================================================
-- Save PO lines to database
-- ==============================================================
FUNCTION save_po_lines()
    DEFINE i INTEGER
    DEFINE l_line RECORD LIKE pu30_ord_det.*
    DEFINE l_timestamp DATETIME YEAR TO FRACTION(5)

    DISPLAY l_line.*

    -- Renumber lines before saving
    CALL renumber_lines()

    BEGIN WORK
    TRY
    -- Delete existing lines for this header
    DELETE FROM pu30_ord_det WHERE hdr_id = m_po_hdr_rec.id

    -- Insert all lines
    FOR i = 1 TO m_po_lines_arr.getLength()
        IF m_po_lines_arr[i].stock_id IS NOT NULL
            AND m_po_lines_arr[i].stock_id > 0 THEN
            -- Clear the id field to let database auto-generate it
            INITIALIZE l_line.* TO NULL

            -- Copy all fields from array to record
            LET l_line.hdr_id           = m_po_hdr_rec.id
            LET l_line.line_no          = i
            LET l_line.stock_id         = m_po_lines_arr[i].stock_id
            LET l_line.item_name        = m_po_lines_arr[i].item_name
            LET l_line.uom              = m_po_lines_arr[i].uom
            LET l_line.qnty             = m_po_lines_arr[i].qnty
            LET l_line.unit_cost        = m_po_lines_arr[i].unit_cost
            LET l_line.disc_pct         = m_po_lines_arr[i].disc_pct
            LET l_line.disc_amt         = m_po_lines_arr[i].disc_amt
            LET l_line.gross_amt        = m_po_lines_arr[i].gross_amt
            LET l_line.vat_rate         = m_po_lines_arr[i].vat_rate
            LET l_line.vat_amt          = m_po_lines_arr[i].vat_amt
            LET l_line.net_amt          = m_po_lines_arr[i].net_amt
            LET l_line.line_total       = m_po_lines_arr[i].line_total
            LET l_line.wh_id            = m_po_lines_arr[i].wh_id
            LET l_line.wb_id            = m_po_lines_arr[i].wb_id
            LET l_line.notes            = m_po_lines_arr[i].notes
            LET l_line.status           = m_po_lines_arr[i].status
            LET l_line.created_at       = CURRENT
            LET l_line.created_by       = utils_globals.get_random_user()

            INSERT INTO pu30_ord_det VALUES l_line.*
            
        END IF
    END FOR

    -- Update header totals
    UPDATE pu30_ord_hdr
        SET gross_tot = m_po_hdr_rec.gross_tot,
            disc_tot = m_po_hdr_rec.disc_tot,
            vat_tot = m_po_hdr_rec.vat_tot,
            net_tot = m_po_hdr_rec.net_tot,
            status = 'posted',
            updated_at = l_timestamp
        WHERE id = m_po_hdr_rec.id

    COMMIT WORK
    CALL utils_globals.msg_saved()
    -- Save record to the transaction record
    IF m_po_hdr_rec.status = 'posted' THEN
        CALL add_po_to_creditor_trans(m_po_hdr_rec.id)
    END IF

    -- Load current PO in read only mode after adding it
    CALL load_po(m_po_hdr_rec.id)
--
    CATCH
    ROLLBACK WORK

    DISPLAY SQLCA.SQLERRM
    
    CALL utils_globals.show_error(
        "Failed to save lines:\n" || SQLCA.SQLERRM)
    END TRY
    
END FUNCTION

-- ==============================================================
-- Add/Update Creditor Transaction for PO
-- ==============================================================
FUNCTION add_po_to_creditor_trans(p_hdr_id INTEGER)
    DEFINE exists SMALLINT

    -- Check if a transaction already exists for this PO
    SELECT COUNT(*)
        INTO exists
        FROM cl30_trans
        WHERE doc_type = 'PO' AND doc_no = p_hdr_id

    IF exists = 0 THEN
        -- INSERT NEW LEDGER ENTRY
        INSERT INTO cl30_trans(
            supp_id,
            trans_date,
            doc_type,
            doc_no,
            gross_tot,
            disc_tot,
            vat_tot,
            net_tot,
            notes,
            created_at,
            created_by,
            status)
            VALUES(m_po_hdr_rec.supp_id,
                m_po_hdr_rec.trans_date,
                'PO', -- Document type
                p_hdr_id, -- doc_no = PO ID
                m_po_hdr_rec.gross_tot,
                m_po_hdr_rec.disc_tot,
                m_po_hdr_rec.vat_tot,
                m_po_hdr_rec.net_tot,
                'Purchase Order',
                TODAY,
                m_po_hdr_rec.created_by,
                'posted');
    ELSE
        -- UPDATE EXISTING LEDGER ENTRY
        UPDATE cl30_trans
            SET gross_tot = m_po_hdr_rec.gross_tot,
                disc_tot = m_po_hdr_rec.disc_tot,
                vat_tot = m_po_hdr_rec.vat_tot,
                net_tot = m_po_hdr_rec.net_tot,
                trans_date = m_po_hdr_rec.trans_date,
                updated_at = TODAY,
                status = 'posted'
            WHERE doc_type = 'PO' AND doc_no = p_hdr_id;
    END IF
END FUNCTION
