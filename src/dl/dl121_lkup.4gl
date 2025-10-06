-- ==========================================
-- Program : dl121_lkup.4gl
-- Purpose : Debtors Lookup (Popup Grid)
-- Module  : Debtors
-- Number  : 121
-- Version : Genero BDL 3.20.10
-- ==========================================

SCHEMA xactdemo_db

FUNCTION display_debtors_list() RETURNS STRING
    DEFINE
        debt_arr DYNAMIC ARRAY OF RECORD
            acc_code LIKE dl01_mast.acc_code,
            cust_name LIKE dl01_mast.cust_name,
            phone LIKE dl01_mast.phone,
            balance LIKE dl01_mast.balance
        END RECORD,
        debt_rec RECORD
            acc_code LIKE dl01_mast.acc_code,
            cust_name LIKE dl01_mast.cust_name,
            phone LIKE dl01_mast.phone,
            balance LIKE dl01_mast.balance
        END RECORD,
        ret_code STRING,
        idx, curr_pa SMALLINT

    OPEN WINDOW w_dl121_lkup
        WITH
        FORM "dl121_lkup"
        ATTRIBUTES(TYPE = POPUP, STYLE = "lookup")

    CALL debt_arr.clear()
    LET idx = 0

    DECLARE debt_curs CURSOR FOR
        SELECT acc_code, cust_name, phone, balance
            FROM dl01_mast
            WHERE status = 1
            ORDER BY acc_code

    FOREACH debt_curs INTO debt_rec.*
        LET idx = idx + 1
        LET debt_arr[idx].* = debt_rec.*
    END FOREACH

    IF idx = 0 THEN
        MESSAGE "No active debtors found."
        CLOSE WINDOW w_dl121_lkup
        RETURN NULL
    END IF

    LET ret_code = NULL

    DIALOG
        DISPLAY ARRAY debt_arr TO sa_debt.* ATTRIBUTES(COUNT = idx)

            ON ACTION doubleclick
                LET curr_pa = arr_curr()
                LET ret_code = debt_arr[curr_pa].acc_code
                EXIT DIALOG

            ON ACTION accept
                LET curr_pa = arr_curr()
                LET ret_code = debt_arr[curr_pa].acc_code
                EXIT DIALOG

            ON ACTION cancel
                LET ret_code = NULL
                EXIT DIALOG
        END DISPLAY
    END DIALOG

    CLOSE WINDOW w_dl121_lkup
    RETURN ret_code
END FUNCTION
