#+ Database creation script for PostgreSQL 8.4 and higher
#+
#+ Note: This script is a helper script to create an empty database schema
#+       Adapt it to fit your needs

MAIN
    DATABASE xactapp_db

    CALL db_drop_constraints()
    CALL db_drop_tables()
    CALL db_create_tables()
    CALL db_add_indexes()
    CALL db_add_constraints()
END MAIN

#+ Create all tables in database.
FUNCTION db_create_tables()
    WHENEVER ERROR STOP

    EXECUTE IMMEDIATE "CREATE TABLE cl01_mast (
        id BIGSERIAL NOT NULL,
        acc_code VARCHAR(20) NOT NULL,
        supp_name VARCHAR(100) NOT NULL,
        address1 VARCHAR(100),
        address2 VARCHAR(100),
        address3 VARCHAR(100),
        phone VARCHAR(20),
        email VARCHAR(100),
        balance DECIMAL(12,2),
        status SMALLINT,
        created_at DATETIME YEAR TO FRACTION(4),
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE cl30_trans (
        id BIGSERIAL NOT NULL,
        acc_code VARCHAR(20) NOT NULL,
        date DATE NOT NULL,
        trans_type VARCHAR(10) NOT NULL,
        doc_type VARCHAR(10) NOT NULL,
        doc_no VARCHAR(20) NOT NULL,
        gross_val DECIMAL(12,2) NOT NULL,
        vat DECIMAL(12,2) NOT NULL,
        notes TEXT)"
    EXECUTE IMMEDIATE "CREATE TABLE dl01_mast (
        id BIGSERIAL NOT NULL,
        acc_code VARCHAR(20) NOT NULL,
        cust_name VARCHAR(100) NOT NULL,
        address1 VARCHAR(100),
        address2 VARCHAR(100),
        address3 VARCHAR(100),
        phone VARCHAR(20),
        email VARCHAR(100),
        balance DECIMAL(12,2),
        cr_limit DECIMAL(12,2),
        sales_ytd DECIMAL(12,2),
        cost_ytd DECIMAL(12,2),
        status SMALLINT,
        created_at DATETIME YEAR TO FRACTION(4),
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE dl30_trans (
        id BIGSERIAL NOT NULL,
        acc_code VARCHAR(20) NOT NULL,
        date DATE NOT NULL,
        trans_type VARCHAR(10) NOT NULL,
        doc_type VARCHAR(10) NOT NULL,
        doc_no VARCHAR(20) NOT NULL,
        gross_val DECIMAL(12,2) NOT NULL,
        vat DECIMAL(12,2) NOT NULL,
        notes TEXT)"
    EXECUTE IMMEDIATE "CREATE TABLE gl01_acc (
        id BIGSERIAL NOT NULL,
        acc_code VARCHAR(20) NOT NULL,
        acc_name VARCHAR(100) NOT NULL,
        acc_type VARCHAR(20) NOT NULL,
        parent_acc VARCHAR(20),
        status SMALLINT,
        created_at DATETIME YEAR TO FRACTION(4),
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE gl30_journals (
        id BIGSERIAL NOT NULL,
        jrn_no SERIAL NOT NULL,
        date DATE NOT NULL,
        source_module VARCHAR(20) NOT NULL,
        doc_type VARCHAR(10),
        doc_no VARCHAR(20),
        description TEXT,
        status SMALLINT,
        created_at DATETIME YEAR TO FRACTION(4),
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE gl31_lines (
        id BIGSERIAL NOT NULL,
        jrn_no INTEGER NOT NULL,
        line_no INTEGER NOT NULL,
        acc_code VARCHAR(20) NOT NULL,
        debit DECIMAL(12,2),
        credit DECIMAL(12,2),
        notes TEXT)"
    EXECUTE IMMEDIATE "CREATE TABLE payt30_hdr (
        id BIGSERIAL NOT NULL,
        doc_no SERIAL NOT NULL,
        pay_type VARCHAR(10) NOT NULL,
        acc_code VARCHAR(20) NOT NULL,
        date DATE NOT NULL,
        method VARCHAR(20),
        bank_account VARCHAR(50),
        amount DECIMAL(12,2) NOT NULL,
        notes TEXT,
        status SMALLINT,
        created_at DATETIME YEAR TO FRACTION(4),
        created_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE payt31_det (
        id BIGSERIAL NOT NULL,
        hdr_id BIGINT NOT NULL,
        invoice_no VARCHAR(20) NOT NULL,
        alloc_amt DECIMAL(12,2) NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE pu30_det (
        id BIGSERIAL NOT NULL,
        doc_no INTEGER NOT NULL,
        item_no INTEGER NOT NULL,
        stock_code VARCHAR(20) NOT NULL,
        batch_id VARCHAR(30),
        expiry_date DATE,
        qty DECIMAL(12,2) NOT NULL,
        unit_cost DECIMAL(12,2),
        total DECIMAL(12,2))"
    EXECUTE IMMEDIATE "CREATE TABLE pu30_hdr (
        id BIGSERIAL NOT NULL,
        doc_no SERIAL NOT NULL,
        acc_code VARCHAR(20) NOT NULL,
        date DATE NOT NULL,
        total_value DECIMAL(12,2),
        vat DECIMAL(12,2),
        status SMALLINT,
        created_at DATETIME YEAR TO FRACTION(4),
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE pu31_hdr (
        id BIGSERIAL NOT NULL,
        doc_no SERIAL NOT NULL,
        acc_code VARCHAR(20) NOT NULL,
        date DATE NOT NULL,
        total_value DECIMAL(12,2),
        vat DECIMAL(12,2),
        status SMALLINT,
        created_at DATETIME YEAR TO FRACTION(4),
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE sa30_det (
        id BIGSERIAL NOT NULL,
        doc_no INTEGER NOT NULL,
        item_no INTEGER NOT NULL,
        stock_code VARCHAR(20) NOT NULL,
        batch_id VARCHAR(30),
        qty DECIMAL(12,2) NOT NULL,
        unit_cost DECIMAL(12,2),
        unit_sell DECIMAL(12,2),
        disc DECIMAL(12,2),
        total DECIMAL(12,2))"
    EXECUTE IMMEDIATE "CREATE TABLE sa30_hdr (
        id BIGSERIAL NOT NULL,
        doc_no SERIAL NOT NULL,
        acc_code VARCHAR(20) NOT NULL,
        date DATE NOT NULL,
        total_excl DECIMAL(12,2),
        vat DECIMAL(12,2),
        total_cost DECIMAL(12,2),
        status SMALLINT,
        created_at DATETIME YEAR TO FRACTION(4),
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE sa31_hdr (
        id BIGSERIAL NOT NULL,
        doc_no SERIAL NOT NULL,
        acc_code VARCHAR(20) NOT NULL,
        date DATE NOT NULL,
        total_excl DECIMAL(12,2),
        vat DECIMAL(12,2),
        total_cost DECIMAL(12,2),
        status SMALLINT,
        created_at DATETIME YEAR TO FRACTION(4),
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE sa32_hdr (
        id BIGSERIAL NOT NULL,
        doc_no SERIAL NOT NULL,
        acc_code VARCHAR(20) NOT NULL,
        date DATE NOT NULL,
        total_excl DECIMAL(12,2),
        vat DECIMAL(12,2),
        total_cost DECIMAL(12,2),
        status SMALLINT,
        created_at DATETIME YEAR TO FRACTION(4),
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE sa33_hdr (
        id BIGSERIAL NOT NULL,
        doc_no SERIAL NOT NULL,
        acc_code VARCHAR(20) NOT NULL,
        date DATE NOT NULL,
        total_excl DECIMAL(12,2),
        vat DECIMAL(12,2),
        total_cost DECIMAL(12,2),
        status SMALLINT,
        created_at DATETIME YEAR TO FRACTION(4),
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE st01_mast (
        id BIGSERIAL NOT NULL,
        stock_code VARCHAR(20) NOT NULL,
        description VARCHAR(150) NOT NULL,
        barcode VARCHAR(50),
        batch_control BOOLEAN,
        category_id BIGINT,
        cost DECIMAL(12,2),
        selling_price DECIMAL(12,2),
        stock_on_hand DECIMAL(12,2),
        total_purch DECIMAL(12,2),
        total_sales DECIMAL(12,2),
        status SMALLINT,
        created_at DATETIME YEAR TO FRACTION(4),
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE st30_trans (
        id BIGSERIAL NOT NULL,
        stock_code VARCHAR(20) NOT NULL,
        date DATE NOT NULL,
        trans_type VARCHAR(10) NOT NULL,
        direction VARCHAR(3) NOT NULL,
        qty DECIMAL(12,2) NOT NULL,
        unit_cost DECIMAL(12,2),
        unit_sell DECIMAL(12,2),
        batch_id VARCHAR(30),
        expiry_date DATE,
        doc_type VARCHAR(10) NOT NULL,
        doc_no VARCHAR(20) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE st_cat (
        id BIGSERIAL NOT NULL,
        cat_code VARCHAR(20) NOT NULL,
        cat_name VARCHAR(100) NOT NULL,
        description TEXT,
        status SMALLINT,
        created_at DATETIME YEAR TO FRACTION(4),
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE st_tag_link (
        id BIGSERIAL NOT NULL,
        stock_id BIGINT NOT NULL,
        tag_id BIGINT NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE sy00_user (
        id BIGSERIAL NOT NULL,
        username VARCHAR(50) NOT NULL,
        full_name VARCHAR(100) NOT NULL,
        phone VARCHAR(20),
        email VARCHAR(100),
        password VARCHAR(255) NOT NULL,
        status SMALLINT,
        role_id BIGINT,
        created_at DATETIME YEAR TO FRACTION(4),
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE sy02_logs (
        id BIGSERIAL NOT NULL,
        user_id BIGINT,
        level VARCHAR(10) NOT NULL,
        action VARCHAR(100) NOT NULL,
        details TEXT,
        created_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE sy03_sett (
        id BIGSERIAL NOT NULL,
        sett_key VARCHAR(50) NOT NULL,
        sett_value TEXT NOT NULL,
        description TEXT,
        updated_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE sy04_role (
        id BIGSERIAL NOT NULL,
        role_name VARCHAR(50) NOT NULL,
        status SMALLINT,
        created_at DATETIME YEAR TO FRACTION(4),
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE sy05_perm (
        id BIGSERIAL NOT NULL,
        perm_name VARCHAR(100) NOT NULL,
        description TEXT,
        status SMALLINT,
        created_at DATETIME YEAR TO FRACTION(4),
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4),
        created_by BIGINT,
        updated_by BIGINT)"
    EXECUTE IMMEDIATE "CREATE TABLE sy06_role_perm (
        id BIGSERIAL NOT NULL,
        role_id BIGINT NOT NULL,
        perm_id BIGINT NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE wb01_mast (
        id BIGSERIAL NOT NULL,
        wb_code VARCHAR(20) NOT NULL,
        wh_id BIGINT NOT NULL,
        description VARCHAR(100),
        status SMALLINT,
        created_at DATETIME YEAR TO FRACTION(4),
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE wb30_hdr (
        id BIGSERIAL NOT NULL,
        trans_no SERIAL NOT NULL,
        wb_from BIGINT NOT NULL,
        wb_to BIGINT NOT NULL,
        trans_date DATE NOT NULL,
        created_by BIGINT,
        created_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE wb31_det (
        id BIGSERIAL NOT NULL,
        hdr_id BIGINT NOT NULL,
        stock_code VARCHAR(20) NOT NULL,
        qty DECIMAL(12,2) NOT NULL,
        batch_id VARCHAR(30),
        expiry_date DATE)"
    EXECUTE IMMEDIATE "CREATE TABLE wh01_mast (
        id BIGSERIAL NOT NULL,
        wh_code VARCHAR(20) NOT NULL,
        wh_name VARCHAR(100) NOT NULL,
        location VARCHAR(100),
        status SMALLINT,
        created_at DATETIME YEAR TO FRACTION(4),
        updated_at DATETIME YEAR TO FRACTION(4),
        deleted_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE wh30_hdr (
        id BIGSERIAL NOT NULL,
        trans_no SERIAL NOT NULL,
        from_wh BIGINT NOT NULL,
        to_wh BIGINT NOT NULL,
        trans_date DATE NOT NULL,
        status SMALLINT,
        created_by BIGINT,
        created_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE wh31_det (
        id BIGSERIAL NOT NULL,
        hdr_id BIGINT NOT NULL,
        stock_code VARCHAR(20) NOT NULL,
        qty DECIMAL(12,2) NOT NULL,
        unit_cost DECIMAL(12,2),
        batch_id VARCHAR(30),
        expiry_date DATE)"
    EXECUTE IMMEDIATE "CREATE TABLE wh_cat_perm (
        id BIGSERIAL NOT NULL,
        wh_id BIGINT NOT NULL,
        cat_id BIGINT NOT NULL,
        created_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE wh_tag (
        id BIGSERIAL NOT NULL,
        tag_code VARCHAR(20) NOT NULL,
        tag_name VARCHAR(100) NOT NULL,
        description TEXT,
        status SMALLINT,
        created_at DATETIME YEAR TO FRACTION(4))"
    EXECUTE IMMEDIATE "CREATE TABLE wh_tag_link (
        id BIGSERIAL NOT NULL,
        wh_id BIGINT NOT NULL,
        tag_id BIGINT NOT NULL)"

END FUNCTION

#+ Drop all tables from database.
FUNCTION db_drop_tables()
    WHENEVER ERROR CONTINUE

    EXECUTE IMMEDIATE "DROP TABLE cl01_mast"
    EXECUTE IMMEDIATE "DROP TABLE cl30_trans"
    EXECUTE IMMEDIATE "DROP TABLE dl01_mast"
    EXECUTE IMMEDIATE "DROP TABLE dl30_trans"
    EXECUTE IMMEDIATE "DROP TABLE gl01_acc"
    EXECUTE IMMEDIATE "DROP TABLE gl30_journals"
    EXECUTE IMMEDIATE "DROP TABLE gl31_lines"
    EXECUTE IMMEDIATE "DROP TABLE payt30_hdr"
    EXECUTE IMMEDIATE "DROP TABLE payt31_det"
    EXECUTE IMMEDIATE "DROP TABLE pu30_det"
    EXECUTE IMMEDIATE "DROP TABLE pu30_hdr"
    EXECUTE IMMEDIATE "DROP TABLE pu31_hdr"
    EXECUTE IMMEDIATE "DROP TABLE sa30_det"
    EXECUTE IMMEDIATE "DROP TABLE sa30_hdr"
    EXECUTE IMMEDIATE "DROP TABLE sa31_hdr"
    EXECUTE IMMEDIATE "DROP TABLE sa32_hdr"
    EXECUTE IMMEDIATE "DROP TABLE sa33_hdr"
    EXECUTE IMMEDIATE "DROP TABLE st01_mast"
    EXECUTE IMMEDIATE "DROP TABLE st30_trans"
    EXECUTE IMMEDIATE "DROP TABLE st_cat"
    EXECUTE IMMEDIATE "DROP TABLE st_tag_link"
    EXECUTE IMMEDIATE "DROP TABLE sy00_user"
    EXECUTE IMMEDIATE "DROP TABLE sy02_logs"
    EXECUTE IMMEDIATE "DROP TABLE sy03_sett"
    EXECUTE IMMEDIATE "DROP TABLE sy04_role"
    EXECUTE IMMEDIATE "DROP TABLE sy05_perm"
    EXECUTE IMMEDIATE "DROP TABLE sy06_role_perm"
    EXECUTE IMMEDIATE "DROP TABLE wb01_mast"
    EXECUTE IMMEDIATE "DROP TABLE wb30_hdr"
    EXECUTE IMMEDIATE "DROP TABLE wb31_det"
    EXECUTE IMMEDIATE "DROP TABLE wh01_mast"
    EXECUTE IMMEDIATE "DROP TABLE wh30_hdr"
    EXECUTE IMMEDIATE "DROP TABLE wh31_det"
    EXECUTE IMMEDIATE "DROP TABLE wh_cat_perm"
    EXECUTE IMMEDIATE "DROP TABLE wh_tag"
    EXECUTE IMMEDIATE "DROP TABLE wh_tag_link"

END FUNCTION

#+ Add constraints for all tables.
FUNCTION db_add_constraints()
    WHENEVER ERROR STOP

    EXECUTE IMMEDIATE "ALTER TABLE cl01_mast ADD CONSTRAINT cl01_mast_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE cl01_mast ADD CONSTRAINT cl01_mast_acc_code_key
        UNIQUE (acc_code)"
    EXECUTE IMMEDIATE "ALTER TABLE cl30_trans ADD CONSTRAINT cl30_trans_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE dl01_mast ADD CONSTRAINT dl01_mast_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE dl01_mast ADD CONSTRAINT dl01_mast_acc_code_key
        UNIQUE (acc_code)"
    EXECUTE IMMEDIATE "ALTER TABLE dl30_trans ADD CONSTRAINT dl30_trans_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE gl01_acc ADD CONSTRAINT gl01_acc_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE gl01_acc ADD CONSTRAINT gl01_acc_acc_code_key
        UNIQUE (acc_code)"
    EXECUTE IMMEDIATE "ALTER TABLE gl30_journals ADD CONSTRAINT gl30_journals_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE gl30_journals ADD CONSTRAINT gl30_journals_jrn_no_key
        UNIQUE (jrn_no)"
    EXECUTE IMMEDIATE "ALTER TABLE gl31_lines ADD CONSTRAINT gl31_lines_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE gl31_lines ADD CONSTRAINT gl31_lines_jrn_no_line_no_key
        UNIQUE (jrn_no, line_no)"
    EXECUTE IMMEDIATE "ALTER TABLE payt30_hdr ADD CONSTRAINT payt30_hdr_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE payt30_hdr ADD CONSTRAINT payt30_hdr_doc_no_key
        UNIQUE (doc_no)"
    EXECUTE IMMEDIATE "ALTER TABLE payt31_det ADD CONSTRAINT payt31_det_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_det ADD CONSTRAINT pu30_det_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_det ADD CONSTRAINT pu30_det_doc_no_item_no_key
        UNIQUE (doc_no, item_no)"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_hdr ADD CONSTRAINT pu30_hdr_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_hdr ADD CONSTRAINT pu30_hdr_doc_no_key
        UNIQUE (doc_no)"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_det ADD CONSTRAINT sa30_det_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_det ADD CONSTRAINT sa30_det_doc_no_item_no_key
        UNIQUE (doc_no, item_no)"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_hdr ADD CONSTRAINT sa30_hdr_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_hdr ADD CONSTRAINT sa30_hdr_doc_no_key
        UNIQUE (doc_no)"
    EXECUTE IMMEDIATE "ALTER TABLE st01_mast ADD CONSTRAINT st01_mast_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE st01_mast ADD CONSTRAINT st01_mast_stock_code_key
        UNIQUE (stock_code)"
    EXECUTE IMMEDIATE "ALTER TABLE st30_trans ADD CONSTRAINT st30_trans_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE st_cat ADD CONSTRAINT st_cat_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE st_cat ADD CONSTRAINT st_cat_cat_code_key
        UNIQUE (cat_code)"
    EXECUTE IMMEDIATE "ALTER TABLE st_tag_link ADD CONSTRAINT st_tag_link_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE st_tag_link ADD CONSTRAINT st_tag_link_stock_id_tag_id_key
        UNIQUE (stock_id, tag_id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy00_user ADD CONSTRAINT sy00_user_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy00_user ADD CONSTRAINT sy00_user_username_key
        UNIQUE (username)"
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
    EXECUTE IMMEDIATE "ALTER TABLE wb01_mast ADD CONSTRAINT wb01_mast_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wb01_mast ADD CONSTRAINT wb01_mast_wh_id_wb_code_key
        UNIQUE (wh_id, wb_code)"
    EXECUTE IMMEDIATE "ALTER TABLE wb30_hdr ADD CONSTRAINT wb30_hdr_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wb30_hdr ADD CONSTRAINT wb30_hdr_trans_no_key
        UNIQUE (trans_no)"
    EXECUTE IMMEDIATE "ALTER TABLE wb31_det ADD CONSTRAINT wb31_det_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh01_mast ADD CONSTRAINT wh01_mast_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh01_mast ADD CONSTRAINT wh01_mast_wh_code_key
        UNIQUE (wh_code)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_hdr ADD CONSTRAINT wh30_hdr_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_hdr ADD CONSTRAINT wh30_hdr_trans_no_key
        UNIQUE (trans_no)"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_det ADD CONSTRAINT wh31_det_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh_cat_perm ADD CONSTRAINT wh_cat_perm_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh_cat_perm ADD CONSTRAINT wh_cat_perm_wh_id_cat_id_key
        UNIQUE (wh_id, cat_id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh_tag ADD CONSTRAINT wh_tag_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh_tag ADD CONSTRAINT wh_tag_tag_code_key
        UNIQUE (tag_code)"
    EXECUTE IMMEDIATE "ALTER TABLE wh_tag_link ADD CONSTRAINT wh_tag_link_pkey
        PRIMARY KEY (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh_tag_link ADD CONSTRAINT wh_tag_link_wh_id_tag_id_key
        UNIQUE (wh_id, tag_id)"
    EXECUTE IMMEDIATE "ALTER TABLE cl30_trans ADD CONSTRAINT cl30_trans_acc_code_fkey
        FOREIGN KEY (acc_code)
        REFERENCES cl01_mast (acc_code)"
    EXECUTE IMMEDIATE "ALTER TABLE dl30_trans ADD CONSTRAINT dl30_trans_acc_code_fkey
        FOREIGN KEY (acc_code)
        REFERENCES dl01_mast (acc_code)"
    EXECUTE IMMEDIATE "ALTER TABLE gl31_lines ADD CONSTRAINT gl31_lines_acc_code_fkey
        FOREIGN KEY (acc_code)
        REFERENCES gl01_acc (acc_code)"
    EXECUTE IMMEDIATE "ALTER TABLE gl31_lines ADD CONSTRAINT gl31_lines_jrn_no_fkey
        FOREIGN KEY (jrn_no)
        REFERENCES gl30_journals (jrn_no)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE payt30_hdr ADD CONSTRAINT payt30_hdr_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE payt31_det ADD CONSTRAINT payt31_det_hdr_id_fkey
        FOREIGN KEY (hdr_id)
        REFERENCES payt30_hdr (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_det ADD CONSTRAINT pu30_det_doc_no_fkey
        FOREIGN KEY (doc_no)
        REFERENCES pu30_hdr (doc_no)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_det ADD CONSTRAINT pu30_det_stock_code_fkey
        FOREIGN KEY (stock_code)
        REFERENCES st01_mast (stock_code)"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_hdr ADD CONSTRAINT pu30_hdr_acc_code_fkey
        FOREIGN KEY (acc_code)
        REFERENCES cl01_mast (acc_code)"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_hdr ADD CONSTRAINT pu31_hdr_acc_fk
        FOREIGN KEY (acc_code)
        REFERENCES cl01_mast (acc_code)"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_det ADD CONSTRAINT sa30_det_doc_no_fkey
        FOREIGN KEY (doc_no)
        REFERENCES sa30_hdr (doc_no)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_det ADD CONSTRAINT sa30_det_stock_code_fkey
        FOREIGN KEY (stock_code)
        REFERENCES st01_mast (stock_code)"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_hdr ADD CONSTRAINT sa30_hdr_acc_code_fkey
        FOREIGN KEY (acc_code)
        REFERENCES dl01_mast (acc_code)"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_hdr ADD CONSTRAINT sa31_hdr_acc_fk
        FOREIGN KEY (acc_code)
        REFERENCES dl01_mast (acc_code)"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_hdr ADD CONSTRAINT sa32_hdr_acc_fk
        FOREIGN KEY (acc_code)
        REFERENCES dl01_mast (acc_code)"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_hdr ADD CONSTRAINT sa33_hdr_acc_fk
        FOREIGN KEY (acc_code)
        REFERENCES dl01_mast (acc_code)"
    EXECUTE IMMEDIATE "ALTER TABLE st01_mast ADD CONSTRAINT st01_mast_category_id_fkey
        FOREIGN KEY (category_id)
        REFERENCES st_cat (id)"
    EXECUTE IMMEDIATE "ALTER TABLE st30_trans ADD CONSTRAINT st30_trans_stock_code_fkey
        FOREIGN KEY (stock_code)
        REFERENCES st01_mast (stock_code)"
    EXECUTE IMMEDIATE "ALTER TABLE st_tag_link ADD CONSTRAINT st_tag_link_stock_id_fkey
        FOREIGN KEY (stock_id)
        REFERENCES st01_mast (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE st_tag_link ADD CONSTRAINT st_tag_link_tag_id_fkey
        FOREIGN KEY (tag_id)
        REFERENCES wh_tag (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE sy00_user ADD CONSTRAINT sy00_user_role_id_fkey
        FOREIGN KEY (role_id)
        REFERENCES sy04_role (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy02_logs ADD CONSTRAINT sy02_logs_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy05_perm ADD CONSTRAINT sy05_perm_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy05_perm ADD CONSTRAINT sy05_perm_updated_by_fkey
        FOREIGN KEY (updated_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE sy06_role_perm ADD CONSTRAINT sy06_role_perm_perm_id_fkey
        FOREIGN KEY (perm_id)
        REFERENCES sy05_perm (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE sy06_role_perm ADD CONSTRAINT sy06_role_perm_role_id_fkey
        FOREIGN KEY (role_id)
        REFERENCES sy04_role (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE wb01_mast ADD CONSTRAINT wb01_mast_wh_id_fkey
        FOREIGN KEY (wh_id)
        REFERENCES wh01_mast (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE wb30_hdr ADD CONSTRAINT wb30_hdr_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wb30_hdr ADD CONSTRAINT wb30_hdr_wb_from_fkey
        FOREIGN KEY (wb_from)
        REFERENCES wb01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wb30_hdr ADD CONSTRAINT wb30_hdr_wb_to_fkey
        FOREIGN KEY (wb_to)
        REFERENCES wb01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wb31_det ADD CONSTRAINT wb31_det_hdr_id_fkey
        FOREIGN KEY (hdr_id)
        REFERENCES wb30_hdr (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE wb31_det ADD CONSTRAINT wb31_det_stock_code_fkey
        FOREIGN KEY (stock_code)
        REFERENCES st01_mast (stock_code)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_hdr ADD CONSTRAINT wh30_hdr_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES sy00_user (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_hdr ADD CONSTRAINT wh30_hdr_from_wh_fkey
        FOREIGN KEY (from_wh)
        REFERENCES wh01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_hdr ADD CONSTRAINT wh30_hdr_to_wh_fkey
        FOREIGN KEY (to_wh)
        REFERENCES wh01_mast (id)"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_det ADD CONSTRAINT wh31_det_hdr_id_fkey
        FOREIGN KEY (hdr_id)
        REFERENCES wh30_hdr (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_det ADD CONSTRAINT wh31_det_stock_code_fkey
        FOREIGN KEY (stock_code)
        REFERENCES st01_mast (stock_code)"
    EXECUTE IMMEDIATE "ALTER TABLE wh_cat_perm ADD CONSTRAINT wh_cat_perm_cat_id_fkey
        FOREIGN KEY (cat_id)
        REFERENCES st_cat (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE wh_cat_perm ADD CONSTRAINT wh_cat_perm_wh_id_fkey
        FOREIGN KEY (wh_id)
        REFERENCES wh01_mast (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE wh_tag_link ADD CONSTRAINT wh_tag_link_tag_id_fkey
        FOREIGN KEY (tag_id)
        REFERENCES wh_tag (id)
        ON DELETE CASCADE"
    EXECUTE IMMEDIATE "ALTER TABLE wh_tag_link ADD CONSTRAINT wh_tag_link_wh_id_fkey
        FOREIGN KEY (wh_id)
        REFERENCES wh01_mast (id)
        ON DELETE CASCADE"

END FUNCTION

#+ Drop all constraints from all tables.
FUNCTION db_drop_constraints()
    WHENEVER ERROR CONTINUE

    EXECUTE IMMEDIATE "ALTER TABLE cl30_trans DROP CONSTRAINT cl30_trans_acc_code_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE dl30_trans DROP CONSTRAINT dl30_trans_acc_code_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE gl31_lines DROP CONSTRAINT gl31_lines_acc_code_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE gl31_lines DROP CONSTRAINT gl31_lines_jrn_no_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE payt30_hdr DROP CONSTRAINT payt30_hdr_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE payt31_det DROP CONSTRAINT payt31_det_hdr_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_det DROP CONSTRAINT pu30_det_doc_no_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_det DROP CONSTRAINT pu30_det_stock_code_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu30_hdr DROP CONSTRAINT pu30_hdr_acc_code_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE pu31_hdr DROP CONSTRAINT pu31_hdr_acc_fk"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_det DROP CONSTRAINT sa30_det_doc_no_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_det DROP CONSTRAINT sa30_det_stock_code_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa30_hdr DROP CONSTRAINT sa30_hdr_acc_code_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sa31_hdr DROP CONSTRAINT sa31_hdr_acc_fk"
    EXECUTE IMMEDIATE "ALTER TABLE sa32_hdr DROP CONSTRAINT sa32_hdr_acc_fk"
    EXECUTE IMMEDIATE "ALTER TABLE sa33_hdr DROP CONSTRAINT sa33_hdr_acc_fk"
    EXECUTE IMMEDIATE "ALTER TABLE st01_mast DROP CONSTRAINT st01_mast_category_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE st30_trans DROP CONSTRAINT st30_trans_stock_code_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE st_tag_link DROP CONSTRAINT st_tag_link_stock_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE st_tag_link DROP CONSTRAINT st_tag_link_tag_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sy00_user DROP CONSTRAINT sy00_user_role_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sy02_logs DROP CONSTRAINT sy02_logs_user_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sy05_perm DROP CONSTRAINT sy05_perm_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sy05_perm DROP CONSTRAINT sy05_perm_updated_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sy06_role_perm DROP CONSTRAINT sy06_role_perm_perm_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE sy06_role_perm DROP CONSTRAINT sy06_role_perm_role_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wb01_mast DROP CONSTRAINT wb01_mast_wh_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wb30_hdr DROP CONSTRAINT wb30_hdr_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wb30_hdr DROP CONSTRAINT wb30_hdr_wb_from_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wb30_hdr DROP CONSTRAINT wb30_hdr_wb_to_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wb31_det DROP CONSTRAINT wb31_det_hdr_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wb31_det DROP CONSTRAINT wb31_det_stock_code_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_hdr DROP CONSTRAINT wh30_hdr_created_by_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_hdr DROP CONSTRAINT wh30_hdr_from_wh_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh30_hdr DROP CONSTRAINT wh30_hdr_to_wh_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_det DROP CONSTRAINT wh31_det_hdr_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh31_det DROP CONSTRAINT wh31_det_stock_code_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh_cat_perm DROP CONSTRAINT wh_cat_perm_cat_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh_cat_perm DROP CONSTRAINT wh_cat_perm_wh_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh_tag_link DROP CONSTRAINT wh_tag_link_tag_id_fkey"
    EXECUTE IMMEDIATE "ALTER TABLE wh_tag_link DROP CONSTRAINT wh_tag_link_wh_id_fkey"

END FUNCTION

#+ Add indexes for all tables.
FUNCTION db_add_indexes()
    WHENEVER ERROR STOP

    EXECUTE IMMEDIATE "CREATE INDEX cl30_idx_acc_date ON cl30_trans(acc_code, date)"
    EXECUTE IMMEDIATE "CREATE INDEX dl30_idx_acc_date ON dl30_trans(acc_code, date)"
    EXECUTE IMMEDIATE "CREATE INDEX st30_idx_code_date ON st30_trans(stock_code, date)"

END FUNCTION


