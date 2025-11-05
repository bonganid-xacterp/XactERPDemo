-- ==============================================================
-- Program   : cl101_mast.4gl
-- Purpose   : Creditors Master maintenance
-- Module    : Creditors (cl)
-- Number    : 101
-- Author    : Bongani Dlamini
-- Version   : Genero ver 3.20.10
-- ==============================================================

IMPORT ui

IMPORT FGL utils_globals
IMPORT FGL cl121_lkup -- Creditor lookup module

IMPORT FGL pu131_invoice

SCHEMA demoapp_db

-- ==============================================================
-- Record definitions
-- ==============================================================
TYPE creditor_t RECORD LIKE cl01_mast.*
DEFINE rec_cred creditor_t

-- Transaction array (linked to detail grid in form)
DEFINE arr_cred_trans DYNAMIC ARRAY OF RECORD LIKE cl30_trans.*

DEFINE arr_codes DYNAMIC ARRAY OF STRING
DEFINE curr_idx INTEGER
DEFINE is_edit_mode SMALLINT

-- ==============================================================
-- MAIN (Standalone Mode)
-- ==============================================================
MAIN
    -- If standalone mode, open window
    -- Initialize application (sets g_standalone_mode automatically)
    IF NOT utils_globals.initialize_application() THEN
        DISPLAY "Initialization failed."
        EXIT PROGRAM 1
    END IF
    OPTIONS INPUT WRAP
    OPEN WINDOW w_cl101 WITH FORM "cl101_mast" ATTRIBUTES(STYLE = "normal")

    -- Run the module (works in both standalone and MDI modes)
    CALL init_cl_module()

    -- If standalone mode, close window on exit
    CLOSE WINDOW w_cl101

END MAIN

-- ==============================================================
-- Lookup popup
-- ==============================================================
FUNCTION query_creditor() RETURNS INTEGER
    DEFINE selected_code INTEGER
    LET selected_code = cl121_lkup.fetch_cred_list()
    RETURN selected_code
END FUNCTION

-- ==============================================================
-- DIALOG Controller
-- ==============================================================
FUNCTION init_cl_module()

    -- Start in read-only mode
    LET is_edit_mode = FALSE

    -- Initialize
    CALL arr_codes.clear()
    LET curr_idx = 0
    INITIALIZE rec_cred.* TO NULL

    -- Load all creditors on startup
    CALL load_all_creditors()

    DISPLAY ARRAY arr_cred_trans TO arr_cred_lines.*
        --BEFORE DISPLAY

        ON ACTION Find
            CALL query_creditors()
            LET is_edit_mode = FALSE

        ON ACTION New
            CALL new_creditor()
            LET is_edit_mode = FALSE

        ON ACTION row_select
            CALL open_transaction_window(arr_cred_trans[arr_curr()].doc_no)

        ON ACTION List
            CALL load_all_creditors()
            LET is_edit_mode = FALSE

        ON ACTION Documents
            CALL show_transactions()

        ON ACTION Edit
            IF rec_cred.acc_code IS NULL OR rec_cred.acc_code = 0 THEN
                CALL utils_globals.show_info("No record selected to edit.")
            ELSE
                LET is_edit_mode = TRUE
                CALL edit_creditor()
            END IF

        ON ACTION Delete
            CALL delete_creditor()
            LET is_edit_mode = FALSE

        ON ACTION Previous
            CALL move_record(-1)
            DISPLAY ARRAY arr_cred_trans TO arr_cred_trans.*
                BEFORE DISPLAY
                    EXIT DISPLAY
            END DISPLAY

        ON ACTION Next
            CALL move_record(1)
            
            DISPLAY ARRAY arr_cred_trans TO arr_cred_trans.*
                BEFORE DISPLAY
                    EXIT DISPLAY
            END DISPLAY

        ON ACTION Exit
            EXIT DISPLAY
    END DISPLAY
    -- CALL load_menu()

END FUNCTION

    -- ===========================================
    -- MAIN MENU (top-level)
    -- ===========================================
