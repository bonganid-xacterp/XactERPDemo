BEGIN;

-- ===== ADMIN ROLE: Full access (all permissions) =====
INSERT INTO sy06_role_perm (role_id, perm_id)
SELECT r.id, p.id
FROM sy04_role r, sy05_perm p
WHERE r.role_name = 'Admin';

-- ===== MANAGER ROLE: Everything except DELETE =====
INSERT INTO sy06_role_perm (role_id, perm_id)
SELECT r.id, p.id
FROM sy04_role r
JOIN sy05_perm p ON p.perm_name NOT LIKE '%.DELETE'
WHERE r.role_name = 'Manager';

-- ===== CLERK ROLE: Menu + READ + CREATE only =====
INSERT INTO sy06_role_perm (role_id, perm_id)
SELECT r.id, p.id
FROM sy04_role r
JOIN sy05_perm p ON (
    p.perm_name LIKE '%.MENU'
 OR p.perm_name LIKE '%.READ'
 OR p.perm_name LIKE '%.CREATE'
)
WHERE r.role_name = 'Clerk';

COMMIT;
