-- ==============================================================
-- Program : utils_global_lkup.4gl
-- Purpose : Simple Global Lookup with Search Filter
-- Author  : Bongani Dlamini
-- Version : Genero BDL 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoappdb

-- ==============================================================
-- Types
-- ==============================================================

TYPE lookup_conf_t RECORD
    lookup_code STRING,
    table_name STRING,
    key_field STRING,
    desc_field STRING,
    extra_field STRING,
    display_title STRING,
    col1_title STRING,
    col2_title STRING,
    col3_title STRING
END RECORD

TYPE lookup_item_t RECORD
    lbl_c1 STRING,
    lbl_c2 STRING,
    lbl_c3 STRING
END RECORD

DEFINE arr_results DYNAMIC ARRAY OF lookup_item_t
DEFINE f_search STRING

-- ==============================================================
-- PUBLIC LOOKUP FUNCTION
-- ==============================================================

PUBLIC FUNCTION display_lookup(p_lookup_code STRING) RETURNS STRING

    DEFINE
        conf lookup_conf_t,
        base_sql STRING,
        ret_val STRING,
        idx SMALLINT

    LET ret_val = NULL
    LET f_search = ""

    TRY
        -- Load configuration ---------------------------------------
        SELECT lookup_code,
            table_name,
            key_field,
            desc_field,
            extra_field,
            display_title,
            col1_title,
            col2_title,
            col3_title
            INTO conf.*
            FROM sy08_lkup_config
            WHERE lookup_code = p_lookup_code

        IF SQLCA.SQLCODE != 0 THEN
            CALL utils_globals.show_error(
                "Lookup config missing: " || p_lookup_code)
            RETURN NULL
        END IF

        -- Build base SQL -------------------------------------------
        LET base_sql =
            SFMT("SELECT CAST(%1 AS VARCHAR) AS c1,
                    %2 AS c2,
                    COALESCE(CAST(%3 AS VARCHAR),'') AS c3
             FROM %4",
                conf.key_field,
                conf.desc_field,
                NVL(conf.extra_field, "''"),
                conf.table_name)

    CATCH
        CALL utils_globals.show_sql_error(
            SFMT("display_lookup: Error loading config for '%1'",
                p_lookup_code))
        RETURN NULL
    END TRY

    TRY
        -- Open lookup form -----------------------------------------
        OPEN WINDOW wlk
            WITH
            FORM "utils_global_lkup"
            ATTRIBUTES(TYPE = POPUP, STYLE = "dialog")

        CALL utils_globals.set_form_label(
            "lbl_title", NVL(conf.display_title, "Lookup") || " Lookup")

        CALL utils_globals.set_page_title(
            NVL(conf.display_title, "Lookup") || " Lookup")

        -- Initial load (no search) ---------------------------------
        CALL load_lookup_data(base_sql, arr_results, f_search)

    CATCH
        CALL utils_globals.show_error(
            SFMT("display_lookup: Error opening lookup form for '%1'",
                p_lookup_code))
        RETURN NULL
    END TRY

    -- ==========================================================
    -- MAIN DIALOG
    -- ==========================================================
    DIALOG ATTRIBUTES(UNBUFFERED)

        -- Search box at bottom of the form ----------------------
        INPUT BY NAME f_search
            BEFORE INPUT

                CALL utils_globals.set_form_label(
                    "formonly.col1", conf.col1_title)
                CALL utils_globals.set_form_label(
                    "formonly.col2", conf.col2_title)
                CALL utils_globals.set_form_label(
                    "formonly.col3", conf.col3_title)

            ON CHANGE f_search
                TRY
                    CALL load_lookup_data(base_sql, arr_results, f_search)
                CATCH
                    CALL utils_globals.show_sql_error(
                        "Error filtering lookup data")
                    LET f_search = ""
                END TRY

            ON ACTION FETCH ATTRIBUTES(TEXT = "Reset Search", IMAGE = "refresh")
                TRY
                    LET f_search = ""
                    CALL load_lookup_data(base_sql, arr_results, f_search)
                    MESSAGE "Search cleared - showing all records"
                CATCH
                    CALL utils_globals.show_sql_error("Error resetting search")
                END TRY

            ON ACTION ACCEPT
            ON KEY(RETURN)
                TRY
                    LET idx = arr_curr()
                    IF idx > 0 THEN
                        LET ret_val = arr_results[idx].lbl_c1
                        EXIT DIALOG
                    END IF
                CATCH
                    CALL utils_globals.show_error(
                        "Error retrieving selected value")
                    LET ret_val = NULL
                END TRY

            ON ACTION cancel
                LET ret_val = NULL
                EXIT DIALOG

        END INPUT

        -- Results table -----------------------------------------
        DISPLAY ARRAY arr_results
            TO tbl_lookup_list.*
            ATTRIBUTES(DOUBLECLICK = ACCEPT)

            ON ACTION ACCEPT
                TRY
                    LET idx = arr_curr()
                    IF idx > 0 THEN
                        LET ret_val = arr_results[idx].lbl_c1
                        EXIT DIALOG
                    END IF
                CATCH
                    CALL utils_globals.show_error(
                        "Error retrieving selected value")
                    LET ret_val = NULL
                END TRY

            ON ACTION FETCH ATTRIBUTES(TEXT = "Reset Search", IMAGE = "refresh")
                TRY
                    LET f_search = ""
                    CALL load_lookup_data(base_sql, arr_results, f_search)
                    MESSAGE "Search cleared - showing all records"
                CATCH
                    CALL utils_globals.show_sql_error("Error resetting search")
                END TRY

            ON ACTION cancel
                LET ret_val = NULL
                EXIT DIALOG

        END DISPLAY

    END DIALOG

    CLOSE WINDOW wlk
    RETURN ret_val

