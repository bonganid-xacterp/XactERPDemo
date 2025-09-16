MAIN


  DEFER INTERRUPT
  CONNECT TO "custdemo"
  -- SET LOCK MODE TO WAIT   valid depending on database vendor  
  CLOSE WINDOW SCREEN
  OPEN WINDOW authf WITH FORM "f_login"

  CLOSE WINDOW authf
 
  DISCONNECT CURRENT

END MAIN  