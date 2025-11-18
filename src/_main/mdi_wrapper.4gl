-- ==============================================================
-- Program   : mdi_wrapper.4gl
-- Purpose   : Simple MDI Tabbed Container
-- Description: Reusable MDI wrapper for loading modules as tabs
-- ==============================================================

IMPORT ui
IMPORT FGL cl101_mast

SCHEMA demoappdb

MAIN
    CALL open_mdi_tabs()
END MAIN

FUNCTION open_mdi_tabs()
    DEFINE w ui.Window
    DEFINE f ui.Form
    DEFINE folder_node ui.Node

    -- Open main MDI window
    OPEN WINDOW w_mdi WITH FORM "mdi_shell"
        ATTRIBUTES(TEXT = "XACT ERP - MDI")

    LET w = ui.Window.getCurrent()
    LET f = w.getForm()
    LET folder_node = f.findNode("Folder", "main_folder")

    -- Load initial module as first tab
    CALL load_module_tab(folder_node, "cl101_mast", "Suppliers")

    -- Keep window open
    MENU "MDI"
        ON ACTION close
            EXIT MENU
    END MENU

    CLOSE WINDOW w_mdi
END FUNCTION

FUNCTION load_module_tab(folder_node ui.Node, module_name STRING, tab_title STRING)
    -- Launch module based on name
    CASE module_name
        WHEN "cl101_mast"
            CALL cl101_mast.init_cl_module()
    END CASE
END FUNCTION
