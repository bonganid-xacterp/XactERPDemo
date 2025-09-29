
# ==============================================================
# Program   :   dl100_mast.4gl
# Purpose   :   A program for adding , edit and to display corresponding transactions debtors
# Module    :   Debtors
# Number    :   100
# Author    :   Bongani Dlamini
# Version   :   Genero BDL 3.2.1
# ==============================================================


FUNCTION open_debtors()
    OPEN WINDOW w_debtors WITH FORM "form_dl100_mast"
    ATTRIBUTE (STYLE="child", TEXT="Debtors")



 END FUNCTION   