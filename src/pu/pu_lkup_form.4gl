-- ==============================================================
-- Program   : pu_lkup_form.4gl
-- Purpose   : Generic Purchases Details Lookup
-- Module    : Purchases (pu)
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
    qnty DECIMAL(12,2),
    unit_cost DECIMAL(12,2),
    disc_pct DECIMAL(5,2),
    disc_amt DECIMAL(12,2),
    gross_amt DECIMAL(12,2),
    vat_rate DECIMAL(5,2),
    vat_amt DECIMAL(12,2),
    net_amt DECIMAL(12,2),
    line_total DECIMAL(12,2)
END RECORD

DEFINE m_line line_data_t

-- Open doc line details lookup form
FUNCTION open_line_details_lookup(p_doc_type STRING) RETURNS line_data_t
    DEFINE l_result line_data_t
    DEFINE l_stock_id STRING
    DEFINE l_stock RECORD LIKE st01_mast.*
        --description VARCHAR(200),
        --unit_cost DECIMAL(12,4)
    --END RECORD

    INITIALIZE l_result.* TO NULL
    INITIALIZE m_line.* TO NULL

    CALL utils_globals.set_page_title("Line Details - " || p_doc_type)

    OPTIONS INPUT WRAP
    OPEN WINDOW pu_lkup_form WITH FORM 'pu_lkup_form'
        ATTRIBUTES(STYLE="normal", TEXT="Line Details - " || p_doc_type)

    -- Set default values
    LET m_line.qnty = 0
    LET m_line.disc_pct = 0

    -- Display defaults
    DISPLAY BY NAME m_line.stock_id, m_line.item_name, m_line.uom,
                    m_line.qnty, m_line.unit_cost, m_line.disc_pct,
                    m_line.disc_amt, m_line.gross_amt, m_line.vat_rate,
                    m_line.vat_amt, m_line.net_amt, m_line.line_total

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME m_line.stock_id, m_line.item_name, m_line.uom,
                      m_line.qnty, m_line.unit_cost, m_line.disc_pct,
                      m_line.disc_amt, m_line.gross_amt, m_line.vat_rate,
                      m_line.vat_amt, m_line.net_amt, m_line.line_total
            ATTRIBUTES(WITHOUT DEFAULTS)

            -- stock look in details form
            ON ACTION lookup_stock
                LET l_stock_id = st121_st_lkup.display_stocklist()
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
                        LET m_line.unit_cost = l_stock.unit_cost
                        
                        -- Recalculate amounts based on new unit cost
                        CALL calculate_line_amounts()

                        -- Display the updated m_line fields (these match the form field names)
                        DISPLAY BY NAME m_line.stock_id, m_line.item_name, m_line.uom,
                                m_line.qnty, m_line.unit_cost, m_line.disc_pct,
                                m_line.disc_amt, m_line.gross_amt, m_line.vat_rate,
                                m_line.vat_amt, m_line.net_amt, m_line.line_total

                    ELSE
                        CALL utils_globals.show_error("Stock item not found.")
                    END IF
                END IF

            AFTER FIELD qnty, unit_cost, disc_pct, vat_rate
                CALL calculate_line_amounts()

        END INPUT

        ON ACTION accept ATTRIBUTES(TEXT="OK", IMAGE="check")
            IF m_line.stock_id IS NULL OR m_line.stock_id = 0 THEN
                CALL utils_globals.show_error("Please select a stock item.")
                CONTINUE DIALOG
            END IF
            IF m_line.qnty IS NULL OR m_line.qnty <= 0 THEN
                CALL utils_globals.show_error("Please enter a valid quantity.")
                CONTINUE DIALOG
            END IF
            LET l_result.* = m_line.*
            EXIT DIALOG

        ON ACTION cancel ATTRIBUTES(TEXT="Cancel", IMAGE="cancel")
            INITIALIZE l_result.* TO NULL
            EXIT DIALOG
    END DIALOG

    CLOSE WINDOW pu_lkup_form
    RETURN l_result.*
END FUNCTION

-- Calculate line amounts
FUNCTION calculate_line_amounts()
    DEFINE l_gross DECIMAL(12,2)
    DEFINE l_disc DECIMAL(12,2)
    DEFINE l_vat DECIMAL(12,2)
    DEFINE l_net DECIMAL(12,2)

    -- Initialize defaults
    IF m_line.qnty IS NULL THEN
        LET m_line.qnty = 0
    END IF
    IF m_line.unit_cost IS NULL THEN
        LET m_line.unit_cost = 0
    END IF
    IF m_line.disc_pct IS NULL THEN
        LET m_line.disc_pct = 0
    END IF
    IF m_line.vat_rate IS NULL THEN
        LET m_line.vat_rate = 0
    END IF

    -- Calculate gross amount
    LET l_gross = m_line.qnty * m_line.unit_cost
    LET m_line.gross_amt = l_gross

    -- Calculate discount
    LET l_disc = l_gross * (m_line.disc_pct / 100)
    LET m_line.disc_amt = l_disc

    -- Calculate net before VAT
    LET l_net = l_gross - l_disc
    LET m_line.net_amt = l_net

    -- Calculate VAT
    LET l_vat = l_net * (m_line.vat_rate / 100)
    LET m_line.vat_amt = l_vat

    -- Calculate line total (net + VAT)
    LET m_line.line_total = l_net + l_vat

    -- Display calculated fields
    DISPLAY BY NAME m_line.disc_amt, m_line.gross_amt, m_line.vat_amt,
                    m_line.net_amt, m_line.line_total
END FUNCTION
