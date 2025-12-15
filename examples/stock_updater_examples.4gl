-- ==============================================================
-- File       : stock_updater_examples.4gl
-- Description: Usage examples for global stock updater
-- ==============================================================

IMPORT FGL utils_global_stock_updater
IMPORT FGL utils_globals

-- ==============================================================
-- Example 1: Simple Sales Invoice
-- ==============================================================
FUNCTION example_sales_invoice()
    DEFINE l_stock_id INTEGER
    DEFINE l_quantity DECIMAL
    DEFINE l_doc_no STRING

    LET l_stock_id = 100
    LET l_quantity = 5.0
    LET l_doc_no = "INV-2025-00123"

    -- Simple stock reduction
    IF NOT utils_global_stock_updater.update_stock_simple(
        l_stock_id,
        l_quantity,
        "OUT",
        "INV"
    ) THEN
        -- Error already shown, just handle failure
        DISPLAY "Failed to update stock for invoice"
        RETURN FALSE
    END IF

    DISPLAY "Stock updated successfully for invoice ", l_doc_no
    RETURN TRUE

END FUNCTION

-- ==============================================================
-- Example 2: GRN with Costing
-- ==============================================================
FUNCTION example_grn_receipt()
    DEFINE l_stock_id INTEGER
    DEFINE l_quantity DECIMAL
    DEFINE l_doc_no STRING
    DEFINE l_unit_cost DECIMAL
    DEFINE l_sell_price DECIMAL

    LET l_stock_id = 100
    LET l_quantity = 100.0
    LET l_doc_no = "GRN-2025-00045"
    LET l_unit_cost = 10.50
    LET l_sell_price = 15.75

    -- Stock increase with cost tracking
    IF NOT utils_global_stock_updater.update_stock_with_cost(
        l_stock_id,
        l_quantity,
        "IN",
        "GRN",
        l_doc_no,
        l_unit_cost,
        l_sell_price
    ) THEN
        DISPLAY "Failed to update stock for GRN"
        RETURN FALSE
    END IF

    DISPLAY "Stock received: ", l_quantity, " units at ", l_unit_cost, " each"
    RETURN TRUE

END FUNCTION

-- ==============================================================
-- Example 3: Process Invoice with Pre-Check
-- ==============================================================
FUNCTION example_invoice_with_check()
    DEFINE l_stock_id INTEGER
    DEFINE l_required_qty DECIMAL
    DEFINE l_current_stock DECIMAL

    LET l_stock_id = 100
    LET l_required_qty = 25.0

    -- First, get current stock to display
    LET l_current_stock = utils_global_stock_updater.get_current_stock(l_stock_id)
    DISPLAY "Current stock level: ", l_current_stock

    -- Check if stock is available before processing
    IF NOT utils_global_stock_updater.check_stock_availability(
        l_stock_id,
        l_required_qty
    ) THEN
        -- Error message already shown to user
        DISPLAY "Cannot process invoice - insufficient stock"
        RETURN FALSE
    END IF

    -- Stock is available, proceed with update
    IF NOT utils_global_stock_updater.update_stock_simple(
        l_stock_id,
        l_required_qty,
        "OUT",
        "INV"
    ) THEN
        DISPLAY "Failed to update stock"
        RETURN FALSE
    END IF

    DISPLAY "Invoice processed successfully"
    RETURN TRUE

END FUNCTION

