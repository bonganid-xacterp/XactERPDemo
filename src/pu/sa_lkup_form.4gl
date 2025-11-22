-- ==============================================================
-- Program   : sa_lkup_form.4gl
-- Purpose   : Generic Sales Details Lookup
-- Module    : Sales (sa)
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
    sell_price DECIMAL(12, 2),
    disc_pct DECIMAL(5, 2),
    disc_amt DECIMAL(12, 2),
    gross_amt DECIMAL(12, 2),
    vat_rate DECIMAL(5, 2),
    vat_amt DECIMAL(12, 2),
    net_excl_amt DECIMAL(12, 2),
    line_total DECIMAL(12, 2)
END RECORD

DEFINE m_line line_data_t

-- Open doc line details lookup form
FUNCTION open_line_details_lookup(p_doc_type STRING) RETURNS line_data_t
    DEFINE l_result line_data_t
    DEFINE l_stock_id INTEGER
    DEFINE l_stock RECORD LIKE st01_mast.*

    INITIALIZE l_result.* TO NULL
    INITIALIZE m_line.* TO NULL

    OPTIONS INPUT WRAP
    OPEN WINDOW pu_lkup_form
        WITH
        FORM 'pu_lkup_form'
        ATTRIBUTES(STYLE = "dialog", TEXT = "Line Details - " || p_doc_type)

    CALL utils_globals.set_page_title("Line Details - " || p_doc_type)

    -- Set default values
    LET m_line.qnty = 0
    LET m_line.disc_pct = 0

    INPUT BY NAME m_line.* ATTRIBUTES(WITHOUT DEFAULTS, UNBUFFERED)

        BEFORE INPUT
            -- Display defaults
            DISPLAY BY NAME m_line.*
            -- stock lookup in details form
        ON ACTION lookup_stock
            LET l_stock_id = st121_st_lkup.fetch_list()

            IF l_stock_id IS NOT NULL AND l_stock_id != "" THEN
                -- Convert STRING to INTEGER
                LET m_line.stock_id = l_stock_id CLIPPED

                -- Load stock details
                SELECT *
                    INTO l_stock.*
                    FROM st01_mast
                    WHERE id = m_line.stock_id

                IF SQLCA.SQLCODE = 0 THEN
                    -- Populate line fields from stock record
                    LET m_line.item_name = l_stock.description
                    LET m_line.uom = l_stock.uom
                    LET m_line.sell_price = l_stock.sell_price

                    -- Recalculate amounts based on new unit cost
                    CALL calculate_line_amounts()

                    -- Display the updated fields
                    DISPLAY BY NAME m_line.*

                ELSE
                    CALL utils_globals.show_error("Stock item not found.")
                END IF
            END IF

        AFTER FIELD qnty, sell_price, disc_pct, vat_rate
            CALL calculate_line_amounts()

        ON ACTION accept ATTRIBUTES(TEXT = "OK", IMAGE = "check")
            IF m_line.stock_id IS NULL OR m_line.stock_id = 0 THEN
                CALL utils_globals.show_error("Please select a stock item.")
                NEXT FIELD CURRENT
            END IF
            IF m_line.qnty IS NULL OR m_line.qnty <= 0 THEN
                CALL utils_globals.show_error("Please enter a valid quantity.")
                NEXT FIELD CURRENT
            END IF
            LET l_result.* = m_line.*
            EXIT INPUT

        ON ACTION cancel ATTRIBUTES(TEXT = "Cancel", IMAGE = "cancel")
            INITIALIZE l_result.* TO NULL
            EXIT INPUT
    END INPUT

    CLOSE WINDOW pu_lkup_form
    RETURN l_result.*
END FUNCTION

-- Calculate line amounts
FUNCTION calculate_line_amounts()
    DEFINE l_gross DECIMAL(12, 2)
    DEFINE l_disc DECIMAL(12, 2)
    DEFINE l_vat DECIMAL(12, 2)
    DEFINE l_net DECIMAL(12, 2)

    -- Initialize defaults
    IF m_line.qnty IS NULL THEN
        LET m_line.qnty = 0
    END IF
    IF m_line.sell_price IS NULL THEN
        LET m_line.sell_price = 0
    END IF
    IF m_line.disc_pct IS NULL THEN
        LET m_line.disc_pct = 0
    END IF
    IF m_line.vat_rate IS NULL THEN
        LET m_line.vat_rate = 0
    END IF

    -- Calculate gross amount
    LET l_gross = m_line.qnty * m_line.sell_price
    LET m_line.gross_amt = l_gross

    -- Calculate discount
    LET l_disc = l_gross * (m_line.disc_pct / 100)
    LET m_line.disc_amt = l_disc

    -- Calculate net before VAT
    LET l_net = l_gross - l_disc
    LET m_line.net_excl_amt = l_net

    -- Calculate VAT
    LET l_vat = l_net * (m_line.vat_rate / 100)
    LET m_line.vat_amt = l_vat

    -- Calculate line total (net + VAT)
    LET m_line.line_total = l_net + l_vat

    -- Display calculated fields
    DISPLAY BY NAME m_line.*
END FUNCTION
