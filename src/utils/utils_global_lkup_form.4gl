-- ==============================================================
-- Program : utils_global_lkup_form.4gl
-- Purpose : Global Dynamic Lookup Utility
-- Author  : Bongani Dlamini
-- Version : Genero BDL 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals


-- ==============================================================
-- Type Definitions
-- ==============================================================
TYPE lookup_conf_t RECORD
    lookup_code       STRING,
    table_name        STRING,
    key_field         STRING,
    desc_field        STRING,
    extra_field      STRING,
    display_title     STRING,
    filter_condition  STRING,
    col1_title        STRING,
    col2_title        STRING,
    col3_title        STRING
END RECORD

TYPE lookup_item_t RECORD
    c1 STRING,
    c2 STRING,
    c3 STRING
END RECORD

DEFINE m_arr_results DYNAMIC ARRAY OF lookup_item_t
DEFINE f_search STRING

-- ==============================================================
-- PUBLIC FUNCTION: display_lookup
-- ==============================================================
PUBLIC FUNCTION display_lookup(p_lookup_code STRING) RETURNS STRING

    DEFINE conf lookup_conf_t,
           base_sql STRING,
           ret_val STRING,
           i SMALLINT,
           frm ui.Form

    LET ret_val  = NULL
    LET f_search = ""

    -- Load configuration
    TRY
    SELECT lookup_code, table_name, key_field, desc_field,
           extra_field, display_title, filter_condition,
           col1_title, col2_title, col3_title
      INTO conf.*
      FROM sy08_lkup_config
     WHERE lookup_code = p_lookup_code

    IF SQLCA.SQLCODE != 0 THEN
        CALL utils_globals.show_error("Lookup config missing: " || p_lookup_code)
        RETURN NULL
    END IF

    -- Build SQL
    LET base_sql = SFMT(
        "SELECT CAST(%1 AS VARCHAR) AS c1,
                %2 AS c2,
                COALESCE(CAST(%3 AS VARCHAR),'') AS c3
         FROM %4",
        conf.key_field,
        conf.desc_field,
        conf.extra_field,
        conf.table_name
    )

    IF conf.filter_condition IS NOT NULL
       AND conf.filter_condition <> "" THEN
        LET base_sql = base_sql || " WHERE " || conf.filter_condition
    END IF

    LET base_sql = base_sql || SFMT(" ORDER BY %1", conf.desc_field)
    CATCH
        CALL utils_globals.show_error('Error retrieving data for  ' || conf.lookup_code || conf.table_name)
    END TRY
    -- Open lookup form
    OPEN WINDOW wlk WITH FORM "utils_global_lkup_form"
         ATTRIBUTES(TYPE=POPUP, STYLE="dialog")

         -- Set lookup titles
    CALL utils_globals.set_form_label("lbl_title", conf.display_title  || " LOOK UP")
    CALL utils_globals.set_page_title(conf.display_title)

    -- Set table column titles dynamically
    LET frm = ui.Window.getCurrent().getForm()

    -- Load initial data
    CALL load_lookup_data(base_sql, m_arr_results)

    -- Dialog
    DIALOG ATTRIBUTES(UNBUFFERED)

        INPUT BY NAME f_search
        
            ON CHANGE f_search
                CALL load_lookup_data(base_sql, m_arr_results)
            
        END INPUT

        DISPLAY ARRAY m_arr_results TO tbl_lookup_list.*
            ATTRIBUTES(DOUBLECLICK=ACCEPT)

            ON KEY (RETURN)
            ON ACTION accept
                LET i = arr_curr()
                IF i > 0 THEN
                    LET ret_val = m_arr_results[i].c1
                    EXIT DIALOG
                END IF

            ON ACTION exit
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
    p_arr DYNAMIC ARRAY OF lookup_item_t)

    DEFINE final_sql STRING
    DEFINE rec lookup_item_t
    DEFINE pattern STRING

    CALL p_arr.clear()

    LET pattern = "%" || f_search || "%"

    -- If no search term, just use the base SQL
    IF f_search IS NULL OR f_search.getLength() = 0 THEN
        LET final_sql = p_base_sql
    ELSE
        -- Build filtered query
        LET final_sql = SFMT(
            "SELECT * FROM (%1) AS t
             WHERE CAST(t.c1 AS VARCHAR) LIKE '%2'
                OR UPPER(t.c2) LIKE UPPER('%2')
                OR CAST(t.c3 AS VARCHAR) LIKE '%2'
             ORDER BY t.c2",
             p_base_sql, pattern)
    END IF

    PREPARE sql_stmt FROM final_sql
    DECLARE record_curs CURSOR FOR sql_stmt

    FOREACH record_curs INTO rec.c1, rec.c2, rec.c3
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
    RETURN display_lookup("sa_ord")
END FUNCTION

PUBLIC FUNCTION lookup_sa_invoice() RETURNS STRING
    RETURN display_lookup("sa_inv")
END FUNCTION

PUBLIC FUNCTION lookup_sa_credit_note() RETURNS STRING
    RETURN display_lookup("sa_crn")
END FUNCTION

PUBLIC FUNCTION lookup_pu_order() RETURNS STRING
    RETURN display_lookup("pu_ord")
END FUNCTION

PUBLIC FUNCTION lookup_pu_grn() RETURNS STRING
    RETURN display_lookup("pu_grn")
END FUNCTION

PUBLIC FUNCTION lookup_pu_inv() RETURNS STRING
    RETURN display_lookup("pu_inv")
END FUNCTION
