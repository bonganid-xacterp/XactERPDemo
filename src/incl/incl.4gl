-- ==============================================================
-- File     : incl.4gl
-- Purpose  : Includes - Centralized shared functions
-- Module   : Includes
-- Author   : Bongani Dlamini
-- Version  : Genero BDL 3.20.10
-- Description: Common include definitions and constants
-- ==============================================================

SCHEMA demoapp_db

-- Application constants
CONSTANT APP_NAME = "XactERP Demo"
CONSTANT APP_VERSION = "3.20.10"
CONSTANT DB_SCHEMA = "demoapp_db"

-- Status constants
CONSTANT STATUS_ACTIVE = 1
CONSTANT STATUS_INACTIVE = 0

-- Common validation function
FUNCTION validate_required(value STRING, field_name STRING) RETURNS BOOLEAN
    IF value IS NULL OR LENGTH(value.trim()) = 0 THEN
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION
