#include "protheus.ch"
#include "tbiconn.ch"
#include "topconn.ch"

User Function MyGetPath()

RpcSetType( 3 )
//PREPARE ENVIRONMENT EMPRESA "T1" FILIAL "D MG 01 " MODULO "COM"
PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "COM"

conout("========================================")
conout("My GetTempPath <<" + GetTempPath() + ">>")
conout("========================================")


Return
