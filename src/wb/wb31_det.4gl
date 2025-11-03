-- ==============================================================
-- Program   : wb31_det.4gl
-- Purpose   : Warehouse Bin Transfer Detail maintenance
-- Module    : Warehouse Bin (wb)
-- Number    : 31
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- Description: Detail lines for bin-to-bin transfers
--              Manages individual stock items being transferred
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

SCHEMA demoapp_db

-- Transfer detail record structure
TYPE bin_detail_t RECORD
    trans_no STRING, -- Transfer transaction number (links to header)
    line_no INTEGER, -- Line sequence number
    stock_code STRING, -- Stock item code
    description STRING, -- Stock item description
    from_bin STRING, -- Source bin code
    to_bin STRING, -- Destination bin code
    qty DECIMAL(10, 2), -- Quantity to transfer
    unit STRING, -- Unit of measure
    cost DECIMAL(10, 2), -- Unit cost
    total DECIMAL(10, 2) -- Line total (qty * cost)
END RECORD

DEFINE arr_details DYNAMIC ARRAY OF bin_detail_t
DEFINE current_trans_no STRING
DEFINE is_edit_mode SMALLINT

--MAIN
--    IF NOT utils_globals.initialize_application() THEN
--        EXIT PROGRAM 1
--    END IF
--
--    -- Get transaction number from command line or prompt
--    LET current_trans_no = ARG_VAL(1)
--    IF utils_globals.is_empty(current_trans_no) THEN
--        PROMPT "Enter Transaction Number:" FOR current_trans_no
--        IF utils_globals.is_empty(current_trans_no) THEN
--            EXIT PROGRAM
--        END IF
--    END IF
--      OPTIONS INPUT WRAP
--    OPEN WINDOW w_wb31 WITH FORM "wb31_det" ATTRIBUTES(STYLE = "main")
--    CALL init_module()
--    CLOSE WINDOW w_wb31
--END MAIN

FUNCTION init_wb31_module()
    LET is_edit_mode = FALSE

    DIALOG ATTRIBUTES(UNBUFFERED)
        DISPLAY ARRAY arr_details
            TO details.*
            ATTRIBUTES(COUNT = arr_details.getLength())

            BEFORE DISPLAY
                CALL load_details()

            ON ACTION new ATTRIBUTES(TEXT = "New Line", IMAGE = "new")
                CALL new_detail_line()

            ON ACTION edit ATTRIBUTES(TEXT = "Edit", IMAGE = "edit")
                LET is_edit_mode = TRUE
                CALL utils_globals.show_info("Edit mode enabled.")

            ON ACTION save ATTRIBUTES(TEXT = "Save All", IMAGE = "filesave")
                IF is_edit_mode THEN
                    CALL save_all_details()
                    LET is_edit_mode = FALSE
                END IF

            ON ACTION DELETE ATTRIBUTES(TEXT = "Delete Line", IMAGE = "delete")
                CALL delete_detail_line()

            ON ACTION calculate ATTRIBUTES(TEXT = "Calculate", IMAGE = "calc")
                CALL calculate_totals()

            ON ACTION QUIT ATTRIBUTES(TEXT = "Quit", IMAGE = "quit")
                EXIT DIALOG
        END DISPLAY

        INPUT ARRAY arr_details
            FROM details.*
            ATTRIBUTES(COUNT = arr_details.getLength(), MAXCOUNT = 1000)

            BEFORE ROW
                IF NOT is_edit_mode THEN
                    CALL utils_globals.show_info(
                        "Click Edit to modify details.")
                END IF

            AFTER FIELD qty, cost
                CALL calculate_line_total(arr_curr())

            ON ACTION add_line ATTRIBUTES(TEXT = "Add Line", IMAGE = "add")
                IF is_edit_mode THEN
                    CALL add_new_line()
                END IF

            ON ACTION delete_line
                ATTRIBUTES(TEXT = "Delete Line", IMAGE = "delete")
                IF is_edit_mode THEN
                    CALL delete_current_line()
                END IF
        END INPUT
    END DIALOG
