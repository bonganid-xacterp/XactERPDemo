-- ==============================================================
-- Program   : wh102_lkup.4gl
-- Purpose   : Warehouse Lookup (search and list records)
-- Module    : Warehouse (wh)
-- Number    : 102
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Lookup functionality for warehouses
--              Provides search, filter and selection capabilities
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoappdb

-- Warehouse lookup record structure
TYPE warehouse_lookup_t RECORD
    wh_code     STRING,           -- Warehouse code
    wh_name     STRING,           -- Warehouse name
    location    STRING,           -- Physical location
    status      SMALLINT,         -- Status code
    status_desc STRING            -- Status description
END RECORD

DEFINE arr_warehouses DYNAMIC ARRAY OF warehouse_lookup_t
DEFINE search_criteria STRING
DEFINE selected_warehouse STRING

MAIN
    IF NOT utils_globals.connectDatabase() THEN
        EXIT PROGRAM 1
    END IF
    
    OPEN WINDOW w_wh102 WITH FORM "wh102_lkup" ATTRIBUTES(STYLE = "main")
    CALL init_lookup()
    CLOSE WINDOW w_wh102
END MAIN

-- Initialize lookup dialog and load all warehouses
FUNCTION init_lookup()
    LET search_criteria = ""
    LET selected_warehouse = ""

    DIALOG ATTRIBUTES(UNBUFFERED)
        -- Display array for warehouse list
        DISPLAY ARRAY arr_warehouses TO warehouses.*
            ATTRIBUTES(COUNT=arr_warehouses.getLength())

            -- Search functionality
            ON ACTION search ATTRIBUTES(TEXT="Search", IMAGE="zoom")
                CALL search_warehouses()
                
            -- Clear search and show all records
            ON ACTION clear ATTRIBUTES(TEXT="Clear", IMAGE="clear")
                CALL load_all_warehouses()
                
            -- Select current warehouse and return
            ON ACTION select ATTRIBUTES(TEXT="Select", IMAGE="accept")
                CALL select_current_warehouse()
                EXIT DIALOG
                
            -- Double-click to select
            ON ACTION doubleClick
                CALL select_current_warehouse()
                EXIT DIALOG
                
            -- Refresh the list
            ON ACTION refresh ATTRIBUTES(TEXT="Refresh", IMAGE="refresh")
                CALL refresh_list()
                
            -- Export list to file
            ON ACTION export ATTRIBUTES(TEXT="Export", IMAGE="export")
                CALL export_warehouse_list()
                
            ON ACTION QUIT ATTRIBUTES(TEXT="Quit", IMAGE="quit")
                EXIT DIALOG
        END DISPLAY

        -- Search input field
        INPUT search_criteria FROM search_field
            ATTRIBUTES(WITHOUT DEFAULTS)
            
            -- Auto-search as user types
            ON CHANGE search_criteria
                IF LENGTH(search_criteria) >= 2 THEN
                    CALL search_warehouses()
                END IF
                
            -- Enter key triggers search
            ON ACTION search
                CALL search_warehouses()
        END INPUT

        BEFORE DIALOG
            CALL load_all_warehouses()  -- Load initial data
    END DIALOG
END FUNCTION

-- Load all warehouse records into array
FUNCTION load_all_warehouses()
    DEFINE idx INTEGER
    
    CALL arr_warehouses.clear()
    LET idx = 0

    -- Query all warehouses with status description
    DECLARE c_all_warehouses CURSOR FOR
        SELECT wh_code, wh_name, location, status,
               CASE status 
                   WHEN 1 THEN 'Active'
                   WHEN 0 THEN 'Inactive'
                   ELSE 'Unknown'
               END
        FROM wh01_mast
        ORDER BY wh_code

    FOREACH c_all_warehouses INTO arr_warehouses[idx + 1].*
        LET idx = idx + 1
    END FOREACH
    FREE c_all_warehouses

    -- Show record count
    IF arr_warehouses.getLength() = 0 THEN
        CALL utils_globals.msg_no_record()
    ELSE
        MESSAGE "Found " || arr_warehouses.getLength() || " warehouse records"
    END IF
END FUNCTION

