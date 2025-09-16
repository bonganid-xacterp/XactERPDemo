-- seeders.sql (XACT ERP DEMO v1.2)
-- Inserts initial roles, permissions, and users (1 admin, 3 managers, 6 clerks)

BEGIN;

-- Roles
INSERT INTO sy04_role (role_name, status) VALUES
('Admin', 1),
('Manager', 1),
('Clerk', 1)
ON CONFLICT (role_name) DO NOTHING;

-- Permissions (basic placeholders, can be expanded)
INSERT INTO sy05_perm (perm_name, description, status)
VALUES 
('system.manage', 'Full system management', 1),
('sales.manage', 'Manage sales documents', 1),
('stock.view', 'View stock items', 1),
('purchases.manage', 'Manage purchase documents', 1)
ON CONFLICT (perm_name) DO NOTHING;

-- Role-Permission mapping (Admin has all, Manager limited, Clerk basic)
-- Admin -> all
INSERT INTO sy06_role_perm (role_id, perm_id)
SELECT r.id, p.id FROM sy04_role r, sy05_perm p WHERE r.role_name='Admin'
ON CONFLICT DO NOTHING;

-- Manager -> sales.manage, stock.view, purchases.manage
INSERT INTO sy06_role_perm (role_id, perm_id)
SELECT r.id, p.id FROM sy04_role r
JOIN sy05_perm p ON p.perm_name IN ('sales.manage','stock.view','purchases.manage')
WHERE r.role_name='Manager'
ON CONFLICT DO NOTHING;

-- Clerk -> stock.view
INSERT INTO sy06_role_perm (role_id, perm_id)
SELECT r.id, p.id FROM sy04_role r
JOIN sy05_perm p ON p.perm_name='stock.view'
WHERE r.role_name='Clerk'
ON CONFLICT DO NOTHING;

-- Users (password hashes are placeholders, replace with bcrypt hashes)
-- 1 Admin
INSERT INTO sy00_user (username, full_name, email, password, role_id, status, created_at)
VALUES ('admin','Administrator','admin@example.com','$2y$bcrypt_hash_placeholder',
       (SELECT id FROM sy04_role WHERE role_name='Admin'),1,now())
ON CONFLICT (username) DO NOTHING;

-- 3 Managers
INSERT INTO sy00_user (username, full_name, email, password, role_id, status, created_at)
VALUES 
('manager1','Manager One','manager1@example.com','$2y$bcrypt_hash_placeholder',
 (SELECT id FROM sy04_role WHERE role_name='Manager'),1,now()),
('manager2','Manager Two','manager2@example.com','$2y$bcrypt_hash_placeholder',
 (SELECT id FROM sy04_role WHERE role_name='Manager'),1,now()),
('manager3','Manager Three','manager3@example.com','$2y$bcrypt_hash_placeholder',
 (SELECT id FROM sy04_role WHERE role_name='Manager'),1,now())
ON CONFLICT (username) DO NOTHING;

-- 6 Clerks
INSERT INTO sy00_user (username, full_name, email, password, role_id, status, created_at)
VALUES 
('clerk1','Clerk One','clerk1@example.com','$2y$bcrypt_hash_placeholder',
 (SELECT id FROM sy04_role WHERE role_name='Clerk'),1,now()),
('clerk2','Clerk Two','clerk2@example.com','$2y$bcrypt_hash_placeholder',
 (SELECT id FROM sy04_role WHERE role_name='Clerk'),1,now()),
('clerk3','Clerk Three','clerk3@example.com','$2y$bcrypt_hash_placeholder',
 (SELECT id FROM sy04_role WHERE role_name='Clerk'),1,now()),
('clerk4','Clerk Four','clerk4@example.com','$2y$bcrypt_hash_placeholder',
 (SELECT id FROM sy04_role WHERE role_name='Clerk'),1,now()),
('clerk5','Clerk Five','clerk5@example.com','$2y$bcrypt_hash_placeholder',
 (SELECT id FROM sy04_role WHERE role_name='Clerk'),1,now()),
('clerk6','Clerk Six','clerk6@example.com','$2y$bcrypt_hash_placeholder',
 (SELECT id FROM sy04_role WHERE role_name='Clerk'),1,now())
ON CONFLICT (username) DO NOTHING;

COMMIT;
