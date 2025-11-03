-- ==============================================================
-- Program   : wh121_lkup.4gl
-- Function  : fetch_wh_list
-- Purpose   : Popup lookup with live search for warehouses
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoapp_db

FUNCTION fetch_wh_list(f_search STRING) RETURNS STRING
    DEFINE selected_code STRING
    DEFINE wh_arr DYNAMIC ARRAY OF RECORD
        wh_code LIKE wh01_mast.wh_code,
        wh_name LIKE wh01_mast.wh_name,
        location LIKE wh01_mast.location,
        status LIKE wh01_mast.status
    END RECORD
    DEFINE row_count INTEGER
    DEFINE sel SMALLINT

    LET selected_code = NULL
    LET row_count = 0

    -- ==========================================================
    -- Open popup window
    -- ==========================================================
    OPTIONS INPUT WRAP
    OPEN WINDOW w_wh_lkup WITH FORM "wh121_lkup" ATTRIBUTES(STYLE = "dialog")

    DIALOG ATTRIBUTES(UNBUFFERED)

        -- ------------------------------------------------------
        -- Search input
        -- ------------------------------------------------------
        INPUT BY NAME f_search
            AFTER FIELD f_search
                --CALL load_warehouses_for_lookup(
                --    f_search)
                --    RETURNING wh_arr, row_count

                CALL DIALOG.setArrayLength("r_wh_list", wh_arr.getLength())
                CALL DIALOG.setCurrentRow("r_wh_list", IIF(row_count > 0, 1, 0))
                NEXT FIELD f_search
        END INPUT

        -- ------------------------------------------------------
        -- Display warehouse list
        -- ------------------------------------------------------
        DISPLAY ARRAY wh_arr TO r_wh_list.*

            BEFORE DISPLAY
                CALL DIALOG.setCurrentRow("r_wh_list", 1)

            ON ACTION accept
                LET sel = DIALOG.getCurrentRow("r_wh_list")
                IF sel > 0 AND sel <= wh_arr.getLength() THEN
                    LET selected_code = wh_arr[sel].wh_code
                    EXIT DIALOG
                END IF

            ON ACTION doubleclick
                LET sel = DIALOG.getCurrentRow("r_wh_list")
                IF sel > 0 AND sel <= wh_arr.getLength() THEN
                    LET selected_code = wh_arr[sel].wh_code
                    EXIT DIALOG
                END IF

            ON KEY(RETURN)
                LET sel = DIALOG.getCurrentRow("r_wh_list")
                IF sel > 0 AND sel <= wh_arr.getLength() THEN
                    LET selected_code = wh_arr[sel].wh_code
                    EXIT DIALOG
                END IF

            ON ACTION cancel
                LET selected_code = NULL
                EXIT DIALOG

        END DISPLAY

    END DIALOG

    CLOSE WINDOW w_wh_lkup

    RETURN selected_code
END FUNCTION

FUNCTION load_warehouses_for_lookup()

END FUNCTION 
