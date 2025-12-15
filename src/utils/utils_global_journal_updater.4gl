-- ==============================================================
-- File       : utils_global_journal_updater.4gl
-- Description: Global centralized journal entry management
-- Author     : Development Team
-- Created    : 2025-01-25
-- Version    : 1.0.0
-- ==============================================================
-- Purpose:
--   Provides centralized journal entry creation for all financial
--   transactions across the XactERP system. Ensures consistency
--   in GL posting and maintains proper double-entry accounting.
-- ==============================================================

IMPORT FGL utils_globals

-- ==============================================================
-- PUBLIC FUNCTIONS
-- ==============================================================

-- --------------------------------------------------------------
-- Function   : create_journal_entry
-- Description: Main function to create a journal entry
-- Parameters : p_doc_type     - Document type (INV, CRN, GRN, etc.)
--             p_doc_no       - Document number
--             p_trans_date   - Transaction date
--             p_description  - Journal description
--             p_entries      - Array of journal line entries
-- Returns    : Journal ID if successful, 0 if failed
-- --------------------------------------------------------------
PUBLIC FUNCTION create_journal_entry(
    p_doc_type STRING,
    p_doc_no STRING,
    p_trans_date DATE,
    p_description STRING,
    p_entries DYNAMIC ARRAY OF RECORD
        acc_id INTEGER,
        debit DECIMAL(15,2),
        credit DECIMAL(15,2),
        notes STRING
    END RECORD
) RETURNS INTEGER

    DEFINE l_jrn_id INTEGER
    DEFINE l_jrn_no STRING
    DEFINE l_total_dr DECIMAL(15,2)
    DEFINE l_total_cr DECIMAL(15,2)
    DEFINE i INTEGER
    DEFINE l_user_id INTEGER
    DEFINE l_status SMALLINT

    -- Validate inputs
    IF p_entries.getLength() = 0 THEN
        CALL utils_globals.show_error("No journal entries provided")
        RETURN 0
    END IF

    -- Calculate totals
    LET l_total_dr = 0
    LET l_total_cr = 0
    FOR i = 1 TO p_entries.getLength()
        LET l_total_dr = l_total_dr + p_entries[i].debit
        LET l_total_cr = l_total_cr + p_entries[i].credit
    END FOR

    -- Validate double-entry (debits must equal credits)
    IF l_total_dr != l_total_cr THEN
        CALL utils_globals.show_error(SFMT("Journal out of balance: DR=%1 CR=%2",
            l_total_dr, l_total_cr))
        RETURN 0
    END IF

    -- Get user ID
    LET l_user_id = utils_globals.get_current_user_id()

    -- Generate journal number
    LET l_jrn_no = generate_journal_number(p_doc_type)
    IF l_jrn_no IS NULL OR l_jrn_no = "" THEN
        CALL utils_globals.show_error("Failed to generate journal number")
        RETURN 0
    END IF

    -- Start transaction
    BEGIN WORK

    TRY
        -- Insert journal header
        INSERT INTO gl30_jnls (
            jrn_no,
            trans_date,
            ref_no,
            doc_type,
            doc_no,
            description,
            status,
            created_by,
            created_at
        ) VALUES (
            l_jrn_no,
            p_trans_date,
            p_doc_no,
            p_doc_type,
            p_doc_no,
            p_description,
            "POSTED",
            l_user_id,
            CURRENT
        )

        LET l_jrn_id = SQLCA.SQLERRD[2]

        -- Insert journal lines
        FOR i = 1 TO p_entries.getLength()
            -- Validate account exists
            IF NOT validate_account_exists(p_entries[i].acc_id) THEN
                CALL utils_globals.show_error(SFMT("Account ID %1 does not exist",
                    p_entries[i].acc_id))
                ROLLBACK WORK
                RETURN 0
            END IF

            INSERT INTO gl31_lines (
                jrn_id,
                line_no,
                acc_id,
                debit,
                credit,
                notes
            ) VALUES (
                l_jrn_id,
                i,
                p_entries[i].acc_id,
                p_entries[i].debit,
                p_entries[i].credit,
                p_entries[i].notes
            )
        END FOR

        COMMIT WORK
        RETURN l_jrn_id

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(SFMT("Failed to create journal: %1", SQLCA.SQLERRM))
        RETURN 0
    END TRY

