-- ==============================================================
-- Program : utils_lkup_form.4gl
-- Purpose : Global Dynamic Lookup Utility
-- Author  : Bongani Dlamini
-- Version : Genero BDL 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoappdb


-- ==============================================================
-- Type Definitions
-- ==============================================================

TYPE lookup_conf_t RECORD
    lookup_code       STRING,
    table_name        STRING,
    key_field         STRING,
    desc_field        STRING,
    extra_fields      STRING,
    display_title     STRING,
    filter_condition  STRING,
    col1_title        STRING,
    col2_title        STRING,
    col3_title        STRING,
    col4_title        STRING
END RECORD

TYPE lookup_item_t RECORD
    c1 STRING,
    c2 STRING,
    c3 STRING,
    c4 STRING
END RECORD


DEFINE tbl_lookup_list lookup_conf_t

-- ==============================================================
-- PUBLIC FUNCTION: display_lookup
-- ==============================================================

PUBLIC FUNCTION display_lookup(p_lookup_code STRING) RETURNS STRING

    DEFINE conf lookup_conf_t,
           arr_results DYNAMIC ARRAY OF lookup_item_t,
           f_search STRING,
           base_sql STRING,
           ret_val STRING,
           i SMALLINT

    LET ret_val = NULL
    LET f_search = ""


    -- Load configuration
    SELECT lookup_code, table_name, key_field, desc_field,
           extra_fields, display_title, filter_condition,
           col1_title, col2_title, col3_title, col4_title
      INTO conf.*
      FROM sy08_lkup_config
     WHERE lookup_code = p_lookup_code

    IF SQLCA.SQLCODE != 0 THEN
        CALL utils_globals.show_error("Lookup config missing: " || p_lookup_code)
        RETURN NULL
    END IF


    -- Build base SQL (4 columns)
    LET base_sql = SFMT(
        "SELECT %1 AS c1,
                %2 AS c2,
                COALESCE(%3,'') AS c3,
                '' AS c4
         FROM %4",
        conf.key_field,
        conf.desc_field,
        conf.extra_fields,
        conf.table_name
    )


    -- Add static filter
    IF conf.filter_condition IS NOT NULL AND conf.filter_condition <> "" THEN
        LET base_sql = base_sql || " WHERE " || conf.filter_condition
    END IF


    -- Order by description field
    LET base_sql = base_sql || SFMT(" ORDER BY %1", conf.desc_field)


    -- Open form
    OPEN WINDOW wlk WITH FORM "utils_lkup_form"
        ATTRIBUTES(TYPE=POPUP, STYLE="dialog")

    CALL utils_globals.set_form_label("lbl_lookup_title", conf.display_title)


    -- ==================================================
    -- Apply column titles (dynamic)
    -- ==================================================
    LET tbl_lookup_list.col1_title =  conf.col1_title
    LET tbl_lookup_list.col2_title =  conf.col2_title
    LET tbl_lookup_list.col3_title =  conf.col3_title
    LET tbl_lookup_list.col4_title =  conf.col4_title

    -- ==================================================
    -- Hide extra columns if required
    -- ==================================================
    IF conf.extra_fields IS NULL OR conf.extra_fields = "" THEN
        CALL ui.Interface.setText("tbl_lookup_list.col3")
        CALL ui.Interface.setText("tbl_lookup_list.col4")
    ELSE
        CALL ui.Interface.setText (tbl_lookup_list.col3_title)
        -- Only show col4 if caption exists
        IF conf.col4_title IS NULL OR conf.col4_title = "" THEN
            CALL ui.Interface.setText("tbl_lookup_list.col4")
        ELSE
            CALL ui.Interface.setText("tbl_lookup_list.col4")
        END IF
    END IF


    -- Load initial data
    CALL load_lookup_data(base_sql, arr_results, NULL)


    -- ==================================================
    -- Dialog for Search + List
    -- ==================================================
    DIALOG ATTRIBUTES(UNBUFFERED)

        INPUT BY NAME f_search ATTRIBUTES( WITHOUT DEFAULTS)
            AFTER FIELD f_search
                CALL load_lookup_data(base_sql, arr_results, f_search)
                DISPLAY ARRAY arr_results TO tbl_lookup_list.*
        END INPUT


        DISPLAY ARRAY arr_results TO tbl_lookup_list.*
            ATTRIBUTES(DOUBLECLICK=ACCEPT)

            ON ACTION accept
                LET i = arr_curr()
                IF i > 0 THEN
                    LET ret_val = arr_results[i].c1
                    EXIT DIALOG
                END IF

            ON ACTION cancel
                LET ret_val = NULL
                EXIT DIALOG

        END DISPLAY

    END DIALOG


    CLOSE WINDOW wlk
    RETURN ret_val

END FUNCTION


-- ==============================================================
-- FILTER + LOAD FUNCTION
-- ==============================================================

FUNCTION load_lookup_data(
    p_base_sql STRING,
    p_arr DYNAMIC ARRAY OF lookup_item_t,
    p_filter STRING)

    DEFINE final_sql STRING
    DEFINE rec lookup_item_t
    DEFINE pattern STRING

    CALL p_arr.clear()


    IF p_filter IS NULL OR p_filter = "" THEN
        LET final_sql = p_base_sql
    ELSE
        LET pattern = "%" || p_filter || "%"

        LET final_sql = SFMT(
            "SELECT * FROM (%1) AS t
             WHERE UPPER(t.c1) LIKE UPPER('%2')
                OR UPPER(t.c2) LIKE UPPER('%2')
                OR UPPER(t.c3) LIKE UPPER('%2')
                OR UPPER(t.c4) LIKE UPPER('%2')
             ORDER BY t.c2",
             p_base_sql,
             pattern
        )
    END IF


    PREPARE q FROM final_sql
    DECLARE c CURSOR FOR q

    FOREACH c INTO rec.c1, rec.c2, rec.c3, rec.c4
        LET p_arr[p_arr.getLength()+1].* = rec.*
    END FOREACH

END FUNCTION


-- ==============================================================
-- SHORTCUT FUNCTIONS
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

PUBLIC FUNCTION lookup_bin() RETURNS STRING
    RETURN display_lookup("bin")
END FUNCTION

PUBLIC FUNCTION lookup_sa_quote() RETURNS STRING
    RETURN display_lookup("sa_quote")
END FUNCTION

PUBLIC FUNCTION lookup_sa_order() RETURNS STRING
    RETURN display_lookup("sa_docs")
END FUNCTION

PUBLIC FUNCTION lookup_sa_invoice() RETURNS STRING
    RETURN display_lookup("sa_inv")
END FUNCTION

PUBLIC FUNCTION lookup_pu_order() RETURNS STRING
    RETURN display_lookup("pu_docs")
END FUNCTION

PUBLIC FUNCTION lookup_pu_grn() RETURNS STRING
    RETURN display_lookup("pu_grn")
END FUNCTION

PUBLIC FUNCTION lookup_pu_inv() RETURNS STRING
    RETURN display_lookup("pu_inv")
END FUNCTION
