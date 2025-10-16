-- ==============================================================
-- File     : utils_types.4gl
-- Purpose  : Utils - Application shared types
-- Module   : Utils
-- Author   : Bongani Dlamini
-- Version  : Genero BDL 3.20.10
-- Description: Common type definitions for the application
-- ==============================================================

SCHEMA demoapp_db

-- Common status type
TYPE status_t RECORD
    code SMALLINT,
    description STRING
END RECORD

-- Common lookup result type
TYPE lookup_result_t RECORD
    code STRING,
    name STRING,
    found BOOLEAN
END RECORD

-- Common date range type
TYPE date_range_t RECORD
    from_date DATE,
    to_date DATE
END RECORD
