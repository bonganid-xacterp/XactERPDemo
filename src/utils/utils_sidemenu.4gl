-- ==============================================================
-- File     : utils_sidemenu.4gl
-- Purpose  : Reusable vertical side menu with mode-aware actions
-- Author   : Bongani Dlamini
-- Version  : Genero 3.20.10
-- Notes    :
--   * No ui.Form.setActionActive() calls (not available) —
--     we use ui.Interface.setActionActive() and dlg.setActionActive().
--   * Exposes a tiny API you can call from any master program.
-- ==============================================================

IMPORT ui

-- ================================
-- Public constants (modes)
-- ================================
CONSTANT MODE_VIEW = 0
CONSTANT MODE_NEW = 1
CONSTANT MODE_EDIT = 2

-- ================================
-- State (module-scope)
-- ================================
DEFINE g_mode SMALLINT
DEFINE g_has_record SMALLINT
DEFINE g_is_dirty SMALLINT
DEFINE g_dlg ui.Dialog

-- ================================
-- Public API
-- ================================
FUNCTION sm_init(dlg ui.Dialog)
    LET g_dlg = dlg
    IF g_dlg IS NULL THEN
        -- Optional but recommended: pass your main dialog reference.
        -- We'll still manage toolbar actions via ui.Interface.
    END IF

    CALL build_toolbar()
    CALL sm_set_mode(MODE_VIEW, FALSE) -- default on load
END FUNCTION

FUNCTION sm_set_mode(p_mode SMALLINT, p_has_record SMALLINT)
    LET g_mode = p_mode
    LET g_has_record = p_has_record
    LET g_is_dirty = FALSE
    CALL apply_action_states()
END FUNCTION

FUNCTION sm_on_record_loaded(p_has_record SMALLINT)
    LET g_has_record = p_has_record
    CALL apply_action_states()
END FUNCTION

FUNCTION sm_set_dirty(p_dirty SMALLINT)
    LET g_is_dirty = p_dirty
    CALL apply_action_states()
END FUNCTION

FUNCTION sm_enable_nav(has_prev SMALLINT, has_next SMALLINT)
    -- Optional: call after you compute navigation flags
    CALL activate("first", has_prev)
    CALL activate("prev", has_prev)
    CALL activate("next", has_next)
    CALL activate("last", has_next)
END FUNCTION

-- ================================
-- Internal helpers
-- ================================
FUNCTION build_toolbar()
    DEFINE f ui.Form
    LET f = ui.Window.getCurrent().getForm()

    -- Create a vertical toolbar on the left
    CALL f.loadToolBar("main_toolbar")
    --CALL f.load("main_toolbar", "orientation", "vertical")
    --CALL f.setToolBarAttribute("sideMenu", "position", "left")
    --CALL f.setToolBarAttribute("sideMenu", "style", "side")

    -- Core CRUD / search
    CALL add_action("new", "New", "new.png")
    CALL add_action("edit", "Edit", "edit.png")
    CALL add_action("delete", "Delete", "delete.png")
    CALL add_action("save", "Save", "save.png")
    CALL add_action("cancel", "Cancel", "cancel.png")
    CALL add_action("find", "Search", "zoom.png")

    -- Navigation (optional, enable via sm_enable_nav)
    CALL add_action("first", "First", "first.png")
    CALL add_action("prev", "Previous", "prev.png")
    CALL add_action("next", "Next", "next.png")
    CALL add_action("last", "Last", "last.png")

    -- Output / comms
    CALL add_action("print", "Print", "print.png")
    CALL add_action("email", "Email", "mail.png")

    -- Exit
    CALL add_action("exit", "Exit", "exit.png")
END FUNCTION

FUNCTION add_action(name STRING, label STRING, icon STRING)
    DEFINE f ui.Form
    LET f = ui.Window.getCurrent().getForm()
    --CALL f.addToolBarAction("sideMenu", name)
    --CALL f.setActionText(name, label)
    --CALL f.setActionImage(name, icon)
    -- default active; will be refined by apply_action_states()
    --CALL ui.Interface.setActionActive(name, TRUE)
    IF g_dlg IS NOT NULL THEN
        CALL g_dlg.setActionActive(name, TRUE)
    END IF
END FUNCTION

FUNCTION activate(action STRING, enabled SMALLINT)
    --CALL ui.Interface..setActionActive(action, enabled)
    IF g_dlg IS NOT NULL THEN
        CALL g_dlg.setActionActive(action, enabled)
    END IF
END FUNCTION

FUNCTION apply_action_states()
    DEFINE
        v_is_view SMALLINT,
        v_is_new SMALLINT,
        v_is_edit SMALLINT

    LET v_is_view = (g_mode = MODE_VIEW)
    LET v_is_new = (g_mode = MODE_NEW)
    LET v_is_edit = (g_mode = MODE_EDIT)

    -- In VIEW: allow New, Find; allow Edit/Delete/Print/Email if a record exists
    IF v_is_view THEN
        CALL activate("new", TRUE)
        CALL activate("find", TRUE)
        CALL activate("edit", g_has_record)
        CALL activate("delete", g_has_record)
        CALL activate("print", g_has_record)
        CALL activate("email", g_has_record)

        CALL activate("save", FALSE)
        CALL activate("cancel", FALSE)

        -- nav defaults (caller may override via sm_enable_nav)
        CALL activate("first", g_has_record)
        CALL activate("prev", g_has_record)
        CALL activate("next", g_has_record)
        CALL activate("last", g_has_record)
    END IF

    -- In NEW: only Save/Cancel; disable everything else
    IF v_is_new THEN
        CALL activate("new", FALSE)
        CALL activate("find", FALSE)
        CALL activate("edit", FALSE)
        CALL activate("delete", FALSE)
        CALL activate("print", FALSE)
        CALL activate("email", FALSE)
        CALL activate("first", FALSE)
        CALL activate("prev", FALSE)
        CALL activate("next", FALSE)
        CALL activate("last", FALSE)

        CALL activate("save", TRUE)
        CALL activate("cancel", TRUE)
    END IF

    -- In EDIT: only Save/Cancel; disable everything else
    IF v_is_edit THEN
        CALL activate("new", FALSE)
        CALL activate("find", FALSE)
        CALL activate("edit", FALSE)
        CALL activate("delete", FALSE)
        CALL activate("print", FALSE)
        CALL activate("email", FALSE)
        CALL activate("first", FALSE)
        CALL activate("prev", FALSE)
        CALL activate("next", FALSE)
        CALL activate("last", FALSE)

        CALL activate("save", TRUE)
        CALL activate("cancel", TRUE)
    END IF

    -- Optional: if dirty, you could also force-enable Save/Cancel
    IF g_is_dirty THEN
        CALL activate("save", TRUE)
        CALL activate("cancel", TRUE)
    END IF

    -- Exit is always available
    CALL activate("exit", TRUE)
END FUNCTION
