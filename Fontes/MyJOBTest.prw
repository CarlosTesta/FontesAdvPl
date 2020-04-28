#include "protheus.ch"
#include "tbiconn.ch"
#include "topconn.ch"
#include 'parmtype.ch'


User Function MyJOBTest()
	StartJob("U_RodaFun",getenvserver(),.F.)
return


User Function RodaFun()
Local _nCnt

RPCSetType(3)
PREPARE ENVIRONMENT EMPRESA "T1" FILIAL "D MG 01 " MODULO "FAT"

ConOut(Repl("-",80))
ConOut("Estou Testando a Chamada de StartJob")
For _nCnt := 10 to 1 Step -1 
	ConOut("laço " + AllTrim(Str(_nCnt)))
	Inkey(1)
Next 
ConOut(Repl("-",80))

RESET ENVIRONMENT

Return