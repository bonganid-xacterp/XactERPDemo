c:\Users\dlami\OneDrive\Documents\GeneroDev\XactERPDemo\PROJECT_RESULTS_FEEDBACK.md
# Project Results Feedback

## Executive Summary
- The active entry point is `start_app.4gl` using a top menu and an MDI container to launch modules. Window management is centralized in `main_shell.4gl`.
- System administration modules for users, roles, permissions, login, password changes, logs, and lookup config are present and largely consistent, but there are schema/table name inconsistencies and password hashing mismatches.
- Utilities (`utils_globals`, `utils_db`, `utils_logger`) provide a solid foundation, though `utils_db` hardcodes credentials and `utils_globals` has a few validation/mode assumptions to revisit.
- Top menu XML uses duplicate action names and should be normalized to avoid handler collisions.

## Startup & MDI
- Entry flow initializes, logs in, opens MDI, runs menu, then cleans up (`_main/start_app.4gl:62–80`, `116–139`).
- Child window management prevents duplicates and tracks open windows (`_main/main_shell.4gl:58–83`, `98–141`, `148–183`).
- Issues
  - `close_current_window` is likely closing the wrong target by using the container name (`_main/start_app.4gl:264–278`).
  - Two overlapping menu implementations: the top menu loop in `start_app.4gl` and `main_menu.4gl` — they can diverge over time.
  - Duplicate action names in top menu XML (e.g., multiple `st_mast`) can cause ambiguous `ON ACTION` dispatch (`_main/main_topmenu.4tm:23, 27–29`).
- Recommendations
  - Use `ui.Window.getCurrent()` or a `main_shell.close_current_child()` helper to close the active child window.
  - Consolidate menu handling into a single module; keep `start_app.4gl` wired to `main_topmenu.4tm`.
  - Normalize action names: use unique identifiers per command (e.g., `st_move`, `st_hist`).

## System Modules
### Lookup Config
- Rich CRUD controller with array-backed navigation and validation (`sy/sy08_lkup_config.4gl:53–91`, `96–170`).
- Good transaction handling with commit/rollback and feedback messages (`sy/sy08_lkup_config.4gl:402–462`, `467–517`).
- Finding
  - Launch point supports standalone vs child style (`sy/sy08_lkup_config.4gl:37–48`).
- Recommendations
  - Consider adding permission checks before edit/delete (ties into `sy102_role`/`sy103_perm`).

### Login
- Dialog-based login with detailed error handling and logging hooks (`sy/sy100_login.4gl:126–248`, `254–324`).
- Validates against `sys_users` table, with demo fallback (`sy/sy100_login.4gl:329–392`, `397–423`).
- Findings
  - Table mismatch: other system modules use `sy00_user`; login uses `sys_users` (`sy/sy100_login.4gl:342–346` vs user modules).
  - No hashing in validation; compares plaintext (`sy/sy100_login.4gl:336–339`, `379–385`).
- Recommendations
  - Unify on `sy00_user` and use hashed password comparison consistent with `sy104_user_pwd` (SHA-256).
  - Remove demo defaults or guard under a dev flag (`sy/sy100_login.4gl:121–124`).

### Users
- Full CRUD with MD5 hashing via `security.Digest`, fallback to Base64 (`sy/sy101_user.4gl:591–606`).
- Clears password on load and only updates it when provided (`sy/sy101_user.4gl:189–208`, `475–504`).
- Findings
  - Hashing mismatch: MD5 here, SHA-256 used in `sy104_user_pwd` (`sy/sy104_user_pwd.4gl:139–145`).
  - Email validation delegates to `utils_globals.is_valid_email` (`sy/sy101_user.4gl:271–276`).
- Recommendations
  - Standardize on SHA-256 for both creation and change flows.
  - Consider salting and a migration path for MD5 → SHA-256.

### Roles
- CRUD with soft delete and duplicate checks; placeholders for permission management (`sy/sy102_role.4gl:357–404`, `424–439`, `472–513`).
- Recommendations
  - Implement `sy06_role_perm` linkage to `sy05_perm` and expose role-permission editing UI.

### Permissions
- Array-based listing/editing with soft delete and duplicate checks (`sy/sy103_perm.4gl:63–86`, `91–141`, `146–202`, `271–307`, `312–361`).
- Recommendation
  - Add role assignment views and propagation to `sy06_role_perm`.

### Password Change
- Validates current password, enforces minimum length, and uses SHA-256 hashing (`sy/sy104_user_pwd.4gl:51–119`, `139–145`).
- Findings
  - Schema typo: `SCHEMA demoapp_db` vs `demoappdb` elsewhere (`sy/sy104_user_pwd.4gl:11`).
  - Action name `bin_change_pwd` should match form definition; ensure alignment across `.4fd`.
- Recommendations
  - Fix schema name and standardize on SHA-256 across modules.

### Logs
- Filterable viewer, export to text, and a comprehensive logging API (`sy/sy130_logs.4gl:60–68`, `72–158`, `184–225`, `333–386`, `392–440`).
- Good separation of view vs write functions; silent failure on logging prevents breaking workflows (`sy/sy130_logs.4gl:435–439`).

