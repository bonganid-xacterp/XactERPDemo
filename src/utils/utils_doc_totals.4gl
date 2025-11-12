-- ==============================================================
-- File      : utils_doc_totals.4gl
-- Purpose   : Shared totals calculation and header update
-- Version   : Genero 3.20.10
-- ==============================================================

IMPORT FGL utils_globals
SCHEMA demoappdb

-- ==============================================================
-- Function : calculate_line_total
-- Purpose  : Calculates totals for a single document line
-- ==============================================================
PUBLIC FUNCTION calculate_line_total(
        p_qty        DECIMAL(15,2),
        p_unit_price DECIMAL(15,2),
        p_disc_perc  DECIMAL(9,2),
        p_vat_rate   DECIMAL(9,2)
    )
    RETURNS DECIMAL

    DEFINE l_gross, l_disc_amt, l_vat_amt, l_net DECIMAL(15,2)

    LET l_gross    = NVL(p_qty,0) * NVL(p_unit_price,0)
    LET l_disc_amt = (l_gross * NVL(p_disc_perc,0)) / 100
    LET l_vat_amt  = ((l_gross - l_disc_amt) * NVL(p_vat_rate,0)) / 100
    LET l_net      = (l_gross - l_disc_amt) + l_vat_amt

    RETURN  l_net
END FUNCTION

-- ==============================================================
-- Function : calculate_line_totals
-- ==============================================================
FUNCTION calculate_line_totals(p_qnty DECIMAL, p_price DECIMAL,
                               p_disc_pct DECIMAL, p_vat_rate DECIMAL)
    RETURNS (DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL)

    DEFINE l_gross, l_disc, l_net, l_vat, l_total DECIMAL(15,2)

    -- Gross = Quantity � Price
    LET l_gross = p_qnty * p_price

    -- Discount = Gross � (Disc% / 100)
    LET l_disc = l_gross * (p_disc_pct / 100)

    -- Net = Gross - Discount
    LET l_net = l_gross - l_disc

    -- VAT = Net × (VAT% / 100)
    LET l_vat = l_net * (p_vat_rate / 100)

    -- Total = Net + VAT
    LET l_total = l_net + l_vat

    RETURN l_gross, l_disc, l_net, l_vat, l_total

END FUNCTION


-- ==============================================================
-- Function : calculate_doc_totals
-- Purpose  : Recalculate totals for any document array
-- ==============================================================

PUBLIC FUNCTION calculate_doc_totals(
                                    p_gross_amt DECIMAL, 
                                    p_disc_amt DECIMAL,
                                    p_vat_amt DECIMAL, 
                                    p_net_total DECIMAL)
                                    RETURNS (DECIMAL, DECIMAL, DECIMAL, DECIMAL)

    DEFINE l_gross, l_disc_tot, l_vat_tot DECIMAL(15,2)

    LET l_gross     = 0.00
    LET l_disc_tot  = 0.00
    LET l_vat_tot   = 0.00

    LET l_gross     = l_gross + NVL(p_gross_amt, 0)
    LET l_disc_tot  = l_disc_tot + NVL(p_disc_amt, 0)
    LET l_vat_tot   = l_vat_tot + NVL(p_vat_amt, 0)
    LET p_net_total = l_gross - l_disc_tot + l_vat_tot

    RETURN l_gross, l_disc_tot, l_vat_tot, p_net_total
    
END FUNCTION


-- ==============================================================
-- Function : update_doc_header_totals
-- Purpose  : Persist totals back to header table dynamically
-- ==============================================================

PUBLIC FUNCTION update_doc_header_totals(p_table STRING, p_id INTEGER,
                                         p_gross DECIMAL, p_disc DECIMAL,
                                         p_vat DECIMAL, p_net DECIMAL)
    DEFINE sql_stmt STRING

    LET sql_stmt = SFMT(
        "UPDATE %1 SET gross_tot=%2, disc=%3, vat=%4, net_tot=%5, updated_at=CURRENT WHERE id=%6",
        p_table, p_gross, p_disc, p_vat, p_net, p_id)

    BEGIN WORK
    TRY
        EXECUTE IMMEDIATE sql_stmt
        COMMIT WORK
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to update totals for %1: %2", p_table, SQLCA.SQLERRM))
    END TRY
END FUNCTION
