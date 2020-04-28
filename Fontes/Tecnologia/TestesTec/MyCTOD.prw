#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TBICONN.CH'
#INCLUDE 'TOPCONN.CH'
User Function MyCTOD()
  Local cRet := STRZero(Day(Date()),2) + "/" +STRZero(Month(Date()),2) + "/" + STRZero(Year(Date()),4)
  Local dRet := CTOD(cRet)

  ConOut()
  ConOut("--------------------------------------------------------")
  ConOut("Vers�o do Bin�rio: <<" + GetBuild() + ">>")
  ConOut("Vers�o do AppServer: <<" + GetSrvVersion() + ">>")
  ConOut()
  ConOut("=== ANTES DO PREPARE ENVIRONMENT ================")
  ConOut("Dta no Formato Padr�o: <<" + cRet + ">>")
  ConOut("Valor da Convers�o: <<" + DTOC(dRet) + '>>' )
  ConOut("=== ANTES DO PREPARE ENVIRONMENT ================")
  ConOut()

  RPCSetType(3)
  PREPARE ENVIRONMENT EMPRESA "T1" FILIAL "D MG 01 " MODULO "FAT"

  dRet := CTOD(cRet)
  ConOut()
  ConOut("=== DEPOIS  DO PREPARE ENVIRONMENT ================")
  ConOut("Dta no Formato Padr�o: <<" + cRet + ">>")
  ConOut("Valor da Convers�o: <<" + DTOC(dRet) + '>>' )
  ConOut("=== DEPOIS  DO PREPARE ENVIRONMENT ================")
  ConOut("--------------------------------------------------------")
  ConOut()

return 0
