BEGIN;

-- ===== PERMISSIONS =====
-- System
INSERT INTO sy05_perm (perm_name, description, status, created_at) VALUES
('SY.MENU', 'Access system menu', 1, now()),
('SY.USER.CREATE', 'Create system users', 1, now()),
('SY.USER.READ', 'View system users', 1, now()),
('SY.USER.UPDATE', 'Update system users', 1, now()),
('SY.USER.DELETE', 'Delete system users', 1, now()),
('SY.ROLE.CREATE', 'Create roles', 1, now()),
('SY.ROLE.READ', 'View roles', 1, now()),
('SY.ROLE.UPDATE', 'Update roles', 1, now()),
('SY.ROLE.DELETE', 'Delete roles', 1, now());

-- Debtors
INSERT INTO sy05_perm (perm_name, description, status, created_at) VALUES
('DL.MENU', 'Access debtors menu', 1, now()),
('DL.MAST.CREATE', 'Create debtor master records', 1, now()),
('DL.MAST.READ', 'View debtor master records', 1, now()),
('DL.MAST.UPDATE', 'Update debtor master records', 1, now()),
('DL.MAST.DELETE', 'Delete debtor master records', 1, now()),
('DL.TRANS.CREATE', 'Create debtor transactions', 1, now()),
('DL.TRANS.READ', 'View debtor transactions', 1, now()),
('DL.TRANS.UPDATE', 'Update debtor transactions', 1, now()),
('DL.TRANS.DELETE', 'Delete debtor transactions', 1, now());

-- Creditors
INSERT INTO sy05_perm (perm_name, description, status, created_at) VALUES
('CL.MENU', 'Access creditors menu', 1, now()),
('CL.MAST.CREATE', 'Create creditor master records', 1, now()),
('CL.MAST.READ', 'View creditor master records', 1, now()),
('CL.MAST.UPDATE', 'Update creditor master records', 1, now()),
('CL.MAST.DELETE', 'Delete creditor master records', 1, now()),
('CL.TRANS.CREATE', 'Create creditor transactions', 1, now()),
('CL.TRANS.READ', 'View creditor transactions', 1, now()),
('CL.TRANS.UPDATE', 'Update creditor transactions', 1, now()),
('CL.TRANS.DELETE', 'Delete creditor transactions', 1, now());

-- Stock
INSERT INTO sy05_perm (perm_name, description, status, created_at) VALUES
('ST.MENU', 'Access stock menu', 1, now()),
('ST.MAST.CREATE', 'Create stock master records', 1, now()),
('ST.MAST.READ', 'View stock master records', 1, now()),
('ST.MAST.UPDATE', 'Update stock master records', 1, now()),
('ST.MAST.DELETE', 'Delete stock master records', 1, now()),
('ST.TRANS.CREATE', 'Create stock transactions', 1, now()),
('ST.TRANS.READ', 'View stock transactions', 1, now()),
('ST.TRANS.UPDATE', 'Update stock transactions', 1, now()),
('ST.TRANS.DELETE', 'Delete stock transactions', 1, now());

-- Sales
INSERT INTO sy05_perm (perm_name, description, status, created_at) VALUES
('SA.MENU', 'Access sales menu', 1, now()),
('SA.DOC.CREATE', 'Create sales documents', 1, now()),
('SA.DOC.READ', 'View sales documents', 1, now()),
('SA.DOC.UPDATE', 'Update sales documents', 1, now()),
('SA.DOC.DELETE', 'Delete sales documents', 1, now());

-- Sales Orders
INSERT INTO sy05_perm (perm_name, description, status, created_at) VALUES
('SA.ORDER.MENU',   'Access sales orders menu', 1, now()),
('SA.ORDER.CREATE', 'Create sales orders', 1, now()),
('SA.ORDER.READ',   'View sales orders', 1, now()),
('SA.ORDER.UPDATE', 'Update sales orders', 1, now()),
('SA.ORDER.DELETE', 'Delete sales orders', 1, now());

