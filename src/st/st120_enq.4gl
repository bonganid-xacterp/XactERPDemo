-- ==============================================================
-- Program   : st120_enq.4gl
-- Purpose   : Stock Enquiry and Search
-- Module    : Stock Enquiry (st)
-- Number    : 120
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals
IMPORT FGL utils_db
IMPORT FGL st121_st_lkup
IMPORT FGL st122_cat_lkup
IMPORT FGL utils_status_const

SCHEMA demoapp_db

-- ==============================================================
-- Record definitions
-- ==============================================================

-- Search criteria record
DEFINE stock_r RECORD LIKE st01_mast.*

-- Stock results array
DEFINE arr_stock_results DYNAMIC ARRAY OF RECORD LIKE st01_mast.*

-- Transaction detail array
DEFINE arr_trans_detail DYNAMIC ARRAY OF RECORD LIKE st30_trans.*

DEFINE curr_stock_idx INTEGER
DEFINE total_value DECIMAL(15, 2)
DEFINE total_profit DECIMAL(15, 2)

-- ==============================================================
-- MAIN - Entry point when run standalone
-- ==============================================================
--MAIN
--    IF NOT utils_globals.initialize_application() THEN
--        DISPLAY "Initialization failed."
--        EXIT PROGRAM 1
--    END IF
--      OPTIONS INPUT WRAP
--    OPEN WINDOW w_st120 WITH FORM "st120_enq" ATTRIBUTES(STYLE = "main")
--    CALL run_stock_enquiry()
--    CLOSE WINDOW w_st120
--END MAIN

-- ==============================================================
-- Run Stock Enquiry - Main entry function
-- ==============================================================
FUNCTION run_stock_enquiry()
    CALL init_enquiry_module()
END FUNCTION

-- ==============================================================
-- Initialize Enquiry Module - Main Dialog
-- ==============================================================
FUNCTION init_enquiry_module()
    -- Initialize search criteria
    INITIALIZE stock_r.* TO NULL

    DIALOG ATTRIBUTES(UNBUFFERED)

        -- Search Criteria Input
        INPUT BY NAME stock_r.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "search_criteria")

            BEFORE INPUT
                -- Set default search to show all active items
                LET stock_r.status = "1"

            ON ACTION lookup_category
                ATTRIBUTES(TEXT = "Lookup Category", DEFAULTVIEW = NO)
                CALL lookup_category_for_search()

            ON ACTION clear_search ATTRIBUTES(TEXT = "Clear", IMAGE = "clear")
                INITIALIZE stock_r.* TO NULL
                LET stock_r.status = "1"
                DISPLAY BY NAME stock_r.*

        END INPUT

        -- Stock Results Display Array
        DISPLAY ARRAY arr_stock_results TO sa_stock.*

            BEFORE ROW
                LET curr_stock_idx = arr_curr()
                IF curr_stock_idx > 0 AND curr_stock_idx <= arr_stock_results.getLength()
                THEN
                    CALL load_transaction_details(
                        arr_stock_results[curr_stock_idx].stock_code)
                END IF

            ON ACTION view_detail
                ATTRIBUTES(TEXT = "View Details", IMAGE = "info", DEFAULTVIEW = NO)
                IF curr_stock_idx > 0 THEN
                    CALL view_stock_detail(
                        arr_stock_results[curr_stock_idx].stock_code)
                END IF

        END DISPLAY

        -- Transaction Details Display Array
        DISPLAY ARRAY arr_trans_detail TO sa_trans.*
            -- Display only, no actions
        END DISPLAY

        -- Dialog Actions
        BEFORE DIALOG
            -- Load all active stock items initially
            CALL search_stock_items()

        ON ACTION search ATTRIBUTES(TEXT = "Search", IMAGE = "zoom")
            CALL search_stock_items()

        ON ACTION refresh ATTRIBUTES(TEXT = "Refresh", IMAGE = "refresh")
            CALL search_stock_items()

        ON ACTION print_report
            ATTRIBUTES(TEXT = "Print Report", IMAGE = "print", DEFAULTVIEW = NO)
            CALL print_stock_report()

        ON ACTION export_csv
            ATTRIBUTES(TEXT = "Export CSV", IMAGE = "save", DEFAULTVIEW = NO)
            CALL export_to_csv()

        ON ACTION stock_analysis
            ATTRIBUTES(TEXT = "Stock Analysis", IMAGE = "piechart", DEFAULTVIEW = NO)
            CALL show_stock_analysis()

        ON ACTION quit ATTRIBUTES(TEXT = "Quit", IMAGE = "quit")
            EXIT DIALOG

    END DIALOG
END FUNCTION

-- ==============================================================
-- Lookup Category for Search
-- ==============================================================
FUNCTION lookup_category_for_search()
    DEFINE selected_cat_id INTEGER

    LET selected_cat_id = st122_cat_lkup.load_lookup()

    IF selected_cat_id IS NOT NULL THEN
        LET stock_r.category_id = selected_cat_id
        DISPLAY BY NAME stock_r.category_id
    END IF
END FUNCTION

