# UI Utilities

FUNCTION show_alert(p_message STRING, p_title STRING)
    DEFINE l_title STRING

    -- If caller passed NULL/empty, fall back to default
    IF p_title IS NULL OR p_title = "" THEN
        LET l_title = "System Alert"
    ELSE
        LET l_title = p_title
    END IF

    DIALOG
        INPUT BY NAME p_message
            ON ACTION ok
                EXIT DIALOG
        END INPUT
    END DIALOG

END FUNCTION

FUNCTION set_page_title(p_title STRING)
    DEFINE g_win ui.Window
    LET g_win = ui.Window.getCurrent()
    IF g_win IS NOT NULL THEN
        CALL g_win.setText("XACT ERP Demo – " || p_title)
    END IF
END FUNCTION
