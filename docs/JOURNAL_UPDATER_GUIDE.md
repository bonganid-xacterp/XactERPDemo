# Global Journal Updater - Usage Guide

## Overview
The Global Journal Updater (`utils_global_journal_updater.4gl`) is a centralized utility for creating GL journal entries across the XactERP system. It ensures consistency in financial postings and maintains proper double-entry accounting.

## Features

### Core Capabilities
- ✓ Automatic double-entry validation (DR = CR)
- ✓ Account validation and existence checks
- ✓ Automatic journal number generation
- ✓ Transaction management (BEGIN/COMMIT/ROLLBACK)
- ✓ Comprehensive error handling
- ✓ Audit trail with user tracking
- ✓ Support for all major document types

### Safety Features
- Row-level account validation
- Double-entry balance checking
- Transaction rollback on error
- User-friendly error messages
- Status tracking (POSTED)

## Database Schema

### Tables Used

#### gl01_acc (Chart of Accounts)
```
id              - Account ID (Primary Key)
acc_code        - Account code (AR, AP, SALES, etc.)
acc_name        - Account name
acc_type        - Account type (Asset, Liability, Revenue, Expense)
is_parent       - Is parent account
parent_id       - Parent account ID
status          - ACTIVE/INACTIVE
```

#### gl30_jnls (Journal Headers)
```
id              - Journal ID (Primary Key)
jrn_no          - Journal number (JRN-YYYY-MM-NNNNNN)
trans_date      - Transaction date
ref_no          - Reference number
doc_type        - Document type (INV, CRN, GRN, etc.)
doc_no          - Document number
description     - Journal description
status          - POSTED/DRAFT
created_by      - User ID
created_at      - Created timestamp
```

#### gl31_lines (Journal Detail Lines)
```
id              - Line ID (Primary Key)
jrn_id          - Journal ID (Foreign Key)
line_no         - Line number
acc_id          - Account ID (Foreign Key to gl01_acc)
debit           - Debit amount
credit          - Credit amount
notes           - Line notes
```

## Functions

### 1. create_journal_entry()

**Main function for creating journal entries**

```4gl
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
```

**Parameters:**
- `p_doc_type` - Document type (INV, CRN, GRN, PINV, etc.)
- `p_doc_no` - Document number
- `p_trans_date` - Transaction date
- `p_description` - Journal description
- `p_entries` - Array of journal line entries

**Returns:**
- Journal ID if successful
- 0 if failed (error already displayed)

**Example:**
```4gl
DEFINE l_entries DYNAMIC ARRAY OF RECORD
    acc_id INTEGER,
    debit DECIMAL(15,2),
    credit DECIMAL(15,2),
    notes STRING
END RECORD

LET l_entries[1].acc_id = 101  -- AR account
LET l_entries[1].debit = 1500.00
LET l_entries[1].credit = 0.00
LET l_entries[1].notes = "Customer invoice"

LET l_entries[2].acc_id = 401  -- Sales account
LET l_entries[2].debit = 0.00
LET l_entries[2].credit = 1500.00
LET l_entries[2].notes = "Sales revenue"

LET l_jrn_id = utils_global_journal_updater.create_journal_entry(
    "INV", "INV-2025-00123", TODAY, "Sales Invoice", l_entries)
```

### 2. create_sales_invoice_journal()

**Specialized function for sales invoices**

```4gl
PUBLIC FUNCTION create_sales_invoice_journal(
    p_inv_id INTEGER,
    p_doc_no STRING,
    p_trans_date DATE,
    p_cust_id INTEGER,
    p_net_total DECIMAL(15,2)
) RETURNS INTEGER
```

**Journal Entry:**
- DR: Accounts Receivable (AR)
- CR: Sales Revenue (SALES)

**Example:**
```4gl
LET l_jrn_id = utils_global_journal_updater.create_sales_invoice_journal(
    l_invoice_id,
    "INV-2025-00123",
    TODAY,
    l_customer_id,
    1500.00
)
```

### 3. create_sales_credit_note_journal()

**Specialized function for sales credit notes**

```4gl
PUBLIC FUNCTION create_sales_credit_note_journal(
    p_crn_id INTEGER,
    p_doc_no STRING,
    p_trans_date DATE,
    p_cust_id INTEGER,
    p_net_total DECIMAL(15,2)
) RETURNS INTEGER
```

**Journal Entry:**
- DR: Sales Returns (SALES_RET)
- CR: Accounts Receivable (AR)

**Example:**
```4gl
LET l_jrn_id = utils_global_journal_updater.create_sales_credit_note_journal(
    l_crn_id,
    "CRN-2025-00012",
    TODAY,
    l_customer_id,
    500.00
)
```

### 4. create_purchase_invoice_journal()

**Specialized function for purchase invoices**

