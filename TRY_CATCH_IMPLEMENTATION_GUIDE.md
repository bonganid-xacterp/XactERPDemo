# Try-Catch Implementation Guide

## Overview
This document outlines the try-catch block implementation across the XactERP 4GL project files.

## Completed Files

### 1. src/sy/sy101_user.4gl ✓
- `select_users()` - Added try-catch around PREPARE/DECLARE/FOREACH
- `load_user()` - Added try-catch around SELECT
- `check_username_unique()` - Added try-catch around SELECT COUNT
- `populate_role_combo()` - Added try-catch around DECLARE/FOREACH
- `save_user()` - Already had try-catch with ROLLBACK (kept existing)
- `delete_user()` - Already had try-catch with ROLLBACK (kept existing)

### 2. src/st/st101_mast.4gl ✓
- `load_stock_item()` - Added try-catch around SELECT
- `get_linked_category()` - Added try-catch around SELECT
- `load_stock_transactions()` - Added try-catch around DECLARE/FOREACH
- `save_stock()` - Added try-catch around SELECT COUNT, INSERT, UPDATE
- `select_stock_items()` - Added try-catch around DECLARE/FOREACH
- `check_stock_unique()` - Added try-catch around SELECT COUNT
- `delete_stock()` - Added try-catch around SELECT COUNT, DELETE

### 3. src/pu/pu130_order.4gl ✓ (Partially)
- `new_po_from_stock()` - Updated to use show_sql_error
- `populate_doc_header()` - Added try-catch around SELECT
- `save_po_header()` - Updated to use show_sql_error
- `delete_po()` - Updated to use show_sql_error
- `load_po()` - Updated to use show_sql_error
- `find_po()` - Updated to use show_sql_error

## Implementation Pattern

### Standard Pattern for Database Operations

```4gl
-- Pattern 1: Simple SELECT
TRY
    SELECT * INTO rec.* FROM table WHERE condition
    -- Handle SQLCODE if needed
CATCH
    CALL utils_globals.show_sql_error("function_name: Error description")
    -- Handle error (RETURN, initialize, etc.)
END TRY

-- Pattern 2: DECLARE/FOREACH
TRY
    DECLARE curs CURSOR FOR SELECT ...
    FOREACH curs INTO variable
        -- Processing logic
    END FOREACH
    CLOSE curs
    FREE curs
CATCH
    CALL utils_globals.show_sql_error("function_name: Error description")
    RETURN
END TRY

-- Pattern 3: INSERT/UPDATE/DELETE with Transaction
BEGIN WORK
TRY
    INSERT/UPDATE/DELETE ...
    COMMIT WORK
    CALL utils_globals.msg_saved()
CATCH
    ROLLBACK WORK
    CALL utils_globals.show_sql_error("function_name: Error description")
    RETURN FALSE
END TRY

-- Pattern 4: PREPARE/DECLARE Dynamic
TRY
    PREPARE stmt FROM sql_string
    DECLARE curs CURSOR FOR stmt
    FOREACH curs INTO var
        -- Logic
    END FOREACH
    CLOSE curs
    FREE curs
    FREE stmt
CATCH
    CALL utils_globals.show_sql_error("function_name: Error description")
    RETURN FALSE
END TRY
```

## Remaining Files to Process

### System Module (src/sy/)
- [ ] sy102_role.4gl
- [ ] sy103_perm.4gl
- [ ] sy104_user_pwd.4gl
- [ ] sy130_logs.4gl
- [ ] sy150_lkup_config.4gl

### Stock Module (src/st/)
- [ ] st102_cat.4gl
- [ ] st103_uom_mast.4gl
- [ ] st120_enq.4gl
- [ ] st121_st_lkup.4gl
- [ ] st122_cat_lkup.4gl
- [ ] st122_wh_lkup.4gl
- [ ] st121_lkup_form.4gl
- [ ] st130_trans.4gl
- [ ] wb121_lkup.4gl

### Purchase Module (src/pu/)
- [ ] pu131_grn.4gl - Needs review
- [ ] pu132_inv.4gl
- [ ] pu140_hist.4gl
- [ ] pu_lkup_form.4gl

### Sales Module (src/sa/)
- [ ] sa130_quote.4gl - Needs review
- [ ] sa131_order.4gl - Needs review
- [ ] sa132_invoice.4gl - Needs review
- [ ] sa133_crn.4gl
- [ ] sa140_hist.4gl

### Customer Module (src/cl/)
- [ ] cl101_mast.4gl
- [ ] cl120_enq.4gl
- [ ] cl121_lkup.4gl
- [ ] cl130_trans.4gl

