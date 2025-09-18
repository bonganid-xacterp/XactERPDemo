FUNCTION log_action(action STRING, user_name STRING, module STRING, status STRING)
    DEFINE user_id BIGINT

    SELECT id INTO user_id FROM sy00_user WHERE username = user_name

    INSERT INTO sy02_logs(action, user_id, module, status, created_at)
    VALUES(action, user_id, module, status, CURRENT)
END FUNCTION


FUNCTION validate_user(p_user STRING, p_pass STRING) RETURNS BOOLEAN
    DEFINE ok BOOLEAN = FALSE
    DEFINE db_pass STRING

    SELECT password INTO db_pass
      FROM sy00_user
     WHERE username = p_user
       AND status = 1
       AND deleted_at IS NULL

    IF STATUS = 0 THEN
        -- TODO: Replace with password hash compare
        IF db_pass = p_pass THEN
            LET ok = TRUE
            CALL log_action("LOGIN_SUCCESS", p_user, "system", "ok")
        ELSE
            CALL log_action("LOGIN_FAIL", p_user, "system", "fail")
        END IF
    ELSE
        CALL log_action("LOGIN_FAIL", p_user, "system", "fail")
    END IF

    RETURN ok
END FUNCTION
