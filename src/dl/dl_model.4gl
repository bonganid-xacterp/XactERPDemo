-- ==============================================================
-- File     : dl_model.4gl
-- Purpose  : Debtors (DL) - DP CRUD only (no UI)
-- Version  : Genero BDL 3.20.10
-- ==============================================================

IMPORT FGL utils_globals

SCHEMA demoapp_db

-- ---------- Model record (must match dl01_mast) ----------
TYPE t_debtor RECORD
    acc_code STRING,
    name STRING,
    phone STRING,
    email STRING,
    address1 STRING,
    address2 STRING,
    address3 STRING,
    cr_limit DECIMAL(10, 2),
    balance DECIMAL(10, 2),
    status SMALLINT
END RECORD

-- ==============================================================
-- READ: list all debtors (ordered by acc_code)
-- ==============================================================
FUNCTION dp_list_all() RETURNS DYNAMIC ARRAY OF t_debtor
    DEFINE arr DYNAMIC ARRAY OF t_debtor
    DEFINE rec t_debtor
    DEFINE idx INTEGER

    LET idx = 0

    DECLARE c CURSOR FOR
        SELECT acc_code,
            name,
            phone,
            email,
            address1,
            address2,
            address3,
            cr_limit,
            balance,
            status
            FROM dl01_mast
            ORDER BY acc_code

    FOREACH c INTO rec.*
        LET idx = idx + 1
        LET arr[idx].* = rec.*
    END FOREACH

    RETURN arr
END FUNCTION

-- ==============================================================
-- READ: get one debtor by code
-- Returns: (record, foundFlag)
-- ==============================================================
FUNCTION dp_get_by_code(p_code STRING)
    DEFINE rec t_debtor

    DECLARE c_debtor CURSOR FOR SELECT * FROM dl01_mast WHERE acc_code = p_code

    OPEN c_debtor
    FETCH c_debtor INTO rec.*
    CLOSE c_debtor

    IF SQLCA.SQLCODE = 0 THEN
        RETURN rec.*, 1
    ELSE
        RETURN rec.*, 0
    END IF
END FUNCTION

-- ==============================================================
-- CREATE: insert debtor
-- Returns TRUE/FALSE
-- ==============================================================
FUNCTION dp_insert(d t_debtor) RETURNS SMALLINT
    INSERT INTO dl01_mast(
        acc_code,
        name,
        phone,
        email,
        address1,
        address2,
        address3,
        cr_limit,
        balance,
        status)
        VALUES(d.acc_code,
            d.name,
            d.phone,
            d.email,
            d.address1,
            d.address2,
            d.address3,
            d.cr_limit,
            d.balance,
            d.status)

    IF SQLCA.SQLCODE != 0 THEN
        CALL utils_globals.show_error(
            "Insert failed (" || SQLCA.SQLCODE || "): " || SQLCA.SQLERRM)
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION

-- ==============================================================
-- UPDATE: full update by key (acc_code)
-- Returns TRUE/FALSE
-- ==============================================================
FUNCTION dp_update(d t_debtor) RETURNS SMALLINT
    UPDATE dl01_mast
        SET name = d.name,
            phone = d.phone,
            email = d.email,
            address1 = d.address1,
            address2 = d.address2,
            address3 = d.address3,
            cr_limit = d.cr_limit,
            balance = d.balance,
            status = d.status
        WHERE acc_code = d.acc_code

    IF SQLCA.SQLCODE != 0 THEN
        CALL utils_globals.show_error(
            "Update failed (" || SQLCA.SQLCODE || "): " || SQLCA.SQLERRM)
        RETURN FALSE
    END IF

    IF SQLCA.SQLERRD[3] = 0 THEN
        -- No row matched (wrong acc_code)
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION

-- ==============================================================
-- DELETE: by key (acc_code)
-- Returns TRUE/FALSE
-- ==============================================================
FUNCTION dp_delete(p_code STRING) RETURNS SMALLINT
    DELETE FROM dl01_mast WHERE acc_code = p_code

    IF SQLCA.SQLCODE != 0 THEN
        -- FK violation nice message (PostgreSQL 23503)
        IF SQLCA.sqlcode = "23503" THEN
            CALL utils_globals.show_error(
                "Delete blocked: debtor is referenced by other records.")
        ELSE
            CALL utils_globals.show_error(
                "Delete failed (" || SQLCA.SQLCODE || "): " || SQLCA.SQLERRM)
        END IF
        RETURN FALSE
    END IF

    IF SQLCA.SQLERRD[3] = 0 THEN
        -- No row deleted (not found)
        RETURN FALSE
    END IF
    RETURN TRUE
END FUNCTION
