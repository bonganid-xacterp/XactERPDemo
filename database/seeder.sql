-- ==============================================================
--  XACT ERP DEMO - Sample Data Seeder (v1.3)
--  Modules  : Debtors, Creditors, Warehouses, Tags, Bins, Stock Categories, Stock
--  Author   : Bongani Dlamini
--  Date     : 2025-10-17
--  Purpose  : Generate demo master data with relationships
-- ==============================================================

BEGIN;
SET CONSTRAINTS ALL DEFERRED;

-- ==============================================================
-- Reset Sequences
-- ==============================================================
ALTER SEQUENCE IF EXISTS dl01_mast_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS cl01_mast_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS wh01_mast_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS wh02_tag_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS wb01_mast_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS st02_cat_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS st01_mast_id_seq RESTART WITH 1;

-- ==============================================================
-- 1. Debtors (dl01_mast)
-- ==============================================================
TRUNCATE TABLE dl01_mast RESTART IDENTITY CASCADE;

DO
$$
DECLARE i INTEGER;
BEGIN
    FOR i IN 1..20 LOOP
        INSERT INTO dl01_mast (acc_code, cust_name, phone, email, address1, address2, address3, cr_limit, balance, status)
        VALUES (
            LPAD(i::TEXT, 4, '0') || '-DL',
            FORMAT('Debtor %s Ltd', i),
            FORMAT('0821234%03s', i),
            FORMAT('debtor%s@example.com', i),
            FORMAT('%s Main Street', i),
            'Durban',
            'KZN',
            (10000 + i * 500),
            (i * 100),
            'ACTIVE'
        );
    END LOOP;
END;
$$;

-- ==============================================================
-- 2. Creditors (cl01_mast)
-- ==============================================================
TRUNCATE TABLE cl01_mast RESTART IDENTITY CASCADE;

DO
$$
DECLARE i INTEGER;
BEGIN
    FOR i IN 1..20 LOOP
        INSERT INTO cl01_mast (acc_code, supp_name, phone, email, address1, address2, address3, balance, status)
        VALUES (
            LPAD(i::TEXT, 4, '0') || '-CL',
            FORMAT('Creditor %s Supplies', i),
            FORMAT('0835678%03s', i),
            FORMAT('creditor%s@example.com', i),
            FORMAT('%s Industrial Park', i),
            'Johannesburg',
            'GP',
            (i * 200),
            'ACTIVE'
        );
    END LOOP;
END;
$$;

-- ==============================================================
-- 3. Warehouses (wh01_mast)
-- ==============================================================
TRUNCATE TABLE wh01_mast RESTART IDENTITY CASCADE;

DO
$$
DECLARE i INTEGER;
BEGIN
    FOR i IN 1..5 LOOP
        INSERT INTO wh01_mast (wh_code, wh_name, location, status)
        VALUES (
            LPAD(i::TEXT, 3, '0') || '-WH',
            FORMAT('Warehouse %s', i),
            FORMAT('Region %s - Industrial Zone', i),
            'ACTIVE'
        );
    END LOOP;
END;
$$;

-- ==============================================================
-- 4. Warehouse Tags (wh02_tag)
-- Each warehouse has 3 tags
-- ==============================================================
TRUNCATE TABLE wh02_tag RESTART IDENTITY CASCADE;

DO
$$
DECLARE 
    w INTEGER;
    t INTEGER;
BEGIN
    FOR w IN 1..5 LOOP
        FOR t IN 1..3 LOOP
            INSERT INTO wh02_tag (tag_code, tag_name, wh_code, status)
            VALUES (
                FORMAT('WH%s-T%s', LPAD(w::TEXT, 3, '0'), LPAD(t::TEXT, 2, '0')),
                FORMAT('Tag %s-%s', w, t),
                LPAD(w::TEXT, 3, '0') || '-WH',
                'ACTIVE'
            );
        END LOOP;
    END LOOP;
END;
$$;

-- ==============================================================
-- 5. Bins (wb01_mast)
-- Each Bin belongs to a Warehouse
-- ==============================================================
TRUNCATE TABLE wb01_mast RESTART IDENTITY CASCADE;

DO
$$
DECLARE 
    i INTEGER;
    wh_ref INTEGER;
BEGIN
    FOR i IN 1..20 LOOP
        wh_ref := ((i - 1) % 5) + 1;  -- rotate across 5 warehouses
        INSERT INTO wb01_mast (bin_code, bin_name, wh_code, capacity, status)
        VALUES (
            LPAD(i::TEXT, 3, '0') || '-BIN',
            FORMAT('Bin %s', i),
            LPAD(wh_ref::TEXT, 3, '0') || '-WH',
            (100 + i * 10),
            'ACTIVE'
        );
    END LOOP;
END;
$$;

-- ==============================================================
-- 6. Stock Categories (st02_cat)
-- ==============================================================
TRUNCATE TABLE st02_cat RESTART IDENTITY CASCADE;

DO
$$
DECLARE i INTEGER;
BEGIN
    FOR i IN 1..10 LOOP
        INSERT INTO st02_cat (cat_code, cat_name, description, status)
        VALUES (
            LPAD(i::TEXT, 3, '0') || '-CAT',
            FORMAT('Category %s', i),
            FORMAT('Generic category description %s', i),
            'ACTIVE'
        );
    END LOOP;
END;
$$;

-- ==============================================================
-- 7. Stock Items (st01_mast)
-- Belongs to Warehouse + Bin + Category
-- ==============================================================
TRUNCATE TABLE st01_mast RESTART IDENTITY CASCADE;

DO
$$
DECLARE 
    i INTEGER;
    cat_ref INTEGER;
    wh_ref INTEGER;
    bin_ref INTEGER;
BEGIN
    FOR i IN 1..20 LOOP
        cat_ref := ((i - 1) % 10) + 1;  -- assign 10 categories
        wh_ref  := ((i - 1) % 5) + 1;   -- assign 5 warehouses
        bin_ref := i;                   -- match bin 1..20 (linked by wh_ref)

        INSERT INTO st01_mast (
            item_code,
            item_name,
            cat_code,
            wh_code,
            bin_code,
            unit_cost,
            sell_price,
            qty_on_hand,
            reorder_level,
            status
        )
        VALUES (
            LPAD(i::TEXT, 5, '0') || '-ST',
            FORMAT('Stock Item %s', i),
            LPAD(cat_ref::TEXT, 3, '0') || '-CAT',
            LPAD(wh_ref::TEXT, 3, '0') || '-WH',
            LPAD(bin_ref::TEXT, 3, '0') || '-BIN',
            (50 + i * 2.5),
            (75 + i * 4.0),
            (50 + i * 5),
            (10 + i),
            'ACTIVE'
        );
    END LOOP;
END;
$$;

COMMIT;
RAISE NOTICE '? Demo Data Seeded for Debtors, Creditors, Warehouses, Tags, Bins, Categories, and Stock!';
