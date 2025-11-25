# Global Stock Updater - Usage Guide

## Overview
The `utils_global_stock_updater` module provides a centralized, consistent way to update stock levels across all modules in the system.

## Features
- ✓ Thread-safe with row-level locking
- ✓ Automatic stock validation (prevents negative stock)
- ✓ Transaction recording in st30_trans
- ✓ Support for batch/expiry tracking
- ✓ Support for costing information
- ✓ Simple and advanced interfaces
- ✓ Comprehensive error handling

## Import Statement
```4gl
IMPORT FGL utils_global_stock_updater
```

## Functions Available

### 1. update_stock_simple() - Most Common
**Use this for basic stock updates**

```4gl
DEFINE l_success SMALLINT

LET l_success = utils_global_stock_updater.update_stock_simple(
    l_stock_id,    -- Stock ID
    l_quantity,    -- Quantity
    "OUT",         -- Direction: "IN" or "OUT"
    "INV"          -- Document type
)

IF NOT l_success THEN
    -- Handle error (error message already shown)
    RETURN
END IF
```

**Document Types:**
- `PO` - Purchase Order
- `GRN` - Goods Received Note
- `SO` - Sales Order
- `INV` - Invoice
- `CRN` - Credit Note
- `TRF` - Warehouse Transfer
- `BIN` - Bin Transaction
- `POS` - Point of Sale

### 2. update_stock_with_cost() - For Purchases/Sales
**Use this when you need to record costs and prices**

```4gl
LET l_success = utils_global_stock_updater.update_stock_with_cost(
    l_stock_id,     -- Stock ID
    l_quantity,     -- Quantity
    "IN",           -- Direction
    "GRN",          -- Document type
    l_doc_no,       -- Document number (e.g., "GRN-00123")
    l_unit_cost,    -- Unit cost
    l_sell_price    -- Selling price
)
```

### 3. update_stock_with_batch() - For Batch-Controlled Items
**Use this for items with batch/expiry tracking**

```4gl
LET l_success = utils_global_stock_updater.update_stock_with_batch(
    l_stock_id,     -- Stock ID
    l_quantity,     -- Quantity
    "IN",           -- Direction
    "GRN",          -- Document type
    l_doc_no,       -- Document number
    l_batch_id,     -- Batch ID (e.g., "BATCH-2025-001")
    l_expiry_date   -- Expiry date
)
```

### 4. update_stock() - Full Control
**Use this when you need all options**

```4gl
LET l_success = utils_global_stock_updater.update_stock(
    l_stock_id,     -- Stock ID
    l_quantity,     -- Quantity
    "OUT",          -- Direction
    "INV",          -- Document type
    l_doc_no,       -- Document number
    "Customer XYZ", -- Notes
    l_batch_id,     -- Batch ID
    l_expiry_date,  -- Expiry date
    l_unit_cost,    -- Unit cost
    l_sell_price    -- Sell price
)
```

### 5. check_stock_availability() - Pre-validation
**Check stock before processing**

```4gl
IF NOT utils_global_stock_updater.check_stock_availability(l_stock_id, l_required_qty) THEN
    -- Error message already shown
    RETURN
END IF

-- Proceed with order/sale
```

### 6. get_current_stock() - Query Stock Level
**Get current stock on hand**

```4gl
DEFINE l_current_stock DECIMAL

LET l_current_stock = utils_global_stock_updater.get_current_stock(l_stock_id)

IF l_current_stock IS NULL THEN
    CALL utils_globals.show_error("Failed to retrieve stock level")
END IF
```

## Usage Examples by Module

### Sales Invoice (sa132_invoice)
```4gl
IMPORT FGL utils_global_stock_updater

PRIVATE FUNCTION post_invoice()
    DEFINE l_line_count INTEGER
    DEFINE i INTEGER

    -- Loop through invoice lines
    FOR i = 1 TO l_line_count
        -- Update stock for each line
        IF NOT utils_global_stock_updater.update_stock_with_cost(
            mr_lines[i].stock_id,
            mr_lines[i].qnty,
            "OUT",
            "INV",
            mr_hdr.doc_no,
            mr_lines[i].unit_cost,
            mr_lines[i].sell_price
        ) THEN
            -- Rollback and exit
            RETURN FALSE
        END IF
    END FOR

    RETURN TRUE
END FUNCTION
```

