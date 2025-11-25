-- ==============================================================
-- Module     : utils_global_stock_updater
-- Description: Global stock update utility for all modules
-- Usage      : IMPORT FGL utils_global_stock_updater
--              CALL utils_global_stock_updater.update_stock(...)
-- ==============================================================
-- Modules    : POS, GRN, Sales Orders, Invoices, Credit Notes,
--              Warehouse Transfer, Bin Transactions
-- ==============================================================

IMPORT FGL utils_globals

-- ==============================================================
-- Function : update_stock
-- Purpose  : Update stock levels and record transaction
-- Usage    : CALL update_stock(stock_id, quantity, direction, doc_type, doc_no, notes)
-- Returns  : TRUE on success, FALSE on failure
-- ==============================================================
-- Parameters:
--   p_stock_id   : Stock item ID (st01_mast.id)
--   p_quantity   : Quantity to add/subtract
--   p_direction  : "IN" = increase stock, "OUT" = decrease stock
--   p_doc_type   : Document type (PO, GRN, SO, INV, CRN, TRF, BIN, POS)
--   p_doc_no     : Document number (optional)
--   p_notes      : Additional notes (optional)
--   p_batch_id   : Batch ID (optional, for batch-controlled items)
--   p_expiry_date: Expiry date (optional, for date-controlled items)
--   p_unit_cost  : Unit cost (optional, for costing)
--   p_sell_price : Sell price (optional, for sales)
-- ==============================================================
PUBLIC FUNCTION update_stock(
    p_stock_id INTEGER,
    p_quantity DECIMAL,
    p_direction STRING,
    p_doc_type STRING,
    p_doc_no STRING,
    p_notes STRING,
    p_batch_id STRING,
    p_expiry_date DATE,
    p_unit_cost DECIMAL,
    p_sell_price DECIMAL
) RETURNS SMALLINT

    DEFINE l_current_stock DECIMAL(15,3)

    -- Validate direction
    IF p_direction NOT MATCHES "[IN|OUT]" THEN
        CALL utils_globals.show_error("Invalid direction. Use IN or OUT")
        RETURN FALSE
    END IF

    -- Validate quantity
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        CALL utils_globals.show_error("Quantity must be greater than zero")
        RETURN FALSE
    END IF

    BEGIN WORK

    TRY
        -- Lock the stock record for update
        SELECT stock_on_hand INTO l_current_stock
          FROM st01_mast
         WHERE id = p_stock_id
           FOR UPDATE

        -- Check if stock exists
        IF SQLCA.SQLCODE != 0 THEN
            CALL utils_globals.show_error("Stock item not found")
            ROLLBACK WORK
            RETURN FALSE
        END IF

        -- Check for negative stock (OUT transactions)
        IF p_direction = "OUT" THEN
            IF (l_current_stock - p_quantity) < 0 THEN
                CALL utils_globals.show_error(
                    SFMT("Insufficient stock. Available: %1, Required: %2",
                    l_current_stock, p_quantity))
                ROLLBACK WORK
                RETURN FALSE
            END IF
        END IF

        -- Update stock levels based on direction
        IF p_direction = "OUT" THEN
            -- Decrease stock (Sales, Issues, Transfers OUT)
            UPDATE st01_mast
               SET stock_on_hand = stock_on_hand - p_quantity,
                   stock_balance = stock_balance - p_quantity,
                   total_sales = total_sales + p_quantity,
                   updated_at = CURRENT
             WHERE id = p_stock_id

        ELSE  -- "IN"
            -- Increase stock (Purchases, Returns, Transfers IN)
            UPDATE st01_mast
               SET stock_on_hand = stock_on_hand + p_quantity,
                   stock_balance = stock_balance + p_quantity,
                   total_purch = total_purch + p_quantity,
                   updated_at = CURRENT
             WHERE id = p_stock_id
        END IF

        -- Record stock transaction
        INSERT INTO st30_trans (
            stock_id,
            trans_date,
            doc_type,
            direction,
            qnty,
            unit_cost,
            sell_price,
            batch_id,
            expiry_date,
            notes,
            doc_no,
            status
        ) VALUES (
            p_stock_id,
            TODAY,
            p_doc_type,
            p_direction,
            p_quantity,
            p_unit_cost,
            p_sell_price,
            p_batch_id,
            p_expiry_date,
            p_notes,
            p_doc_no,
            "POSTED"
        )

        COMMIT WORK
        RETURN TRUE

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            SFMT("Failed to update stock: %1 - %2", SQLCA.SQLCODE, SQLERRMESSAGE))
        RETURN FALSE
    END TRY

