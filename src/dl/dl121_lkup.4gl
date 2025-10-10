-- ==========================================
-- Program : dl121_lkup.4gl
-- Purpose : Debtors Lookup (Popup Grid)
-- Module  : Debtors
-- Number  : 121
-- Version : Genero ver 3.20.10
-- ==========================================
IMPORT FGL utils_globals
IMPORT ui   

SCHEMA xactdemo_db

-- display debtor form
FUNCTION fetch_debt_list() RETURNS STRING
    DEFINE selected_code STRING
    DEFINE idx INTEGER
    DEFINE dlg ui.Dialog
    DEFINE sel INTEGER
    DEFINE r INTEGER


    DEFINE  debt_arr DYNAMIC ARRAY OF RECORD
            acc_code LIKE dl01_mast.acc_code,
            cust_name LIKE dl01_mast.cust_name,
            status LIKE dl01_mast.status,
            lbl_status STRING
        END RECORD,

        debt_rec RECORD
            acc_code LIKE dl01_mast.acc_code,
            cust_name LIKE dl01_mast.cust_name,
            status LIKE dl01_mast.status,
            lbl_status STRING
        END RECORD

    LET idx = 0
    LET selected_code = NULL

    OPEN WINDOW w_debt WITH FORM "dl121_lkup" ATTRIBUTES(STYLE = "dialog")

    -- Load data of all active debtors
    DECLARE debtors_curs CURSOR FOR
        SELECT acc_code,
            cust_name,
            status,
            CASE status
                WHEN 1 THEN 'Active'
                WHEN 0 THEN 'Inactive'
                WHEN -1 THEN 'Archived'
                ELSE 'Unknown' 
            END
                AS lbl_status
            FROM dl01_mast
            ORDER BY acc_code

    CALL debt_arr.clear()

    FOREACH debtors_curs INTO debt_rec.*
        LET idx = idx + 1
        LET debt_arr[idx].* = debt_rec.*
    END FOREACH

    -- Show array only if records exist
    IF idx > 0 THEN
        DIALOG ATTRIBUTES(UNBUFFERED)
            DISPLAY ARRAY debt_arr TO r_debtors_list.* ATTRIBUTES(COUNT = idx)

                BEFORE DISPLAY
                    LET dlg = ui.Dialog.getCurrent()
                    IF debt_arr.getLength() > 0 THEN
                        CALL dlg.setCurrentRow("r_debtors_list", 1)
                    END IF

                ON ACTION accept
                    LET sel = dlg.getCurrentRow("r_debtors_list")
                    IF sel > 0 AND sel <= debt_arr.getLength() THEN
                        LET selected_code = debt_arr[sel].acc_code
                    END IF
                    EXIT DIALOG

                ON ACTION cancel
                    LET selected_code = NULL

                    EXIT DIALOG

                ON ACTION next
                    LET r = DIALOG.getCurrentRow("r_debtors_list")
                    IF r < debt_arr.getLength() THEN
                        CALL DIALOG.setCurrentRow("r_debtors_list", r + 1)
                    ELSE
                        -- wrap to first (optional)
                        CALL DIALOG.setCurrentRow("r_debtors_list", 1)
                    END IF

                ON ACTION previous
                    LET r = DIALOG.getCurrentRow("r_debtors_list")
                    IF r < debt_arr.getLength() THEN
                        CALL DIALOG.setCurrentRow("r_debtors_list", r + 1)
                    ELSE
                        -- wrap to first (optional)
                        CALL DIALOG.setCurrentRow("r_debtors_list", 1)
                    END IF

                ON KEY(RETURN)
                    LET sel = dlg.getCurrentRow("r_debtors_list")
                    IF sel > 0 AND sel <= debt_arr.getLength() THEN
                        LET selected_code = debt_arr[sel].acc_code
                    END IF
                    EXIT DIALOG
                ON KEY(ESCAPE)
                    LET selected_code = NULL
                     EXIT DIALOG
            END DISPLAY
        END DIALOG
    ELSE
        CALL utils_globals.show_info("No debtor records found.")
    END IF

    CLOSE WINDOW w_debt
    RETURN selected_code
END FUNCTION