-- ==============================================================
-- Example 4: Process Multiple Invoice Lines
-- ==============================================================
FUNCTION example_multi_line_invoice()
    DEFINE ma_lines ARRAY[10] OF RECORD
        stock_id INTEGER,
        quantity DECIMAL,
        unit_cost DECIMAL,
        sell_price DECIMAL
    END RECORD
    DEFINE l_line_count INTEGER
    DEFINE i INTEGER
    DEFINE l_doc_no STRING

    -- Sample data
    LET l_doc_no = "INV-2025-00150"
    LET l_line_count = 3

    LET ma_lines[1].stock_id = 100
    LET ma_lines[1].quantity = 5.0
    LET ma_lines[1].unit_cost = 10.00
    LET ma_lines[1].sell_price = 15.00

    LET ma_lines[2].stock_id = 101
    LET ma_lines[2].quantity = 10.0
    LET ma_lines[2].unit_cost = 5.00
    LET ma_lines[2].sell_price = 8.00

    LET ma_lines[3].stock_id = 102
    LET ma_lines[3].quantity = 2.0
    LET ma_lines[3].unit_cost = 50.00
    LET ma_lines[3].sell_price = 75.00

    -- Process each line
    FOR i = 1 TO l_line_count
        -- Check availability first
        IF NOT utils_global_stock_updater.check_stock_availability(
            ma_lines[i].stock_id,
            ma_lines[i].quantity
        ) THEN
            DISPLAY "Line ", i, " failed availability check"
            RETURN FALSE
        END IF

        -- Update stock with costing
        IF NOT utils_global_stock_updater.update_stock_with_cost(
            ma_lines[i].stock_id,
            ma_lines[i].quantity,
            "OUT",
            "INV",
            l_doc_no,
            ma_lines[i].unit_cost,
            ma_lines[i].sell_price
        ) THEN
            DISPLAY "Line ", i, " failed to update"
            RETURN FALSE
        END IF
    END FOR

    DISPLAY "Invoice ", l_doc_no, " processed: ", l_line_count, " lines"
    RETURN TRUE

END FUNCTION

-- ==============================================================
-- Example 5: Credit Note (Return to Stock)
-- ==============================================================
FUNCTION example_credit_note()
    DEFINE l_stock_id INTEGER
    DEFINE l_return_qty DECIMAL
    DEFINE l_doc_no STRING

    LET l_stock_id = 100
    LET l_return_qty = 3.0
    LET l_doc_no = "CRN-2025-00012"

    -- Credit note increases stock (customer returns)
    IF NOT utils_global_stock_updater.update_stock_simple(
        l_stock_id,
        l_return_qty,
        "IN",           -- IN because we're getting stock back
        "CRN"
    ) THEN
        DISPLAY "Failed to process credit note"
        RETURN FALSE
    END IF

    DISPLAY "Credit note processed: ", l_return_qty, " units returned to stock"
    RETURN TRUE

END FUNCTION

-- ==============================================================
-- Example 6: Warehouse Transfer
-- ==============================================================
FUNCTION example_warehouse_transfer()
    DEFINE l_stock_id INTEGER
    DEFINE l_transfer_qty DECIMAL
    DEFINE l_doc_no STRING
    DEFINE l_from_wh STRING
    DEFINE l_to_wh STRING

    LET l_stock_id = 100
    LET l_transfer_qty = 50.0
    LET l_doc_no = "TRF-2025-00078"
    LET l_from_wh = "WH-MAIN"
    LET l_to_wh = "WH-BRANCH"

    -- Check source warehouse has stock
    IF NOT utils_global_stock_updater.check_stock_availability(
        l_stock_id,
        l_transfer_qty
    ) THEN
        DISPLAY "Insufficient stock in source warehouse"
        RETURN FALSE
    END IF

    -- Transfer OUT from source warehouse
    IF NOT utils_global_stock_updater.update_stock_simple(
        l_stock_id,
        l_transfer_qty,
        "OUT",
        "TRF"
    ) THEN
        DISPLAY "Failed to transfer OUT from ", l_from_wh
        RETURN FALSE
    END IF

    -- Transfer IN to destination warehouse
    IF NOT utils_global_stock_updater.update_stock_simple(
        l_stock_id,
        l_transfer_qty,
        "IN",
        "TRF"
    ) THEN
        DISPLAY "Failed to transfer IN to ", l_to_wh
        -- Note: In production, you'd need to reverse the OUT transaction
        RETURN FALSE
    END IF

    DISPLAY "Transfer completed: ", l_transfer_qty, " units from ", l_from_wh, " to ", l_to_wh
    RETURN TRUE

END FUNCTION

