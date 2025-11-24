c:\Users\dlami\OneDrive\Documents\GeneroDev\XactERPDemo\src\README_MASTERS.md
# Master Modules: Feedback and Changes

## Overview
- Enforce empty-on-init for all `_mast` modules.
- Gate navigation until a record is found via Find/List.
- Fix navigation to load the current index, not the first record.

## Findings
- `st101_mast`: `move_record` loads `arr_codes[1]` instead of `arr_codes[curr_idx]`.
- Several masters preload records on init; should start with an empty form and require Find/List first.

## Required Changes
- Remove preload calls in `init_*_module` (e.g., `load_all_*`, `select_*`).
- Initialize and display empty record on init.
- Fix navigation to respect `curr_idx`.

## Code Snippets

### Empty Init Pattern
FUNCTION init_st_module()
    LET is_edit_mode = FALSE
    INITIALIZE rec_stock.* TO NULL
    DISPLAY BY NAME rec_stock.*
    MENU "Stock Master Menu"
        COMMAND "Find" CALL query_stock_lookup()
        COMMAND "New"  CALL new_stock()
        COMMAND "Edit"
            IF rec_stock.id IS NULL OR rec_stock.id = 0 THEN
                CALL utils_globals.show_info("No record selected.")
            ELSE
                CALL edit_stock()
            END IF
        COMMAND "Previous" CALL move_record(-1)
        COMMAND "Next"     CALL move_record(1)
        COMMAND "Exit"     EXIT MENU
    END MENU
END FUNCTION

### Navigation Fix (Stock Master)
FUNCTION move_record(dir SMALLINT)
    DEFINE new_idx INTEGER
    IF arr_codes.getLength() = 0 THEN
        CALL utils_globals.show_info("No records to navigate.")
        RETURN
    END IF
    LET new_idx = utils_globals.navigate_records(arr_codes, curr_idx, dir)
    LET curr_idx = new_idx
    CALL load_stock_item(arr_codes[curr_idx])
END FUNCTION

### Empty Init in Other Masters
FUNCTION init_wh_module()
    LET is_edit_mode = FALSE
    INITIALIZE rec_wh.* TO NULL
    DISPLAY BY NAME rec_wh.*
    MENU "Warehouse Menu"
        COMMAND "Find"     CALL query_warehouses()
        COMMAND "New"      CALL new_warehouse()
        COMMAND "Edit"     IF rec_wh.wh_code IS NOT NULL THEN CALL edit_warehouse() END IF
        COMMAND "Previous" CALL move_record(-1)
        COMMAND "Next"     CALL move_record(1)
        COMMAND "Exit"     EXIT MENU
    END MENU
END FUNCTION

## Tasks
- Remove initial preload from `init_*_module` in `wh101_mast`, `wb101_mast`, `st102_cat`, `st103_uom_mast`, `dl101_mast`. 
- Add explicit empty form initialization across all masters.
- Fix `st101_mast.move_record` to load `arr_codes[curr_idx]`.
- Keep creditors’ navigation gating as the reference pattern for all masters.

c:\Users\dlami\OneDrive\Documents\GeneroDev\XactERPDemo\src\README_DOCS.md
# Document Modules (PU/SA): Feedback and Changes

## Overview
- On init, present an empty doc and a menu with New/Find/Exit.
- On New, set header defaults: doc_no, date, status, zero totals, created_by.
- Customer/Supplier lookups must populate header fields consistently.

## Findings
- App menu dispatch calls `new_*` directly for SA/PU, bypassing empty-on-init.
- `sa130_quote` uses `id` inconsistently instead of `cust_id` for customer lookup.
- PO/GRN/Invoice/Order correctly zero totals and set defaults on New.

## Required Changes
- Add init controllers for each doc module; call these from the menu.
- Standardize customer lookup to `cust_id`; supplier lookup to `id`.
- Ensure header defaults and zero totals on New in all docs.

## Code Snippets

### Init Controller Skeleton (Invoice)
FUNCTION init_sa_invoice()
    INITIALIZE m_rec_inv.* TO NULL
    DISPLAY BY NAME m_rec_inv.*
    MENU "Invoice"
        COMMAND "New"  CALL new_invoice()
        COMMAND "Find" CALL find_invoice()
        COMMAND "Exit" EXIT MENU
    END MENU
END FUNCTION

### Menu Dispatch to Init (not new)
CASE module_name
    WHEN "sa132_invoice" CALL sa132_invoice.init_sa_invoice()
    WHEN "sa131_order"   CALL sa131_order.init_sa_order()
    WHEN "sa130_quote"   CALL sa130_quote.init_sa_quote()
    WHEN "pu130_order"   CALL pu130_order.init_po_module()
    WHEN "pu131_grn"     CALL pu131_grn.init_pu_grn()
    WHEN "pu132_inv"     CALL pu132_inv.init_pu_inv()
    OTHERWISE CALL utils_globals.show_error("Module not implemented: " || module_name)
