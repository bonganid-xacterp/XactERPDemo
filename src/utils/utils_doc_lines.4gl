-- ==============================================================
-- File      : utils_doc_lines.4gl
-- Purpose   : Global document line utilities (shared across SA, PU)
-- Version   : Genero 3.20.10
-- ==============================================================

IMPORT FGL utils_globals
SCHEMA demoappdb



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
