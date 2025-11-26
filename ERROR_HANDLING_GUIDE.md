# Error Handling Implementation Guide

## Overview
This guide documents the standardized error handling patterns used across the XactERP application.

## Core Principles

### 1. **Always Use TRY-CATCH for Database Operations**
All SQL operations (SELECT, INSERT, UPDATE, DELETE, PREPARE, DECLARE, FOREACH) must be wrapped in TRY-CATCH blocks.

### 2. **Provide Context in Error Messages**
Error messages should include the function name and operation that failed.

### 3. **Handle Errors Gracefully**
- Display user-friendly messages
- Log technical details for debugging
- Prevent application crashes
- Return control to the user

---

## Standard Patterns

### Pattern 1: Simple SELECT Query

```4gl
FUNCTION load_record(p_id INTEGER)
    DEFINE l_rec RECORD LIKE table_name.*

    TRY
        SELECT * INTO l_rec.*
            FROM table_name
            WHERE id = p_id

        IF SQLCA.SQLCODE != 0 THEN
            CALL utils_globals.show_error("Record not found.")
            RETURN
        END IF
    CATCH
        CALL utils_globals.show_sql_error("load_record: Query failed - " || SQLERRMESSAGE)
        RETURN
    END TRY

    DISPLAY BY NAME l_rec.*
END FUNCTION
```

### Pattern 2: INSERT with Transaction

```4gl
FUNCTION save_record()
    DEFINE l_rec RECORD LIKE table_name.*

    BEGIN WORK
    TRY
        INSERT INTO table_name VALUES l_rec.*

        COMMIT WORK
        CALL utils_globals.msg_saved()
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_sql_error("save_record: Insert failed - " || SQLERRMESSAGE)
    END TRY
END FUNCTION
```

### Pattern 3: UPDATE with Transaction

```4gl
FUNCTION update_record()
    DEFINE l_rec RECORD LIKE table_name.*

    BEGIN WORK
    TRY
        UPDATE table_name
            SET table_name.* = l_rec.*
            WHERE id = l_rec.id

        IF SQLCA.SQLERRD[3] = 0 THEN
            ROLLBACK WORK
            CALL utils_globals.show_error("No records updated.")
            RETURN
        END IF

        COMMIT WORK
        CALL utils_globals.msg_updated()
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_sql_error("update_record: Update failed - " || SQLERRMESSAGE)
    END TRY
END FUNCTION
```

### Pattern 4: DELETE with Confirmation

```4gl
FUNCTION delete_record(p_id INTEGER)
    IF NOT utils_globals.show_confirm("Delete this record?", "Confirm") THEN
        RETURN
    END IF

    BEGIN WORK
    TRY
        DELETE FROM table_name WHERE id = p_id

        IF SQLCA.SQLERRD[3] = 0 THEN
            ROLLBACK WORK
            CALL utils_globals.show_error("Record not found.")
            RETURN
        END IF

        COMMIT WORK
        CALL utils_globals.msg_deleted()
    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_sql_error("delete_record: Delete failed - " || SQLERRMESSAGE)
    END TRY
END FUNCTION
```

### Pattern 5: FOREACH Loop with Cursor

```4gl
FUNCTION load_records()
    DEFINE l_arr DYNAMIC ARRAY OF RECORD
        id LIKE table_name.id,
        name LIKE table_name.name
    END RECORD
    DEFINE l_rec RECORD
        id LIKE table_name.id,
        name LIKE table_name.name
    END RECORD
    DEFINE i INTEGER

    CALL l_arr.clear()

    TRY
        DECLARE rec_curs CURSOR FOR
            SELECT id, name
            FROM table_name
            ORDER BY id

        LET i = 0
        FOREACH rec_curs INTO l_rec.*
            LET i = i + 1
            LET l_arr[i].* = l_rec.*
        END FOREACH

        CLOSE rec_curs
        FREE rec_curs
    CATCH
        CALL utils_globals.show_sql_error("load_records: Query failed - " || SQLERRMESSAGE)
        RETURN
    END TRY

    RETURN l_arr
END FUNCTION
```

### Pattern 6: Complex Multi-Table Save

