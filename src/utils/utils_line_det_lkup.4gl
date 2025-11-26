-- ==============================================================
-- Program   : utils_line_det_lkup.4gl
-- Purpose   : Generic Doc Lines Details Lookup
-- Module    : Utils (utils)
-- Author    : Bongani Dlamini
-- Version   : Genero 3.20.10
-- ==============================================================
IMPORT FGL utils_globals
IMPORT FGL st121_st_lkup

SCHEMA demoappdb

TYPE line_data_t RECORD
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
    line_total DECIMAL(12, 2),
    available DECIMAL(15,2),
    balance DECIMAL(15,2),
    reserved DECIMAL(15,2)
END RECORD

DEFINE m_line_data line_data_t

-- Open doc line details lookup form
FUNCTION open_line_details_lookup(p_doc_type STRING) RETURNS line_data_t
    DEFINE l_result line_data_t
    DEFINE l_stock RECORD LIKE st01_mast.*

    INITIALIZE l_result.* TO NULL

    OPTIONS INPUT WRAP
    OPEN WINDOW w_line_det WITH FORM 'pu_lkup_form'
        ATTRIBUTES(STYLE = "dialog", TEXT = "Line Details - " || p_doc_type)

    CALL utils_globals.set_form_label("lbl_title", "Line Details - " || p_doc_type)

    -- Set default values
    LET m_line_data.qnty = 0
    LET m_line_data.disc_pct = 0

    INPUT BY NAME m_line_data.* ATTRIBUTES(WITHOUT DEFAULTS, UNBUFFERED)
        
        BEFORE INPUT
            -- Display defaults
            DISPLAY BY NAME m_line_data.*
            -- stock lookup in details form
        ON ACTION lookup_stock
            LET l_result.stock_id = st121_st_lkup.fetch_list()

            IF l_result.stock_id IS NOT NULL AND l_result.stock_id != "" THEN
                -- Convert STRING to INTEGER
                LET m_line_data.stock_id = l_result.stock_id CLIPPED

                -- Load stock details
                SELECT * INTO m_line_data.* FROM st01_mast
                    WHERE id =l_result.stock_id

                IF SQLCA.SQLCODE = 0 THEN
                    -- Populate line fields from stock record
                    LET m_line_data.item_name = l_stock.description
                    LET m_line_data.uom = l_stock.uom
                    LET m_line_data.unit_cost = l_stock.unit_cost

                    -- Recalculate amounts based on new unit cost
                    CALL calculate_line_amounts()

                    -- Display the updated fields
                    DISPLAY BY NAME m_line_data.*

                ELSE
                    CALL utils_globals.show_error("Stock item not found.")
                END IF
            END IF

        AFTER FIELD qnty, unit_cost, disc_pct, vat_rate
            CALL calculate_line_amounts()

        ON ACTION accept ATTRIBUTES(TEXT = "OK", IMAGE = "check")
            IF m_line_data.stock_id IS NULL OR m_line_data.stock_id = 0 THEN
                CALL utils_globals.show_error("Please select a stock item.")
                NEXT FIELD CURRENT
            END IF
            IF m_line_data.qnty IS NULL OR m_line_data.qnty <= 0 THEN
                CALL utils_globals.show_error("Please enter a valid quantity.")
                NEXT FIELD CURRENT
            END IF
            LET l_result.* = m_line_data.*
            EXIT INPUT

        ON ACTION cancel ATTRIBUTES(TEXT = "Cancel", IMAGE = "cancel")
            INITIALIZE l_result.* TO NULL
            EXIT INPUT
    END INPUT

    CLOSE WINDOW w_line_det
    RETURN l_result.*
END FUNCTION

-- Calculate line amounts
FUNCTION calculate_line_amounts()
    DEFINE l_gross DECIMAL(12, 2)
    DEFINE l_disc DECIMAL(12, 2)
    DEFINE l_vat DECIMAL(12, 2)
    DEFINE l_net DECIMAL(12, 2)

    -- Initialize defaults
    IF m_line_data.qnty IS NULL THEN
        LET m_line_data.qnty = 0
    END IF
    IF m_line_data.unit_cost IS NULL THEN
        LET m_line_data.unit_cost = 0
    END IF
    IF m_line_data.disc_pct IS NULL THEN
        LET m_line_data.disc_pct = 0
    END IF
    IF m_line_data.vat_rate IS NULL THEN
        LET m_line_data.vat_rate = 0
    END IF

    -- Calculate gross amount
    LET l_gross = m_line_data.qnty * m_line_data.unit_cost
    LET m_line_data.gross_amt = l_gross

    -- Calculate discount
    LET l_disc = l_gross * (m_line_data.disc_pct / 100)
    LET m_line_data.disc_amt = l_disc

    -- Calculate net before VAT
    LET l_net = l_gross - l_disc
    LET m_line_data.net_amt = l_net

    -- Calculate VAT
    LET l_vat = l_net * (m_line_data.vat_rate / 100)
    LET m_line_data.vat_amt = l_vat

    -- Calculate line total (net + VAT)
    LET m_line_data.line_total = l_net + l_vat

    -- Display calculated fields
    DISPLAY BY NAME m_line_data.*
END FUNCTION