## Utilities
### Globals
- Centralized initialization, messaging, dialog action mode helpers, formatting and field UI utility (`utils/utils_globals.4gl:137–176`, `276–349`, `411–500`).
- Findings
  - `is_valid_phone` expects 11 digits in regex but message says 10 (`utils/utils_globals.4gl:569–583`).
  - `initialize_application` loads styles and connects DB via `utils_db` (`utils/utils_globals.4gl:151–165`).
- Recommendations
  - Correct phone regex to match intended length and region format.
  - Provide environment-based configuration for DB settings and style file paths.

### DB
- Connects to Postgres with hardcoded credentials (`utils/utils_db.4gl:11–21`).
- Findings
  - Security risk: `USER "postgres" USING "napoleon"` is committed in source.
- Recommendations
  - Externalize DB configuration via environment or runtime config; never hardcode secrets.

### Logger
- Wrapper to route logs to console and DB with min-level filtering (`utils/utils_logger.4gl:39–66`, `70–127`, `132–159`).
- Integrates with `sy130_logs` and `utils_globals.get_current_user_id` (ensure it exists) (`utils/utils_logger.4gl:90–95`, `267–275`).
- Recommendations
  - Confirm `utils_globals.get_current_user_id` is implemented and consistent.
  - Initialize logger early in app startup.

## UI Resources
- `main_shell.4fd` defines the MDI container and status label (`_main/main_shell.4fd:6–12`).
- Presentation styles are thorough and consistent; forms should reference style classes (`_main/main_styles.4st`, e.g., `"Window.child"` is used in `main_shell.4gl:74`).
- `main_topmenu.4tm` maps action names; ensure each is unique and covered by `ON ACTION` handlers (`_main/main_topmenu.4tm:21–69, 81–86, 88–94`).

## Cross-Cutting Concerns
- Password hashing inconsistency (MD5 vs SHA-256) across modules (`sy/sy101_user.4gl:591–606` vs `sy/sy104_user_pwd.4gl:139–145`).
- Mixed user tables and schemas (`sys_users` vs `sy00_user`; `demoappdb` vs `demoapp_db`).
- Hardcoded database credentials risk (`utils/utils_db.4gl:11–21`).
- Duplicate menu action names and overlapping menu modules.

## Recommended Fixes
- Window closing:
  - Replace container-based closing with `ui.Window.getCurrent()` or add `main_shell.close_current_child()` to close the active child (`_main/start_app.4gl:253–278`).
- Menu unification:
  - Consolidate menu code into `start_app.4gl` and deprecate `main_menu.4gl` handlers; normalize action names (`_main/start_app.4gl:144–196`, `_main/main_topmenu.4tm`).
- Authentication consistency:
  - Use `sy00_user` table uniformly and SHA-256 password hashing for login validation and user management (`sy/sy100_login.4gl:342–346`, `sy/sy104_user_pwd.4gl:139–145`, `sy/sy101_user.4gl:591–606`).
- Security:
  - Remove hardcoded DB credentials and load from environment/config (`utils/utils_db.4gl:11–21`).
- Schema name alignment:
  - Ensure all modules use `SCHEMA demoappdb` consistently (`sy/sy104_user_pwd.4gl:11`).
- Validation:
  - Fix phone regex and align message with expected format (`utils/utils_globals.4gl:569–583`).
- Roles/Permissions:
  - Implement `sy06_role_perm` linkage and UI to assign permissions to roles (`sy/sy102_role.4gl:471–505`, `sy/sy103_perm.4gl:330–336`).

## Next Steps
- Apply the authentication overhaul:
  - Migrate MD5 passwords to SHA-256; dual-verify during migration, then flip to SHA-256-only.
  - Update `sy100_login` to use hashed comparison against `sy00_user`.
- Normalize top menu action names and complete missing handlers for movements/transfers/history.
- Externalize DB connection details and provide environment-based configuration.
- Implement role-permission assignment screens and enforce permission checks in controllers (e.g., in “Edit/Delete” actions of system modules).
- Add unit/system tests for login, password change, and permission checks.

## Notable References
- `_main/start_app.4gl:62–80`, `116–139`, `144–196`, `201–248`, `253–289`, `351–356`
- `_main/main_shell.4gl:58–83`, `98–141`, `148–183`, `264–290`
- `_main/main_topmenu.4tm:21–29`, `32–39`, `48–53`, `63–69`, `81–86`, `88–94`
- `sy/sy08_lkup_config.4gl:31–48`, `53–91`, `96–170`, `402–462`, `467–517`
- `sy/sy100_login.4gl:126–248`, `254–324`, `329–392`
- `sy/sy101_user.4gl:229–353`, `444–510`, `591–606`
- `sy/sy102_role.4gl:61–99`, `104–134`, `357–404`, `424–439`
- `sy/sy103_perm.4gl:63–86`, `91–141`, `146–202`, `271–307`, `312–361`
- `sy/sy104_user_pwd.4gl:25–119`, `139–145`
- `sy/sy130_logs.4gl:60–68`, `72–158`, `184–225`, `333–386`, `392–440`
- `utils/utils_globals.4gl:137–176`, `276–349`, `569–583`
- `utils/utils_db.4gl:11–21`
- `utils/utils_logger.4gl:39–66`, `70–127`, `132–159`