# XactERP - Tasks To Do

## Core Functionality Fixes

### Document Conversion Workflows
- [ ] **Implement PO-to-GRN conversion logic** - Currently just shows an info message. Need to create actual GRN records from purchase orders, including all line items, quantities, and stock updates (pu130_order.4gl:767)

- [ ] **Add navigation from Quote to converted Order** - When a quote is converted to an order, users should be able to click to view the created order. Currently shows placeholder message (sa130_quote.4gl:949)

- [ ] **Add navigation from Order to converted Invoice** - When an order is converted to an invoice, users should be able to navigate to view the created invoice. Currently shows placeholder message (sa131_order.4gl:1286)

- [ ] **Fix quote line editing** - Critical bug where array assignment is commented out, preventing quote lines from being properly saved when edited. Need to fix the array assignment logic (sa130_quote.4gl:478-482)

- [ ] **Fix invoice line editing** - Array assignment logic for editing invoice lines needs to be implemented or corrected. May cause issues when modifying existing invoice lines (sa132_invoice.4gl:262)

### Stock Management
- [ ] **Implement full stock reservation system** - Database has stock_ordered column but it's not being fully utilized. When orders are created, available stock should be reserved and unavailable for other orders

- [ ] **Update PO module to reserve stock on order creation** - Purchase orders should update stock_ordered when created so the system knows stock is incoming

- [ ] **Update Sales Order module to reserve stock on order creation** - Sales orders should reserve stock_ordered to prevent overselling

- [ ] **Implement stock release when orders are cancelled** - When PO or Sales Orders are cancelled, their reserved stock quantities need to be released back to available

- [ ] **Add stock validation before order confirmation** - Prevent users from creating orders when insufficient stock is available, show clear messages about stock levels

## Data Quality & Consistency

### Database Schema
- [ ] **Standardize schema name** - One module uses 'demoapp_db' (sy104_user_pwd.4gl) while all others use 'demoappdb'. This inconsistency could cause runtime errors

- [ ] **Audit all RECORD LIKE assignments** - Verify that all record definitions match actual database table structures. Fields may have been added/removed from tables without updating code

- [ ] **Verify all field references match database schema** - Check all SQL queries and RECORD.field references to ensure they match current database column names

### Validation
- [ ] **Fix phone validation regex mismatch** - Validation pattern expects 11 digits but error message tells users to enter 10 digits. Need to align these (utils_globals.4gl:569-583)

- [ ] **Add consistent email validation across all modules** - Some modules validate email format, others don't. Standardize email regex pattern across creditor, debtor, warehouse, and branch modules

- [ ] **Implement proper date range validation** - Ensure end dates are after start dates, transaction dates are not in the future, and date ranges are reasonable

- [ ] **Add numeric field boundary checks** - Quantities, prices, and amounts should have min/max validation. Prevent negative quantities, unreasonable prices, etc.

- [ ] **Implement cross-field validation rules** - Check business rules like: total amounts match line totals, required fields for certain transaction types, etc.

## UI/UX Improvements

### Navigation & Data Loading
- [ ] **Enforce empty-on-init pattern for all master modules** - Master modules (customer, supplier, stock, etc.) should open empty, not pre-loaded with data. Users should search/query first

- [ ] **Remove load_all_*() calls from init functions** - Several modules still call load_all_records() on startup which is slow and defeats the empty-on-init pattern

- [ ] **Fix navigation index bugs** - When navigating between records (next/previous), some modules always load arr_codes[1] instead of arr_codes[curr_idx], causing incorrect record to display

- [ ] **Update move_record() function in all master modules** - Standardize the record navigation logic to use current index, not hardcoded array position

- [ ] **Deduplicate action names in menu files** - Some menu actions have duplicate names (like multiple 'st_mast') which can cause action handler conflicts

### Form Behavior
- [ ] **Ensure all lookup forms return to correct record after selection** - After using a lookup to select a customer/product/etc, the parent form should refresh and show the selected record

- [ ] **Standardize dialog message formatting** - Info, warning, and error messages should have consistent wording and formatting across all modules

- [ ] **Implement consistent error message display** - All error messages should be user-friendly, explain what went wrong, and suggest how to fix it

- [ ] **Add confirmation dialogs for all delete operations** - Every delete action should ask "Are you sure?" with clear indication of what will be deleted

- [ ] **Standardize cancel/back button behavior** - Cancel should consistently discard changes and return to previous screen, with confirmation if changes were made

## Missing Module Implementations

### Enquiry Modules
- [ ] **Implement cl120_mast - Creditors Enquiry** - Read-only view of creditor accounts with filtering, searching, and drill-down to transactions. No editing capability

