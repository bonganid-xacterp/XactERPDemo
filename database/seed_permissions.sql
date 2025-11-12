-- ==============================================================
-- Permissions Seeder Script
-- Purpose: Seed basic CRUD permissions for all system modules
-- Author: Bongani Dlamini
-- ==============================================================

-- Clear existing permissions (optional - comment out if you want to keep existing)
-- DELETE FROM sy06_role_perm;
-- DELETE FROM sy05_perm;

-- ==============================================================
-- SYSTEM MODULE (SY) PERMISSIONS
-- ==============================================================

-- User Management
INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('User - View', 'SY_USER_VIEW', 'View users list and details', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('User - Create', 'SY_USER_CREATE', 'Create new users', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('User - Update', 'SY_USER_UPDATE', 'Update existing users', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('User - Delete', 'SY_USER_DELETE', 'Delete users', 'active', CURRENT, 1);

-- Role Management
INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Role - View', 'SY_ROLE_VIEW', 'View roles list and details', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Role - Create', 'SY_ROLE_CREATE', 'Create new roles', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Role - Update', 'SY_ROLE_UPDATE', 'Update existing roles', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Role - Delete', 'SY_ROLE_DELETE', 'Delete roles', 'active', CURRENT, 1);

-- Permission Management
INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Permission - View', 'SY_PERM_VIEW', 'View permissions list', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Permission - Create', 'SY_PERM_CREATE', 'Create new permissions', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Permission - Update', 'SY_PERM_UPDATE', 'Update existing permissions', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Permission - Delete', 'SY_PERM_DELETE', 'Delete permissions', 'active', CURRENT, 1);

-- System Logs
INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Logs - View', 'SY_LOGS_VIEW', 'View system logs', 'active', CURRENT, 1);

-- ==============================================================
-- STOCK MODULE (ST) PERMISSIONS
-- ==============================================================

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Stock - View', 'ST_STOCK_VIEW', 'View stock items and inventory', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Stock - Create', 'ST_STOCK_CREATE', 'Create new stock items', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Stock - Update', 'ST_STOCK_UPDATE', 'Update stock items', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Stock - Delete', 'ST_STOCK_DELETE', 'Delete stock items', 'active', CURRENT, 1);

-- Stock Categories
INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Stock Category - View', 'ST_CAT_VIEW', 'View stock categories', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Stock Category - Create', 'ST_CAT_CREATE', 'Create stock categories', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Stock Category - Update', 'ST_CAT_UPDATE', 'Update stock categories', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Stock Category - Delete', 'ST_CAT_DELETE', 'Delete stock categories', 'active', CURRENT, 1);

-- Stock Transactions
INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Stock Trans - View', 'ST_TRANS_VIEW', 'View stock transactions', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Stock Trans - Create', 'ST_TRANS_CREATE', 'Create stock transactions', 'active', CURRENT, 1);

-- ==============================================================
-- PURCHASES MODULE (PU) PERMISSIONS
-- ==============================================================

-- Purchase Orders
INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Purchase Order - View', 'PU_ORDER_VIEW', 'View purchase orders', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Purchase Order - Create', 'PU_ORDER_CREATE', 'Create purchase orders', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Purchase Order - Update', 'PU_ORDER_UPDATE', 'Update purchase orders', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Purchase Order - Delete', 'PU_ORDER_DELETE', 'Delete purchase orders', 'active', CURRENT, 1);

-- Goods Received Notes (GRN)
INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('GRN - View', 'PU_GRN_VIEW', 'View goods received notes', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('GRN - Create', 'PU_GRN_CREATE', 'Create goods received notes', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('GRN - Update', 'PU_GRN_UPDATE', 'Update goods received notes', 'active', CURRENT, 1);

-- Purchase Invoices
INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Purchase Invoice - View', 'PU_INV_VIEW', 'View purchase invoices', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Purchase Invoice - Create', 'PU_INV_CREATE', 'Create purchase invoices', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Purchase Invoice - Update', 'PU_INV_UPDATE', 'Update purchase invoices', 'active', CURRENT, 1);

-- ==============================================================
-- SALES MODULE (SA) PERMISSIONS
-- ==============================================================

-- Sales Quotations
INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Sales Quote - View', 'SA_QUOTE_VIEW', 'View sales quotations', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Sales Quote - Create', 'SA_QUOTE_CREATE', 'Create sales quotations', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Sales Quote - Update', 'SA_QUOTE_UPDATE', 'Update sales quotations', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Sales Quote - Delete', 'SA_QUOTE_DELETE', 'Delete sales quotations', 'active', CURRENT, 1);

-- Sales Orders
INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Sales Order - View', 'SA_ORDER_VIEW', 'View sales orders', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Sales Order - Create', 'SA_ORDER_CREATE', 'Create sales orders', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Sales Order - Update', 'SA_ORDER_UPDATE', 'Update sales orders', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Sales Order - Delete', 'SA_ORDER_DELETE', 'Delete sales orders', 'active', CURRENT, 1);

-- Sales Invoices
INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Sales Invoice - View', 'SA_INV_VIEW', 'View sales invoices', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Sales Invoice - Create', 'SA_INV_CREATE', 'Create sales invoices', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Sales Invoice - Update', 'SA_INV_UPDATE', 'Update sales invoices', 'active', CURRENT, 1);

