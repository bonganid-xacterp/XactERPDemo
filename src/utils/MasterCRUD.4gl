-- ==============================================================
-- Generic Master CRUD Operations
-- Purpose: Eliminate duplication across master maintenance modules
-- ==============================================================

IMPORT ui
IMPORT FGL utils_globals

-- Generic master record type (PUBLIC for shared usage)
PUBLIC TYPE MasterRecord RECORD
    tableName STRING,
    keyField STRING,
    nameField STRING,
    phoneField STRING,
    emailField STRING
END RECORD

DEFINE dlg ui.Dialog

-- Generic status function
PUBLIC FUNCTION getStatusDescription(code SMALLINT) RETURNS STRING
    CASE code
        WHEN 1 RETURN "Active"
        WHEN 0 RETURN "Inactive" 
        WHEN -1 RETURN "Archived"
        OTHERWISE RETURN "Unknown"
    END CASE
END FUNCTION

-- Generic navigation
PUBLIC FUNCTION navigateRecords(codes DYNAMIC ARRAY OF STRING, currentIndex INTEGER, direction SMALLINT) RETURNS INTEGER
    DEFINE newIndex INTEGER
    
    CASE direction
        WHEN -2 -- First
            LET newIndex = 1
        WHEN -1 -- Previous
            IF currentIndex > 1 THEN
                LET newIndex = currentIndex - 1
            ELSE
                CALL utils_globals.msg_start_of_list()
                RETURN currentIndex
            END IF
        WHEN 1 -- Next
            IF currentIndex < codes.getLength() THEN
                LET newIndex = currentIndex + 1
            ELSE
                CALL utils_globals.msg_end_of_list()
                RETURN currentIndex
            END IF
        WHEN 2 -- Last
            LET newIndex = codes.getLength()
    END CASE
    
    RETURN newIndex
END FUNCTION

-- Generic record selection
PUBLIC FUNCTION selectRecords(master MasterRecord, whereClause STRING) RETURNS DYNAMIC ARRAY OF STRING
    DEFINE codes DYNAMIC ARRAY OF STRING
    DEFINE code STRING
    DEFINE idx INTEGER
    DEFINE sql STRING
    
    CALL codes.clear()
    LET idx = 0
    LET sql = "SELECT " || master.keyField || " FROM " || master.tableName || 
              " WHERE " || whereClause || " ORDER BY " || master.keyField
    
    TRY
        DECLARE c_select CURSOR FROM sql
        FOREACH c_select INTO code
            LET idx = idx + 1
            LET codes[idx] = code
        END FOREACH
        FREE c_select
    CATCH
        CALL utils_globals.show_error("Query failed: " || SQLCA.SQLERRM)
    END TRY
    
    IF codes.getLength() = 0 THEN
        CALL utils_globals.msg_no_record()
    END IF
    
    RETURN codes
END FUNCTION

-- Generic uniqueness check
PUBLIC FUNCTION checkUniqueness(master MasterRecord, acc_code STRING, name STRING, phone STRING, email STRING) RETURNS BOOLEAN
    DEFINE count INTEGER
    
    -- Check account code
    IF NOT utils_globals.is_empty(acc_code) THEN
        LET count = getFieldCount(master.tableName, master.keyField, acc_code)
        IF count > 0 THEN
            CALL utils_globals.show_error("Duplicate account code already exists.")
            RETURN FALSE
        END IF
    END IF
    
    -- Check name
    IF NOT utils_globals.is_empty(name) AND NOT utils_globals.is_empty(master.nameField) THEN
        LET count = getFieldCount(master.tableName, master.nameField, name)
        IF count > 0 THEN
            CALL utils_globals.show_error("Name already exists.")
            RETURN FALSE
        END IF
    END IF
    
    -- Check phone
    IF NOT utils_globals.is_empty(phone) AND NOT utils_globals.is_empty(master.phoneField) THEN
        LET count = getFieldCount(master.tableName, master.phoneField, phone)
        IF count > 0 THEN
            CALL utils_globals.show_error("Phone number already exists.")
            RETURN FALSE
        END IF
    END IF
    
    -- Check email
    IF NOT utils_globals.is_empty(email) AND NOT utils_globals.is_empty(master.emailField) THEN
        LET count = getFieldCount(master.tableName, master.emailField, email)
        IF count > 0 THEN
            CALL utils_globals.show_error("Email already exists.")
            RETURN FALSE
        END IF
    END IF
    
    RETURN TRUE
END FUNCTION

-- Generic delete confirmation
PUBLIC FUNCTION confirmDelete(entityName STRING, recordName STRING) RETURNS BOOLEAN
    DEFINE message STRING
    LET message = "Delete this " || entityName || ": " || recordName || "?"
    RETURN utils_globals.show_confirm(message, "Confirm Delete")
END FUNCTION

-- Generic field validation
PUBLIC FUNCTION validateMasterFields(acc_code STRING, name STRING, email STRING, phone STRING) RETURNS BOOLEAN
    -- Required field validation
    IF utils_globals.is_empty(acc_code) THEN
        CALL utils_globals.show_error("Account Code is required.")
        RETURN FALSE
    END IF
    
    IF utils_globals.is_empty(name) THEN
        CALL utils_globals.show_error("Name is required.")
        RETURN FALSE
    END IF
    
    -- Format validation
    IF NOT utils_globals.is_empty(email) AND NOT utils_globals.is_valid_email(email) THEN
        CALL utils_globals.show_error("Invalid email format.")
        RETURN FALSE
    END IF
    
    IF NOT utils_globals.is_empty(phone) AND NOT utils_globals.is_valid_phone(phone) THEN
        CALL utils_globals.show_error("Invalid phone format.")
        RETURN FALSE
    END IF
    
    RETURN TRUE
END FUNCTION

-- Generic edit mode management
PUBLIC FUNCTION set_edit_mode(p_dlg ui.Dialog, p_edit_mode SMALLINT)
    DEFINE l_message STRING

    -- Safety check
    IF p_dlg IS NULL THEN
        RETURN
    END IF

    -- Enable/disable actions depending on mode
    CALL p_dlg.setActionActive("save", p_edit_mode)
    CALL p_dlg.setActionActive("update", p_edit_mode)
    CALL p_dlg.setActionActive("cancel", p_edit_mode)

    CALL p_dlg.setActionActive("edit", NOT p_edit_mode)
    CALL p_dlg.setActionActive("new", NOT p_edit_mode)
    CALL p_dlg.setActionActive("delete", NOT p_edit_mode)
    CALL p_dlg.setActionActive("find", NOT p_edit_mode)

    -- Optional user feedback
    IF p_edit_mode THEN
        LET l_message = "Edit mode enabled. Make your changes and click Save."
    ELSE
        LET l_message = "View mode. Click Edit or New to modify records."
    END IF

    CALL show_info( l_message)
    
END FUNCTION

-- Helper function for count queries
PRIVATE FUNCTION getFieldCount(tableName STRING, fieldName STRING, value STRING) RETURNS INTEGER
    DEFINE count INTEGER
    DEFINE sql STRING
    
    -- Skip check if fieldName is empty
    IF utils_globals.is_empty(fieldName) THEN
        RETURN 0
    END IF
    
    LET sql = "SELECT COUNT(*) FROM " || tableName || " WHERE " || fieldName || " = ?"
    
    TRY
        PREPARE stmt_count FROM sql
        EXECUTE stmt_count USING value INTO count
        RETURN count
    CATCH
        RETURN 0
    END TRY
END FUNCTION