- [ ] **Implement dl120_mast - Debtors Enquiry** - Read-only view of debtor accounts with filtering, searching, and drill-down to transactions and orders

- [ ] **Enhance st120_enq - Stock Enquiry** - Current implementation is basic. Needs filtering by category, warehouse, stock levels, and showing transaction history

- [ ] **Implement wh120_stock - Warehouse Stock Enquiry** - View stock quantities by warehouse, with filtering and searching. Show stock movements in/out

- [ ] **Implement wb120_stock - Bin Stock Enquiry** - View stock at bin location level within warehouses. Show which bin has what stock and quantities

### Transaction Enquiry
- [ ] **Implement cl121_tran - Creditors Transactions Enquiry** - View all transactions for creditors: invoices, payments, adjustments. Filter by date range, amount, status

- [ ] **Implement dl121_tran - Debtors Transactions Enquiry** - View all debtor transactions: invoices, payments, credit notes. Filter by date, customer, amount

- [ ] **Implement st121_tran - Stock Transactions Enquiry** - View all stock movements: receipts, issues, adjustments, transfers. Filter by date, product, warehouse

### Transaction Processing
- [ ] **Implement st130_adj - Stock Adjustment module** - Allow manual stock adjustments for stocktake, damage, theft. Require reason codes and authorization

- [ ] **Complete wh130_trans - Warehouse Transfer module** - Transfer stock between warehouses. Update stock levels at both source and destination warehouses

- [ ] **Implement stock movement tracking** - Every stock transaction should create an audit record showing what moved, when, why, and who did it

- [ ] **Add audit trail for all transactions** - All financial and stock transactions need complete audit trail: user, timestamp, before/after values, reason

## Code Quality

### Code Cleanup
- [ ] **Fix incomplete TODO comment with typo** - Comment says "Fix this so taht the lines are" but is incomplete. Clarify what needs to be fixed (sa130_quote.4gl:478)

- [ ] **Remove all commented-out code that's no longer needed** - Lots of old code commented out throughout modules. Either implement or delete it

- [ ] **Standardize code formatting across all modules** - Indentation, spacing, naming conventions should be consistent across all .4gl files

- [ ] **Add consistent function header comments** - Every function should have comment explaining purpose, parameters, return values, and any side effects

- [ ] **Document all global variables** - All module-level variables should have comments explaining their purpose and lifecycle

### Error Handling
- [ ] **Add try-catch blocks to all database operations** - Every SQL statement should be wrapped in WHENEVER ERROR to handle database failures gracefully

- [ ] **Implement consistent error logging** - All errors should be logged with timestamp, user, module, function, and error details for troubleshooting

- [ ] **Add user-friendly error messages** - Replace technical database errors with clear messages users can understand and act on

- [ ] **Handle null/empty result sets gracefully** - Queries that return no rows should show appropriate message, not error or blank screen

- [ ] **Add transaction rollback on errors** - If any part of a multi-step transaction fails, roll back all changes and leave database in clean state

### Performance
- [ ] **Review all database queries for optimization** - Look for missing WHERE clauses, inefficient joins, selecting unnecessary columns

- [ ] **Add indexes for frequently queried fields** - Common filter/search fields should have database indexes to speed up queries

- [ ] **Implement pagination for large result sets** - Modules that load many records should use LIMIT/OFFSET or cursor pagination

- [ ] **Cache frequently accessed lookup data** - Customer types, categories, units of measure could be cached in memory instead of queried repeatedly

- [ ] **Optimize array operations in line editing** - Line editing (quote/order/invoice lines) does a lot of array manipulation which could be optimized

## Testing & Documentation

### Testing
- [ ] **Create test cases for all document conversions** - Test quote→order, order→invoice, PO→GRN workflows with various scenarios and edge cases

- [ ] **Test all CRUD operations in master modules** - Verify create, read, update, delete works correctly in all master data modules

- [ ] **Validate all lookup functionality** - Test all lookup forms return correct data and integrate properly with parent forms

- [ ] **Test multi-user scenarios** - Verify concurrent users can work without conflicts, record locking works correctly

- [ ] **Test transaction rollback scenarios** - Verify that errors during transactions properly rollback and don't leave partial data

### Documentation
- [ ] **Document all module dependencies** - Map which modules depend on which others, shared code, database tables used

- [ ] **Create user manual for each module** - Step-by-step instructions with screenshots for each business process

- [ ] **Document database schema** - Complete ERD with table descriptions, field definitions, relationships, and constraints

- [ ] **Create API documentation for shared functions** - Document all utils functions with parameters, return values, usage examples

- [ ] **Document workflow diagrams for all processes** - Visual flowcharts showing business process steps from start to finish
