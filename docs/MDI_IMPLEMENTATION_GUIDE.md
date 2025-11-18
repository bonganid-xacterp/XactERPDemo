# MDI (Multiple Document Interface) Implementation Guide
## XactERP System - Complete Reference

---

## Table of Contents
1. [Overview](#overview)
2. [MDI Architecture](#mdi-architecture)
3. [Key Components](#key-components)
4. [Step-by-Step Implementation](#step-by-step-implementation)
5. [Important Concepts](#important-concepts)
6. [Troubleshooting](#troubleshooting)

---

## Overview

**MDI (Multiple Document Interface)** allows multiple child windows to be open simultaneously within a parent container window. Think of it like tabs in a web browser - you can have many documents/modules open at once.

### What You Get:
- ✅ Multiple modules open at the same time
- ✅ Tabbed interface for easy switching
- ✅ Window management (close individual or all windows)
- ✅ Prevents duplicate windows
- ✅ Professional ERP interface

---

## MDI Architecture

```
┌─────────────────────────────────────────────────────┐
│  Main Container Window (w_main)                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  Top Menu Bar (File, Inventory, Sales, etc.) │  │
│  ├───────────────────────────────────────────────┤  │
│  │                                               │  │
│  │  Main_container Group                         │  │
│  │  ┌─────────────────────────────────────────┐ │  │
│  │  │  Child Window 1 (Stock Master)          │ │  │
│  │  ├─────────────────────────────────────────┤ │  │
│  │  │  Child Window 2 (Purchase Orders)       │ │  │
│  │  ├─────────────────────────────────────────┤ │  │
│  │  │  Child Window 3 (Customers)             │ │  │
│  │  └─────────────────────────────────────────┘ │  │
│  │                                               │  │
│  ├───────────────────────────────────────────────┤  │
│  │  Status Bar: Ready                            │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

---

## Key Components

### 1. **Main Container Program** (`start_app.4gl`)
**Purpose**: Main entry point, handles login and initializes MDI container

**Key Functions**:
```4gl
FUNCTION open_mdi_container()
    -- Sets up the MDI container interface
    CALL ui.Interface.setContainer('main_shell')  -- Name of container
    CALL ui.Interface.setName('main_shell')       -- Interface name
    CALL ui.Interface.setType('container')        -- Mark as container

    -- Open the main window
    OPEN WINDOW w_main WITH FORM "main_shell"
        ATTRIBUTES(TEXT = "Your Title Here")

    -- Load top menu
    LET f = ui.Window.getCurrent().getForm()
    CALL f.loadTopMenu("main_topmenu")

    -- Show menu and wait
    CALL show_main_menu()
END FUNCTION
```

### 2. **MDI Window Manager** (`main_shell.4gl`)
**Purpose**: Manages all child windows (open, close, track)

**Key Functions**:

#### a. Launch Child Window
```4gl
FUNCTION launch_child_window(formname STRING, wintitle STRING) RETURNS BOOLEAN
    -- 1. Check if already open (prevent duplicates)
    -- 2. Configure as MDI child:
    CALL ui.Interface.setType("child")
    CALL ui.Interface.setName(formname)
    CALL ui.Interface.setContainer("main_shell")  -- Parent container name

    -- 3. Open the window
    OPEN WINDOW winname WITH FORM formname
        ATTRIBUTES(STYLE = "Window.child", TEXT = wintitle)

    -- 4. Register in tracking array
    -- 5. Return TRUE if successful
END FUNCTION
```

#### b. Close Child Window
```4gl
FUNCTION close_child_window(formname STRING) RETURNS BOOLEAN
    -- Find window by form name and close it
END FUNCTION

FUNCTION close_all_child_windows()
    -- Close all open child windows
END FUNCTION
```

### 3. **Main Container Form** (`main_shell.4fd`)
**Purpose**: The visual container for child windows

**Structure**:
```xml
<Form name="main_shell" style="Window.main">
  <Group name="Main_container">  <!-- CRITICAL: This is where children appear -->
    <Grid name="main_content">
      <Label name="lbl_status" text="Ready"/>
    </Grid>
  </Group>
</Form>
```

**IMPORTANT**: The Group name `Main_container` MUST match the name used in `setContainer()`!

### 4. **Style Configuration** (`main_styles.4st`)
**Purpose**: Defines window styles for MDI

**Required Styles**:
```xml
<!-- Main Container Window -->
<Style name="Window.main">
    <StyleAttribute name="windowType" value="container"/>
    <StyleAttribute name="tabbedContainer" value="yes"/>
    <StyleAttribute name="position" value="center"/>
    <StyleAttribute name="sizable" value="yes"/>
</Style>

<!-- Child Windows -->
<Style name="Window.child">
    <StyleAttribute name="windowType" value="dialog"/>
    <StyleAttribute name="border" value="title"/>
    <StyleAttribute name="sizable" value="yes"/>
</Style>
```

---

## Step-by-Step Implementation

### Step 1: Create Main Container Form

**File**: `main_shell.4fd`

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<ManagedForm>
  <Form fourSTFile="main_styles.4st"
        gridHeight="30"
        gridWidth="100"
        name="main_shell"
        text="Your App Name"
        style="Window.main">

    <!-- This Group is the MDI container -->
    <Group name="Main_container"
           gridHeight="28"
           gridWidth="100">
      <Grid gridHeight="26" gridWidth="98">
        <Label name="lbl_status" text="Ready" style="Label.status_bar"/>
      </Grid>
    </Group>
  </Form>
</ManagedForm>
```

### Step 2: Initialize MDI Container

**File**: `start_app.4gl` - Main program

```4gl
IMPORT FGL main_shell  -- Import window manager

MAIN
    -- 1. Initialize
    CALL utils_globals.initialize_application()

    -- 2. Login
    IF NOT login() THEN
        EXIT PROGRAM
    END IF

    -- 3. Open MDI Container
    CALL open_mdi_container()
END MAIN

FUNCTION open_mdi_container()
    DEFINE w ui.Window
    DEFINE f ui.Form

    -- Configure interface as container
    CALL ui.Interface.setContainer('main_shell')  -- Match your form name
    CALL ui.Interface.setName('main_shell')
    CALL ui.Interface.setType('container')

    -- Open main window
    OPEN WINDOW w_main WITH FORM "main_shell"
        ATTRIBUTES(TEXT = "My Application")

    LET w = ui.Window.getCurrent()
    LET f = w.getForm()

    -- Load top menu
    CALL f.loadTopMenu("main_topmenu")

    -- Show menu (blocks here until user exits)
    CALL show_main_menu()

    -- Cleanup
    CALL main_shell.close_all_child_windows()
    CLOSE WINDOW w_main
END FUNCTION
```

### Step 3: Launch Child Windows

**File**: `start_app.4gl` - Launch function

```4gl
FUNCTION launch_child_module(module_name STRING, title STRING)
    -- Use main_shell to open the window
    IF main_shell.launch_child_window(module_name, title) THEN
        -- Window opened successfully, now run the module function
        CASE module_name
            WHEN "st101_mast"
                CALL st101_mast.init_st_module()

            WHEN "cl101_mast"
                CALL cl101_mast.init_cl_module()

            -- Add more modules here
        END CASE
    END IF
END FUNCTION

FUNCTION show_main_menu()
    MENU "Main Menu"
        ON ACTION st_mast
            -- This launches Stock Master as child window
            CALL launch_child_module("st101_mast", "Stock Master")

        ON ACTION quit
            EXIT MENU
    END MENU
END FUNCTION
```

### Step 4: Create Window Manager

**File**: `main_shell.4gl`

```4gl
IMPORT ui
IMPORT FGL utils_globals

-- Track open windows
DEFINE m_open_modules DYNAMIC ARRAY OF RECORD
    prog STRING,
    winname STRING,
    title STRING
END RECORD

FUNCTION launch_child_window(formname STRING, wintitle STRING) RETURNS BOOLEAN
    DEFINE winname STRING
    DEFINE i INTEGER

    -- Check if already open
    FOR i = 1 TO m_open_modules.getLength()
        IF m_open_modules[i].prog = formname THEN
            CALL utils_globals.show_info(wintitle || " is already open.")
            RETURN FALSE
        END IF
    END FOR

    -- Generate unique window name
    LET winname = "w_" || formname || "_" || (m_open_modules.getLength() + 1)

    TRY
        -- Configure as child
        CALL ui.Interface.setType("child")
        CALL ui.Interface.setName(formname)
        CALL ui.Interface.setContainer("main_shell")  -- MUST match your Group name!

        -- Open window
        OPEN WINDOW winname WITH FORM formname
            ATTRIBUTES(STYLE = "Window.child", TEXT = wintitle)

        -- Register
        LET i = m_open_modules.getLength() + 1
        LET m_open_modules[i].prog = formname
        LET m_open_modules[i].winname = winname
        LET m_open_modules[i].title = wintitle

        RETURN TRUE
    CATCH
        CALL utils_globals.show_error("Error opening " || formname)
        RETURN FALSE
    END TRY
END FUNCTION

FUNCTION close_all_child_windows()
    DEFINE i INTEGER
    DEFINE w ui.Window

    FOR i = m_open_modules.getLength() TO 1 STEP -1
        LET w = ui.Window.forName(m_open_modules[i].winname)
        IF w IS NOT NULL THEN
            CLOSE WINDOW m_open_modules[i].winname
        END IF
    END FOR

    CALL m_open_modules.clear()
END FUNCTION
```

---

## Important Concepts

### 1. **Container Name Matching**
The most critical requirement for MDI to work:

```4gl
-- In start_app.4gl
CALL ui.Interface.setContainer('main_shell')  -- Container name

-- In main_shell.4gl (when opening children)
CALL ui.Interface.setContainer("main_shell")  -- MUST BE SAME!

-- In main_shell.4fd
<Group name="Main_container">  -- Container element
```

### 2. **Window Types**

| Type | Used For | Set With |
|------|----------|----------|
| `container` | Main parent window | `setType('container')` |
| `child` | Child windows inside container | `setType('child')` |
| `modal` | Dialogs (login, alerts) | `ATTRIBUTES(STYLE="modal")` |

### 3. **Window Lifecycle**

```
1. Configure Interface → setType(), setName(), setContainer()
2. Open Window       → OPEN WINDOW ... WITH FORM
3. Run Module        → MENU or INPUT/DIALOG
4. Close Window      → CLOSE WINDOW or user closes
5. Cleanup           → Remove from tracking array
```

### 4. **Child Module Structure**

Your child modules should NOT have a MAIN section for MDI use:

```4gl
-- DON'T DO THIS for MDI:
-- MAIN
--     OPEN WINDOW w_st101 WITH FORM "st101_mast"
--     CALL init_st_module()
--     CLOSE WINDOW w_st101
-- END MAIN

-- DO THIS instead:
FUNCTION init_st_module()
    -- Window is already open by main_shell
    -- Just run your menu/dialog here
    MENU "Stock Master"
        COMMAND "New"
            CALL new_stock()
        COMMAND "Exit"
            EXIT MENU
    END MENU
    -- Window will be closed by main_shell
END FUNCTION
```

---

## Troubleshooting

### Problem: Child windows don't appear

**Solution**:
1. Check container name matches in all places
2. Verify `setContainer()` is called BEFORE opening window
3. Check Group name in form matches container name
4. Verify window style is "Window.child"

### Problem: Windows open but can't see them

**Solution**:
- Make sure your main form has a Group with the correct name
- Check that `tabbedContainer="yes"` in Window.main style

### Problem: Duplicate windows appear

**Solution**:
- Add duplicate check in `launch_child_window()` function
- Maintain tracking array of open windows

### Problem: Module shows blank screen

**Solution**:
- Module might be trying to open its own window
- Remove MAIN section or OPEN WINDOW from module
- Module should just run MENU/DIALOG assuming window exists

---

## Quick Checklist

- [ ] main_shell.4fd has Group named "Main_container"
- [ ] Window.main style has `windowType="container"` and `tabbedContainer="yes"`
- [ ] start_app calls setContainer(), setName(), setType() before OPEN WINDOW
- [ ] main_shell.4gl calls setType("child"), setContainer("main_shell") before opening children
- [ ] Container names match everywhere
- [ ] Top menu is loaded with loadTopMenu()
- [ ] Child modules don't have MAIN or OPEN WINDOW
- [ ] close_all_child_windows() called before closing main window

---

## Complete Example Flow

```
User Start
    ↓
start_app.MAIN
    ↓
Login (modal window)
    ↓
open_mdi_container()
    ├─ setContainer('main_shell')
    ├─ setType('container')
    ├─ OPEN WINDOW w_main WITH FORM "main_shell"
    ├─ loadTopMenu("main_topmenu")
    └─ show_main_menu()  ← WAITS HERE
        ↓
User clicks "Stock Master" in menu
    ↓
launch_child_module("st101_mast", "Stock Master")
    ├─ main_shell.launch_child_window()
    │   ├─ Check if already open
    │   ├─ setType("child")
    │   ├─ setContainer("main_shell")
    │   ├─ OPEN WINDOW w_st101_mast_1
    │   └─ Register in tracking array
    ├─ st101_mast.init_st_module()
    │   └─ MENU "Stock Master"  ← RUNS IN CHILD WINDOW
    └─ Return to main menu
        ↓
User clicks "Customers" in menu
    ↓
Another child window opens...
    ↓
User clicks Exit
    ↓
close_all_child_windows()
CLOSE WINDOW w_main
EXIT PROGRAM
```

---

## Summary

**3 Simple Rules for MDI**:

1. **Container Setup**: Set interface type to "container" and give it a name
2. **Child Setup**: Set interface type to "child" and tell it the container name
3. **Name Matching**: Container name MUST match everywhere

That's it! Follow these rules and your MDI will work perfectly.

---

*Document Version: 1.0*
*Last Updated: 2025-01-14*
*Author: Claude Code Assistant*