FUNCTION load_menu()

    MENU "Creditors Menu"

        COMMAND "Find"
            CALL query_creditors()
            LET is_edit_mode = FALSE

        COMMAND "New"
            CALL new_creditor()
            LET is_edit_mode = FALSE

        COMMAND "List All"
            CALL load_all_creditors()
            LET is_edit_mode = FALSE

        COMMAND "Edit"
            IF rec_cred.acc_code IS NULL OR rec_cred.acc_code = 0 THEN
                CALL utils_globals.show_info("No record selected to edit.")
            ELSE
                LET is_edit_mode = TRUE
                CALL edit_creditor()
            END IF

        COMMAND "Delete"
            CALL delete_creditor()
            LET is_edit_mode = FALSE

        COMMAND "Add Order"
           MESSAGE "new order"

        COMMAND "Transactions"
            IF rec_cred.acc_code IS NULL OR rec_cred.acc_code = 0 THEN
                CALL utils_globals.show_info("No creditor selected.")
            ELSE
                --CALL load_and_display_transactions(rec_cred.acc_code)
            END IF

        COMMAND "Previous"
            CALL move_record(-1)
        COMMAND "Next"
            CALL move_record(1)

        COMMAND "Exit"
            EXIT MENU

    END MENU

END FUNCTION 

-- ==============================================================
-- Load All Creditors for Navigation
-- ==============================================================
FUNCTION load_all_creditors()
    DEFINE ok SMALLINT

    LET ok = select_creditors("1=1")

    IF ok THEN
        MESSAGE (SFMT("Loaded %1 creditor(s)", arr_codes.getLength()))
    ELSE
        CALL utils_globals.show_info("No creditors found")
        INITIALIZE rec_cred.* TO NULL
        DISPLAY BY NAME rec_cred.*
    END IF
END FUNCTION

-- ==============================================================
-- Query using Lookup Window
-- ==============================================================
FUNCTION query_creditors()
    DEFINE selected_code INTEGER
    DEFINE found_idx INTEGER
    DEFINE i INTEGER
    DEFINE array_size INTEGER

    LET selected_code = query_creditor()

    IF selected_code IS NOT NULL THEN
        LET array_size = arr_codes.getLength()

        -- Find the selected record in the existing array
        LET found_idx = 0

        IF array_size > 0 THEN
            FOR i = 1 TO array_size
                IF arr_codes[i] = selected_code THEN
                    LET found_idx = i
                    EXIT FOR
                END IF
            END FOR
        END IF

        -- If found in array, just move to it
        IF found_idx > 0 THEN
            LET curr_idx = found_idx
            CALL load_creditor(selected_code)
        ELSE
            -- If not in array, reload all creditors to include it
            CALL load_all_creditors()

            -- Find it again in the refreshed array
            LET array_size = arr_codes.getLength()
            IF array_size > 0 THEN
                FOR i = 1 TO array_size
                    IF arr_codes[i] = selected_code THEN
                        LET curr_idx = i
                        EXIT FOR
                    END IF
                END FOR
            END IF

            CALL load_creditor(selected_code)
        END IF
    END IF
END FUNCTION

-- ==============================================================
-- SELECT Creditors into Array
-- ==============================================================
FUNCTION select_creditors(where_clause STRING) RETURNS SMALLINT
    DEFINE code INTEGER
    DEFINE idx INTEGER
    DEFINE sql_stmt STRING

    CALL arr_codes.clear()
    LET idx = 0

    LET sql_stmt = "SELECT acc_code FROM cl01_mast"

    IF where_clause IS NOT NULL AND where_clause != "" THEN
        LET sql_stmt = sql_stmt || " WHERE " || where_clause
    END IF

    LET sql_stmt = sql_stmt || " ORDER BY acc_code"

    PREPARE stmt_select FROM sql_stmt
    DECLARE c_curs CURSOR FOR stmt_select

    FOREACH c_curs INTO code
        LET idx = idx + 1
        LET arr_codes[idx] = code
    END FOREACH

    CLOSE c_curs
    FREE c_curs
    FREE stmt_select

    IF arr_codes.getLength() == 0 THEN
        CALL utils_globals.msg_no_record()
        LET curr_idx = 0
        RETURN FALSE
    END IF

    LET curr_idx = 1
    CALL load_creditor(arr_codes[curr_idx])
    RETURN TRUE

END FUNCTION

-- ==============================================================
-- Load Single Creditor
-- ==============================================================
FUNCTION load_creditor(p_code INTEGER)

    SELECT * INTO rec_cred.* FROM cl01_mast WHERE acc_code = p_code

    IF SQLCA.SQLCODE = 0 THEN
        DISPLAY BY NAME rec_cred.*

        -- Load transactions automatically
        CALL load_transactions(rec_cred.acc_code)
    ELSE
        INITIALIZE rec_cred.* TO NULL
        DISPLAY BY NAME rec_cred.*
        CALL arr_cred_trans.clear()
    END IF