```4gl
PUBLIC FUNCTION create_purchase_invoice_journal(
    p_inv_id INTEGER,
    p_doc_no STRING,
    p_trans_date DATE,
    p_supp_id INTEGER,
    p_net_total DECIMAL(15,2)
) RETURNS INTEGER
```

**Journal Entry:**
- DR: Purchases (PURCH)
- CR: Accounts Payable (AP)

**Example:**
```4gl
LET l_jrn_id = utils_global_journal_updater.create_purchase_invoice_journal(
    l_invoice_id,
    "PINV-2025-00045",
    TODAY,
    l_supplier_id,
    2500.00
)
```

### 5. create_grn_journal()

**Specialized function for Goods Received Notes**

```4gl
PUBLIC FUNCTION create_grn_journal(
    p_grn_id INTEGER,
    p_doc_no STRING,
    p_trans_date DATE,
    p_supp_id INTEGER,
    p_net_total DECIMAL(15,2)
) RETURNS INTEGER
```

**Journal Entry:**
- DR: Inventory Asset (INV)
- CR: GRN Clearing/Accruals (GRN_CLR)

**Example:**
```4gl
LET l_jrn_id = utils_global_journal_updater.create_grn_journal(
    l_grn_id,
    "GRN-2025-00055",
    TODAY,
    l_supplier_id,
    2500.00
)
```

## Account Codes Configuration

### Required GL Accounts

The following account codes must exist in `gl01_acc` table:

| Code | Description | Type | Usage |
|------|-------------|------|-------|
| AR | Accounts Receivable | Asset | Customer invoices, credit notes |
| AP | Accounts Payable | Liability | Supplier invoices |
| SALES | Sales Revenue | Revenue | Customer invoices |
| SALES_RET | Sales Returns | Expense | Credit notes |
| PURCH | Purchases | Expense | Purchase invoices |
| INV | Inventory | Asset | GRN, stock receipts |
| GRN_CLR | GRN Clearing/Accruals | Liability | GRN clearing |

### Setup SQL

```sql
-- Insert standard chart of accounts
INSERT INTO gl01_acc (acc_code, acc_name, acc_type, is_parent, status)
VALUES ('AR', 'Accounts Receivable', 'Asset', FALSE, 'ACTIVE');

INSERT INTO gl01_acc (acc_code, acc_name, acc_type, is_parent, status)
VALUES ('AP', 'Accounts Payable', 'Liability', FALSE, 'ACTIVE');

INSERT INTO gl01_acc (acc_code, acc_name, acc_type, is_parent, status)
VALUES ('SALES', 'Sales Revenue', 'Revenue', FALSE, 'ACTIVE');

INSERT INTO gl01_acc (acc_code, acc_name, acc_type, is_parent, status)
VALUES ('SALES_RET', 'Sales Returns', 'Expense', FALSE, 'ACTIVE');

INSERT INTO gl01_acc (acc_code, acc_name, acc_type, is_parent, status)
VALUES ('PURCH', 'Purchases', 'Expense', FALSE, 'ACTIVE');

INSERT INTO gl01_acc (acc_code, acc_name, acc_type, is_parent, status)
VALUES ('INV', 'Inventory', 'Asset', FALSE, 'ACTIVE');

INSERT INTO gl01_acc (acc_code, acc_name, acc_type, is_parent, status)
VALUES ('GRN_CLR', 'GRN Clearing', 'Liability', FALSE, 'ACTIVE');
```

## Integration Examples

### Sales Invoice Module (sa132_invoice.4gl)

```4gl
IMPORT FGL utils_global_journal_updater

FUNCTION post_invoice(p_inv_id INTEGER)
    DEFINE l_jrn_id INTEGER

    BEGIN WORK
    TRY
        -- Update stock
        -- ... stock update code ...

        -- Update customer balance
        UPDATE dl01_mast SET balance = balance + m_inv_hdr.net_tot
         WHERE id = m_inv_hdr.cust_id

        -- Create journal entry
        LET l_jrn_id = utils_global_journal_updater.create_sales_invoice_journal(
            p_inv_id,
            m_inv_hdr.doc_no,
            m_inv_hdr.trans_date,
            m_inv_hdr.cust_id,
            m_inv_hdr.net_tot
        )

        IF l_jrn_id = 0 THEN
            ROLLBACK WORK
            RETURN FALSE
        END IF

        -- Update invoice status
        UPDATE sa32_inv_hdr SET status = "POSTED" WHERE id = p_inv_id

        COMMIT WORK
        RETURN TRUE

    CATCH
        ROLLBACK WORK
        RETURN FALSE
    END TRY
END FUNCTION
```

### Sales Credit Note Module (sa133_crn.4gl)

