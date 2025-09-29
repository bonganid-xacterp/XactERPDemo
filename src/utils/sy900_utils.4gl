-- sy900_utils.4gl
-- Utility functions for global dialogs and UI helpers

FUNCTION show_alert(p_message STRING)
    DEFINE g_alert_win ui.Window
    DEFINE g_alert_form ui.Form

    -- Open a small modal window with your alert form
    OPEN WINDOW w_alert WITH FORM "frm_sy900_alert"
    LET g_alert_win = ui.Window.getCurrent()
    LET g_alert_form = g_alert_win.getForm()
    CALL g_alert_win.setText("System Alert")

    -- Populate the form label with the passed message
    CALL g_alert_form.setElementText("lbl_message", p_message)

    -- Dialog waits for user to acknowledge
    DIALOG
        INPUT BY NAME p_message
            -- User presses OK
            ON ACTION ok
                EXIT DIALOG
        END INPUT
    END DIALOG

    CLOSE WINDOW w_alert
END FUNCTION
