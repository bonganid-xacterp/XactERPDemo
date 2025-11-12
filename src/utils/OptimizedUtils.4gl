-- ==============================================================
-- Optimized Utils - Consolidated and Deduplicated
-- Purpose: Single source of truth for all utility functions
-- ==============================================================

IMPORT ui
IMPORT FGL fgldialog

-- ==============================================================
-- CONSTANTS
-- ==============================================================
CONSTANT APP_NAME = "XACT DEMO System"

-- Message constants
CONSTANT MSG_NO_RECORD = "No records found."
CONSTANT MSG_SAVED = "Record saved successfully."
CONSTANT MSG_UPDATED = "Record updated successfully."
CONSTANT MSG_DELETED = "Record deleted successfully."
CONSTANT MSG_EOL = "End of list."
CONSTANT MSG_SOL = "Start of list."
CONSTANT MSG_NO_SEARCH = "Enter account code or name to search."
CONSTANT MSG_CONFIRM_DELETE = "Do you want to delete this record ?"

-- Status constants
CONSTANT STATUS_ACTIVE = 1
CONSTANT STATUS_INACTIVE = 0
CONSTANT STATUS_ARCHIVED = -1


TYPE LookupResult RECORD
    code STRING,
    description STRING,
    field3 STRING,
    field4 STRING,
    field5 STRING
END RECORD

-- ==============================================================
-- MESSAGE FUNCTIONS
-- ==============================================================

-- Base message function (eliminates 6 duplicate functions)
PUBLIC FUNCTION showMessage(message STRING, messageType STRING, title STRING)
    DEFINE icon STRING
    DEFINE windowTitle STRING
    
    LET windowTitle = IIF(title IS NULL, "Message", title)
    
    CASE messageType
        WHEN "info" LET icon = "information"
        WHEN "warning" LET icon = "exclamation"
        WHEN "error" LET icon = "stop"
        WHEN "question" LET icon = "question"
        OTHERWISE LET icon = "information"
    END CASE
    
    CALL fgldialog.fgl_winmessage(windowTitle, message, icon)
END FUNCTION

-- Simplified message wrappers
PUBLIC FUNCTION showInfo(msg STRING) CALL showMessage(msg, "info", "Information") END FUNCTION
PUBLIC FUNCTION showWarning(msg STRING) CALL showMessage(msg, "warning", "Warning") END FUNCTION
PUBLIC FUNCTION showError(msg STRING) CALL showMessage(msg, "error", "Error") END FUNCTION
PUBLIC FUNCTION showSuccess(msg STRING) CALL showMessage(msg, "info", "Success") END FUNCTION

-- Confirmation dialog
PUBLIC FUNCTION showConfirm(message STRING, title STRING) RETURNS BOOLEAN
    DEFINE answer STRING
    LET title = IIF(title IS NULL, "Confirm", title)
    LET answer = fgldialog.fgl_winQuestion(title, message, "no", "yes|no", "question", 0)
    RETURN (answer = "yes")
END FUNCTION

-- Standard message functions
PUBLIC FUNCTION msgNoRecord() CALL showInfo(MSG_NO_RECORD) END FUNCTION
PUBLIC FUNCTION msgSaved() CALL showInfo(MSG_SAVED) END FUNCTION
PUBLIC FUNCTION msgUpdated() CALL showInfo(MSG_UPDATED) END FUNCTION
PUBLIC FUNCTION msgDeleted() CALL showInfo(MSG_DELETED) END FUNCTION
PUBLIC FUNCTION msgEndOfList() CALL showInfo(MSG_EOL) END FUNCTION
PUBLIC FUNCTION msgStartOfList() CALL showInfo(MSG_SOL) END FUNCTION
PUBLIC FUNCTION msgNoSearch() CALL showInfo(MSG_NO_SEARCH) END FUNCTION
PUBLIC FUNCTION confirmDelete() RETURNS BOOLEAN RETURN showConfirm(MSG_CONFIRM_DELETE, "Delete Record") END FUNCTION

