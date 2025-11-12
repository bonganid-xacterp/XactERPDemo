# ==============================================================
# Program   :   cl30_trans.4gl
# Purpose   :   Creditors transactions
# Module    :   Creditors Transactions (cl)
# Number    :   30
# Author    :   Bongani Dlamini
# Version   :   Genero ver 3.20.10
# ==============================================================

IMPORT FGL utils_globals

SCHEMA demoappdb

TYPE cl_trans_t RECORD LIKE cl30_trans.*

DEFINE m_cl_trans cl_trans_t

FUNCTION show_cl_trans()

    -- Set page title (top bar, if defined in form)

END FUNCTION

FUNCTION add_transaction(p_id INTEGER)
    DEFINE l_po_hdr RECORD LIKE pu30_ord_hdr.*

    -- Lookup order header
    SELECT * INTO l_po_hdr.* FROM pu30_ord_hdr WHERE id = p_id

    IF SQLCA.SQLCODE != 0 THEN
        CALL utils_globals.show_error("Purchase order not found.")
        RETURN
    END IF

    -- Initialize transaction record
    INITIALIZE m_cl_trans.* TO NULL

    -- Populate transaction record
    LET m_cl_trans.supp_id      = l_po_hdr.supp_id
    LET m_cl_trans.trans_date   = l_po_hdr.trans_date
    LET m_cl_trans.doc_no       = l_po_hdr.doc_no
    LET m_cl_trans.doc_type     = "PO"
    LET m_cl_trans.gross_tot    = l_po_hdr.gross_tot
    LET m_cl_trans.disc_tot     = l_po_hdr.disc_tot
    LET m_cl_trans.vat_tot      = l_po_hdr.vat_tot
    LET m_cl_trans.net_tot      = l_po_hdr.net_tot
    LET m_cl_trans.notes        = l_po_hdr.notes

    -- Insert transaction
    TRY
        INSERT INTO cl30_trans VALUES (m_cl_trans.*)
        DISPLAY "Creditor transaction created: ", m_cl_trans.doc_no
    CATCH
        CALL utils_globals.show_error("Failed to create creditor transaction:\n" || SQLCA.SQLERRM)
    END TRY

END FUNCTION
