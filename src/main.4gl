IMPORT ui

MAIN
    DEFINE main_win ui.Window
    DEFINE form ui.Form

    CLOSE WINDOW SCREEN

    -- Step 1: Login
    IF NOT login_screen() THEN
        MESSAGE "Login cancelled. Exiting..."
        EXIT PROGRAM
    END IF

    -- Step 2: Open MDI container window
    OPEN WINDOW w_main_container WITH FORM "main_container"
        ATTRIBUTE(STYLE="container", TEXT="XactERP Demo System")

        CALL update_status("Ready")

    LET main_win = ui.Window.getCurrent()
    LET form     = main_win.getForm()

    -- Step 3: Dashboard
    CALL launch_child_window("dashboard")

    -- Step 4: Main menu
    CALL main_application_menu()

    -- Step 5: Shutdown
    CALL shutdown_application()
    CLOSE WINDOW w_main_container
END MAIN