-- ==============================================================
-- Search Stock Items based on criteria
-- ==============================================================
FUNCTION search_stock_items()
    DEFINE where_clause STRING
    DEFINE sql_stmt STRING
    DEFINE idx INTEGER

    -- Build WHERE clause based on search criteria
    LET where_clause = "1=1"

    IF stock_r.stock_code IS NOT NULL AND stock_r.stock_code != "" THEN
        LET where_clause =
            where_clause || " AND stock_code LIKE '" || stock_r.stock_code || "%'"
    END IF

    IF stock_r.description IS NOT NULL AND stock_r.description != "" THEN
        LET where_clause =
            where_clause
            || " AND description LIKE '%"
            || stock_r.description
            || "%'"
    END IF

    -- Execute search
    CALL arr_stock_results.clear()
    LET idx = 0
    LET total_value = 0
    LET total_profit = 0

    LET sql_stmt =
        "SELECT stock_code, description, barcode, category_id, cost, "
        || "selling_price, stock_on_hand, total_purch, total_sales, status "
        || "FROM st01_mast WHERE "
        || where_clause
        || " ORDER BY stock_code"

    DECLARE c_search_curs CURSOR FROM sql_stmt

    FOREACH c_search_curs INTO arr_stock_results[idx + 1].*

        ---- Calculate profit margin
        --IF arr_stock_results[idx + 1].unit_cost > 0 THEN
        --    LET arr_stock_results[idx + 1].profit_margin =
        --        ((arr_stock_results[idx + 1].sell_price
        --            - arr_stock_results[idx + 1].unit_cost)
        --            / arr_stock_results[idx + 1].unit_cost)
        --        * 100
        --ELSE
        --    LET arr_stock_results[idx + 1].profit_margin = 0
        --END IF

        -- Accumulate totals
        LET total_value =
            total_value
            + (arr_stock_results[idx + 1].unit_cost
                * arr_stock_results[idx + 1].stock_on_hand)
        LET total_profit =
            total_profit
            + ((arr_stock_results[idx + 1].sell_price
                - arr_stock_results[idx + 1].unit_cost)
                * arr_stock_results[idx + 1].stock_on_hand)

        LET idx = idx + 1
    END FOREACH

    FREE c_search_curs

    IF idx = 0 THEN
        CALL utils_globals.msg_no_record()
        CALL arr_trans_detail.clear()
    ELSE
        MESSAGE idx || " stock item(s) found. Total Value: " || total_value
        -- Load transactions for first item
        IF arr_stock_results.getLength() > 0 THEN
            CALL load_transaction_details(arr_stock_results[1].stock_code)
        END IF
    END IF
END FUNCTION

-- ==============================================================
-- Load Transaction Details for a stock item
-- ==============================================================
FUNCTION load_transaction_details(p_stock_code STRING)
    DEFINE idx INTEGER

    CALL arr_trans_detail.clear()
    LET idx = 0

    DECLARE c_trans_curs CURSOR FOR
        SELECT *
        FROM st30_trans
        WHERE stock_code = p_stock_code
        ORDER BY trans_date DESC, id DESC

    FOREACH c_trans_curs INTO arr_trans_detail[idx + 1].*
        LET idx = idx + 1
    END FOREACH

    FREE c_trans_curs
END FUNCTION

-- ==============================================================
-- View Stock Detail - Show full item information
-- ==============================================================
FUNCTION view_stock_detail(p_stock_code STRING)
    DEFINE rec_detail RECORD LIKE st01_mast.*
    DEFINE profit_margin DECIMAL(10, 2)
    DEFINE stock_value DECIMAL(15, 2)
    DEFINE detail_msg STRING

    -- Load stock details
    SELECT * 
        INTO rec_detail.*
        FROM st01_mast
        WHERE stock_code = p_stock_code

    IF SQLCA.SQLCODE <> 0 THEN
        CALL utils_globals.show_error("Stock item not found.")
        RETURN
    END IF

    -- Calculate metrics
    IF rec_detail.unit_cost > 0 THEN
        LET profit_margin =
            ((rec_detail.sell_price - rec_detail.unit_cost) / rec_detail.unit_cost) * 100
    ELSE
        LET profit_margin = 0
    END IF

    LET stock_value = rec_detail.unit_cost * rec_detail.stock_on_hand

    -- Build detail message
    LET detail_msg = "STOCK ITEM DETAILS\n\n"
    LET detail_msg = detail_msg || "Stock Code: " || rec_detail.stock_code || "\n"
    LET detail_msg = detail_msg || "Description: " || rec_detail.description || "\n"
    LET detail_msg =
        detail_msg
        || "Barcode: "
        || NVL(rec_detail.barcode, "N/A")
        || "\n"
    LET detail_msg = detail_msg || "Category ID: " || rec_detail.category_id || "\n"
    LET detail_msg = detail_msg || "Batch Control: "
    IF rec_detail.batch_control = 1 THEN
        LET detail_msg = detail_msg || "Yes\n"
    ELSE
        LET detail_msg = detail_msg || "No\n"
    END IF
    LET detail_msg = detail_msg || "\n--- PRICING ---\n"
    LET detail_msg = detail_msg || "Cost Price: " || rec_detail.unit_cost || "\n"
    LET detail_msg = detail_msg || "Selling Price: " || rec_detail.sell_price || "\n"
    LET detail_msg =
        detail_msg || "Profit Margin: " || profit_margin USING "<<<.<<" || "%\n"
    LET detail_msg = detail_msg || "\n--- STOCK LEVELS ---\n"
    LET detail_msg = detail_msg || "Stock On Hand: " || rec_detail.stock_on_hand || "\n"
    LET detail_msg = detail_msg || "Stock Value: " || stock_value || "\n"
    LET detail_msg = detail_msg || "Total Purchases: " || rec_detail.total_purch || "\n"
    LET detail_msg = detail_msg || "Total Sales: " || rec_detail.total_sales || "\n"
    LET detail_msg = detail_msg || "\n--- STATUS ---\n"
    LET detail_msg = detail_msg || "Status: "
    CASE rec_detail.status
        WHEN "1"
            LET detail_msg = detail_msg || "Active\n"
        WHEN "0"
            LET detail_msg = detail_msg || "Inactive\n"
        OTHERWISE
            LET detail_msg = detail_msg || rec_detail.status || "\n"
    END CASE

    CALL utils_globals.show_info(detail_msg)