END FUNCTION

-- --------------------------------------------------------------
-- Function   : create_sales_invoice_journal
-- Description: Create journal entry for sales invoice
-- Parameters : p_inv_id       - Invoice ID
--             p_doc_no       - Invoice document number
--             p_trans_date   - Invoice date
--             p_cust_id      - Customer ID
--             p_net_total    - Net invoice amount
-- Returns    : Journal ID if successful, 0 if failed
-- Notes      : DR: Accounts Receivable, CR: Sales Revenue
-- --------------------------------------------------------------
PUBLIC FUNCTION create_sales_invoice_journal(
    p_inv_id INTEGER,
    p_doc_no STRING,
    p_trans_date DATE,
    p_cust_id INTEGER,
    p_net_total DECIMAL(15,2)
) RETURNS INTEGER

    DEFINE l_entries DYNAMIC ARRAY OF RECORD
        acc_id INTEGER,
        debit DECIMAL(15,2),
        credit DECIMAL(15,2),
        notes STRING
    END RECORD
    DEFINE l_ar_acc_id INTEGER
    DEFINE l_sales_acc_id INTEGER
    DEFINE l_description STRING

    -- Get account IDs from configuration
    LET l_ar_acc_id = get_account_id("AR")  -- Accounts Receivable
    LET l_sales_acc_id = get_account_id("SALES")  -- Sales Revenue

    IF l_ar_acc_id = 0 OR l_sales_acc_id = 0 THEN
        CALL utils_globals.show_error("Failed to get GL account configuration for sales invoice")
        RETURN 0
    END IF

    -- Build journal entries
    LET l_entries[1].acc_id = l_ar_acc_id
    LET l_entries[1].debit = p_net_total
    LET l_entries[1].credit = 0.00
    LET l_entries[1].notes = SFMT("Invoice %1 - Customer ID %2", p_doc_no, p_cust_id)

    LET l_entries[2].acc_id = l_sales_acc_id
    LET l_entries[2].debit = 0.00
    LET l_entries[2].credit = p_net_total
    LET l_entries[2].notes = SFMT("Invoice %1 - Sales Revenue", p_doc_no)

    LET l_description = SFMT("Sales Invoice %1", p_doc_no)

    RETURN create_journal_entry("INV", p_doc_no, p_trans_date, l_description, l_entries)

END FUNCTION

-- --------------------------------------------------------------
-- Function   : create_sales_credit_note_journal
-- Description: Create journal entry for sales credit note
-- Parameters : p_crn_id       - Credit note ID
--             p_doc_no       - Credit note document number
--             p_trans_date   - Credit note date
--             p_cust_id      - Customer ID
--             p_net_total    - Net credit amount
-- Returns    : Journal ID if successful, 0 if failed
-- Notes      : DR: Sales Returns, CR: Accounts Receivable
-- --------------------------------------------------------------
PUBLIC FUNCTION create_sales_credit_note_journal(
    p_crn_id INTEGER,
    p_doc_no STRING,
    p_trans_date DATE,
    p_cust_id INTEGER,
    p_net_total DECIMAL(15,2)
) RETURNS INTEGER

    DEFINE l_entries DYNAMIC ARRAY OF RECORD
        acc_id INTEGER,
        debit DECIMAL(15,2),
        credit DECIMAL(15,2),
        notes STRING
    END RECORD
    DEFINE l_ar_acc_id INTEGER
    DEFINE l_sales_ret_acc_id INTEGER
    DEFINE l_description STRING

    -- Get account IDs from configuration
    LET l_ar_acc_id = get_account_id("AR")  -- Accounts Receivable
    LET l_sales_ret_acc_id = get_account_id("SALES_RET")  -- Sales Returns

    IF l_ar_acc_id = 0 OR l_sales_ret_acc_id = 0 THEN
        CALL utils_globals.show_error("Failed to get GL account configuration for credit note")
        RETURN 0
    END IF

    -- Build journal entries (reverse of invoice)
    LET l_entries[1].acc_id = l_sales_ret_acc_id
    LET l_entries[1].debit = p_net_total
    LET l_entries[1].credit = 0.00
    LET l_entries[1].notes = SFMT("Credit Note %1 - Sales Returns", p_doc_no)

    LET l_entries[2].acc_id = l_ar_acc_id
    LET l_entries[2].debit = 0.00
    LET l_entries[2].credit = p_net_total
    LET l_entries[2].notes = SFMT("Credit Note %1 - Customer ID %2", p_doc_no, p_cust_id)

    LET l_description = SFMT("Sales Credit Note %1", p_doc_no)

    RETURN create_journal_entry("CRN", p_doc_no, p_trans_date, l_description, l_entries)

