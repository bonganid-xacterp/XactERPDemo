# ============================================================================
# UTILS LOOKUP MODULE
# Split lookups by group: Masters, Stock, Documents
# ============================================================================
IMPORT ui

# Shared result type
TYPE t_lookup_result RECORD
    code        STRING,
    description STRING,
    field3      STRING,
    field4      STRING,
    field5      STRING
END RECORD

# ============================================================================
# MASTER LOOKUPS
# ============================================================================

FUNCTION lookup_debtor(search_val STRING, field_name STRING)
    RETURNS STRING

    DEFINE sql_query STRING
    LET sql_query = "SELECT acc_code, cust_name, address1, phone, cr_limit "
                  || "FROM dl01_mast "
                  || build_where(search_val, "acc_code", "cust_name")
                  || " ORDER BY acc_code"

    RETURN do_lookup(sql_query, "Debtor", field_name)

END FUNCTION

FUNCTION lookup_creditor(search_val STRING, field_name STRING)
    RETURNS STRING

    DEFINE sql_query STRING
    LET sql_query = "SELECT acc_code, supplier_name, address1, phone, payment_terms "
                  || "FROM cl01_mast "
                  || build_where(search_val, "acc_code", "supplier_name")
                  || " ORDER BY acc_code"

    RETURN do_lookup(sql_query, "Creditor", field_name)

END FUNCTION

FUNCTION lookup_warehouse(search_val STRING, field_name STRING)
    RETURNS STRING

    DEFINE sql_query STRING
    LET sql_query = "SELECT wh_code, wh_name, location, manager, capacity "
                  || "FROM wh01_mast "
                  || build_where(search_val, "wh_code", "wh_name")
                  || " ORDER BY wh_code"

    RETURN do_lookup(sql_query, "Warehouse", field_name)

END FUNCTION

# ============================================================================
# STOCK LOOKUPS
# ============================================================================

FUNCTION lookup_stock(search_val STRING, field_name STRING)
    RETURNS STRING

    DEFINE sql_query STRING
    LET sql_query = "SELECT stock_code, description, unit, selling_price, category.name "
                  || "FROM st01_mast "
                  || build_where(search_val, "stock_code", "description")
                  || " ORDER BY stock_code"

    RETURN do_lookup(sql_query, "Stock", field_name)

END FUNCTION

FUNCTION lookup_stock_category(search_val STRING, field_name STRING)
    RETURNS STRING

    DEFINE sql_query STRING
    LET sql_query = "SELECT cat_code, cat_name, description, NULL, NULL "
                  || "FROM st_cat "
                  || build_where(search_val, "cat_code", "cat_name")
                  || " ORDER BY cat_code"

    RETURN do_lookup(sql_query, "Stock Category", field_name)

END FUNCTION

# ============================================================================
# DOCUMENT LOOKUPS
# ============================================================================

FUNCTION lookup_sales_order(search_val STRING, field_name STRING)
    RETURNS STRING

    DEFINE sql_query STRING
    LET sql_query = "SELECT doc_no, acc_code, order_date, total_amount, status "
                  || "FROM sa30_hdr "
                  || build_where(search_val, "doc_no", "acc_code")
                  || " ORDER BY doc_no DESC"

    RETURN do_lookup(sql_query, "Sales Order", field_name)

END FUNCTION

FUNCTION lookup_purchase_order(search_val STRING, field_name STRING)
    RETURNS STRING

    DEFINE sql_query STRING
    LET sql_query = "SELECT doc_no, acc_code, po_date, total_amount, status "
                  || "FROM pu30_hdr "
                  || build_where(search_val, "doc_no", "acc_code")
                  || " ORDER BY doc_no DESC"

    RETURN do_lookup(sql_query, "Purchase Order", field_name)

END FUNCTION

# ============================================================================
# SHARED UTILITIES
# ============================================================================

