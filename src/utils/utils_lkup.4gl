-- ==============================================================
-- Program : utils_lookup.4gl
-- Purpose : Global Dynamic Lookup Utility
-- Author  : Bongani Dlamini
-- Version : 3.20.10
-- ==============================================================

IMPORT ui
IMPORT om
IMPORT FGL utils_globals
IMPORT FGL utils_db

SCHEMA demoappdb

-- ==============================================================
-- Type Definitions
-- ==============================================================
TYPE lookup_conf_t RECORD
    lookup_code       STRING,        -- unique code e.g. 'debtors', 'stock'
    table_name        STRING,        -- physical table name
    key_field         STRING,        -- PK or unique field
    desc_field        STRING,        -- display/description field
    extra_fields      STRING,        -- optional comma-separated fields
    display_title     STRING,        -- lookup window title
    filter_condition  STRING         -- WHERE clause, optional
END RECORD

TYPE lookup_item_t RECORD
    key_val   STRING,
    desc_val  STRING,
    extra_val STRING
END RECORD

-- ==============================================================
-- PUBLIC FUNCTION: display_lookup
-- Purpose : Dynamically open lookup for any configured entity
-- Usage   : id = utils_lookup.display_lookup("debtors")
-- ==============================================================
PUBLIC FUNCTION display_lookup(p_lookup_code STRING) RETURNS STRING

    DEFINE conf lookup_conf_t,
           arr_results DYNAMIC ARRAY OF lookup_item_t,
           f_search STRING,
           sql_stmt STRING,
           i INTEGER,
           selected_idx INTEGER,
           ret_val STRING

    INITIALIZE conf.* TO NULL
    LET ret_val = NULL

    -- Load configuration from sy10_lookup_config
    SELECT lookup_code, table_name, key_field, desc_field,
           extra_fields, display_title, filter_condition
      INTO conf.*
      FROM sy10_lookup_config
     WHERE lookup_code = p_lookup_code

    IF SQLCA.SQLCODE != 0 THEN
        CALL utils_globals.show_error("Lookup config not found: " || p_lookup_code)
        RETURN NULL
    END IF

    -- Build SQL query dynamically
    LET sql_stmt =
        SFMT("SELECT %1, %2 FROM %3", conf.key_field, conf.desc_field, conf.table_name)

    IF conf.filter_condition IS NOT NULL AND conf.filter_condition <> "" THEN
        LET sql_stmt = sql_stmt || " WHERE " || conf.filter_condition
    END IF

    LET sql_stmt = sql_stmt || SFMT(" ORDER BY %1", conf.desc_field)

    -- Open lookup window
    OPEN WINDOW w_lkup WITH FORM "utils_lkup_form"
        ATTRIBUTES (TYPE = POPUP, STYLE = "lookup")

    CALL utils_globals.set_form_label("lbl_lookup_title", conf.display_title)

    LET f_search = ""

    DIALOG ATTRIBUTES (UNBUFFERED)

        DISPLAY ARRAY arr_results TO tbl_lookup_list.*
            ATTRIBUTES (DOUBLECLICK = ACCEPT)

            BEFORE DISPLAY
                CALL load_lookup_data(sql_stmt, arr_results, f_search)

            ON ACTION accept
                LET selected_idx = arr_curr()
                IF selected_idx > 0 THEN
                    LET ret_val = arr_results[selected_idx].key_val
                    EXIT DIALOG
                END IF

            ON ACTION cancel ATTRIBUTES(TEXT="Close", IMAGE="exit")
                LET ret_val = NULL
                EXIT DIALOG

        END DISPLAY

        INPUT BY NAME f_search ATTRIBUTES(WITHOUT DEFAULTS)
            AFTER FIELD f_search
                CALL load_lookup_data(sql_stmt, arr_results, f_search)
                NEXT FIELD f_search

            ON ACTION accept ATTRIBUTES(TEXT="Search")
                CALL load_lookup_data(sql_stmt, arr_results, f_search)
        END INPUT

    END DIALOG

    CLOSE WINDOW w_lkup
    RETURN ret_val
END FUNCTION

-- ==============================================================
-- PRIVATE FUNCTION: load_lookup_data
-- Purpose : Execute dynamic SQL and populate result array
-- ==============================================================
FUNCTION load_lookup_data(
    p_sql STRING,
    p_arr DYNAMIC ARRAY OF lookup_item_t,
    p_filter STRING)

    DEFINE sql_filtered STRING,
           like_pattern STRING,
           rec lookup_item_t,
           i INTEGER

    CALL p_arr.clear()
    LET i = 0

    LET sql_filtered = p_sql

    -- Optional filter clause
    IF p_filter IS NOT NULL AND p_filter <> "" THEN
        LET like_pattern = "%" || p_filter || "%"
        -- Add WHERE or AND intelligently
        IF sql_filtered MATCHES "*WHERE*" THEN
            LET sql_filtered = sql_filtered || SFMT(
                " AND (CAST(%1 AS TEXT) ILIKE '%2' OR CAST(%3 AS TEXT) ILIKE '%2')",
                "1", like_pattern, "2")
        ELSE
            -- Fallback: just append for readability; real version can be improved
            LET sql_filtered = sql_filtered || SFMT(
                " WHERE (CAST(%1 AS TEXT) ILIKE '%2' OR CAST(%3 AS TEXT) ILIKE '%2')",
                "1", like_pattern, "2")
        END IF
    END IF

    -- Prepare + Declare pattern (required by Genero)
    PREPARE stmt FROM sql_filtered
    DECLARE c_lkup CURSOR FOR stmt

    FOREACH c_lkup INTO rec.key_val, rec.desc_val
        LET i = i + 1
        LET p_arr[i].* = rec.*
    END FOREACH

    CLOSE c_lkup
    FREE c_lkup
    FREE stmt
END FUNCTION


-- ==============================================================
-- PUBLIC WRAPPER FUNCTIONS (optional)
-- Simplify calls from modules
-- ==============================================================
PUBLIC FUNCTION lookup_debtor() RETURNS STRING
    RETURN display_lookup("debtors")
END FUNCTION

PUBLIC FUNCTION lookup_creditor() RETURNS STRING
    RETURN display_lookup("creditors")
END FUNCTION

PUBLIC FUNCTION lookup_stock() RETURNS STRING
    RETURN display_lookup("stock")
END FUNCTION

PUBLIC FUNCTION lookup_warehouse() RETURNS STRING
    RETURN display_lookup("warehouse")
END FUNCTION

PUBLIC FUNCTION lookup_whbin() RETURNS STRING
    RETURN display_lookup("bin")
END FUNCTION

PUBLIC FUNCTION lookup_category() RETURNS STRING
    RETURN display_lookup("category")
END FUNCTION
