IMPORT ui

FUNCTION login_screen() RETURNS BOOLEAN
    DEFINE login_ok BOOLEAN = FALSE

    OPEN WINDOW w_login WITH FORM "f_login"
        ATTRIBUTE(STYLE="dialog", TEXT="Login")

    DIALOG ATTRIBUTES(UNBUFFERED, INPUT ARRAY=FALSE)
        INPUT BY NAME formonly.username, formonly.password
            ON ACTION btn_login
                IF validate_user(formonly.username, formonly.password) THEN
                    LET login_ok = TRUE
                    EXIT DIALOG
                ELSE
                    MESSAGE "Invalid username or password."
                END IF

            ON ACTION btn_cancel
                LET login_ok = FALSE
                EXIT DIALOG
        END INPUT
    END DIALOG

    CLOSE WINDOW w_login
    RETURN login_ok
END FUNCTION