END FUNCTION

-- ==============================================================
-- LOAD DATA INTO ARRAY WITH FILTER
-- ==============================================================

FUNCTION load_lookup_data(
    p_base_sql STRING, p_arr DYNAMIC ARRAY OF lookup_item_t, p_search STRING)

    DEFINE rec lookup_item_t
    DEFINE final_sql STRING
    DEFINE pattern STRING
    DEFINE record_count INTEGER

    CALL p_arr.clear()

    TRY
        -- Build LIKE pattern ---------------------------------------
        IF p_search IS NULL OR p_search = "" THEN
            LET final_sql = p_base_sql || " ORDER BY 2"
        ELSE
            LET pattern = "%" || p_search || "%"

            LET final_sql =
                SFMT("SELECT * FROM ( %1 ) AS t
                 WHERE t.c1 LIKE '%2'
                    OR UPPER(t.c2) LIKE UPPER('%2')
                    OR t.c3 LIKE '%2'
                 ORDER BY t.c2", p_base_sql, pattern)
        END IF

        PREPARE stmt FROM final_sql
        DECLARE cur CURSOR FOR stmt

        FOREACH cur INTO rec.lbl_c1, rec.lbl_c2, rec.lbl_c3
            LET p_arr[p_arr.getLength() + 1].* = rec.*
        END FOREACH

        -- Clean up cursor
        CLOSE cur
        FREE cur
        FREE stmt

        -- Provide feedback on results ------------------------------
        LET record_count = p_arr.getLength()

        IF record_count = 0 THEN
            IF p_search IS NOT NULL AND p_search <> "" THEN
                MESSAGE SFMT("No records found matching '%1'", p_search)
            ELSE
                MESSAGE "No records available"
            END IF
        ELSE
            IF p_search IS NOT NULL AND p_search <> "" THEN
                MESSAGE SFMT("Found %1 record(s) matching '%2'",
                    record_count, p_search)
            ELSE
                MESSAGE SFMT("Displaying %1 record(s)", record_count)
            END IF
        END IF

    CATCH
        CALL utils_globals.show_sql_error(
            "load_lookup_data: Error loading data")
        -- Ensure array is empty on error
        CALL p_arr.clear()
        MESSAGE "Error loading lookup data"
    END TRY

END FUNCTION

-- ==============================================================
-- SHORTCUTS
-- ==============================================================

PUBLIC FUNCTION lookup_customer() RETURNS STRING
    RETURN display_lookup("customer")
END FUNCTION

PUBLIC FUNCTION lookup_creditor() RETURNS STRING
    RETURN display_lookup("creditor")
END FUNCTION

PUBLIC FUNCTION lookup_stock() RETURNS STRING
    RETURN display_lookup("stock")
END FUNCTION

PUBLIC FUNCTION lookup_uom() RETURNS STRING
    RETURN display_lookup("uom")
END FUNCTION

PUBLIC FUNCTION lookup_pu_ord() RETURNS STRING
    RETURN display_lookup("pu_ord")
END FUNCTION

PUBLIC FUNCTION lookup_pu_inv() RETURNS STRING
    RETURN display_lookup("pu_inv")
END FUNCTION

PUBLIC FUNCTION lookup_stock_category() RETURNS STRING
    RETURN display_lookup("stock_category")
END FUNCTION

PUBLIC FUNCTION lookup_warehouse() RETURNS STRING
    RETURN display_lookup("warehouse")
END FUNCTION

PUBLIC FUNCTION lookup_bin() RETURNS STRING
    RETURN display_lookup("bin")
END FUNCTION

PUBLIC FUNCTION lookup_users() RETURNS STRING
    RETURN display_lookup("users")
END FUNCTION
