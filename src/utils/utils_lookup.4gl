-- ==============================================================
-- Program   : utils_lookup.4gl
-- ==============================================================

IMPORT FGL utils_globals

-- Redirect all lookup functions to optimized generic implementation
FUNCTION lookup_creditor(search_val STRING) RETURNS STRING
    RETURN utils_globals.lookup_supplier(search_val)
END FUNCTION

FUNCTION lookup_warehouse(search_val STRING, field_name STRING) RETURNS STRING
    RETURN utils_globals.generic_lookup(
        "wh01_mast", "wh_code", "wh_name", search_val, "Warehouse", field_name)
END FUNCTION

--FUNCTION lookup_stock(search_val STRING) RETURNS STRING
--    RETURN utils_globals.lookup_stock(search_val)
--END FUNCTION

FUNCTION lookup_stock_category(
    search_val STRING, field_name STRING)
    RETURNS STRING
    RETURN utils_globals.generic_lookup(
        "st_cat",
        "cat_code",
        "cat_name",
        search_val,
        "Stock Category",
        field_name)
END FUNCTION

FUNCTION lookup_sales_order(search_val STRING, field_name STRING) RETURNS STRING
    RETURN utils_globals.generic_lookup(
        "sa30_hdr", "doc_no", "acc_code", search_val, "Sales Order", field_name)
END FUNCTION

FUNCTION lookup_purchase_order(
    search_val STRING, field_name STRING)
    RETURNS STRING
    RETURN utils_globals.generic_lookup(
        "pu30_hdr",
        "doc_no",
        "acc_code",
        search_val,
        "Purchase Order",
        field_name)
END FUNCTION