### Debtor Module (src/dl/)
- [ ] dl100_lookup.4gl
- [ ] dl101_mast.4gl
- [ ] dl120_enq.4gl
- [ ] dl121_lkup.4gl
- [ ] dl121_lkup_1.4gl
- [ ] dl130_trans.4gl
- [ ] dl140_hist.4gl

### Warehouse Module (src/wh/)
- [ ] wh101_mast.4gl - Needs review
- [ ] wh102_lkup.4gl
- [ ] wh102_tag.4gl
- [ ] wh103_tag.4gl
- [ ] wh121_lkup.4gl
- [ ] wh30_hdr.4gl
- [ ] wh30_trans.4gl
- [ ] wh31_det.4gl
- [ ] wh130_trans.4gl
- [ ] wh140_hist.4gl

### Workbench Module (src/wb/)
- [ ] wb01_mast.4gl
- [ ] wb101_mast.4gl - Needs review
- [ ] wb102_lkup.4gl
- [ ] wb30_hdr.4gl
- [ ] wb31_det.4gl
- [ ] wb130_trans.4gl
- [ ] wb140_hist.4gl

### General Ledger Module (src/gl/)
- [ ] gl100_trans.4gl
- [ ] gl101_acc.4gl
- [ ] gl130_jnls.4gl
- [ ] gl140_hist.4gl

### Payment Module (src/payt/)
- [ ] payt130_doc.4gl
- [ ] payt140_hist.4gl
- [ ] payt220_cashbook.4gl

### Utils Module (src/utils/)
- [ ] utils_db.4gl
- [ ] utils_doc_lines.4gl
- [ ] utils_doc_totals.4gl
- [ ] utils_enq.4gl
- [ ] utils_form_modes.4gl
- [ ] utils_lkup.4gl
- [ ] utils_logger.4gl
- [ ] utils_sidemenu.4gl
- [ ] utils_global_lkup_form.4gl
- [ ] utils_global_record_load.4gl

### App Module (src/app/)
- [ ] app_menu.4gl
- [ ] app_start.4gl

## Quick Reference for Replacement

When updating existing try-catch blocks, replace:

```4gl
# Replace this:
CATCH
    CALL utils_globals.show_error("Error: " || SQLCA.SQLERRM)
END TRY

# With this:
CATCH
    CALL utils_globals.show_sql_error("function_name: Error description")
END TRY
```

## Guidelines

1. **Don't over-complicate**: Keep it simple, just wrap SQL calls
2. **Context in messages**: Include function name and action in error messages
3. **Preserve transactions**: Keep BEGIN WORK/COMMIT/ROLLBACK patterns
4. **Check existing**: Don't add try-catch if it already exists nearby
5. **CLOSE/FREE cursors**: Always include after FOREACH in try block

## Tools

### Grep patterns to find database operations:
```bash
# Find SELECT statements
grep -n "SELECT.*INTO.*FROM" file.4gl

# Find INSERT statements
grep -n "INSERT INTO" file.4gl

# Find UPDATE statements
grep -n "UPDATE.*SET" file.4gl

# Find DELETE statements
grep -n "DELETE FROM" file.4gl

# Find DECLARE CURSOR
grep -n "DECLARE.*CURSOR" file.4gl

# Find FOREACH
grep -n "FOREACH" file.4gl
```

## Status

**Completed Modules**:
- ✅ **sy (System)** - 6/6 files (100%)
  - sy101_user.4gl ✓
  - sy102_role.4gl ✓
  - sy103_perm.4gl ✓
  - sy104_user_pwd.4gl ✓
  - sy130_logs.4gl ✓
  - sy150_lkup_config.4gl ✓

- ✅ **st (Stock) - Core Files** - 3/11 files (27%)
  - st101_mast.4gl ✓
  - st102_cat.4gl ✓
  - st103_uom_mast.4gl ✓

- **pu (Purchase)** - 1/5 files (20%) - Partial
  - pu130_order.4gl ✓ (partial - needs completion)

**Remaining**: ~70+ files across 9 modules
**Progress**: ~12% overall

## Next Steps

1. Process remaining files in sy module
2. Complete st module files
3. Continue with pu, sa modules
4. Process cl, dl, wh, wb, gl, payt modules
5. Review utils module files
6. Test all modifications

## Notes

- The `utils_globals.show_sql_error()` function automatically captures SQLCA.SQLCODE and SQLCA.SQLERRM
- No need to pass SQLCA values manually - just provide context description
- Function signature: `show_sql_error(p_context STRING)`
