# ==============================================================
# Program   :   cl100_mast.4gl
# Purpose   :   Creditors Maintanance progragm for adding, edit, update and delete.
# Module    :   Creditors (cl)
# Number    :   100
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.2.1
# ==============================================================




FUNCTION open_creditors()
    OPEN WINDOW w_debtors WITH  FORM "frm_dl100_mast"
 ATTRIBUTE (STYLE="child", TEXT="Debtors")

END FUNCTION

-- search creditors
FUNCTION search_creditors(p_term STRING)
    DEFINE search string
LET search = p_term 




END FUNCTION    