### GRN (pu131_grn)
```4gl
IMPORT FGL utils_global_stock_updater

PRIVATE FUNCTION post_grn()
    -- Update stock with batch tracking
    IF NOT utils_global_stock_updater.update_stock_with_batch(
        l_stock_id,
        l_received_qty,
        "IN",
        "GRN",
        mr_hdr.doc_no,
        l_batch_no,
        l_expiry_date
    ) THEN
        RETURN FALSE
    END IF

    RETURN TRUE
END FUNCTION
```

### Warehouse Transfer (wh130_stock_trf)
```4gl
IMPORT FGL utils_global_stock_updater

PRIVATE FUNCTION process_transfer()
    -- Transfer OUT from source warehouse
    IF NOT utils_global_stock_updater.update_stock_simple(
        l_stock_id,
        l_transfer_qty,
        "OUT",
        "TRF"
    ) THEN
        RETURN FALSE
    END IF

    -- Transfer IN to destination warehouse
    IF NOT utils_global_stock_updater.update_stock_simple(
        l_stock_id,
        l_transfer_qty,
        "IN",
        "TRF"
    ) THEN
        RETURN FALSE
    END IF

    RETURN TRUE
END FUNCTION
```

### Credit Note (sa133_crn)
```4gl
IMPORT FGL utils_global_stock_updater

PRIVATE FUNCTION post_credit_note()
    -- Return to stock (opposite of sales)
    IF NOT utils_global_stock_updater.update_stock_simple(
        l_stock_id,
        l_return_qty,
        "IN",          -- Returns increase stock
        "CRN"
    ) THEN
        RETURN FALSE
    END IF

    RETURN TRUE
END FUNCTION
```

## Direction Reference

| Transaction Type | Direction | Effect |
|-----------------|-----------|--------|
| Purchase Order Receipt | IN | Increase stock |
| GRN | IN | Increase stock |
| Sales Order | OUT | Decrease stock |
| Invoice | OUT | Decrease stock |
| Credit Note | IN | Increase stock (return) |
| Debit Note | OUT | Decrease stock |
| Transfer OUT | OUT | Decrease from source |
| Transfer IN | IN | Increase at destination |
| Stock Adjustment + | IN | Increase stock |
| Stock Adjustment - | OUT | Decrease stock |
| POS Sale | OUT | Decrease stock |

## Error Handling

The functions automatically handle and display errors for:
- Invalid direction (must be "IN" or "OUT")
- Invalid quantity (must be > 0)
- Stock item not found
- Insufficient stock for OUT transactions
- Database errors

All error messages are shown using `utils_globals.show_error()`.

## Transaction Safety

All stock updates are wrapped in BEGIN WORK/COMMIT WORK with:
- Row-level locking (FOR UPDATE)
- Automatic rollback on error
- Consistent transaction recording

## Database Updates

Each successful stock update:
1. Updates `st01_mast` fields:
   - `stock_on_hand` (actual quantity)
   - `stock_balance` (balance quantity)
   - `total_sales` or `total_purch` (cumulative)
   - `updated_at` (timestamp)

2. Inserts into `st30_trans`:
   - All transaction details
   - Status set to "POSTED"
   - Timestamp and document reference

## Migration from Local Functions

To replace existing `update_stock_on_hand()` functions:

**Before:**
```4gl
PRIVATE FUNCTION update_stock_on_hand(p_stock_id, p_qty, p_dir)
    -- Custom implementation
END FUNCTION
```

**After:**
```4gl
IMPORT FGL utils_global_stock_updater

-- Replace calls:
-- IF update_stock_on_hand(l_stock_id, l_qty, "OUT") THEN
IF utils_global_stock_updater.update_stock_simple(l_stock_id, l_qty, "OUT", "INV") THEN
    -- Continue
END IF
```

## Best Practices

1. **Always check return value** - Don't ignore FALSE returns
2. **Use appropriate function** - Choose simple/cost/batch based on needs
3. **Consistent doc_type** - Use standard abbreviations
4. **Pre-validate for UI** - Use `check_stock_availability()` before user commits
5. **Include doc_no** - Always pass document number for audit trail
6. **Let it handle transactions** - The functions manage BEGIN/COMMIT/ROLLBACK

## Questions?

Contact: Development Team
Module Location: `src/utils/utils_global_stock_updater.4gl`