FUNCTION build_where(search_val STRING, field1 STRING, field2 STRING)
    RETURNS STRING
    DEFINE clause STRING

    IF search_val IS NOT NULL AND search_val.trim() <> "" THEN
        LET clause = " WHERE " || field1 || " ILIKE '%" || search_val || "%' "
                   || " OR " || field2 || " ILIKE '%" || search_val || "%'"
    ELSE
        LET clause = ""
    END IF

    RETURN clause
END FUNCTION

# Main lookup executor
FUNCTION do_lookup(sql_query STRING, title STRING, field_name STRING)
    RETURNS STRING

    DEFINE results DYNAMIC ARRAY OF t_lookup_result
    DEFINE selected_idx INTEGER
    DEFINE return_val STRING

    # Run query + dialog
    CALL execute_lookup_query(sql_query, title)
        RETURNING results, selected_idx

    IF selected_idx > 0 THEN
        CASE field_name.toUpperCase()
            WHEN "CODE" LET return_val = results[selected_idx].code
            WHEN "DESC" LET return_val = results[selected_idx].description
            WHEN "FIELD3" LET return_val = results[selected_idx].field3
            WHEN "FIELD4" LET return_val = results[selected_idx].field4
            WHEN "FIELD5" LET return_val = results[selected_idx].field5
            OTHERWISE LET return_val = results[selected_idx].code
        END CASE
    END IF

    RETURN return_val
END FUNCTION


# ============================================================================
# SHARED EXECUTION FUNCTIONS
# ============================================================================

# ----------------------------------------------------------------------------
# Execute lookup query and return results
# ----------------------------------------------------------------------------
FUNCTION execute_lookup_query(sql_query STRING, module_title STRING)
    RETURNS (DYNAMIC ARRAY OF t_lookup_result, INTEGER)

    DEFINE result_array DYNAMIC ARRAY OF t_lookup_result
    DEFINE row_count INTEGER
    DEFINE selected_idx INTEGER

    LET row_count = 0
    LET selected_idx = 0

    TRY
        DECLARE c1 CURSOR FROM sql_query

        FOREACH c1 INTO result_array[row_count+1].*
            LET row_count = row_count + 1
        END FOREACH

        CLOSE c1
        FREE c1

    CATCH
        CALL show_error("Database error: " || SQLCA.SQLERRM)
        RETURN result_array, 0
    END TRY

    IF row_count = 0 THEN
        CALL show_message("No records found")
        RETURN result_array, 0
    END IF

    CALL display_lookup_dialog(result_array, row_count, module_title)
        RETURNING selected_idx

    RETURN result_array, selected_idx

END FUNCTION


# ----------------------------------------------------------------------------
# Display lookup results in array dialog
# ----------------------------------------------------------------------------
FUNCTION display_lookup_dialog(result_array DYNAMIC ARRAY OF t_lookup_result,
                               row_count INTEGER,
                               dialog_title STRING)
    RETURNS INTEGER

    DEFINE selected_idx INTEGER

    LET selected_idx = 0

    OPEN WINDOW w_lookup WITH FORM "lookup_form"
        ATTRIBUTES(TEXT = dialog_title, STYLE = "dialog")

    DIALOG ATTRIBUTES(UNBUFFERED)

        DISPLAY ARRAY result_array TO sr_lookup.*

            ON ACTION accept
                LET selected_idx = arr_curr()
                EXIT DIALOG

            ON ACTION cancel
                LET selected_idx = 0
                EXIT DIALOG

            DISPLAY row_count

        END DISPLAY

    END DIALOG

    CLOSE WINDOW w_lookup

    RETURN selected_idx

END FUNCTION


# ----------------------------------------------------------------------------
# Simple error popup
# ----------------------------------------------------------------------------
FUNCTION show_error(msg STRING)
    MENU "Error" ATTRIBUTES(STYLE="dialog", COMMENT=msg)
        ON ACTION accept
            EXIT MENU
    END MENU
END FUNCTION


# ----------------------------------------------------------------------------
# Simple info popup
# ----------------------------------------------------------------------------
FUNCTION show_message(msg STRING)
    MENU "Info" ATTRIBUTES(STYLE="dialog", COMMENT=msg)
        ON ACTION accept
            EXIT MENU
    END MENU
END FUNCTION