```4gl
FUNCTION save_document_with_lines()
    DEFINE i INTEGER

    BEGIN WORK
    TRY
        -- Save header
        IF m_hdr_rec.id IS NULL THEN
            INSERT INTO doc_hdr VALUES m_hdr_rec.*
        ELSE
            UPDATE doc_hdr
                SET doc_hdr.* = m_hdr_rec.*
                WHERE id = m_hdr_rec.id
        END IF

        -- Delete existing lines
        DELETE FROM doc_det WHERE hdr_id = m_hdr_rec.id

        -- Insert new lines
        FOR i = 1 TO m_lines_arr.getLength()
            INSERT INTO doc_det VALUES m_lines_arr[i].*
        END FOR

        COMMIT WORK
        CALL utils_globals.msg_saved()
        RETURN TRUE

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_sql_error("save_document: Transaction failed - " || SQLERRMESSAGE)
        RETURN FALSE
    END TRY
END FUNCTION
```

### Pattern 7: Lookup Function

```4gl
FUNCTION lookup_customer()
    DEFINE l_cust_id STRING

    TRY
        LET l_cust_id = dl121_lkup.fetch_list()

        IF l_cust_id IS NOT NULL AND l_cust_id != "" THEN
            CALL load_customer_details(l_cust_id)
        END IF
    CATCH
        CALL utils_globals.show_error("Customer lookup failed: " || STATUS)
    END TRY
END FUNCTION
```

### Pattern 8: Dynamic SQL

```4gl
FUNCTION search_records(p_filter STRING)
    DEFINE l_sql STRING
    DEFINE l_arr DYNAMIC ARRAY OF RECORD
        id INTEGER,
        name VARCHAR(100)
    END RECORD

    LET l_sql = "SELECT id, name FROM table_name WHERE name ILIKE ?"

    TRY
        PREPARE search_stmt FROM l_sql
        DECLARE search_curs CURSOR FOR search_stmt
        OPEN search_curs USING p_filter

        FOREACH search_curs INTO l_arr[l_arr.getLength() + 1].*
        END FOREACH

        CLOSE search_curs
        FREE search_curs
        FREE search_stmt
    CATCH
        CALL utils_globals.show_sql_error("search_records: Search failed - " || SQLERRMESSAGE)
    END TRY

    RETURN l_arr
END FUNCTION
```

---

## Utility Functions Reference

### utils_globals.show_sql_error()
Displays SQL errors with technical details
```4gl
CALL utils_globals.show_sql_error("Context: " || SQLERRMESSAGE)
```

### utils_globals.show_error()
Displays user-friendly error messages
```4gl
CALL utils_globals.show_error("Operation failed. Please try again.")
```

### utils_globals.show_info()
Displays informational messages
```4gl
CALL utils_globals.show_info("Please save header first.")
```

### utils_globals.show_confirm()
Shows confirmation dialog
```4gl
IF utils_globals.show_confirm("Delete this record?", "Confirm") THEN
    -- proceed with delete
END IF
```

### Message Functions
```4gl
CALL utils_globals.msg_saved()      -- "Record saved successfully"
CALL utils_globals.msg_updated()    -- "Record updated successfully"
CALL utils_globals.msg_deleted()    -- "Record deleted successfully"
```

---

## SQL Error Information

### SQLCA.SQLCODE
- `0`: Success
- `100`: No data found (NOT FOUND)
- Negative: Error occurred

### SQLCA.SQLERRD[3]
Number of rows affected by INSERT, UPDATE, or DELETE

### SQLERRMESSAGE
Text description of the error

### SQLSTATE
5-character SQL state code

---

## Transaction Management

### Pattern: Single Operation
```4gl
BEGIN WORK
TRY
    -- Single operation
    COMMIT WORK
CATCH
    ROLLBACK WORK
    -- handle error
END TRY
```

### Pattern: Multiple Related Operations
```4gl
BEGIN WORK
TRY
    -- Operation 1
    -- Operation 2
    -- Operation 3
    COMMIT WORK
CATCH
    ROLLBACK WORK
    -- handle error
END TRY
```

### Pattern: Nested Checks
```4gl
BEGIN WORK
TRY
    INSERT INTO table1 VALUES rec1.*

    IF SQLCA.SQLCODE != 0 THEN
        ROLLBACK WORK
        CALL utils_globals.show_error("Failed to insert into table1")
        RETURN
    END IF

    INSERT INTO table2 VALUES rec2.*

    COMMIT WORK
CATCH
    ROLLBACK WORK
    CALL utils_globals.show_sql_error("Transaction failed: " || SQLERRMESSAGE)
END TRY
```

---

## Common Error Scenarios