-- Search warehouses based on criteria
FUNCTION search_warehouses()
    DEFINE idx INTEGER
    DEFINE whereClause STRING
    DEFINE sql STRING
    
    -- Build search criteria
    IF utils_globals.is_empty(search_criteria) THEN
        CALL load_all_warehouses()
        RETURN
    END IF
    
    -- Create flexible search across multiple fields
    LET whereClause = "UPPER(wh_code) LIKE '%" || UPSHIFT(search_criteria) || "%' OR " ||
                      "UPPER(wh_name) LIKE '%" || UPSHIFT(search_criteria) || "%' OR " ||
                      "UPPER(location) LIKE '%" || UPSHIFT(search_criteria) || "%'"
    
    CALL arr_warehouses.clear()
    LET idx = 0
    
    LET sql = "SELECT wh_code, wh_name, location, status, " ||
              "       CASE status WHEN 1 THEN 'Active' WHEN 0 THEN 'Inactive' ELSE 'Unknown' END " ||
              "FROM wh01_mast WHERE " || whereClause || " ORDER BY wh_code"

    DECLARE c_search_warehouses CURSOR FROM sql
    
    FOREACH c_search_warehouses INTO arr_warehouses[idx + 1].*
        LET idx = idx + 1
    END FOREACH
    FREE c_search_warehouses

    -- Show search results
    IF arr_warehouses.getLength() = 0 THEN
        CALL utils_globals.show_info("No warehouses found matching: " || search_criteria)
    ELSE
        MESSAGE "Found " || arr_warehouses.getLength() || " warehouses matching: " || search_criteria
    END IF
END FUNCTION

-- Select current warehouse from array
FUNCTION select_current_warehouse()
    DEFINE current_row INTEGER
    
    LET current_row = arr_curr()
    IF current_row > 0 AND current_row <= arr_warehouses.getLength() THEN
        LET selected_warehouse = arr_warehouses[current_row].wh_code
        CALL utils_globals.show_success("Selected warehouse: " || selected_warehouse)
        -- Return selected warehouse code for calling program
        DISPLAY "SELECTED:", selected_warehouse
    ELSE
        CALL utils_globals.show_info("No warehouse selected.")
    END IF
END FUNCTION

-- Refresh the current list
FUNCTION refresh_list()
    IF utils_globals.is_empty(search_criteria) THEN
        CALL load_all_warehouses()
    ELSE
        CALL search_warehouses()
    END IF
    CALL utils_globals.show_info("List refreshed.")
END FUNCTION

-- Export warehouse list to CSV file
FUNCTION export_warehouse_list()
    DEFINE i INTEGER
    DEFINE export_file STRING
    DEFINE ch base.Channel
    
    IF arr_warehouses.getLength() = 0 THEN
        CALL utils_globals.show_info("No data to export.")
        RETURN
    END IF
    
    LET export_file = "warehouse_lookup_" || TODAY USING "yyyymmdd" || ".csv"
    
    TRY
        LET ch = base.Channel.create()
        CALL ch.openFile(export_file, "w")
        
        -- Write CSV header
        CALL ch.writeLine("Warehouse Code,Warehouse Name,Location,Status,Status Description")
        
        -- Write warehouse data
        FOR i = 1 TO arr_warehouses.getLength()
            CALL ch.writeLine(arr_warehouses[i].wh_code || "," ||
                             arr_warehouses[i].wh_name || "," ||
                             arr_warehouses[i].location || "," ||
                             arr_warehouses[i].status || "," ||
                             arr_warehouses[i].status_desc)
        END FOR
        
        CALL ch.close()
        CALL utils_globals.show_success("Warehouse list exported to: " || export_file)
        
    CATCH
        CALL utils_globals.show_error("Export failed: " || STATUS)
    END TRY
END FUNCTION

-- Public function to get selected warehouse code
FUNCTION get_selected_warehouse() RETURNS STRING
    RETURN selected_warehouse
END FUNCTION

-- Public function for external lookup calls
FUNCTION lookup_warehouse(default_search STRING) RETURNS STRING
    IF NOT utils_globals.is_empty(default_search) THEN
        LET search_criteria = default_search
    END IF
    
    CALL init_lookup()
    RETURN selected_warehouse
END FUNCTION