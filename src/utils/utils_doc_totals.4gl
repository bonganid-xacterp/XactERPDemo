-- ==============================================================
-- Module  : utils_doc_totals.4gl
-- Purpose : Generic document line and header total calculations
-- Used by : SA (Sales), PU (Purchases), GRN, INV, etc.
-- Author  : Bongani Dlamini
-- Version : Genero 3.20.10
-- ==============================================================

IMPORT FGL utils_globals

-- --------------------------------------------------------------
-- Calculate a single line total (Qty * Price - Discount + VAT)
-- --------------------------------------------------------------
PUBLIC FUNCTION calc_line_total(
                                p_qty DECIMAL, 
                                p_price DECIMAL,
                                p_disc DECIMAL,
                                p_vat DECIMAL) 
                                RETURNS DECIMAL
    DEFINE l_sub, l_disc_amt, l_vat_amt, l_total DECIMAL(15,2)

    LET l_sub = NVL(p_qty,0) * NVL(p_price,0)
    LET l_disc_amt = (NVL(p_disc,0) / 100) * l_sub
    LET l_sub = l_sub - l_disc_amt
    LET l_vat_amt = (NVL(p_vat,0) / 100) * l_sub
    LET l_total = l_sub + l_vat_amt

    RETURN l_total
END FUNCTION


-- --------------------------------------------------------------
-- Recalculate and update document totals dynamically
-- --------------------------------------------------------------
--PUBLIC FUNCTION recalc_doc_totals(p_doc_type STRING,
--                                  p_arr DYNAMIC ARRAY OF RECORD
--                                      qnty DECIMAL(15,2),
--                                      sell_price DECIMAL(15,2),
--                                      disc DECIMAL(15,2),
--                                      vat DECIMAL(15,2),
--                                      line_tot DECIMAL(15,2)
--                                  END RECORD,
--                                  p_hdr RECORD ,
--                                 p_hdr_id INTEGER)
--    DEFINE i INTEGER
--    DEFINE l_gross, l_vat, l_net DECIMAL(15,2)
--
--    LET l_gross, l_vat, l_net = 0, 0, 0
--
--    --get headear data
--    SELECT * FROM p_hdr WHERE id = prd_id
--
--    -- Iterate through all line records
--    FOR i = 1 TO p_arr.getLength()
--        LET p_arr[i].line_tot = calc_line_total(p_arr[i].qnty, p_arr[i].sell_price,
--                                                p_arr[i].disc, p_arr[i].vat)
--        LET l_net = l_net + (p_arr[i].qnty * p_arr[i].sell_price)
--        LET l_vat = l_vat + ((NVL(p_arr[i].vat,0) / 100) *
--                    ((p_arr[i].qnty * p_arr[i].sell_price) -
--                    ((NVL(p_arr[i].disc,0) / 100) * (p_arr[i].qnty * p_arr[i].sell_price))))
--        LET l_gross = l_gross + p_arr[i].line_tot
--    END FOR
--
--    -- Update header record (generic field names)
--    LET p_hdr.gross_tot = l_gross
--    LET p_hdr.vat = l_vat
--    LET p_hdr.net_tot = l_net
--
--    -- Log info for clarity (optional for dev)
--    CALL utils_globals.debug_log(
--        SFMT("[%1] Totals recalculated ? Net:%2 VAT:%3 Gross:%4",
--             p_doc_type, l_net, l_vat, l_gross)
--    )
--END FUNCTION
