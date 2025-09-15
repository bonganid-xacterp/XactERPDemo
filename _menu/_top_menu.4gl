DATABASE xactdemoapp_db

GLOBALS
    DEFINE g_userid INTEGER   -- logged-in user
END GLOBALS

FUNCTION start_menu(p_userid INTEGER)
    DEFINE l_exit SMALLINT
    LET g_userid = p_userid

    OPEN WINDOW w_main WITH FORM "f_main_menu"

    MENU "System Navigation"
        -- Debtors
        COMMAND "Debtors"
            IF can(g_userid, "DL.MENU") THEN
                CALL open_debtors()
            ELSE
                ERROR "Access denied."
            END IF

        -- Creditors
        COMMAND "Creditors"
            IF can(g_userid, "CL.MENU") THEN
                CALL open_creditors()
            ELSE
                ERROR "Access denied."
            END IF

        -- Stock
        COMMAND "Stock"
            IF can(g_userid, "ST.MENU") THEN
                CALL open_stock()
            ELSE
                ERROR "Access denied."
            END IF

        -- Warehousing
        COMMAND "Warehouse"
            IF can(g_userid, "WH.MENU") THEN
                CALL open_warehouse()
            ELSE
                ERROR "Access denied."
            END IF

        -- Sales
        COMMAND "Sales"
            IF can(g_userid, "SA30.MENU") OR can(g_userid,"SA32.MENU") THEN
                CALL open_sales()
            ELSE
                ERROR "Access denied."
            END IF

        -- Purchases
        COMMAND "Purchases"
            IF can(g_userid, "PU30.MENU") OR can(g_userid,"PU31.MENU") THEN
                CALL open_purchases()
            ELSE
                ERROR "Access denied."
            END IF

        -- Finance
        COMMAND "Finance"
            IF can(g_userid, "GL.MENU") THEN
                CALL open_finance()
            ELSE
                ERROR "Access denied."
            END IF

        -- Quit
        COMMAND "Quit"
            LET l_exit = TRUE
            EXIT MENU
    END MENU

    CLOSE WINDOW w_main
END FUNCTION

-- ========== TOOLBAR NAVIGATION ==========
TOOLBAR
    TOOLITEM "Search" IMAGE="search.png" COMMENT="Global search"
        CALL global_search()

    TOOLITEM "Prev" IMAGE="prev.png" COMMENT="Previous record"
        CALL global_prev()

    TOOLITEM "Next" IMAGE="next.png" COMMENT="Next record"
        CALL global_next()

    TOOLITEM "Delete" IMAGE="delete.png" COMMENT="Delete record"
        CALL global_delete()
END TOOLBAR

-- ========== STUB FUNCTIONS ==========
FUNCTION open_debtors()
    MESSAGE "Debtors module opened..."
END FUNCTION

FUNCTION open_creditors()
    MESSAGE "Creditors module opened..."
END FUNCTION

FUNCTION open_stock()
    MESSAGE "Stock module opened..."
END FUNCTION

FUNCTION open_warehouse()
    MESSAGE "Warehouse module opened..."
END FUNCTION

FUNCTION open_sales()
    MESSAGE "Sales module opened..."
END FUNCTION

FUNCTION open_purchases()
    MESSAGE "Purchases module opened..."
END FUNCTION

FUNCTION open_finance()
    MESSAGE "Finance module opened..."
END FUNCTION

-- ========== GLOBAL ACTIONS ==========
FUNCTION global_search()
    MESSAGE "Global search placeholder"
END FUNCTION

FUNCTION global_prev()
    MESSAGE "Previous record placeholder"
END FUNCTION

FUNCTION global_next()
    MESSAGE "Next record placeholder"
END FUNCTION

FUNCTION global_delete()
    MESSAGE "Delete action placeholder"
END FUNCTION
