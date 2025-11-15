# Utils Logger - Complete Usage Guide

## Status: ✅ COMPLETE & READY TO USE

---

## Overview

**utils_logger.4gl** is a comprehensive logging utility wrapper that provides a convenient, centralized interface to the sy130_logs logging system. It offers both console and database logging with configurable log levels and specialized logging functions.

**Location**: `src/utils/utils_logger.4gl`
**Compiled**: `bin/utils_logger.42m` ✅

---

## Key Features

✅ **Dual Logging**: Console and database logging (configurable independently)
✅ **Log Level Filtering**: DEBUG, INFO, WARNING, ERROR, SECURITY
✅ **Specialized Functions**: SQL errors, data operations, security events
✅ **Performance Logging**: Track slow operations automatically
✅ **Transaction Tracking**: Monitor BEGIN/COMMIT/ROLLBACK operations
✅ **Easy Integration**: Simple API for all modules
✅ **Silent Failure**: Logging errors don't break your application

---

## Quick Start

### 1. Import the Logger

```4gl
IMPORT FGL utils_logger
```

### 2. Initialize (Optional - at application startup)

```4gl
-- In start_app.4gl or application initialization
CALL utils_logger.init_logger()
```

### 3. Start Logging

```4gl
-- Simple logging
CALL utils_logger.log_info("my_function", "Operation completed")
CALL utils_logger.log_error("my_function", "Something went wrong")

-- Detailed logging
CALL utils_logger.log_info_detail("my_function", "Data saved",
    "Record ID: 123, User: admin")
```

---

## Configuration

### Initialization

```4gl
CALL utils_logger.init_logger()
```

