-- ==============================================================
-- Program   : utils_windows.4gl
-- Purpose   : Global window management utilities
-- Module    : Utils
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL fgldialog

-- ==============================================================
-- FUNCTION: handle_window_close
-- Purpose : Standard handler for window close (X) button
-- Usage   : ON ACTION close
--             CALL utils_windows.handle_window_close() RETURNING exit_flag
--             IF exit_flag THEN
--                 EXIT INPUT/MENU/DIALOG
--             END IF
-- ==============================================================
FUNCTION handle_window_close() RETURNS SMALLINT
    DEFINE answer STRING

    LET answer =
        fgldialog.fgl_winquestion(
            "Confirm Close",
            "Are you sure you want to close this window?",
            "no",
            "yes|no",
            "question",
            0)

    RETURN (answer = "yes")
END FUNCTION

-- ==============================================================
-- FUNCTION: handle_window_close_no_confirm
-- Purpose : Close window immediately without confirmation
-- Usage   : ON ACTION close
--             CALL utils_windows.handle_window_close_no_confirm()
--             EXIT INPUT/MENU/DIALOG
-- ==============================================================
FUNCTION handle_window_close_no_confirm() RETURNS SMALLINT
    RETURN TRUE
END FUNCTION

-- ==============================================================
-- FUNCTION: handle_exit_with_confirm
-- Purpose : Confirm exit with custom message
-- Usage   : ON ACTION close
--             IF utils_windows.handle_exit_with_confirm("Exit Application?") THEN
--                 EXIT MENU
--             END IF
-- ==============================================================
FUNCTION handle_exit_with_confirm(p_message STRING) RETURNS SMALLINT
    DEFINE answer STRING
    DEFINE message STRING

    IF p_message IS NULL OR p_message = "" THEN
        LET message = "Are you sure you want to close this window?"
    ELSE
        LET message = p_message
    END IF

    LET answer =
        fgldialog.fgl_winquestion(
            "Confirm", message, "no", "yes|no", "question", 0)

    RETURN (answer = "yes")
END FUNCTION

-- ==============================================================
-- FUNCTION: close_current_window
-- Purpose : Close the current window safely
-- ==============================================================
FUNCTION close_current_window()
    DEFINE w ui.Window
    DEFINE win_name STRING

    TRY
        LET w = ui.Window.getCurrent()
        IF w IS NOT NULL THEN
            LET win_name = w.getText()
            -- Note: This function is informational only
            -- You must close windows explicitly by name in your code
            DISPLAY "Current window: ", win_name
        END IF
    CATCH
        DISPLAY "Warning: Could not get current window"
    END TRY
END FUNCTION

-- ==============================================================
-- FUNCTION: confirm_unsaved_changes
-- Purpose : Standard dialog for unsaved changes
-- Returns : TRUE if user wants to discard changes
-- ==============================================================
FUNCTION confirm_unsaved_changes() RETURNS SMALLINT
    DEFINE answer STRING

    LET answer =
        fgldialog.fgl_winquestion(
            "Unsaved Changes",
            "You have unsaved changes.\n\nDiscard changes and close?",
            "no",
            "yes|no",
            "exclamation",
            0)

    RETURN (answer = "yes")
END FUNCTION

-- ==============================================================
-- FUNCTION: standard_close_handler
-- Purpose : Complete close handler with optional dirty flag check
-- Usage   : ON ACTION close
--             IF utils_windows.standard_close_handler(has_changes) THEN
--                 EXIT INPUT
--             END IF
-- ==============================================================
FUNCTION standard_close_handler(p_has_changes SMALLINT) RETURNS SMALLINT

    IF p_has_changes THEN
        RETURN confirm_unsaved_changes()
    ELSE
        RETURN handle_window_close()
    END IF

END FUNCTION
