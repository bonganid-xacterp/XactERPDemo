-- ==============================================================
-- Program   : wb102_lkup.4gl
-- Purpose   : Warehouse Bin Lookup (search and list records)
-- Module    : Warehouse Bin (wb)
-- Number    : 102
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Lookup functionality for warehouse bins
--              Provides search, filter and selection capabilities
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoapp_db

-- Bin lookup record structure
TYPE bin_lookup_t RECORD
    wb_code STRING,
    wh_id STRING,
    description STRING,
    status SMALLINT,
    status_desc STRING
END RECORD

DEFINE arr_bins DYNAMIC ARRAY OF bin_lookup_t
DEFINE search_criteria STRING
DEFINE selected_bin STRING

MAIN
    IF NOT utils_globals.initialize_application() THEN
        EXIT PROGRAM 1
    END IF

    OPEN WINDOW w_wb102 WITH FORM "wb102_lkup" ATTRIBUTES(STYLE = "main")
    CALL init_lookup()
    CLOSE WINDOW w_wb102
END MAIN

-- Initialize lookup dialog and load all bins
FUNCTION init_lookup()
    LET search_criteria = ""
    LET selected_bin = ""

    DIALOG ATTRIBUTES(UNBUFFERED)
        -- Display array for bin list
        DISPLAY ARRAY arr_bins
            TO bins.*
            ATTRIBUTES(COUNT = arr_bins.getLength())

            -- Search functionality
            ON ACTION search ATTRIBUTES(TEXT = "Search", IMAGE = "zoom")
                CALL search_bins()

                -- Clear search and show all records
            ON ACTION clear ATTRIBUTES(TEXT = "Clear", IMAGE = "clear")
                CALL load_all_bins()

                -- Select current bin and return
            ON ACTION select ATTRIBUTES(TEXT = "Select", IMAGE = "accept")
                CALL select_current_bin()
                EXIT DIALOG

                -- Double-click to select
            ON ACTION doubleClick
                CALL select_current_bin()
                EXIT DIALOG

                -- Refresh the list
            ON ACTION refresh ATTRIBUTES(TEXT = "Refresh", IMAGE = "refresh")
                CALL refresh_list()

                -- Export list to file
            ON ACTION export ATTRIBUTES(TEXT = "Export", IMAGE = "export")
                CALL export_bin_list()

            ON ACTION QUIT ATTRIBUTES(TEXT = "Quit", IMAGE = "quit")
                EXIT DIALOG
        END DISPLAY

        -- Search input field
        INPUT search_criteria FROM search_field ATTRIBUTES(WITHOUT DEFAULTS)

            -- Auto-search as user types
            ON CHANGE search_criteria
                IF LENGTH(search_criteria) >= 2 THEN
                    CALL search_bins()
                END IF

                -- Enter key triggers search
            ON ACTION search
                CALL search_bins()
        END INPUT

        BEFORE DIALOG
            CALL load_all_bins() -- Load initial data
    END DIALOG
END FUNCTION

-- Load all bin records into array
FUNCTION load_all_bins()
    DEFINE idx INTEGER

    CALL arr_bins.clear()
    LET idx = 0

    -- Query all bins with status description
    DECLARE c_all_bins CURSOR FOR
        SELECT wb_code,
            wh_id,
            description,
            status,
            CASE status
                WHEN 1 THEN 'Active' WHEN 0 THEN 'Inactive'
                ELSE 'Unknown' END
            FROM wb01_mast
            ORDER BY wb_code

    FOREACH c_all_bins INTO arr_bins[idx + 1].*
        LET idx = idx + 1
    END FOREACH
    FREE c_all_bins

    -- Show record count
    IF arr_bins.getLength() = 0 THEN
        CALL utils_globals.msg_no_record()
    ELSE
        MESSAGE "Found " || arr_bins.getLength() || " bin records"
    END IF
END FUNCTION