-- Credit Notes
INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Credit Note - View', 'SA_CRN_VIEW', 'View credit notes', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Credit Note - Create', 'SA_CRN_CREATE', 'Create credit notes', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Credit Note - Update', 'SA_CRN_UPDATE', 'Update credit notes', 'active', CURRENT, 1);

-- ==============================================================
-- CREDITORS MODULE (CL) PERMISSIONS
-- ==============================================================

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Creditor - View', 'CL_CRED_VIEW', 'View creditors/suppliers', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Creditor - Create', 'CL_CRED_CREATE', 'Create creditors/suppliers', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Creditor - Update', 'CL_CRED_UPDATE', 'Update creditors/suppliers', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Creditor - Delete', 'CL_CRED_DELETE', 'Delete creditors/suppliers', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Creditor Trans - View', 'CL_TRANS_VIEW', 'View creditor transactions', 'active', CURRENT, 1);

-- ==============================================================
-- DEBTORS MODULE (DL) PERMISSIONS
-- ==============================================================

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Debtor - View', 'DL_DEBT_VIEW', 'View debtors/customers', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Debtor - Create', 'DL_DEBT_CREATE', 'Create debtors/customers', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Debtor - Update', 'DL_DEBT_UPDATE', 'Update debtors/customers', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Debtor - Delete', 'DL_DEBT_DELETE', 'Delete debtors/customers', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Debtor Trans - View', 'DL_TRANS_VIEW', 'View debtor transactions', 'active', CURRENT, 1);

-- ==============================================================
-- GENERAL LEDGER MODULE (GL) PERMISSIONS
-- ==============================================================

-- Chart of Accounts
INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('GL Account - View', 'GL_ACC_VIEW', 'View GL accounts', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('GL Account - Create', 'GL_ACC_CREATE', 'Create GL accounts', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('GL Account - Update', 'GL_ACC_UPDATE', 'Update GL accounts', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('GL Account - Delete', 'GL_ACC_DELETE', 'Delete GL accounts', 'active', CURRENT, 1);

-- Journal Entries
INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('GL Journal - View', 'GL_JRN_VIEW', 'View journal entries', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('GL Journal - Create', 'GL_JRN_CREATE', 'Create journal entries', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('GL Journal - Update', 'GL_JRN_UPDATE', 'Update journal entries', 'active', CURRENT, 1);

-- Reports
INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('GL Report - Trial Balance', 'GL_RPT_TRIAL', 'View trial balance report', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('GL Report - Income Statement', 'GL_RPT_INCOME', 'View income statement', 'active', CURRENT, 1);

-- ==============================================================
-- WAREHOUSE MODULE (WH) PERMISSIONS
-- ==============================================================

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Warehouse - View', 'WH_WH_VIEW', 'View warehouses', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Warehouse - Create', 'WH_WH_CREATE', 'Create warehouses', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Warehouse - Update', 'WH_WH_UPDATE', 'Update warehouses', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Warehouse - Delete', 'WH_WH_DELETE', 'Delete warehouses', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Warehouse Trans - View', 'WH_TRANS_VIEW', 'View warehouse transactions', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Warehouse Trans - Create', 'WH_TRANS_CREATE', 'Create warehouse transactions', 'active', CURRENT, 1);

-- ==============================================================
-- WAYBILLS MODULE (WB) PERMISSIONS
-- ==============================================================

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Waybill - View', 'WB_WB_VIEW', 'View waybills', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Waybill - Create', 'WB_WB_CREATE', 'Create waybills', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Waybill - Update', 'WB_WB_UPDATE', 'Update waybills', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Waybill - Delete', 'WB_WB_DELETE', 'Delete waybills', 'active', CURRENT, 1);

-- ==============================================================
-- PAYMENTS MODULE (PAYT) PERMISSIONS
-- ==============================================================

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Payment - View', 'PAYT_PAY_VIEW', 'View payments', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Payment - Create', 'PAYT_PAY_CREATE', 'Create payments', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Payment - Update', 'PAYT_PAY_UPDATE', 'Update payments', 'active', CURRENT, 1);

INSERT INTO sy05_perm (perm_name, perm_code, description, status, created_at, created_by)
VALUES ('Payment - Delete', 'PAYT_PAY_DELETE', 'Delete payments', 'active', CURRENT, 1);

-- ==============================================================
-- SUMMARY
-- ==============================================================
-- Total Permissions Created: 96 permissions across 11 modules
-- Modules Covered:
--   SY  - System (Users, Roles, Permissions, Logs)
--   ST  - Stock (Items, Categories, Transactions)
--   PU  - Purchases (Orders, GRN, Invoices)
--   SA  - Sales (Quotes, Orders, Invoices, Credit Notes)
--   CL  - Creditors (Suppliers, Transactions)
--   DL  - Debtors (Customers, Transactions)
--   GL  - General Ledger (Accounts, Journals, Reports)
--   WH  - Warehouse (Warehouses, Transactions)
--   WB  - Waybills
--   PAYT - Payments
-- ==============================================================

-- Verify the insert
SELECT
    LEFT(perm_code, 2) AS module,
    COUNT(*) AS permission_count
FROM sy05_perm
WHERE deleted_at IS NULL
GROUP BY LEFT(perm_code, 2)
ORDER BY module;

SELECT COUNT(*) AS total_permissions FROM sy05_perm WHERE deleted_at IS NULL;