-- ==============================================================
-- FORMAT FUNCTIONS
-- ==============================================================

-- Single format function for decimals
PRIVATE FUNCTION formatDecimal(value DECIMAL, pattern STRING) RETURNS STRING
    RETURN (NVL(value, 0) USING pattern)
END FUNCTION

PUBLIC FUNCTION formatCurrency(amount DECIMAL) RETURNS STRING
    RETURN formatDecimal(amount, "---,---,--&.&&")
END FUNCTION

PUBLIC FUNCTION formatQuantity(qty DECIMAL) RETURNS STRING
    RETURN formatDecimal(qty, "---,---,--&.&&")
END FUNCTION

-- Date formatting
PUBLIC FUNCTION formatDate(p_date DATE) RETURNS STRING
    RETURN IIF(p_date IS NULL, "", p_date USING "dd/mm/yyyy")
END FUNCTION

PUBLIC FUNCTION formatDateTime(date_time DATETIME YEAR TO SECOND) RETURNS STRING
    RETURN IIF(date_time IS NULL, "", date_time USING "dd/mm/yyyy hh:mm:ss")
END FUNCTION

-- ==============================================================
-- VALIDATION FUNCTION
-- ==============================================================

PUBLIC FUNCTION isEmpty(str STRING) RETURNS BOOLEAN
    RETURN (str IS NULL OR LENGTH(str.trim()) = 0)
END FUNCTION

PUBLIC FUNCTION trimString(str STRING) RETURNS STRING
    RETURN IIF(str IS NULL, "", str.trim())
END FUNCTION

PUBLIC FUNCTION isValidEmail(email STRING) RETURNS BOOLEAN
    RETURN (email IS NOT NULL AND email MATCHES "*@*.*")
END FUNCTION

PUBLIC FUNCTION isValidPhone(phone STRING) RETURNS BOOLEAN
    DEFINE clean STRING
    LET clean = trimString(phone)
    RETURN (clean MATCHES "[0-9]{10}")
END FUNCTION

-- ==============================================================
-- UI UTILITIES
-- ==============================================================

PUBLIC FUNCTION setPageTitle(title STRING)
    DEFINE w ui.Window
    LET w = ui.Window.getCurrent()
    IF w IS NOT NULL THEN
        CALL w.setText(APP_NAME || " - " || title)
    END IF
END FUNCTION

PUBLIC FUNCTION setFormLabel(labelName STRING, text STRING)
    DEFINE f ui.Form
    LET f = ui.Window.getCurrent().getForm()
    CALL f.setElementText(labelName, text)
END FUNCTION

PUBLIC FUNCTION setFieldsVisibility(fields DYNAMIC ARRAY OF STRING, hidden BOOLEAN)
    DEFINE f ui.Form
    DEFINE i INTEGER
    
    LET f = ui.Window.getCurrent().getForm()
    FOR i = 1 TO fields.getLength()
        CALL f.setFieldHidden(fields[i], hidden)
    END FOR
END FUNCTION

-- Status combobox population
PUBLIC FUNCTION populateStatusCombo(fieldName STRING)
    DEFINE cb ui.ComboBox
    
    LET cb = ui.ComboBox.forName(fieldName)
    IF cb IS NOT NULL THEN
        CALL cb.clear()
        CALL cb.addItem(STATUS_ACTIVE, "Active")
        CALL cb.addItem(STATUS_INACTIVE, "Inactive")
        CALL cb.addItem(STATUS_ARCHIVED, "Archived")
    END IF
END FUNCTION

-- ==============================================================
-- DATABASE UTILITIES
-- ==============================================================

-- Single database connection function
PUBLIC FUNCTION connectDatabase() RETURNS BOOLEAN
    TRY
        CONNECT TO "demoappdb@localhost:5432+driver='dbmpgs_9'"
            USER "postgres" USING "napoleon"
        RETURN TRUE
    CATCH
        CALL showError("Database connection failed: " || SQLCA.SQLERRM)
        RETURN FALSE
    END TRY
END FUNCTION