**Default Settings**:
- Logging enabled: YES
- Console logging: YES
- Database logging: YES
- Minimum level: INFO (doesn't log DEBUG by default)

### Configuration Functions

```4gl
-- Enable/disable all logging
CALL utils_logger.set_logging_enabled(TRUE)   -- Turn on
CALL utils_logger.set_logging_enabled(FALSE)  -- Turn off

-- Control console logging (DISPLAY statements)
CALL utils_logger.set_console_logging(TRUE)   -- Show in console
CALL utils_logger.set_console_logging(FALSE)  -- Don't show in console

-- Control database logging (sy02_logs table)
CALL utils_logger.set_database_logging(TRUE)  -- Save to database
CALL utils_logger.set_database_logging(FALSE) -- Don't save to database

-- Set minimum log level
CALL utils_logger.set_min_log_level("DEBUG")    -- Log everything
CALL utils_logger.set_min_log_level("INFO")     -- Log INFO and above (default)
CALL utils_logger.set_min_log_level("WARNING")  -- Log WARNING, ERROR, SECURITY only
CALL utils_logger.set_min_log_level("ERROR")    -- Log ERROR and SECURITY only
```

---

## Log Levels

### Level Priority (Lowest to Highest)

```
1. DEBUG     - Development/troubleshooting info
2. INFO      - Normal operations, informational messages
3. WARNING   - Non-critical issues, potential problems
4. ERROR     - Application errors, failures
5. SECURITY  - Security-related events (highest priority)
```

### Level Filtering

When you set `set_min_log_level("WARNING")`, only messages with priority >= WARNING are logged:
- ✅ WARNING logged
- ✅ ERROR logged
- ✅ SECURITY logged
- ❌ INFO skipped
- ❌ DEBUG skipped

---

## Basic Logging Functions

### Simple Logging (No Details)

```4gl
-- Log an error
CALL utils_logger.log_error("st101_mast", "Failed to save stock item")

-- Log a warning
CALL utils_logger.log_warning("st101_mast", "Stock quantity below minimum")

-- Log information
CALL utils_logger.log_info("st101_mast", "Stock item created successfully")

-- Log debug info (only when min level = DEBUG)
CALL utils_logger.log_debug("st101_mast", "Entering save_stock function")

-- Log security event
CALL utils_logger.log_security("sy101_user", "Unauthorized access attempt")
```

### Detailed Logging (With Additional Details)

```4gl
-- Error with details
CALL utils_logger.log_error_detail(
    "st101_mast",
    "Database constraint violation",
    "Duplicate stock code: ITEM001, Table: st01_stock"
)

-- Warning with details
CALL utils_logger.log_warning_detail(
    "pu130_order",
    "Supplier credit limit exceeded",
    SFMT("Supplier: %1, Credit Limit: %2, Order Amount: %3",
         supplier_code, credit_limit, order_total)
)

-- Info with details
CALL utils_logger.log_info_detail(
    "sa131_order",
    "Sales order completed",
    SFMT("Order #: %1, Customer: %2, Total: %3",
         order_number, customer_name, order_total)
)

-- Debug with details
CALL utils_logger.log_debug_detail(
    "st120_enq",
    "Query execution",
    SFMT("SQL: %1, Rows returned: %2", sql_query, row_count)
)

-- Security with details
CALL utils_logger.log_security_detail(
    "sy103_perm",
    "Permission granted",
    SFMT("User: %1, Module: %2, Permission: %3",
         username, module_name, permission_type)
)
```

---

## Specialized Logging Functions

### 1. SQL Error Logging

Automatically captures SQLCA information:

```4gl
TRY
    INSERT INTO st01_stock VALUES (rec_stock.*)
CATCH
    -- Logs: SQLCODE, SQLERRD[2], SQLERRM automatically
    CALL utils_logger.log_sql_error("st101_mast", "INSERT INTO st01_stock")
    RETURN FALSE
END TRY
```

**Output**:
```
[ERROR] st101_mast | SQL Error in INSERT INTO st01_stock |
Details: SQLCODE: -239, SQLERRD[2]: 0, Message: Duplicate value for unique constraint
```

### 2. User Authentication Logging

```4gl
-- Log successful login
CALL utils_logger.log_user_login_attempt("admin", TRUE, 1)

-- Log failed login
CALL utils_logger.log_user_login_attempt("hacker", FALSE, 0)

-- Log logout
CALL utils_logger.log_user_logout_event("admin", 1)
```

### 3. Data Operation Logging

```4gl
-- Log INSERT operation
CALL utils_logger.log_data_insert("st101_mast", "st01_stock", rec_stock.id)

-- Log UPDATE operation
CALL utils_logger.log_data_update("st101_mast", "st01_stock", rec_stock.id)

-- Log DELETE operation
CALL utils_logger.log_data_delete("st101_mast", "st01_stock", rec_stock.id)
```

**Example Output**:
```
[INFO] st101_mast | Record inserted into st01_stock | Record ID: 123
[INFO] st101_mast | Record updated in st01_stock | Record ID: 123
[INFO] st101_mast | Record deleted from st01_stock | Record ID: 123
```

### 4. Permission & Security Logging

```4gl
-- Log permission check
CALL utils_logger.log_permission_check("st101_mast", user_id, TRUE)   -- Granted
CALL utils_logger.log_permission_check("sy101_user", user_id, FALSE)  -- Denied

-- Log module access
CALL utils_logger.log_module_access("st101_mast", user_id)
```

### 5. Performance Monitoring

```4gl
DEFINE start_time, end_time DATETIME YEAR TO FRACTION(3)
DEFINE duration FLOAT

LET start_time = CURRENT YEAR TO FRACTION(3)

-- ... perform operation ...

LET end_time = CURRENT YEAR TO FRACTION(3)
LET duration = (end_time - start_time) UNITS SECOND

-- Automatically logs as WARNING if > 5 seconds, DEBUG otherwise
CALL utils_logger.log_performance("st120_enq", "Stock query", duration)
```

### 6. Business Rule Violations

```4gl
IF stock_quantity < minimum_quantity THEN
    CALL utils_logger.log_business_rule_violation(
        "st101_mast",
        "Minimum Stock Level",
        SFMT("Stock code: %1, Current: %2, Minimum: %3",
             stock_code, stock_quantity, minimum_quantity)
    )
END IF
```

### 7. Configuration Changes

```4gl
CALL utils_logger.log_config_change(
    "sy105_settings",
    "max_login_attempts",
    "3",    -- old value
    "5"     -- new value
)
```

---

## Transaction Logging

Track database transactions for debugging:

```4gl
-- Start transaction
BEGIN WORK
CALL utils_logger.log_transaction_start("pu130_order", "Purchase Order Save")

TRY
    -- ... database operations ...

    COMMIT WORK
    CALL utils_logger.log_transaction_commit("pu130_order", "Purchase Order Save")

CATCH
    ROLLBACK WORK
    CALL utils_logger.log_transaction_rollback(
        "pu130_order",
        "Purchase Order Save",
        SQLERRM
    )
END TRY
```

---

## Debug Function Tracing

Track function entry/exit for debugging (only when min level = DEBUG):

```4gl
FUNCTION calculate_order_total(p_order_id INTEGER) RETURNS DECIMAL(15,2)
    DEFINE total DECIMAL(15,2)

    -- Log function entry with parameters
    CALL utils_logger.log_function_entry(
        "calculate_order_total",
        SFMT("order_id=%1", p_order_id)
    )

    -- ... calculation logic ...

    -- Log function exit with result
    CALL utils_logger.log_function_exit(
        "calculate_order_total",
        SFMT("total=%1", total USING "<<<,<<<,<<&.&&")
    )

    RETURN total
END FUNCTION
```

---

## Error Handling & Retrieval

### Store and Retrieve Last Error

```4gl
-- Error is automatically stored when you call log_error()
CALL utils_logger.log_error("st101_mast", "Validation failed")

-- Later, retrieve the last error
DEFINE last_err STRING
LET last_err = utils_logger.get_last_error()
DISPLAY "Last error was: ", last_err

-- Clear the last error
CALL utils_logger.clear_last_error()
```

---

## Complete Usage Examples

### Example 1: Stock Master Save Function

```4gl
FUNCTION save_stock_item() RETURNS BOOLEAN
    DEFINE rec_stock RECORD LIKE st01_stock.*
    DEFINE is_new BOOLEAN

    LET is_new = (rec_stock.id IS NULL)

    BEGIN WORK
    CALL utils_logger.log_transaction_start("st101_mast", "Save Stock Item")

    TRY
        -- Validate stock code
        IF rec_stock.stock_code IS NULL OR rec_stock.stock_code = "" THEN
            CALL utils_logger.log_business_rule_violation(
                "st101_mast",
                "Required Field Validation",
                "Stock code is required"
            )
            ROLLBACK WORK
            RETURN FALSE
        END IF

        -- Save record
        IF is_new THEN
            INSERT INTO st01_stock VALUES (rec_stock.*)
            LET rec_stock.id = SQLCA.SQLERRD[2]

            CALL utils_logger.log_data_insert("st101_mast", "st01_stock", rec_stock.id)
            CALL utils_logger.log_info_detail("st101_mast", "New stock item created",
                SFMT("Code: %1, Description: %2", rec_stock.stock_code, rec_stock.description))
        ELSE
            UPDATE st01_stock SET * = rec_stock.* WHERE id = rec_stock.id

            CALL utils_logger.log_data_update("st101_mast", "st01_stock", rec_stock.id)
            CALL utils_logger.log_info("st101_mast", "Stock item updated")
        END IF

        COMMIT WORK
        CALL utils_logger.log_transaction_commit("st101_mast", "Save Stock Item")

        RETURN TRUE

    CATCH
        ROLLBACK WORK
        CALL utils_logger.log_transaction_rollback(
            "st101_mast",
            "Save Stock Item",
            SQLERRM
        )
        CALL utils_logger.log_sql_error("st101_mast", "Save stock item")

        RETURN FALSE
    END TRY
END FUNCTION
```

### Example 2: User Login Function

```4gl
FUNCTION process_login(p_username STRING, p_password STRING) RETURNS INTEGER
    DEFINE rec_user RECORD LIKE sy00_user.*
    DEFINE hashed_password STRING

    CALL utils_logger.log_info_detail("sy100_login", "Login attempt",
        SFMT("Username: %1", p_username))

    TRY
        SELECT * INTO rec_user.*
          FROM sy00_user
         WHERE username = p_username
           AND status = 'Active'

        IF SQLCA.SQLCODE = NOTFOUND THEN
            -- User not found or inactive
            CALL utils_logger.log_user_login_attempt(p_username, FALSE, 0)
            CALL utils_logger.log_security_detail("sy100_login", "Login failed",
                SFMT("Unknown or inactive user: %1", p_username))
            RETURN 0
        END IF

        -- Verify password (simplified - use proper hashing in production)
        IF rec_user.password = p_password THEN
            -- Success
            CALL utils_logger.log_user_login_attempt(p_username, TRUE, rec_user.id)
            CALL utils_logger.log_module_access("sy100_login", rec_user.id)
            RETURN rec_user.id
        ELSE
            -- Wrong password
            CALL utils_logger.log_user_login_attempt(p_username, FALSE, 0)
            CALL utils_logger.log_security_detail("sy100_login", "Login failed",
                SFMT("Invalid password for user: %1", p_username))
            RETURN 0
        END IF

    CATCH
        CALL utils_logger.log_sql_error("sy100_login", "User authentication")
        RETURN 0
    END TRY
END FUNCTION
```

### Example 3: Permission Check Function

```4gl
FUNCTION check_module_permission(p_user_id INTEGER, p_module STRING) RETURNS BOOLEAN
    DEFINE has_permission SMALLINT

    TRY
        SELECT COUNT(*) INTO has_permission
          FROM sy03_perm p
          JOIN sy04_role_perm rp ON p.id = rp.perm_id
          JOIN sy00_user u ON u.role_id = rp.role_id
         WHERE u.id = p_user_id
           AND p.module_code = p_module
           AND p.can_access = TRUE

        -- Log the permission check
        CALL utils_logger.log_permission_check(p_module, p_user_id, has_permission)

        RETURN has_permission

    CATCH
        CALL utils_logger.log_sql_error("check_module_permission",
            "Permission query for " || p_module)
        RETURN FALSE
    END TRY
END FUNCTION
```

### Example 4: Performance-Monitored Query

```4gl
FUNCTION load_large_dataset() RETURNS INTEGER
    DEFINE start_time, end_time DATETIME YEAR TO FRACTION(3)
    DEFINE duration FLOAT
    DEFINE row_count INTEGER

    LET start_time = CURRENT YEAR TO FRACTION(3)

    CALL utils_logger.log_debug("st120_enq", "Starting large dataset load")

    TRY
        -- Execute complex query
        DECLARE complex_cursor CURSOR FOR
            SELECT * FROM st01_stock s
            JOIN st02_trans t ON s.id = t.stock_id
            WHERE t.trans_date >= TODAY - 365
            ORDER BY t.trans_date DESC

        LET row_count = 0
        FOREACH complex_cursor INTO ...
            LET row_count = row_count + 1
        END FOREACH

        LET end_time = CURRENT YEAR TO FRACTION(3)
        LET duration = (end_time - start_time) UNITS SECOND

        -- Logs as WARNING if > 5 seconds, DEBUG otherwise
        CALL utils_logger.log_performance("st120_enq",
            SFMT("Load %1 rows", row_count), duration)

        RETURN row_count

    CATCH
        CALL utils_logger.log_sql_error("st120_enq", "Large dataset load")
        RETURN 0
    END TRY
END FUNCTION
```

---

## Console Output Format

When console logging is enabled, output appears in this format:

```
[LEVEL] timestamp | function | message | details

Examples:
[INFO] 2025-01-14 15:30:45.123 | st101_mast | Record inserted into st01_stock | Record ID: 123
[ERROR] 2025-01-14 15:31:12.456 | st101_mast | SQL Error in INSERT INTO st01_stock | SQLCODE: -239, SQLERRD[2]: 0, Message: Duplicate value
[SECURITY] 2025-01-14 15:32:00.789 | sy100_login | Login failed | Invalid password for user: admin
[WARNING] 2025-01-14 15:33:15.012 | pu130_order | Performance: Load 5000 rows | Duration: 6.234 seconds
```

---

## Database Storage

All logs (when database logging is enabled) are stored in the **sy02_logs** table via the sy130_logs module:

```sql
TABLE: sy02_logs
├─ id (PRIMARY KEY)
├─ user_id (FK to sy00_user)
├─ level (INFO, WARNING, ERROR, DEBUG, SECURITY)
├─ action (function: message)
├─ details (additional information)
└─ created_at (timestamp)
```

Logs can be viewed via: **System → System Logs** menu

---

## Best Practices

### 1. Choose Appropriate Log Levels

```4gl
-- ✅ GOOD: Appropriate levels
CALL utils_logger.log_info("st101_mast", "Stock item saved")        -- Normal operation
CALL utils_logger.log_warning("st101_mast", "Low stock alert")      -- Potential issue
CALL utils_logger.log_error("st101_mast", "Save failed")            -- Error condition
CALL utils_logger.log_security("sy100_login", "Failed login")       -- Security event

-- ❌ BAD: Wrong levels
CALL utils_logger.log_error("st101_mast", "Stock item saved")       -- Not an error!
CALL utils_logger.log_info("st101_mast", "Database connection lost") -- Should be ERROR!
```

### 2. Provide Useful Context

```4gl
-- ✅ GOOD: Specific, actionable information
CALL utils_logger.log_error_detail("st101_mast", "Validation failed",
    SFMT("Stock code '%1' exceeds maximum length of 20 characters", stock_code))

-- ❌ BAD: Vague, unhelpful
CALL utils_logger.log_error("st101_mast", "Error")
```

### 3. Don't Over-Log in Production

```4gl
-- ✅ GOOD: Set min level to INFO in production
CALL utils_logger.set_min_log_level("INFO")

-- ❌ BAD: DEBUG in production creates too many logs
CALL utils_logger.set_min_log_level("DEBUG")  -- Only for development!
```

### 4. Log Security-Sensitive Events

```4gl
-- ✅ ALWAYS LOG:
-- - Login attempts (success/failure)
-- - Permission denials
-- - Configuration changes
-- - Data deletions
-- - Password changes
-- - Role/permission modifications

CALL utils_logger.log_security_detail("sy101_user", "Password changed",
    SFMT("User ID: %1, Changed by: %2", target_user_id, current_user_id))
```

### 5. Use Try-Catch with Logging

```4gl
-- ✅ GOOD: Log errors, don't break the app
TRY
    -- risky operation
CATCH
    CALL utils_logger.log_sql_error("my_function", "Operation description")
    -- Handle error gracefully
END TRY

-- ❌ BAD: Unhandled errors crash the application
-- risky operation without TRY-CATCH
```

---

## Production vs Development Configuration

### Development Setup

```4gl
-- Enable everything for maximum visibility
CALL utils_logger.init_logger()
CALL utils_logger.set_logging_enabled(TRUE)
CALL utils_logger.set_console_logging(TRUE)
CALL utils_logger.set_database_logging(TRUE)
CALL utils_logger.set_min_log_level("DEBUG")  -- See everything
```

### Production Setup

```4gl
-- Optimize for performance and storage
CALL utils_logger.init_logger()
CALL utils_logger.set_logging_enabled(TRUE)
CALL utils_logger.set_console_logging(FALSE)   -- Reduce console noise
CALL utils_logger.set_database_logging(TRUE)   -- Keep audit trail
CALL utils_logger.set_min_log_level("INFO")    -- Skip DEBUG messages
```

### Troubleshooting Setup

```4gl
-- When investigating an issue
CALL utils_logger.set_console_logging(TRUE)    -- See output immediately
CALL utils_logger.set_min_log_level("DEBUG")   -- Maximum detail

-- ... investigate ...

-- Restore production settings
CALL utils_logger.set_console_logging(FALSE)
CALL utils_logger.set_min_log_level("INFO")
```

---

## Integration with Existing Code

### Minimal Changes Required

```4gl
-- OLD CODE (before utils_logger):
FUNCTION save_record()
    TRY
        INSERT INTO my_table VALUES (rec.*)
    CATCH
        ERROR "Failed to save record"
        RETURN FALSE
    END TRY
    RETURN TRUE
END FUNCTION

-- NEW CODE (with utils_logger):
FUNCTION save_record()
    TRY
        INSERT INTO my_table VALUES (rec.*)
        CALL utils_logger.log_data_insert("my_module", "my_table", rec.id)  -- ADD THIS
    CATCH
        CALL utils_logger.log_sql_error("my_module", "INSERT INTO my_table")  -- ADD THIS
        ERROR "Failed to save record"
        RETURN FALSE
    END TRY
    RETURN TRUE
END FUNCTION
```

---

## Performance Considerations

### Logging is Fast
- Console logging: negligible overhead
- Database logging: async write (doesn't block your app)
- Failed logging operations don't crash your app (silent fail)

### Storage Management
- Use System → System Logs → "Clear Old Logs" monthly
- Default: deletes logs older than 90 days
- Consider archiving important logs before deletion

### When to Disable Logging
```4gl
-- Temporarily disable during batch operations
CALL utils_logger.set_logging_enabled(FALSE)

-- ... process 10,000 records ...

CALL utils_logger.set_logging_enabled(TRUE)
```

---

## Troubleshooting

### Issue: Logs not appearing in database
**Check**:
1. Is database logging enabled? `set_database_logging(TRUE)`
2. Is logging enabled overall? `set_logging_enabled(TRUE)`
3. Is log level appropriate? `set_min_log_level("INFO")` or lower
4. Check sy02_logs table: `SELECT COUNT(*) FROM sy02_logs`

### Issue: Too many DEBUG logs in production
**Solution**:
```4gl
CALL utils_logger.set_min_log_level("INFO")  -- Skip DEBUG
```

### Issue: Want to see logs immediately during testing
**Solution**:
```4gl
CALL utils_logger.set_console_logging(TRUE)  -- Show in terminal
```

---

## Summary

✅ **Comprehensive Logging Utility**
- Wraps sy130_logs with convenient API
- Dual output: console and database
- Configurable log levels and filtering
- Specialized functions for common scenarios

✅ **Easy to Use**
```4gl
IMPORT FGL utils_logger
CALL utils_logger.log_info("module", "message")
```

✅ **Production Ready**
- Silent failure protection
- Performance optimized
- Flexible configuration

✅ **Feature Rich**
- SQL error logging
- Performance monitoring
- Transaction tracking
- Security event logging
- Business rule violations
- And much more!

---

*Document Version: 1.0*
*Implementation Date: 2025-01-14*
*Status: COMPLETE & COMPILED*
*Module: utils_logger (Logging Utility)*