### 1. Unique Constraint Violation
```4gl
TRY
    INSERT INTO table_name VALUES rec.*
CATCH
    IF SQLSTATE = "23505" THEN  -- PostgreSQL unique violation
        CALL utils_globals.show_error("Record already exists.")
    ELSE
        CALL utils_globals.show_sql_error("Insert failed: " || SQLERRMESSAGE)
    END IF
END TRY
```

### 2. Foreign Key Violation
```4gl
TRY
    DELETE FROM table_name WHERE id = p_id
CATCH
    IF SQLSTATE = "23503" THEN  -- PostgreSQL foreign key violation
        CALL utils_globals.show_error("Cannot delete: Record is referenced by other data.")
    ELSE
        CALL utils_globals.show_sql_error("Delete failed: " || SQLERRMESSAGE)
    END IF
END TRY
```

### 3. Connection Lost
```4gl
TRY
    -- Database operation
CATCH
    IF SQLCA.SQLCODE = -1 THEN
        CALL utils_globals.show_error("Database connection lost. Please reconnect.")
    ELSE
        CALL utils_globals.show_sql_error("Operation failed: " || SQLERRMESSAGE)
    END IF
END TRY
```

---

## Best Practices

1. **Always catch errors at the appropriate level**
   - Catch in the function where you can provide meaningful context
   - Let higher-level functions handle UI feedback

2. **Use transactions for data integrity**
   - BEGIN WORK before multiple related operations
   - COMMIT on success, ROLLBACK on error

3. **Free resources in CATCH blocks**
   ```4gl
   TRY
       DECLARE curs CURSOR FOR SELECT ...
       FOREACH curs INTO ...
       END FOREACH
       CLOSE curs
       FREE curs
   CATCH
       CLOSE curs  -- Free even on error
       FREE curs
       -- handle error
   END TRY
   ```

4. **Validate before database operations**
   ```4gl
   IF NOT validate_data() THEN
       RETURN
   END IF

   TRY
       -- Database operation
   CATCH
       -- handle error
   END TRY
   ```

5. **Log errors for debugging**
   - Include function name in error messages
   - Include operation context
   - Include SQL error details

6. **Test error paths**
   - Test constraint violations
   - Test connection failures
   - Test transaction rollbacks

---

## Module-Specific Patterns

### Sales Quote Module (sa130_quote.4gl)
✅ Comprehensive TRY-CATCH implemented
- Load operations
- Save operations (header and lines)
- Delete operations
- Stock lookup integration

### Purchase Order Module (pu130_order.4gl)
✅ TRY-CATCH implemented in key areas
- Supplier lookup
- Stock lookup
- Header/line saves

### GRN Module (pu131_grn.4gl)
⚠️ Needs review for comprehensive coverage

### Warehouse Module (wh130_trf.4gl)
✅ TRY-CATCH implemented
- Load/save transactions
- Navigation operations

---

## Implementation Checklist

- [ ] All SELECT statements wrapped in TRY-CATCH
- [ ] All INSERT statements wrapped in TRY-CATCH with transactions
- [ ] All UPDATE statements wrapped in TRY-CATCH with transactions
- [ ] All DELETE statements wrapped in TRY-CATCH with transactions
- [ ] All FOREACH loops wrapped in TRY-CATCH
- [ ] All cursors properly freed in CATCH blocks
- [ ] All prepared statements properly freed
- [ ] Error messages include function context
- [ ] User-friendly messages displayed
- [ ] Technical details logged for debugging

---

## Script Usage

Use the provided Python script to automatically add TRY-CATCH blocks:

```bash
python add_error_handling.py src/sa/sa130_quote.4gl
```

Or process an entire directory:

```bash
python add_error_handling.py src/
```

**Note:** The script creates `.bak` backups before modifying files.

---

## Testing Error Handling

### Test Scenarios
1. Network disconnection during operation
2. Constraint violations (unique, foreign key)
3. Invalid data types
4. Missing required fields
5. Concurrent updates (optimistic locking)
6. Transaction deadlocks
7. Disk space exhaustion

### Verification
```sql
-- Trigger unique constraint violation
INSERT INTO table_name (id, name) VALUES (1, 'Test');
INSERT INTO table_name (id, name) VALUES (1, 'Test');

-- Trigger foreign key violation
DELETE FROM parent_table WHERE id = 1;  -- when child records exist

-- Test connection loss
-- Disconnect network during operation
```

---

## Conclusion

Comprehensive error handling ensures:
- Stable application behavior
- Data integrity
- Better user experience
- Easier debugging and maintenance
- Protection against data corruption

Always implement TRY-CATCH blocks for all database operations and provide meaningful feedback to users.
