# ==============================================================
# Consolidated Lookup Utilities
# File: 4gl
# 
# Version: 2.0.0
# ==============================================================

IMPORT ui
IMPORT FGL utils_db
IMPORT FGL fgldialog
IMPORT FGL utils_lookup
IMPORT FGL utils_globals

-- ==============================================================
-- LOOKUP UTILITIES
-- ==============================================================

-- Generic lookup function (replaces multiple specific lookup functions)
PUBLIC FUNCTION generic_lookup(
    table_name STRING,
    code_field STRING,
    desc_field STRING,
    search_value STRING,
    title STRING,
    return_field STRING)
    RETURNS STRING

    DEFINE l_sql STRING
    DEFINE results DYNAMIC ARRAY OF r_lookup_result
    DEFINE selected_index INTEGER
    DEFINE where_clause STRING

    -- Build WHERE clause if search value provided
    IF NOT is_empty(search_value) THEN
        LET where_clause =
            " WHERE "
                || code_field
                || " ILIKE '%"
                || search_value
                || "%' OR "
                || desc_field
                || " ILIKE '%"
                || search_value
                || "%'"
    ELSE
        LET where_clause = ""
    END IF

    LET l_sql =
        "SELECT "
            || code_field
            || ", "
            || desc_field
            || " FROM "
            || table_name
            || where_clause
            || " ORDER BY "
            || code_field

    CALL execute_lookup_query(l_sql, results)

    IF results.getLength() > 0 THEN
        LET selected_index = display_lookup_dialog(results, title)
        IF selected_index > 0 THEN
            CASE return_field
                WHEN "code"
                    RETURN results[selected_index].code
                WHEN "description"
                    RETURN results[selected_index].description
                OTHERWISE
                    RETURN results[selected_index].code
            END CASE
        END IF
    END IF

    RETURN ""
END FUNCTION

-- ===========================
-- Specific lookup wrappers
-- ===========================

-- search for debtors
PUBLIC FUNCTION lookup_debtor(p_search STRING) RETURNS STRING
    RETURN generic_lookup(
        "dl01_mast",
        "acc_code",
        "cust_name",
        p_search,
        "Customer Lookup",
        "acc_code")
END FUNCTION

-- search for the suppliers
PUBLIC FUNCTION lookup_supplier(p_search STRING) RETURNS STRING
    RETURN generic_lookup(
        "cl01_mast",
        "acc_code",
        "supp_name",
        p_search,
        "Supplier Lookup",
        "acc_code")
END FUNCTION

-- search for stock
PUBLIC FUNCTION lookup_stock(p_search STRING) RETURNS STRING
    RETURN generic_lookup(
        "st01_mast",
        "acc_code",
        "supp_name",
        p_search,
        "Supplier Lookup",
        "acc_code")
END FUNCTION

-- warehouse look up
FUNCTION lookup_warehouse(search_val STRING, field_name STRING) RETURNS STRING
    RETURN generic_lookup(
        "wh01_mast", "wh_code", "wh_name", search_val, "Warehouse", field_name)
END FUNCTION

-- look up stock categories
FUNCTION lookup_stock_category(
    search_val STRING, field_name STRING)
    RETURNS STRING
    RETURN generic_lookup(
        "st_cat",
        "cat_code",
        "cat_name",
        search_val,
        "Stock Category",
        field_name)
END FUNCTION

-- lookup for sales orders
FUNCTION lookup_sales_order(search_val STRING, field_name STRING) RETURNS STRING
    RETURN generic_lookup(
        "sa30_hdr", "doc_no", "acc_code", search_val, "Sales Order", field_name)
END FUNCTION

--look up purchase orders
FUNCTION lookup_purchase_order(
    search_val STRING, field_name STRING)
    RETURNS STRING
    RETURN generic_lookup(
        "pu30_hdr",
        "doc_no",
        "acc_code",
        search_val,
        "Purchase Order",
        field_name)
END FUNCTION

-- Helper function for lookup queries
PRIVATE FUNCTION execute_lookup_query(
    p_sql STRING, results DYNAMIC ARRAY OF r_lookup_result)
    DEFINE idx INTEGER
    LET idx = 0

    TRY
        DECLARE lookup_cursor CURSOR FROM p_sql
        FOREACH lookup_cursor
            INTO results[idx + 1].code, results[idx + 1].description
            LET idx = idx + 1
        END FOREACH
        CLOSE lookup_cursor
        FREE lookup_cursor
    CATCH
        CALL show_error("Lookup query failed: " || SQLCA.SQLERRM)
    END TRY
END FUNCTION

-- display the lookup dialog
PRIVATE FUNCTION display_lookup_dialog(
    results DYNAMIC ARRAY OF r_lookup_result, title STRING)
    RETURNS INTEGER

    -- In real implementation, would show proper lookup form
    IF results.getLength() = 1 THEN
        RETURN 1 -- Auto-select if only one result
    END IF

    -- set look up form title
    CALL utils_globals.set_page_title(title)
    OPTIONS INPUT WRAP
    OPEN WINDOW w_lkup WITH FORM "utils_lkup_form"

    -- For now, return first result
    RETURN IIF(results.getLength() > 0, 1, 0)
END FUNCTION
