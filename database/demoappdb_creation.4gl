#+ Database creation script for PostgreSQL 8.4 and higher
#+
#+ Note: This script is a helper script to create an empty database schema
#+       Adapt it to fit your needs

IMPORT FGL db_sample_values

MAIN
    DATABASE demoappdb

    CALL db_drop_constraints()
    CALL db_drop_tables()
    CALL db_create_tables()
    CALL db_add_indexes()
    CALL db_add_constraints()
    CALL init_sample_values()    
    CALL db_populate_tables()
END MAIN

#+ Create all tables in database.
FUNCTION db_create_tables()
    WHENEVER ERROR STOP

    EXECUTE IMMEDIATE "CREATE TABLE cl01_mast (
        id BIGSERIAL NOT NULL,
        supp_name VARCHAR(120) NOT NULL,
        phone VARCHAR(30),
        email VARCHAR(120),
        address1 VARCHAR(100),
        address2 VARCHAR(100),
        address3 VARCHAR(100),
        postal_code VARCHAR(10),
        vat_no VARCHAR(20),
        payment_terms VARCHAR(50),
        balance DECIMAL(15,2) NOT NULL,
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4),
        created_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE cl30_trans (
        id BIGSERIAL NOT NULL,
        supp_id BIGINT,
        trans_date DATE NOT NULL,
        doc_no VARCHAR(30),
        doc_type VARCHAR(20),
        gross_tot DECIMAL(15,2) NOT NULL,
        disc_tot DECIMAL(15,2) NOT NULL,
        vat_tot DECIMAL(15,2) NOT NULL,
        net_tot DECIMAL(15,2) NOT NULL,
        notes VARCHAR(200))"
    EXECUTE IMMEDIATE "CREATE TABLE dl01_mast (
        id BIGSERIAL NOT NULL,
        cust_name VARCHAR(120) NOT NULL,
        phone VARCHAR(30),
        email VARCHAR(120),
        address1 VARCHAR(100),
        address2 VARCHAR(100),
        address3 VARCHAR(100),
        postal_code VARCHAR(10),
        vat_no VARCHAR(20),
        payment_terms VARCHAR(50),
        balance DECIMAL(15,2) NOT NULL,
        cr_limit DECIMAL(15,2) NOT NULL,
        sales_ytd DECIMAL(15,2),
        cost_ytd DECIMAL(15,2),
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4),
        created_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE dl30_trans (
        id BIGSERIAL NOT NULL,
        cust_id BIGINT,
        doc_no VARCHAR(30),
        trans_date DATE NOT NULL,
        doc_type VARCHAR(20),
        gross_tot DECIMAL(15,2) NOT NULL,
        vat DECIMAL(15,2) NOT NULL,
        disc DECIMAL(15,2) NOT NULL,
        net_tot DECIMAL(15,2) NOT NULL,
        notes TEXT)"
    EXECUTE IMMEDIATE "CREATE TABLE gl01_acc (
        id BIGSERIAL NOT NULL,
        acc_code VARCHAR(30),
        acc_name VARCHAR(120) NOT NULL,
        acc_type VARCHAR(20) NOT NULL,
        is_parent BOOLEAN NOT NULL,
        parent_id BIGINT,
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4),
        created_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE gl30_jnls (
        id BIGSERIAL NOT NULL,
        jrn_no VARCHAR(30),
        trans_date DATE NOT NULL,
        ref_no VARCHAR(30),
        doc_type VARCHAR(20),
        doc_no VARCHAR(30),
        description VARCHAR(200),
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4),
        created_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE gl31_lines (
        id BIGSERIAL NOT NULL,
        jrn_id BIGINT NOT NULL,
        line_no INTEGER NOT NULL,
        acc_id BIGINT NOT NULL,
        debit DECIMAL(15,2) NOT NULL,
        credit DECIMAL(15,2) NOT NULL,
        notes VARCHAR(200))"
    EXECUTE IMMEDIATE "CREATE TABLE payt30_hdr (
        id BIGSERIAL NOT NULL,
        doc_no VARCHAR(30),
        party_type VARCHAR(10),
        party_id BIGINT,
        pay_type VARCHAR(20),
        trans_date DATE NOT NULL,
        method VARCHAR(30),
        bank_account VARCHAR(40),
        amount DECIMAL(15,2) NOT NULL,
        notes TEXT,
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        created_by BIGINT,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE payt31_trans_det (
        id BIGSERIAL NOT NULL,
        hdr_id BIGINT NOT NULL,
        doc_type VARCHAR(20),
        doc_no VARCHAR(30),
        alloc_amt DECIMAL(15,2) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE pu30_ord_det (
        id BIGSERIAL NOT NULL,
        hdr_id BIGINT NOT NULL,
        line_no INTEGER NOT NULL,
        stock_id BIGINT,
        item_name VARCHAR(200),
        uom VARCHAR(20),
        qnty DECIMAL(15,3) NOT NULL,
        unit_cost DECIMAL(15,4) NOT NULL,
        disc_pct DECIMAL(7,3) NOT NULL,
        disc_amt DECIMAL(15,2) NOT NULL,
        gross_amt DECIMAL(15,2) NOT NULL,
        vat_rate DECIMAL(7,3) NOT NULL,
        vat_amt DECIMAL(15,2) NOT NULL,
        net_amt DECIMAL(15,2) NOT NULL,
        line_total DECIMAL(15,2) NOT NULL,
        wh_id BIGINT,
        wb_id BIGINT,
        notes VARCHAR(200),
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        created_by BIGINT,
        updated_at DATETIME YEAR TO FRACTION(4),
        updated_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE pu30_ord_hdr (
        id BIGSERIAL NOT NULL,
        doc_no VARCHAR(30),
        ref_no VARCHAR(30),
        trans_date DATE NOT NULL,
        supp_id BIGINT,
        supp_name VARCHAR(100),
        supp_phone VARCHAR(20),
        supp_email VARCHAR(100),
        supp_address1 VARCHAR(100),
        supp_address2 VARCHAR(100),
        supp_address3 VARCHAR(100),
        supp_postal_code VARCHAR(10),
        supp_vat_no VARCHAR(20),
        supp_payment_terms VARCHAR(50),
        gross_tot DECIMAL(15,2) NOT NULL,
        disc_tot DECIMAL(15,2) NOT NULL,
        vat_tot DECIMAL(15,2) NOT NULL,
        net_tot DECIMAL(15,2) NOT NULL,
        notes VARCHAR(200),
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4),
        created_by BIGINT,
        updated_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE pu31_grn_det (
        id BIGSERIAL NOT NULL,
        hdr_id BIGINT NOT NULL,
        line_no INTEGER NOT NULL,
        stock_id BIGINT,
        item_name VARCHAR(200),
        uom VARCHAR(20),
        batch_id VARCHAR(40),
        expiry_date DATE,
        qnty DECIMAL(15,3) NOT NULL,
        unit_cost DECIMAL(15,4) NOT NULL,
        disc_pct DECIMAL(7,3) NOT NULL,
        disc_amt DECIMAL(15,2) NOT NULL,
        gross_amt DECIMAL(15,2) NOT NULL,
        vat_rate DECIMAL(7,3) NOT NULL,
        vat_amt DECIMAL(15,2) NOT NULL,
        net_amt DECIMAL(15,2) NOT NULL,
        line_total DECIMAL(15,2) NOT NULL,
        po_line_id BIGINT,
        wh_id BIGINT,
        wb_id BIGINT,
        notes VARCHAR(200),
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        created_by BIGINT,
        updated_at DATETIME YEAR TO FRACTION(4),
        updated_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE pu31_grn_hdr (
        id BIGSERIAL NOT NULL,
        doc_no VARCHAR(30),
        ref_doc_type VARCHAR(20),
        ref_doc_no VARCHAR(30),
        trans_date DATE NOT NULL,
        supp_id BIGINT,
        supp_name VARCHAR(100),
        supp_phone VARCHAR(20),
        supp_email VARCHAR(100),
        supp_address1 VARCHAR(100),
        supp_address2 VARCHAR(100),
        supp_address3 VARCHAR(100),
        supp_postal_code VARCHAR(10),
        supp_vat_no VARCHAR(20),
        supp_payment_terms VARCHAR(50),
        delivery_note_no VARCHAR(50),
        carrier_name VARCHAR(50),
        received_by BIGINT,
        gross_tot DECIMAL(15,2) NOT NULL,
        vat_tot DECIMAL(15,2) NOT NULL,
        net_tot DECIMAL(15,2) NOT NULL,
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4),
        created_by BIGINT,
        updated_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE pu32_inv_det (
        id BIGSERIAL NOT NULL,
        hdr_id BIGINT NOT NULL,
        line_no INTEGER NOT NULL,
        stock_id BIGINT,
        item_name VARCHAR(200),
        uom VARCHAR(20),
        batch_id VARCHAR(40),
        expiry_date DATE,
        qnty DECIMAL(15,3) NOT NULL,
        unit_cost DECIMAL(15,4) NOT NULL,
        disc_pct DECIMAL(7,3) NOT NULL,
        disc_amt DECIMAL(15,2) NOT NULL,
        gross_amt DECIMAL(15,2) NOT NULL,
        vat_rate DECIMAL(7,3) NOT NULL,
        vat_amt DECIMAL(15,2) NOT NULL,
        net_amt DECIMAL(15,2) NOT NULL,
        line_total DECIMAL(15,2) NOT NULL,
        wh_id BIGINT,
        wb_id BIGINT,
        notes VARCHAR(200),
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        created_by BIGINT,
        updated_at DATETIME YEAR TO FRACTION(4),
        updated_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE pu32_inv_hdr (
        id BIGSERIAL NOT NULL,
        doc_no VARCHAR(30),
        ref_doc_type VARCHAR(20),
        ref_doc_no VARCHAR(30),
        trans_date DATE NOT NULL,
        invoice_date DATE,
        due_date DATE,
        payment_method VARCHAR(30),
        supp_id BIGINT,
        supp_name VARCHAR(100),
        supp_phone VARCHAR(20),
        supp_email VARCHAR(100),
        supp_address1 VARCHAR(100),
        supp_address2 VARCHAR(100),
        supp_address3 VARCHAR(100),
        supp_postal_code VARCHAR(10),
        supp_vat_no VARCHAR(20),
        supp_payment_terms VARCHAR(50),
        supp_bank_name VARCHAR(60),
        supp_bank_account VARCHAR(40),
        supp_bank_branch VARCHAR(40),
        gross_tot DECIMAL(15,2) NOT NULL,
        disc_tot DECIMAL(15,2) NOT NULL,
        vat_tot DECIMAL(15,2) NOT NULL,
        net_tot DECIMAL(15,2) NOT NULL,
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4),
        created_by BIGINT,
        updated_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE sa30_quo_det (
        id BIGSERIAL NOT NULL,
        hdr_id BIGINT NOT NULL,
        line_no INTEGER NOT NULL,
        stock_id BIGINT,
        item_name VARCHAR(200),
        uom VARCHAR(20),
        qnty DECIMAL(15,3) NOT NULL,
        unit_price DECIMAL(15,4) NOT NULL,
        disc_pct DECIMAL(7,3) NOT NULL,
        disc_amt DECIMAL(15,2) NOT NULL,
        gross_amt DECIMAL(15,2) NOT NULL,
        vat_rate DECIMAL(7,3) NOT NULL,
        vat_amt DECIMAL(15,2) NOT NULL,
        net_amt DECIMAL(15,2) NOT NULL,
        line_total DECIMAL(15,2) NOT NULL,
        wh_id BIGINT,
        wb_id BIGINT,
        notes VARCHAR(200),
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        created_by BIGINT,
        updated_at DATETIME YEAR TO FRACTION(4),
        updated_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE sa30_quo_hdr (
        id BIGSERIAL NOT NULL,
        doc_no VARCHAR(30),
        ref_no VARCHAR(30),
        trans_date DATE NOT NULL,
        cust_id BIGINT,
        cust_name VARCHAR(100),
        cust_phone VARCHAR(20),
        cust_email VARCHAR(100),
        cust_address1 VARCHAR(100),
        cust_address2 VARCHAR(100),
        cust_address3 VARCHAR(100),
        cust_postal_code VARCHAR(10),
        cust_vat_no VARCHAR(20),
        cust_payment_terms VARCHAR(50),
        gross_tot DECIMAL(15,2) NOT NULL,
        disc_tot DECIMAL(15,2) NOT NULL,
        vat_tot DECIMAL(15,2) NOT NULL,
        net_tot DECIMAL(15,2) NOT NULL,
        notes TEXT,
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4),
        created_by BIGINT,
        updated_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE sa31_ord_det (
        id BIGSERIAL NOT NULL,
        hdr_id BIGINT NOT NULL,
        line_no INTEGER NOT NULL,
        stock_id BIGINT,
        item_name VARCHAR(200),
        uom VARCHAR(20),
        qnty DECIMAL(15,3) NOT NULL,
        unit_price DECIMAL(15,4) NOT NULL,
        disc_pct DECIMAL(7,3) NOT NULL,
        disc_amt DECIMAL(15,2) NOT NULL,
        gross_amt DECIMAL(15,2) NOT NULL,
        vat_rate DECIMAL(7,3) NOT NULL,
        vat_amt DECIMAL(15,2) NOT NULL,
        net_amt DECIMAL(15,2) NOT NULL,
        line_total DECIMAL(15,2) NOT NULL,
        wh_id BIGINT,
        wb_id BIGINT,
        notes VARCHAR(200),
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        created_by BIGINT,
        updated_at DATETIME YEAR TO FRACTION(4),
        updated_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE sa31_ord_hdr (
        id BIGSERIAL NOT NULL,
        doc_no VARCHAR(30),
        ref_doc_type VARCHAR(20),
        ref_doc_no VARCHAR(30),
        trans_date DATE NOT NULL,
        cust_id BIGINT,
        cust_name VARCHAR(100),
        cust_phone VARCHAR(20),
        cust_email VARCHAR(100),
        cust_address1 VARCHAR(100),
        cust_address2 VARCHAR(100),
        cust_address3 VARCHAR(100),
        cust_postal_code VARCHAR(10),
        cust_vat_no VARCHAR(20),
        cust_payment_terms VARCHAR(50),
        gross_tot DECIMAL(15,2) NOT NULL,
        disc_tot DECIMAL(15,2) NOT NULL,
        vat_tot DECIMAL(15,2) NOT NULL,
        net_tot DECIMAL(15,2) NOT NULL,
        notes TEXT,
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4),
        created_by BIGINT,
        updated_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE sa32_inv_det (
        id BIGSERIAL NOT NULL,
        hdr_id BIGINT NOT NULL,
        line_no INTEGER NOT NULL,
        stock_id BIGINT,
        item_name VARCHAR(200),
        uom VARCHAR(20),
        qnty DECIMAL(15,3) NOT NULL,
        unit_price DECIMAL(15,4) NOT NULL,
        disc_pct DECIMAL(7,3) NOT NULL,
        disc_amt DECIMAL(15,2) NOT NULL,
        gross_amt DECIMAL(15,2) NOT NULL,
        vat_rate DECIMAL(7,3) NOT NULL,
        vat_amt DECIMAL(15,2) NOT NULL,
        net_amt DECIMAL(15,2) NOT NULL,
        line_total DECIMAL(15,2) NOT NULL,
        wh_id BIGINT,
        wb_id BIGINT,
        notes VARCHAR(200),
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        created_by BIGINT,
        updated_at DATETIME YEAR TO FRACTION(4),
        updated_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE sa32_inv_hdr (
        id BIGSERIAL NOT NULL,
        doc_no VARCHAR(30),
        ref_doc_type VARCHAR(20),
        ref_doc_no VARCHAR(30),
        trans_date DATE NOT NULL,
        due_date DATE,
        cust_id BIGINT,
        cust_name VARCHAR(100),
        cust_phone VARCHAR(20),
        cust_email VARCHAR(100),
        cust_address1 VARCHAR(100),
        cust_address2 VARCHAR(100),
        cust_address3 VARCHAR(100),
        cust_postal_code VARCHAR(10),
        cust_vat_no VARCHAR(20),
        cust_payment_terms VARCHAR(50),
        gross_tot DECIMAL(15,2) NOT NULL,
        disc_tot DECIMAL(15,2) NOT NULL,
        vat_tot DECIMAL(15,2) NOT NULL,
        net_tot DECIMAL(15,2) NOT NULL,
        notes TEXT,
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4),
        created_by BIGINT,
        updated_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE sa33_crn_det (
        id BIGSERIAL NOT NULL,
        hdr_id BIGINT NOT NULL,
        line_no INTEGER NOT NULL,
        stock_id BIGINT,
        item_name VARCHAR(200),
        uom VARCHAR(20),
        qnty DECIMAL(15,3) NOT NULL,
        unit_price DECIMAL(15,4) NOT NULL,
        disc_pct DECIMAL(7,3) NOT NULL,
        disc_amt DECIMAL(15,2) NOT NULL,
        gross_amt DECIMAL(15,2) NOT NULL,
        vat_rate DECIMAL(7,3) NOT NULL,
        vat_amt DECIMAL(15,2) NOT NULL,
        net_amt DECIMAL(15,2) NOT NULL,
        line_total DECIMAL(15,2) NOT NULL,
        wh_id BIGINT,
        wb_id BIGINT,
        notes VARCHAR(200),
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        created_by BIGINT,
        updated_at DATETIME YEAR TO FRACTION(4),
        updated_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE sa33_crn_hdr (
        id BIGSERIAL NOT NULL,
        doc_no VARCHAR(30),
        ref_doc_type VARCHAR(20),
        ref_doc_no VARCHAR(30),
        trans_date DATE NOT NULL,
        credit_date DATE,
        cust_id BIGINT,
        cust_name VARCHAR(100),
        cust_phone VARCHAR(20),
        cust_email VARCHAR(100),
        cust_address1 VARCHAR(100),
        cust_address2 VARCHAR(100),
        cust_address3 VARCHAR(100),
        cust_postal_code VARCHAR(10),
        cust_vat_no VARCHAR(20),
        cust_payment_terms VARCHAR(50),
        gross_tot DECIMAL(15,2) NOT NULL,
        disc_tot DECIMAL(15,2) NOT NULL,
        vat_tot DECIMAL(15,2) NOT NULL,
        net_tot DECIMAL(15,2) NOT NULL,
        notes TEXT,
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4),
        created_by BIGINT,
        updated_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE st01_mast (
        id BIGSERIAL NOT NULL,
        stock_code VARCHAR(30),
        description VARCHAR(200) NOT NULL,
        barcode VARCHAR(60),
        batch_control BOOLEAN,
        has_expiry_date BOOLEAN,
        category_id BIGINT NOT NULL,
        unit_cost DECIMAL(15,4) NOT NULL,
        sell_price DECIMAL(15,4) NOT NULL,
        stock_on_hand DECIMAL(15,3) NOT NULL,
        total_purch DECIMAL(15,3) NOT NULL,
        total_sales DECIMAL(15,3) NOT NULL,
        reserved_qnty DECIMAL(15,3) NOT NULL,
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4),
        created_by BIGINT NOT NULL,
        uom VARCHAR(20),
        stock_balance DECIMAL(5,3),
        base_uom_id BIGINT,
        is_multiple_uom BOOLEAN)"
    EXECUTE IMMEDIATE "CREATE TABLE st02_cat (
        id BIGSERIAL NOT NULL,
        cat_code VARCHAR(30),
        cat_name VARCHAR(120) NOT NULL,
        description VARCHAR(200),
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4),
        created_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE st03_uom_master (
        id BIGSERIAL NOT NULL,
        uom_code VARCHAR(20) NOT NULL,
        uom_name VARCHAR(50) NOT NULL,
        uom_type VARCHAR(20),
        is_active BOOLEAN,
        decimal_places INTEGER,
        created_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE st04_stock_uom (
        id BIGSERIAL NOT NULL,
        stock_id BIGINT NOT NULL,
        uom_id BIGINT NOT NULL,
        is_base_uom BOOLEAN,
        conversion_factor DECIMAL(15,6),
        barcode VARCHAR(60),
        unit_cost DECIMAL(15,4),
        sell_price DECIMAL(15,4),
        is_active BOOLEAN,
        display_order INTEGER,
        created_at DATETIME YEAR TO FRACTION(4),
        updated_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE st30_trans (
        id BIGSERIAL NOT NULL,
        stock_id VARCHAR(20) NOT NULL,
        trans_date DATE NOT NULL,
        doc_type VARCHAR(10) NOT NULL,
        direction VARCHAR(3) NOT NULL,
        qnty DECIMAL(12,2) NOT NULL,
        unit_cost DECIMAL(12,2),
        sell_price DECIMAL(12,2),
        batch_id VARCHAR(30),
        expiry_date DATE,
        notes VARCHAR(200))"
    EXECUTE IMMEDIATE "CREATE TABLE sy00_user (
        id BIGSERIAL NOT NULL,
        username VARCHAR(60) NOT NULL,
        full_name VARCHAR(120),
        phone VARCHAR(30),
        email VARCHAR(120),
        password VARCHAR(200),
        status VARCHAR(20) NOT NULL,
        role_id BIGINT,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE sy01_sess (
        id BIGSERIAL NOT NULL,
        user_id BIGINT NOT NULL,
        uuid VARCHAR(64) NOT NULL,
        login_time DATETIME YEAR TO FRACTION(4) NOT NULL,
        logout_time DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE sy02_logs (
        id BIGSERIAL NOT NULL,
        user_id BIGINT,
        level VARCHAR(20),
        action VARCHAR(120),
        details TEXT,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE sy03_sett (
        id BIGSERIAL NOT NULL,
        sett_key VARCHAR(120) NOT NULL,
        sett_value TEXT,
        description TEXT,
        updated_at DATETIME YEAR TO FRACTION(4) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE sy04_role (
        id BIGSERIAL NOT NULL,
        role_name VARCHAR(60) NOT NULL,
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE sy05_perm (
        id BIGSERIAL NOT NULL,
        perm_name VARCHAR(120) NOT NULL,
        description VARCHAR(200),
        perm_code VARCHAR(60),
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4),
        created_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE sy06_role_perm (
        id BIGSERIAL NOT NULL,
        role_id BIGINT NOT NULL,
        perm_id BIGINT NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE sy07_doc_num (
        id BIGSERIAL NOT NULL,
        doc_name VARCHAR(60) NOT NULL,
        prefix VARCHAR(20),
        next_no BIGINT NOT NULL,
        step INTEGER NOT NULL,
        status VARCHAR(20) NOT NULL,
        created_by BIGINT,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE sy08_lkup_config (
        id BIGSERIAL NOT NULL,
        lookup_code VARCHAR(60) NOT NULL,
        table_name VARCHAR(120) NOT NULL,
        key_field VARCHAR(120) NOT NULL,
        desc_field VARCHAR(120) NOT NULL,
        display_title VARCHAR(120),
        filter_condition VARCHAR(400),
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE wb01_mast (
        id BIGSERIAL NOT NULL,
        wb_code VARCHAR(30),
        wh_id BIGINT NOT NULL,
        description VARCHAR(120),
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4),
        created_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE wb30_trf_hdr (
        id BIGSERIAL NOT NULL,
        trans_no VARCHAR(30),
        wb_from BIGINT,
        wb_to BIGINT,
        trans_date DATE NOT NULL,
        created_by BIGINT,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE wb31_trf_det (
        id BIGSERIAL NOT NULL,
        hdr_id BIGINT NOT NULL,
        item_no INTEGER NOT NULL,
        stock_id BIGINT,
        qnty DECIMAL(15,3) NOT NULL,
        batch_id VARCHAR(40),
        expiry_date DATE)"
    EXECUTE IMMEDIATE "CREATE TABLE wh01_mast (
        id BIGSERIAL NOT NULL,
        wh_code VARCHAR(30),
        wh_name VARCHAR(120) NOT NULL,
        location VARCHAR(120),
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4),
        created_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE wh30_trans (
        id BIGSERIAL NOT NULL,
        trans_date DATE NOT NULL,
        trans_type VARCHAR(20),
        ref_no VARCHAR(40),
        source_module VARCHAR(20),
        source_doc_id BIGINT,
        wh_id BIGINT,
        wb_id BIGINT,
        stock_id BIGINT,
        qnty_in DECIMAL(15,3) NOT NULL,
        qnty_out DECIMAL(15,3) NOT NULL,
        run_qty DECIMAL(15,3),
        uom VARCHAR(20),
        unit_cost DECIMAL(15,4) NOT NULL,
        ext_cost DECIMAL(15,2) NOT NULL,
        remarks VARCHAR(200),
        status VARCHAR(20) NOT NULL,
        created_by BIGINT,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_by BIGINT,
        updated_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE wh30_trf_hdr (
        id BIGSERIAL NOT NULL,
        trans_no VARCHAR(30),
        from_wh_id BIGINT NOT NULL,
        to_wh_id BIGINT NOT NULL,
        from_wb_id BIGINT,
        to_wb_id BIGINT,
        trans_date DATE NOT NULL,
        notes TEXT,
        status VARCHAR(20) NOT NULL,
        created_by BIGINT,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        updated_by BIGINT,
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE wh31_trf_det (
        id BIGSERIAL NOT NULL,
        hdr_id BIGINT NOT NULL,
        item_no INTEGER NOT NULL,
        stock_id BIGINT,
        item_name VARCHAR(200),
        uom VARCHAR(20),
        from_wb_id BIGINT,
        to_wb_id BIGINT,
        batch_id VARCHAR(40),
        expiry_date DATE,
        qnty DECIMAL(15,3) NOT NULL,
        unit_cost DECIMAL(15,4) NOT NULL,
        ext_cost DECIMAL(15,2) NOT NULL,
        notes VARCHAR(200),
        status VARCHAR(20) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4) NOT NULL,
        created_by BIGINT,
        updated_at DATETIME YEAR TO FRACTION(4),
        updated_by BIGINT)"

END FUNCTION

#+ Drop all tables from database.
FUNCTION db_drop_tables()
    WHENEVER ERROR CONTINUE

    EXECUTE IMMEDIATE "DROP TABLE cl01_mast"
    EXECUTE IMMEDIATE "DROP TABLE cl30_trans"
    EXECUTE IMMEDIATE "DROP TABLE dl01_mast"
    EXECUTE IMMEDIATE "DROP TABLE dl30_trans"
    EXECUTE IMMEDIATE "DROP TABLE gl01_acc"
    EXECUTE IMMEDIATE "DROP TABLE gl30_jnls"
    EXECUTE IMMEDIATE "DROP TABLE gl31_lines"
    EXECUTE IMMEDIATE "DROP TABLE payt30_hdr"
    EXECUTE IMMEDIATE "DROP TABLE payt31_trans_det"
    EXECUTE IMMEDIATE "DROP TABLE pu30_ord_det"
    EXECUTE IMMEDIATE "DROP TABLE pu30_ord_hdr"
    EXECUTE IMMEDIATE "DROP TABLE pu31_grn_det"
    EXECUTE IMMEDIATE "DROP TABLE pu31_grn_hdr"
    EXECUTE IMMEDIATE "DROP TABLE pu32_inv_det"
    EXECUTE IMMEDIATE "DROP TABLE pu32_inv_hdr"
    EXECUTE IMMEDIATE "DROP TABLE sa30_quo_det"
    EXECUTE IMMEDIATE "DROP TABLE sa30_quo_hdr"
    EXECUTE IMMEDIATE "DROP TABLE sa31_ord_det"
    EXECUTE IMMEDIATE "DROP TABLE sa31_ord_hdr"
    EXECUTE IMMEDIATE "DROP TABLE sa32_inv_det"
    EXECUTE IMMEDIATE "DROP TABLE sa32_inv_hdr"
    EXECUTE IMMEDIATE "DROP TABLE sa33_crn_det"
    EXECUTE IMMEDIATE "DROP TABLE sa33_crn_hdr"
    EXECUTE IMMEDIATE "DROP TABLE st01_mast"
    EXECUTE IMMEDIATE "DROP TABLE st02_cat"
    EXECUTE IMMEDIATE "DROP TABLE st03_uom_master"
    EXECUTE IMMEDIATE "DROP TABLE st04_stock_uom"
    EXECUTE IMMEDIATE "DROP TABLE st30_trans"
    EXECUTE IMMEDIATE "DROP TABLE sy00_user"
    EXECUTE IMMEDIATE "DROP TABLE sy01_sess"
    EXECUTE IMMEDIATE "DROP TABLE sy02_logs"
    EXECUTE IMMEDIATE "DROP TABLE sy03_sett"
    EXECUTE IMMEDIATE "DROP TABLE sy04_role"
    EXECUTE IMMEDIATE "DROP TABLE sy05_perm"
    EXECUTE IMMEDIATE "DROP TABLE sy06_role_perm"
    EXECUTE IMMEDIATE "DROP TABLE sy07_doc_num"
    EXECUTE IMMEDIATE "DROP TABLE sy08_lkup_config"
    EXECUTE IMMEDIATE "DROP TABLE wb01_mast"
    EXECUTE IMMEDIATE "DROP TABLE wb30_trf_hdr"
    EXECUTE IMMEDIATE "DROP TABLE wb31_trf_det"
    EXECUTE IMMEDIATE "DROP TABLE wh01_mast"
    EXECUTE IMMEDIATE "DROP TABLE wh30_trans"
    EXECUTE IMMEDIATE "DROP TABLE wh30_trf_hdr"
    EXECUTE IMMEDIATE "DROP TABLE wh31_trf_det"

END FUNCTION

#+ Add constraints for all tables.
FUNCTION db_add_constraints()
    WHENEVER ERROR STOP

    EXECUTE IMMEDIATE "ALTER TABLE cl01_mast ADD CONSTRAINT cl01_mast_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE cl30_trans ADD CONSTRAINT cl30_trans_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE dl01_mast ADD CONSTRAINT dl01_mast_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE dl30_trans ADD CONSTRAINT dl30_trans_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE gl01_acc ADD CONSTRAINT gl01_acc_acc_code_key
        UNIQUE (acc_code)"
    EXECUTE IMMEDIATE "ALTER TABLE gl30_jnls ADD CONSTRAINT gl30_jnls_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE gl30_jnls ADD CONSTRAINT gl30_jnls_jrn_no_key
        UNIQUE (jrn_no)"
    EXECUTE IMMEDIATE "ALTER TABLE gl31_lines ADD CONSTRAINT gl31_lines_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE gl31_lines ADD CONSTRAINT gl31_lines_jrn_id_line_no_key
        UNIQUE (jrn_id, line_no)"
    EXECUTE IMMEDIATE "ALTER TABLE payt30_hdr ADD CONSTRAINT payt30_hdr_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE payt30_hdr ADD CONSTRAINT payt30_hdr_doc_no_key
        UNIQUE (doc_no)"
    EXECUTE IMMEDIATE "ALTER TABLE payt31_trans_det ADD CONSTRAINT payt31_trans_det_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_det ADD CONSTRAINT pu30_ord_det_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_det ADD CONSTRAINT pu30_ord_det_hdr_id_line_no_key
        UNIQUE (hdr_id, line_no)"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_hdr ADD CONSTRAINT pu30_ord_hdr_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_hdr ADD CONSTRAINT pu30_ord_hdr_doc_no_key
        UNIQUE (doc_no)"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_det ADD CONSTRAINT pu31_grn_det_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_det ADD CONSTRAINT pu31_grn_det_hdr_id_line_no_key
        UNIQUE (hdr_id, line_no)"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_hdr ADD CONSTRAINT pu31_grn_hdr_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_hdr ADD CONSTRAINT pu31_grn_hdr_doc_no_key
        UNIQUE (doc_no)"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_det ADD CONSTRAINT pu32_inv_det_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_det ADD CONSTRAINT pu32_inv_det_hdr_id_line_no_key
        UNIQUE (hdr_id, line_no)"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_hdr ADD CONSTRAINT pu32_inv_hdr_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_hdr ADD CONSTRAINT pu32_inv_hdr_doc_no_key
        UNIQUE (doc_no)"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_det ADD CONSTRAINT sa30_quo_det_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_det ADD CONSTRAINT sa30_quo_det_hdr_id_line_no_key
        UNIQUE (hdr_id, line_no)"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_hdr ADD CONSTRAINT sa30_quo_hdr_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_hdr ADD CONSTRAINT sa30_quo_hdr_doc_no_key
        UNIQUE (doc_no)"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_det ADD CONSTRAINT sa31_ord_det_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_det ADD CONSTRAINT sa31_ord_det_hdr_id_line_no_key
        UNIQUE (hdr_id, line_no)"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_hdr ADD CONSTRAINT sa31_ord_hdr_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_hdr ADD CONSTRAINT sa31_ord_hdr_doc_no_key
        UNIQUE (doc_no)"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_det ADD CONSTRAINT sa32_inv_det_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_det ADD CONSTRAINT sa32_inv_det_hdr_id_line_no_key
        UNIQUE (hdr_id, line_no)"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_hdr ADD CONSTRAINT sa32_inv_hdr_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_hdr ADD CONSTRAINT sa32_inv_hdr_doc_no_key
        UNIQUE (doc_no)"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_det ADD CONSTRAINT sa33_crn_det_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_det ADD CONSTRAINT sa33_crn_det_hdr_id_line_no_key
        UNIQUE (hdr_id, line_no)"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_hdr ADD CONSTRAINT sa33_crn_hdr_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_hdr ADD CONSTRAINT sa33_crn_hdr_doc_no_key
        UNIQUE (doc_no)"
    EXECUTE IMMEDIATE "ALTER TABLE st01_mast ADD CONSTRAINT st01_mast_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE st01_mast ADD CONSTRAINT st01_mast_stock_code_key
        UNIQUE (stock_code)"
    EXECUTE IMMEDIATE "ALTER TABLE st02_cat ADD CONSTRAINT st02_cat_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE st02_cat ADD CONSTRAINT st02_cat_cat_code_key
        UNIQUE (cat_code)"
    EXECUTE IMMEDIATE "ALTER TABLE st03_uom_master ADD CONSTRAINT st03_uom_master_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE st03_uom_master ADD CONSTRAINT st03_uom_master_uom_code_key
        UNIQUE (uom_code)"
    EXECUTE IMMEDIATE "ALTER TABLE st04_stock_uom ADD CONSTRAINT st04_stock_uom_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE st04_stock_uom ADD CONSTRAINT st04_stock_uom_stock_id_uom_id_key
        UNIQUE (stock_id, uom_id)"
    EXECUTE IMMEDIATE "ALTER TABLE st30_trans ADD CONSTRAINT st30_trans_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy00_user ADD CONSTRAINT sy00_user_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy00_user ADD CONSTRAINT sy00_user_username_key
        UNIQUE (username)"
    EXECUTE IMMEDIATE "ALTER TABLE sy01_sess ADD CONSTRAINT sy01_sess_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy02_logs ADD CONSTRAINT sy02_logs_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy03_sett ADD CONSTRAINT sy03_sett_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy03_sett ADD CONSTRAINT sy03_sett_sett_key_key
        UNIQUE (sett_key)"
    EXECUTE IMMEDIATE "ALTER TABLE sy04_role ADD CONSTRAINT sy04_role_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy04_role ADD CONSTRAINT sy04_role_role_name_key
        UNIQUE (role_name)"
    EXECUTE IMMEDIATE "ALTER TABLE sy05_perm ADD CONSTRAINT sy05_perm_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy05_perm ADD CONSTRAINT sy05_perm_perm_name_key
        UNIQUE (perm_name)"
    EXECUTE IMMEDIATE "ALTER TABLE sy06_role_perm ADD CONSTRAINT sy06_role_perm_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy06_role_perm ADD CONSTRAINT sy06_role_perm_role_id_perm_id_key
        UNIQUE (role_id, perm_id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy07_doc_num ADD CONSTRAINT sy07_doc_num_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy07_doc_num ADD CONSTRAINT sy07_doc_num_doc_name_key
        UNIQUE (doc_name)"
    EXECUTE IMMEDIATE "ALTER TABLE sy08_lkup_config ADD CONSTRAINT sy08_lkup_config_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy08_lkup_config ADD CONSTRAINT sy08_lkup_config_lookup_code_key
        UNIQUE (lookup_code)"
    EXECUTE IMMEDIATE "ALTER TABLE wb01_mast ADD CONSTRAINT wb01_mast_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wb01_mast ADD CONSTRAINT wb01_mast_wh_id_wb_code_key
        UNIQUE (wh_id, wb_code)"
    EXECUTE IMMEDIATE "ALTER TABLE wb30_trf_hdr ADD CONSTRAINT wb30_trf_hdr_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wb30_trf_hdr ADD CONSTRAINT wb30_trf_hdr_trans_no_key
        UNIQUE (trans_no)"
    EXECUTE IMMEDIATE "ALTER TABLE wb31_trf_det ADD CONSTRAINT wb31_trf_det_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wb31_trf_det ADD CONSTRAINT wb31_trf_det_hdr_id_item_no_key
        UNIQUE (hdr_id, item_no)"
    EXECUTE IMMEDIATE "ALTER TABLE wh01_mast ADD CONSTRAINT wh01_mast_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh01_mast ADD CONSTRAINT wh01_mast_wh_code_key
        UNIQUE (wh_code)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trans ADD CONSTRAINT wh30_trans_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trf_hdr ADD CONSTRAINT wh30_trf_hdr_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trf_hdr ADD CONSTRAINT wh30_trf_hdr_trans_no_key
        UNIQUE (trans_no)"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_trf_det ADD CONSTRAINT wh31_trf_det_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_trf_det ADD CONSTRAINT wh31_trf_det_hdr_id_item_no_key
        UNIQUE (hdr_id, item_no)"
    EXECUTE IMMEDIATE "ALTER TABLE cl01_mast ADD CONSTRAINT cl01_mast_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE cl30_trans ADD CONSTRAINT cl30_trans_supp_id_fkey
        FOREIGN KEY (supp_id)
        REFERENCES cl01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE dl01_mast ADD CONSTRAINT dl01_mast_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE dl30_trans ADD CONSTRAINT dl30_trans_cust_id_fkey
        FOREIGN KEY (cust_id)
        REFERENCES dl01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE st01_mast ADD CONSTRAINT fk_st01_mast_base_uom
        FOREIGN KEY (base_uom_id)
        REFERENCES st03_uom_master (id)"
    EXECUTE IMMEDIATE "ALTER TABLE gl01_acc ADD CONSTRAINT gl01_acc_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE gl01_acc ADD CONSTRAINT gl01_acc_parent_id_fkey
        FOREIGN KEY (parent_id)
        REFERENCES gl01_acc (id)"
    EXECUTE IMMEDIATE "ALTER TABLE gl30_jnls ADD CONSTRAINT gl30_jnls_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE gl31_lines ADD CONSTRAINT gl31_lines_acc_id_fkey
        FOREIGN KEY (acc_id)
        REFERENCES gl01_acc (id)"
    EXECUTE IMMEDIATE "ALTER TABLE gl31_lines ADD CONSTRAINT gl31_lines_jrn_id_fkey
        FOREIGN KEY (jrn_id)
        REFERENCES gl30_jnls (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE payt30_hdr ADD CONSTRAINT payt30_hdr_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE payt31_trans_det ADD CONSTRAINT payt31_trans_det_hdr_id_fkey
        FOREIGN KEY (hdr_id)
        REFERENCES payt30_hdr (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_det ADD CONSTRAINT pu30_ord_det_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_det ADD CONSTRAINT pu30_ord_det_hdr_id_fkey
        FOREIGN KEY (hdr_id)
        REFERENCES pu30_ord_hdr (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_det ADD CONSTRAINT pu30_ord_det_stock_id_fkey
        FOREIGN KEY (stock_id)
        REFERENCES st01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_det ADD CONSTRAINT pu30_ord_det_updated_by_fkey
        FOREIGN KEY (updated_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_det ADD CONSTRAINT pu30_ord_det_wb_id_fkey
        FOREIGN KEY (wb_id)
        REFERENCES wb01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_det ADD CONSTRAINT pu30_ord_det_wh_id_fkey
        FOREIGN KEY (wh_id)
        REFERENCES wh01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_hdr ADD CONSTRAINT pu30_ord_hdr_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_hdr ADD CONSTRAINT pu30_ord_hdr_supp_id_fkey
        FOREIGN KEY (supp_id)
        REFERENCES cl01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_hdr ADD CONSTRAINT pu30_ord_hdr_updated_by_fkey
        FOREIGN KEY (updated_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_det ADD CONSTRAINT pu31_grn_det_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_det ADD CONSTRAINT pu31_grn_det_hdr_id_fkey
        FOREIGN KEY (hdr_id)
        REFERENCES pu31_grn_hdr (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_det ADD CONSTRAINT pu31_grn_det_stock_id_fkey
        FOREIGN KEY (stock_id)
        REFERENCES st01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_det ADD CONSTRAINT pu31_grn_det_updated_by_fkey
        FOREIGN KEY (updated_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_det ADD CONSTRAINT pu31_grn_det_wb_id_fkey
        FOREIGN KEY (wb_id)
        REFERENCES wb01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_det ADD CONSTRAINT pu31_grn_det_wh_id_fkey
        FOREIGN KEY (wh_id)
        REFERENCES wh01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_hdr ADD CONSTRAINT pu31_grn_hdr_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_hdr ADD CONSTRAINT pu31_grn_hdr_received_by_fkey
        FOREIGN KEY (received_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_hdr ADD CONSTRAINT pu31_grn_hdr_supp_id_fkey
        FOREIGN KEY (supp_id)
        REFERENCES cl01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_hdr ADD CONSTRAINT pu31_grn_hdr_updated_by_fkey
        FOREIGN KEY (updated_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_det ADD CONSTRAINT pu32_inv_det_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_det ADD CONSTRAINT pu32_inv_det_hdr_id_fkey
        FOREIGN KEY (hdr_id)
        REFERENCES pu32_inv_hdr (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_det ADD CONSTRAINT pu32_inv_det_stock_id_fkey
        FOREIGN KEY (stock_id)
        REFERENCES st01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_det ADD CONSTRAINT pu32_inv_det_updated_by_fkey
        FOREIGN KEY (updated_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_det ADD CONSTRAINT pu32_inv_det_wb_id_fkey
        FOREIGN KEY (wb_id)
        REFERENCES wb01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_det ADD CONSTRAINT pu32_inv_det_wh_id_fkey
        FOREIGN KEY (wh_id)
        REFERENCES wh01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_hdr ADD CONSTRAINT pu32_inv_hdr_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_hdr ADD CONSTRAINT pu32_inv_hdr_supp_id_fkey
        FOREIGN KEY (supp_id)
        REFERENCES cl01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_hdr ADD CONSTRAINT pu32_inv_hdr_updated_by_fkey
        FOREIGN KEY (updated_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_det ADD CONSTRAINT sa30_quo_det_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_det ADD CONSTRAINT sa30_quo_det_hdr_id_fkey
        FOREIGN KEY (hdr_id)
        REFERENCES sa30_quo_hdr (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_det ADD CONSTRAINT sa30_quo_det_stock_id_fkey
        FOREIGN KEY (stock_id)
        REFERENCES st01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_det ADD CONSTRAINT sa30_quo_det_updated_by_fkey
        FOREIGN KEY (updated_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_det ADD CONSTRAINT sa30_quo_det_wb_id_fkey
        FOREIGN KEY (wb_id)
        REFERENCES wb01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_det ADD CONSTRAINT sa30_quo_det_wh_id_fkey
        FOREIGN KEY (wh_id)
        REFERENCES wh01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_hdr ADD CONSTRAINT sa30_quo_hdr_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_hdr ADD CONSTRAINT sa30_quo_hdr_cust_id_fkey
        FOREIGN KEY (cust_id)
        REFERENCES dl01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_hdr ADD CONSTRAINT sa30_quo_hdr_updated_by_fkey
        FOREIGN KEY (updated_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_det ADD CONSTRAINT sa31_ord_det_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_det ADD CONSTRAINT sa31_ord_det_hdr_id_fkey
        FOREIGN KEY (hdr_id)
        REFERENCES sa31_ord_hdr (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_det ADD CONSTRAINT sa31_ord_det_stock_id_fkey
        FOREIGN KEY (stock_id)
        REFERENCES st01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_det ADD CONSTRAINT sa31_ord_det_updated_by_fkey
        FOREIGN KEY (updated_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_det ADD CONSTRAINT sa31_ord_det_wb_id_fkey
        FOREIGN KEY (wb_id)
        REFERENCES wb01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_det ADD CONSTRAINT sa31_ord_det_wh_id_fkey
        FOREIGN KEY (wh_id)
        REFERENCES wh01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_hdr ADD CONSTRAINT sa31_ord_hdr_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_hdr ADD CONSTRAINT sa31_ord_hdr_cust_id_fkey
        FOREIGN KEY (cust_id)
        REFERENCES dl01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_hdr ADD CONSTRAINT sa31_ord_hdr_updated_by_fkey
        FOREIGN KEY (updated_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_det ADD CONSTRAINT sa32_inv_det_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_det ADD CONSTRAINT sa32_inv_det_hdr_id_fkey
        FOREIGN KEY (hdr_id)
        REFERENCES sa32_inv_hdr (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_det ADD CONSTRAINT sa32_inv_det_stock_id_fkey
        FOREIGN KEY (stock_id)
        REFERENCES st01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_det ADD CONSTRAINT sa32_inv_det_updated_by_fkey
        FOREIGN KEY (updated_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_det ADD CONSTRAINT sa32_inv_det_wb_id_fkey
        FOREIGN KEY (wb_id)
        REFERENCES wb01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_det ADD CONSTRAINT sa32_inv_det_wh_id_fkey
        FOREIGN KEY (wh_id)
        REFERENCES wh01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_hdr ADD CONSTRAINT sa32_inv_hdr_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_hdr ADD CONSTRAINT sa32_inv_hdr_cust_id_fkey
        FOREIGN KEY (cust_id)
        REFERENCES dl01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_hdr ADD CONSTRAINT sa32_inv_hdr_updated_by_fkey
        FOREIGN KEY (updated_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_det ADD CONSTRAINT sa33_crn_det_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_det ADD CONSTRAINT sa33_crn_det_hdr_id_fkey
        FOREIGN KEY (hdr_id)
        REFERENCES sa33_crn_hdr (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_det ADD CONSTRAINT sa33_crn_det_stock_id_fkey
        FOREIGN KEY (stock_id)
        REFERENCES st01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_det ADD CONSTRAINT sa33_crn_det_updated_by_fkey
        FOREIGN KEY (updated_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_det ADD CONSTRAINT sa33_crn_det_wb_id_fkey
        FOREIGN KEY (wb_id)
        REFERENCES wb01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_det ADD CONSTRAINT sa33_crn_det_wh_id_fkey
        FOREIGN KEY (wh_id)
        REFERENCES wh01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_hdr ADD CONSTRAINT sa33_crn_hdr_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_hdr ADD CONSTRAINT sa33_crn_hdr_cust_id_fkey
        FOREIGN KEY (cust_id)
        REFERENCES dl01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_hdr ADD CONSTRAINT sa33_crn_hdr_updated_by_fkey
        FOREIGN KEY (updated_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE st01_mast ADD CONSTRAINT st01_mast_category_id_fkey
        FOREIGN KEY (category_id)
        REFERENCES st02_cat (id)"
    EXECUTE IMMEDIATE "ALTER TABLE st01_mast ADD CONSTRAINT st01_mast_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE st02_cat ADD CONSTRAINT st02_cat_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE st04_stock_uom ADD CONSTRAINT st04_stock_uom_stock_id_fkey
        FOREIGN KEY (stock_id)
        REFERENCES st01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE st04_stock_uom ADD CONSTRAINT st04_stock_uom_uom_id_fkey
        FOREIGN KEY (uom_id)
        REFERENCES st03_uom_master (id)"
    EXECUTE IMMEDIATE "ALTER TABLE st30_trans ADD CONSTRAINT st30_trans_stock_id_fkey
        FOREIGN KEY (stock_id)
        REFERENCES st01_mast (stock_code)"
    EXECUTE IMMEDIATE "ALTER TABLE sy00_user ADD CONSTRAINT sy00_user_role_id_fkey
        FOREIGN KEY (role_id)
        REFERENCES sy04_role (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy01_sess ADD CONSTRAINT sy01_sess_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES sy00_user (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE sy02_logs ADD CONSTRAINT sy02_logs_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy06_role_perm ADD CONSTRAINT sy06_role_perm_perm_id_fkey
        FOREIGN KEY (perm_id)
        REFERENCES sy05_perm (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE sy06_role_perm ADD CONSTRAINT sy06_role_perm_role_id_fkey
        FOREIGN KEY (role_id)
        REFERENCES sy04_role (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE sy07_doc_num ADD CONSTRAINT sy07_doc_num_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wb01_mast ADD CONSTRAINT wb01_mast_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wb01_mast ADD CONSTRAINT wb01_mast_wh_id_fkey
        FOREIGN KEY (wh_id)
        REFERENCES wh01_mast (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE wb30_trf_hdr ADD CONSTRAINT wb30_trf_hdr_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wb30_trf_hdr ADD CONSTRAINT wb30_trf_hdr_wb_from_fkey
        FOREIGN KEY (wb_from)
        REFERENCES wb01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wb30_trf_hdr ADD CONSTRAINT wb30_trf_hdr_wb_to_fkey
        FOREIGN KEY (wb_to)
        REFERENCES wb01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wb31_trf_det ADD CONSTRAINT wb31_trf_det_hdr_id_fkey
        FOREIGN KEY (hdr_id)
        REFERENCES wb30_trf_hdr (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE wb31_trf_det ADD CONSTRAINT wb31_trf_det_stock_id_fkey
        FOREIGN KEY (stock_id)
        REFERENCES st01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh01_mast ADD CONSTRAINT wh01_mast_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trans ADD CONSTRAINT wh30_trans_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trans ADD CONSTRAINT wh30_trans_stock_id_fkey
        FOREIGN KEY (stock_id)
        REFERENCES st01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trans ADD CONSTRAINT wh30_trans_updated_by_fkey
        FOREIGN KEY (updated_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trans ADD CONSTRAINT wh30_trans_wb_id_fkey
        FOREIGN KEY (wb_id)
        REFERENCES wb01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trans ADD CONSTRAINT wh30_trans_wh_id_fkey
        FOREIGN KEY (wh_id)
        REFERENCES wh01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trf_hdr ADD CONSTRAINT wh30_trf_hdr_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trf_hdr ADD CONSTRAINT wh30_trf_hdr_from_wb_id_fkey
        FOREIGN KEY (from_wb_id)
        REFERENCES wb01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trf_hdr ADD CONSTRAINT wh30_trf_hdr_from_wh_id_fkey
        FOREIGN KEY (from_wh_id)
        REFERENCES wh01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trf_hdr ADD CONSTRAINT wh30_trf_hdr_to_wb_id_fkey
        FOREIGN KEY (to_wb_id)
        REFERENCES wb01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trf_hdr ADD CONSTRAINT wh30_trf_hdr_to_wh_id_fkey
        FOREIGN KEY (to_wh_id)
        REFERENCES wh01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trf_hdr ADD CONSTRAINT wh30_trf_hdr_updated_by_fkey
        FOREIGN KEY (updated_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_trf_det ADD CONSTRAINT wh31_trf_det_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_trf_det ADD CONSTRAINT wh31_trf_det_from_wb_id_fkey
        FOREIGN KEY (from_wb_id)
        REFERENCES wb01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_trf_det ADD CONSTRAINT wh31_trf_det_hdr_id_fkey
        FOREIGN KEY (hdr_id)
        REFERENCES wh30_trf_hdr (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_trf_det ADD CONSTRAINT wh31_trf_det_stock_id_fkey
        FOREIGN KEY (stock_id)
        REFERENCES st01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_trf_det ADD CONSTRAINT wh31_trf_det_to_wb_id_fkey
        FOREIGN KEY (to_wb_id)
        REFERENCES wb01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_trf_det ADD CONSTRAINT wh31_trf_det_updated_by_fkey
        FOREIGN KEY (updated_by)
        REFERENCES sy00_user (id)"

END FUNCTION

#+ Drop all constraints from all tables.
FUNCTION db_drop_constraints()
    WHENEVER ERROR CONTINUE

    EXECUTE IMMEDIATE "ALTER TABLE cl01_mast DROP CONSTRAINT cl01_mast_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE cl30_trans DROP CONSTRAINT cl30_trans_supp_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE dl01_mast DROP CONSTRAINT dl01_mast_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE dl30_trans DROP CONSTRAINT dl30_trans_cust_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE st01_mast DROP CONSTRAINT fk_st01_mast_base_uom"
    EXECUTE IMMEDIATE "ALTER TABLE gl01_acc DROP CONSTRAINT gl01_acc_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE gl01_acc DROP CONSTRAINT gl01_acc_parent_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE gl30_jnls DROP CONSTRAINT gl30_jnls_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE gl31_lines DROP CONSTRAINT gl31_lines_acc_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE gl31_lines DROP CONSTRAINT gl31_lines_jrn_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE payt30_hdr DROP CONSTRAINT payt30_hdr_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE payt31_trans_det DROP CONSTRAINT payt31_trans_det_hdr_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_det DROP CONSTRAINT pu30_ord_det_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_det DROP CONSTRAINT pu30_ord_det_hdr_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_det DROP CONSTRAINT pu30_ord_det_stock_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_det DROP CONSTRAINT pu30_ord_det_updated_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_det DROP CONSTRAINT pu30_ord_det_wb_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_det DROP CONSTRAINT pu30_ord_det_wh_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_hdr DROP CONSTRAINT pu30_ord_hdr_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_hdr DROP CONSTRAINT pu30_ord_hdr_supp_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_ord_hdr DROP CONSTRAINT pu30_ord_hdr_updated_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_det DROP CONSTRAINT pu31_grn_det_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_det DROP CONSTRAINT pu31_grn_det_hdr_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_det DROP CONSTRAINT pu31_grn_det_stock_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_det DROP CONSTRAINT pu31_grn_det_updated_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_det DROP CONSTRAINT pu31_grn_det_wb_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_det DROP CONSTRAINT pu31_grn_det_wh_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_hdr DROP CONSTRAINT pu31_grn_hdr_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_hdr DROP CONSTRAINT pu31_grn_hdr_received_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_hdr DROP CONSTRAINT pu31_grn_hdr_supp_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_grn_hdr DROP CONSTRAINT pu31_grn_hdr_updated_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_det DROP CONSTRAINT pu32_inv_det_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_det DROP CONSTRAINT pu32_inv_det_hdr_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_det DROP CONSTRAINT pu32_inv_det_stock_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_det DROP CONSTRAINT pu32_inv_det_updated_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_det DROP CONSTRAINT pu32_inv_det_wb_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_det DROP CONSTRAINT pu32_inv_det_wh_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_hdr DROP CONSTRAINT pu32_inv_hdr_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_hdr DROP CONSTRAINT pu32_inv_hdr_supp_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu32_inv_hdr DROP CONSTRAINT pu32_inv_hdr_updated_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_det DROP CONSTRAINT sa30_quo_det_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_det DROP CONSTRAINT sa30_quo_det_hdr_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_det DROP CONSTRAINT sa30_quo_det_stock_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_det DROP CONSTRAINT sa30_quo_det_updated_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_det DROP CONSTRAINT sa30_quo_det_wb_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_det DROP CONSTRAINT sa30_quo_det_wh_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_hdr DROP CONSTRAINT sa30_quo_hdr_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_hdr DROP CONSTRAINT sa30_quo_hdr_cust_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_quo_hdr DROP CONSTRAINT sa30_quo_hdr_updated_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_det DROP CONSTRAINT sa31_ord_det_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_det DROP CONSTRAINT sa31_ord_det_hdr_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_det DROP CONSTRAINT sa31_ord_det_stock_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_det DROP CONSTRAINT sa31_ord_det_updated_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_det DROP CONSTRAINT sa31_ord_det_wb_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_det DROP CONSTRAINT sa31_ord_det_wh_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_hdr DROP CONSTRAINT sa31_ord_hdr_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_hdr DROP CONSTRAINT sa31_ord_hdr_cust_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_ord_hdr DROP CONSTRAINT sa31_ord_hdr_updated_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_det DROP CONSTRAINT sa32_inv_det_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_det DROP CONSTRAINT sa32_inv_det_hdr_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_det DROP CONSTRAINT sa32_inv_det_stock_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_det DROP CONSTRAINT sa32_inv_det_updated_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_det DROP CONSTRAINT sa32_inv_det_wb_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_det DROP CONSTRAINT sa32_inv_det_wh_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_hdr DROP CONSTRAINT sa32_inv_hdr_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_hdr DROP CONSTRAINT sa32_inv_hdr_cust_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_inv_hdr DROP CONSTRAINT sa32_inv_hdr_updated_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_det DROP CONSTRAINT sa33_crn_det_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_det DROP CONSTRAINT sa33_crn_det_hdr_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_det DROP CONSTRAINT sa33_crn_det_stock_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_det DROP CONSTRAINT sa33_crn_det_updated_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_det DROP CONSTRAINT sa33_crn_det_wb_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_det DROP CONSTRAINT sa33_crn_det_wh_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_hdr DROP CONSTRAINT sa33_crn_hdr_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_hdr DROP CONSTRAINT sa33_crn_hdr_cust_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_crn_hdr DROP CONSTRAINT sa33_crn_hdr_updated_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE st01_mast DROP CONSTRAINT st01_mast_category_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE st01_mast DROP CONSTRAINT st01_mast_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE st02_cat DROP CONSTRAINT st02_cat_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE st04_stock_uom DROP CONSTRAINT st04_stock_uom_stock_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE st04_stock_uom DROP CONSTRAINT st04_stock_uom_uom_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE st30_trans DROP CONSTRAINT st30_trans_stock_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sy00_user DROP CONSTRAINT sy00_user_role_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sy01_sess DROP CONSTRAINT sy01_sess_user_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sy02_logs DROP CONSTRAINT sy02_logs_user_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sy06_role_perm DROP CONSTRAINT sy06_role_perm_perm_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sy06_role_perm DROP CONSTRAINT sy06_role_perm_role_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sy07_doc_num DROP CONSTRAINT sy07_doc_num_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wb01_mast DROP CONSTRAINT wb01_mast_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wb01_mast DROP CONSTRAINT wb01_mast_wh_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wb30_trf_hdr DROP CONSTRAINT wb30_trf_hdr_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wb30_trf_hdr DROP CONSTRAINT wb30_trf_hdr_wb_from_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wb30_trf_hdr DROP CONSTRAINT wb30_trf_hdr_wb_to_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wb31_trf_det DROP CONSTRAINT wb31_trf_det_hdr_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wb31_trf_det DROP CONSTRAINT wb31_trf_det_stock_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh01_mast DROP CONSTRAINT wh01_mast_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trans DROP CONSTRAINT wh30_trans_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trans DROP CONSTRAINT wh30_trans_stock_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trans DROP CONSTRAINT wh30_trans_updated_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trans DROP CONSTRAINT wh30_trans_wb_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trans DROP CONSTRAINT wh30_trans_wh_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trf_hdr DROP CONSTRAINT wh30_trf_hdr_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trf_hdr DROP CONSTRAINT wh30_trf_hdr_from_wb_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trf_hdr DROP CONSTRAINT wh30_trf_hdr_from_wh_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trf_hdr DROP CONSTRAINT wh30_trf_hdr_to_wb_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trf_hdr DROP CONSTRAINT wh30_trf_hdr_to_wh_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_trf_hdr DROP CONSTRAINT wh30_trf_hdr_updated_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_trf_det DROP CONSTRAINT wh31_trf_det_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_trf_det DROP CONSTRAINT wh31_trf_det_from_wb_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_trf_det DROP CONSTRAINT wh31_trf_det_hdr_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_trf_det DROP CONSTRAINT wh31_trf_det_stock_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_trf_det DROP CONSTRAINT wh31_trf_det_to_wb_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_trf_det DROP CONSTRAINT wh31_trf_det_updated_by_fkey"

END FUNCTION

#+ Add indexes for all tables.
FUNCTION db_add_indexes()
    WHENEVER ERROR STOP

    EXECUTE IMMEDIATE "CREATE INDEX idx_cl30_supp ON cl30_trans(supp_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_dl30_cust ON dl30_trans(cust_id)"
    EXECUTE IMMEDIATE "CREATE UNIQUE INDEX gl01_acc_pkey ON gl01_acc(id, id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_pu30_det_hdr ON pu30_ord_det(hdr_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_pu30_hdr_supp ON pu30_ord_hdr(supp_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_pu31_det_hdr ON pu31_grn_det(hdr_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_pu31_hdr_supp ON pu31_grn_hdr(supp_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_pu32_det_hdr ON pu32_inv_det(hdr_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_pu32_hdr_supp ON pu32_inv_hdr(supp_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_sa30_det_hdr ON sa30_quo_det(hdr_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_sa30_hdr_cust ON sa30_quo_hdr(cust_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_sa31_det_hdr ON sa31_ord_det(hdr_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_sa31_hdr_cust ON sa31_ord_hdr(cust_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_sa32_det_hdr ON sa32_inv_det(hdr_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_sa32_hdr_cust ON sa32_inv_hdr(cust_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_sa33_det_hdr ON sa33_crn_det(hdr_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_sa33_hdr_cust ON sa33_crn_hdr(cust_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_st01_cat ON st01_mast(category_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_stock_uom_stock ON st04_stock_uom(stock_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_stock_uom_uom ON st04_stock_uom(uom_id)"
    EXECUTE IMMEDIATE "CREATE INDEX st30_idx_code_trans_date ON st30_trans(trans_date)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_wb_wh ON wb01_mast(wh_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_wh30_trans_dt ON wh30_trans(trans_date)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_wh30_trans_stock ON wh30_trans(stock_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_wh30_trans_type ON wh30_trans(trans_type)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_wh30_trans_wb ON wh30_trans(wb_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_wh30_trans_wh ON wh30_trans(wh_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_wh30_trf_hdr_dt ON wh30_trf_hdr(trans_date)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_wh30_trf_hdr_from ON wh30_trf_hdr(from_wh_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_wh30_trf_hdr_stat ON wh30_trf_hdr(status)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_wh30_trf_hdr_to ON wh30_trf_hdr(to_wh_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_wh31_trf_det_hdr ON wh31_trf_det(hdr_id)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_wh31_trf_det_stock ON wh31_trf_det(stock_id)"

END FUNCTION

#+ Populate new tables with fake data
FUNCTION db_populate_tables()
-- Error found while checking dependencies:
-- Recursivity found iterating on sy00_user, gl01_acc, gl01_acc

END FUNCTION