END FUNCTION

FUNCTION load_details()
    DEFINE idx INTEGER

    CALL arr_details.clear()
    LET idx = 0

    DECLARE c_details CURSOR FOR
        SELECT trans_no,
            line_no,
            stock_code,
            description,
            from_bin,
            to_bin,
            qty,
            unit,
            cost,
            total
            FROM wb31_det
            WHERE trans_no = current_trans_no
            ORDER BY line_no

    FOREACH c_details INTO arr_details[idx + 1].*
        LET idx = idx + 1
    END FOREACH
    FREE c_details

    IF arr_details.getLength() = 0 THEN
        CALL utils_globals.msg_no_record()
        -- Add one empty line
        LET arr_details[1].trans_no = current_trans_no
        LET arr_details[1].line_no = 1
        LET arr_details[1].qty = 0.00
        LET arr_details[1].cost = 0.00
        LET arr_details[1].total = 0.00
    END IF
END FUNCTION

FUNCTION new_detail_line()
    DEFINE new_detail bin_detail_t
    DEFINE new_line INTEGER

    INITIALIZE new_detail.* TO NULL

    LET new_line = get_next_line_number()
    LET new_detail.trans_no = current_trans_no
    LET new_detail.line_no = new_line
    LET new_detail.qty = 0.00
    LET new_detail.cost = 0.00
    LET new_detail.total = 0.00

    PROMPT "Stock Code:" FOR new_detail.stock_code
    PROMPT "Description:" FOR new_detail.description
    PROMPT "From Bin:" FOR new_detail.from_bin
    PROMPT "To Bin:" FOR new_detail.to_bin
    PROMPT "Quantity:" FOR new_detail.qty
    PROMPT "Unit:" FOR new_detail.unit
    PROMPT "Cost:" FOR new_detail.cost

    IF validate_detail_line(new_detail.*) THEN
        LET new_detail.total = new_detail.qty * new_detail.cost
        CALL add_detail_to_array(new_detail.*)
    END IF
END FUNCTION

FUNCTION add_detail_to_array(detail bin_detail_t)
    DEFINE new_idx INTEGER

    LET new_idx = arr_details.getLength() + 1
    LET arr_details[new_idx].* = detail.*

    CALL utils_globals.show_success("Detail line added.")
END FUNCTION

FUNCTION delete_detail_line()
    DEFINE current_row INTEGER
    DEFINE confirmed BOOLEAN

    LET current_row = arr_curr()
    IF current_row <= 0 OR current_row > arr_details.getLength() THEN
        CALL utils_globals.show_info("No line selected.")
        RETURN
    END IF

    LET confirmed =
        utils_globals.show_confirm(
            "Delete line " || arr_details[current_row].line_no || "?",
            "Confirm Delete")

    IF confirmed THEN
        -- Delete from database if exists
        DELETE FROM wb31_det
            WHERE trans_no = current_trans_no
                AND line_no = arr_details[current_row].line_no

        -- Remove from array
        CALL arr_details.deleteElement(current_row)

        -- Renumber lines
        CALL renumber_lines()

        CALL utils_globals.msg_deleted()
    END IF
END FUNCTION

FUNCTION delete_current_line()
    DEFINE current_row INTEGER

    LET current_row = arr_curr()
    IF current_row > 0 AND current_row <= arr_details.getLength() THEN
        CALL arr_details.deleteElement(current_row)
        CALL renumber_lines()
    END IF
END FUNCTION

FUNCTION add_new_line()
    DEFINE new_idx INTEGER
    DEFINE new_line INTEGER

    LET new_idx = arr_details.getLength() + 1
    LET new_line = get_next_line_number()

    LET arr_details[new_idx].trans_no = current_trans_no
    LET arr_details[new_idx].line_no = new_line
    LET arr_details[new_idx].qty = 0.00
    LET arr_details[new_idx].cost = 0.00
    LET arr_details[new_idx].total = 0.00
