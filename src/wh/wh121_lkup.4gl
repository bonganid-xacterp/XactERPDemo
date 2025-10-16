FUNCTION fetch_wh_list()
    DEFINE p_wh_list STRING

    LET p_wh_list = NULL

    DECLARE wh_cur CURSOR FOR SELECT wh_code FROM warehouse_mst ORDER BY wh_code

    FOREACH wh_cur INTO p_wh_list
        IF p_wh_list IS NULL THEN
            LET p_wh_list = "'" || p_wh_list || "'"
        ELSE
            LET p_wh_list = p_wh_list || ",'" || p_wh_list || "'"
        END IF
    END FOREACH

    RETURN p_wh_list
END FUNCTION