-- Search bins based on criteria
FUNCTION search_bins()
    DEFINE idx INTEGER
    DEFINE whereClause STRING
    DEFINE sql STRING

    -- Build search criteria
    IF utils_globals.is_empty(search_criteria) THEN
        CALL load_all_bins()
        RETURN
    END IF

    -- Create flexible search across multiple fields
    LET whereClause =
        "UPPER(wb_code) LIKE '%"
            || UPSHIFT(search_criteria)
            || "%' OR "
            || "UPPER(wh_id) LIKE '%"
            || UPSHIFT(search_criteria)
            || "%' OR "
            || "UPPER(description) LIKE '%"
            || UPSHIFT(search_criteria)
            || "%'"

    CALL arr_bins.clear()
    LET idx = 0

    LET sql =
        "SELECT wb_code, wh_id, description, status, "
            || "       CASE status WHEN 1 THEN 'Active' WHEN 0 THEN 'Inactive' ELSE 'Unknown' END "
            || "FROM wb01_mast WHERE "
            || whereClause
            || " ORDER BY wb_code"

    DECLARE c_search_bins CURSOR FROM sql

    FOREACH c_search_bins INTO arr_bins[idx + 1].*
        LET idx = idx + 1
    END FOREACH
    FREE c_search_bins

    -- Show search results
    IF arr_bins.getLength() = 0 THEN
        CALL utils_globals.show_info(
            "No bins found matching: " || search_criteria)
    ELSE
        MESSAGE "Found "
            || arr_bins.getLength()
            || " bins matching: "
            || search_criteria
    END IF
END FUNCTION

-- Select current bin from array
FUNCTION select_current_bin()
    DEFINE current_row INTEGER

    LET current_row = arr_curr()
    IF current_row > 0 AND current_row <= arr_bins.getLength() THEN
        LET selected_bin = arr_bins[current_row].wb_code
        CALL utils_globals.show_success("Selected bin: " || selected_bin)
        -- Return selected bin code for calling program
        DISPLAY "SELECTED:", selected_bin
    ELSE
        CALL utils_globals.show_info("No bin selected.")
    END IF
END FUNCTION

-- Refresh the current list
FUNCTION refresh_list()
    IF utils_globals.is_empty(search_criteria) THEN
        CALL load_all_bins()
    ELSE
        CALL search_bins()
    END IF
    CALL utils_globals.show_info("List refreshed.")
END FUNCTION

-- Export bin list to CSV file
FUNCTION export_bin_list()
    DEFINE i INTEGER
    DEFINE export_file STRING
    DEFINE ch base.Channel

    IF arr_bins.getLength() = 0 THEN
        CALL utils_globals.show_info("No data to export.")
        RETURN
    END IF

    LET export_file = "bin_lookup_" || TODAY USING "yyyymmdd" || ".csv"

    TRY
        LET ch = base.Channel.create()
        CALL ch.openFile(export_file, "w")

        -- Write CSV header
        CALL ch.writeLine(
            "Bin Code,Warehouse ID,Description,Status,Status Description")

        -- Write bin data
        FOR i = 1 TO arr_bins.getLength()
            CALL ch.writeLine(
                arr_bins[i].wb_code
                    || ","
                    || arr_bins[i].wh_id
                    || ","
                    || arr_bins[i].description
                    || ","
                    || arr_bins[i].status
                    || ","
                    || arr_bins[i].status_desc)
        END FOR

        CALL ch.close()
        CALL utils_globals.show_success("Bin list exported to: " || export_file)

    CATCH
        CALL utils_globals.show_error("Export failed: " || STATUS)
    END TRY
END FUNCTION

-- Public function to get selected bin code
FUNCTION get_selected_bin() RETURNS STRING
    RETURN selected_bin
END FUNCTION

-- Public function for external lookup calls
FUNCTION lookup_bin(default_search STRING) RETURNS STRING
    IF NOT utils_globals.is_empty(default_search) THEN
        LET search_criteria = default_search
    END IF

    CALL init_lookup()
    RETURN selected_bin
END FUNCTION