END FUNCTION

FUNCTION save_all_details()
    DEFINE i INTEGER
    DEFINE success_count INTEGER

    LET success_count = 0

    TRY
        BEGIN WORK

        -- Delete existing details
        DELETE FROM wb31_det WHERE trans_no = current_trans_no

        -- Insert all current details
        FOR i = 1 TO arr_details.getLength()
            IF NOT utils_globals.is_empty(arr_details[i].stock_code) THEN
                INSERT INTO wb31_det(
                    trans_no,
                    line_no,
                    stock_code,
                    description,
                    from_bin,
                    to_bin,
                    qty,
                    unit,
                    cost,
                    total)
                    VALUES(arr_details[i].trans_no,
                        arr_details[i].line_no,
                        arr_details[i].stock_code,
                        arr_details[i].description,
                        arr_details[i].from_bin,
                        arr_details[i].to_bin,
                        arr_details[i].qty,
                        arr_details[i].unit,
                        arr_details[i].cost,
                        arr_details[i].total)
                LET success_count = success_count + 1
            END IF
        END FOR

        COMMIT WORK
        CALL utils_globals.show_success(
            "Saved " || success_count || " detail lines.")

    CATCH
        ROLLBACK WORK
        CALL utils_globals.show_error(
            "Failed to save details: " || SQLCA.SQLERRM)
    END TRY
END FUNCTION

FUNCTION calculate_line_total(row_num INTEGER)
    IF row_num > 0 AND row_num <= arr_details.getLength() THEN
        LET arr_details[row_num].total =
            arr_details[row_num].qty * arr_details[row_num].cost
    END IF
END FUNCTION

FUNCTION calculate_totals()
    DEFINE i INTEGER
    DEFINE total_qty DECIMAL(10, 2)
    DEFINE total_value DECIMAL(10, 2)

    LET total_qty = 0.00
    LET total_value = 0.00

    FOR i = 1 TO arr_details.getLength()
        CALL calculate_line_total(i)
        LET total_qty = total_qty + arr_details[i].qty
        LET total_value = total_value + arr_details[i].total
    END FOR

    CALL utils_globals.show_info(
        "Total Qty: " || total_qty || ", Total Value: " || total_value)
END FUNCTION

FUNCTION get_next_line_number() RETURNS INTEGER
    DEFINE max_line INTEGER
    DEFINE i INTEGER

    LET max_line = 0
    FOR i = 1 TO arr_details.getLength()
        IF arr_details[i].line_no > max_line THEN
            LET max_line = arr_details[i].line_no
        END IF
    END FOR

    RETURN max_line + 1
END FUNCTION

FUNCTION renumber_lines()
    DEFINE i INTEGER

    FOR i = 1 TO arr_details.getLength()
        LET arr_details[i].line_no = i
    END FOR
END FUNCTION

FUNCTION validate_detail_line(detail bin_detail_t) RETURNS BOOLEAN
    IF utils_globals.is_empty(detail.stock_code) THEN
        CALL utils_globals.show_error("Stock Code is required.")
        RETURN FALSE
    END IF

    IF utils_globals.is_empty(detail.from_bin) THEN
        CALL utils_globals.show_error("From Bin is required.")
        RETURN FALSE
    END IF

    IF utils_globals.is_empty(detail.to_bin) THEN
        CALL utils_globals.show_error("To Bin is required.")
        RETURN FALSE
    END IF

    IF detail.from_bin = detail.to_bin THEN
        CALL utils_globals.show_error("From and To bins cannot be the same.")
        RETURN FALSE
    END IF

    IF detail.qty <= 0 THEN
        CALL utils_globals.show_error("Quantity must be greater than zero.")
        RETURN FALSE
    END IF

    IF detail.cost < 0 THEN
        CALL utils_globals.show_error("Cost cannot be negative.")
        RETURN FALSE
    END IF

    RETURN TRUE
END FUNCTION