-- ==============================================================
-- Alternative version with search capability using f_search field
-- ==============================================================
FUNCTION load_lookup_form_with_search() RETURNS STRING
    DEFINE selected_code STRING
    DEFINE debt_arr DYNAMIC ARRAY OF RECORD
        acc_code LIKE dl01_mast.acc_code,
        cust_name LIKE dl01_mast.cust_name,
        status LIKE dl01_mast.status,
        lbl_status STRING
    END RECORD
    DEFINE f_search STRING
    DEFINE sel SMALLINT
    DEFINE row_count INTEGER


    LET selected_code = NULL
    LET f_search = ""

    -- Load all records initially
    CALL load_debtors_for_lookup(f_search) RETURNING debt_arr, row_count

    IF row_count = 0 THEN
        CALL utils_globals.show_info("No debtor records found.")
        RETURN NULL
    END IF

    OPEN WINDOW w_lkup WITH FORM "dl121_lkup" ATTRIBUTES(STYLE = "dialog")

    DIALOG ATTRIBUTES(UNBUFFERED)

        INPUT BY NAME f_search
            AFTER FIELD f_search
                CALL load_debtors_for_lookup(f_search)
                    RETURNING debt_arr, row_count
                CALL DIALOG.setArrayLength("r_debtors_list", debt_arr.getLength())
                -- keep table on row 1 but return focus to filter
                CALL DIALOG.setCurrentRow("r_debtors_list", IIF(row_count>0,1,0))
                NEXT FIELD f_search
        END INPUT

        DISPLAY ARRAY debt_arr TO r_debtors_list.*

            BEFORE DISPLAY
                CALL DIALOG.setCurrentRow("r_debtors_list", 1)

            ON ACTION accept
                LET sel = DIALOG.getCurrentRow("r_debtors_list")
                IF sel > 0 AND sel <= debt_arr.getLength() THEN
                    LET selected_code = debt_arr[sel].acc_code
                    EXIT DIALOG
                END IF

            ON ACTION cancel
                LET selected_code = NULL
                EXIT DIALOG

            ON ACTION doubleclick
                LET sel = DIALOG.getCurrentRow("r_debtors_list")
                IF sel > 0 AND sel <= debt_arr.getLength() THEN
                    LET selected_code = debt_arr[sel].acc_code
                    EXIT DIALOG
                END IF

            ON KEY(RETURN)
                LET sel = DIALOG.getCurrentRow("r_debtors_list")
                IF sel > 0 AND sel <= debt_arr.getLength() THEN
                    LET selected_code = debt_arr[sel].acc_code
                    EXIT DIALOG
                END IF

        END DISPLAY

    END DIALOG

    CLOSE WINDOW w_lkup

    RETURN selected_code

END FUNCTION

-- Helper function to load debtors with optional search filter
FUNCTION load_debtors_for_lookup(search_filter STRING)
    RETURNS(
        DYNAMIC ARRAY OF RECORD
            acc_code LIKE dl01_mast.acc_code,
            cust_name LIKE dl01_mast.cust_name,
            status LIKE dl01_mast.status,
            lbl_status STRING
        END RECORD,
        INTEGER)

    DEFINE rec RECORD
        acc_code LIKE dl01_mast.acc_code,
        cust_name LIKE dl01_mast.cust_name,
        status LIKE dl01_mast.status,
        lbl_status STRING
    END RECORD

    DEFINE debt_arr DYNAMIC ARRAY OF RECORD
        acc_code LIKE dl01_mast.acc_code,
        cust_name LIKE dl01_mast.cust_name,
        status LIKE dl01_mast.status,
        lbl_status STRING
    END RECORD
    DEFINE sql_stmt STRING
    DEFINE row_count INTEGER
    DEFINE search_pat STRING

    CALL debt_arr.clear()
    LET row_count = 0

    LET search_pat = "%" || NVL(search_filter, "") || "%"

    -- Build SQL with search filter
    LET sql_stmt = "SELECT acc_code, cust_name, status FROM dl01_mast"

    IF search_filter IS NOT NULL AND search_filter.getLength() > 0 THEN
        LET sql_stmt =
            sql_stmt
                || " WHERE acc_code LIKE '%"
                || search_filter
                || "%'"
                || " OR cust_name LIKE '%"
                || search_filter
                || "%'"
    END IF

    LET sql_stmt = sql_stmt || " ORDER BY acc_code"


    WHENEVER ERROR CONTINUE
    PREPARE debt_prep FROM
      "SELECT acc_code, cust_name, status, " ||
      " CASE status " ||
      "  WHEN 1 THEN 'Active' "   ||
      "  WHEN 0 THEN 'Inactive' " ||
      "  WHEN -1 THEN 'Archived' "||
      "  ELSE 'Unknown' END AS lbl_status " ||
      "FROM dl01_mast " ||
      "WHERE acc_code ILIKE ? OR cust_name ILIKE ? " ||
      "ORDER BY acc_code";
    DECLARE debt_csr2 CURSOR FOR debt_prep

      OPEN debt_csr2 USING search_pat, search_pat

    IF SQLCA.SQLCODE = 0 THEN
        FETCH debt_csr2 INTO rec.*
        WHILE SQLCA.SQLCODE = 0
            LET row_count = row_count + 1
            LET debt_arr[row_count].* = rec.*
            FETCH debt_csr2 INTO rec.*
        END WHILE
    END IF

    CLOSE debt_csr2
    FREE debt_prep
    WHENEVER ERROR STOP

    RETURN debt_arr, row_count

END FUNCTION