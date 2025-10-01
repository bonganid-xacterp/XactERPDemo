# ==============================================================
# Program   :   wb01_mast.4gl
# Purpose   :   A warehouse bin master program for maintaining the
#               bin records.
# Module    :   Warehouse Bin (wb)
# Number    :   01
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.2.1
# ==============================================================
IMPORT FGL utils_ui

FUNCTION open_wbbin_form()
    DEFINE int_flag_saved SMALLINT

    -- Save current interrupt flag state
    LET int_flag_saved = int_flag

    -- Open the main application container
    OPEN WINDOW w_wb01_mast
        WITH
        FORM "wb01_mast"
        ATTRIBUTE(STYLE = "child", TEXT = "Warehouse Bin")

    -- Set page title (top bar, if defined in form)
    CALL utils_ui.set_page_title("Dashboard")

    -- Main loop: keep the container alive with a menu

    -- Close window when menu exits
    CLOSE WINDOW w_wb01_mast

    -- Restore interrupt flag
    LET int_flag = int_flag_saved
END FUNCTION
