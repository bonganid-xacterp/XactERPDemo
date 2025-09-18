# ==============================================================
# Program : sy100_main.4gl
# Purpose : Minimal app container (no login yet)
# Module  : System (sy)
# Number  : 100 (Input Program per standard)
# Version : v0.1 (Genero BDL 3.2.1)
# ==============================================================

IMPORT os -- 3.2.1-safe; future file ops

CONSTANT k_app_version = "XACT ERP Demo v0.1"

-- Modular variables (window + form handles)
DEFINE g_win ui.Window
DEFINE g_form ui.Form

MAIN
    DEFER INTERRUPT -- Defer Ctrl+C to safe points

    CALL init_app() -- 1) Clear/init globals
    CALL open_main_shell() -- 2) Open the main container window

    CALL run_main_menu() -- 3) Basic menu loop (no business logic here)

    CALL shutdown_app() -- 4) Tidy close
END MAIN

# ------------------ INITIALISATION (no business logic) --------
FUNCTION init_app()
    -- If we add globals later, we clear/init them here.
END FUNCTION

# ------------------ BUILD/DISPLAY (UI only) -------------------
FUNCTION open_main_shell()

    -- Close the default SCREEN window first
    CLOSE WINDOW SCREEN

    -- Open a window with a very small shell form (main_container.4fd)
    OPEN WINDOW w_main WITH FORM "main_container" ATTRIBUTES(NORMAL);
    LET g_win = ui.Window.getCurrent()
    LET g_form = g_win.getForm()

    -- Set a nice title bar
    CALL g_win.setText("XACT ERP Demo – Dev - Bongani Dlamini")

    -- Show version in form label if present
    IF g_form IS NOT NULL THEN
        CALL g_form.setElementText("lbl_version", k_app_version)
    END IF
END FUNCTION

# ------------------ MAIN MENU (keep thin) ---------------------
FUNCTION run_main_menu()
    MENU "XACT ERP Demo"
        COMMAND "About"
            MESSAGE k_app_version
        COMMAND "Quit"
            EXIT MENU
    END MENU
END FUNCTION

# ------------------ SHUTDOWN / CLEAR --------------------------
FUNCTION shutdown_app()
    -- IMPORTANT: CLOSE WINDOW expects an identifier, not an expression.
    -- That's why we close 'w_main' directly, not g_win.getIdentifier().
    CLOSE WINDOW w_main
END FUNCTION