END FUNCTION

-- ==============================================================
-- Function : update_stock_simple
-- Purpose  : Simplified stock update (most common use case)
-- Usage    : CALL update_stock_simple(stock_id, quantity, direction, doc_type)
-- ==============================================================
PUBLIC FUNCTION update_stock_simple(
    p_stock_id INTEGER,
    p_quantity DECIMAL,
    p_direction STRING,
    p_doc_type STRING
) RETURNS SMALLINT

    RETURN update_stock(
        p_stock_id,
        p_quantity,
        p_direction,
        p_doc_type,
        NULL,  -- doc_no
        NULL,  -- notes
        NULL,  -- batch_id
        NULL,  -- expiry_date
        NULL,  -- unit_cost
        NULL   -- sell_price
    )

END FUNCTION

-- ==============================================================
-- Function : update_stock_with_cost
-- Purpose  : Stock update with costing information
-- Usage    : CALL update_stock_with_cost(stock_id, qty, direction, doc_type, doc_no, unit_cost, sell_price)
-- ==============================================================
PUBLIC FUNCTION update_stock_with_cost(
    p_stock_id INTEGER,
    p_quantity DECIMAL,
    p_direction STRING,
    p_doc_type STRING,
    p_doc_no STRING,
    p_unit_cost DECIMAL,
    p_sell_price DECIMAL
) RETURNS SMALLINT

    RETURN update_stock(
        p_stock_id,
        p_quantity,
        p_direction,
        p_doc_type,
        p_doc_no,
        NULL,  -- notes
        NULL,  -- batch_id
        NULL,  -- expiry_date
        p_unit_cost,
        p_sell_price
    )

END FUNCTION

-- ==============================================================
-- Function : update_stock_with_batch
-- Purpose  : Stock update with batch/expiry tracking
-- Usage    : CALL update_stock_with_batch(stock_id, qty, direction, doc_type, doc_no, batch_id, expiry_date)
-- ==============================================================
PUBLIC FUNCTION update_stock_with_batch(
    p_stock_id INTEGER,
    p_quantity DECIMAL,
    p_direction STRING,
    p_doc_type STRING,
    p_doc_no STRING,
    p_batch_id STRING,
    p_expiry_date DATE
) RETURNS SMALLINT

    RETURN update_stock(
        p_stock_id,
        p_quantity,
        p_direction,
        p_doc_type,
        p_doc_no,
        NULL,  -- notes
        p_batch_id,
        p_expiry_date,
        NULL,  -- unit_cost
        NULL   -- sell_price
    )

END FUNCTION

-- ==============================================================
-- Function : check_stock_availability
-- Purpose  : Check if sufficient stock is available
-- Returns  : TRUE if stock available, FALSE if insufficient
-- ==============================================================
PUBLIC FUNCTION check_stock_availability(
    p_stock_id INTEGER,
    p_required_qty DECIMAL
) RETURNS SMALLINT

    DEFINE l_available_stock DECIMAL(15,3)

    TRY
        SELECT stock_on_hand INTO l_available_stock
          FROM st01_mast
         WHERE id = p_stock_id

        IF SQLCA.SQLCODE != 0 THEN
            CALL utils_globals.show_error("Stock item not found")
            RETURN FALSE
        END IF

        IF l_available_stock >= p_required_qty THEN
            RETURN TRUE
        ELSE
            CALL utils_globals.show_error(
                SFMT("Insufficient stock. Available: %1, Required: %2",
                l_available_stock, p_required_qty))
            RETURN FALSE
        END IF

    CATCH
        CALL utils_globals.show_error(
            SFMT("Error checking stock: %1", SQLERRMESSAGE))
        RETURN FALSE
    END TRY

END FUNCTION

-- ==============================================================
-- Function : get_current_stock
-- Purpose  : Get current stock on hand for an item
-- Returns  : Stock quantity or NULL on error
-- ==============================================================
PUBLIC FUNCTION get_current_stock(p_stock_id INTEGER) RETURNS DECIMAL

    DEFINE l_stock DECIMAL(15,3)

    TRY
        SELECT stock_on_hand INTO l_stock
          FROM st01_mast
         WHERE id = p_stock_id

        RETURN l_stock

    CATCH
        RETURN NULL
    END TRY

END FUNCTION