END FUNCTION

-- ==============================================================
-- Navigation
-- ==============================================================
FUNCTION move_record(dir SMALLINT)
    DEFINE new_idx INTEGER

    -- ? Check if array is empty
    IF arr_codes.getLength() == 0 THEN
        CALL utils_globals.show_info("No records to navigate.")
        RETURN
    END IF

    -- Calculate new index based on direction
    -- arr_codes DYNAMIC ARRAY OF STRING, current_index INTEGER, direction SMALLINT
    LET new_idx = utils_globals.navigate_records(arr_codes, curr_idx, dir)
    DISPLAY "Next rec : " || new_idx
    LET curr_idx = new_idx
    DISPLAY " New local idx : " || curr_idx
    -- ? FIXED: Load using the account code from array, not the index
    CALL load_creditor(arr_codes[curr_idx])

END FUNCTION

-- ==============================================================
-- Create a New Creditor
-- ==============================================================
FUNCTION new_creditor()
    DEFINE dup_found SMALLINT
    DEFINE new_acc_code INTEGER
    DEFINE next_num INTEGER
    DEFINE next_full STRING
    DEFINE i INTEGER
    DEFINE array_size INTEGER

    -- Clear record and defaults
    INITIALIZE rec_cred.* TO NULL
    LET rec_cred.status = 'active'
    LET rec_cred.balance = 0.00

    -- Auto-generate next supplier code
    CALL utils_globals.get_next_number("cl01_mast", "CL")
        RETURNING next_num, next_full

    LET rec_cred.acc_code = next_num
    LET rec_cred.full_acc_code = next_full

    MESSAGE (SFMT("Creating new creditor: %1", rec_cred.full_acc_code))

    DIALOG ATTRIBUTES(UNBUFFERED)
        INPUT BY NAME rec_cred.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "new_creditor")

            AFTER FIELD supp_name
                IF rec_cred.supp_name IS NULL OR rec_cred.supp_name = "" THEN
                    CALL utils_globals.show_error("Supplier Name is required.")
                    NEXT FIELD supp_name
                END IF

            AFTER FIELD email
                IF rec_cred.email IS NOT NULL AND rec_cred.email != "" THEN
                    IF NOT utils_globals.is_valid_email(rec_cred.email) THEN
                        CALL utils_globals.show_error("Invalid email format.")
                        NEXT FIELD email
                    END IF
                END IF

            ON ACTION save ATTRIBUTES(TEXT = "Save", IMAGE = "filesave")
                LET dup_found =
                    check_creditor_unique(
                        rec_cred.acc_code,
                        rec_cred.supp_name,
                        rec_cred.phone,
                        rec_cred.email)

                IF dup_found = 0 THEN
                    CALL save_creditor()
                    LET new_acc_code = rec_cred.acc_code
                    CALL utils_globals.show_info("Creditor saved successfully.")
                    EXIT DIALOG
                ELSE
                    CALL utils_globals.show_error("Duplicate creditor found.")
                END IF

            ON ACTION cancel ATTRIBUTES(TEXT = "Cancel", IMAGE = "cancel")
                LET new_acc_code = NULL
                CALL utils_globals.show_info("Creation cancelled.")
                EXIT DIALOG
        END INPUT
    END DIALOG

    -- Reload all creditors after save or cancel
    IF new_acc_code IS NOT NULL THEN
        -- Reload all creditors
        CALL load_all_creditors()

        -- Find the new record in the array (with bounds check)
        LET array_size = arr_codes.getLength()
        IF array_size > 0 THEN
            FOR i = 1 TO array_size
                IF arr_codes[i] = new_acc_code THEN
                    LET curr_idx = i
                    EXIT FOR
                END IF
            END FOR
        END IF

        CALL load_creditor(new_acc_code)
    ELSE
        -- Cancel - stay on current record if valid
        LET array_size = arr_codes.getLength()

        IF array_size > 0 AND curr_idx >= 1 AND curr_idx <= array_size THEN
            CALL load_creditor(arr_codes[curr_idx])
        ELSE
            -- No valid record to display
            LET curr_idx = 0
            INITIALIZE rec_cred.* TO NULL
            DISPLAY BY NAME rec_cred.*
        END IF
    END IF