-- Sales Invoices
INSERT INTO sy05_perm (perm_name, description, status, created_at) VALUES
('SA.INVOICE.MENU',   'Access sales invoices menu', 1, now()),
('SA.INVOICE.CREATE', 'Create sales invoices', 1, now()),
('SA.INVOICE.READ',   'View sales invoices', 1, now()),
('SA.INVOICE.UPDATE', 'Update sales invoices', 1, now()),
('SA.INVOICE.DELETE', 'Delete sales invoices', 1, now());

-- Sales Deliveries
INSERT INTO sy05_perm (perm_name, description, status, created_at) VALUES
('SA.DELIVERY.MENU',   'Access sales deliveries menu', 1, now()),
('SA.DELIVERY.CREATE', 'Create sales deliveries', 1, now()),
('SA.DELIVERY.READ',   'View sales deliveries', 1, now()),
('SA.DELIVERY.UPDATE', 'Update sales deliveries', 1, now()),
('SA.DELIVERY.DELETE', 'Delete sales deliveries', 1, now());

-- Sales Returns (Credit Notes)
INSERT INTO sy05_perm (perm_name, description, status, created_at) VALUES
('SA.RETURN.MENU',   'Access sales returns menu', 1, now()),
('SA.RETURN.CREATE', 'Create sales returns', 1, now()),
('SA.RETURN.READ',   'View sales returns', 1, now()),
('SA.RETURN.UPDATE', 'Update sales returns', 1, now()),
('SA.RETURN.DELETE', 'Delete sales returns', 1, now());


-- Purchases
INSERT INTO sy05_perm (perm_name, description, status, created_at) VALUES
('PU.MENU', 'Access purchases menu', 1, now()),
('PU.DOC.CREATE', 'Create purchase documents', 1, now()),
('PU.DOC.READ', 'View purchase documents', 1, now()),
('PU.DOC.UPDATE', 'Update purchase documents', 1, now()),
('PU.DOC.DELETE', 'Delete purchase documents', 1, now());

-- Purchase Orders
INSERT INTO sy05_perm (perm_name, description, status, created_at) VALUES
('PU.ORDER.MENU',   'Access purchase orders menu', 1, now()),
('PU.ORDER.CREATE', 'Create purchase orders', 1, now()),
('PU.ORDER.READ',   'View purchase orders', 1, now()),
('PU.ORDER.UPDATE', 'Update purchase orders', 1, now()),
('PU.ORDER.DELETE', 'Delete purchase orders', 1, now());

-- Purchase Invoices
INSERT INTO sy05_perm (perm_name, description, status, created_at) VALUES
('PU.INVOICE.MENU',   'Access purchase invoices menu', 1, now()),
('PU.INVOICE.CREATE', 'Create purchase invoices', 1, now()),
('PU.INVOICE.READ',   'View purchase invoices', 1, now()),
('PU.INVOICE.UPDATE', 'Update purchase invoices', 1, now()),
('PU.INVOICE.DELETE', 'Delete purchase invoices', 1, now());


-- GL
INSERT INTO sy05_perm (perm_name, description, status, created_at) VALUES
('GL.MENU', 'Access general ledger menu', 1, now()),
('GL.JNL.CREATE', 'Create GL journals', 1, now()),
('GL.JNL.READ', 'View GL journals', 1, now()),
('GL.JNL.UPDATE', 'Update GL journals', 1, now()),
('GL.JNL.DELETE', 'Delete GL journals', 1, now());

-- Payments
INSERT INTO sy05_perm (perm_name, description, status, created_at) VALUES
('PAYT.MENU', 'Access payments menu', 1, now()),
('PAYT.DOC.CREATE', 'Create payment documents', 1, now()),
('PAYT.DOC.READ', 'View payment documents', 1, now()),
('PAYT.DOC.UPDATE', 'Update payment documents', 1, now()),
('PAYT.DOC.DELETE', 'Delete payment documents', 1, now());

COMMIT;