-- ==============================================================
-- Example 7: Batch-Controlled Item Receipt
-- ==============================================================
FUNCTION example_batch_receipt()
    DEFINE l_stock_id INTEGER
    DEFINE l_quantity DECIMAL
    DEFINE l_doc_no STRING
    DEFINE l_batch_id STRING
    DEFINE l_expiry_date DATE

    LET l_stock_id = 200
    LET l_quantity = 1000.0
    LET l_doc_no = "GRN-2025-00055"
    LET l_batch_id = "BATCH-2025-001"
    LET l_expiry_date = MDY(12, 31, 2025)

    -- Receive batch-controlled item with expiry
    IF NOT utils_global_stock_updater.update_stock_with_batch(
        l_stock_id,
        l_quantity,
        "IN",
        "GRN",
        l_doc_no,
        l_batch_id,
        l_expiry_date
    ) THEN
        DISPLAY "Failed to receive batch"
        RETURN FALSE
    END IF

    DISPLAY "Batch received: ", l_batch_id, " Qty: ", l_quantity, " Expiry: ", l_expiry_date
    RETURN TRUE

END FUNCTION

-- ==============================================================
-- Example 8: Stock Adjustment (Positive)
-- ==============================================================
FUNCTION example_stock_adjustment_positive()
    DEFINE l_stock_id INTEGER
    DEFINE l_adjustment_qty DECIMAL
    DEFINE l_notes STRING

    LET l_stock_id = 100
    LET l_adjustment_qty = 15.0
    LET l_notes = "Physical count adjustment - found extra stock"

    -- Full control with notes
    IF NOT utils_global_stock_updater.update_stock(
        l_stock_id,
        l_adjustment_qty,
        "IN",           -- Positive adjustment
        "ADJ",          -- Adjustment document type
        NULL,           -- No doc number
        l_notes,        -- Reason for adjustment
        NULL,           -- No batch
        NULL,           -- No expiry
        NULL,           -- No cost
        NULL            -- No price
    ) THEN
        DISPLAY "Failed to adjust stock"
        RETURN FALSE
    END IF

    DISPLAY "Stock adjusted UP by ", l_adjustment_qty, " units"
    RETURN TRUE

END FUNCTION

-- ==============================================================
-- Example 9: Stock Adjustment (Negative)
-- ==============================================================
FUNCTION example_stock_adjustment_negative()
    DEFINE l_stock_id INTEGER
    DEFINE l_adjustment_qty DECIMAL
    DEFINE l_notes STRING

    LET l_stock_id = 100
    LET l_adjustment_qty = 5.0
    LET l_notes = "Damaged stock write-off"

    -- Check if we have enough stock to adjust down
    IF NOT utils_global_stock_updater.check_stock_availability(
        l_stock_id,
        l_adjustment_qty
    ) THEN
        DISPLAY "Cannot adjust - insufficient stock"
        RETURN FALSE
    END IF

    -- Negative adjustment
    IF NOT utils_global_stock_updater.update_stock(
        l_stock_id,
        l_adjustment_qty,
        "OUT",          -- Negative adjustment
        "ADJ",
        NULL,
        l_notes,
        NULL, NULL, NULL, NULL
    ) THEN
        DISPLAY "Failed to adjust stock"
        RETURN FALSE
    END IF

    DISPLAY "Stock adjusted DOWN by ", l_adjustment_qty, " units"
    RETURN TRUE

END FUNCTION

-- ==============================================================
-- Example 10: POS Sale
-- ==============================================================
FUNCTION example_pos_sale()
    DEFINE l_stock_id INTEGER
    DEFINE l_quantity DECIMAL
    DEFINE l_sell_price DECIMAL
    DEFINE l_receipt_no STRING

    LET l_stock_id = 100
    LET l_quantity = 2.0
    LET l_sell_price = 15.00
    LET l_receipt_no = "POS-00123"

    -- Quick availability check
    IF NOT utils_global_stock_updater.check_stock_availability(l_stock_id, l_quantity) THEN
        DISPLAY "Item out of stock!"
        RETURN FALSE
    END IF

    -- Process POS sale
    IF NOT utils_global_stock_updater.update_stock_with_cost(
        l_stock_id,
        l_quantity,
        "OUT",
        "POS",
        l_receipt_no,
        NULL,           -- Unit cost not tracked at POS
        l_sell_price
    ) THEN
        DISPLAY "POS sale failed"
        RETURN FALSE
    END IF

    DISPLAY "POS Sale completed: Receipt ", l_receipt_no
    RETURN TRUE

END FUNCTION