END CASE

### Header Defaults on New (Order)
FUNCTION new_order()
    DEFINE l_hdr RECORD LIKE sa31_ord_hdr.*
    DEFINE l_next_doc_no INTEGER
    SELECT COALESCE(MAX(doc_no), 0) + 1 INTO l_next_doc_no FROM sa31_ord_hdr
    INITIALIZE l_hdr.* TO NULL
    LET l_hdr.doc_no    = l_next_doc_no
    LET l_hdr.trans_date = TODAY
    LET l_hdr.status     = "NEW"
    LET l_hdr.created_at = CURRENT
    LET l_hdr.created_by = utils_globals.get_current_user_id()
    LET l_hdr.gross_tot  = 0
    LET l_hdr.vat_tot    = 0
    LET l_hdr.disc_tot   = 0
    LET l_hdr.net_tot    = 0
    INPUT BY NAME l_hdr.cust_id, l_hdr.trans_date, l_hdr.ref_doc_type, l_hdr.ref_doc_no
        ATTRIBUTES(WITHOUT DEFAULTS, UNBUFFERED)
        ON ACTION accept ACCEPT INPUT
        ON ACTION cancel  EXIT INPUT
    END INPUT
END FUNCTION

### Supplier Lookup Population (PO From Master)
FUNCTION new_po_from_master(p_supp_id INTEGER)
    SELECT * INTO m_crd_rec.* FROM cl01_mast WHERE id = p_supp_id
    INITIALIZE m_po_hdr_rec.* TO NULL
    LET m_po_hdr_rec.doc_no = utils_globals.get_next_code('pu30_ord_hdr', 'id')
    LET m_po_hdr_rec.trans_date = TODAY
    LET m_po_hdr_rec.status = "draft"
    LET m_po_hdr_rec.created_at = TODAY
    LET m_po_hdr_rec.created_by = utils_globals.get_random_user()
    LET m_po_hdr_rec.supp_id = m_crd_rec.id
    LET m_po_hdr_rec.supp_name = m_crd_rec.supp_name
    LET m_po_hdr_rec.supp_phone = m_crd_rec.phone
    LET m_po_hdr_rec.supp_email = m_crd_rec.email
    LET m_po_hdr_rec.supp_address1 = m_crd_rec.address1
    LET m_po_hdr_rec.supp_address2 = m_crd_rec.address2
    LET m_po_hdr_rec.supp_address3 = m_crd_rec.address3
    LET m_po_hdr_rec.supp_postal_code = m_crd_rec.postal_code
    LET m_po_hdr_rec.supp_vat_no = m_crd_rec.vat_no
    LET m_po_hdr_rec.supp_payment_terms = m_crd_rec.payment_terms
    LET m_po_hdr_rec.gross_tot = 0
    LET m_po_hdr_rec.disc_tot = 0
    LET m_po_hdr_rec.vat_tot = 0
    LET m_po_hdr_rec.net_tot = 0
END FUNCTION

### Customer Lookup Population (Invoice)
INPUT BY NAME l_hdr.cust_id, l_hdr.trans_date, l_hdr.due_date, l_hdr.ref_doc_type, l_hdr.ref_doc_no
    ATTRIBUTES(WITHOUT DEFAULTS, UNBUFFERED)
    AFTER FIELD cust_id
        IF l_hdr.cust_id IS NOT NULL THEN
            CALL load_customer_details(l_hdr.cust_id)
                RETURNING l_hdr.cust_id, l_hdr.cust_name,
                          l_hdr.cust_phone, l_hdr.cust_email, l_hdr.cust_address1,
                          l_hdr.cust_address2, l_hdr.cust_address3,
                          l_hdr.cust_postal_code, l_hdr.cust_vat_no,
                          l_hdr.cust_payment_terms
        END IF
    ON ACTION lookup_customer
        CALL dl121_lkup.load_lookup_form_with_search() RETURNING l_hdr.cust_id
        IF l_hdr.cust_id IS NOT NULL THEN
            CALL load_customer_details(l_hdr.cust_id)
                RETURNING l_hdr.cust_id, l_hdr.cust_name,
                          l_hdr.cust_phone, l_hdr.cust_email, l_hdr.cust_address1,
                          l_hdr.cust_address2, l_hdr.cust_address3,
                          l_hdr.cust_postal_code, l_hdr.cust_vat_no,
                          l_hdr.cust_payment_terms
            DISPLAY BY NAME l_hdr.cust_id
        END IF
END INPUT

## Tasks
- Add init controllers for `sa130_quote`, `sa131_order`, `sa132_invoice`, `pu131_grn`, `pu132_inv` that start with empty headers and expose New/Find/Exit.
- Update main dispatch in `_main/start_app.4gl` to call init controllers, not `new_*`.
- Standardize `sa130_quote` to use `cust_id` for lookup and header population.
- Verify totals are zeroed on New for all docs; already implemented in PO/GRN/Order/Invoice/Quote.