END FUNCTION

-- --------------------------------------------------------------
-- Function   : create_purchase_invoice_journal
-- Description: Create journal entry for purchase invoice
-- Parameters : p_inv_id       - Invoice ID
--             p_doc_no       - Invoice document number
--             p_trans_date   - Invoice date
--             p_supp_id      - Supplier ID
--             p_net_total    - Net invoice amount
-- Returns    : Journal ID if successful, 0 if failed
-- Notes      : DR: Purchases, CR: Accounts Payable
-- --------------------------------------------------------------
PUBLIC FUNCTION create_purchase_invoice_journal(
    p_inv_id INTEGER,
    p_doc_no STRING,
    p_trans_date DATE,
    p_supp_id INTEGER,
    p_net_total DECIMAL(15,2)
) RETURNS INTEGER

    DEFINE l_entries DYNAMIC ARRAY OF RECORD
        acc_id INTEGER,
        debit DECIMAL(15,2),
        credit DECIMAL(15,2),
        notes STRING
    END RECORD
    DEFINE l_ap_acc_id INTEGER
    DEFINE l_purch_acc_id INTEGER
    DEFINE l_description STRING

    -- Get account IDs from configuration
    LET l_ap_acc_id = get_account_id("AP")  -- Accounts Payable
    LET l_purch_acc_id = get_account_id("PURCH")  -- Purchases

    IF l_ap_acc_id = 0 OR l_purch_acc_id = 0 THEN
        CALL utils_globals.show_error("Failed to get GL account configuration for purchase invoice")
        RETURN 0
    END IF

    -- Build journal entries
    LET l_entries[1].acc_id = l_purch_acc_id
    LET l_entries[1].debit = p_net_total
    LET l_entries[1].credit = 0.00
    LET l_entries[1].notes = SFMT("Purchase Invoice %1", p_doc_no)

    LET l_entries[2].acc_id = l_ap_acc_id
    LET l_entries[2].debit = 0.00
    LET l_entries[2].credit = p_net_total
    LET l_entries[2].notes = SFMT("Invoice %1 - Supplier ID %2", p_doc_no, p_supp_id)

    LET l_description = SFMT("Purchase Invoice %1", p_doc_no)

    RETURN create_journal_entry("PINV", p_doc_no, p_trans_date, l_description, l_entries)

END FUNCTION

