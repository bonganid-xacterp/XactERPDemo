-- ==============================================================
-- Program : dl121_lkup.4gl
-- Purpose : Debtors Lookup (Popup Grid) with wildcard search (*)
-- Module  : Debtors
-- Version : Genero BDL 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
SCHEMA demoappdb

TYPE debtor_lookup_t RECORD
    acc_code LIKE dl01_mast.acc_code,
    cust_name LIKE dl01_mast.cust_name,
    status LIKE dl01_mast.status,
    status_desc STRING
END RECORD

-- ==============================================================
-- Public function: open lookup window and return selected acc_code
-- ==============================================================
FUNCTION fetch_debt_list() RETURNS STRING
    DEFINE selected_acc_code STRING
    DEFINE search_text STRING
    DEFINE debtor_list DYNAMIC ARRAY OF debtor_lookup_t
    DEFINE total_rows INTEGER

    LET selected_acc_code = NULL
    LET search_text = ""

    -- Initial load: show all
    CALL load_debtors_for_lookup(search_text) RETURNING debtor_list, total_rows
    IF total_rows = 0 THEN
        CALL utils_globals.show_info("No debtor records found.")
        RETURN NULL
    END IF

    OPEN WINDOW w_lookup WITH FORM "dl121_lkup" ATTRIBUTES(STYLE = "dialog")

    DIALOG ATTRIBUTES(UNBUFFERED)

        INPUT BY NAME search_text
            AFTER FIELD search_text
                CALL load_debtors_for_lookup(
                    search_text)
                    RETURNING debtor_list, total_rows
                CALL DIALOG.setArrayLength(
                    "r_debtors_list", debtor_list.getLength())
                CALL DIALOG.setCurrentRow(
                    "r_debtors_list", IIF(total_rows > 0, 1, 0))
                NEXT FIELD search_text
        END INPUT

        DISPLAY ARRAY debtor_list TO r_debtors_list.*

            BEFORE DISPLAY
                CALL DIALOG.setCurrentRow("r_debtors_list", 1)

            ON ACTION ACCEPT
                LET selected_acc_code = get_selected_debtor(debtor_list)

            ON ACTION doubleclic
                LET selected_acc_code = get_selected_debtor(debtor_list)

            ON KEY(RETURN)
                LET selected_acc_code = get_selected_debtor(debtor_list)

            ON ACTION cancel
                LET selected_acc_code = NULL

            ON KEY(ESCAPE)
                LET selected_acc_code = NULL
        END DISPLAY

    END DIALOG

    CLOSE WINDOW w_lookup
    RETURN selected_acc_code
END FUNCTION

-- ==============================================================
-- Helper: return selected debtor code
-- ==============================================================
FUNCTION get_selected_debtor(
    debtor_list DYNAMIC ARRAY OF debtor_lookup_t)
    RETURNS STRING

    DEFINE dlg ui.Dialog
    DEFINE current_row INTEGER
    LET current_row = dlg.getCurrentRow("r_debtors_list")
    IF current_row >= 1 AND current_row <= debtor_list.getLength() THEN
        RETURN debtor_list[current_row].acc_code
    END IF
    RETURN NULL
END FUNCTION

-- ==============================================================
-- Helper: Load debtors from DB based on search text
-- ==============================================================
FUNCTION load_debtors_for_lookup(
    search_text STRING)
    RETURNS(DYNAMIC ARRAY OF debtor_lookup_t, INTEGER)

    DEFINE debtor_list DYNAMIC ARRAY OF debtor_lookup_t
    DEFINE debtor_record debtor_lookup_t
    DEFINE row_count INTEGER
    DEFINE search_pattern STRING

    CALL debtor_list.clear()
    LET row_count = 0

    -- Handle wildcard: "*" means show all records
    IF search_text = "*" OR search_text IS NULL OR search_text = "" THEN
        LET search_pattern = "%"
    ELSE
        -- Wrap in %...% for contains search
        LET search_pattern = "%" || search_text || "%"
    END IF

    WHENEVER ERROR CONTINUE
    PREPARE stmt
        FROM "SELECT acc_code, cust_name, status, "
            || " CASE status WHEN 1 THEN 'Active' "
            || "             WHEN 0 THEN 'Inactive' "
            || "             WHEN -1 THEN 'Archived' "
            || "             ELSE 'Unknown' END AS status_desc "
            || "FROM dl01_mast "
            || "WHERE acc_code ILIKE ? OR cust_name ILIKE ? "
            || "ORDER BY acc_code"

    DECLARE csr CURSOR FOR stmt
    OPEN csr USING search_pattern, search_pattern

    IF sqlca.sqlcode = 0 THEN
        FETCH csr INTO debtor_record.*
        WHILE sqlca.sqlcode = 0
            LET row_count = row_count + 1
            LET debtor_list[row_count].* = debtor_record.*
            FETCH csr INTO debtor_record.*
        END WHILE
    END IF

    CLOSE csr
    FREE stmt
    WHENEVER ERROR STOP

    RETURN debtor_list, row_count
END FUNCTION
