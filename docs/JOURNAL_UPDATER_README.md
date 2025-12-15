# Global Journal Updater Module

## Summary
A centralized, enterprise-grade GL journal entry utility for the entire XactERP system. Provides consistent financial posting across all modules including Sales, Purchases, Inventory, and POS transactions with automatic double-entry validation.

## What Was Created

### 1. Core Module
**File:** `src/utils/utils_global_journal_updater.4gl`
- Main journal entry utility with 5 public functions
- Automatic double-entry validation (DR = CR)
- Account existence validation
- Transaction management with rollback
- Automatic journal number generation
- Complete audit trail with user tracking

### 2. Documentation
**Files:**
- `docs/JOURNAL_UPDATER_GUIDE.md` - Complete usage guide with examples
- `docs/JOURNAL_UPDATER_QUICK_REF.txt` - Quick reference card
- `docs/JOURNAL_UPDATER_README.md` - This file

### 3. Integration
**Integrated into:**
- `src/sa/sa133_crn.4gl` - Sales Credit Note module (complete)
- Ready for integration into other modules (sa132_invoice, pu132_inv, etc.)

## Key Features

### Simplicity ✓
- One function call for each transaction type
- Consistent interface across all modules
- Clear, self-documenting function names
- Automatic error display

### Safety ✓
- Automatic double-entry validation
- Account existence checks
- Transaction management (BEGIN/COMMIT/ROLLBACK)
- Comprehensive error handling
- Prevents unbalanced entries

### Consistency ✓
- Standard journal entries for all transactions
- Proper GL account usage
- Consistent journal number format
- Audit trail with user tracking

### Traceability ✓
- All entries recorded in gl30_jnls/gl31_lines
- Document reference tracking (doc_type, doc_no)
- Timestamp and user tracking
- Status management (POSTED)

## Functions Overview

| Function | Use Case | Complexity |
|----------|----------|------------|
| `create_sales_invoice_journal()` | Sales invoices | ⭐ Simple |
| `create_sales_credit_note_journal()` | Credit notes | ⭐ Simple |
| `create_purchase_invoice_journal()` | Purchase invoices | ⭐ Simple |
| `create_grn_journal()` | Goods received | ⭐ Simple |
| `create_journal_entry()` | Custom entries | ⭐⭐ Medium |

## Quick Start

### Import the Module
```4gl
IMPORT FGL utils_global_journal_updater
```

### Basic Usage - Sales Invoice
```4gl
LET l_jrn_id = utils_global_journal_updater.create_sales_invoice_journal(
    l_inv_id,      -- Invoice ID
    l_doc_no,      -- Invoice number
    l_trans_date,  -- Invoice date
    l_cust_id,     -- Customer ID
    l_net_total    -- Net amount
)

IF l_jrn_id = 0 THEN
    -- Error already shown, handle failure
    ROLLBACK WORK
    RETURN FALSE
END IF
```

### Basic Usage - Credit Note
```4gl
LET l_jrn_id = utils_global_journal_updater.create_sales_credit_note_journal(
    l_crn_id,      -- Credit note ID
    l_doc_no,      -- Credit note number
    l_trans_date,  -- Credit note date
    l_cust_id,     -- Customer ID
    l_net_total    -- Net amount
)

IF l_jrn_id = 0 THEN
    ROLLBACK WORK
    RETURN FALSE
END IF
```

## Journal Entries Generated

### Sales Invoice
```
DR: Accounts Receivable (AR)    1,500.00
CR: Sales Revenue (SALES)                  1,500.00
```

### Sales Credit Note
```
DR: Sales Returns (SALES_RET)     500.00
CR: Accounts Receivable (AR)                500.00
```

### Purchase Invoice
```
DR: Purchases (PURCH)           2,500.00
CR: Accounts Payable (AP)                 2,500.00
```

### Goods Received Note (GRN)
```
DR: Inventory (INV)             2,500.00
CR: GRN Clearing (GRN_CLR)                2,500.00
```

## Required GL Account Setup

Before using the journal updater, ensure these accounts exist in `gl01_acc`:

```sql
INSERT INTO gl01_acc (acc_code, acc_name, acc_type, status)
VALUES ('AR', 'Accounts Receivable', 'Asset', 'ACTIVE');

INSERT INTO gl01_acc (acc_code, acc_name, acc_type, status)
VALUES ('AP', 'Accounts Payable', 'Liability', 'ACTIVE');

INSERT INTO gl01_acc (acc_code, acc_name, acc_type, status)
VALUES ('SALES', 'Sales Revenue', 'Revenue', 'ACTIVE');

INSERT INTO gl01_acc (acc_code, acc_name, acc_type, status)
VALUES ('SALES_RET', 'Sales Returns', 'Expense', 'ACTIVE');

INSERT INTO gl01_acc (acc_code, acc_name, acc_type, status)
VALUES ('PURCH', 'Purchases', 'Expense', 'ACTIVE');

INSERT INTO gl01_acc (acc_code, acc_name, acc_type, status)
VALUES ('INV', 'Inventory', 'Asset', 'ACTIVE');

INSERT INTO gl01_acc (acc_code, acc_name, acc_type, status)
VALUES ('GRN_CLR', 'GRN Clearing', 'Liability', 'ACTIVE');
```

