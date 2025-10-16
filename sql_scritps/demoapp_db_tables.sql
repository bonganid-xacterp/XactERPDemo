-- =========================================================
-- ERP DEMO - PostgreSQL Schema v1.3
-- Fully DS-compliant schema (System, Debtors, Creditors, Stock,
-- Warehousing/Bins, Sales, Purchases, GL, Payments)
-- =========================================================
BEGIN;
SET CONSTRAINTS ALL DEFERRED;

CREATE DATABASE demoapp_db
  WITH OWNER = postgres
  ENCODING = 'UTF8'
  LC_COLLATE = 'en_US.utf8'
  LC_CTYPE = 'en_US.utf8'
  TEMPLATE template0;


-- ===== SYSTEM (sy) =====
CREATE TABLE IF NOT EXISTS sy04_role (
  id BIGSERIAL PRIMARY KEY,
  role_name VARCHAR(50) UNIQUE NOT NULL,
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sy00_user (
  id BIGSERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  phone VARCHAR(20),
  email VARCHAR(100),
  password VARCHAR(255) NOT NULL,
  status SMALLINT DEFAULT 1,
  role_id BIGINT REFERENCES sy04_role(id),
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sy01_sess (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  uuid UUID DEFAULT gen_random_uuid(),
  login_time TIMESTAMP DEFAULT now(),
  logout_time TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sy02_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  level VARCHAR(10) NOT NULL,
  action VARCHAR(100) NOT NULL,
  details TEXT,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sy03_sett (
  id BIGSERIAL PRIMARY KEY,
  sett_key VARCHAR(50) UNIQUE NOT NULL,
  sett_value TEXT NOT NULL,
  description TEXT,
  updated_at TIMESTAMP DEFAULT now(),
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sy05_perm (
  id BIGSERIAL PRIMARY KEY,
  perm_name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sy06_role_perm (
  id BIGSERIAL PRIMARY KEY,
  role_id BIGINT NOT NULL REFERENCES sy04_role(id) ON DELETE CASCADE,
  perm_id BIGINT NOT NULL REFERENCES sy05_perm(id) ON DELETE CASCADE,
  UNIQUE(role_id, perm_id)
);

CREATE TABLE IF NOT EXISTS sy40_hist (
  id BIGSERIAL PRIMARY KEY,
  entity VARCHAR(30) NOT NULL,
  entity_id BIGINT,
  action VARCHAR(20) NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  changed_at TIMESTAMP DEFAULT now()
);

-- ===== DEBTORS (dl) =====
CREATE TABLE IF NOT EXISTS dl01_mast (
  id BIGSERIAL PRIMARY KEY,
  acc_code VARCHAR(20) UNIQUE NOT NULL,
  cust_name VARCHAR(100) NOT NULL,
  address1 VARCHAR(100), address2 VARCHAR(100), address3 VARCHAR(100),
  phone VARCHAR(20), email VARCHAR(100),
  balance NUMERIC(12,2) DEFAULT 0,
  cr_limit NUMERIC(12,2) DEFAULT 0,
  sales_ytd NUMERIC(12,2) DEFAULT 0,
  cost_ytd NUMERIC(12,2) DEFAULT 0,
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS dl30_trans (
  id BIGSERIAL PRIMARY KEY,
  acc_code VARCHAR(20) NOT NULL REFERENCES dl01_mast(acc_code) ON DELETE RESTRICT,
  date DATE NOT NULL,
  trans_type VARCHAR(10) NOT NULL,   -- INV/CRN/PAY
  doc_type VARCHAR(10) NOT NULL,     -- sa32/sa33/PAYT
  doc_no VARCHAR(20) NOT NULL,
  gross_val NUMERIC(12,2) NOT NULL,
  vat NUMERIC(12,2) NOT NULL,
  notes TEXT
);
CREATE INDEX IF NOT EXISTS dl30_idx_acc_date ON dl30_trans(acc_code, date);

CREATE TABLE IF NOT EXISTS dl40_hist (
  id BIGSERIAL PRIMARY KEY,
  debtor_id BIGINT REFERENCES dl01_mast(id) ON DELETE SET NULL,
  action VARCHAR(20) NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  changed_at TIMESTAMP DEFAULT now()
);

-- ===== CREDITORS (cl) =====
CREATE TABLE IF NOT EXISTS cl01_mast (
  id BIGSERIAL PRIMARY KEY,
  acc_code VARCHAR(20) UNIQUE NOT NULL,
  supp_name VARCHAR(100) NOT NULL,
  address1 VARCHAR(100), address2 VARCHAR(100), address3 VARCHAR(100),
  phone VARCHAR(20), email VARCHAR(100),
  balance NUMERIC(12,2) DEFAULT 0,
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS cl30_trans (
  id BIGSERIAL PRIMARY KEY,
  acc_code VARCHAR(20) NOT NULL REFERENCES cl01_mast(acc_code) ON DELETE RESTRICT,
  date DATE NOT NULL,
  trans_type VARCHAR(10) NOT NULL,   -- PO/PINV/PAY
  doc_type VARCHAR(10) NOT NULL,     -- pu30/pu31/PAYT
  doc_no VARCHAR(20) NOT NULL,
  gross_val NUMERIC(12,2) NOT NULL,
  vat NUMERIC(12,2) NOT NULL,
  notes TEXT
);
CREATE INDEX IF NOT EXISTS cl30_idx_acc_date ON cl30_trans(acc_code, date);

CREATE TABLE IF NOT EXISTS cl40_hist (
  id BIGSERIAL PRIMARY KEY,
  creditor_id BIGINT REFERENCES cl01_mast(id) ON DELETE SET NULL,
  action VARCHAR(20) NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  changed_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS st01_mast (
  id BIGSERIAL PRIMARY KEY,
  stock_code VARCHAR(20) UNIQUE NOT NULL,
  description VARCHAR(150) NOT NULL,
  barcode VARCHAR(50),
  batch_control BOOLEAN DEFAULT FALSE,
  category_id BIGINT REFERENCES st02_cat(id) ON DELETE SET NULL,
  cost NUMERIC(12,2) DEFAULT 0,
  selling_price NUMERIC(12,2) DEFAULT 0,
  stock_on_hand NUMERIC(12,2) DEFAULT 0,
  total_purch NUMERIC(12,2) DEFAULT 0,
  total_sales NUMERIC(12,2) DEFAULT 0,
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS st30_trans (
  id BIGSERIAL PRIMARY KEY,
  stock_code VARCHAR(20) NOT NULL REFERENCES st01_mast(stock_code) ON DELETE RESTRICT,
  date DATE NOT NULL,
  trans_type VARCHAR(10) NOT NULL,  -- SALE/PURC/ADJ
  direction VARCHAR(3) NOT NULL,    -- IN/OUT
  qty NUMERIC(12,2) NOT NULL,
  unit_cost NUMERIC(12,2) DEFAULT 0,
  unit_sell NUMERIC(12,2) DEFAULT 0,
  batch_id VARCHAR(30),
  expiry_date DATE,
  doc_type VARCHAR(10) NOT NULL,
  doc_no VARCHAR(20) NOT NULL,
  notes TEXT
);
CREATE INDEX IF NOT EXISTS st30_idx_code_date ON st30_trans(stock_code, date);

-- ===== WAREHOUSES (wh) =====
CREATE TABLE IF NOT EXISTS wh01_mast (
  id BIGSERIAL PRIMARY KEY,
  wh_code VARCHAR(20) UNIQUE NOT NULL,
  wh_name VARCHAR(100) NOT NULL,
  location VARCHAR(100),
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

-- Tags that can be applied to warehouses and stock (safety/compliance)
CREATE TABLE IF NOT EXISTS wh30_tag (
  id BIGSERIAL PRIMARY KEY,
  tag_code VARCHAR(20) UNIQUE NOT NULL,
  tag_name VARCHAR(100) NOT NULL,
  description TEXT,
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

-- Link tags to warehouses
CREATE TABLE IF NOT EXISTS wh30_tag_link (
  id BIGSERIAL PRIMARY KEY,
  wh_id BIGINT NOT NULL REFERENCES wh01_mast(id) ON DELETE CASCADE,
  tag_id BIGINT NOT NULL REFERENCES wh30_tag(id) ON DELETE CASCADE,
  UNIQUE(wh_id, tag_id)
);

-- Link tags to stock items
CREATE TABLE IF NOT EXISTS st30_tag_link (
  id BIGSERIAL PRIMARY KEY,
  stock_id BIGINT NOT NULL REFERENCES st01_mast(id) ON DELETE CASCADE,
  tag_id BIGINT NOT NULL REFERENCES wh30_tag(id) ON DELETE CASCADE,
  UNIQUE(stock_id, tag_id)
);

-- Category permissions per warehouse
CREATE TABLE IF NOT EXISTS wh30_cat_perm (
  id BIGSERIAL PRIMARY KEY,
  wh_id BIGINT NOT NULL REFERENCES wh01_mast(id) ON DELETE CASCADE,
  cat_id BIGINT NOT NULL REFERENCES st02_cat(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT now(),
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  UNIQUE(wh_id, cat_id)
);

-- Warehouse Transfers (Header/Detail)
CREATE TABLE IF NOT EXISTS wh30_hdr (
  id BIGSERIAL PRIMARY KEY,
  trans_no SERIAL UNIQUE,
  from_wh BIGINT NOT NULL REFERENCES wh01_mast(id),
  to_wh BIGINT NOT NULL REFERENCES wh01_mast(id),
  trans_date DATE NOT NULL,
  status SMALLINT DEFAULT 1,
  created_by BIGINT REFERENCES sy00_user(id),
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS wh31_det (
  id BIGSERIAL PRIMARY KEY,
  hdr_id BIGINT NOT NULL REFERENCES wh30_hdr(id) ON DELETE CASCADE,
  stock_code VARCHAR(20) NOT NULL REFERENCES st01_mast(stock_code),
  qty NUMERIC(12,2) NOT NULL,
  unit_cost NUMERIC(12,2) DEFAULT 0,
  batch_id VARCHAR(30),
  expiry_date DATE
);

CREATE TABLE IF NOT EXISTS wh40_hist (
  id BIGSERIAL PRIMARY KEY,
  wh_id BIGINT REFERENCES wh01_mast(id) ON DELETE SET NULL,
  action VARCHAR(20) NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  changed_at TIMESTAMP DEFAULT now()
);

-- ===== BINS (wb) =====
CREATE TABLE IF NOT EXISTS wb01_mast (
  id BIGSERIAL PRIMARY KEY,
  wb_code VARCHAR(20) NOT NULL,
  wh_id BIGINT NOT NULL REFERENCES wh01_mast(id) ON DELETE CASCADE,
  description VARCHAR(100),
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  UNIQUE(wh_id, wb_code)
);

-- Bin Transfers (Header/Detail)
CREATE TABLE IF NOT EXISTS wb30_hdr (
  id BIGSERIAL PRIMARY KEY,
  trans_no SERIAL UNIQUE,
  wb_from BIGINT NOT NULL REFERENCES wb01_mast(id),
  wb_to BIGINT NOT NULL REFERENCES wb01_mast(id),
  trans_date DATE NOT NULL,
  created_by BIGINT REFERENCES sy00_user(id),
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS wb31_det (
  id BIGSERIAL PRIMARY KEY,
  hdr_id BIGINT NOT NULL REFERENCES wb30_hdr(id) ON DELETE CASCADE,
  stock_code VARCHAR(20) NOT NULL REFERENCES st01_mast(stock_code),
  qty NUMERIC(12,2) NOT NULL,
  batch_id VARCHAR(30),
  expiry_date DATE
);

CREATE TABLE IF NOT EXISTS wb40_hist (
  id BIGSERIAL PRIMARY KEY,
  wb_id BIGINT REFERENCES wb01_mast(id) ON DELETE SET NULL,
  action VARCHAR(20) NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  changed_at TIMESTAMP DEFAULT now()
);

-- ===== SALES INVOICE (Base) =====
CREATE TABLE IF NOT EXISTS sa30_hdr (
  id BIGSERIAL PRIMARY KEY,
  doc_no SERIAL UNIQUE,
  acc_code VARCHAR(20) NOT NULL REFERENCES dl01_mast(acc_code) ON DELETE RESTRICT,
  date DATE NOT NULL,
  total_excl NUMERIC(12,2) DEFAULT 0,
  vat NUMERIC(12,2) DEFAULT 0,
  total_cost NUMERIC(12,2) DEFAULT 0,
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sa30_det (
  id BIGSERIAL PRIMARY KEY,
  doc_no INT NOT NULL REFERENCES sa30_hdr(doc_no) ON DELETE CASCADE,
  item_no INT NOT NULL,
  stock_code VARCHAR(20) NOT NULL REFERENCES st01_mast(stock_code) ON DELETE RESTRICT,
  batch_id VARCHAR(30),
  qty NUMERIC(12,2) NOT NULL,
  unit_cost NUMERIC(12,2) DEFAULT 0,
  unit_sell NUMERIC(12,2) DEFAULT 0,
  disc NUMERIC(12,2) DEFAULT 0,
  total NUMERIC(12,2) DEFAULT 0,
  UNIQUE(doc_no, item_no)
);

CREATE TABLE IF NOT EXISTS sa40_hist (
  id BIGSERIAL PRIMARY KEY,
  doc_no INT NOT NULL REFERENCES sa30_hdr(doc_no) ON DELETE CASCADE,
  action VARCHAR(20) NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  changed_at TIMESTAMP DEFAULT now()
);

-- ===== SALES ORDERS =====
CREATE TABLE IF NOT EXISTS sa31_hdr (
  id BIGSERIAL PRIMARY KEY,
  doc_no SERIAL UNIQUE,
  acc_code VARCHAR(20) NOT NULL REFERENCES dl01_mast(acc_code) ON DELETE RESTRICT,
  date DATE NOT NULL,
  total_excl NUMERIC(12,2) DEFAULT 0,
  vat NUMERIC(12,2) DEFAULT 0,
  total_cost NUMERIC(12,2) DEFAULT 0,
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sa31_det (
  id BIGSERIAL PRIMARY KEY,
  doc_no INT NOT NULL REFERENCES sa31_hdr(doc_no) ON DELETE CASCADE,
  item_no INT NOT NULL,
  stock_code VARCHAR(20) NOT NULL REFERENCES st01_mast(stock_code) ON DELETE RESTRICT,
  batch_id VARCHAR(30),
  qty NUMERIC(12,2) NOT NULL,
  unit_cost NUMERIC(12,2) DEFAULT 0,
  unit_sell NUMERIC(12,2) DEFAULT 0,
  disc NUMERIC(12,2) DEFAULT 0,
  total NUMERIC(12,2) DEFAULT 0,
  UNIQUE(doc_no, item_no)
);

CREATE TABLE IF NOT EXISTS sa41_hist (
  id BIGSERIAL PRIMARY KEY,
  doc_no INT NOT NULL REFERENCES sa31_hdr(doc_no) ON DELETE CASCADE,
  action VARCHAR(20) NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  changed_at TIMESTAMP DEFAULT now()
);

-- ===== SALES DELIVERIES =====
CREATE TABLE IF NOT EXISTS sa32_hdr (
  id BIGSERIAL PRIMARY KEY,
  doc_no SERIAL UNIQUE,
  acc_code VARCHAR(20) NOT NULL REFERENCES dl01_mast(acc_code) ON DELETE RESTRICT,
  date DATE NOT NULL,
  total_excl NUMERIC(12,2) DEFAULT 0,
  vat NUMERIC(12,2) DEFAULT 0,
  total_cost NUMERIC(12,2) DEFAULT 0,
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sa32_det (
  id BIGSERIAL PRIMARY KEY,
  doc_no INT NOT NULL REFERENCES sa32_hdr(doc_no) ON DELETE CASCADE,
  item_no INT NOT NULL,
  stock_code VARCHAR(20) NOT NULL REFERENCES st01_mast(stock_code) ON DELETE RESTRICT,
  batch_id VARCHAR(30),
  qty NUMERIC(12,2) NOT NULL,
  unit_cost NUMERIC(12,2) DEFAULT 0,
  unit_sell NUMERIC(12,2) DEFAULT 0,
  disc NUMERIC(12,2) DEFAULT 0,
  total NUMERIC(12,2) DEFAULT 0,
  UNIQUE(doc_no, item_no)
);

CREATE TABLE IF NOT EXISTS sa42_hist (
  id BIGSERIAL PRIMARY KEY,
  doc_no INT NOT NULL REFERENCES sa32_hdr(doc_no) ON DELETE CASCADE,
  action VARCHAR(20) NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  changed_at TIMESTAMP DEFAULT now()
);

-- ===== SALES RETURNS =====
CREATE TABLE IF NOT EXISTS sa33_hdr (
  id BIGSERIAL PRIMARY KEY,
  doc_no SERIAL UNIQUE,
  acc_code VARCHAR(20) NOT NULL REFERENCES dl01_mast(acc_code) ON DELETE RESTRICT,
  date DATE NOT NULL,
  total_excl NUMERIC(12,2) DEFAULT 0,
  vat NUMERIC(12,2) DEFAULT 0,
  total_cost NUMERIC(12,2) DEFAULT 0,
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sa33_det (
  id BIGSERIAL PRIMARY KEY,
  doc_no INT NOT NULL REFERENCES sa33_hdr(doc_no) ON DELETE CASCADE,
  item_no INT NOT NULL,
  stock_code VARCHAR(20) NOT NULL REFERENCES st01_mast(stock_code) ON DELETE RESTRICT,
  batch_id VARCHAR(30),
  qty NUMERIC(12,2) NOT NULL,
  unit_cost NUMERIC(12,2) DEFAULT 0,
  unit_sell NUMERIC(12,2) DEFAULT 0,
  disc NUMERIC(12,2) DEFAULT 0,
  total NUMERIC(12,2) DEFAULT 0,
  UNIQUE(doc_no, item_no)
);

CREATE TABLE IF NOT EXISTS sa43_hist (
  id BIGSERIAL PRIMARY KEY,
  doc_no INT NOT NULL REFERENCES sa33_hdr(doc_no) ON DELETE CASCADE,
  action VARCHAR(20) NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  changed_at TIMESTAMP DEFAULT now()
);

-- ===== PURCHASE INVOICE (Base) =====
CREATE TABLE IF NOT EXISTS pu30_hdr (
  id BIGSERIAL PRIMARY KEY,
  doc_no SERIAL UNIQUE,
  acc_code VARCHAR(20) NOT NULL REFERENCES cl01_mast(acc_code) ON DELETE RESTRICT,
  date DATE NOT NULL,
  total_value NUMERIC(12,2) DEFAULT 0,
  vat NUMERIC(12,2) DEFAULT 0,
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS pu30_det (
  id BIGSERIAL PRIMARY KEY,
  doc_no INT NOT NULL REFERENCES pu30_hdr(doc_no) ON DELETE CASCADE,
  item_no INT NOT NULL,
  stock_code VARCHAR(20) NOT NULL REFERENCES st01_mast(stock_code) ON DELETE RESTRICT,
  batch_id VARCHAR(30),
  expiry_date DATE,
  qty NUMERIC(12,2) NOT NULL,
  unit_cost NUMERIC(12,2) DEFAULT 0,
  total NUMERIC(12,2) DEFAULT 0,
  UNIQUE(doc_no, item_no)
);

CREATE TABLE IF NOT EXISTS pu40_hist (
  id BIGSERIAL PRIMARY KEY,
  doc_no INT NOT NULL REFERENCES pu30_hdr(doc_no) ON DELETE CASCADE,
  action VARCHAR(20) NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  changed_at TIMESTAMP DEFAULT now()
);

-- ===== PURCHASE ORDER =====
CREATE TABLE IF NOT EXISTS pu31_hdr (
  id BIGSERIAL PRIMARY KEY,
  doc_no SERIAL UNIQUE,
  acc_code VARCHAR(20) NOT NULL REFERENCES cl01_mast(acc_code) ON DELETE RESTRICT,
  date DATE NOT NULL,
  total_value NUMERIC(12,2) DEFAULT 0,
  vat NUMERIC(12,2) DEFAULT 0,
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS pu31_det (
  id BIGSERIAL PRIMARY KEY,
  doc_no INT NOT NULL REFERENCES pu31_hdr(doc_no) ON DELETE CASCADE,
  item_no INT NOT NULL,
  stock_code VARCHAR(20) NOT NULL REFERENCES st01_mast(stock_code) ON DELETE RESTRICT,
  batch_id VARCHAR(30),
  expiry_date DATE,
  qty NUMERIC(12,2) NOT NULL,
  unit_cost NUMERIC(12,2) DEFAULT 0,
  total NUMERIC(12,2) DEFAULT 0,
  UNIQUE(doc_no, item_no)
);

CREATE TABLE IF NOT EXISTS pu41_hist (
  id BIGSERIAL PRIMARY KEY,
  doc_no INT NOT NULL REFERENCES pu31_hdr(doc_no) ON DELETE CASCADE,
  action VARCHAR(20) NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  changed_at TIMESTAMP DEFAULT now()
);

-- ===== GL ACCOUNTS =====
CREATE TABLE IF NOT EXISTS gl01_acc (
  id BIGSERIAL PRIMARY KEY,
  acc_code VARCHAR(20) UNIQUE NOT NULL,
  acc_name VARCHAR(100) NOT NULL,
  acc_type VARCHAR(20) NOT NULL, -- Asset, Liability, Equity, Revenue, Expense
  parent_acc VARCHAR(20),
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

-- ===== GL JOURNAL HEADERS =====
CREATE TABLE IF NOT EXISTS gl30_journals (
  id BIGSERIAL PRIMARY KEY,
  jrn_no SERIAL UNIQUE,
  date DATE NOT NULL,
  source_module VARCHAR(20) NOT NULL,
  doc_type VARCHAR(10),
  doc_no VARCHAR(20),
  description TEXT,
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

-- ===== GL JOURNAL LINES =====
CREATE TABLE IF NOT EXISTS gl31_lines (
  id BIGSERIAL PRIMARY KEY,
  jrn_no INT NOT NULL REFERENCES gl30_journals(jrn_no) ON DELETE CASCADE,
  line_no INT NOT NULL,
  acc_code VARCHAR(20) NOT NULL REFERENCES gl01_acc(acc_code) ON DELETE RESTRICT,
  debit NUMERIC(12,2) DEFAULT 0,
  credit NUMERIC(12,2) DEFAULT 0,
  notes TEXT,
  UNIQUE(jrn_no, line_no)
);

-- ===== GL HISTORY =====
CREATE TABLE IF NOT EXISTS gl40_hist (
  id BIGSERIAL PRIMARY KEY,
  jrn_no INT REFERENCES gl30_journals(jrn_no) ON DELETE SET NULL,
  action VARCHAR(20) NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  changed_at TIMESTAMP DEFAULT now()
);

-- ===== PAYMENTS (payt) =====
CREATE TABLE IF NOT EXISTS payt30_hdr (
  id BIGSERIAL PRIMARY KEY,
  doc_no SERIAL UNIQUE,
  pay_type VARCHAR(10) NOT NULL, -- RECEIPT/PAYMENT
  acc_code VARCHAR(20) NOT NULL, -- debtor or creditor code (by pay_type + doc_type usage)
  date DATE NOT NULL,
  method VARCHAR(20),
  bank_account VARCHAR(50),
  amount NUMERIC(12,2) NOT NULL,
  notes TEXT,
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payt31_det (
  id BIGSERIAL PRIMARY KEY,
  hdr_id BIGINT NOT NULL REFERENCES payt30_hdr(id) ON DELETE CASCADE,
  invoice_no VARCHAR(20) NOT NULL,
  alloc_amt NUMERIC(12,2) NOT NULL,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS payt40_hist (
  id BIGSERIAL PRIMARY KEY,
  doc_no INT NOT NULL REFERENCES payt30_hdr(doc_no) ON DELETE CASCADE,
  action VARCHAR(20) NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  changed_at TIMESTAMP DEFAULT now()
);


-- ===== STOCK CATEGORIES (st02_cat) =====
CREATE TABLE IF NOT EXISTS st02_cat (
  id BIGSERIAL PRIMARY KEY,
  cat_code VARCHAR(20) UNIQUE NOT NULL,
  cat_name VARCHAR(100) NOT NULL,
  description TEXT,
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

-- ===== STOCK MASTER (st01_mast) =====
CREATE TABLE IF NOT EXISTS st01_mast (
  id BIGSERIAL PRIMARY KEY,
  stock_code VARCHAR(20) UNIQUE NOT NULL,
  description VARCHAR(150) NOT NULL,
  barcode VARCHAR(50),
  batch_control BOOLEAN DEFAULT FALSE,
  category_id BIGINT REFERENCES st02_cat(id) ON DELETE SET NULL,
  cost NUMERIC(12,2) DEFAULT 0,
  selling_price NUMERIC(12,2) DEFAULT 0,
  stock_on_hand NUMERIC(12,2) DEFAULT 0,
  total_purch NUMERIC(12,2) DEFAULT 0,
  total_sales NUMERIC(12,2) DEFAULT 0,
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

-- ===== STOCK TRANSACTIONS (st30_trans) =====
CREATE TABLE IF NOT EXISTS st30_trans (
  id BIGSERIAL PRIMARY KEY,
  stock_code VARCHAR(20) NOT NULL REFERENCES st01_mast(stock_code) ON DELETE RESTRICT,
  date DATE NOT NULL,
  trans_type VARCHAR(10) NOT NULL,  -- SALE/PURC/ADJ
  direction VARCHAR(3) NOT NULL,    -- IN/OUT
  qty NUMERIC(12,2) NOT NULL,
  unit_cost NUMERIC(12,2) DEFAULT 0,
  unit_sell NUMERIC(12,2) DEFAULT 0,
  batch_id VARCHAR(30),
  expiry_date DATE,
  doc_type VARCHAR(10) NOT NULL,
  doc_no VARCHAR(20) NOT NULL,
  notes TEXT
);
CREATE INDEX IF NOT EXISTS st30_idx_code_date ON st30_trans(stock_code, date);

-- ===== STOCK HISTORY (st40_hist) =====
CREATE TABLE IF NOT EXISTS st40_hist (
  id BIGSERIAL PRIMARY KEY,
  stock_id BIGINT REFERENCES st01_mast(id) ON DELETE SET NULL,
  action VARCHAR(20) NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  changed_at TIMESTAMP DEFAULT now()
);

BEGIN;

-- ===== WAREHOUSES (wh01_mast) =====
CREATE TABLE IF NOT EXISTS wh01_mast (
  id BIGSERIAL PRIMARY KEY,
  wh_code VARCHAR(20) UNIQUE NOT NULL,
  wh_name VARCHAR(100) NOT NULL,
  location VARCHAR(100),
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

-- ===== WAREHOUSE TAGS (wh30_tag) =====
CREATE TABLE IF NOT EXISTS wh30_tag (
  id BIGSERIAL PRIMARY KEY,
  tag_code VARCHAR(20) UNIQUE NOT NULL,
  tag_name VARCHAR(100) NOT NULL,
  description TEXT,
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL
);

-- Link tags to warehouses
CREATE TABLE IF NOT EXISTS wh30_tag_link (
  id BIGSERIAL PRIMARY KEY,
  wh_id BIGINT NOT NULL REFERENCES wh01_mast(id) ON DELETE CASCADE,
  tag_id BIGINT NOT NULL REFERENCES wh30_tag(id) ON DELETE CASCADE,
  UNIQUE(wh_id, tag_id)
);

-- Link tags to stock items
CREATE TABLE IF NOT EXISTS st30_tag_link (
  id BIGSERIAL PRIMARY KEY,
  stock_id BIGINT NOT NULL REFERENCES st01_mast(id) ON DELETE CASCADE,
  tag_id BIGINT NOT NULL REFERENCES wh30_tag(id) ON DELETE CASCADE,
  UNIQUE(stock_id, tag_id)
);

-- Category permissions per warehouse
CREATE TABLE IF NOT EXISTS wh30_cat_perm (
  id BIGSERIAL PRIMARY KEY,
  wh_id BIGINT NOT NULL REFERENCES wh01_mast(id) ON DELETE CASCADE,
  cat_id BIGINT NOT NULL REFERENCES st02_cat(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT now(),
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  UNIQUE(wh_id, cat_id)
);

-- Warehouse Transfers (Header/Detail)
CREATE TABLE IF NOT EXISTS wh30_hdr (
  id BIGSERIAL PRIMARY KEY,
  trans_no SERIAL UNIQUE,
  from_wh BIGINT NOT NULL REFERENCES wh01_mast(id),
  to_wh BIGINT NOT NULL REFERENCES wh01_mast(id),
  trans_date DATE NOT NULL,
  status SMALLINT DEFAULT 1,
  created_by BIGINT REFERENCES sy00_user(id),
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS wh31_det (
  id BIGSERIAL PRIMARY KEY,
  hdr_id BIGINT NOT NULL REFERENCES wh30_hdr(id) ON DELETE CASCADE,
  stock_code VARCHAR(20) NOT NULL REFERENCES st01_mast(stock_code),
  qty NUMERIC(12,2) NOT NULL,
  unit_cost NUMERIC(12,2) DEFAULT 0,
  batch_id VARCHAR(30),
  expiry_date DATE
);

CREATE TABLE IF NOT EXISTS wh40_hist (
  id BIGSERIAL PRIMARY KEY,
  wh_id BIGINT REFERENCES wh01_mast(id) ON DELETE SET NULL,
  action VARCHAR(20) NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  changed_at TIMESTAMP DEFAULT now()
);

-- ===== BINS (wb01_mast) =====
CREATE TABLE IF NOT EXISTS wb01_mast (
  id BIGSERIAL PRIMARY KEY,
  wb_code VARCHAR(20) NOT NULL,
  wh_id BIGINT NOT NULL REFERENCES wh01_mast(id) ON DELETE CASCADE,
  description VARCHAR(100),
  status SMALLINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  UNIQUE(wh_id, wb_code)
);

-- Bin Transfers (Header/Detail)
CREATE TABLE IF NOT EXISTS wb30_hdr (
  id BIGSERIAL PRIMARY KEY,
  trans_no SERIAL UNIQUE,
  wb_from BIGINT NOT NULL REFERENCES wb01_mast(id),
  wb_to BIGINT NOT NULL REFERENCES wb01_mast(id),
  trans_date DATE NOT NULL,
  created_by BIGINT REFERENCES sy00_user(id),
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS wb31_det (
  id BIGSERIAL PRIMARY KEY,
  hdr_id BIGINT NOT NULL REFERENCES wb30_hdr(id) ON DELETE CASCADE,
  stock_code VARCHAR(20) NOT NULL REFERENCES st01_mast(stock_code),
  qty NUMERIC(12,2) NOT NULL,
  batch_id VARCHAR(30),
  expiry_date DATE
);

CREATE TABLE IF NOT EXISTS wb40_hist (
  id BIGSERIAL PRIMARY KEY,
  wb_id BIGINT REFERENCES wb01_mast(id) ON DELETE SET NULL,
  action VARCHAR(20) NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_by BIGINT REFERENCES sy00_user(id) ON DELETE SET NULL,
  changed_at TIMESTAMP DEFAULT now()
);

COMMIT;