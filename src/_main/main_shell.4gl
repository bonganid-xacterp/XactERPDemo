# ==============================================================
# Program   :   main_shell.4gl
# Purpose   :   Centralized container window with menu + child mgmt
# Module    :   Main
# Number    :
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.20.10
# ==============================================================

IMPORT ui
IMPORT FGL utils_ui
IMPORT FGL sy100_login

-- Track open modules
DEFINE g_open_modules DYNAMIC ARRAY OF RECORD
    prog STRING, -- form/program name
    winname STRING -- window identifier
END RECORD

-- Launch child with duplicate check
FUNCTION launch_child_window(formname STRING, wintitle STRING)
    DEFINE i INTEGER
    DEFINE winname STRING

    -- Check if already open
    FOR i = 1 TO g_open_modules.getLength()
        IF g_open_modules[i].prog = formname THEN
            CALL utils_ui.show_alert(
                wintitle || " is already open!", "System Alert")
            RETURN
        END IF
    END FOR

    -- Assign unique window name
    LET winname = "w_" || formname

    -- Attach child to mdi_wrapper container
    CALL ui.Interface.setContainer("mdi_wrapper")
    CALL ui.Interface.setType("child")

    -- Open child window (using Window.child style)
    OPEN WINDOW winname
        WITH
        FORM formname
        ATTRIBUTES(STYLE = "child", TEXT = wintitle)

    -- Add to registry
    LET i = g_open_modules.getLength() + 1
    LET g_open_modules[i].prog = formname
    LET g_open_modules[i].winname = winname
END FUNCTION

-- Add companion cleanup function
FUNCTION close_child_window(formname STRING)
    DEFINE i INTEGER

    FOR i = 1 TO g_open_modules.getLength()
        IF g_open_modules[i].prog = formname THEN
            CALL g_open_modules.deleteElement(i)
            EXIT FOR
        END IF
    END FOR
END FUNCTION

-- Remove from registry when closed
FUNCTION unregister_program(formname STRING)
    DEFINE i INTEGER
    FOR i = 1 TO g_open_modules.getLength()
        IF g_open_modules[i].prog = formname THEN
            CALL g_open_modules.deleteElement(i)
            EXIT FOR
        END IF
    END FOR
END FUNCTION