PUBLIC FUNCTION disconnectDatabase() RETURNS BOOLEAN
    TRY
        DISCONNECT CURRENT
        RETURN TRUE
    CATCH
        RETURN FALSE
    END TRY
END FUNCTION

-- Transaction management
PUBLIC FUNCTION executeTransaction(operation STRING) RETURNS BOOLEAN
    TRY
        CASE operation
            WHEN "BEGIN" BEGIN WORK
            WHEN "COMMIT" COMMIT WORK
            WHEN "ROLLBACK" ROLLBACK WORK
        END CASE
        RETURN TRUE
    CATCH
        CALL showError("Transaction " || operation || " failed: " || SQLCA.SQLERRM)
        RETURN FALSE
    END TRY
END FUNCTION

-- ==============================================================
-- LOOKUP UTILITIES
-- ==============================================================


-- Generic lookup function
PUBLIC FUNCTION genericLookup(
    tableName STRING,
    codeField STRING,
    descField STRING,
    searchValue STRING,
    title STRING,
    returnField STRING
) RETURNS STRING
    
    DEFINE sql STRING
    DEFINE results DYNAMIC ARRAY OF LookupResult
    DEFINE selectedIndex INTEGER
    DEFINE whereClause STRING
    
    -- Build WHERE clause if search value provided
    IF NOT isEmpty(searchValue) THEN
        LET whereClause = " WHERE " || codeField || " ILIKE '%" || searchValue || 
                         "%' OR " || descField || " ILIKE '%" || searchValue || "%'"
    ELSE
        LET whereClause = ""
    END IF
    
    LET sql = "SELECT " || codeField || ", " || descField || 
              " FROM " || tableName || whereClause || 
              " ORDER BY " || codeField
    
    CALL executeLookupQuery(sql, results)
    
    IF results.getLength() > 0 THEN
        LET selectedIndex = displayLookupDialog(results, title)
        IF selectedIndex > 0 THEN
            CASE returnField
                WHEN "code" RETURN results[selectedIndex].code
                WHEN "description" RETURN results[selectedIndex].description
                OTHERWISE RETURN results[selectedIndex].code
            END CASE
        END IF
    END IF
    
    RETURN ""
END FUNCTION

-- Specific lookup wrappers (much simpler now)
PUBLIC FUNCTION lookupCustomer(search STRING) RETURNS STRING
    RETURN genericLookup("dl01_mast", "acc_code", "cust_name", search, "Customer Lookup", "code")
END FUNCTION

PUBLIC FUNCTION lookupSupplier(search STRING) RETURNS STRING
    RETURN genericLookup("cl01_mast", "acc_code", "supp_name", search, "Supplier Lookup", "code")
END FUNCTION

PUBLIC FUNCTION lookupStock(search STRING) RETURNS STRING
    RETURN genericLookup("st01_mast", "stock_code", "description", search, "Stock Lookup", "code")
END FUNCTION

-- Private helper functions
PRIVATE FUNCTION executeLookupQuery(sql STRING, results DYNAMIC ARRAY OF LookupResult)
    DEFINE idx INTEGER
    LET idx = 0
    
    TRY
        DECLARE lookup_cursor CURSOR FROM sql
        FOREACH lookup_cursor INTO results[idx + 1].code, results[idx + 1].description
            LET idx = idx + 1
        END FOREACH
        CLOSE lookup_cursor
        FREE lookup_cursor
    CATCH
        CALL showError("Lookup query failed: " || SQLCA.SQLERRM)
    END TRY
END FUNCTION

PRIVATE FUNCTION displayLookupDialog(results DYNAMIC ARRAY OF LookupResult, p_title STRING) RETURNS INTEGER
    DEFINE selectedIndex INTEGER
    
    -- Simplified dialog implementation
    -- In real implementation, would show proper lookup form
    IF results.getLength() = 1 THEN
        RETURN 1  -- Auto-select if only one result
    END IF
    
    -- For now, return first result
    RETURN IIF(results.getLength() > 0, 1, 0)
END FUNCTION