-- ==========================================
-- Program : dl121_lkup.4gl
-- Purpose : Debtors Lookup (Popup Grid)
-- Module  : Debtors
-- Number  : 121
-- Version : Genero BDL 3.20.10
-- ==========================================
IMPORT FGL utils_globals


SCHEMA xactdemo_db


-- display debtor form
FUNCTION display_debt_list() RETURNS STRING
    DEFINE selected_code STRING
    DEFINE idx INTEGER
    DEFINE dlg ui.Dialog
    DEFINE sel INTEGER


    DEFINE debt_arr DYNAMIC ARRAY OF RECORD
        acc_code LIKE dl01_mast.acc_code,
        cust_name LIKE dl01_mast.cust_name,
        phone LIKE dl01_mast.phone,
        balance LIKE dl01_mast.balance,
         credit LIKE dl01_mast.cr_limit,
         status LIKE dl01_mast.status
    END RECORD,

    debt_rec RECORD
        acc_code LIKE dl01_mast.acc_code,
        cust_name LIKE dl01_mast.cust_name,
        phone LIKE dl01_mast.phone,
        balance LIKE dl01_mast.balance,
        credit LIKE dl01_mast.cr_limit,
        status LIKE dl01_mast.status
    END RECORD

    LET idx = 0
    LET selected_code = NULL

    OPEN WINDOW wdebtr WITH FORM "dl121_lkup" ATTRIBUTES(STYLE="dialog")

    -- Load data from the correct table
    DECLARE debtors_curs CURSOR FOR
        SELECT acc_code, cust_name, phone, balance, cr_limit,status
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
            DISPLAY ARRAY debt_arr TO r_debtors_list.* ATTRIBUTES(COUNT=idx)

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

                ON ACTION cancel
                    LET selected_code = NULL

                ON ACTION doubleclick
                   
                    LET sel = dlg.getCurrentRow("r_debtors_list")
                    IF sel > 0 AND sel <= debt_arr.getLength() THEN
                        LET selected_code = debt_arr[sel].acc_code
                    END IF

                ON KEY (RETURN)
                    LET sel = dlg.getCurrentRow("r_debtors_list")
                    IF sel > 0 AND sel <= debt_arr.getLength() THEN
                        LET selected_code = debt_arr[sel].acc_code
                    END IF

                ON KEY (ESCAPE)
                    LET selected_code = NULL

            END DISPLAY
        END DIALOG
    ELSE
        CALL utils_globals.show_info("No debtor records found.")
    END IF

    CLOSE WINDOW wdebtr
    RETURN selected_code
END FUNCTION
