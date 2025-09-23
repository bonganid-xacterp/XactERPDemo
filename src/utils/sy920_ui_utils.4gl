# UI Utilities

FUNCTION show_alert(p_message STRING, p_title STRING)
    DEFINE g_alert_win ui.Window
    DEFINE g_alert_form ui.Form
    DEFINE g_title STRING 

    LET g_title =  "System Alert"

    OPEN WINDOW w_alert WITH FORM "frm_sy900_alert"
    LET g_alert_win = ui.Window.getCurrent()
    LET g_alert_form = g_alert_win.getForm()
    CALL g_alert_win.setText(p_title)

    CALL g_alert_form.setElementText("lbl_message", p_message)

    DIALOG
        INPUT BY NAME p_message
            ON ACTION ok
                EXIT DIALOG
        END INPUT
    END DIALOG

    CLOSE WINDOW w_alert
END FUNCTION


FUNCTION set_page_title(p_title STRING)
    DEFINE g_win ui.Window
    LET g_win = ui.Window.getCurrent()
    IF g_win IS NOT NULL THEN
        CALL g_win.setText("XACT ERP Demo – " || p_title)
    END IF
END FUNCTION
