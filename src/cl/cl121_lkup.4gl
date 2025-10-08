-- ==========================================
-- Program : cl121_lkup.4gl
-- Purpose : Creditors Lookup (Popup Grid)
-- Module  : Creditors
-- Number  : 121
-- Version : Genero ver 3.20.10
-- ==========================================

IMPORT FGL utils_globals

SCHEMA xactdemo_db

-- display creditor form
FUNCTION display_cred_list() RETURNS STRING
    DEFINE selected_code STRING
    DEFINE idx INTEGER
    DEFINE dlg ui.Dialog
    DEFINE sel INTEGER

    DEFINE
        cred_arr DYNAMIC ARRAY OF RECORD
            acc_code LIKE cl01_mast.acc_code,
            supp_name LIKE cl01_mast.supp_name,
            status LIKE cl01_mast.status
        END RECORD,

        cred_rec RECORD
            acc_code LIKE cl01_mast.acc_code,
            supp_name LIKE cl01_mast.supp_name,
            status LIKE cl01_mast.status
        END RECORD

    LET idx = 0
    LET selected_code = NULL

    OPEN WINDOW w_cred WITH FORM "cl121_lkup" ATTRIBUTES(STYLE = "dialog")

    -- Load data of all active credors
    DECLARE creditors_curs CURSOR FOR
        SELECT acc_code, supp_name, status FROM cl01_mast ORDER BY acc_code

    CALL cred_arr.clear()

    FOREACH creditors_curs INTO cred_rec.*
        LET idx = idx + 1
        LET cred_arr[idx].* = cred_rec.*
    END FOREACH

    CLOSE creditors_curs

    -- Show array only if records exist
    IF idx > 0 THEN
        DIALOG ATTRIBUTES(UNBUFFERED)
            DISPLAY ARRAY cred_arr TO r_creditors_list.* ATTRIBUTES(COUNT = idx)

                BEFORE DISPLAY
                    LET dlg = ui.Dialog.getCurrent()
                    IF cred_arr.getLength() > 0 THEN
                        CALL dlg.setCurrentRow("r_creditors_list", 1)
                    END IF

                ON ACTION accept
                    LET sel = dlg.getCurrentRow("r_creditors_list")
                    IF sel > 0 AND sel <= cred_arr.getLength() THEN
                        LET selected_code = cred_arr[sel].acc_code
                    END IF
                    EXIT DIALOG

                ON ACTION cancel
                    LET selected_code = NULL

                ON KEY(RETURN)
                    LET sel = dlg.getCurrentRow("r_creditors_list")
                    IF sel > 0 AND sel <= cred_arr.getLength() THEN
                        LET selected_code = cred_arr[sel].acc_code
                    END IF
                    EXIT DIALOG

                ON KEY(ESCAPE)
                    LET selected_code = NULL
                    EXIT DIALOG
            END DISPLAY
        END DIALOG
    ELSE
        CALL utils_globals.show_info("No creditor records found.")
    END IF

    CLOSE WINDOW w_cred
    RETURN selected_code
END FUNCTION
