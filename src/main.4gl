# ==============================================================
# Program   :   sy100_main.4gl
# Purpose   :   App entry point with login + main container
# Module    :   Main
# Number    :   100
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.2.1
# ==============================================================

IMPORT os
IMPORT ui
IMPORT security -- For password hashing (if available)
IMPORT util -- For crypto functions

DEFINE g_win ui.Window
DEFINE g_form ui.Form
DEFINE f_username STRING
DEFINE f_password STRING

MAIN
    DEFER INTERRUPT
    CLOSE WINDOW SCREEN
    -- Initialize database connection
    #CALL initialize_database()

    CALL run_login()
END MAIN

# ------------------ DATABASE INITIALIZATION -------------------
FUNCTION initialize_database()
    DEFINE db_name STRING

    -- Set your database name/connection string
    LET db_name = "xactdemo"

    -- Connect to database
    TRY
        DATABASE db_name
        DISPLAY "Connected to database: ", db_name
    CATCH
        DISPLAY "Database connection failed: ", SQLCA.SQLCODE
        DISPLAY "Error message: ", SQLCA.SQLERRM
        EXIT PROGRAM
    END TRY

END FUNCTION

# ------------------ LOGIN FLOW -------------------
FUNCTION run_login()
    DEFINE ok SMALLINT

    -- Open login window
    OPEN WINDOW w_login WITH FORM "frm_login"
    LET g_win = ui.Window.getCurrent()
    LET g_form = g_win.getForm()
    CALL g_win.setText("XACT ERP Demo – Login")

    -- Setup and display company logo
    CALL setup_login_image()

    -- Run login interaction
    DIALOG
        INPUT BY NAME f_username, f_password

            -- Initialize display when dialog starts
            BEFORE INPUT
                CALL initialize_login_display()

            ON ACTION login
                LET ok = validate_login(f_username, f_password)
                IF ok = 1 THEN
                    CALL open_main_container()
                    MESSAGE "Successfully logged in as: " || f_username
                    EXIT DIALOG
                END IF

            ON ACTION cancel
                EXIT PROGRAM

        END INPUT
    END DIALOG

   

    IF ok = 1 THEN
        CLOSE WINDOW w_login
        CALL open_main_container()
    END IF
END FUNCTION

# ------------------ IMAGE SETUP -------------------
FUNCTION setup_login_image()
    DEFINE image_path STRING
    DEFINE image_exists SMALLINT

    -- Try different possible image paths
    LET image_path = "resources/logo.png"
    LET image_exists = os.Path.exists(image_path)

    IF NOT image_exists THEN
        LET image_path = "src/resources/logo.png"
        LET image_exists = os.Path.exists(image_path)
    END IF

    IF NOT image_exists THEN
        LET image_path = "resources/logo.png"
        LET image_exists = os.Path.exists(image_path)
    END IF

    -- Set the image if found
    IF image_exists THEN
        DISPLAY image_path
    END IF
END FUNCTION

# ------------------ LOGIN DISPLAY INIT -------------------
FUNCTION initialize_login_display()
    DEFINE logo_node om.DomNode

    -- Get the image element from the form
    LET logo_node = g_form.findNode("Image", "company_logo")

    IF logo_node IS NOT NULL THEN
        -- Set image display properties for better rendering
        CALL logo_node.setAttribute("stretch", "both")
        CALL logo_node.setAttribute("autoScale", "isotropic")

        -- Optional: Set border style
        CALL logo_node.setAttribute("style", "companyLogo")

        DISPLAY "Logo display properties configured"
    ELSE
        DISPLAY "Warning: Logo image element 'company_logo' not found in form"
    END IF
END FUNCTION

# ------------------ VALIDATION -------------------
FUNCTION validate_login(p_user STRING, p_pass STRING)
    DEFINE db_pass STRING
    DEFINE db_status SMALLINT
    DEFINE input_hash STRING

    -- Empty checks
    IF p_user IS NULL OR p_user = "" THEN
        ERROR "Username cannot be empty"
        RETURN 0
    END IF

    IF p_pass IS NULL OR p_pass = "" THEN
        ERROR "Password cannot be empty"
        RETURN 0
    END IF

    -- For development/testing - remove in production
    IF p_user = "admin" AND p_pass = "admin" THEN
        RETURN 1
    END IF

    -- Database validation (uncomment when database is ready)

    -- Fetch encrypted password
    SELECT password, status
        INTO db_pass, db_status
        FROM sy00_user
        WHERE username = p_user AND deleted_at IS NULL AND status = 1

    WHENEVER NOT FOUND CONTINUE

    IF db_pass IS NULL THEN
        ERROR "Invalid username or password"
        RETURN 0
    END IF

    -- Hash entered password with bcrypt
    #LET input_hash = check_password(p_pass, db_pass)

    IF input_hash = db_pass THEN
        RETURN 1
    ELSE
        ERROR "Invalid username or password"
        RETURN 0
    END IF

    -- Default response for development
    ERROR "Invalid username or password"
    RETURN 0

END FUNCTION

# ------------------ MAIN CONTAINER ----------------
FUNCTION open_main_container()

    #CLOSE WINDOW SCREEN

    -- Open main container window
    OPEN WINDOW w_main WITH FORM "main_container"
    LET g_win = ui.Window.getCurrent()
    LET g_form = g_win.getForm()
    CALL g_win.setText("XACT ERP Demo – Main Container")

    MENU "XACT ERP Demo"
        COMMAND "About"
            MESSAGE "About the app"
            #CALL show_about_dialog()

        COMMAND "User Profile"
            MESSAGE "User: " || f_username

        COMMAND "Quit"
            EXIT MENU

    END MENU

    CLOSE WINDOW w_main
END FUNCTION
