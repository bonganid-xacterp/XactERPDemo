-- ==============================================================
-- File      : utils_doc_lines.4gl
-- Purpose   : Global document line utilities (shared across SA, PU)
-- Version   : Genero 3.20.10
-- ==============================================================

IMPORT FGL utils_globals
SCHEMA demoapp_db

-- ==============================================================
-- Function : calculate_line_totals
-- Purpose  : Calculate Gross, Discount, Net, VAT, and Line Total
-- ==============================================================
PUBLIC FUNCTION calculate_line_totals(p_qty DECIMAL, p_price DECIMAL,
                                      p_disc_pct DECIMAL, p_vat_rate DECIMAL)
    RETURNS (DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL)

    DEFINE l_gross, l_disc, l_net, l_vat, l_total DECIMAL(15,2)

    LET l_gross = p_qty * p_price
    LET l_disc  = l_gross * (p_disc_pct / 100)
    LET l_net   = l_gross - l_disc
    LET l_vat   = l_net * (p_vat_rate / 100)
    LET l_total = l_net + l_vat

    RETURN l_gross, l_disc, l_net, l_vat, l_total
END FUNCTION


-- ==============================================================
-- Function : load_stock_defaults
-- Purpose  : Load stock cost, price and description
-- ==============================================================
PUBLIC FUNCTION load_stock_defaults(p_stock_id INTEGER)
    RETURNS (DECIMAL, DECIMAL, VARCHAR(150), DECIMAL)

    DEFINE l_cost, l_price, l_onhand DECIMAL(15,2)
    DEFINE l_desc VARCHAR(150)

    SELECT unit_cost, sell_price, description, stock_on_hand
      INTO l_cost, l_price, l_desc, l_onhand
      FROM st01_mast
     WHERE stock_id = p_stock_id

    IF SQLCA.SQLCODE != 0 THEN
        LET l_cost = 0
        LET l_price = 0
        LET l_desc = "Unknown Item"
        LET l_onhand = 0
    END IF

    RETURN l_cost, l_price, l_desc, l_onhand
END FUNCTION