```4gl
IMPORT FGL utils_global_journal_updater

FUNCTION post_credit_note(p_crn_id INTEGER)
    DEFINE l_jrn_id INTEGER

    BEGIN WORK
    TRY
        -- Return stock
        -- ... stock return code ...

        -- Credit customer balance
        UPDATE dl01_mast SET balance = balance - m_crn_hdr.net_tot
         WHERE id = m_crn_hdr.cust_id

        -- Create journal entry
        LET l_jrn_id = utils_global_journal_updater.create_sales_credit_note_journal(
            p_crn_id,
            m_crn_hdr.doc_no,
            m_crn_hdr.trans_date,
            m_crn_hdr.cust_id,
            m_crn_hdr.net_tot
        )

        IF l_jrn_id = 0 THEN
            ROLLBACK WORK
            RETURN FALSE
        END IF

        -- Update credit note status
        UPDATE sa33_crn_hdr SET status = "POSTED" WHERE id = p_crn_id

        COMMIT WORK
        RETURN TRUE

    CATCH
        ROLLBACK WORK
        RETURN FALSE
    END TRY
END FUNCTION
```

### Purchase Invoice Module (pu132_inv.4gl)

```4gl
IMPORT FGL utils_global_journal_updater

FUNCTION post_purchase_invoice(p_inv_id INTEGER)
    DEFINE l_jrn_id INTEGER

    BEGIN WORK
    TRY
        -- Update supplier balance
        UPDATE cl01_mast SET balance = balance + m_inv_hdr.net_tot
         WHERE id = m_inv_hdr.supp_id

        -- Create journal entry
        LET l_jrn_id = utils_global_journal_updater.create_purchase_invoice_journal(
            p_inv_id,
            m_inv_hdr.doc_no,
            m_inv_hdr.trans_date,
            m_inv_hdr.supp_id,
            m_inv_hdr.net_tot
        )

        IF l_jrn_id = 0 THEN
            ROLLBACK WORK
            RETURN FALSE
        END IF

        -- Update invoice status
        UPDATE pu32_inv_hdr SET status = "POSTED" WHERE id = p_inv_id

        COMMIT WORK
        RETURN TRUE

    CATCH
        ROLLBACK WORK
        RETURN FALSE
    END TRY
END FUNCTION
```

## Error Handling

The journal updater handles errors automatically and displays user-friendly messages:

```4gl
IF l_jrn_id = 0 THEN
    -- Error already shown to user via utils_globals.show_error()
    -- Just handle the failure (e.g., rollback transaction)
    ROLLBACK WORK
    RETURN FALSE
END IF
```

### Common Error Messages
- "No journal entries provided" - Empty entries array
- "Journal out of balance: DR=X CR=Y" - Debits don't equal credits
- "Failed to generate journal number" - Journal number generation failed
- "Account ID X does not exist" - Invalid account ID
- "Failed to get GL account configuration" - Account code not found
- "Failed to create journal: [error]" - Database error

## Testing

### Unit Tests
1. Create journal with balanced entries
2. Create journal with unbalanced entries (should fail)
3. Create journal with invalid account ID (should fail)
4. Create sales invoice journal
5. Create credit note journal
6. Create purchase invoice journal
7. Create GRN journal
8. Verify double-entry posting
9. Verify journal number generation
10. Verify error handling and rollback

### Integration Tests
1. Post sales invoice and verify journal
2. Post credit note and verify journal
3. Post purchase invoice and verify journal
4. Post GRN and verify journal
5. Verify all GL accounts updated correctly

## Benefits

### For Developers
- ✓ Single function call for journal creation
- ✓ No need to worry about double-entry validation
- ✓ Automatic account validation
- ✓ Consistent error handling
- ✓ Less code to write and maintain

### For Business
- ✓ Accurate financial records
- ✓ Proper double-entry accounting
- ✓ Complete audit trail
- ✓ Consistent GL postings across modules
- ✓ Easier reconciliation

### For Auditors
- ✓ Every transaction has journal entry
- ✓ Clear audit trail with user tracking
- ✓ Proper document references
- ✓ Status tracking (POSTED)
- ✓ Timestamp tracking

## Compilation

```batch
fglcomp -M src\utils\utils_global_journal_updater.4gl -o bin\utils_global_journal_updater.42m
```

## Files

```
Source:     src/utils/utils_global_journal_updater.4gl
Binary:     bin/utils_global_journal_updater.42m
Guide:      docs/JOURNAL_UPDATER_GUIDE.md
Reference:  docs/JOURNAL_UPDATER_QUICK_REF.txt
```

## Version History

### v1.0.0 - 2025-01-25
- Initial release
- Core functionality: create_journal_entry()
- Specialized functions: sales invoice, credit note, purchase invoice, GRN
- Helper functions: account validation, journal number generation
- Complete documentation

## Support

For questions or issues:
1. Check this guide
2. Review the quick reference
3. Contact: Development Team

---
**Module:** utils_global_journal_updater
**Status:** Production Ready ✓
**Last Updated:** 2025-01-25
**Maintained By:** Development Team
