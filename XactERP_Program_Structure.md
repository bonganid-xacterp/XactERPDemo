# 📊 XactERP Program Structure (Corrected)

This document lists all **programs, forms, and utilities** for each module in the XactERP Demo, following the **naming conventions**, **numbering scheme**, and **header/detail transaction patterns**.

---

## 🔑 Naming Rules

- **Module Prefixes**  
  - System = `sy`, Debtors = `dl`, Creditors = `cl`, Stock = `st`, Warehouses = `wh`, Bins = `wb`, Sales = `sa`, Purchases = `pu`, General Ledger = `gl`, Payments = `payt`
- **Program Numbers**  
  - 100–119 = Master Maintenance  
  - 120–129 = Enquiries  
  - 130–199 = Transactions (documents, transfers)  
  - 200–219 = Document/Batch Reports  
  - 220–299 = Reports  
- **Table Numbers**  
  - 01–19 = Master Tables  
  - 30–39 = Transactions / Documents (hdr+det)  
  - 40–59 = History  

---

## 📦 Modules & Programs

### 🛠 System (sy)
| Program | DB Tables | Purpose |
|---------|-----------|---------|
| `sy100_login` | — | Login screen |
| `sy101_user` | `sy00_user` | User Master |
| `sy102_role` | `sy04_role` | Role Master |
| `sy103_perm` | `sy05_perm` | Permission Master |
| `sy120_user_enq` | `sy00_user` | User Enquiry |
| `sy130_logs` | `sy02_logs` | Logs Viewer |
| `sy140_hist` | `sy40_hist` | System History |

---

### 👥 Debtors (dl)
| Program | DB Tables | Purpose |
|---------|-----------|---------|
| `dl101_mast` | `dl01_mast` | Debtors Master |
| `dl120_enq` | `dl01_mast` | Debtors Enquiry |
| `dl130_trans` | `dl30_trans` | Debtor Transactions (flat) |
| `dl140_hist` | `dl40_hist` | Debtor History |

---

### 🏦 Creditors (cl)
| Program | DB Tables | Purpose |
|---------|-----------|---------|
| `cl101_mast` | `cl01_mast` | Creditors Master |
| `cl120_enq` | `cl01_mast` | Creditors Enquiry |
| `cl130_trans` | `cl30_trans` | Creditor Transactions (flat) |
| `cl140_hist` | `cl40_hist` | Creditor History |

---

### 📦 Stock (st)
| Program | DB Tables | Purpose |
|---------|-----------|---------|
| `st101_mast` | `st01_mast` | Stock Master |
| `st102_cat` | `st02_cat` | Stock Categories |
| `st120_enq` | `st01_mast` | Stock Enquiry |
| `st130_trans` | `st30_trans` | Stock Transactions (flat) |
| `st140_hist` | `st40_hist` | Stock History |

---

### 🏬 Warehouses (wh)
| Program | DB Tables | Purpose |
|---------|-----------|---------|
| `wh101_mast` | `wh01_mast` | Warehouse Master |
| `wh102_tag` | `wh30_tag` | Warehouse Tags |
| `wh130_trans` | `wh30_hdr` + `wh31_det` | Warehouse Transfers (Header + Detail) |
| `wh140_hist` | `wh40_hist` | Warehouse History |

### 📦 Bins (wb)
| Program | DB Tables | Purpose |
|---------|-----------|---------|
| `wb101_mast` | `wb01_mast` | Bin Master |
| `wb130_trans` | `wb30_hdr` + `wb31_det` | Bin Transfers (Header + Detail) |
| `wb140_hist` | `wb40_hist` | Bin History |

---

### 🧾 Sales (sa)
| Program | DB Tables | Purpose |
|---------|-----------|---------|
| `sa130_order` | `sa31_hdr` + `sa31_det` | Sales Orders |
| `sa131_invoice` | `sa30_hdr` + `sa30_det` | Sales Invoices |
| `sa132_delivery` | `sa32_hdr` + `sa32_det` | Sales Deliveries |
| `sa133_return` | `sa33_hdr` + `sa33_det` | Sales Returns / Credit Notes |
| `sa140_hist` | `sa40_hist` + `sa41_hist` + `sa42_hist` + `sa43_hist` | Sales History |

---

### 📥 Purchases (pu)
| Program | DB Tables | Purpose |
|---------|-----------|---------|
| `pu130_order` | `pu31_hdr` + `pu31_det` | Purchase Orders |
| `pu131_invoice` | `pu30_hdr` + `pu30_det` | Purchase Invoices |
| `pu140_hist` | `pu40_hist` + `pu41_hist` | Purchase History |

---

### 💰 General Ledger (gl)
| Program | DB Tables | Purpose |
|---------|-----------|---------|
| `gl101_acc` | `gl01_acc` | GL Accounts |
| `gl130_journal` | `gl30_journals` + `gl31_lines` | GL Journals (Header + Lines) |
| `gl140_hist` | `gl40_hist` | GL History |
| `gl220_trial_balance` | derived | Trial Balance Report |
| `gl221_income_stmt` | derived | Income Statement |
| `gl222_balance_sheet` | derived | Balance Sheet |

---

### 💵 Payments (payt)
| Program | DB Tables | Purpose |
|---------|-----------|---------|
| `payt130_doc` | `payt30_hdr` + `payt31_det` | Payments (Header + Detail) |
| `payt140_hist` | `payt40_hist` | Payment History |
| `payt220_cashbook` | derived | Cashbook Report |

---

## ⚙️ Shared Utilities

| File | Purpose |
|------|---------|
| `utils_ui.4gl` | Common UI helpers (titles, logos, etc.) |
| `utils_db.4gl` | Database connection, error handling |
| `utils_alerts.4gl` | Alert/confirm/info wrappers |
| `utils_auth.4gl` | Authentication & permissions |
| `utils_style.4st` | Central style definitions |
| `res/logo.png` | App/company logo |
| `res/icon_*.png` | Module icons (`icon_dl.png`, `icon_cl.png`, etc.) |

---

## 📂 Suggested Folder Layout

```
src/
  _main/              → main container + styles
  sy/                 → system programs
  dl/                 → debtors programs
  cl/                 → creditors programs
  st/                 → stock programs
  wh/                 → warehouses programs
  wb/                 → bins programs
  sa/                 → sales programs
  pu/                 → purchases programs
  gl/                 → general ledger programs
  payt/               → payments programs
  utils/              → shared utility libraries
  res/                → logo + icons
sql/
  schema/             → create table scripts
  seed/               → seed data (roles, users, permissions)
```