END FUNCTION

-- ==============================================================
-- Save / Update
-- ==============================================================
FUNCTION save_creditor()
    DEFINE exists INTEGER

    SELECT COUNT(*)
        INTO exists
        FROM cl01_mast
        WHERE acc_code = rec_cred.acc_code

    IF exists = 0 THEN
        -- Insert new record
        INSERT INTO cl01_mast VALUES rec_cred.*
        CALL utils_globals.msg_saved()
    ELSE
        -- Update existing record
        UPDATE cl01_mast
            SET cl01_mast.* = rec_cred.*
            WHERE acc_code = rec_cred.acc_code
        CALL utils_globals.msg_updated()
    END IF

    -- Reload to confirm
    CALL load_creditor(rec_cred.acc_code)
END FUNCTION

-- ==============================================================
-- Edit Creditor
-- ==============================================================
FUNCTION edit_creditor()
    DEFINE selected_doc STRING

    DIALOG ATTRIBUTES(UNBUFFERED)

        INPUT BY NAME rec_cred.*
            ATTRIBUTES(WITHOUT DEFAULTS, NAME = "creditors")

            ON ACTION save ATTRIBUTES(TEXT = "Update", IMAGE = "filesave")
                CALL save_creditor()
                EXIT DIALOG

            ON ACTION cancel
                CALL load_creditor(rec_cred.acc_code)
                EXIT DIALOG

            AFTER FIELD supp_name
                IF rec_cred.supp_name IS NULL OR rec_cred.supp_name = "" THEN
                    CALL utils_globals.show_error("Supplier Name is required.")
                    NEXT FIELD supp_name
                END IF

        END INPUT

    ---- Make transaction grid interactive
    --DISPLAY ARRAY arr_cred_trans TO arr_cred_trans.*
    --
    --     ON ACTION view_doc ATTRIBUTES(TEXT = "View Document", IMAGE = "view")
    --         LET arr_cred_trans_idx = ARR_CURR()
    --         IF arr_cred_trans_idx > 0 AND arr_cred_trans_idx <= arr_cred_trans.getLength() THEN
    --             LET selected_doc = arr_cred_trans[arr_cred_trans_idx].doc_no
    --             CALL view_transaction_detail(selected_doc)
    --         END IF
    --
    --     ON ACTION refresh ATTRIBUTES(TEXT = "Refresh", IMAGE = "refresh")
    --         CALL load_creditor_transactions(rec_cred.acc_code)
    --
    -- END DISPLAY

    END DIALOG
END FUNCTION

-- ==============================================================
-- Delete Creditor
-- ==============================================================
FUNCTION delete_creditor()
    DEFINE ok SMALLINT
    DEFINE deleted_code INTEGER
    DEFINE array_size INTEGER

    -- If no record is loaded, skip
    IF rec_cred.acc_code IS NULL OR rec_cred.acc_code = 0 THEN
        CALL utils_globals.show_info('No creditor selected for deletion.')
        RETURN
    END IF

    -- Confirm delete
    LET ok =
        utils_globals.show_confirm(
            "Delete this creditor: " || rec_cred.supp_name || "?",
            "Confirm Delete")

    IF NOT ok THEN
        CALL utils_globals.show_info("Delete cancelled.")
        RETURN
    END IF

    LET deleted_code = rec_cred.acc_code
    DELETE FROM cl01_mast WHERE acc_code = deleted_code
    CALL utils_globals.msg_deleted()

    -- Reload all creditors after delete
    CALL load_all_creditors()

    -- Try to stay near the deleted position (with bounds check)
    LET array_size = arr_codes.getLength()

    IF array_size > 0 THEN
        -- If we deleted the last record, move back one
        IF curr_idx > array_size THEN
            LET curr_idx = array_size
        END IF

        -- Validate curr_idx
        IF curr_idx < 1 THEN
            LET curr_idx = 1
        END IF

        -- Load the record at current position
        CALL load_creditor(arr_codes[curr_idx])
    ELSE
        -- No records left
        LET curr_idx = 0
        INITIALIZE rec_cred.* TO NULL
        DISPLAY BY NAME rec_cred.*
    END IF

END FUNCTION

