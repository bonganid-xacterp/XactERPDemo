-- ==============================================================
-- Program   : utils_line_det_lkup.4gl
-- Purpose   : Generic Doc Lines Details Lookup
-- Author    : Bongani Dlamini
-- Version   : Genero 3.20.10
-- ==============================================================

IMPORT FGL utils_globals
IMPORT FGL st121_st_lkup

SCHEMA demoappdb

TYPE line_data_t RECORD
    stock_id     INTEGER,
    item_name    STRING,
    uom          STRING,
    qnty         DECIMAL(12, 2),
    unit_cost    DECIMAL(12, 2),
    disc_pct     DECIMAL(5, 2),
    disc_amt     DECIMAL(12, 2),
    gross_amt    DECIMAL(12, 2),
    vat_rate     DECIMAL(5, 2),
    vat_amt      DECIMAL(12, 2),
    net_amt      DECIMAL(12, 2),
    line_total   DECIMAL(12, 2),

    available    DECIMAL(15,2),
    balance      DECIMAL(15,2),
    reserved     DECIMAL(15,2)
END RECORD

DEFINE m_line_data line_data_t


-- ==============================================================
-- Public FUNCTION: open_line_details_lookup()
-- ==============================================================

PUBLIC FUNCTION open_line_details_lookup(p_doc_type STRING) RETURNS line_data_t
    DEFINE l_result line_data_t
    DEFINE l_stock RECORD LIKE st01_mast.*

    INITIALIZE m_line_data.* TO NULL
    INITIALIZE l_result.* TO NULL

    -- Defaults
    LET m_line_data.qnty = 0
    LET m_line_data.disc_pct = 0
    LET m_line_data.vat_rate = 0

    OPTIONS INPUT WRAP
    OPEN WINDOW w_line_det WITH FORM "pu_lkup_form"
        ATTRIBUTES(STYLE = "dialog", TEXT = "Line Details - " || p_doc_type)

    CALL utils_globals.set_form_label("lbl_title", "Line Details - " || p_doc_type)

    INPUT BY NAME m_line_data.* ATTRIBUTES(UNBUFFERED, WITHOUT DEFAULTS)

        BEFORE INPUT
            DISPLAY BY NAME m_line_data.*

        -- ======================================================
        -- Stock lookup action
        -- ======================================================
        ON ACTION lookup_stock
            LET m_line_data.stock_id = st121_st_lkup.fetch_list()

            IF m_line_data.stock_id > 0 THEN
                SELECT * INTO l_stock.* FROM st01_mast
                    WHERE id = m_line_data.stock_id

                IF SQLCA.SQLCODE = 0 THEN
                    LET m_line_data.item_name  = l_stock.description
                    LET m_line_data.uom        = l_stock.uom
                    LET m_line_data.unit_cost  = l_stock.unit_cost

                    LET m_line_data.available  = l_stock.stock_on_hand
                    LET m_line_data.balance    = l_stock.stock_balance
                    LET m_line_data.reserved   = l_stock.reserved_qnty

                    CALL calculate_line_amounts()
                    DISPLAY BY NAME m_line_data.*
                ELSE
                    CALL utils_globals.show_error("Stock item not found.")
                END IF
            END IF

        -- ======================================================
        -- Auto recalc on fields
        -- ======================================================
        AFTER FIELD qnty, unit_cost, disc_pct, vat_rate
            CALL calculate_line_amounts()

        -- ======================================================
        -- Accept line
        -- ======================================================
        ON ACTION accept ATTRIBUTES(TEXT="OK", IMAGE="check")
            IF m_line_data.stock_id IS NULL OR m_line_data.stock_id <= 0 THEN
                CALL utils_globals.show_error("Please select a stock item.")
                NEXT FIELD stock_id
            END IF

            IF m_line_data.qnty <= 0 THEN
                CALL utils_globals.show_error("Quantity must be greater than zero.")
                NEXT FIELD qnty
            END IF

            LET l_result.* = m_line_data.*
            EXIT INPUT

        -- ======================================================
        -- Cancel
        -- ======================================================
        ON ACTION cancel ATTRIBUTES(TEXT="Cancel", IMAGE="cancel")
            INITIALIZE l_result.* TO NULL
            EXIT INPUT

    END INPUT

    CLOSE WINDOW w_line_det
    RETURN l_result.*
END FUNCTION


-- ==============================================================
-- Recalculate line amounts
-- ==============================================================
FUNCTION calculate_line_amounts()
    DEFINE l_gross, l_disc, l_vat, l_net DECIMAL(12, 2)

    LET m_line_data.qnty      = NVL(m_line_data.qnty, 0)
    LET m_line_data.unit_cost = NVL(m_line_data.unit_cost, 0)
    LET m_line_data.disc_pct  = NVL(m_line_data.disc_pct, 0)
    LET m_line_data.vat_rate  = NVL(m_line_data.vat_rate, 0)

    LET l_gross = m_line_data.qnty * m_line_data.unit_cost
    LET m_line_data.gross_amt = l_gross

    LET l_disc = l_gross * (m_line_data.disc_pct / 100)
    LET m_line_data.disc_amt = l_disc

    LET l_net = l_gross - l_disc
    LET m_line_data.net_amt = l_net

    LET l_vat = l_net * (m_line_data.vat_rate / 100)
    LET m_line_data.vat_amt = l_vat

    LET m_line_data.line_total = l_net + l_vat

    DISPLAY BY NAME m_line_data.gross_amt, m_line_data.disc_amt,
                    m_line_data.net_amt, m_line_data.vat_amt,
                    m_line_data.line_total
END FUNCTION
