-- ==============================================================
-- Program   : start_app.4gl
-- Purpose   : XactERP Launcher / Parent MDI Container
-- Author    : Bongani Dlamini
-- Version   : Genero 3.20.10
-- ==============================================================

IMPORT ui
IMPORT om
IMPORT FGL utils_globals
IMPORT FGL sy100_login
IMPORT FGL utils_db
IMPORT FGL main_menu   -- the module that builds the StartMenu

CONSTANT APP_NAME = "XACT ERP System"
CONSTANT MAX_LOGIN_ATTEMPTS = 3

DEFINE g_user_authenticated SMALLINT

MAIN
    -- ==========================================================
    -- 1. Initialize environment
    -- ==========================================================
    IF NOT utils_globals.initialize_application() THEN
        CALL utils_globals.show_error(
            "Application initialization failed. Please contact your system administrator.")
        EXIT PROGRAM 1
    END IF

    -- ==========================================================
    -- 2. Login
    -- ==========================================================
    IF NOT run_login_with_retry() THEN
        CALL utils_globals.show_info("Login cancelled or failed.")
        EXIT PROGRAM
    END IF

    -- ==========================================================
    -- 3. Open main MDI container
    -- ==========================================================
    CALL open_main_container()

    -- ==========================================================
    -- 4. Application exit handling
    -- ==========================================================
    CALL cleanup_application()
END MAIN


-- ==============================================================
-- LOGIN LOGIC
-- ==============================================================
FUNCTION run_login_with_retry() RETURNS SMALLINT
    DEFINE result, attempts SMALLINT
    DEFINE username STRING
    LET attempts = 0

    WHILE attempts < MAX_LOGIN_ATTEMPTS
        LET result = sy100_login.login_user()
        IF result THEN
            LET g_user_authenticated = TRUE
            RETURN TRUE
        END IF
        LET attempts = attempts + 1
        IF attempts < MAX_LOGIN_ATTEMPTS THEN
            CALL utils_globals.show_warning(
                "Invalid credentials (" || attempts || "/" || MAX_LOGIN_ATTEMPTS || "). Try again.")
        END IF
    END WHILE

    CALL utils_globals.show_error("Maximum login attempts exceeded. Application will close.")
    RETURN FALSE
END FUNCTION


-- ==============================================================
-- OPEN MAIN CONTAINER
-- ==============================================================
FUNCTION open_main_container()
    DEFINE username STRING
    DEFINE root, sm, smg, smc om.DomNode

    LET username = sy100_login.get_current_user()

    -- load the style sheet
    CALL ui.Interface.loadStyles("main_styles")

    -- open the main shell (parent container)
    OPEN WINDOW main_shell WITH FORM "main_shell"
         ATTRIBUTES(STYLE="Window.container", TEXT=APP_NAME || " - " || username)

    LET root = ui.Interface.getRootNode()

    -- create StartMenu under this parent
    LET sm = root.createChild("StartMenu")
    CALL sm.setAttribute("text", "XactERP Main Menu")

    -- SALES
    LET smg = createStartMenuGroup(sm, "Sales")
    LET smc = createStartMenuCommand(smg, "Sales Orders", "fglrun sa131_order --mode=child", "order.png")
    LET smc = createStartMenuCommand(smg, "Sales Quotes", "fglrun sa133_quote --mode=child", "quote.png")

    -- PURCHASES
    LET smg = createStartMenuGroup(sm, "Purchases")
    LET smc = createStartMenuCommand(smg, "Purchase Orders", "fglrun pu131_order --mode=child", "purchase.png")

    -- STOCK
    LET smg = createStartMenuGroup(sm, "Stock & Inventory")
    LET smc = createStartMenuCommand(smg, "Stock Items", "fglrun st130_mast --mode=child", "stock.png")

    -- SYSTEM
    LET smg = createStartMenuGroup(sm, "System Configuration")
    LET smc = createStartMenuCommand(smg, "User Management", "fglrun sy131_user --mode=child", "user.png")
    LET smc = createStartMenuCommand(smg, "Roles & Permissions", "fglrun sy132_roles --mode=child", "roles.png")

    --MENU "File"
    --    COMMAND "Exit"
    --        EXIT PROGRAM
    --END MENU
END FUNCTION


-- ==============================================================
-- START MENU HELPERS
-- ==============================================================
FUNCTION createStartMenuGroup(p, t) RETURNS om.DomNode
    DEFINE p om.DomNode, t STRING, s om.DomNode
    LET s = p.createChild("StartMenuGroup")
    CALL s.setAttribute("text", t)
    RETURN s
END FUNCTION

FUNCTION createStartMenuCommand(p, t, c, i) RETURNS om.DomNode
    DEFINE p om.DomNode, t, c, i STRING
    DEFINE s om.DomNode
    LET s = p.createChild("StartMenuCommand")
    CALL s.setAttribute("text", t)
    CALL s.setAttribute("exec", c)
    IF i IS NOT NULL THEN
        CALL s.setAttribute("image", i)
    END IF
    RETURN s
END FUNCTION


-- ==============================================================
-- CLEANUP
-- ==============================================================
FUNCTION cleanup_application()
    DEFINE db_ok SMALLINT
    TRY
        LET db_ok = utils_db.close_database()
        LET g_user_authenticated = FALSE
        DISPLAY "User session closed cleanly."
    CATCH
        DISPLAY "Warning: cleanup error (STATUS=", STATUS, ")"
    END TRY
END FUNCTION