-- ==============================================================
-- Check creditor uniqueness
-- ==============================================================
FUNCTION check_creditor_unique(
    p_acc_code INTEGER, p_supp_name STRING, p_phone STRING, p_email STRING)
    RETURNS SMALLINT

    DEFINE dup_count INTEGER
    DEFINE exists SMALLINT

    LET exists = 0

    -- Check for duplicate supplier code
    SELECT COUNT(*) INTO dup_count FROM cl01_mast WHERE acc_code = p_acc_code

    IF dup_count > 0 THEN
        CALL utils_globals.show_error("Duplicate supplier code already exists.")
        LET exists = 1
        RETURN exists
    END IF

    -- Check for duplicate name (if provided)
    IF p_supp_name IS NOT NULL AND p_supp_name != "" THEN
        SELECT COUNT(*)
            INTO dup_count
            FROM cl01_mast
            WHERE supp_name = p_supp_name

        IF dup_count > 0 THEN
            CALL utils_globals.show_error("Supplier name already exists.")
            LET exists = 1
            RETURN exists
        END IF
    END IF

    -- Check for duplicate phone (if provided)
    IF p_phone IS NOT NULL AND p_phone != "" THEN
        SELECT COUNT(*) INTO dup_count FROM cl01_mast WHERE phone = p_phone

        IF dup_count > 0 THEN
            CALL utils_globals.show_error("Phone number already exists.")
            LET exists = 1
            RETURN exists
        END IF
    END IF

    -- Check for duplicate email (if provided)
    IF p_email IS NOT NULL AND p_email != "" THEN
        SELECT COUNT(*) INTO dup_count FROM cl01_mast WHERE email = p_email

        IF dup_count > 0 THEN
            CALL utils_globals.show_error("Email already exists.")
            LET exists = 1
            RETURN exists
        END IF
    END IF

    RETURN exists
END FUNCTION


-- ==============================================================
-- Load Debtor Transactions
-- ==============================================================
FUNCTION load_transactions(p_acc_code INTEGER)
    DEFINE idx INTEGER

    CALL arr_cred_trans.clear()
   

    DECLARE c_trans CURSOR FOR
        SELECT *
            FROM dl30_trans
            WHERE acc_code = p_acc_code
            ORDER BY trans_date DESC, doc_no DESC
        LET idx = 1
    FOREACH c_trans
        INTO arr_cred_trans[idx].id,
            arr_cred_trans[idx].acc_code,
            arr_cred_trans[idx].trans_date,
            arr_cred_trans[idx].doc_no,
            arr_cred_trans[idx].doc_type,
            arr_cred_trans[idx].gross_tot,
            arr_cred_trans[idx].vat,
            arr_cred_trans[idx].disc,
            arr_cred_trans[idx].net_tot
        LET idx = idx + 1
    END FOREACH

    CLOSE c_trans
    FREE c_trans
END FUNCTION

-- ==============================================================
-- Interactive Transactions Grid
-- ==============================================================
FUNCTION show_transactions()
    DEFINE l_row INTEGER

    IF arr_cred_trans.getLength() = 0 THEN
        CALL utils_globals.show_info("No transactions found for this debtor.")
        RETURN
    END IF

    DIALOG
        DISPLAY ARRAY arr_cred_trans TO arr_cred_trans.*
            ATTRIBUTES(DOUBLECLICK = row_select)

            ON ACTION row_select
                CALL open_transaction_window(arr_cred_trans[l_row].doc_no)

            ON ACTION open ATTRIBUTES(TEXT = "Open", IMAGE = "zoom")
                CALL open_transaction_window(arr_cred_trans[l_row].doc_no)

            ON ACTION close
                EXIT DIALOG
        END DISPLAY
    END DIALOG
END FUNCTION

-- ==============================================================
-- Open Related Document (inactive case block)
-- ==============================================================
FUNCTION open_transaction_window(p_doc_no INTEGER)
    DEFINE l_type STRING

    SELECT doc_type INTO l_type FROM dl30_trans WHERE doc_no = p_doc_no

    IF SQLCA.SQLCODE != 0 THEN
        CALL utils_globals.show_error("Document not found.")
        RETURN
    END IF

    DISPLAY "Loaded the doc no for doc : " || p_doc_no

    CASE l_type
            WHEN "ORD"
                --CALL pu130_order.
            WHEN "INV"
                --CALL pu131_invoice.load_invoice_via_cred(p_doc_no)
        OTHERWISE
            CALL utils_globals.show_info("Unknown document type: " || l_type)
    END CASE
END FUNCTION