END FUNCTION

-- ==============================================================
-- Print Stock Report
-- ==============================================================
FUNCTION print_stock_report()
    DEFINE report_content STRING
    DEFINE i INTEGER

    IF arr_stock_results.getLength() = 0 THEN
        CALL utils_globals.show_info("No stock items to report.")
        RETURN
    END IF

    LET report_content = "STOCK ENQUIRY REPORT\n"
    LET report_content = report_content || "Generated: " || CURRENT || "\n\n"
    LET report_content =
        report_content
        || "Total Items: "
        || arr_stock_results.getLength()
        || "\n"
    LET report_content = report_content || "Total Value: " || total_value || "\n"
    LET report_content = report_content || "Total Profit: " || total_profit || "\n\n"

    LET report_content = report_content || "Stock Code | Description | Cost | Selling | "
    LET report_content = report_content || "On Hand | Margin %\n"
    LET report_content =
        report_content
        || "--------------------------------------------------------------\n"

    FOR i = 1 TO arr_stock_results.getLength()
        LET report_content =
            report_content
            || arr_stock_results[i].stock_code
            || " | "
            || arr_stock_results[i].description
            || " | "
            || arr_stock_results[i].unit_cost
            || " | "
            || arr_stock_results[i].sell_price
            || " | "
            || arr_stock_results[i].stock_on_hand
            || " | "
            || "\n"
    END FOR

    CALL utils_globals.show_info(report_content)
    MESSAGE "Report generated for " || arr_stock_results.getLength() || " items."
END FUNCTION

-- ==============================================================
-- Export to CSV
-- ==============================================================
FUNCTION export_to_csv()
    IF arr_stock_results.getLength() = 0 THEN
        CALL utils_globals.show_info("No stock items to export.")
        RETURN
    END IF

    -- In a real implementation, this would write to a file
    CALL utils_globals.show_info(
        "Export feature: Would export "
        || arr_stock_results.getLength()
        || " items to CSV file.")
END FUNCTION

-- ==============================================================
-- Show Stock Analysis
-- ==============================================================
FUNCTION show_stock_analysis()
    DEFINE analysis_msg STRING
    DEFINE low_stock_count INTEGER
    DEFINE high_value_count INTEGER
    DEFINE avg_margin DECIMAL(10, 2)
    DEFINE i INTEGER

    IF arr_stock_results.getLength() = 0 THEN
        CALL utils_globals.show_info("No stock items to analyze.")
        RETURN
    END IF

    LET low_stock_count = 0
    LET high_value_count = 0
    LET avg_margin = 0

    FOR i = 1 TO arr_stock_results.getLength()
        -- Count low stock items (less than 10)
        IF arr_stock_results[i].stock_on_hand < 10 THEN
            LET low_stock_count = low_stock_count + 1
        END IF

        -- Count high value items (cost > 100)
        IF arr_stock_results[i].unit_cost > 100 THEN
            LET high_value_count = high_value_count + 1
        END IF

    END FOR

    LET avg_margin = avg_margin / arr_stock_results.getLength()

    LET analysis_msg = "STOCK ANALYSIS\n\n"
    LET analysis_msg =
        analysis_msg || "Total Items Analyzed: " || arr_stock_results.getLength() || "\n"
    LET analysis_msg = analysis_msg || "Low Stock Items (< 10): " || low_stock_count || "\n"
    LET analysis_msg =
        analysis_msg || "High Value Items (> 100): " || high_value_count || "\n"
    LET analysis_msg =
        analysis_msg || "Average Margin: " || avg_margin USING "<<<.<<" || "%\n"
    LET analysis_msg = analysis_msg || "Total Stock Value: " || total_value || "\n"
    LET analysis_msg = analysis_msg || "Potential Profit: " || total_profit || "\n"

    CALL utils_globals.show_info(analysis_msg)
END FUNCTION