-- --------------------------------------------------------------
-- Function   : create_grn_journal
-- Description: Create journal entry for GRN (Goods Received)
-- Parameters : p_grn_id       - GRN ID
--             p_doc_no       - GRN document number
--             p_trans_date   - GRN date
--             p_supp_id      - Supplier ID
--             p_net_total    - Net GRN amount
-- Returns    : Journal ID if successful, 0 if failed
-- Notes      : DR: Inventory, CR: GRN Clearing/Accruals
-- --------------------------------------------------------------
PUBLIC FUNCTION create_grn_journal(
    p_grn_id INTEGER,
    p_doc_no STRING,
    p_trans_date DATE,
    p_supp_id INTEGER,
    p_net_total DECIMAL(15,2)
) RETURNS INTEGER

    DEFINE l_entries DYNAMIC ARRAY OF RECORD
        acc_id INTEGER,
        debit DECIMAL(15,2),
        credit DECIMAL(15,2),
        notes STRING
    END RECORD
    DEFINE l_inv_acc_id INTEGER
    DEFINE l_grn_acc_id INTEGER
    DEFINE l_description STRING

    -- Get account IDs from configuration
    LET l_inv_acc_id = get_account_id("INV")  -- Inventory Asset
    LET l_grn_acc_id = get_account_id("GRN_CLR")  -- GRN Clearing/Accruals

    IF l_inv_acc_id = 0 OR l_grn_acc_id = 0 THEN
        CALL utils_globals.show_error("Failed to get GL account configuration for GRN")
        RETURN 0
    END IF

    -- Build journal entries
    LET l_entries[1].acc_id = l_inv_acc_id
    LET l_entries[1].debit = p_net_total
    LET l_entries[1].credit = 0.00
    LET l_entries[1].notes = SFMT("GRN %1 - Inventory Received", p_doc_no)

    LET l_entries[2].acc_id = l_grn_acc_id
    LET l_entries[2].debit = 0.00
    LET l_entries[2].credit = p_net_total
    LET l_entries[2].notes = SFMT("GRN %1 - Supplier ID %2", p_doc_no, p_supp_id)

    LET l_description = SFMT("Goods Received Note %1", p_doc_no)

    RETURN create_journal_entry("GRN", p_doc_no, p_trans_date, l_description, l_entries)

END FUNCTION

-- ==============================================================
-- PRIVATE HELPER FUNCTIONS
-- ==============================================================

-- --------------------------------------------------------------
-- Function   : generate_journal_number
-- Description: Generate next journal number
-- Parameters : p_doc_type - Document type
-- Returns    : Journal number or NULL if failed
-- --------------------------------------------------------------
PRIVATE FUNCTION generate_journal_number(p_doc_type STRING) RETURNS STRING
    DEFINE l_jrn_no STRING
    DEFINE l_next_no INTEGER
    DEFINE l_year STRING
    DEFINE l_month STRING

    -- Get current year and month
    LET l_year = YEAR(TODAY) USING "####"
    LET l_month = MONTH(TODAY) USING "&&"

    -- Get next number from sequence
    -- For simplicity, we'll use a simple counter based on existing records
    TRY
        SELECT COUNT(*) + 1 INTO l_next_no FROM gl30_jnls
         WHERE jrn_no MATCHES SFMT("JRN-%1-%2-*", l_year, l_month)

        IF l_next_no IS NULL THEN
            LET l_next_no = 1
        END IF

        LET l_jrn_no = SFMT("JRN-%1-%2-%3", l_year, l_month,
            l_next_no USING "<<<<<&")

        RETURN l_jrn_no

    CATCH
        RETURN NULL
    END TRY

END FUNCTION

-- --------------------------------------------------------------
-- Function   : get_account_id
-- Description: Get GL account ID by account code
-- Parameters : p_acc_code - Account code (AR, AP, SALES, etc.)
-- Returns    : Account ID or 0 if not found
-- --------------------------------------------------------------
PRIVATE FUNCTION get_account_id(p_acc_code STRING) RETURNS INTEGER
    DEFINE l_acc_id INTEGER

    TRY
        SELECT id INTO l_acc_id FROM gl01_acc
         WHERE acc_code = p_acc_code
           AND status = "ACTIVE"

        IF l_acc_id IS NULL THEN
            RETURN 0
        END IF

        RETURN l_acc_id

    CATCH
        RETURN 0
    END TRY

END FUNCTION

-- --------------------------------------------------------------
-- Function   : validate_account_exists
-- Description: Check if account ID exists and is active
-- Parameters : p_acc_id - Account ID to validate
-- Returns    : TRUE if exists and active, FALSE otherwise
-- --------------------------------------------------------------
PRIVATE FUNCTION validate_account_exists(p_acc_id INTEGER) RETURNS SMALLINT
    DEFINE l_count INTEGER

    TRY
        SELECT COUNT(*) INTO l_count FROM gl01_acc
         WHERE id = p_acc_id
           AND status = "ACTIVE"

        RETURN (l_count > 0)

    CATCH
        RETURN FALSE
    END TRY

END FUNCTION