## Integration Pattern

### Standard Transaction Posting
```4gl
IMPORT FGL utils_global_journal_updater

FUNCTION post_document(p_doc_id INTEGER)
    DEFINE l_jrn_id INTEGER

    BEGIN WORK
    TRY
        -- 1. Update stock/balances
        -- ... business logic ...

        -- 2. Create journal entry
        LET l_jrn_id = utils_global_journal_updater.create_xxx_journal(...)

        IF l_jrn_id = 0 THEN
            ROLLBACK WORK
            RETURN FALSE
        END IF

        -- 3. Update document status
        UPDATE xxx_hdr SET status = "POSTED" WHERE id = p_doc_id

        COMMIT WORK
        RETURN TRUE

    CATCH
        ROLLBACK WORK
        RETURN FALSE
    END TRY
END FUNCTION
```

## Database Schema

### gl30_jnls (Journal Headers)
```
id              INTEGER       - Primary Key
jrn_no          VARCHAR(30)   - Journal number (JRN-YYYY-MM-NNNNNN)
trans_date      DATE          - Transaction date
ref_no          VARCHAR(30)   - Reference number
doc_type        VARCHAR(20)   - Document type (INV, CRN, GRN, etc.)
doc_no          VARCHAR(30)   - Document number
description     VARCHAR(200)  - Journal description
status          VARCHAR(20)   - POSTED/DRAFT
created_by      INTEGER       - User ID
created_at      DATETIME      - Created timestamp
```

### gl31_lines (Journal Detail Lines)
```
id              INTEGER       - Primary Key
jrn_id          INTEGER       - Journal ID (FK)
line_no         SMALLINT      - Line number
acc_id          INTEGER       - Account ID (FK to gl01_acc)
debit           DECIMAL(15,2) - Debit amount
credit          DECIMAL(15,2) - Credit amount
notes           VARCHAR(200)  - Line notes
```

## Integration Status

### Completed ✓
- Sales Credit Note (sa133_crn.4gl)

### Pending
- Sales Invoice (sa132_invoice.4gl)
- Sales Order (sa131_order.4gl)
- Purchase Invoice (pu132_inv.4gl)
- Goods Received Note (pu131_grn.4gl)
- Point of Sale (pos modules)

## Benefits

### For Developers
- ✓ Write less code (1 function call vs 20+ lines)
- ✓ No need to worry about double-entry validation
- ✓ Automatic error handling
- ✓ Consistent across all modules
- ✓ Less testing required

### For Business
- ✓ Accurate financial records
- ✓ Proper double-entry accounting
- ✓ Complete audit trail
- ✓ Easier reconciliation
- ✓ Financial compliance

### For Auditors
- ✓ Every transaction has journal entry
- ✓ Clear audit trail
- ✓ Proper document references
- ✓ Timestamp tracking
- ✓ User accountability

### For Maintenance
- ✓ Single point of change
- ✓ Easier bug fixes
- ✓ Better code reuse
- ✓ Improved testability

## Testing

### Unit Tests
1. Create balanced journal entry
2. Reject unbalanced journal entry
3. Validate account existence
4. Generate journal numbers
5. Create sales invoice journal
6. Create credit note journal
7. Create purchase invoice journal
8. Create GRN journal
9. Verify error handling
10. Verify rollback on failure

### Integration Tests
1. Post sales invoice and verify journal
2. Post credit note and verify journal
3. Post purchase invoice and verify journal
4. Post GRN and verify journal
5. Verify GL accounts updated correctly
6. Verify audit trail complete

## Compilation

```batch
fglcomp -M src\utils\utils_global_journal_updater.4gl -o bin\utils_global_journal_updater.42m
```

Status: ✓ Compiled successfully

## Files Location

```
src/utils/utils_global_journal_updater.4gl    - Source code
bin/utils_global_journal_updater.42m          - Compiled module
docs/JOURNAL_UPDATER_GUIDE.md                 - Complete guide
docs/JOURNAL_UPDATER_QUICK_REF.txt            - Quick reference
docs/JOURNAL_UPDATER_README.md                - This file
```

## Support

For questions or issues:
1. Check the [Usage Guide](JOURNAL_UPDATER_GUIDE.md)
2. Review the [Quick Reference](JOURNAL_UPDATER_QUICK_REF.txt)
3. Contact: Development Team

## Version History

### v1.0.0 - 2025-01-25
- Initial release
- Core functionality: create_journal_entry()
- Specialized functions: sales invoice, credit note, purchase invoice, GRN
- Helper functions: account validation, journal number generation
- Complete documentation and integration into sa133_crn.4gl

## License
Internal use - XactERP System

---
**Module:** utils_global_journal_updater
**Status:** Production Ready ✓
**Last Updated:** 2025-01-25
**Maintained By:** Development Team
